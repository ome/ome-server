/* Copyright (C) 2003 Open Microscopy Environment
 * Author:  Ilya G. Goldberg <igg@nih.gov>
 * 
 *     This library is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU Lesser General Public
 *     License as published by the Free Software Foundation; either
 *     version 2.1 of the License, or (at your option) any later version.
 *
 *     This library is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *     Lesser General Public License for more details.
 *
 *     You should have received a copy of the GNU Lesser General Public
 *     License along with this library; if not, write to the Free Software
 *     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
* DumpTIFFheader
*
* This program will output the TIFF header information in a format compatible with
* OME's TIFF import method.
* Specifically, the only things output here are the SizeX and SizeY - one per line, tab delimited:
* SizeX \t 123\n
* SizeY \t 456\n
* 
*/


/*
* tiffio.h must be included to deal with TIFF.
*/
#include <stdio.h>
#include <tiffio.h>


int main(int argc, char* argv[])
{
/*
* The following variables are required to deal with TIFF files:
*/
TIFF *tif;
uint32 width,height;
uint16 bits;

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

/*
* Print them out.
*/
	fprintf (stdout,"SizeX\t%ld\n",width);
	fprintf (stdout,"SizeY\t%ld\n",height);

/*
* Close up shop.
*/
	TIFFClose (tif);
	return (0);
}
