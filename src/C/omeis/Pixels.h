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

#ifndef Pixels_h
#define Pixels_h

#include <sys/types.h>
#include "digest.h"
#include "repository.h"
#include "sha1DB.h"
#include "File.h"


/* ----------- */
/* Definitions */
/* ----------- */

#define OME_IS_PIXL_SIG 0x5049584C /* PIXL in ASCII */
#define OME_IS_PIXL_VER 3   /* Version 3. Change from version 2 to version 3: */
							/* histogram computation added breaking binary compatibility */
#define NUM_BINS 128 /* NUM_BINS is the number of bins used in binning the image histogram */
                     /* N.B: Modifying value breaks binary compatibility */
                     
/* -------- */
/* Typedefs */
/* -------- */

/* OME Coordinate */
typedef int32_t ome_coord;

/* OME Dimension */
typedef int32_t ome_dim;

typedef struct
{
	u_int8_t stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y;
	u_int32_t hist[NUM_BINS];
	u_int8_t reserved[7]; /* reserved buffer (64 bytes total) */
} planeInfo;


typedef struct
{
	u_int8_t stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y, centroid_z;
	u_int32_t hist[NUM_BINS];
	u_int8_t reserved[67]; /* reserved buffer (128 bytes total) */
} stackInfo;

typedef struct {
	u_int32_t mySig;
	u_int8_t vers;
	u_int8_t isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	u_int8_t bp;             /* bytes per pixel */
	u_int8_t isSigned;       /* signed integers or not */
	u_int8_t isFloat;        /* floating point or not */
	u_int8_t sha1[OME_DIGEST_LENGTH]; /* SHA1 digest */
	u_int8_t reserved[15];   /* buffer to 64 (60?)assuming OME_DIGEST_LENGTH=20 */
} pixHeader;

typedef struct
{
	OID ID;
	char  path_ID[OMEIS_PATH_SIZE];  /* Path to the ID file */
	char  path_rep[OMEIS_PATH_SIZE];  /* Path to the repository-format file */
	char  path_info[OMEIS_PATH_SIZE]; /* Path to the info header */
	char  path_conv[OMEIS_PATH_SIZE]; /* Path to the info header */
	char  path_DB[OMEIS_PATH_SIZE];    /* Path to the sha1 DB */
	int   fd_rep;   /* This will be < 0 when closed */
	int   fd_info;  /* This will be < 0 when closed */
	int   fd_conv;  /* This will be < 0 when closed */
	DB    *DB;      /* sha1 DB returned from sha1DB_open() (as returned by dbopen()) */
	size_t size_rep;
	size_t size_info;
	FILE *IO_stream;   /* One of these two should be set for reading/writing */
	void *IO_buf;
	unsigned long IO_buf_off; /* This keeps track of where we're writing in IO_buf */
	unsigned char swap_buf [OMEIS_IO_BUF_SIZE];
	char doSwap;
	size_t num_pixels;
	size_t num_write;  /* number of pixels written */
	char is_mmapped;
	/* The rest is just like in the file */
	pixHeader *head;
	planeInfo *planeInfos;
	stackInfo *stackInfos;
	void *pixels;
} PixelsRep;

typedef struct {
	ome_coord theZ, theC, theT;
	u_int32_t dir_index;
	u_int64_t pad2;
} tiffConvertSpec;

typedef struct {
	u_int64_t file_offset;
	u_int64_t pix_offset;
	u_int64_t nPix;
} fileConvertSpec;

typedef struct {
	OID FileID;
	u_int8_t isBigEndian;
	u_int8_t isTIFF;
	u_int8_t pad1[6];  /* 64-bit aligned for the next part. */
	union {
		tiffConvertSpec tiff;
		fileConvertSpec file;
	} spec;
	u_int8_t reserved[24]; /* reserved buffer (64 bytes total) */
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

size_t
setPixelPlane (PixelsRep * thePixels,
		       void * buf,
			   int theZ,
			   int theC,
			   int theT);

size_t
getPixelPlane (PixelsRep * thePixels,
		       void * buf,
			   int theZ,
			   int theC,
			   int theT);

OID
FinishPixels (PixelsRep * myPixels,
		      char force);

PixelsRep *
NewPixels (ome_dim dx,
		   ome_dim dy,
		   ome_dim dz,
		   ome_dim dc,
		   ome_dim dt,
		   ome_dim bp, /* bp is bytes per pixel */
		   char isSigned,
		   char isFloat);

PixelsRep *newPixelsRep (OID ID);

void
freePixelsRep (PixelsRep *myPixels);

PixelsRep *
GetPixelsRep (OID ID, char rorw, char isBigEndian);

void
PurgePixels (OID myID);

int
isConvertVerified (PixelsRep *myPixels);

int
recoverPixels (PixelsRep *myPixels, int open_flags, int mmap_flags, char verify);

void
ScalePixels (
	PixelsRep *myPixels, size_t offset, size_t nPix,
	unsigned char *buf, size_t jump,
	channelSpecType *chSpec);

void
fixChannelSpec (PixelsRep *myPixels, channelSpecType *chSpec);

int
CheckCoords (PixelsRep * myPixels,
             ome_coord theX,
             ome_coord theY,
             ome_coord theZ,
             ome_coord theC,
             ome_coord theT);

size_t
GetOffset (PixelsRep *myPixels, int theX, int theY, int theZ, int theC, int theT);

size_t
DoPixelIO (PixelsRep *myPixels, size_t offset, size_t nPix, char rorw);

size_t
DoROI (PixelsRep *myPixels,
	ome_coord X0, ome_coord Y0, ome_coord Z0, ome_coord W0, ome_coord T0,
	ome_coord X1, ome_coord Y1, ome_coord Z1, ome_coord W1, ome_coord T1,
	char rorw);


size_t
ConvertTIFF (
	PixelsRep *myPixels,
	FileRep   *myFile,
	ome_coord theZ,
	ome_coord theC,
	ome_coord theT,
	unsigned long tiffDir,
	char writeRec);

size_t
ConvertFile (
	PixelsRep *myPixels,
	FileRep   *myFile,
	size_t     file_offset,
	size_t     pix_offset,
	size_t     nPix,
	char       writeRec);


int FinishStats (PixelsRep *myPixels, char force);



#endif /* Pixels_h */
