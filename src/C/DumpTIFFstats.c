/*
  Author:  Ilya G. Goldberg (igg@mit.edu)
  Copyright 1999-2001 Ilya G. Goldberg
  This file is part of OME.
  
      OME is free software; you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation; either version 2 of the License, or
      (at your option) any later version.
  
      OME is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.
  
      You should have received a copy of the GNU General Public License
      along with OME; if not, write to the Free Software
      Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
  
 
*/

/*
* This program uses ReadTIFFData and libtiff to read a 16 bit TIFF file into a single
* continuous buffer, then rescale it to a 8 bits and dump the result into a raw image
* file.
* to run the program, compile it, link it to readTiffData.o and to libtiff:
cc readTiffData.c dump8bitTiff.c -ltiff -o dump8bitTiff
* then execute it:
dump8bitTiff a16bitTiffFile aRaw8bitTiffFile
* The program will read the file called a16bitTiffFile (or whatever name you provide)
* and create (or overwrite) a file called aRaw8bitTiffFile (or whatever name you provide),
* which contains the scaled 8 bit raw image.
*/


/*
* tiffio.h must be included to deal with TIFF.
*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <tiffio.h>


/*
* This is a prototype for ReadTIFFData
*/
int ReadTIFFData(TIFF* tif,unsigned char *buf);

/*
* In this case, we define a pixel as a signed short integer.
*/
typedef short pixel;


int main(int argc, char* argv[])
{
/*
* The following variables are required to deal with TIFF files:
*/
TIFF *tif;
uint32 width,height;
uint16 bits;
pixel *pixelBuf;
int error;

/*
* The following variables are used for this program only:
*/
pixel *pixelPtr,*maxIndex;
float sum_i=0.0,sum_i2=0.0,theVal, sd,min,max;
float sum_xi=0.0,sum_yi=0.0;
int x=0,y=0;
unsigned long numPix;


/*
* The following lines open a TIFF file, allocate an appropriately sized buffer to contain it,
* and read the TIFF file into the buffer with error checking.
*/

/*
* Get the tif file descriptor.
*/
	tif = TIFFOpen(argv[1],"r");
	if (!tif)
		{
		fprintf (stderr,"Could not open TIFF file %s\n",argv[1]);
		exit (-1);
		}

/*
* Determine the bits per pixel in this TIFF file.
*/
	TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bits);
	if (bits != 16)
		{
		fprintf (stderr,"Can only deal with 16 bits per pixel, not %d\n",bits);
		exit (-1);
		}

/*
* Get the width and height.
*/
	TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &height);
	numPix = width*height;
	fprintf (stderr,"Memory to read TIFF file: %4.1f Kb\n",
		 (float)(numPix*sizeof(pixel)) / 1024.0);

/*
* Allocate the buffer.
*/
	pixelBuf = (pixel *) malloc (numPix*sizeof(pixel));

	if (!pixelBuf)
		{
		fprintf (stderr,"Could not allocate sufficient memory to read TIFF file\n");
		exit (-1);
		}

/*
* Read the TIFF file.
*/
	error = ReadTIFFData (tif,(unsigned char *)pixelBuf);





/*
* Crunch through the pixels, putting stuff in various accumulators.
*/
	maxIndex = pixelBuf+numPix;
	min = max = *pixelBuf;
	for (pixelPtr = pixelBuf; pixelPtr < maxIndex;pixelPtr++)
		{
		theVal = (float) *pixelPtr;
		sum_xi += (theVal*x);
		sum_yi += (theVal*y);

		sum_i += theVal;
		sum_i2 += (theVal*theVal);
/*
* offset is used so that we don't compute logs of values less than or equal to zero.
*/
/* It was decreed that these damn logs take too freakin long, OK?
		sum_log_i +=  log (theVal+offset);
*/
		if (theVal < min) min = theVal;
		if (theVal > max) max = theVal;

		x++;
		if (x == width) {
			x = 0;
			y++;
		}
	}

/*
* Calculate the actual statistics from the accumulators
*/
	sd = sqrt ( (sum_i2	 - (sum_i * sum_i) / numPix)/  (numPix - 1.0) );
	fprintf (stdout,"min\tmax\tmean\tsigma\tsum_XI\tsumYI\tsum I\tsum I^2\n");
	fprintf (stdout,"%ld\t%ld\t%f\t%f\t%f\t%f\t%f\t%f\n",
		(long) min,(long) max,
		sum_i / numPix,
		(float) fabs (sd),
		sum_xi,sum_yi,sum_i,sum_i2
	);

/*
* Close up shop.
*/
	TIFFClose (tif);
	return (0);
}
