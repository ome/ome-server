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

/* typedef unsigned long long OID; */
typedef u_int64_t OID;
#define OME_IS_PIXL_SIG 0x5049584C /* PIXL in ASCII */
#define OME_IS_PIXL_VER 1  /* Version 1 */

typedef struct
{
	char  path[256];	/* Path to the input file for conversion */
	FILE *fp; /* This will be NULL if closed */
	int fd; /* This will be 0 if closed */
	int bp; /* bytes per pixel in the input file */
	char swapBytes; /* true if file's endian-ness doesn't match the machine's */
} convertFile;

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
	unsigned long dx,dy,dz,dc,dt; /* Pixel dimension extents */
	unsigned char bp;             /* bytes per pixel */
	unsigned char isSigned;       /* signed integers or not */
	unsigned char isFloat;        /* floating point or not */
	char reserved[31];            /* extra stuff to fill out to 64 bytes */
	unsigned long jump;           /* bytes to jump to the pixels (leaving room for stack and plane info)*/
} pixHeader;

typedef struct
{
	OID ID;
	char  path_ID[256];  /* Path to the ID file */
	char  path_rep[256];  /* Path to the repository-format file */
	char  path_info[256]; /* Path to the info header */
	int   fd_rep;   /* This will be < 0 when closed */
	int   fd_info;  /* This will be < 0 when closed */
	FILE *IO_stream;   /* One of these two should be set for reading/writing */
	void *IO_buf;
	unsigned long IO_buf_off; /* This keeps track of where we're writing in IO_buf */
	unsigned char swap_buf [4096];
	char doSwap;
	size_t num_pixels;
	size_t num_write;  /* number of pixels written */
	char error_str[256];
	convertFile inFile;
	off_t file_size;
	char is_mmapped;
	/* The rest is just like in the file */
	pixHeader *head;
	planeInfo *planeInfos;
	stackInfo *stackInfos;
	void *pixels;
} PixelsRep;

typedef struct {
	OID FileID;
	char isBigEndian;
	unsigned long file_offset;
	unsigned long pix_offset;
	unsigned long nPix;
} convertFileRec;



/*  CGI/CLI prototypes */
char *get_param (char **cgivars, char *param);
int inList(char **cgivars, char *str);
char x2c(char *what);
void unescape_url(char *url);
char **getcgivars(void);
char **getCLIvars(int argc, char **argv);
