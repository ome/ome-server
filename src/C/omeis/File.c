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
#include "Pixels.h"
#include "OMEIS_Error.h"

/* Private prototypes */
int update_file_info (FileRep *myFile);
OID check_aliases (FileRep *existFile, FileRep *myFile);
int make_alias (FileRep *myFile, FileRep *aliasFile);
int remove_alias (FileRep *myFile, OID aliasID);
int check_pixels_dep (FileRep *myFile, OID theDep);
char *get_rel_path (char *toPath, const char *fromPath, char *pathBuf);




void freeFileRep (FileRep *myFile)
{
	if (!myFile)
		return;

	if (myFile->is_mmapped) {
		munmap (myFile->file_buf, myFile->size_buf);
	}
	
	if (myFile->fd_info > -1 && myFile->file_info) {
		if (myFile->rorw_info == 'w')
			msync (myFile->file_info, myFile->size_info, MS_SYNC);
		munmap (myFile->file_info, myFile->size_info);
		myFile->file_info = NULL;
	}

	
	if (myFile->fd_info > -1 ) close (myFile->fd_info);
	if (myFile->mod_info == 'w') chmod (myFile->path_info,0400);
	if (myFile->fd_rep > -1 )  close (myFile->fd_rep);

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
			OMEIS_DoError ("Could not get path for FileID=%llu: %s",
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

	if (myFile->fd_rep < 0) {
		if ( (myFile->fd_rep = openRepFile (myFile->path_rep, O_RDONLY)) < 0) {
			freeFileRep (myFile);
			OMEIS_DoError ("Could not open repository file (FileID = %llu: %s", (unsigned long long)ID,strerror( errno ));
			return (NULL);
		}
	}
	
	GetFileInfo (myFile,'r');

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
char path_rep[OMEIS_PATH_SIZE],path_info[OMEIS_PATH_SIZE];

	*path_rep = *path_info = '\0';

	if (myFile->path_rep) strncpy (path_rep,myFile->path_rep,OMEIS_PATH_SIZE);
	if (myFile->path_info) strncpy (path_info,myFile->path_info,OMEIS_PATH_SIZE);

	freeFileRep (myFile);

	if (*path_rep) {
		chmod (path_rep,0600);
		unlink (path_rep);
	}
	if (*path_info) {
		chmod (path_info,0600);
		unlink (path_info);
	}
	
	return (0);
}


int ExpungeFile (FileRep *myFile) {
int i;
int numBytes; 
OID existOID;
FileRep *myRepFile,*aliasFile;
PixelsRep *myPixels;
FileAlias *myAlias;
u_int32_t nPixelDeps;
OID *myDep;


	/* Get the file's info and SHA1 database*/
	GetFileInfo (myFile,'w');
	
	
	/* check to see if the file hasAlias or isAlias */
	if ( myFile->file_info->isAlias == 0 && myFile->file_info->nAliases == 0 ){ 
	
		/* CASE 1: file has no alias buddies */
		
		/*
		  If the file has pixel dependencies, then recover all of them, and mark
		  them as unpurgeable.
		*/
		nPixelDeps = myFile->nPixelDeps;
		myDep = myFile->PixelDeps;
		if (myDep) {
			for (i = 0; i < nPixelDeps; i++) {
				/* This will open the pixels for reading (i.e. recover them) */
				if (! (myPixels = GetPixelsRep (*myDep, 'r', bigEndian())) ) {
					OMEIS_DoError ("Error recovering Pixels %llu", (unsigned long long)*myDep);
					return (0);
				}
				/* These pixels may depend on other files, so we unregister them all */
				UnregisterPixelDeps (myPixels);
				/* This marks pixels as unpurgeable */
				unlink (myPixels->path_conv);
				freePixelsRep(myPixels);
				myDep++;
			}
		}

		/* remove SHA1 entry if it exists */
		if ( existOID = sha1DB_get (myFile->path_DB, myFile->file_info->sha1) ) {
			sha1DB_del (myFile->path_DB, myFile->file_info->sha1);
		}
	} else if ( myFile->file_info->isAlias != 0 ) {
		/* CASE 2: file has a representive file. This file is only a symbolic link */

		/*
		  remove this file's ID from the representative file's alias list
		*/
		if (! (myRepFile = newFileRep (myFile->file_info->isAlias))) {
			OMEIS_DoError ("Could not get a File object (out of memory?).");
			return (0);
		}
		GetFileInfo (myRepFile,'w');

		if (! remove_alias (myRepFile, myFile->ID) ) {
			OMEIS_DoError ("Could not remove alias %llu from FileID=%llu.",
				(unsigned long long)myFile->ID,
				(unsigned long long)myRepFile->ID);
				freeFileRep (myRepFile);
			return (0);
		}
		/*
		  If the file has pixel dependencies, then set their dependencies
		  to the original.
		  Let myRepFile know about its new pixel deps.
		*/

		nPixelDeps = myFile->nPixelDeps;
		myDep = myFile->PixelDeps;
		if (myDep) {
			for (i = 0; i < nPixelDeps; i++) {
				if (! (myPixels = GetPixelsRep (*myDep, 'i', bigEndian())) ) {
					OMEIS_DoError ("Error recovering Pixels %llu", (unsigned long long)*myDep);
					freeFileRep (myRepFile);
					return (0);
				}
				if (!RemapPixelDeps (myPixels,myFile->ID,myRepFile->ID)) {
					OMEIS_DoError ("Error remaping Pixel dependencies for PixelsID %llu (FileID %llu -> %llu)",
						(unsigned long long)*myDep,
						(unsigned long long)myFile->ID,
						(unsigned long long)myRepFile->ID);
					freePixelsRep(myPixels);
					freeFileRep(myRepFile);
					return (0);
				}
				if (!MakePixelsDep (myRepFile, myPixels->ID)) {
					OMEIS_DoError ("Error making Pixels %llu dependency in FileID %llu",
						(unsigned long long)*myDep,
						(unsigned long long)myRepFile->ID);
					freePixelsRep(myPixels);
					freeFileRep(myRepFile);
					return (0);
				}
				freePixelsRep(myPixels);
				myDep++;
			}
		}
		freeFileRep (myRepFile);
	} else if (myFile->file_info->nAliases > 0 ) {
		/* CASE 3: this file serves as a representive to other files */
		/*
		  elect the first alias in this file's list as our representive file.
		  move this repository file to the new representative's path.
		  copy this file's alias list to the new representative, omitting the alias to itself.
		  make each of this file's aliases point to the new representative
		*/
		if (! (myRepFile = newFileRep (myFile->aliases[0].ID))) {
			OMEIS_DoError ("Could not get a File object (out of memory?).");
			return (0);
		}

		GetFileInfo (myRepFile,'w');
		myRepFile->file_info->isAlias = 0;

		myAlias = myFile->aliases;
		/* relink myFile's aliases to myRepFile */
		for (i=0; i < myFile->file_info->nAliases; i++) {
			if (myAlias->ID != myRepFile->ID) {
				if (! (aliasFile = newFileRep (myAlias->ID))) {
					OMEIS_DoError ("Could not get a File object (out of memory?).");
					return (0);
				}
				if (! make_alias (myRepFile, aliasFile)) {
					OMEIS_DoError ("Could make alias from %llu to %llu.",
						(unsigned long long)myRepFile->ID,
						(unsigned long long)aliasFile->ID);
					freeFileRep (aliasFile);
					return (0);
				}
				freeFileRep (aliasFile);
			}
		myAlias++;
		}
		/*
		  If the file has pixel dependencies, then set their dependencies
		  to the new original.
		*/
		nPixelDeps = myFile->nPixelDeps;
		myDep = myFile->PixelDeps;
		if (myDep) {
			for (i = 0; i < nPixelDeps; i++) {
				if (! (myPixels = GetPixelsRep (*myDep, 'i', bigEndian())) ) {
					OMEIS_DoError ("Error recovering Pixels %llu", (unsigned long long)*myDep);
					return (0);
				}
				if (!RemapPixelDeps (myPixels,myFile->ID,myRepFile->ID)) {
					OMEIS_DoError ("Error remaping Pixel dependencies for PixelsID %llu (FileID %llu -> %llu)",
						(unsigned long long)*myDep,
						(unsigned long long)myFile->ID,
						(unsigned long long)myRepFile->ID);
					return (0);
				}
				if (!MakePixelsDep (myRepFile, myPixels->ID)) {
					OMEIS_DoError ("Error making Pixels %llu dependency in FileID %llu",
						(unsigned long long)*myDep,
						(unsigned long long)myRepFile->ID);
					return (0);
				}
				freePixelsRep(myPixels);
				myDep++;
			}
		}

		unlink (myRepFile->path_rep); /* rm the sym link */
		if (rename (myFile->path_rep,myRepFile->path_rep) == -1) {
			OMEIS_DoError ("Error transfering fd_rep from FileID=%llu to FileID=%llu : %s.",
				(unsigned long long)myFile->ID, (unsigned long long)myRepFile->ID, strerror (errno));
			return (0);
		}
		
		/* inform the SHA1 database what is the new representative for the SA1 digest */
		if ( existOID = sha1DB_get (myFile->path_DB, myFile->file_info->sha1) ) {
			sha1DB_update (myFile->path_DB, myFile->file_info->sha1, myRepFile->ID);
		}

		freeFileRep (myRepFile);
	} else {
		OMEIS_DoError (" ERROR: CASE 4 in DeleteFile. This is very bad and very unexpected: %s", strerror (errno));
	}


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
FileInfo myInfo;
char error[OMEIS_ERROR_SIZE];
int status;


	if ( size > UINT_MAX || size == 0) return NULL;  /* Bad mojo for mmap */

	if (! (myFile = newFileRep (0LL)) ) {
		OMEIS_DoError ("BAH! Can't make a new file object - out of memory");
		return (NULL);
	}
	myFile->ID = nextID(myFile->path_ID);
	if (myFile->ID <= 0 && errno) {
		OMEIS_DoError ("Couldn't get next File ID");
		freeFileRep (myFile);
		return (NULL);
	} else if (myFile->ID <= 0){
		/* I'll be damned, we rolled over a 64-bit number */
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
	myFile->rorw_info = 'n';
	
	myFile->size_rep = size;

	myFile->fd_rep = newRepFile (myFile->ID, myFile->path_rep, size, NULL);
	if (myFile->fd_rep < 0) {
		sprintf (error,"Couldn't open repository file for FileID %llu (%s).",
			(unsigned long long)myFile->ID,myFile->path_rep);
		perror (error);
		DeleteFile (myFile);
		return (NULL);
	}

	if ( (myFile->file_buf = (char *)mmap (NULL, size, PROT_READ|PROT_WRITE , MAP_SHARED, myFile->fd_rep, 0LL)) == (char *) -1 ) {
		OMEIS_DoError ("Couldn't mmap File '%s' (ID=%llu)",myFile->path_rep,
			(unsigned long long)myFile->ID);
		DeleteFile (myFile);
		return (NULL);
	}

	memset(&myInfo, 0, sizeof(myInfo));

	myInfo.mySig    = OME_IS_FILE_SIG;
	myInfo.vers     = OME_IS_FILE_VER;
	myInfo.ID       = myFile->ID;
	myInfo.size     = size;
	if (filename)
		strncpy ((char *)myInfo.name,filename,OMEIS_PATH_SIZE-1);
	if ( (status = SetFileInfo (myFile, &myInfo, myFile->size_info)) != 1 ) {
		OMEIS_DoError ("NewFile: SetFileInfo failed for '%s' (ID=%llu).  Status=%d",myFile->path_rep,
			(unsigned long long)myFile->ID,status);
		DeleteFile (myFile);
		return (NULL);
	}

	return (myFile);
}

/*
* This function copies the contents of new_info to  the file's info record
* Note that new_info can't point to the same memory range as myFile->file_info
* because myFile->file_info will be munmapped.
*/
int SetFileInfo (FileRep *myFile, void *new_info, size_t size) {

	if (! (myFile->rorw_info == 'n' || myFile->rorw_info == 'w')) {
		return (-1);
	}
	if (myFile->fd_info < 0) {
		return (-2);
	}
	
	if (myFile->file_info) munmap (myFile->file_info, myFile->size_info);
	myFile->file_info = NULL;

	if (lseek(myFile->fd_info, (off_t) 0, SEEK_SET) < 0) {
		close (myFile->fd_info);
		return (-3);
	}
	
	if ( write(myFile->fd_info, new_info, size) < 1) {
		close (myFile->fd_info);
		return (-4);
	}

	if (myFile->size_info > size) {
		ftruncate (myFile->fd_info, size);
	}
	
	myFile->rorw_info = 'w';
	return (GetFileInfo (myFile,'w'));
	
}

int update_file_info (FileRep *myFile) {
FileInfo myInfo;
FileInfo_v2 myV1Info;
struct stat fStat;
u_int32_t mySig;
u_int8_t vers=0;
u_int32_t alias, nAliases;
FileAlias *aliases=NULL,*myAlias;

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
	memset(&myInfo, 0, sizeof(myInfo));

	switch(vers){
		case 1:
			if ( read (myFile->fd_info,(void *)&(myInfo.sha1),sizeof(myInfo.sha1)) != sizeof(myInfo.sha1) ) 
				return (0);
			if ( read (myFile->fd_info,(void *)&(myInfo.name),sizeof(myInfo.name)) != sizeof(myInfo.name) )
				return (0);
			myInfo.mySig    = OME_IS_FILE_SIG;
			myInfo.vers     = OME_IS_FILE_VER;
			myInfo.ID       = myFile->ID;
			
			/* open the rep file to make sure its inflated */
			if (myFile->fd_rep < 0) {
				if ( (myFile->fd_rep = openRepFile (myFile->path_rep, O_RDONLY)) < 0) {
					OMEIS_DoError ("Could not open repository file (FileID = %llu: %s", (unsigned long long)myFile->ID,strerror( errno ));
					return (0);
				}
			}

			/* Get the size */
			if (stat (myFile->path_rep, &fStat) < 0) {
				OMEIS_DoError ("Could not stat repository file (FileID = %llu: %s", (unsigned long long)myFile->ID,strerror( errno ));
				return (0);			
			}
			myFile->size_rep = myInfo.size = fStat.st_size;

			myInfo.isAlias  = 0;
			myInfo.nAliases = 0;
			aliases = NULL;
		break;
		
		case 2:
			if ( read (myFile->fd_info,(void *)&(myV1Info),sizeof(myV1Info)) != sizeof(myV1Info) ) 
				return (0);

			/* open the rep file to make sure its inflated */
			if (myFile->fd_rep < 0) {
				if ( (myFile->fd_rep = openRepFile (myFile->path_rep, O_RDONLY)) < 0) {
					OMEIS_DoError ("Could not open repository file (FileID = %llu: %s", (unsigned long long)myFile->ID,strerror( errno ));
					return (0);
				}
			}
			
			/* Get the size */
			if (stat (myFile->path_rep, &fStat) < 0) {
				OMEIS_DoError ("Could not stat repository file (FileID = %llu: %s", (unsigned long long)myFile->ID,strerror( errno ));
				return (0);			
			}
			myInfo.mySig    = OME_IS_FILE_SIG;
			myInfo.vers     = OME_IS_FILE_VER;
			myInfo.ID       = myV1Info.ID;
			memcpy (myInfo.name,myV1Info.name,OMEIS_PATH_SIZE);
			memcpy (myInfo.sha1,myV1Info.sha1,OME_DIGEST_LENGTH);
			myFile->size_rep = myInfo.size = fStat.st_size;
			myInfo.isAlias  = myV1Info.isAlias;
			myInfo.nAliases = myV1Info.nAliases;
			nAliases = myInfo.nAliases;
			/* Read the aliases if any */
			if (nAliases > 0) {

				/* Get enough memory for all of the aliases */
				if ( ! (myAlias = aliases = (FileAlias *)malloc (nAliases * sizeof (FileAlias))) ) {
					return (0);
				}

				/* read them in */
				for (alias = 0; alias < nAliases; alias++) {
					if ( read (myFile->fd_info,(void *)myAlias,sizeof(FileAlias)) != sizeof(FileAlias) ) {
						free (aliases);
						close (myFile->fd_info);
						myFile->fd_info = -1;
						return (0);
					}
					myAlias++;
				}
			}			
		break;

		case OME_IS_FILE_VER:
		/* We should never end up here */
			if (aliases) free (aliases);
			return (1);
		break;
	}
	
	/* Rewind to the beginning and write everything out */
	lseek(myFile->fd_info, (off_t)0, SEEK_SET);
	if ( write (myFile->fd_info,(void *)(&myInfo),sizeof(FileInfo)) != sizeof(FileInfo) ) {
		if (aliases) free (aliases);
		return (0);
	}
	
	myAlias = aliases;
	for (alias = 0; alias < myInfo.nAliases; alias++) {
		if ( write (myFile->fd_info,(void *)myAlias,sizeof(FileAlias)) != sizeof(FileAlias) ) {
		if (aliases) free (aliases);
			return (0);
		}
		myAlias++;
	}
	
	
	if (aliases) free (aliases);
	return (1);
}


int GetFileInfo (FileRep *myFile, char rorw) {
u_int32_t mySig;
u_int8_t vers=0;
struct stat fStat;
int status;
int open_flags=0, mmap_flags=0;
size_t alias_off,pixel_deps_off;
int myFlags;
char myLock;


	switch (rorw) {
		case 'r':
			open_flags = O_RDONLY;
			mmap_flags = PROT_READ;
			myLock = 'r';
		break;
		case 'w':
			open_flags = O_RDWR;
			mmap_flags = PROT_READ|PROT_WRITE;
			myLock = 'w';
		break;
		case 'i':
			open_flags = O_RDONLY;
			mmap_flags = PROT_READ;
			myLock = 'r';
		break;
		case 'n':
			open_flags = O_RDWR;
			mmap_flags = PROT_READ|PROT_WRITE;
			myLock = 'w';
		break;
		default:
			return (0);
		break;
	}
/* return if already opened with correct access. */
	if (myFile->fd_info >= 0) {
		myFlags = fcntl (myFile->fd_info, F_GETFL, 0);
		if (myFlags < 0 || ((myFlags & O_ACCMODE) != open_flags)) {
			if (myFile->file_info) {
				if (myFile->rorw_info == 'w')
					msync (myFile->file_info, myFile->size_info, MS_SYNC);
				munmap (myFile->file_info, myFile->size_info);
				myFile->file_info = NULL;
			}
			close (myFile->fd_info);
			myFile->fd_info = -1;
		} else {
			if (myFile->file_info) return (1);
		}
	}

/*
  we've either switched our access mode, in which the file is now closed,
  or we're just remapping.
  If the file is closed, open it with the right locks, etc.
*/
	if (myFile->fd_info < 0) {
		myFile->rorw_info = myLock;
		if (myLock == 'w') {
			chmod (myFile->path_info,0600);
			myFile->mod_info = 'w';
		}

		if ( (myFile->fd_info = open (myFile->path_info, open_flags, 0600)) < 0) {
			OMEIS_DoError ("Error opening FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-1);
		}
		lockRepFile (myFile->fd_info,myLock,0LL,0LL);
	}

	/* Do a stat to get the file length and permissions */
	if (stat (myFile->path_info , &fStat) == -1) return (-2);
	myFile->size_info = fStat.st_size;

	/* mmap the entire contents of the info file */
	if ( (myFile->file_info = (FileInfo *)mmap (NULL, fStat.st_size, mmap_flags, MAP_SHARED, myFile->fd_info, 0LL)) == (void *) -1 ) {
		OMEIS_DoError ("Could not mmap info for FileID=%llu",(unsigned long long)myFile->ID);
		close (myFile->fd_info);
		myFile->fd_info = -1;
		return (-2);			
	}

	/* get the signature and version */
	if (myFile->file_info->mySig != OME_IS_FILE_SIG) {
		OMEIS_DoError ("Error reading FileID=%llu.  Bad signature.  Expected %lu, got %lu",
			(unsigned long long)myFile->ID, (unsigned long)OME_IS_FILE_SIG, (unsigned long)myFile->file_info->mySig);
		close (myFile->fd_info);
		myFile->fd_info = -1;
		return (-3);
	}

	if (fStat.st_size == 276) vers = 1;
	else vers = myFile->file_info->vers;

	if (vers != OME_IS_FILE_VER) {
		munmap (myFile->file_info, fStat.st_size);
		/* re-open the file for exclusive read-write */
		/* closing releases all locks */
		close (myFile->fd_info);
		myFile->fd_info = -1;
		chmod (myFile->path_info,0600);	
		myFile->mod_info = 'w';

		if (myFile->file_info->vers == 0) {
			OMEIS_DoError ("Error reading version for FileID=%llu: %s.",
				(unsigned long long)myFile->ID,strerror (errno));
			return (-5);
		}
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
		if ( (status = update_file_info (myFile)) < 1) {
			OMEIS_DoError ("Error %d updating info version for FileID=%llu: %s.",status,
				(unsigned long long)myFile->ID,strerror (errno));
			if (myFile->fd_info > -1) close (myFile->fd_info);
			myFile->fd_info = -1;
			return (-8);
		}
		close (myFile->fd_info);
		myFile->fd_info = -1;
		chmod (myFile->path_info,0400);
		myFile->mod_info = 'r';
		/* And release the lock also */
		/* try again */
		return (GetFileInfo (myFile,rorw));
	}
	
	/* set up the aliases */
	alias_off = sizeof (FileInfo);
	if (myFile->file_info->nAliases) {
		myFile->aliases = (FileAlias *) ( (void *)(myFile->file_info) + alias_off);
	} else {
		myFile->aliases = NULL;
	}
	
	/* set up the pixel deps */
	pixel_deps_off = alias_off + (sizeof (FileAlias) * myFile->file_info->nAliases);
	if (myFile->size_info > pixel_deps_off) {
		myFile->nPixelDeps = *( (u_int32_t *)( (void *)(myFile->file_info) + pixel_deps_off) );
		myFile->PixelDeps = (OID *)( (void *)(myFile->file_info) + pixel_deps_off + sizeof (u_int32_t));
	} else {
		myFile->nPixelDeps = 0;
		myFile->PixelDeps = NULL;
	}

	myFile->size_rep = myFile->file_info->size;

	return (1);
}


OID check_aliases (FileRep *existFile, FileRep *myFile) {
unsigned int i, nAliases;
OID found=0;
FileAlias *alias;


	if (!existFile->file_info || !myFile->file_info) return (0);

	/* Check the name */
	if (! strncmp ((char *)myFile->file_info->name,(char *)existFile->file_info->name,OMEIS_PATH_SIZE) ) {
		return (existFile->ID);
	}

	/* No aliases, and name didn't match, so return myFile's OID */
	if ( (nAliases = existFile->file_info->nAliases) == 0 ) {
		return (myFile->ID);
	}
	
	alias = existFile->aliases;
	if (alias) {
		for (i = 0; i < nAliases && !found; i++) {
			if (! strncmp (alias->name,(char *)myFile->file_info->name,OMEIS_PATH_SIZE) )
				found = alias->ID;
			alias++;
		}
	}

	if (found) return found;
	else return (myFile->ID);
	return (found);
}

/*
	Makes aliasFile an alias to myFile's ID (representative file - repFile).
	Sets aliasFile's isAlias to point at myFile's ID.
	Adds aliasFile to myFile's list of aliases.
	unlinks aliasFile, and sets a symlink to myFile
	
	reopens aliasFile as read-only
	returns true on success
*/
int make_alias (FileRep *myFile, FileRep *aliasFile) {
unsigned int i, nAliases;
FileAlias *new_alias;
size_t pix_dep_off, pix_dep_size;
OID *PixelDeps;
int myFlags;
FileInfo *info_myFile;
char backupName[OMEIS_PATH_SIZE];
char relPath[OMEIS_PATH_SIZE];
int status;

	/* Get both file's infos in write mode */
	if ( GetFileInfo (myFile,'w') != 1) {
		OMEIS_DoError ("Could not read the File info for FileID=%llu.",(unsigned long long)myFile->ID);
		return (0);
	}
	if ( GetFileInfo (aliasFile,'w') != 1) {
		OMEIS_DoError ("Could not read the File info for FileID=%llu.",(unsigned long long)aliasFile->ID);
		return (0);
	}
	
	/* if the file is mmapped, unmap it */
	if (myFile->is_mmapped) {
		munmap (myFile->file_buf, myFile->size_rep);
		myFile->file_buf = NULL;
		myFile->is_mmapped = 0;
	}

	/* Copy the alias file's path, and rename it to a temporary backup (append ~) */
	strncpy (backupName,aliasFile->path_rep,OMEIS_PATH_SIZE-1);
	strcat (backupName,"~");
	if (rename (aliasFile->path_rep,backupName) == -1) {
		OMEIS_DoError ("Error making backup of FileID=%llu: %s.",
			(unsigned long long)aliasFile->ID,strerror (errno));
		free (info_myFile);
		return (0);
	}

	/* make a symlink between the original and the alias */
	if (symlink (get_rel_path(myFile->path_rep,aliasFile->path_rep,relPath), aliasFile->path_rep) == -1) {
		OMEIS_DoError ("Error making symlink from %s to %s: %s.",
			aliasFile->path_rep,relPath,strerror (errno));
		free (info_myFile);
		/* restore backup on error */
		if (rename (backupName, aliasFile->path_rep) == -1) {
			OMEIS_DoError ("Error restoring backup %s.",backupName);
			return (0);
		}
		return (0);
	}
	
	/*
	* file infos are mmap'ed, exclusive locked and read-write at this point.
	* The info for myFile will be larger by one FileAlias.
	* Since we're changing the size, we allocate our own memory for this modified info
	*/
	if (! (info_myFile = (FileInfo *) malloc (myFile->size_info + sizeof (FileAlias)) ) ) {
		OMEIS_DoError ("Could not get a File info object (out of memory?).");
		return (0);
	}
	memset(info_myFile, 0, myFile->size_info + sizeof (FileAlias));

	/*
	* myFile needs an extra FileAlias, so we block-copy everything up to and including the
	* aliases, then set the values for the new one, then block-copy the pixel deps
	*/
	pix_dep_off = sizeof (FileInfo) + (sizeof (FileAlias) * myFile->file_info->nAliases);
	pix_dep_size = sizeof (OID) * myFile->nPixelDeps;

	memcpy (info_myFile,myFile->file_info,pix_dep_off);
	new_alias = (FileAlias *) ( (void *)(info_myFile) + pix_dep_off);
	new_alias->ID = aliasFile->ID;
	strncpy (new_alias->name,(char *)aliasFile->file_info->name,OMEIS_PATH_SIZE);
	(info_myFile->nAliases)++;
	if (pix_dep_size) {
		pix_dep_size += sizeof (u_int32_t); /* add space for nPixelDeps if there are any*/
		memcpy ((void *)(info_myFile) + pix_dep_off + sizeof (FileAlias), (void *)(myFile->file_info) + pix_dep_off, pix_dep_size);
	}

	/* Now we just call SetFileInfo with our new infos. */
	if ( (status = SetFileInfo (myFile, info_myFile, myFile->size_info + sizeof (FileAlias))) != 1) {
		OMEIS_DoError ("Could not update the File info for FileID=%llu. Status=%d",(unsigned long long)myFile->ID,status);
		free (info_myFile);
		if (rename (backupName, aliasFile->path_rep) == -1) {
			OMEIS_DoError ("Error restoring backup %s.",backupName);
			return (0);
		}
		return (0);
	}

	/* We don't need this anymore */
	free (info_myFile);
	
	/* Ditch the backup */
	unlink (backupName);
	
	/* aliasFile just needs its isAlias setting changed */
	aliasFile->file_info->isAlias = myFile->ID;

	/* return true */
	return (1);

}


/*
  This removes aliasFile's ID from myFile's alias list
*/
int remove_alias (FileRep *myFile, OID aliasID) {
int i;
FileAlias *myAlias, *srcAlias;
size_t size_move;

	if (!myFile->file_info) return (0);
	if (!(myFile->rorw_info == 'w' || myFile->rorw_info == 'n') ) return (0);
	if (!(myFile->aliases) ) return (1);

	/* remove references in myFile's alias list to aliasFile's ID  */
	myAlias = myFile->aliases;
	for (i=0; myAlias->ID !=aliasID && i<myFile->file_info->nAliases; i++)
		myAlias++;

	if (myAlias->ID == aliasID) {
		srcAlias = myAlias;
		srcAlias++;
		(myFile->file_info->nAliases)--;
		size_move = sizeof (FileAlias) * (myFile->file_info->nAliases - i) +
			sizeof (OID) * myFile->nPixelDeps;

		if (size_move) memmove( (void *)myAlias, (void *)srcAlias, size_move);
		
		/* write the file and fix file size */
		msync (myFile->file_info, myFile->size_info, MS_SYNC);
		munmap (myFile->file_info, myFile->size_info);
		myFile->file_info = NULL;

		myFile->size_info -= sizeof (FileAlias);
		ftruncate (myFile->fd_info, myFile->size_info);
		GetFileInfo (myFile,myFile->rorw_info);
	}
	
	return (1);
}


/*
  Check if myFile has a dependency on myPixels
  returns 1 if a dependency exists
  returns 0 if no dependency exists
  returns < 0 on error
 */

int check_pixels_dep (FileRep *myFile, OID theDep) {
unsigned int i;
u_int32_t nPixelDeps;
OID found=0;
OID *myDep;

	if (!myFile->file_info) return (-1);

	/* No pixel deps, so return 0 */
	if ( (nPixelDeps = myFile->nPixelDeps) == 0 ) {
		return (0);
	}

	myDep = myFile->PixelDeps;
	if (myDep) {
		for (i = 0; i < nPixelDeps && *myDep != theDep; i++)
			myDep++;
	}
	
	if (*myDep == theDep ) return (1);
	return (0);
}

/*
  This removes theDep PixelsID from myFile's pixel_deps list
*/
int RemovePixelsDep (FileRep *myFile, OID theDep) {
int i;
OID *myDep, *srcDep;
size_t size_move, pixel_deps_off;
u_int32_t *newNdeps;

	if (!myFile->file_info) {
		if ( GetFileInfo (myFile,'w') != 1) {
			OMEIS_DoError ("Could not read the File info for FileID=%llu.",(unsigned long long)myFile->ID);
			return (0);
		}
	}
	if (!(myFile->rorw_info == 'w' || myFile->rorw_info == 'n') ) return (0);
	if (!(myFile->PixelDeps) ) return (1);
	if (!(myFile->nPixelDeps) ) return (1);

	pixel_deps_off = sizeof (FileInfo) + (sizeof (FileAlias) * myFile->file_info->nAliases);
	newNdeps = ( (u_int32_t *)( (void *)myFile->file_info + pixel_deps_off) );

	/* remove references in myFile's deps list to OID of Pixels  */
	myDep = myFile->PixelDeps;
	for (i=0; *myDep != theDep && i<myFile->nPixelDeps; i++)
		myDep++;

	if (*myDep == theDep) {
		srcDep = myDep;
		srcDep++;
		*newNdeps = myFile->nPixelDeps - 1;
		(myFile->nPixelDeps)--;
		size_move = sizeof (OID) * (myFile->nPixelDeps - i);

		if (size_move) memmove( (void *)myDep, (void *)srcDep, size_move);
		
		/* write the file and fix file size */
		msync (myFile->file_info, myFile->size_info, MS_SYNC);
		munmap (myFile->file_info, myFile->size_info);
		myFile->file_info = NULL;
		/* don't close the file lest we lose the lock */

		myFile->size_info -= sizeof (OID);
		if (myFile->nPixelDeps == 0) myFile->size_info -= sizeof (u_int32_t);
		ftruncate (myFile->fd_info, myFile->size_info);
		GetFileInfo (myFile,myFile->rorw_info);
	}
	
	return (1);
}


int MakePixelsDep (FileRep *myFile, OID theDep) {
OID *newDep;
u_int32_t *newNdeps;
FileInfo *info_myFile;
int hasDep;
size_t size_extra, pixel_deps_off;
int status;

	/* Get the file's info in write mode */
	if (!myFile->file_info) {
		if ( GetFileInfo (myFile,'w') != 1) {
			OMEIS_DoError ("Could not read the File info for FileID=%llu.",(unsigned long long)myFile->ID);
			return (0);
		}
	}

	if ( (hasDep = check_pixels_dep (myFile,theDep)) < 0) {
		OMEIS_DoError ("Could not check the pixel dependencies for FileID=%llu.",(unsigned long long)myFile->ID);
		return (0);
	} else if (hasDep == 1) {
		return (1);
	}
	
	
	/*
	* file infos are mmap'ed, exclusive locked and read-write at this point.
	* The info for myFile will be larger by one PixelsDep.
	* If there are no PixelDeps, then the info file will be larger by an additional u_int32_t
	* Since we're changing the size, we allocate our own memory for this modified info
	*/
	size_extra = sizeof (OID);
	if (!myFile->nPixelDeps) size_extra += sizeof (u_int32_t);
	if (! (info_myFile = (FileInfo *) malloc (myFile->size_info + size_extra) ) ) {
		OMEIS_DoError ("Could not get a File info object (out of memory?).");
		freeFileRep (myFile);
		return (0);
	}

	/*
	* myFile needs an extra OID, so we block-copy everything then set the new OID
	*/
	memcpy (info_myFile, myFile->file_info, myFile->size_info);
	pixel_deps_off = sizeof (FileInfo) + (sizeof (FileAlias) * myFile->file_info->nAliases);
	newNdeps = ( (u_int32_t *)( (void *)info_myFile + pixel_deps_off) );
	*newNdeps = myFile->nPixelDeps + 1;

	newDep = (OID *)( (void *)(info_myFile) + pixel_deps_off + sizeof(u_int32_t) + (sizeof (OID) * (myFile->nPixelDeps)));
	*newDep = theDep;
	
	/* Now we just call SetFileInfo with our new infos. */
	if ( (status = SetFileInfo (myFile, info_myFile, myFile->size_info + size_extra)) != 1) {
		OMEIS_DoError ("Could not update the File info for FileID=%llu. Status=%d",(unsigned long long)myFile->ID,status);
		free (info_myFile);
		return (0);
	}

	/* We don't need this anymore */
	free (info_myFile);

	/* return true */
	return (1);

}



char *get_rel_path (char *toPath, const char *fromPath, char *pathBuf) {
char *tmp1,*tmp2;
int nBack=0;

	strcpy (pathBuf,"");
	
	/* Skip identical path components until we get to the last '/' */
	/* Keep track of the last path component before we see a difference. */
	tmp1 = strrchr (toPath,'/');
	tmp2 = toPath; /* The first non-identical path component initialized to start of toPath */
	if (tmp1) tmp1++;
	while (*toPath && *fromPath && *toPath == *fromPath && toPath != tmp1) {
		if (*toPath == '/') tmp2 = toPath; /* update last identical path component pointer */
		toPath++;
		fromPath++;
	}
	
	/*
	  if tmp2 points at '/', andvance it by one.
	*/
	if (*tmp2 == '/') tmp2++;
	
	/* rewind toPath to point at the first character of the first non-identical path component (tmp2) */
	toPath = tmp2;

	/* Get the number of '../' we need to put in by counting remaining '/' in fromPath */
	while (*fromPath) {
		if (*fromPath++ == '/') nBack++;
	}

	/* use tmp2 to point at the end (NULL) of pathBuf after we add all the '../' */
	tmp2 = pathBuf + (nBack*3);
	while (nBack) {
		strcat (pathBuf,"../");
		nBack--;
	}
	
	/* Copy the non-identical path components after the last '../' */
	while (*toPath) {
		*tmp2++ = *toPath++;
	}
	*tmp2 = '\0';
	
	return (pathBuf);
}

/*
OID FinishFile (FileRep *myFile) {
  Call this only to balance a call to NewFile()
  this calls freeFileRep(myFile) and returns the final FileID.
  Acessing myFile after this call should cause a segfault.
  Most errors at this point will cause the file to be deleted.
*/
OID FinishFile (FileRep *myFile) {
OID myID, existOID, aliasOID;
char path_rep[OMEIS_PATH_SIZE],path_info[OMEIS_PATH_SIZE];
FileRep *existFile;

	/* Set up the paths */
	*path_rep = *path_info = '\0';

	if (myFile->path_rep) strncpy (path_rep,myFile->path_rep,OMEIS_PATH_SIZE);
	if (myFile->path_info) strncpy (path_info,myFile->path_info,OMEIS_PATH_SIZE);

	/* Get SHA1 */
	if ( get_md_from_buffer (myFile->file_buf, myFile->size_rep, myFile->file_info->sha1) < 0 ) {
		DeleteFile (myFile);
		return (0);
	}

	/*
	  Put the SHA1 in the DB.
	  If sha1DB_put returns non-zero, either it exists, or there was an error.
	*/
	if ( sha1DB_put (myFile->path_DB, myFile->file_info->sha1, myFile->ID) ) {
		if ( (existOID = sha1DB_get (myFile->path_DB, myFile->file_info->sha1)) ) {
			/* Get a FileRep struct for the existing file */
			if (! (existFile = newFileRep (existOID))) {
				OMEIS_DoError ("Could not get a File object (out of memory?).");
				DeleteFile (myFile);
				return (0);
			}
	
			GetFileInfo (existFile,'r');
	
			/* Check the original for duplicate alias */
			aliasOID = check_aliases (existFile,myFile);
			if ( !aliasOID ) {
				OMEIS_DoError ("Could not check aliases in FileID=%llu for FileID=%llu.",
					(unsigned long long)existFile->ID,
					(unsigned long long)myFile->ID);
				freeFileRep (existFile);
				DeleteFile (myFile);
				return (0);
			} else if (aliasOID != myFile->ID) {
			/* existFile has a matching alias */
				freeFileRep (existFile);
				DeleteFile (myFile);
				return (aliasOID);
			} else {
			/* existFile has no matching alias (we keep myFile, but make it an alias) */
				/* unlinks repository file (myFile), makes a symlink to existFile,
				  records alias in existFile, and sets myFile.isAlias to existFile's ID.
				  if anything goes wrong here, this function will return 0.
				  If everything's OK, it will return 1.
				*/
	
				/* myFile becomes the alias */
				if (! (make_alias (existFile,myFile)) ) {
					OMEIS_DoError ("Could not make an alias from %llu to %llu.",
						(unsigned long long)myFile->ID,
						(unsigned long long)existFile->ID);
					freeFileRep (existFile);
					DeleteFile (myFile);
					return (0);
				}			
			}
			freeFileRep (existFile);
		} else {
			OMEIS_DoError ("In FinishFile, Error writing SHA1-DB for FileID=%llu: %s",
				(unsigned long long)myFile->ID, strerror (errno) );
			DeleteFile (myFile);
			return (0);
		}
	}


	myID = myFile->ID;

	freeFileRep (myFile);

	chmod (path_rep,0400);
	chmod (path_info,0400);

	return (myID);
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
			return (0);
		}
    }

	ID = FinishFile (myFile);
	closeInputFile (infile,isLocalFile);
	return (ID);
}
