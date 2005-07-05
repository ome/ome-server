#ifndef HTTP_OMEIS_H
#define HTTP_OMEIS_H

#include <sys/types.h>
#include <curl/curl.h>
#include <curl/types.h>

/* Copied from Pixels.h */
typedef int32_t ome_coord;
typedef int32_t ome_dim;
typedef u_int64_t OID;

#define OME_DIGEST_CHAR_LENGTH 41
typedef struct {
	u_int32_t mySig;
	u_int8_t vers;
	u_int8_t isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	u_int8_t bp;             /* bytes per pixel */
	u_int8_t isSigned;       /* signed integers or not */
	u_int8_t isFloat;        /* floating point or not */
	u_int8_t sha1[OME_DIGEST_CHAR_LENGTH]; /* SHA1 digest */
	u_int8_t reserved[15];   /* buffer to 64 (60?)assuming OME_DIGEST_LENGTH=20 */
} pixHeader;

/* Copied from Pixels.h, but trimmed */
typedef struct {
	OID ID;
	
	/* The rest is just like in the file */
	pixHeader *head;
/*	planeInfo *planeInfos;
	stackInfo *stackInfos; */
	void *pixels;
} PixelsRep;

typedef struct {
	char url[128];
	char sessionKey[128];
	
	CURL *curl;
} omeis;

/* External Functions */
omeis* openConnectionOMEIS (char* url, char* sessionKey);
OID newPixels (omeis* is, pixHeader* head);
pixHeader* pixelsInfo (omeis* is, OID pixelsID);
char* pixelsSHA1 (omeis *is, OID pixelsID);
int setPixels (omeis *is, OID pixelsID, void* pixels);
void* getPixels (omeis* is, OID pixelsID);
OID finishPixels (omeis* is, OID pixelsID);
char* getLocalPath (omeis *is, OID pixelsID);
int setROI (omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1, void* pixels);
void* getROI (omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1);
#endif