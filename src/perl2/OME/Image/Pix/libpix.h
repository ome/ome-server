/*
# OME/Image/Pix/pixlib/GetPix.h

# Copyright (C) 2002 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


typedef struct
{
	char  path[256];	/* Path to the input file for conversion */
	FILE *fp; /* This will be NULL if closed */
	int bp; /* bytes per pixel in the input file */
	char swapBytes; /* true if file's endian-ness doesn't match the machine's */
} convertFile;

typedef struct
{
	char  path[256];	    /* Path to the repository-format file */
	int  dx,dy,dz,dw,dt,bp; /* Image dimensions bp is bytes per pixel */
	size_t num_pixels;
	convertFile inFile;
	FILE *rep_file;  /* This will be NULL when closed */
	char rep_write;  /* true if the file is open for writing */
	size_t num_write;  /* number of pixels written */
} Pix;



Pix *NewPix      (char* path, int dx, int dy, int dz, int dw, int dt, int bp);

void FreePix  (Pix *pPix);

char *GetPixels (Pix *pPix);
char *GetPlane (Pix *pPix, int theZ, int theW, int theT);
char *GetStack (Pix *pPix, int theW, int theT);
char *GetROI (Pix *pPix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
);

size_t SetPixels (Pix *pPix, char *thePix);
size_t SetPlane (Pix *pPix, char *thePix, int theZ, int theW, int theT);
size_t SetStack (Pix *pPix, char *thePix, int theW, int theT);
size_t SetROI (Pix *pPix, char *thePix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
);
void pixFinish (Pix *pPix);



size_t Plane2TIFF (Pix *pPix, int theZ, int theW, int theT, char *path);
size_t Plane2TIFF8 (Pix *pPix, int theZ, int theW, int theT, char *path, double scale, double offset);

int setConvertFile (Pix *pPix, char *inPath, int bp, int bigEndian);
size_t convertRow (Pix *pPix, size_t offset, int theY, int theZ, int theW, int theT);
size_t convertRows (Pix *pPix, size_t offset, int nRows, int theY, int theZ, int theW, int theT);
size_t convertPlane (Pix *pPix, size_t offset, int theZ, int theW, int theT);
size_t convertStack (Pix *pPix, size_t offset, int theW, int theT);
void convertFinish (Pix *pPix);

void byteSwap2 (char *theBuf, size_t length);
void byteSwap4 (char *theBuf, size_t length);
void byteSwap8 (char *theBuf, size_t length);
void byteSwap16 (char *theBuf, size_t length);

/* PRIVATE methods */
FILE *GetPixFileUpdate (Pix *pPix);
FILE *GetPixFile (Pix *pPix);
size_t Buff2Tiff (char *buf, char *path, size_t dx, size_t dy, size_t bpp);
char *ScaleBuf8 (char *theBuf, int bp, size_t nPix, float scale, int offset);
size_t WriteRepFile (Pix *pPix, char *thePix, size_t offset, size_t nPix);
int bigEndian();

