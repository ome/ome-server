#include "RemoteProcessor.h"
#include "Common.h"
#include "wt.h"
#include "WaveletHigh.h"
#include "WaveletMedium.h"
#include "WaveletLow.h"
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string>
#include <fcntl.h>
#include <pthread.h>
using namespace std;

#define MAX_MSG 4096

int respond_port;
char respond_ip[32];

RemoteProcessor::RemoteProcessor()
{
	
}

RemoteProcessor::~RemoteProcessor() { }

struct ThreadArgs
{
	double * input;
	int size;
	double * approx; 
	double * detail;
	int outsize;
	int extension_mode;
	int wave_mode;
	char * ip;
	int port;
	int incoming_port;
	
	int is_approx;
	
	
	ThreadArgs(double * i, int s, double * a, 
	double * d, int o, int e, int w, char * p, int po, int inp) : 
		input(i), size(s), approx(a), detail(d), outsize(o), extension_mode(e), wave_mode(w), ip(p), port(po), incoming_port(inp) { }
};

int portBind(int port) {
	struct sockaddr_in serv_addr;
	int server_sock;
	
	if((server_sock = socket(AF_INET,SOCK_STREAM,0))<0) {
	        fprintf(stderr,"socket() failed...exiting\n");
	        exit(-1);
	}
	
	int on = 1;
	setsockopt(server_sock,SOL_SOCKET,SO_REUSEADDR,&on,sizeof(on));
	
	memset(&serv_addr,0,sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	serv_addr.sin_port = htons(port);
	
	if(bind(server_sock,(struct sockaddr *) &serv_addr,sizeof(serv_addr))<0) {
	        fprintf(stderr,"bind() failed...exiting\n");
	        exit(-1);
	}
	
	// note buffer parameter.
	if(listen(server_sock,5)<0) {
	        fprintf(stderr,"listen() failed...exiting\n");
	        exit(-1);
	}

	return server_sock;	
}

char * thread_create_request(struct ThreadArgs * a) {
	
	XMLRPC_REQUEST request;
	XMLRPC_VALUE xParamList;
	STRUCT_XMLRPC_REQUEST_OUTPUT_OPTIONS output = { };

	request = XMLRPC_RequestNew();

	if (a->is_approx == 1) {
		if (verbose) cout << "running approx thread " << endl;
		XMLRPC_RequestSetMethodName(request, "wave_dec_approx");
	}
	else {
		if (verbose) cout << "running detail thread" << endl;
		XMLRPC_RequestSetMethodName(request, "wave_dec_detail");
	}
	
	XMLRPC_RequestSetRequestType(request, xmlrpc_request_call);
	output.version = xmlrpc_version_1_0;
	
	XMLRPC_RequestSetOutputOptions(request, &output);

	/* Create a parameter list vector */
	xParamList = XMLRPC_CreateVector(NULL, xmlrpc_vector_array);
  	
	/* Add our name as first param to the parameter list. */
	XMLRPC_VectorAppendInt(xParamList, NULL, a->incoming_port);
	XMLRPC_VectorAppendInt(xParamList, NULL, a->size);
	XMLRPC_VectorAppendInt(xParamList, NULL, a->outsize);
	XMLRPC_VectorAppendInt(xParamList, NULL, a->wave_mode);
	XMLRPC_VectorAppendInt(xParamList, NULL, a->extension_mode);
	
	for (int k = 0; k < a->size; k++) {
		XMLRPC_VectorAppendDouble(xParamList, NULL, a->input[k]);
	}
	
	/* add the parameter list to request */
	XMLRPC_RequestSetData(request, xParamList);

	/* serialize client request as XML */
	char *outBuf = XMLRPC_REQUEST_ToXML(request, 0);
	return outBuf;
}

void thread_send(struct ThreadArgs * a, char * outBuf) {
	// send to other node
	struct sockaddr_in serv_addr;
	if (verbose) cout << " sending data to " << a->ip << " on port " << a->port << endl;
	int sock;
	memset(&serv_addr,0,sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = inet_addr((const char *)a->ip);
	serv_addr.sin_port = htons(a->port);

	if((sock = socket(AF_INET,SOCK_STREAM,0))<0) { 
		cout << "socket error" << endl; 	
	}
	
	if (connect(sock,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
		cout << "connect error" << endl; 	
	}
	
	
	//if  (verbose) cout << outBuf << endl;
	if (send(sock, outBuf, strlen(outBuf), 0)<0) {
		cout << "send error" << endl; 	
	}
	close(sock);
	//if (verbose) cout << "sent " << strlen(outBuf) << "B to slave" << endl;
}

string thread_listen(int server_sock) {
	
	struct sockaddr_in clientname;
	socklen_t size = sizeof(clientname);
	int client_sock = accept(server_sock,(struct sockaddr *)&clientname,&size);
	if (client_sock < 0) {
		cout << "client sock accept problem" << endl;
	}
	
	int bytes = 0;
	int received = 0;
	string resp;	
	char buffer[MAX_MSG];
	memset(buffer,'\0',MAX_MSG);
	while ((received = recv(client_sock, buffer, MAX_MSG-1, 0)) > 0) {
		//cout << received << " on " <<client_sock << endl; cout.flush();
		resp += buffer;
		memset(buffer,'\0',MAX_MSG);
		bytes += received;
	}
	//if (verbose) cout << "received " << bytes << "B from slave" << endl;
	
	close(client_sock);
	close(server_sock);
	return resp;
}


string thread_communicate(struct ThreadArgs * a, char * outBuf) {
	
	// first set up channel to get response
	int server_sock = portBind(a->incoming_port);	

	thread_send(a,outBuf);
	return thread_listen(server_sock);
	
}

void thread_process_reply(struct ThreadArgs * a, string & resp) {
	
	double * out;
	if (a->is_approx) {
		out = a->approx;
	}
	else {
		out = a->detail;	
	}
	
	XMLRPC_REQUEST rpc_resp = XMLRPC_REQUEST_FromXML((const char*) resp.c_str(), resp.length(), NULL);
	XMLRPC_VALUE xParams = XMLRPC_RequestGetData(rpc_resp);
	XMLRPC_VALUE xFirstParam = XMLRPC_VectorRewind(xParams);
	
	for (int k = 0; k < a->outsize; k++) {
		out[k] = XMLRPC_GetValueDouble(xFirstParam);
		xFirstParam = XMLRPC_VectorNext(xParams);
		//if (verbose) cout << out[k] << endl;	
	}
	
	//printf(outBuf);
	
	if(rpc_resp) {
		XMLRPC_RequestFree(rpc_resp, 1);
	}
}

void thread_method(void * args) {
	
	struct ThreadArgs * a = (struct ThreadArgs *) args;
	
	char * outBuf = thread_create_request(a);
	string resp = thread_communicate(a, outBuf);
	thread_process_reply(a, resp);
	
}

Wavelet * getWavelet(int mode) {
	Wavelet * wave;
	switch(mode) {
		case WAVELET_HIGH:
			wave = new WaveletHigh(0);
			break;	
		case WAVELET_MED:
			wave = new WaveletMedium(0);
			break;
		case WAVELET_LOW:
			wave = new WaveletLow(0);
			break;
		default:
			cout << "Can't find wavelet specified ... exiting " << endl;
	}
	return wave;		
}

double * decode_xml(XMLRPC_REQUEST request, int & size, int & outsize, int & wave_mode, int & extension_mode) {
	
	XMLRPC_VALUE xParams = XMLRPC_RequestGetData(request);   // obtain method params from request
	XMLRPC_VALUE xFirstParam = XMLRPC_VectorRewind(xParams); // obtain first parameter
	
	respond_port = XMLRPC_GetValueInt(xFirstParam);  // get string value
	xFirstParam = XMLRPC_VectorNext(xParams);
	
	size = XMLRPC_GetValueInt(xFirstParam);  // get string value
	xFirstParam = XMLRPC_VectorNext(xParams);
	
	outsize = XMLRPC_GetValueInt(xFirstParam);  // get string value
	xFirstParam = XMLRPC_VectorNext(xParams);
	
	wave_mode = XMLRPC_GetValueInt(xFirstParam);  // get string value
	xFirstParam = XMLRPC_VectorNext(xParams);
	
	extension_mode = XMLRPC_GetValueInt(xFirstParam);  // get string value
	xFirstParam = XMLRPC_VectorNext(xParams);
	
	double * input = new double[size];
	for (int k = 0; k < size; k++) {
		input[k] = XMLRPC_GetValueDouble(xFirstParam);	
		xFirstParam = XMLRPC_VectorNext(xParams);
	}
	return input;
}

XMLRPC_VALUE wave_dec_approx(XMLRPC_SERVER server, XMLRPC_REQUEST request, void* userData)
{
	int size, outsize, wave_mode, extension_mode;
	double * input = decode_xml(request, size, outsize, wave_mode, extension_mode);

	if (verbose)  cout << " Received approx request to process with size: " << size << " outsize " << outsize << ", wavemode " << wave_mode << " and ext " << extension_mode << " and need to respond back to " << respond_port << endl;
	
	double * approx = new double[outsize];
	bzero(approx,outsize);

	Wavelet * wave = getWavelet(wave_mode);
	
	d_dec_a(input, size, wave, approx, outsize, extension_mode);
	
	XMLRPC_VALUE xParamList = XMLRPC_CreateVector(NULL, xmlrpc_vector_array);
	for (int k = 0; k < outsize; k++) {
		XMLRPC_VectorAppendDouble(xParamList, NULL, approx[k]);
	}
	
	return xParamList;
}

XMLRPC_VALUE wave_dec_detail(XMLRPC_SERVER server, XMLRPC_REQUEST request, void* userData)
{
	int size, outsize, wave_mode, extension_mode;
	double * input = decode_xml(request, size, outsize, wave_mode, extension_mode);
	
	if (verbose)  cout << " Received detail request to process with size: " << size << " outsize " << outsize << ", wavemode " << wave_mode << " and ext " << extension_mode << " and need to respond back to " << respond_port << endl;
	

	double * detail = new double[outsize];
	bzero(detail,outsize);

	Wavelet * wave = getWavelet(wave_mode);
	
	d_dec_d(input, size, wave, detail, outsize, extension_mode);
	
	XMLRPC_VALUE xParamList = XMLRPC_CreateVector(NULL, xmlrpc_vector_array);
	for (int k = 0; k < outsize; k++) {
		XMLRPC_VectorAppendDouble(xParamList, NULL, detail[k]);
	}
	
	return xParamList;
}

void RemoteProcessor::remoteProcess(double * input, int size, double * approx, 
	double * detail, int outsize, int extension_mode, int wave_mode) {

	
	
	pthread_t tid1, tid2;
	ThreadArgs *args1 = new ThreadArgs(input, size,approx,detail, 
		outsize,extension_mode,wave_mode,slave1,PORT,slave1port);
	args1->is_approx = 1;
	args1->approx = new double[outsize];

	ThreadArgs *args2 = new ThreadArgs(input, size,approx,detail, 
		outsize,extension_mode,wave_mode,slave2,PORT,slave2port);
	args2->is_approx = 0;
	args1->detail = new double[outsize];
	
	if(pthread_create(&tid1,NULL,(void*(*)(void *)) thread_method, (void *) args1) != 0) {
		if (verbose) fprintf(stderr,"pthread_create() failed\n");
	}
	
	if(pthread_create(&tid2,NULL, (void*(*)(void *)) thread_method, (void *) args2) != 0) {
		if (verbose) fprintf(stderr,"pthread_create() failed\n");
	}
     
	if (verbose) cout << "created threads and waiting for two nodes now " << endl;           
	pthread_join(tid1, NULL);
	pthread_join(tid2, NULL);

	for (int j = 0; j < outsize; j++) {
		approx[j] = args1->approx[j];
		detail[j] = args2->detail[j];
	}
}



string RemoteProcessor::getNetCommand(int client_sock, struct sockaddr_in & clientname) {

	//if(fcntl(client_sock,F_SETFL,O_NONBLOCK|O_ASYNC )<0) {
	//	if (verbose) fprintf(stderr,"fcntl() failed\n");
	//}
		
	
	sprintf(respond_ip,"%u.%u.%u.%u",(0xFF000000 & ntohl(clientname.sin_addr.s_addr)) >> 24,
	        (0x00FF0000 & ntohl(clientname.sin_addr.s_addr)) >> 16,
	        (0x0000FF00 & ntohl(clientname.sin_addr.s_addr)) >> 8,
	        (0x000000FF & ntohl(clientname.sin_addr.s_addr)) >> 0);
	
	if (verbose) printf("client connecting from: %s\n",respond_ip);
		
	if(client_sock<0) {
	        if (verbose) fprintf(stderr,"accept() failed\n");
	}
	
	char buffer[MAX_MSG];
	memset(buffer,'\0',MAX_MSG);
	int retval;

	string data = "";
	
	fd_set read_fd_set;
	struct timeval tv;
	FD_ZERO(&read_fd_set);
	FD_SET(client_sock,&read_fd_set);
	tv.tv_sec = 1;
	tv.tv_usec = 0;

	retval = 1;
	while ((retval = recv(client_sock,buffer,MAX_MSG-1,0)) > 0) {
		data += buffer;
		memset(buffer,'\0',MAX_MSG);
		
		FD_ZERO(&read_fd_set);
		FD_SET(client_sock,&read_fd_set);
	}
	close(client_sock);
    	return data;
}

void RemoteProcessor::commandReply(char * data) {
	
	//cout    << data << endl;
	
	struct sockaddr_in serv_addr;
	//if (verbose) cout << " sending data to " << respond_ip << " on port " << respond_port << endl;
	
	int sock;
	memset(&serv_addr,0,sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = inet_addr((const char *)respond_ip);
	serv_addr.sin_port = htons(respond_port);

	if((sock = socket(AF_INET,SOCK_STREAM,0))<0) { 
		cout << "socket error" << endl; 	
	}
	
	if (connect(sock,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
		cout << "connect error" << endl; 	
	}
	
	if(send(sock,(const void*) data,strlen(data),0)<0) {
		cout << "send error" << endl;
	}
	close(sock);
	//exit(0);
}

void RemoteProcessor::awaitCommand() {
	

	int server_sock = portBind(PORT);
	XMLRPC_SERVER  server = XMLRPC_ServerCreate();;
	XMLRPC_REQUEST request, response;
	XMLRPC_ServerRegisterMethod(server, "wave_dec_detail", wave_dec_detail);
	XMLRPC_ServerRegisterMethod(server, "wave_dec_approx", wave_dec_approx);
	
	
	while(1) {
		struct sockaddr_in clientname;
		socklen_t size = sizeof(clientname);
	
		int client_sock = accept(server_sock,(struct sockaddr *)&clientname,&size);
			
		string command = getNetCommand(client_sock, clientname);
		//cout << "GOT COMMAND " << command << endl; cout.flush();
		request = XMLRPC_REQUEST_FromXML((const char*)command.c_str(), command.length(), NULL);
		if (!request) { cout << "RPC Request invalid" << endl; }
		
		response = XMLRPC_RequestNew();
		XMLRPC_RequestSetRequestType(response, xmlrpc_request_response);
		XMLRPC_RequestSetData(response, XMLRPC_ServerCallMethod(server, request, NULL));
		XMLRPC_RequestSetOutputOptions(response, XMLRPC_RequestGetOutputOptions(request) );
		char *outBuf = XMLRPC_REQUEST_ToXML(response, 0);	
		
		commandReply(outBuf);
		XMLRPC_RequestFree(request, 1);
		XMLRPC_RequestFree(response, 1);
	}
    
	XMLRPC_ServerDestroy(server);
}

