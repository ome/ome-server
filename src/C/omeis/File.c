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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   11/2003
 * 
 *------------------------------------------------------------------------------
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h> 
#include <ctype.h> 
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <limits.h>


#include "File.h"

void freeFileRep (FileRep *myFile)
{
	if (!myFile)
		return;

	if (myFile->is_mmapped) {
		munmap (myFile->file_buf, myFile->size_buf);
	}
	
	if (myFile->fd_info >=0 ) close (myFile->fd_info);
	if (myFile->fd_rep >=0 ) close (myFile->fd_rep);
	free (myFile);
}



FileRep *newFileRep (OID ID)
{
FileRep *myFile;
char *root="Files/";
char *filesIDfile="Files/lastFileID";
char *sha1DBfile="Files/sha1DB.idx";

	if (! (myFile =  (FileRep *)malloc (sizeof (FileRep)))  )
		return (NULL);
	myFile = memset(myFile, 0, sizeof(FileRep));
	
	strcpy (myFile->path_rep,root);
	strcpy (myFile->path_info,root);
	strcpy (myFile->path_ID,filesIDfile);
	strcpy (myFile->path_DB,sha1DBfile);


	/* file descriptors reset to -1 */
	myFile->fd_rep = -1;
	myFile->fd_info = -1;

	/* If we got an ID, set the paths */
	if (ID) {
		if (! getRepPath (ID,myFile->path_rep,0)) {
			fprintf (stderr,"Could not get path to files file.\n");
			freeFileRep (myFile);
			return (NULL);
		}
		myFile->ID = ID;
		strcpy (myFile->path_info,myFile->path_rep);
		strcat (myFile->path_info,".info");
	}
	
	return (myFile);
}


FileRep *GetFileRep (OID ID, size_t offset, size_t length)
{
FileRep *myFile;
struct stat fStat;

	if (!ID) return (NULL);

	if (! (myFile = newFileRep (ID))) {
		fprintf (stderr,"Could not get a File object.\n");
		return (NULL);
	}

	if ( (myFile->fd_rep = open (myFile->path_rep, O_RDONLY, 0600)) < 0) {
		freeFileRep (myFile);
		return (NULL);
	}

	/* Wait for a read lock */
	lockRepFile (myFile->fd_rep, 'r', offset, length);

	if (fstat (myFile->fd_rep, &fStat) < 0) {
		fprintf (stderr,"Could not get size of FileID=%llu",myFile->ID);
		freeFileRep (myFile);
		return (NULL);			
	}
	myFile->size_rep = fStat.st_size;

    if (length == 0)
        length = myFile->size_rep;

    if (offset+length > myFile->size_rep) {
        fprintf (stderr,"Trying to read past end of file\n");
        freeFileRep (myFile);
        return (NULL);
    }

    myFile->size_buf = myFile->size_rep;

	if ( (myFile->file_buf = (char *)mmap (NULL, myFile->size_rep, PROT_READ, MAP_SHARED, myFile->fd_rep, 0LL)) == (char *) -1 ) {
		fprintf (stderr,"Could not mmap FileID=%llu",myFile->ID);
		freeFileRep (myFile);
		return (NULL);			
	}
	myFile->is_mmapped = 1;

	return (myFile);
}


int DeleteFile (FileRep *myFile) {
	if (myFile->is_mmapped) munmap (myFile->file_buf, myFile->size_rep);
	if (myFile->fd_info >=0 ) close (myFile->fd_info);
	if (myFile->fd_rep >=0 ) close (myFile->fd_rep);
	
	if (myFile->path_rep) {
		chmod (myFile->path_rep,0600);
		unlink (myFile->path_rep);
	}
	if (myFile->path_info) {
		chmod (myFile->path_info,0600);
		unlink (myFile->path_info);
	}
	myFile->fd_info = -1;
	myFile->fd_rep = -1;
	myFile->is_mmapped = 0;
	myFile->file_buf = NULL;
	return (0);
}


/*
  NewFile makes a new repository File.
  The parameters are the filename and size
  A pointer to a new FileRep structure is returned
  The file is opened for writing, write-locked and mmapped.
*/

FileRep *NewFile (char *filename, size_t size)
{
FileRep *myFile;
char error[256];

	if ( size > UINT_MAX || size == 0) return NULL;  /* Bad mojo for mmap */

	if (! (myFile = newFileRep (0LL)) ) {
		perror ("BAH!");
		return (NULL);
	}
	myFile->ID = nextID(myFile->path_ID);
	if (myFile->ID <= 0 && errno) {
		perror ("Couldn't get next File ID");
		freeFileRep (myFile);
		return (NULL);
	} else if (myFile->ID <= 0){
		fprintf (stderr,"Happy New Year !!!\n");
		freeFileRep (myFile);
		return (NULL);
	}

	myFile->size_info = sizeof (FileInfo);
	myFile->fd_info = newRepFile (myFile->ID, myFile->path_info, myFile->size_info, "info");
	if (myFile->fd_info < 0) {
		sprintf (error,"Couldn't open repository info file for FileID %llu (%s).",myFile->ID,myFile->path_info);
		perror (error);
		freeFileRep (myFile);
		return (NULL);
	}
	
	myFile->size_rep = size;

	myFile->fd_rep = newRepFile (myFile->ID, myFile->path_rep, size, NULL);
	if (myFile->fd_rep < 0) {
		sprintf (error,"Couldn't open repository file for FileID %llu (%s).",myFile->ID,myFile->path_rep);
		perror (error);
		DeleteFile (myFile);
		freeFileRep (myFile);
		return (NULL);
	}

	if ( (myFile->file_buf = (char *)mmap (NULL, size, PROT_READ|PROT_WRITE , MAP_SHARED, myFile->fd_rep, 0LL)) == (char *) -1 ) {
		DeleteFile (myFile);
		fprintf (stderr,"Couldn't mmap File %s (ID=%llu)\n",myFile->path_rep,myFile->ID);
		freeFileRep (myFile);
		return (NULL);
	}
	
	if (filename)
		strncpy (myFile->file_info.name,filename,255);
	else
		strcpy (myFile->file_info.name,"");

	return (myFile);
}

int GetFileInfo (FileRep *myFile) {

	if ( (myFile->fd_info = open (myFile->path_info, O_RDONLY, 0600)) < 0) {
		return (-1);
	}

	if ( read (myFile->fd_info,(void *)&(myFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		return (-2);
	}

	close (myFile->fd_info);
	myFile->fd_info = -1;

	return (1);
}

/*
  Call this only to balance a call to NewFile()
*/
OID FinishFile (FileRep *myFile) {
OID existOID;

	/* Get SHA1 */
	if ( get_md_from_buffer (myFile->file_buf, myFile->size_rep, myFile->file_info.sha1) < 0 ) {
		DeleteFile (myFile);
		return (0);
	}
	
	/* Open the DB file if necessary */
	if (! myFile->DB)
		if (! (myFile->DB = sha1DB_open (myFile->path_DB)) ) {
			DeleteFile (myFile);
			return (0);
		}

	/* Check if SHA1 exists */
	if ( (existOID = sha1DB_get (myFile->DB, myFile->file_info.sha1)) ) {
		sha1DB_close (myFile->DB);
		myFile->DB = NULL;
		DeleteFile (myFile);
		myFile->ID = existOID;
		return (existOID);
	}

	if ( (myFile->fd_info = open (myFile->path_info, O_RDWR, 0600)) < 0) {
		DeleteFile (myFile);
		return (0);
	}

	if ( write (myFile->fd_info,(void *)&(myFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		DeleteFile (myFile);
		return (0);
	}

	close (myFile->fd_info);
	myFile->fd_info = -1;

	if (myFile->is_mmapped) {
		if (msync (myFile->file_buf , myFile->size_rep , MS_SYNC) != 0) {
			DeleteFile (myFile);
			return (0);
		}
		munmap (myFile->file_buf, myFile->size_rep);
		myFile->file_buf = NULL;
		myFile->is_mmapped = 0;
	}	

	if (myFile->fd_rep >=0 ) {
		lockRepFile (myFile->fd_rep,'u',0LL,0LL);
		close (myFile->fd_rep);
		myFile->fd_rep = -1;
	}

	/* put the SHA1 in the DB */
	if ( sha1DB_put (myFile->DB, myFile->file_info.sha1, myFile->ID) ) {
		sha1DB_close (myFile->DB);
		myFile->DB = NULL;
		DeleteFile (myFile);
		return (0);
	}

	/* Close the DB (and release the exclusive lock) */
	sha1DB_close (myFile->DB);
	myFile->DB = NULL;


	chmod (myFile->path_info,0400);
	chmod (myFile->path_rep,0400);

	
	return (myFile->ID);
}



/*
  UploadFile (char *filename, size_t size)
  Makes new rep file in 'Files' of the specified size.
  copies filename parameter to OID.info
  Reads stdin, writing to the file.
  returns file OID.
*/
OID UploadFile (char *filename, size_t size, unsigned char isLocalFile) {
OID ID;
FileRep *myFile;
size_t nIO;
FILE *infile;

	if (  !(myFile = NewFile(filename, size )) ) return 0;
	ID = myFile->ID;

    infile = openInputFile(filename,isLocalFile);

    if (infile) {
        nIO = fread (myFile->file_buf,1,size,infile);
        if (nIO != size) {
            fprintf (stderr,"Couldn't finish writing uploaded file %s (ID=%llu).  Wrote %lu, expected %lu\n",
                     filename,ID,(unsigned long)nIO,(unsigned long)size);
            DeleteFile (myFile);
			freeFileRep (myFile);
	        }
    }

	ID = FinishFile (myFile);
	freeFileRep (myFile);
	closeInputFile (infile,isLocalFile);
	return (ID);
}
