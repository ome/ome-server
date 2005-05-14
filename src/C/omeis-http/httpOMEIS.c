#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

#include "httpOMEIS.h"
/* #define DEBUG */ /* Uncomment preprocessor directive to see verbose info */

/* PRIVATE functions and datatypes */
typedef struct {
	unsigned char* buffer;
	int len;
	int capacity;
} smartBuffer;

void* executeGETCall (omeis* is, char* parameters, size_t nmemb);
size_t writeBuffer (void* ptr, size_t size, size_t nmemb, smartBuffer* buffer);
int bigEndian (void);

omeis* openConnectionOMEIS (char* url, char* sessionKey)
{
	omeis* is = malloc (sizeof(omeis));
	
	strncpy(is->url, url, 128);
	strncpy(is->sessionKey, sessionKey, 128);
	
	curl_global_init(CURL_GLOBAL_DEFAULT);
	return is;
}

OID newPixels (omeis* is, pixHeader* head)
{
	OID pixelsID;
	char* buffer;
	char command [256];
	char dims[128];
	sprintf(dims,"%d,%d,%d,%d,%d,%d", head->dx, head->dy, head->dz, head->dc, head->dt, head->bp);
    sprintf(command,"%s%sMethod=NewPixels&Dims=%s&IsSigned=%d&IsFloat=%d", is->url, "?", dims, head->isSigned, head->isFloat);
	buffer = (char*) executeGETCall(is, command, 32);

	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return -1;
	}
	
	if (sscanf(buffer,"%llu", &pixelsID) != 1) {
		fprintf(stderr, "Output from OMEIS method NewPixels couldn't be parsed.\n");
	}
	
	free(buffer);
	return pixelsID;
}

pixHeader* pixelsInfo (omeis* is, OID pixelsID)
{
	pixHeader* head = (pixHeader*) malloc(sizeof(pixHeader));
	char* buffer;
	char command [256];
	int dx, dy, dz, dc, dt, bp, isFinished, isSigned, isFloat;

	sprintf(command,"%s%sMethod=PixelsInfo&PixelsID=%llu",is->url,"?", pixelsID);
	buffer = (char*) executeGETCall(is, command, 256);
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return NULL;
	}
	
	if (sscanf(buffer,"Dims=%d,%d,%d,%d,%d,%d\nFinished=%d\nSigned=%d\nFloat=%d\nSHA1=%40c",
		&dx, &dy, &dz, &dc, &dt, &bp, &isFinished, &isSigned, &isFloat, head->sha1) != 10) {
		fprintf(stderr, "Output from OMEIS method PixelsInfo couldn't be parsed.\n");
		return NULL;
	}
	
	head->dx = (ome_dim) dx;
	head->dy = (ome_dim) dy;
	head->dz = (ome_dim) dz;
	head->dc = (ome_dim) dc;
	head->dt = (ome_dim) dt;
	head->bp         = (u_int8_t) bp;
	head->isFinished = (u_int8_t) isFinished;
	head->isSigned   = (u_int8_t) isSigned;
	head->isFloat    = (u_int8_t) isFloat;
	
	free(buffer);
	return head;
}

char* pixelsSHA1 (omeis *is, OID pixelsID)
{
	char* sha1 = (char*) malloc(sizeof(char)*OME_DIGEST_LENGTH);
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=PixelsSHA1&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 64);
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return NULL;
	}
	
	if (sscanf(buffer,"%40c", sha1) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	sha1[40] = '\0';

	free(buffer);
	return sha1;
}

int setPixels (omeis *is, OID pixelsID, void* pixels)
{
	pixHeader* head = pixelsInfo (is, pixelsID);
	char scratch[32];
	smartBuffer buffer;
	
	/* initialize smart Buffer for output */
	buffer.buffer = malloc(32);
	buffer.len = 0;
	buffer.capacity = 32;
	
	is->curl = curl_easy_init();
	curl_easy_setopt(is->curl, CURLOPT_FORBID_REUSE, 1);
	#ifdef DEBUG
		curl_easy_setopt(is->curl, CURLOPT_VERBOSE, 1);
	#endif
	curl_easy_setopt (is->curl, CURLOPT_WRITEFUNCTION, writeBuffer);
	curl_easy_setopt (is->curl, CURLOPT_WRITEDATA, &buffer);
	
	struct curl_httppost *post=NULL;
    struct curl_httppost *last=NULL;
    struct curl_slist *headerlist=NULL;
    
	curl_formadd(&post, &last,
				CURLFORM_COPYNAME, "Method",
				CURLFORM_COPYCONTENTS, "SetPixels",
				CURLFORM_END);

	sprintf (scratch, "%llu", pixelsID);
	curl_formadd(&post, &last,
				 CURLFORM_COPYNAME, "PixelsID",
				 CURLFORM_COPYCONTENTS, scratch,
				 CURLFORM_END);
				 
	sprintf (scratch, "%d", bigEndian());
	curl_formadd(&post, &last,
				 CURLFORM_COPYNAME, "BigEndian",
				 CURLFORM_COPYCONTENTS, scratch,
				 CURLFORM_END);
				 
	curl_formadd(&post, &last,
				CURLFORM_COPYNAME, "Pixels",
				CURLFORM_BUFFER, "data",
				CURLFORM_BUFFERPTR, pixels,
				CURLFORM_BUFFERLENGTH, head->dx*head->dy*head->dz*head->dc*head->dt*head->bp,
				CURLFORM_END);

	headerlist = curl_slist_append(headerlist, "Expect:");    
    curl_easy_setopt(is->curl, CURLOPT_URL, is->url);
    curl_easy_setopt(is->curl, CURLOPT_HTTPHEADER, headerlist);
    curl_easy_setopt(is->curl, CURLOPT_HTTPPOST, post);

    int result_code = curl_easy_perform (is->curl);

    /* cleanup */
	curl_easy_cleanup (is->curl);
	curl_formfree (post);
	curl_slist_free_all (headerlist);
	
    if (result_code != CURLE_OK) {
		return 0;
	}
	
	int pix;
	if (sscanf(buffer.buffer,"%d\n", &pix) != 1) {
		fprintf(stderr, "Output from OMEIS method SetPixels couldn't be parsed.\n");
		return 0;
	}
	free(buffer.buffer);
	return pix;
}

void* getPixels (omeis* is, OID pixelsID)
{
	char* buffer;
	char command [256];
    pixHeader* ph;
    ph = pixelsInfo (is, pixelsID);
    int bytes = ph->dx*ph->dy*ph->dz*ph->dc*ph->dt*ph->bp;
    sprintf(command,"%s%sMethod=GetPixels&PixelsID=%llu&BigEndian=%d",is->url,"?",pixelsID,bigEndian());
    
    buffer = (char*) executeGETCall(is, command,bytes+1);
    buffer[bytes] = '\0';
    
    if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return NULL;
	}
	
	return (void*) buffer;
}

OID finishPixels (omeis* is, OID pixelsID)
{
	OID newID;
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=FinishPixels&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 32);

	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return -1;
	}

	if (sscanf(buffer,"%llu", &newID) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	
	free(buffer);
	return newID;
}

char* getLocalPath (omeis *is, OID pixelsID)
{
	char* path = (char*) malloc(sizeof(char)*OME_DIGEST_LENGTH);
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=GetLocalPath&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 64);
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		return NULL;
	}
	
	if (sscanf(buffer,"%s\n", path) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	
	free(buffer);
	return path;
}

/*
	Private Functions
*/
void* executeGETCall (omeis* is, char* parameters, size_t nmemb)
{
	int result_code;
	smartBuffer buffer;
	
	buffer.buffer = malloc(nmemb);
	buffer.len = 0;
	buffer.capacity = nmemb;
	
	is->curl = curl_easy_init();
	curl_easy_setopt (is->curl, CURLOPT_URL, parameters);
	curl_easy_setopt (is->curl, CURLOPT_FORBID_REUSE, 1);
	#ifdef DEBUG
	curl_easy_setopt (is->curl, CURLOPT_VERBOSE, 1);
	#endif
	
	/* Define our callback to get called when there's data to be written */
	curl_easy_setopt (is->curl, CURLOPT_WRITEFUNCTION, writeBuffer);
	curl_easy_setopt (is->curl, CURLOPT_WRITEDATA, &buffer);
	result_code = curl_easy_perform (is->curl);
	if (result_code != CURLE_OK) {
		return NULL;
	}
	curl_easy_cleanup (is->curl);
	
	return buffer.buffer;
}

size_t writeBuffer (void* ptr, size_t size, size_t nmemb, smartBuffer* buffer)
{
	unsigned char* typed_ptr = ptr;
	
	if (nmemb + buffer->len > buffer->capacity) {
		fprintf(stderr, "ERROR not enough memmory allocated to accept data from OMEIS");
		exit(EXIT_FAILURE);	
	}

	int i;
	for (i = 0; i < size*nmemb; i++) {
		buffer->buffer[buffer->len+i] = typed_ptr[i];
	}
	buffer->len += nmemb;
	
	return nmemb;
}

/*
	Josiah Johnston <siah@nih.gov>
	Returns 1 if the machine executing this code is bigEndian, 0 otherwise.
*/
int bigEndian (void)
{
    static int init = 1;
    static int endian_value;
    char *p;

    p = (char*)&init;
    return endian_value = p[0]?0:1;
}