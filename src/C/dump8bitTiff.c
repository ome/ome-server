
/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
 * Written by:    Ilya G. Goldberg <igg@nih.gov>
 * 
 *------------------------------------------------------------------------------
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
#include <tiffio.h>


/*
* This is a prototype for ReadTIFFData
*/
int ReadTIFFData(TIFF* tif,unsigned char *buf);

/*
* In this case, we define a pixel as a signed short integer.
*/
typedef short pixel;


main(int argc, char* argv[])
{
/*
* The following variables are required to deal with TIFF files:
*/
TIFF *tif;
uint32 width,height;
uint16 bits;
int16 pixels;
pixel *pixelBuf;
int error;

/*
* The following variables are used for this program only:
*/
pixel *pixelPtr,*maxIndex;
pixel maxPix=-32760,minPix=32760,thePix;
unsigned char bytePix;
FILE *outFP;
float scale;


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

	fprintf (stderr,"Memory to read TIFF file: %d Kb\n",
		 (width*height*sizeof(pixel)) / 1024);

/*
* Allocate the buffer.
*/
	pixelBuf = (pixel *) malloc (width*height*sizeof(pixel));

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
* Determine the minimum and maximum pixel value.
*/
	maxIndex = pixelBuf+(width*height);	
	for (pixelPtr = pixelBuf; pixelPtr < maxIndex;pixelPtr++)
		{
		thePix = *pixelPtr;
		if (thePix < minPix)
			minPix = thePix;
		if (thePix > maxPix)
			maxPix = thePix;
		}

/*
* Open an output file.
*/
	outFP = fopen (argv[2],"w");
	if (!outFP)
		{
		fprintf (stderr,"Could not open file %s for writing 8 bit raw data\n",argv[2]);
		exit (-1);
		}

/*
* Determine the scale factor.
*/
	scale =  255.0 / ((float)maxPix-(float)minPix);
	fprintf (stdout,"width:  %d, height:  %d, min:  %d, max:  %d, scale:  %f\n",
		(int)width,(int)height,(int)minPix,(int)maxPix,scale);


/*
* Write the raw image, re-scaling the 16 bit pixels as we go.
*/
	for (pixelPtr = pixelBuf; pixelPtr < maxIndex;pixelPtr++)
		{
		bytePix = (unsigned char) ( (float)(*pixelPtr - minPix) * scale );
		putc ( (int)bytePix,outFP);
		}
	fclose (outFP);
}
