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
 * Written by:	Tom Macura <tmacura@nih.gov>   5/2004
 * 
 *------------------------------------------------------------------------------
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h> 
#include <ctype.h> 
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/param.h>

#include "Pixels.h"
#include "File.h"


/* driver that updates pixels from vers 2 to vers 3 */
int main (int argc, char **argv) {
OID theID=0;
PixelsRep *myPixels;
char iamBigEndian;
int theArg;
	
	iamBigEndian = bigEndian();
	
	if (argc < 2) {
 		fprintf (stderr,"Update Pixels files - Convert version 2 Pixels to version 3.\n");
 		fprintf (stderr,"Usage:\n%s path [PixelsID] [PixelsID]...\n",argv[0]);
 		fprintf (stderr,"  Where path is the OMEIS root (containing the Pixels directory)\n");
 		fprintf (stderr,"  If no PixelsID parameters are supplied, the entire repository will be updated.\n");
 		exit (-1); 
	} 

 	if (chdir (argv[1])) { 
 		char error[256]; 
		sprintf (error,"Could not change working directory to %s",argv[1]); 
 		perror (error); 
		exit (-1); 
 	} 
	 
 	theArg = 2; 
 	if (theArg < argc) {
		while (theArg < argc) {
 			theID = strtoull(argv[theArg], NULL, 10);
			if (theID != 0) GetFileRep (theID,0,0);
 			theArg++;
 		} 
 	} else {
 		myPixels = newPixelsRep (0LL);
		theID = lastID (myPixels->path_ID);
 		if (!theID) fprintf (stderr,"Couldn't get the last ID: %s\n",strerror (errno));
		freePixelsRep (myPixels);
		
 		while (theID) {
			fprintf(stdout, "Updating pixels ID = %d\n", theID);
			if (! (myPixels = GetPixelsRep (theID,'i',1)) ){
				fprintf(stderr, "Could not open pixels with ID=%d\n", theID);
				theID--;
				continue;
			}
			
			freePixelsRep (myPixels);
 			theID--;
 		} 
	}
 	return (1);
}
