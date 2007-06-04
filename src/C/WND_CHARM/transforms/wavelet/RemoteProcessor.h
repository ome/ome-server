#ifndef REMOTEPROCESSOR_H_
#define REMOTEPROCESSOR_H_

#include <string>
using namespace std;

//#include "xmlrpc-epi/src/xmlrpc.h"

class RemoteProcessor
{
public:
	RemoteProcessor();
	virtual ~RemoteProcessor();
	
	void remoteProcess(double * input, int ysize, double * approx, 
		double * detail, int outsizey, int extension_mode, int wave_mode);
		
	void awaitCommand();
private:
	
	string getNetCommand(int client_sock, struct sockaddr_in & clientname);
	void commandReply(char * data);
		
};

#endif /*REMOTEPROCESSOR_H_*/
