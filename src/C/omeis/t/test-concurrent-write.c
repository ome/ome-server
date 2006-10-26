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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   3/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#define OMEIS_TEST_ROOT "OMEIS-TEST"
#include "../Pixels.h"
#include "../OMEIS_Error.h"

#define DX 3
#define DY 3
#define DZ 3
#define DC 1
#define DT 1
#define BP 4
#define IS_SIGNED 1
#define IS_FLOAT 1

int main (void)
{
int i;
OID *array;
size_t arr_size,npix,j;
PixelsRep *thePixels;
char command[256];
OID newID,finishID;
	
	if (chdir (OMEIS_TEST_ROOT)) {
		OMEIS_ReportError ("Initialization",NULL, (OID)0, "Could not change working directory to %s: %s",
			OMEIS_TEST_ROOT,strerror (errno));
		exit (-1);
	}

	arr_size = DX*DY*DZ*DC*DT*8;
	npix = DX*DY*DZ*DC*DT;
	array = malloc (arr_size);

	fork(); /* 2 */
	fork(); /* 4 */
	fork(); /* 8 */
	fork(); /* 16 */
	fork(); /* 32 */
	fork(); /* 64 */

	for (i=1; i<1000; i++) {
		OMEIS_ClearError();
		if (i % 100 == 0) {
			printf("pix %d\n", i);
			fflush (stdout);
		}

		thePixels = NewPixels (DX,DY,DZ,DC,DT,BP,IS_SIGNED,IS_FLOAT);
		if (! thePixels ) {
			OMEIS_ReportError ("test-concurrent-write", NULL, 0, "NewPixels failed.");
			exit (-1);
		}
		newID = thePixels->ID;

		for (j=0; j < npix; j++) {
			array[j] = rand();
		}


		thePixels->IO_buf = array;
		if ( DoPixelIO (thePixels, 0, npix, 'w') != npix ) {
			OMEIS_ReportError ("test-concurrent-write", NULL, 0, "Failure to write all pixels");
			exit (-1);
		}

		thePixels->IO_buf = NULL;
		

		if (! (finishID = FinishPixels (thePixels, 0)) ) {
			OMEIS_ReportError ("test-concurrent-write", NULL, 0, "Failure calling FinishPixels");
		}
//		if (newID != finishID) {
//			fprintf (stderr,"%20llu is a duplicate of %20llu\n",newID,finishID);
//		}

//		ExpungePixels (thePixels);
		freePixelsRep (thePixels);
	}

	free (array);
	return 1;
}
