/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */

#ifndef omeis_h
#define omeis_h

#include <sys/types.h>
#include "digest.h"


/* ----------- */
/* Definitions */
/* ----------- */

#define OME_IS_PIXL_SIG 0x5049584C /* PIXL in ASCII */
#define OME_IS_PIXL_VER 1  /* Version 1 */
#define MAXNAMELEN 256  /* There isn't really a portable way to retrieve this */

/* -------- */
/* Typedefs */
/* -------- */

/* OID */
typedef u_int64_t OID;

/* OME Coordinate */
typedef int32_t ome_coord;

/* OME Dimension */
typedef int32_t ome_dim;

typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y;
	char reserved[7]; /* reserved buffer (64 bytes total) */
} planeInfo;


typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y, centroid_z;
	char reserved[67]; /* reserved buffer (128 bytes total) */
} stackInfo;


typedef struct {
	unsigned long mySig;
	unsigned char vers;
	unsigned char isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	unsigned char bp;             /* bytes per pixel */
	unsigned char isSigned;       /* signed integers or not */
	unsigned char isFloat;        /* floating point or not */
	unsigned char sha1[OME_DIGEST_LENGTH]; /* SHA1 digest */
	char reserved[11];            /* buffer assuming OME_DIGEST_LENGTH=20 */
} pixHeader;

typedef struct
{
	OID ID;
	char  path_ID[256];  /* Path to the ID file */
	char  path_rep[256];  /* Path to the repository-format file */
	char  path_info[256]; /* Path to the info header */
	int   fd_rep;   /* This will be < 0 when closed */
	int   fd_info;  /* This will be < 0 when closed */
	size_t size_rep;
	size_t size_info;
	FILE *IO_stream;   /* One of these two should be set for reading/writing */
	void *IO_buf;
	unsigned long IO_buf_off; /* This keeps track of where we're writing in IO_buf */
	unsigned char swap_buf [4096];
	char doSwap;
	size_t num_pixels;
	size_t num_write;  /* number of pixels written */
	char error_str[256];
	char is_mmapped;
	/* The rest is just like in the file */
	pixHeader *head;
	planeInfo *planeInfos;
	stackInfo *stackInfos;
	void *pixels;
} PixelsRep;

typedef struct {
	char sha1[OME_DIGEST_LENGTH];
	char name[256];
} FileInfo;

typedef struct {
	OID ID;
	char path_ID[256];
	char path_rep[256];
	char path_info[256];
	int  fd_rep;
	int  fd_info;
	size_t size_rep;
	size_t size_info;
	char is_mmapped;
	FileInfo file_info;
	void *file_buf;
} FileRep;

typedef struct {
	ome_coord theZ, theC, theT;
} tiffConvertSpec;

typedef struct {
	unsigned long file_offset;
	unsigned long pix_offset;
	unsigned long nPix;
} fileConvertSpec;

typedef struct {
	OID FileID;
	char isBigEndian;
	char isTIFF;
	union {
		tiffConvertSpec tiff;
		fileConvertSpec file;
	} spec;
} convertFileRec;

typedef enum {
	GEOMEAN_BASIS, MEAN_BASIS, FIXED_BASIS
} levelBasisType;

typedef struct {
	int channel;
	int time; /* to know which stack statistics to use for the basis */
	float black, white, gamma;
	levelBasisType basis;
	float scale;  /* the computed scaling factor to multiply pixels by. */
	char isOn;
	char isFixed;
} channelSpecType;



/* ------------------- */
/* External Prototypes */
/* ------------------- */

void
byteSwap (unsigned char * theBuf,
		  size_t length,
		  char bp);

size_t
setPixelPlane (PixelsRep * thePixels,
		       void * buf,
			   int theZ,
			   int theC,
			   int theT);

int
FinishPixels (PixelsRep * myPixels,
		      char force);

int
bigEndian (void);

PixelsRep *
NewPixels (ome_dim dx,
		   ome_dim dy,
		   ome_dim dz,
		   ome_dim dc,
		   ome_dim dt,
		   ome_dim bp, /* bp is bytes per pixel */
		   char isSigned,
		   char isFloat);


off_t
GetOffset (PixelsRep *myPixels,
	int theX, int theY, int theZ, int theC, int theT);

void
ScalePixels (
	PixelsRep *myPixels, off_t offset, size_t nPix,
	unsigned char *buf, off_t jump,
	channelSpecType *chSpec);

void fixChannelSpec (PixelsRep *myPixels, channelSpecType *chSpec);

int GetFileInfo (FileRep *myFile);

char *get_param (char **cgivars, char *param);

char *get_lc_param (char **cgivars, char *param);

off_t GetOffset (PixelsRep *myPixels, int theX, int theY, int theZ, int theC, int theT);

void HTTP_DoError (char *method, char *template, ...);

void HTTP_ResultType (char *mimeType);



#endif /* omeis_h */
