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
 * Written by:	Josiah Johnston <siah@nih.gov>    
 * 
 *------------------------------------------------------------------------------
 */

/******************************************************************************
*
*	maxIntensity.c
*	
*	Originally written: September 23, 2003
****

	Intent: To construct a maximum intensity projection from an OME repository
	file.

	Usage: Execute the program with no parameters to see the usage message. 
	alternately, look at the function printUsage

	Libraries: This program uses libtiff
	
	Other Dependencies:
	../perl2/OME/Image/Pix/libpix.c
	../perl2/OME/Image/Pix/libpix.h

	Other Notes: Outputs a binary file to the specified path

	Compilation notes: Assuming libtiff is installed at /sw/lib/, the one line
	compilation command is:

		gcc -L/sw/lib/ -ltiff maxIntensity.c \
		../../perl2/OME/Image/Pix/libpix.c -o maxIntensity

*
******************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../perl2/OME/Image/Pix/libpix.h"


void printUsage( int argc, char **argv );
char *get_param ( int argc, char **cgivars, char*param);


int main(int argc, char **argv) {
	
	/* variable declarations */
	Pix *pixReader;
	char *inPath, *outPath, *dims, *channel;
	FILE *outFile;
	int x, y, z, c, t, bpp;
	int theX, theY, theZ, theT, theC;
	int numInts;
	size_t rowSize, pixelSize, numPixelsInPlane, countsWritten;
	char *maxIntensity, *planeIterator;

	/* parse input parameters, perform validation */
	inPath = get_param (argc, argv,"InPath");
	if (!inPath) {
		fprintf (stderr,"Input Path parameter not set.\n");
		printUsage(argc,argv);
		exit (-1);
	}
	outPath = get_param (argc, argv, "OutPath");
	if (!outPath) {
		fprintf (stderr,"Output Path parameter not set.\n");
		printUsage(argc,argv);
		exit (-1);
	}
	dims = get_param (argc, argv, "Dims");
	if (!dims) {
		fprintf (stderr,"Dims parameter not set.\n");
		printUsage(argc,argv);
		exit (-1);
	}
	numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&x,&y,&z,&c,&t,&bpp);
	if (numInts < 6 || x < 1 || y < 1 || z < 1 || c < 1 || t < 1 || bpp < 1) {
		fprintf (stderr,"All 6 dimension sizes (X,Y,Z,C,T,NumBytes) must be > 0: #dims=%d, Dims=%s\n",numInts,dims);
		exit (-1);
	}
	channel = get_param (argc, argv, "ProjectionChannel");
	if (!dims) {
		fprintf (stderr,"Projection Channel parameter not set.\n");
		printUsage(argc,argv);
		exit (-1);
	}
	numInts = sscanf (channel,"%d",&theC);
	if (numInts < 1 || theC >= c ) {
		fprintf (stderr,"The channel index for the Projection Channel must be less than the maximum number of channels. ProjectionChannel=%d MaxChannel=%d\n",theC,c);
		exit (-1);
	}


	/* variable initialization */
	theZ = 0;
	theT = 0;
	pixelSize        = bpp;
	rowSize          = pixelSize * x;
	numPixelsInPlane = x * y;


	/* open files */
	outFile = fopen( outPath, "w" );
	if( outFile == NULL ) {
		fprintf( stderr, "Cannot open file '%s' for writing.\n", outPath );
		exit (-1);
	}

	pixReader = NewPix(	inPath, x, y, z, c, t, bpp );
	if( pixReader == NULL ) {
		fprintf( stderr, "Cannot initialize libpix reader on repository file %s.\n", inPath );
		exit (-1);
	}


	/* start chugging planes */
	maxIntensity = GetPlane( pixReader, theZ++, theC, theT );
	for( ; theT < t; theT++ ) {
		for( ; theZ < z; theZ++ ) {
			planeIterator = GetPlane( pixReader, theZ, theC, theT );
			for( theX = 0; theX < x; theX++ ) {
				for( theY = 0; theY < y; theY++ ) {
					/* if this pixel of maxIntesity is less than the corrosponding
					   pixel of planeIterator, then copy to maxIntensity. */
					if( memcmp( maxIntensity + theY * rowSize + theX * pixelSize, 
					            planeIterator + theY * rowSize + theX * pixelSize,
					            pixelSize ) < 0 ) {
						memcpy( maxIntensity + theY * rowSize + theX * pixelSize, 
					            planeIterator + theY * rowSize + theX * pixelSize,
					            pixelSize );
					}
				}
			}
			free( planeIterator );
		}
	}

	/* write maxIntensity to output file */
	countsWritten = fwrite( maxIntensity, pixelSize, numPixelsInPlane, outFile );

	free (maxIntensity);
	FreePix (pixReader);

	/* error checking */
	if( countsWritten != numPixelsInPlane ) {
		fprintf( stderr, "ERROR! Tried to write %zi pixels, actually wrote %zi.\n", numPixelsInPlane, countsWritten );
		return 1;
	}

	
	return 0;
}


void printUsage(int argc, char **argv) {
	fprintf( stderr, "Usage:\n" );
	fprintf( stderr, "%s InPath=/path/to/repository/file OutPath=/path/to/output/file Dims=X,Y,Z,W,T,BytesPerPixel ProjectionChannel=Channel\n", argv[0] );
}


char *get_param (int argc, char **argv, char *param)
{
	register int k;
	int paramLen;
	char *returnVal = NULL;

	paramLen = strlen( param );
	for(k=1; k<argc; k++){
		
		if( strstr(argv[k],param) ){
			returnVal = argv[k] + paramLen + 1;
			break;
		}
	}
	
	return returnVal;
}
