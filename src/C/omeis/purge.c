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
#include "OMEIS_Error.h"
#include "omeis.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif


int main (int argc, char **argv) {
OID theID=0;
PixelsRep *myPixels;
char iamBigEndian;
int theArg;

	iamBigEndian = bigEndian();
	
	if (argc < 2) {
		fprintf (stderr,"Purge Pixels files - delete them if they are recoverable from the original File.\n");
		fprintf (stderr,"Usage:\n%s [PixelsID] [PixelsID]...\n",argv[0]);
		fprintf (stderr,"  If no PixelsID parameters are supplied, the entire repository will be purged.\n");
		exit (-1);
	}

	if (chdir (OMEIS_ROOT)) {
		OMEIS_ReportError ("OMEIS purge",NULL,(OID)0,"Could not change working directory to %s",
			OMEIS_ROOT);
		exit (-1);
	}
	
	theArg = 1;
	if (theArg < argc) {
		while (theArg < argc) {
			if (strrchr(argv[theArg],'/')) {
				theID = strtoull(strrchr(argv[theArg],'/')+1, NULL, 10);
			} else {
				theID = strtoull(argv[theArg], NULL, 10);
			}
			if (theID != 0) PurgePixels (theID);
			if (OMEIS_CheckError()) OMEIS_ReportError ("Purge","PixelsID",theID,"Purge failed");
			theArg++;
		}
	} else {
		myPixels = newPixelsRep (0LL);
		theID = lastID (myPixels->path_ID);
		if (!theID) fprintf (stderr,"Couldn't get the last ID: %s\n",strerror (errno));
		freePixelsRep (myPixels);
		while (theID) {
			OMEIS_ClearError();
			PurgePixels (theID);
			OMEIS_ReportError ("Purge","PixelsID",theID,"Purge failed");
			theID--;
		}
	}
	
	return (1);
}
