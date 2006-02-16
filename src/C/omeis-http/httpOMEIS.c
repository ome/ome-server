/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2005 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */
 
 
/*------------------------------------------------------------------------------
 *
 * Written by:	Tom J. Macura <tmacura@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

#include "httpOMEIS.h"
#include "httpOMEISaux.h"
/* #define DEBUG */ /* Uncomment preprocessor directive to see verbose info */

/* special logic to use MATLAB specific memory managment during matlab files */
/* #define MATLAB */
#ifdef MATLAB

#include "matrix.h"
#define CALLOC mxCalloc
#define MALLOC mxMalloc
#define REALLOC mxRealloc
#define FREE mxFree

#else

#define CALLOC calloc
#define MALLOC malloc
#define REALLOC realloc
#define FREE free

#endif

/* PRIVATE functions and datatypes */
typedef struct {
	void* buffer;
	size_t len;
	size_t capacity;
} smartBuffer;

void* executeGETCall (const omeis* is, const char* parameters, size_t nmemb);
size_t writeBuffer (void* ptr, size_t size, size_t nmemb, smartBuffer* buffer);

omeis* openConnectionOMEIS (const char* url, const char* sessionKey)
{
	omeis* is = (omeis*) MALLOC (sizeof(omeis));
	
	strncpy(is->url, url, 128);
	strncpy(is->sessionKey, sessionKey, 128);
	
/*	curl_global_init(CURL_GLOBAL_DEFAULT); */
	curl_global_init(CURL_GLOBAL_WIN32);
	
	return is;
}

OID newPixels (const omeis* is, const pixHeader* head)
{
	OID pixelsID;
	char* buffer;
	char command [256];
	char dims[128];
	sprintf(dims,"%d,%d,%d,%d,%d,%d", head->dx, head->dy, head->dz, head->dc, head->dt, head->bp);
    sprintf(command,"%s%sMethod=NewPixels&Dims=%s&IsSigned=%d&IsFloat=%d", is->url, "?", dims, head->isSigned, head->isFloat);
	buffer = (char*) executeGETCall(is, command, 1024);
	
	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return 0;
	}
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return 0;
	}
	
	if (sscanf(buffer,"%llu", &pixelsID) != 1) {
		fprintf(stderr, "Output from OMEIS method NewPixels couldn't be parsed.\n");
		FREE(buffer);
		return 0;
	}
	
	FREE(buffer);
	return pixelsID;
}

pixHeader* pixelsInfo (const omeis* is, OID pixelsID)
{
	pixHeader* head = (pixHeader*) MALLOC (sizeof(pixHeader));
	
	char* sha1 = (char*) MALLOC(sizeof(char)*OME_DIGEST_CHAR_LENGTH);
	char* buffer;
	char command [256];
	int dx, dy, dz, dc, dt, bp, isFinished, isSigned, isFloat;
	int i;
	
	sprintf(command,"%s%sMethod=PixelsInfo&PixelsID=%llu",is->url,"?", pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);
	
	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return NULL;
	}

	if (strstr(buffer, "Error")) {
		FREE(buffer);
		return NULL;
	}

	if (sscanf(buffer,"Dims=%d,%d,%d,%d,%d,%d\nFinished=%d\nSigned=%d\nFloat=%d\nSHA1=%40c",
		&dx, &dy, &dz, &dc, &dt, &bp, &isFinished, &isSigned, &isFloat, sha1) != 10) {
		fprintf(stderr, "Output from OMEIS method PixelsInfo couldn't be parsed.\n");
		FREE(buffer);
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
	
	for (i=0; i < OME_DIGEST_CHAR_LENGTH-1; i++)
		head->sha1[i] = (u_int8_t) sha1[i];
	head->sha1[OME_DIGEST_CHAR_LENGTH-1] = '\0';

	FREE(buffer);
	FREE(sha1);
	return head;
}

char* pixelsSHA1 (const omeis *is, OID pixelsID)
{
	char* sha1 = (char*) MALLOC(sizeof(char)*OME_DIGEST_CHAR_LENGTH);
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=PixelsSHA1&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);
	
	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return NULL;
	}
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return NULL;
	}
	
	if (sscanf(buffer,"%40c", sha1) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	sha1[OME_DIGEST_CHAR_LENGTH-1] = '\0';

	FREE(buffer);
	return sha1;
}

int setPixels (const omeis *is, OID pixelsID, const void* pixels)
{
	pixHeader* head = pixelsInfo (is, pixelsID);
	char scratch[32];
	smartBuffer buffer;
	CURL* curl;
	
	/* initialize smart Buffer for output */
	buffer.buffer = (unsigned char*) CALLOC(1024,1);
	buffer.len = 0;
	buffer.capacity = 1023;
	
	curl = curl_easy_init();
	curl_easy_setopt(curl, CURLOPT_FORBID_REUSE, 1);
	#ifdef DEBUG
		curl_easy_setopt(curl, CURLOPT_VERBOSE, 1);
	#endif
	curl_easy_setopt (curl, CURLOPT_WRITEFUNCTION, writeBuffer);
	curl_easy_setopt (curl, CURLOPT_WRITEDATA, &buffer);
	
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
				CURLFORM_BUFFERLENGTH, (long) (head->dx*head->dy*head->dz*head->dc*head->dt*head->bp),
				CURLFORM_END);

	headerlist = curl_slist_append(headerlist, "Expect:");    
    curl_easy_setopt(curl, CURLOPT_URL, is->url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerlist);
    curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);

    int result_code = curl_easy_perform (curl);

    /* cleanup */
	curl_easy_cleanup (curl);
	curl_formfree (post);
	curl_slist_free_all (headerlist);
	
    if (result_code != CURLE_OK) {
    	FREE(head);
		FREE(buffer.buffer);
		return 0;
	}
	
	int pix;
	if (sscanf(buffer.buffer,"%d\n", &pix) != 1) {
		fprintf(stderr, "Output from OMEIS method SetPixels couldn't be parsed.\n");
		FREE(head);
		FREE(buffer.buffer);
		return 0;
	}
	FREE(head);
	FREE(buffer.buffer);
	return pix;
}

void* getPixels (const omeis* is, OID pixelsID)
{
	char* buffer;
	char command [256];
    pixHeader* ph;

    ph = pixelsInfo (is, pixelsID);
    int bytes = ph->dx*ph->dy*ph->dz*ph->dc*ph->dt*ph->bp;
	if (bytes < 1024)
    	bytes = 1024;
	FREE(ph);

    sprintf(command,"%s%sMethod=GetPixels&PixelsID=%llu&BigEndian=%d",is->url,"?",pixelsID,bigEndian()); 	
    buffer = (char*) executeGETCall(is, command, bytes);
    
    if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);
		return NULL;
	}
	
    if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return NULL;
	}

	return (void*) buffer;
}

OID finishPixels (const omeis* is, OID pixelsID)
{
	OID newID;
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=FinishPixels&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);

	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return 0;
	}
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return 0;
	}

	if (sscanf(buffer,"%llu", &newID) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	
	FREE(buffer);
	return newID;
}

OID deletePixels (const omeis* is, OID pixelsID)
{
	OID oldID;
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=DeletePixels&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);

	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return 0;
	}
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return 0;
	}

	if (sscanf(buffer,"%llu", &oldID) != 1) {
		fprintf(stderr, "Output from OMEIS method DeletePixels couldn't be parsed.\n");
	}
	
	FREE(buffer);
	return oldID;
}

char* getLocalPath (const omeis *is, OID pixelsID)
{
	char* path = (char*) MALLOC (sizeof(char)*128);
	char* buffer;
	char command [256];
	sprintf(command,"%s%sMethod=GetLocalPath&PixelsID=%llu", is->url,"?",pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);

	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		FREE(buffer);
		return 0;
	}
	
	if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return NULL;
	}
	
	if (sscanf(buffer,"%s\n", path) != 1) {
		fprintf(stderr, "Output from OMEIS method FinishPixels couldn't be parsed.\n");
	}
	
	FREE(buffer);
	return path;
}

int setROI (const omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1, const void* pixels)
{
	pixHeader* head = pixelsInfo (is, pixelsID); /* needed to figure out bp */
	char scratch[128];
	smartBuffer buffer;
	CURL* curl;
	
	/* initialize smart Buffer for output */
	buffer.buffer = (unsigned char*) CALLOC(1024,1);
	buffer.len = 0;
	buffer.capacity = 1023;
	
	curl = curl_easy_init();
	curl_easy_setopt(curl, CURLOPT_FORBID_REUSE, 1);
	#ifdef DEBUG
		curl_easy_setopt(curl, CURLOPT_VERBOSE, 1);
	#endif
	curl_easy_setopt (curl, CURLOPT_WRITEFUNCTION, writeBuffer);
	curl_easy_setopt (curl, CURLOPT_WRITEDATA, &buffer);
	
	struct curl_httppost *post=NULL;
    struct curl_httppost *last=NULL;
    struct curl_slist *headerlist=NULL;
    
	curl_formadd(&post, &last,
				CURLFORM_COPYNAME, "Method",
				CURLFORM_COPYCONTENTS, "SetROI",
				CURLFORM_END);

	sprintf (scratch, "%llu", pixelsID);
	curl_formadd(&post, &last,
				 CURLFORM_COPYNAME, "PixelsID",
				 CURLFORM_COPYCONTENTS, scratch,
				 CURLFORM_END);
				 
	sprintf (scratch, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", x0, y0, z0, c0, t0,
			x1, y1, z1, c1, t1);
	curl_formadd(&post, &last,
				 CURLFORM_COPYNAME, "ROI",
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
				CURLFORM_BUFFERLENGTH, (long) ( (x1-x0+1)*(y1-y0+1)*(z1-z0+1)*(c1-c0+1)*(t1-t0+1)*head->bp ),
				CURLFORM_END);

	headerlist = curl_slist_append(headerlist, "Expect:");    
    curl_easy_setopt(curl, CURLOPT_URL, is->url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerlist);
    curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);

    int result_code = curl_easy_perform (curl);

    /* cleanup */
	curl_easy_cleanup (curl);
	curl_formfree (post);
	curl_slist_free_all (headerlist);
	
    if (result_code != CURLE_OK) {
		FREE(head);
		FREE(buffer.buffer);
		return 0;
	}
	
	int pix;
	if (sscanf(buffer.buffer,"%d\n", &pix) != 1) {
		fprintf(stderr, "Output from OMEIS method SetROI couldn't be parsed.\n");
		FREE(head);
		FREE(buffer.buffer);
		return 0;
	}
	FREE(head);
	FREE(buffer.buffer);
	return pix;
}

void* getROI (const omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1)
{
	char* buffer;
	char command [256];
    pixHeader* ph;

    ph = pixelsInfo (is, pixelsID);
    int bytes = (x1-x0+1)*(y1-y0+1)*(z1-z0+1)*(c1-c0+1)*(t1-t0+1)*ph->bp;
	if (bytes < 1024)
    	bytes = 1024;
	FREE(ph);

    sprintf(command,"%s%sMethod=GetROI&PixelsID=%llu&ROI=%d,%d,%d,%d,%d,%d,%d,%d,%d,%d&BigEndian=%d",
    		is->url,"?",pixelsID,x0,y0,z0,c0,t0,x1,y1,z1,c1,t1,bigEndian()); 	
    buffer = (char*) executeGETCall(is, command, bytes);
    
    if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		return NULL;
	}
	
    if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return NULL;
	}

	return (void*) buffer;
}

void* getStack (const omeis *is, OID pixelsID, int theC, int theT)
{
	char* buffer;
	char command [256];
	int bytes;
    pixHeader* ph;

    ph = pixelsInfo (is, pixelsID);
    bytes = ph->dx*ph->dy*ph->dz*ph->bp;
	if (bytes < 1024)
    	bytes = 1024;
	FREE (ph);

    sprintf(command,"%s%sMethod=GetStack&PixelsID=%llu&theC=%d&theT=%d&BigEndian=%d",
    		is->url,"?",pixelsID,theC,theT,bigEndian()); 	
    buffer = (char*) executeGETCall(is, command, bytes);
    
    if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		return NULL;
	}
	
    if (strstr(buffer, "Error")) {
		fprintf (stderr, "ERROR:\n%s\n", buffer);
		FREE(buffer);
		return NULL;
	}

	return (void*) buffer;
}


/*
  This returns a 2-D array of pixStats structs, which can be acessed like this:
  stats = getStackStats (is, pixelsID, theC, theT);
  c0t0min = stats[0][0].min;
  c0t1min = stats[0][1].min;
  theMin = stats[theC][theT].min;
  The first dimension specifies the channel and the second specifies the time
  available stats are:
  	float min, max, mean, sigma, geomean, geosigma;
  	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
  	float centroid_x, centroid_y, centroid_z;

  When finished with the stats, make sure to call freeStackStats (stats);

  The 2-D array returned by this function is stored as a contiguous block
  of pixStats structs in memory at &(stats[0][0]) or, just stats, so it can be acessed
  serially in CT order using a pixStats pointer.
*/
pixStats **getStackStats (const omeis *is, OID pixelsID){
	char* buffer, *line, *lineEnd;
	char command [256];
    pixStats *array;
    pixStats **theStats;
    unsigned long theC, theT, nC=0, nT=0;
    pixHeader* ph;

    ph = pixelsInfo (is, pixelsID);
	nC = ph->dc;
	nT = ph->dt;
	FREE(ph);

	sprintf(command,"%s%sMethod=GetStackStats&PixelsID=%llu",is->url,"?", pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);
	
	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		return NULL;
	}

	if (strstr(buffer, "Error")) {
		FREE(buffer);
		return NULL;
	}

	/* Allocate the memory for the array */
	array = malloc(nC * nT * sizeof(pixStats));
    if (array == NULL) {
		fprintf (stderr, "Could not allocate space for stats array\n");	
		return (NULL);
	}

	/* next we allocate room for the pointers to the Cs */
	theStats = malloc(nC * sizeof(pixStats *));
	if (theStats == NULL) {
		fprintf (stderr, "Could not allocate space for stats array\n");	
		return (NULL);
	}

	/* and set the pointers */
	for (theC = 0; theC < nC; theC++)
	{
		theStats[theC] = array + (theC * nT);
	}

	/*
	  Now go through the buffer again reading the stats
	*/
	line = buffer;
	lineEnd = strstr (buffer,"\n");
	while (lineEnd) {
		sscanf (line,"%lu\t%lu",&theC,&theT);
		sscanf (line,"%*lu\t%*lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f",
			&(theStats[theC][theT].min),
			&(theStats[theC][theT].max),
			&(theStats[theC][theT].mean),
			&(theStats[theC][theT].sigma),
			&(theStats[theC][theT].geomean),
			&(theStats[theC][theT].geosigma),
			&(theStats[theC][theT].centroid_x),
			&(theStats[theC][theT].centroid_y),
			&(theStats[theC][theT].centroid_z),
			&(theStats[theC][theT].sum_i),
			&(theStats[theC][theT].sum_i2),
			&(theStats[theC][theT].sum_log_i),
			&(theStats[theC][theT].sum_xi),
			&(theStats[theC][theT].sum_yi),
			&(theStats[theC][theT].sum_zi)
		);
		line = lineEnd+1;
		lineEnd = strstr (line,"\n");
	}

	FREE(buffer);
	return theStats;
}


void freeStackStats (pixStats **theStats){
	FREE (*theStats);
	FREE (theStats);
}



/*
pixStats ***getPlaneStats (const omeis *is, OID pixelsID);

  This returns a 3-D array of pixStats strcuts, which can be acessed like this:
  stats = getStackStats (is, pixelsID);
  z0c0t0min = stats[0][0][0].min;
  z1c0t1min = stats[1][0][1].min;
  theMin    = stats[theZ][theC][theT].min;
  available stats are:
	float min, max, mean, sigma, geomean, geosigma;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float centroid_x, centroid_y;
	// centroid_z is set to the Z index.

  When finished with the stats, make sure to call freePlaneStats (stats);

  The 3-D array returned by this function is stored as a contiguous block
  of pixStats structs in memory at &(stats[0][0][0]) or, just stats, so it can be acessed
  serially in ZCT order using a pixStats pointer.
*/
pixStats ***getPlaneStats (const omeis *is, OID pixelsID){
	char* buffer, *line, *lineEnd;
	char command [256];
    pixStats *array;
    pixStats **theStatsZ;
    pixStats ***theStats;
    unsigned long theZ, theC, theT, nZ=0, nC=0, nT=0;
    pixHeader* ph;

    ph = pixelsInfo (is, pixelsID);
	nZ = ph->dz;
	nC = ph->dc;
	nT = ph->dt;
	FREE(ph);

	sprintf(command,"%s%sMethod=GetPlaneStats&PixelsID=%llu",is->url,"?", pixelsID);
	buffer = (char*) executeGETCall(is, command, 1024);
	
	if (buffer == NULL) {
		fprintf (stderr, "Could not get response from server. Perhaps URL `%s` is wrong.\n", is->url);	
		return NULL;
	}

	if (strstr(buffer, "Error")) {
		fprintf (stderr, "Server error: %s.\n", buffer);	
		FREE(buffer);
		return NULL;
	}

	
	/* Allocate the memory for the array */
	array = malloc(nZ * nC * nT * sizeof(pixStats));
    if (array == NULL) {
		fprintf (stderr, "Could not allocate space for stats array\n");	
		FREE(buffer);
		return (NULL);
	}

	/* next we allocate room for the pointers to Cs */
	theStatsZ = malloc(nZ * nC * sizeof(pixStats *));
	if (theStatsZ == NULL) {
		fprintf (stderr, "Could not allocate space for stats array\n");	
		FREE(buffer);
		return (NULL);
	}

	/* next we allocate room for the pointers to the Zs. */
	theStats = malloc(nZ * sizeof(pixStats **));
	if (theStats == NULL) {
		fprintf (stderr, "Could not allocate space for stats array\n");	
		FREE(buffer);
		return (NULL);
	}

	/* and set the pointers */
	for (theZ = 0; theZ < nZ; theZ++) {
		theStats[theZ] = theStatsZ + (theZ * nC) ;
		for (theC = 0; theC < nC; theC++) {
			theStats[theZ][theC] = array + (theZ * nC * nT) + (theC * nT);
		}
	}

	/*
	  Now go through the buffer reading the stats
	*/
	line = buffer;
	lineEnd = strstr (buffer,"\n");
	while (lineEnd) {
		sscanf (line,"%lu\t%lu\t%lu",&theC,&theT,&theZ);
		sscanf (line,"%*lu\t%*lu\t%*lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f",
			&(theStats[theZ][theC][theT].min),
			&(theStats[theZ][theC][theT].max),
			&(theStats[theZ][theC][theT].mean),
			&(theStats[theZ][theC][theT].sigma),
			&(theStats[theZ][theC][theT].geomean),
			&(theStats[theZ][theC][theT].geosigma),
			&(theStats[theZ][theC][theT].centroid_x),
			&(theStats[theZ][theC][theT].centroid_y),
			&(theStats[theZ][theC][theT].sum_i),
			&(theStats[theZ][theC][theT].sum_i2),
			&(theStats[theZ][theC][theT].sum_log_i),
			&(theStats[theZ][theC][theT].sum_xi),
			&(theStats[theZ][theC][theT].sum_yi),
			&(theStats[theZ][theC][theT].sum_zi)
		);
		theStats[theZ][theC][theT].centroid_z = theZ;
		line = lineEnd+1;
		lineEnd = strstr (line,"\n");
	}

	FREE(buffer);
	return theStats;
}


void freePlaneStats (pixStats ***theStats){
	FREE (**theStats);
	FREE (*theStats);
	FREE (theStats);
}




/*
	Private Functions
*/
void* executeGETCall (const omeis* is, const char* parameters, size_t nmemb)
{
	int result_code;
	smartBuffer buffer;
	CURL* curl;

	/* callocing avoids problems with string null terminators */
	buffer.buffer = (unsigned char*) CALLOC (nmemb+1, 1);
	buffer.len = 0;
	buffer.capacity = nmemb;
	
	curl = curl_easy_init();
	curl_easy_setopt (curl, CURLOPT_URL, parameters);
	curl_easy_setopt (curl, CURLOPT_FORBID_REUSE, 1);
	#ifdef DEBUG
	curl_easy_setopt (curl, CURLOPT_VERBOSE, 1);
	#endif
	
	/* Define our callback to get called when there's data to be written */
	curl_easy_setopt (curl, CURLOPT_WRITEFUNCTION, writeBuffer);
	curl_easy_setopt (curl, CURLOPT_WRITEDATA, &buffer);
	result_code = curl_easy_perform (curl);
	if (result_code != CURLE_OK) {
		curl_easy_cleanup (curl);
		FREE(buffer.buffer);
		return NULL;
	}
	curl_easy_cleanup (curl);
	if (buffer.len < buffer.capacity) 
		*( (char *)(buffer.buffer+buffer.len) ) = '\0';

	return buffer.buffer;
}

size_t writeBuffer (void* ptr, size_t size, size_t nmemb, smartBuffer* buffer)
{
size_t write_size;
void *newBuffer;

	write_size = nmemb*size;
	
	if ( write_size + buffer->len > buffer->capacity) {
		newBuffer = REALLOC (buffer->buffer,write_size + buffer->len + 1);
		if (!newBuffer) {
			fprintf(stderr, "ERROR not enough memmory allocated to accept data from OMEIS");
			return 0;
		} else {
			buffer->buffer = newBuffer;
			buffer->capacity = write_size + buffer->len + 1;
			*( (char *)(buffer->buffer+buffer->len+write_size) ) = '\0';
		}
	}

	memcpy(buffer->buffer+buffer->len, ptr, write_size);
	buffer->len += write_size;
	
	return write_size;
}
