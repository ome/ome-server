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
#include "OMEIS_Error.h"

/* Private prototypes */
int update_file_info (FileRep *myFile);
OID check_aliases (OID ID, const char *name);
int make_alias (OID ID,FileRep *aliasFile);
char *get_rel_path (const char *toPath, const char *fromPath, char *pathBuf);


void freeFileRep (FileRep *myFile)
{
	if (!myFile)
		return;

	if (myFile->is_mmapped) {
		munmap (myFile->file_buf, myFile->size_buf);
	}
	
	if (myFile->fd_info >=0 ) close (myFile->fd_info);
	if (myFile->fd_rep >=0 )  close (myFile->fd_rep);
	
	if (myFile->aliases) free (myFile->aliases);
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
			OMEIS_DoError ("Could not get path for FIleID=%llu: %s",
				(unsigned long long)ID,strerror (errno));
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
		OMEIS_DoError ("Could not get a File object (no memory).");
		return (NULL);
	}

	if ( (myFile->fd_rep = openRepFile (myFile->path_rep, O_RDONLY)) < 0) {
		freeFileRep (myFile);
		OMEIS_DoError ("Could not open repository file (FileID = %llu: %s", (unsigned long long)ID,strerror( errno ));
		return (NULL);
	}

	/* Wait for a read lock */
	lockRepFile (myFile->fd_rep, 'r', offset, length);

	if (fstat (myFile->fd_rep, &fStat) < 0) {
		OMEIS_DoError ("Could not get size of FileID=%llu",(unsigned long long)myFile->ID);
		freeFileRep (myFile);
		return (NULL);			
	}
	myFile->size_rep = fStat.st_size;

    if (length == 0)
        length = myFile->size_rep;

    if (offset+length > myFile->size_rep) {
        OMEIS_DoError ("Trying to read past end of FileID=%llu",(unsigned long long)myFile->ID);
        freeFileRep (myFile);
        return (NULL);
    }

    myFile->size_buf = myFile->size_rep;

	if ( (myFile->file_buf = mmap (NULL, myFile->size_rep, PROT_READ, MAP_SHARED, myFile->fd_rep, 0LL)) == (void *) -1 ) {
		OMEIS_DoError ("Could not mmap FileID=%llu",(unsigned long long)myFile->ID);
		freeFileRep (myFile);
		return (NULL);			
	}
	myFile->is_mmapped = 1;

	return (myFile);
}

/*
  This deletes the file and its ".info" companion, but it does not delete the file's
  digest from the SHA1 => ID database.
  Call ExpungeFile to delete all records of the file.
*/
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


int ExpungeFile (FileRep *myFile) {
int i;
int numBytes; 
OID existOID;

	/* Get the file's info and SHA1 database*/
	GetFileInfo (myFile);
	GetFileAliases (myFile);
	
	if (! myFile->DB)	
		/* if we can't get its SHA1 entry thats really bad */
		if (! (myFile->DB = sha1DB_open (myFile->path_DB)) ) {
			DeleteFile (myFile);
			return (0);
		}
	
	/* check to see if the file hasAlias or isAlias */
	if ( myFile->file_info.isAlias == 0 && myFile->file_info.nAliases == 0 ){ 
	
		/* CASE 1: file has no alias buddies */
		
		/* remove SHA1 entry if it exists */
		if ( existOID = sha1DB_get (myFile->DB, myFile->file_info.sha1) ) {
			sha1DB_del (myFile->DB, myFile->file_info.sha1);
		}
	} else if ( myFile->file_info.isAlias != 0 ) {
		/* CASE 2: file has a representive file. This file is only a symbolic link */
		
		/* open the representive file based on OID */
		FileRep *myRepFile = newFileRep(myFile->file_info.isAlias);
		GetFileInfo (myRepFile);
		GetFileAliases (myRepFile);
							
		/* remove references in the representive file to this alias file  */
		for (i=0; i<myRepFile->file_info.nAliases; i++)
			if (myRepFile->aliases[i].ID == myFile->file_info.ID) {
				myRepFile->aliases[i].ID = myRepFile->aliases[myRepFile->file_info.nAliases-1].ID;
				strncpy(myRepFile->aliases[i].name, myRepFile->aliases[myRepFile->file_info.nAliases-1].name, OMEIS_PATH_SIZE);
				break;
			}
		(myRepFile->file_info.nAliases)--;
		
		/* chmod and reopen repfile's info with exclusive (destructive) write access */
		chmod (myRepFile->path_info,0600);
		if (myRepFile->fd_info >= 0) close (myRepFile->fd_info);
		
		if ( (myRepFile->fd_info = open (myRepFile->path_info, O_WRONLY|O_TRUNC, 0600)) < 0) {
			OMEIS_DoError ("In ExpungeFile, Error opening O_WRONLY|O_TRUNC info file for modification for FileID=%llu: %s",
						   	(unsigned long long)myRepFile->ID, strerror (errno) );
			return (0);
		}
		
		if ( write (myRepFile->fd_info,(void *)&(myRepFile->file_info), sizeof(FileInfo)) != sizeof(FileInfo) )
			OMEIS_DoError ("In ExpungeFile, Error updating the alias list for FileID=%llu: %s",
						   	(unsigned long long)myRepFile->ID, strerror (errno) );
						   	
		/* write the whole alias struct to the file */
		numBytes = sizeof(*myRepFile->aliases)*myRepFile->file_info.nAliases;
		if ( write (myRepFile->fd_info, (void *) myRepFile->aliases, numBytes ) != numBytes) {
			OMEIS_DoError ("Error writing alias info for original FileID=%llu: %s",
				(unsigned long long) myFile->ID, strerror (errno));
			return (0);
		}
		
		/* clean up file and permissions */
		close (myRepFile->fd_info);
		chmod (myRepFile->path_info,0400);
		
		freeFileRep (myRepFile);
	} else if (myFile->file_info.nAliases > 0 ) {
		/* CASE 3: this file serves as a representive to other files */
		
		/* elect the first hasAlias file as our representive file */
		FileRep *myRepFile = newFileRep(myFile->aliases[0].ID);
		
		GetFileInfo (myRepFile);
		GetFileAliases (myRepFile);
		
		/* update the hasAlias + nAliases fields and aliases struct of new representative */
		myRepFile->file_info.isAlias = 0;
		myRepFile->file_info.nAliases = myFile->file_info.nAliases - 1;
		
		if (myRepFile->aliases != NULL) free (myRepFile->aliases);
		myRepFile->aliases = (FileAlias *) malloc (myRepFile->file_info.nAliases * sizeof(FileAlias));
		
		/* copy alias structure from old representative file to new representitive file */
		for (i=1; i<myFile->file_info.nAliases; i++) {
			myRepFile->aliases[i-1].ID = myFile->aliases[i].ID;
			strncpy(myRepFile->aliases[i-1].name, myFile->aliases[i-1].name,  OMEIS_PATH_SIZE);
		}
		
		/* chmod and reopen repfile's info with exclusive (destructive) write access */
		chmod (myRepFile->path_info,0600);
		if (myRepFile->fd_info >= 0) close (myRepFile->fd_info);
		if ( (myRepFile->fd_info = open (myRepFile->path_info, O_WRONLY, 0600)) < 0) {
			OMEIS_DoError ("In ExpungeFile, Error opening O_WRONLY info file for modification for FileID=%llu: %s",
						   	(unsigned long long)myRepFile->ID, strerror (errno) );
			return (0);
		}
		
		if ( write (myRepFile->fd_info,(void *)&(myRepFile->file_info), sizeof(FileInfo)) != sizeof(FileInfo) )
			OMEIS_DoError ("In ExpungeFile, Error updating the alias list for FileID=%llu: %s",
						   	(unsigned long long)myRepFile->ID, strerror (errno) );
				   	
		/* write the alias struct to the file */
		numBytes = sizeof(*myRepFile->aliases)*myRepFile->file_info.nAliases;
		if ( write (myRepFile->fd_info, (void *) myRepFile->aliases, numBytes ) != numBytes) {
			OMEIS_DoError ("Error writing alias info for original FileID=%llu: %s",
				(unsigned long long) myFile->ID, strerror (errno));
			return (0);
		}
		
		/* replace the representive's sym-link file with the real file */
		if (myFile->fd_rep    > 0) close (myFile->fd_rep);
		if (myRepFile->fd_rep > 0) close (myRepFile->fd_rep);
		chmod (myFile->path_rep,    0400);
		chmod (myRepFile->path_rep, 0400);
		lockRepFile (myFile->fd_rep,   'w',0LL,0LL);
		lockRepFile (myRepFile->fd_rep,'w',0LL,0LL);
		
		unlink (myRepFile->path_rep); /* rm the sym link */
		if (rename (myFile->path_rep,myRepFile->path_rep) == -1) {
			OMEIS_DoError ("Error transfering fd_rep from FileID=%llu to FileID=%llu : %s.",
				(unsigned long long)myFile->ID, (unsigned long long)myRepFile->ID, strerror (errno));
			return (0);
		}
		chmod (myRepFile->path_rep, 0600);

		/* inform all the aliases in the group what is their new representative */
		for (i = 0; i < myRepFile->file_info.nAliases; i++) {
			FileRep *aliasFile;
			char relPath[OMEIS_PATH_SIZE];
			
			if (! (aliasFile = newFileRep (myRepFile->aliases[i].ID))) {
				OMEIS_DoError ("Could not get a File object (out of memory?).");
				return (0);
			}
			
			GetFileInfo (aliasFile);
			
			/* whose your daddy? */
			aliasFile->file_info.isAlias = myRepFile->ID;
			
			/* Close the info files if they're open */
			if (aliasFile->fd_info >= 0) close (aliasFile->fd_info);
			chmod (aliasFile->path_info,0600);	
			if ( (aliasFile->fd_info = open (aliasFile->path_info, O_RDWR, 0600)) < 0) {
				return (0);
			}
		
			/* write the info structure back */
			if ( write (aliasFile->fd_info,(void *)&(aliasFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
				OMEIS_DoError ("Error updating info struct for original FileID=%llu: %s",
					(unsigned long long)aliasFile->ID, strerror (errno));
				return (0);
			}
			
			/* Close file's info and chmod back to read-only */
			chmod (myFile->path_info,0400);
			close (myFile->fd_info);
			
			/* make the file's symbolic link point to the new alias representative */
			if (aliasFile->fd_rep > 0) close (aliasFile->fd_rep);
			chmod (aliasFile->path_rep,  0400);	
			lockRepFile (aliasFile->fd_rep, 'w',0LL,0LL);
			
			unlink (aliasFile->path_rep); /* rm the sym link */
			
			/* make a symlink between the original and the alias */
			if (symlink (get_rel_path(myRepFile->path_rep,aliasFile->path_rep,relPath), aliasFile->path_rep) == -1) {
				OMEIS_DoError ("Error making symlink from %s to %s: %s.",
				aliasFile->path_rep,relPath,strerror (errno));
			}
			
			chmod (aliasFile->path_rep, 0600);
		}
		
		/* inform the SHA1 database what is the new representative for the SA1 digest */
		if ( existOID = sha1DB_get (myFile->DB, myFile->file_info.sha1) ) {
			sha1DB_del (myFile->DB, myFile->file_info.sha1);
			sha1DB_put (myFile->DB, myFile->file_info.sha1, myRepFile->ID);
		}
		
		freeFileRep (myRepFile);
	} else {
		OMEIS_DoError (" ERROR: CASE 4 in DeleteFile. This is very bad and very unexpected: %s", strerror (errno));
	}
	sha1DB_close (myFile->DB);
	myFile->DB = NULL;
	
	DeleteFile (myFile);
	return (1);
	
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
FileInfo *myInfo;
char error[OMEIS_ERROR_SIZE];


	if ( size > UINT_MAX || size == 0) return NULL;  /* Bad mojo for mmap */

	if (! (myFile = newFileRep (0LL)) ) {
		perror ("BAH!");
		return (NULL);
	}
	myFile->ID = nextID(myFile->path_ID);
	if (myFile->ID <= 0 && errno) {
		OMEIS_DoError ("Couldn't get next File ID");
		freeFileRep (myFile);
		return (NULL);
	} else if (myFile->ID <= 0){
		OMEIS_DoError ("Happy New Year !!!");
		freeFileRep (myFile);
		return (NULL);
	}

	myFile->size_info = sizeof (FileInfo);
	myFile->fd_info = newRepFile (myFile->ID, myFile->path_info, myFile->size_info, "info");
	if (myFile->fd_info < 0) {
		sprintf (error,"Couldn't open repository info file for FileID %llu (%s).",
			(unsigned long long)myFile->ID,myFile->path_info);
		perror (error);
		freeFileRep (myFile);
		return (NULL);
	}
	
	myFile->size_rep = size;

	myFile->fd_rep = newRepFile (myFile->ID, myFile->path_rep, size, NULL);
	if (myFile->fd_rep < 0) {
		sprintf (error,"Couldn't open repository file for FileID %llu (%s).",
			(unsigned long long)myFile->ID,myFile->path_rep);
		perror (error);
		DeleteFile (myFile);
		freeFileRep (myFile);
		return (NULL);
	}

	if ( (myFile->file_buf = (char *)mmap (NULL, size, PROT_READ|PROT_WRITE , MAP_SHARED, myFile->fd_rep, 0LL)) == (char *) -1 ) {
		DeleteFile (myFile);
		OMEIS_DoError ("Couldn't mmap File %s (ID=%llu)",myFile->path_rep,
			(unsigned long long)myFile->ID);
		freeFileRep (myFile);
		return (NULL);
	}

	myInfo = &(myFile->file_info);
	memset(myInfo, 0, sizeof(myInfo));

	myInfo->mySig    = OME_IS_FILE_SIG;
	myInfo->vers     = OME_IS_FILE_VER;
	myInfo->ID       = myFile->ID;
	if (filename)
		strncpy (myInfo->name,filename,OMEIS_PATH_SIZE-1);
	if ( write (myFile->fd_info,(void *)myInfo,sizeof(FileInfo)) != sizeof(FileInfo) ) {
		DeleteFile (myFile);
		OMEIS_DoError ("Couldn't write info for File %s (ID=%llu)",myFile->path_info,
			(unsigned long long)myFile->ID);
		freeFileRep (myFile);
		return (NULL);
	}
	close (myFile->fd_info);
	myFile->fd_info = -1;

	return (myFile);
}



int update_file_info (FileRep *myFile) {
FileInfo *myInfo = &(myFile->file_info);
struct stat fStat;
u_int32_t mySig;
u_int8_t vers=0;

/*
  N.B.:  File opening and locking happens outside of this func!
  The file must be opened read-write, and this func must have exclusive access to it.
*/
	lseek(myFile->fd_info, (off_t)0, SEEK_SET);
	if (fstat (myFile->fd_info , &fStat) != 0) return (-2);
	if (fStat.st_size == 276) vers = 1;

	if (vers != 1) {
		if ( read (myFile->fd_info,(void *)&(mySig),sizeof(mySig)) != sizeof(mySig) ) {
			return (-2);
		}
		if (mySig != OME_IS_FILE_SIG) return (-3);

		if ( read (myFile->fd_info,(void *)&(vers),sizeof(vers)) != sizeof(vers) ) {
			return (-3);
		}
	}

	lseek(myFile->fd_info, (off_t)0, SEEK_SET);
	switch(vers){
		case 1:
			if ( read (myFile->fd_info,(void *)&(myInfo->sha1),sizeof(myInfo->sha1)) != sizeof(myInfo->sha1) ) 
				return (0);
			if ( read (myFile->fd_info,(void *)&(myInfo->name),sizeof(myInfo->name)) != sizeof(myInfo->name) )
				return (0);
			myInfo->mySig    = OME_IS_FILE_SIG;
			myInfo->vers     = OME_IS_FILE_VER;
			myInfo->ID       = myFile->ID;
			myInfo->isAlias  = 0;
			myInfo->nAliases = 0;
		break;
		
		case OME_IS_FILE_VER:
			if ( read (myFile->fd_info,(void *)myInfo,sizeof(FileInfo)) != sizeof(FileInfo) )
				return (0);
		break;
	}
	
	lseek(myFile->fd_info, (off_t)0, SEEK_SET);
	if ( write (myFile->fd_info,(void *)myInfo,sizeof(FileInfo)) != sizeof(FileInfo) ) {
		return (0);
	}
	
	return (1);
}


int GetFileInfo (FileRep *myFile) {
u_int32_t mySig;
u_int8_t vers=0;
struct stat fStat;

	/* Do nothing if version and signature are set */
	if ( myFile->file_info.mySig == OME_IS_FILE_SIG && myFile->file_info.vers == OME_IS_FILE_VER)
		return (1);

	if ( (myFile->fd_info = open (myFile->path_info, O_RDONLY, 0600)) < 0) {
		OMEIS_DoError ("Error opening FileID=%llu: %s.",
			(unsigned long long)myFile->ID,strerror (errno));
		return (-1);
	}
	/* We'll block here until others are finish writing */
	lockRepFile (myFile->fd_rep,'r',0LL,0LL);

	if (fstat (myFile->fd_info , &fStat) == -1) return (-2);
	if (fStat.st_size == 276) vers = 1;
	
	if (vers != 1) {
		if ( read (myFile->fd_info,(void *)&(mySig),sizeof(mySig)) != sizeof(mySig) ) {
			OMEIS_DoError ("Error reading FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-2);
		}
		if (mySig != OME_IS_FILE_SIG) {
			OMEIS_DoError ("Error reading FileID=%llu.  Bad signature : %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-3);
		}

		if ( read (myFile->fd_info,(void *)&(vers),sizeof(vers)) != sizeof(vers) ) {
			OMEIS_DoError ("Error reading version for FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-4);
		}
	}
	
	lseek(myFile->fd_info, (off_t)0, SEEK_SET);
	if (vers == 0) {
		OMEIS_DoError ("Error reading version for FileID=%llu: %s.",
			(unsigned long long)myFile->ID,strerror (errno));
		return (-5);
	}

	if (vers == OME_IS_FILE_VER) {
	if ( read (myFile->fd_info,(void *)&(myFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
			OMEIS_DoError ("Error reading info for FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-6);
		}
	} else {
		/* re-open the file for exclusive read-write */
		/* closing releases all locks */
		close (myFile->fd_info);
		myFile->fd_info = -1;
		chmod (myFile->path_info,0600);	
		if ( (myFile->fd_info = open (myFile->path_info, O_RDWR, 0600)) < 0) {
			OMEIS_DoError ("Error opening info for FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-7);
		}
		/* We'll block here until we can write exclusively */
		lockRepFile (myFile->fd_rep,'w',0LL,0LL);
		/*
		  At this point, another process could have already fixed this file,
		  So update_file_info will determine the version again on its own.
		*/
		if (! update_file_info (myFile)) {
			OMEIS_DoError ("Error updating info version for FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-8);
		}
		close (myFile->fd_info);
		chmod (myFile->path_info,0400);
		/* And release the lock also */
		myFile->fd_info = -1;
	}

	if (myFile->fd_info > -1) {
		close (myFile->fd_info);
		myFile->fd_info = -1;
	}

	return (1);
}

int GetFileAliases (FileRep *myFile) {
unsigned int i, nAliases;
FileAlias *aliases,*myAlias;

	/* return immediately if aliases is not NULL */
	if (myFile->aliases) return (1);

	/* Make sure the info struct is filled up */
	GetFileInfo (myFile);

	/* No aliases, so return 1 */
	if ( (nAliases = myFile->file_info.nAliases) == 0 ) {
		return (1);
	}
	
	/* Get enough memory for all of the aliases */
	if ( ! (myAlias = aliases = (FileAlias *)malloc (nAliases * sizeof (FileAlias))) ) {
		close (myFile->fd_info);
		myFile->fd_info = -1;
		return (0);
	}

	/* Open the info file if necessary */
	if (myFile->fd_info < 0) {
		if ( (myFile->fd_info = open (myFile->path_info, O_RDONLY, 0600)) < 0) {
			free (aliases);
			close (myFile->fd_info);
			myFile->fd_info = -1;
			return (0);
		}
	}
	
	lseek(myFile->fd_info, (off_t)sizeof(FileInfo), SEEK_SET);
	for (i = 0; i < nAliases; i++) {
		if ( read (myFile->fd_info,(void *)myAlias,sizeof(FileAlias)) != sizeof(FileAlias) ) {
			free (aliases);
			close (myFile->fd_info);
			myFile->fd_info = -1;
			return (0);
		}
		myAlias++;
	}
	close (myFile->fd_info);
	myFile->fd_info = -1;
	myFile->aliases = aliases;
	return (1);	
	
}


OID check_aliases (OID ID, const char *name) {
FileRep *myFile;
unsigned int i, nAliases;
OID found=0;
FileAlias *alias;

	/* Get a FileRep struct */
	if (! (myFile = newFileRep (ID))) {
		OMEIS_DoError ("Could not get a File object (out of memory?).");
		return (0);
	}

	/* Read the original's info file */
	GetFileInfo (myFile);

	/* Check the name */
	if (! strncmp (myFile->file_info.name,name,OMEIS_PATH_SIZE) ) {
		freeFileRep (myFile);
		return (ID);
	}

	/* No aliases, and name didn't match, so return 0 */
	if ( (nAliases = myFile->file_info.nAliases) == 0 ) {
		freeFileRep (myFile);
		return (0);
	}

	GetFileAliases (myFile);
	
	if (myFile->aliases) {
		alias = myFile->aliases;
		for (i = 0; i < nAliases && !found; i++) {
			if (! strncmp (alias->name,name,OMEIS_PATH_SIZE) )
				found = alias->ID;
			alias++;
		}
	}

	freeFileRep (myFile);
	return (found);


}

/* returns true on success */
int make_alias (OID ID,FileRep *aliasFile) {
FileRep *myFile;
unsigned int i, nAliases;
FileAlias alias;
int myFlags;
char backupName[OMEIS_PATH_SIZE];
char relPath[OMEIS_PATH_SIZE];

	/* Get a FileRep struct */
	if (! (myFile = newFileRep (ID))) {
		OMEIS_DoError ("Could not get a File object (out of memory?).");
		return (0);
	}

	/* Get the both file's infos */
	GetFileInfo (myFile);
	GetFileInfo (aliasFile);

	/* Close the info files if they're open */
	if (myFile->fd_info >= 0) close (myFile->fd_info);
	if (aliasFile->fd_info >= 0) close (aliasFile->fd_info);
	myFile->fd_info = -1;
	aliasFile->fd_info = -1;

	/* chmod and reopen the both file's info with exclusive write access */
	chmod (myFile->path_info,0600);	
	if ( (myFile->fd_info = open (myFile->path_info, O_RDWR, 0600)) < 0) {
		return (0);
	}
	lockRepFile (myFile->fd_rep,'w',0LL,0LL);
	chmod (aliasFile->path_info,0600);	
	if ( (aliasFile->fd_info = open (aliasFile->path_info, O_RDWR, 0600)) < 0) {
		return (0);
	}
	lockRepFile (aliasFile->fd_rep,'w',0LL,0LL);

	/* Copy the alias file's path, and rename it to a temporary backup (append ~) */
	strncpy (backupName,aliasFile->path_rep,OMEIS_PATH_SIZE-1);
	strcat (backupName,"~");
	if (rename (aliasFile->path_rep,backupName) == -1) {
		OMEIS_DoError ("Error making backup of FileID=%llu: %s.",
			(unsigned long long)aliasFile->ID,strerror (errno));
		return (0);
	}

	/* make a symlink between the original and the alias */
	if (symlink (get_rel_path(myFile->path_rep,aliasFile->path_rep,relPath), aliasFile->path_rep) == -1) {
		OMEIS_DoError ("Error making symlink from %s to %s: %s.",
			aliasFile->path_rep,relPath,strerror (errno));
		/* restore backup on error */
		if (rename (backupName, aliasFile->path_rep) == -1) {
			OMEIS_DoError ("Error restoring backup %s.",backupName);
			return (0);
		}
		return (0);
	}

	/* Ditch the backup */
	unlink (backupName);
	
	/* increment nAliases in the original, and set isAlias in the alias */
	myFile->file_info.nAliases++;
	aliasFile->file_info.isAlias = myFile->ID;

	/* write both info structures back */
	if ( write (myFile->fd_info,(void *)&(myFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		OMEIS_DoError ("Error writing info for original FileID=%llu: %s",
			(unsigned long long)myFile->ID, strerror (errno));
		return (0);
	}
	if ( write (aliasFile->fd_info,(void *)&(aliasFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		OMEIS_DoError ("Error writing info for alias FileID=%llu: %s",
			(unsigned long long)aliasFile->ID, strerror (errno));
		return (0);
	}

	/* Set write mode to append for the original */
	if ( (myFlags = fcntl (myFile->fd_info, F_GETFL, 0)) < 0) {
		OMEIS_DoError ("Error getting file flags for %s: %s",
			myFile->path_info, strerror (errno));
		return (0);
	}
	myFlags |= O_APPEND;
	if ( fcntl (myFile->fd_info, F_SETFL, myFlags) < 0) {
		OMEIS_DoError ("Error setting append file flag for %s: %s",
			myFile->path_info, strerror (errno));
		return (0);
	}

	/* set the FileAlias struct */
	alias.ID = aliasFile->ID;
	strncpy (alias.name,aliasFile->file_info.name,OMEIS_PATH_SIZE);
	
	/* append the alias struct to the file */
	if ( write (myFile->fd_info,(void *)&(alias),sizeof(alias)) != sizeof(alias) ) {
		OMEIS_DoError ("Error writing alias info for original FileID=%llu: %s",
			(unsigned long long)myFile->ID, strerror (errno));
		return (0);
	}
	
	/* Close both file's infos and chmod back to read-only */
	chmod (myFile->path_info,0400);
	close (myFile->fd_info);
	myFile->fd_info = -1;
	chmod (aliasFile->path_info,0400);
	close (aliasFile->fd_info);
	aliasFile->fd_info = -1;

	/* return true */
	return (1);

}


char *get_rel_path (const char *toPath, const char *fromPath, char *pathBuf) {
char *tmp1,*tmp2;
int nBack=0;

	strcpy (pathBuf,"");
	tmp1 = strrchr (toPath,'/');
	if (tmp1) tmp1++;
	while (*toPath && *fromPath && *toPath == *fromPath && toPath != tmp1) {
		toPath++;
		fromPath++;
	}

	while (*fromPath) {
		if (*fromPath++ == '/') nBack++;
	}
	tmp2 = pathBuf + (nBack*3);

	while (nBack) {
		strcat (pathBuf,"../");
		nBack--;
	}
	
	while (*toPath) {
		*tmp2++ = *toPath++;
	}
	*tmp2 = '\0';
	
	return (pathBuf);
}

/*
  Call this only to balance a call to NewFile()
*/
OID FinishFile (FileRep *myFile) {
OID existOID, aliasOID;

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
		/* Check the original for duplicate alias */
		if ( (aliasOID = check_aliases (existOID,myFile->file_info.name)) ) {
			DeleteFile (myFile);
			myFile->ID = aliasOID;
			myFile->file_info.ID = aliasOID;
			return (aliasOID);
		} else {
			/* unlinks myFile, makes a symlink to original, records alias in original,
			  file_info.isAlias set to existOID. un-mmapps the file.
			  myFile->file_info is not written.
			  if anything goes wrong here, this function will return 0.
			  If everything's OK, it will return 1.
			*/
			if (! (make_alias (existOID,myFile)) ) {
				DeleteFile (myFile);
				return (0);
			}			
		}
	}

	chmod (myFile->path_info,0600);
	if ( (myFile->fd_info = open (myFile->path_info, O_RDWR, 0600)) < 0) {
		DeleteFile (myFile);
		sha1DB_close (myFile->DB);
		myFile->DB = NULL;
		return (0);
	}

	if ( write (myFile->fd_info,(void *)&(myFile->file_info),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		OMEIS_DoError ("In FinishFile, Error writing info for FileID=%llu: %s",
			(unsigned long long)myFile->ID, strerror (errno) );
		sha1DB_close (myFile->DB);
		myFile->DB = NULL;
		DeleteFile (myFile);
		return (0);
	}

	close (myFile->fd_info);
	myFile->fd_info = -1;

	if (myFile->is_mmapped) {
		if (msync (myFile->file_buf , myFile->size_rep , MS_SYNC) != 0) {
			OMEIS_DoError ("In FinishFile, Error msynching FileID=%lly: %s",
				(unsigned long long)myFile->ID, strerror (errno) );
			sha1DB_close (myFile->DB);
			myFile->DB = NULL;
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
	if (! existOID) {
		if ( sha1DB_put (myFile->DB, myFile->file_info.sha1, myFile->ID) ) {
			OMEIS_DoError ("In FinishFile, Error writing SHA1-DB for FileID=%llu: %s",
				(unsigned long long)myFile->ID, strerror (errno) );
			sha1DB_close (myFile->DB);
			myFile->DB = NULL;
			DeleteFile (myFile);
			return (0);
		}
		/* Close the DB (and release the exclusive lock) */
		sha1DB_close (myFile->DB);
		myFile->DB = NULL;
	}



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
        	OMEIS_DoError ("Couldn't finish writing uploaded file %s (ID=%llu).  Wrote %lu, expected %lu",
                     filename,(unsigned long long)ID,(unsigned long)nIO,(unsigned long)size);
            DeleteFile (myFile);
			freeFileRep (myFile);
			return (0);
	        }
    }

	ID = FinishFile (myFile);
	freeFileRep (myFile);
	closeInputFile (infile,isLocalFile);
	return (ID);
}
