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
char beSilent = 0, doQuery = 0;
OID thePixID=0,theFileID=0, theID=0;
PixelsRep *myPixels;
FileRep *myFile;
int theArg;
int pix_vers_fd, file_vers_fd;
char pix_vers_path[OMEIS_PATH_SIZE], file_vers_path[OMEIS_PATH_SIZE];
int pix_vers=0, file_vers=0;
char pix_vers_str[256], file_vers_str[256];
		
	
	if (argc > 1) {
		/* Can't be both silent and ask questions */
		if ( !strcmp(argv[1],"-s") ) beSilent = 1;
		/*
		  Query.  Does OMEIS need updating?  Returns strings of the following form:
		  [Update] Component [old vers ->] new vers
		  Files 3
		  Update Files 2 -> 3
		  Pixels 4
		  Update Pixels 0 -> 4
		  Note that 0 is 'undefined'
		*/
		if ( !strcmp(argv[1],"-q") ) doQuery = 1; 
	}

	if (chdir (OMEIS_ROOT)) {
		if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not change working directory to %s",
			OMEIS_ROOT);
		exit (-1);
	}

	
	/*
	  Get the Pixels version and the last used PixelsID
	*/
	if ( !(myPixels = newPixelsRep (0LL)) ) {
		if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not get a new PixelsRep");
		exit (-1);
	}
	thePixID = lastID (myPixels->path_ID);
	/* with a NULL ID, path_rep is set to the root with trailing slash */
	sprintf (pix_vers_path,"%sVERSION",myPixels->path_rep);
	freePixelsRep (myPixels);

	if ( (pix_vers_fd = open (pix_vers_path, O_RDWR|O_CREAT, 0600)) < 0 ) {
		if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not open version file %s",pix_vers_path);
		exit (-1);
	}
	lockRepFile (pix_vers_fd, 'w', (size_t)0, (size_t)0);
	
	/*
	  If we got a 0 for the lastID, then its a brand-new repository.
	  We write the current version into it.
	*/
	if (thePixID == 0) {
		sprintf (pix_vers_str,"%d\n",OME_IS_PIXL_VER);
		write ( pix_vers_fd,(void *)pix_vers_str,strlen(pix_vers_str) );
		pix_vers = OME_IS_PIXL_VER;
	} else {
		read ( pix_vers_fd, (void *)pix_vers_str, sizeof(pix_vers_str) );
		sscanf (pix_vers_str,"%d",&pix_vers);
	}
	close (pix_vers_fd);

	/*
	  Get the File version and the last used FileID
	*/
	if ( !(myFile = newFileRep (0LL)) ) {
		if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not get a new FileRep");
		exit (-1);
	}
	theFileID = lastID (myFile->path_ID);
	/* with a NULL ID, path_rep is set to the root with trailing slash */
	sprintf (file_vers_path,"%sVERSION",myFile->path_rep);
	freeFileRep (myFile);

	if ( (file_vers_fd = open (file_vers_path, O_RDWR|O_CREAT, 0600)) < 0 ) {
		if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not open version file %s",file_vers_path);
		exit (-1);
	}
	lockRepFile (file_vers_fd, 'w', (size_t)0, (size_t)0);
	
	/*
	  If we got a 0 for the lastID, then its a brand-new repository.
	  We write the current version into it.
	*/
	if (theFileID == 0) {
		sprintf (file_vers_str,"%d\n",OME_IS_FILE_VER);
		write ( file_vers_fd,(void *)file_vers_str,strlen(file_vers_str) );
		file_vers = OME_IS_FILE_VER;
	} else {
		read ( file_vers_fd, (void *)file_vers_str, sizeof(file_vers_str) );
		sscanf (file_vers_str,"%d",&file_vers);
	}
	close (file_vers_fd);

	

	/*
	  Print out what we got and return if we're just doing a query
	*/
	if (doQuery) {
		if (pix_vers != OME_IS_PIXL_VER) fprintf (stdout,"Update Pixels %d -> %d\n",pix_vers,OME_IS_PIXL_VER);
		else fprintf (stdout,"Pixels %d\n",OME_IS_PIXL_VER);

		if (file_vers != OME_IS_FILE_VER) fprintf (stdout,"Update Files %d -> %d\n",file_vers,OME_IS_FILE_VER);
		else fprintf (stdout,"Files %d\n",OME_IS_FILE_VER);

		return (0);
	}


	/*
	  Process Pixels
	*/
	if (pix_vers == OME_IS_PIXL_VER) {
		if (!beSilent) fprintf(stdout, "Pixels repository is up to date (version = %d)\n", pix_vers);
	} else {
		if (!beSilent) fprintf(stdout, "Updating Pixels 1 to %llu\n", (unsigned long long)thePixID);
		for (theID=1; theID <= thePixID; theID++) {
			if (!beSilent) fprintf(stdout, "\r%25llu", (unsigned long long)theID);
			fflush (stdout);
			if ( (myPixels = GetPixelsRep (theID,'i',1)) ){
				freePixelsRep (myPixels);
			}		
		}
		if (!beSilent) fprintf(stdout, "\nSuccessfully updated Pixels in OMEIS\n");
	
		if ( (pix_vers_fd = open (pix_vers_path, O_RDWR, 0600)) < 0 ) {
			if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not open version file %s for writing",pix_vers_path);
			exit (-1);
		}
		lockRepFile (pix_vers_fd, 'w', (size_t)0, (size_t)0);

		sprintf (pix_vers_str,"%d\n",OME_IS_PIXL_VER);
		write ( pix_vers_fd,(void *)pix_vers_str,strlen(pix_vers_str) );
		close (pix_vers_fd);
	}
	

	/*
	  Process Files
	*/
	if (file_vers == OME_IS_FILE_VER) {
		if (!beSilent) fprintf(stdout, "Files repository is up to date (version = %d)\n", file_vers);
	} else {
		if (!beSilent) fprintf(stdout, "Updating Files 1 to %llu\n", (unsigned long long)theFileID);
		for (theID=1; theID <= theFileID; theID++) {
			if (!beSilent) fprintf(stdout, "\r%25llu", (unsigned long long)theFileID);
			fflush (stdout);
			if ( (myFile = GetFileRep (theID,'i',1)) ){
				freeFileRep (myFile);
			}		
		}
		if (!beSilent) fprintf(stdout, "\nSuccessfully updated Files in OMEIS\n");
	
		if ( (file_vers_fd = open (file_vers_path, O_RDWR, 0600)) < 0 ) {
			if (!beSilent) OMEIS_ReportError ("UpdateOMEIS",NULL,(OID)0,"Could not open version file %s for writing",file_vers_path);
			exit (-1);
		}
		lockRepFile (file_vers_fd, 'w', (size_t)0, (size_t)0);

		sprintf (file_vers_str,"%d\n",OME_IS_FILE_VER);
		write ( file_vers_fd,(void *)file_vers_str,strlen(file_vers_str) );
		close (file_vers_fd);
	}


 	return (0);
}
