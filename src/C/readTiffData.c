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
* ReadTIFFData
* 
* PROTOTYPE:
int ReadTIFFData(TIFF* tif,unsigned char *buf)
* PURPOSE:
* This routine will read a multi-stripped (or not), compressed (or not), 8 (or 16)
* bits-per-pixel TIFF file (big or little-endian)
* into a single contiguous buffer using libtiff.
* This routine WILL NOT READ:
* TIFF files that are tiled.
* TIFF files that contain more than one sample per pixel or more than one plane of pixels.
* PARAMETERS:
* TIFF *tif - pointer to a TIFF structure as returned by TIFFOpen.
* unsigned char *buf - pointer to a pre-allocated buffer that is large enough
*	to contin the entire TIFF file.
* USAGE:
* you will need to:
#include <tiffio.h>
* This will define TIFF tags, and declare i/o routines from libtiff.
* To get the tif, call:
	tif = TIFFOpen(filename,"r")
		filename is a string containing the filename (just like fopen())
		"r" for reading, "w" for writing, and "a" for appending.
		man TIFFOpen for more details.
* To determine the size of the TIFF file, call:
	TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bits);
	TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &height);
		bits is an uint16.
		width and height are uint32.
		This function, types and #defines are defined in tiffio.h
* Allocate an appropriately sized buffer to contain the TIFF file
* For example if reading 16-bit TIFFs,
	buf = (unsigned short *)malloc (width*height*sizeof(unsigned short));
	or, using the portable TIFF memory allocation:
	buf = (unsigned short *)_TIFFmalloc(width*height*sizeof(unsigned short));
* Call ReadTIFFData:
	error = ReadTiffData (tif,(unsigned char *)buf);
* Do whatever it is you want to the buffer, then call
	free (buf)
*	or, if used _TIFFmalloc, call
	_TIFFfree(buf);
* Note that although the buffer passed to ReadTIFFData must be of type unisigned char,
* this is only because the functions therein deal only in bytes.  They will handle
* 16 bit pixels just fine, though.
* ERROR CODES:
* -1 buf is NULL
* -2 TIFF is tiled.
* -3 TIFF is less than 8 bits/pixel.
* -4 TIFF has more than one plane or more than one sample/pixel.
* -5 Problem reading strips (error in libtiff's TIFFReadEncodedStrip).
*  0 no errors.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <tiffio.h>
#include "readTIFF.h"




int
TIFFReadContigStripData(TIFF* tif,unsigned char *buf)
{
	tsize_t scanline = TIFFScanlineSize(tif);


	if (buf)
		{
		uint32 row, h;
		uint32 rowsperstrip = (uint32)-1;

		TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
		TIFFGetField(tif, TIFFTAG_ROWSPERSTRIP, &rowsperstrip);
		for (row = 0; row < h; row += rowsperstrip)
			{
			uint32 nrow = (row+rowsperstrip > h ?
			    h-row : rowsperstrip);
			tstrip_t strip = TIFFComputeStrip(tif, row, 0);
			if (TIFFReadEncodedStrip(tif, strip, buf, nrow*scanline) < 0)
				return (-1);
			buf += (nrow * scanline);
			}
		}
		return (0);
}











int ReadTIFFData(TIFF* tif,unsigned char *buf)
{
	uint16 config;
	uint16 bits;
	char pixelBytes;

/*
* if buf isn't a valid pointer, return immediately.
*/
	if (!buf)
		return (-1);

/*
* We don't deal with tiled data.
*/
	if (TIFFIsTiled(tif))
		return (-2);

	TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bits);

/*
* We don't deal with less than 8 bits/pixel.
*/
	if (bits < 8)
		return (-3);

	pixelBytes = bits / 8;


/*
* We don't deal with non-contiguous data - samples per pixel should be 1
*/
	TIFFGetField(tif, TIFFTAG_PLANARCONFIG, &config);
	if (config != PLANARCONFIG_CONTIG)
		return (-4);



/*
* Read the strips.
*/
	if (TIFFReadContigStripData(tif,buf) < 0)
		return (-5);

/*
* Return a pointer to the buffer.
*/
	return (0);
}






int WriteTIFFData (char *file,unsigned char *buf,int bufbps,int rows, int cols) {
TIFF* tiff;
uint32 row;
uint32 rowsperstrip = (uint32)-1;
tsize_t scanline;
	
		
	tiff = TIFFOpen(file,"w");
	if (!tiff ) return -6;
	
	TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, bufbps);
	TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, 1);
	if (! TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW) )
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_NONE);
	TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	

	TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, cols);
	TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, rows);
	rowsperstrip = TIFFDefaultStripSize(tiff,0);
	TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, rowsperstrip);

	scanline = TIFFScanlineSize(tiff);

	for (row = 0; row < rows; row += rowsperstrip)
		{
		uint32 nrow = (row+rowsperstrip > rows ?
			rows-row : rowsperstrip);
		tstrip_t strip = TIFFComputeStrip(tiff, row, 0);
		if (TIFFWriteEncodedStrip(tiff, strip, buf, nrow*scanline) < 0) {
			TIFFClose (tiff);
			return (-8);
		}
		buf += (nrow * scanline);
		}
	TIFFClose (tiff);
	return (0);
}









char *GetReadTIFFError (int errNum, char *errMsg)
{


	switch (errNum)
	{
	case -1:
		strcpy (errMsg,"Buffer for reading TIFF was NULL.");
	break;
	case -2:
		strcpy (errMsg,"TIFF file is tiled - cannot read a tiled TIFF file.");
	break;
	case -3:
		strcpy (errMsg,"Pixels in TIFF file have less than 8 bits/pixel.");
	break;
	case -4:
		strcpy (errMsg,"TIFF has more than one plane or more than one sample/pixel.");
	break;
	case -5:
		strcpy (errMsg,"Problem reading strips (error in libtiff's TIFFReadEncodedStrip).");
	break;

	case -6:
		strcpy (errMsg,"Could not open file for writing.");
	break;
	case -7:
		strcpy (errMsg,"tiff bits-per-sample must be >=8 and divisible by 8.");
	break;
	case -8:
		strcpy (errMsg,"Problem writing strips (error in libtiff's TIFFWriteEncodedStrip).");
	break;

	case 0:
		strcpy (errMsg,"");
	break;
	}
	
	return (errMsg);
}

