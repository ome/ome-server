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
 * Written by:	Ilya Goldberg <igg@nih.gov> 7/2004
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
#include "OMEIS_Error.h"
#include "omeis.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif



/* driver that updates pixels from vers 2 to vers 3 */
int main (int argc, char **argv) {
OID theID=0;
PixelsRep *myPixels;
int theArg;
int vers_fd;
char vers_path[OMEIS_PATH_SIZE];
int version;
char version_str[256];
		
	if (chdir (OMEIS_ROOT)) {
		OMEIS_ReportError ("UpdatePixels",NULL,(OID)0,"Could not change working directory to %s",
			OMEIS_ROOT);
		exit (-1);
	}
	
	if ( !(myPixels = newPixelsRep (0LL)) ) {
		OMEIS_ReportError ("UpdatePixels",NULL,(OID)0,"Could not get a new PixelsRep");
		exit (-1);
	}
	theID = lastID (myPixels->path_ID);
	/* with a NULL ID, path_rep is set to the root with trailing slash */
	sprintf (vers_path,"%sVERSION",myPixels->path_rep);
	freePixelsRep (myPixels);

	if ( (vers_fd = open (vers_path, O_RDWR|O_CREAT, 0600)) < 0 ) {
		OMEIS_ReportError ("UpdatePixels",NULL,(OID)0,"Could not open version file %s",vers_path);
		exit (-1);
	}
	read ( vers_fd, (void *)version_str, sizeof(version_str) );
	sscanf (version_str,"%d",&version);
	close (vers_fd);
	if (version == OME_IS_PIXL_VER) {
		fprintf(stdout, "Pixels repository is up to date (version = %d)\n", version);
		return (0);
	}
	

	
	fprintf(stdout, "Updating pixels 1 to %llu\n", (unsigned long long)theID);
	while (theID) {
		fprintf(stdout, "\r%25llu", (unsigned long long)theID);
		fflush (stdout);
		if ( (myPixels = GetPixelsRep (theID,'i',1)) ){
			freePixelsRep (myPixels);
		}		
		theID--;
	}
	fprintf(stdout, "\nSuccessfully updated Pixels in OMEIS\n");

	if ( (vers_fd = open (vers_path, O_RDWR, 0600)) < 0 ) {
		OMEIS_ReportError ("UpdatePixels",NULL,(OID)0,"Could not open version file %s for writing",vers_path);
		exit (-1);
	}
	sprintf (version_str,"%d\n",OME_IS_PIXL_VER);
	write ( vers_fd,(void *)version_str,strlen(version_str) );
	close (vers_fd);

 	return (0);
}
