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
#include <stdlib.h>
#include <string.h> 
#include <ctype.h> 
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <math.h>
#include <float.h>

#include <tiffio.h>

#include "Pixels.h"
#include "File.h"
#include "OMEIS_Error.h"
#include "update.h"

/* Private prototypes */
static void
deletePixels (PixelsRep *myPixels);
static int
openConvertFile (PixelsRep *myPixels, char rorw);
static void
closeConvertFile (PixelsRep *myPixels);
static int
unpackBits (void* read_buf, int read_bitspp, void* write_buf, int write_bytespp, int nlength);
static void 
extractRGBChannels(uint8* read_buf, int nPix, int chan, uint8* write_buf);



/*
  PixelRep keeps track of everything having to do with pixel i/o to the repository.
*/
void freePixelsRep (PixelsRep *myPixels) {
	if (!myPixels->is_mmapped) {
		if (myPixels->planeInfos) free (myPixels->planeInfos);
		if (myPixels->stackInfos) free (myPixels->stackInfos);
		if (myPixels->head) free (myPixels->head);
	} else {
		if (myPixels->head) munmap (myPixels->head, myPixels->size_info);
		if (myPixels->pixels) munmap (myPixels->pixels, myPixels->size_rep);
	}

	if (myPixels->fd_info >=0 ) close (myPixels->fd_info);
	closeConvertFile (myPixels);
	if (myPixels->fd_rep >=0 ) close (myPixels->fd_rep);
	free (myPixels);
}



/*
  The constructor doesn't do very much other than allocate and initialize
  memory.  If an ID is passed in, it will set the paths to the dependent files,
  but not open anything.
*/
PixelsRep *newPixelsRep (OID ID)
{
PixelsRep *myPixels;
char *root="Pixels/";
char *pixIDfile="Pixels/lastPix";
char *sha1DBfile="Pixels/sha1DB.idx";

	if (! (myPixels =  (PixelsRep *)malloc (sizeof (PixelsRep)))  )
		return (NULL);
	myPixels = memset(myPixels, 0, sizeof(PixelsRep));
	
	strcpy (myPixels->path_rep,root);
	strcpy (myPixels->path_info,root);
	strcpy (myPixels->path_thumb,root);
	strcpy (myPixels->path_ID,pixIDfile);
	strcpy (myPixels->path_DB,sha1DBfile);

	/* file descriptors reset to -1 */
	myPixels->fd_rep = -1;
	myPixels->fd_info = -1;
	myPixels->fd_conv = -1;

	/* If we got an ID, set the paths */
	if (ID) {
		if (! getRepPath (ID,myPixels->path_rep,0)) {
			OMEIS_DoError ("Could not get path to pixels file.");
			freePixelsRep (myPixels);
			return (NULL);
		}
		strcpy (myPixels->path_info,myPixels->path_rep);
		strcat (myPixels->path_info,".info");
		strcpy (myPixels->path_conv,myPixels->path_rep);
		strcat (myPixels->path_conv,".convert");
		strcpy (myPixels->path_thumb,myPixels->path_rep);
		strcat (myPixels->path_thumb,".thumb");
		myPixels->ID = ID;
	}

	return (myPixels);
}


/*
  The following functions deal with opening for reading or writing the header 
  and repository files used by PixelsRep

  openPixelsFile -> opens header (calls openHeaderFile) and repository.  
  		rorw may be set to 'w' (write), 'r' (read), 'i' (info), or 'n' (new file).
  openHeaderFile -> this function opens the Header file. If the header file is 
                    of the same version as OMEIS then it is uneventful. if, 
					however, the header file is of a previous version, updateHeaderFile 
					is called to update the HeaderFile.
  updateHeaderFile -> this function updates the Header file to newest format. Returns old
                      header format.
*/

static int updateHeaderFile (PixelsRep *myPixels, int fromVers)
{
void *mmap_info=NULL;
int mmap_flags=PROT_READ|PROT_WRITE;
int ret=0; /* variable stores the pixel files original version */
int nPlanes, nStacks;
pixHeader* head;
size_t new_size;
int vers;
int i;
int t,c,z;
planeInfo* planeInfoP;
char nullByte=0;
	
	/*  figure out from the old header how many planes and stacks there are
		to predict the size of the new header */
	head = myPixels->head;
	nPlanes = head->dz * head->dc * head->dt;
	nStacks = head->dc * head->dt;
	vers = head->vers;
	
	new_size = sizeof(pixHeader) + sizeof(planeInfo) * nPlanes + 
			sizeof(stackInfo) * nStacks;

	/* close read only file and open it again with exclusive write access*/
	if (myPixels->is_mmapped) munmap (myPixels->head, myPixels->size_info);
	close(myPixels->fd_info);
	myPixels->size_info = new_size;
	chmod (myPixels->path_info,0600);
	if ( (myPixels->fd_info = open (myPixels->path_info, O_RDWR, 0600)) < 0) {
		return (-1);
	}
	lockRepFile (myPixels->fd_info,'w',0LL,0LL);


	/* expand the header file so the new header will fit and then mmap */
	if (lseek(myPixels->fd_info, myPixels->size_info-1, SEEK_SET) < 0) {
		OMEIS_DoError ("During update, header file resize failed");
		close(myPixels->fd_info);
		return (-2);
	}
	if (write(myPixels->fd_info, &nullByte, 1) < 1){
		OMEIS_DoError ("During update, header file resize failed");
		close(myPixels->fd_info);
		return (-2);
	}

	/* Go back to the beginning, and mmap the whole thing */
	lseek(myPixels->fd_info, 0LL, SEEK_SET);
	if ((mmap_info = mmap (NULL, myPixels->size_info, mmap_flags, MAP_SHARED, 
		myPixels->fd_info, 0LL)) == (void *) -1)
			return (-3);
	myPixels->is_mmapped = 1;
	
	/* try to update based on version */
	switch(vers){
		case 1:
			OMEIS_DoError ("Upgrade from vers 1 doesn't work (PixelsID=%llu)", (unsigned long long)myPixels->ID);
		/*
			myPixels->head = update_header_v1( (pixHeader_v1 *) mmap_info );
			
			myPixels->size_rep = head->dx * head->dy * head->dz * head->dc * head->dt * head->bp;
			myPixels->planeInfos = update_planeInfos_v1( (planeInfo_v2 *) (mmap_info + sizeof(pixHeader_v1)), 
								head->dz * head->dc * head->dt);
			myPixels->stackInfos = update_stackInfos_v1( (stackInfo_v2 *) 
			(mmap_info + sizeof(pixHeader_v1) + (sizeof (planeInfo_v1) * head->dz * head->dc * head->dt)), 
			head->dc * head->dt);
		*/
			
			ret = 1;
		case 2:
			/* N.B: If header is vers 2 we need to recompute the statistics to compute the histogram bins */	
		case 3:
			/* N.B: If header is vers 3 we need to recompute the histogram bins */	
			if (head->isFinished == 1) {
				myPixels->planeInfos = (planeInfo*) ( (u_int8_t *) mmap_info + sizeof(pixHeader) );
				myPixels->stackInfos = (stackInfo*) ( (u_int8_t *) mmap_info + sizeof(pixHeader) + sizeof (planeInfo) * nPlanes );
				
				for (i=0; i<nPlanes; i++)
					myPixels->planeInfos[i].stats_OK = 0;
				for (i=0; i<nStacks; i++)
					myPixels->stackInfos[i].stats_OK = 0;
			}
			
			/* put the stamp of approval */
			head->vers = (u_int8_t) 4;
			ret = 3; /* ret 3 is returned even if the original file was in ver 2 */
			break;
		case 4:
			/* if the header is in vers 4 already we are lucky */
			/* N.B: this could be because another process updated this file while this process waited  */
			/*      for an exclusive read/write lock */
			
			ret = 4;
			break;
				
		default:
			OMEIS_DoError ("Incompatible file type.");
			return (-10);
			break;
	}
	lockRepFile (myPixels->fd_info,'u',0LL,sizeof (pixHeader));
	chmod (myPixels->path_info,0400);
	return ret;
}


/* returns the orginal version number of the pixel header file */
/* N.B: during this function call the pixel header file is updated to the newest verison, if appropriate*/
static int openHeaderFile (PixelsRep *myPixels, char rorw)
{
void *mmap_info=NULL;
pixHeader *head;
struct stat fStat;
int open_flags=0, mmap_flags=0;

	if (rorw == 'r' || rorw == 'i') {
		open_flags = O_RDONLY;
		mmap_flags = PROT_READ;
	} else if (rorw == 'w' || rorw == 'n') {
		open_flags = O_RDWR;
		mmap_flags = PROT_READ|PROT_WRITE;
	} else {
		return (-1);
	}
	
	/* open the info file (header) */
	if (myPixels->fd_info < 0) {
		if ( (myPixels->fd_info = open (myPixels->path_info, open_flags, 0600)) < 0)
			return (-2);
		}
	if (rorw != 'n') {
	/* wait until we can get a read lock on the header */
		if (lockRepFile (myPixels->fd_info,'r',0LL,0LL) < 0){
			OMEIS_DoError ("lockRepFile failed at openHeaderFile");
		}
	} else {
	/*
	  If the Pixels file needs recovering, we're going to hang all subsequent requests
	  until we've recovered it.  We do this by putting a write-lock on the header
	  if the pixels file doesn't exist.
	*/
		if (myPixels->fd_rep < 0) {
			if ( (myPixels->fd_rep = open (myPixels->path_rep, open_flags, 0600)) < 0) {
				lockRepFile (myPixels->fd_info,'w',0LL,0LL); /* lock the whole thing */
			}
		}
	}

	/* get the size of the header. */
	if (!myPixels->size_info) {
		if (fstat (myPixels->fd_info , &fStat) != 0)
			return (-8);
		myPixels->size_info = fStat.st_size;
	}

	/* mmap the header */
	if ((mmap_info = mmap (NULL, myPixels->size_info, mmap_flags, MAP_SHARED, myPixels->fd_info, 0LL)) == (void *) -1)
		return (-3);


	myPixels->head = head = (pixHeader *) mmap_info;
	myPixels->size_rep = head->dx * head->dy * head->dz * head->dc * head->dt * head->bp;
	myPixels->is_mmapped = 1;
	
	if (!head->isFinished && rorw == 'r') {
			OMEIS_DoError ("Attempt to read a write-only file");
			return (-4);
	}

	if (head->isFinished && rorw == 'w') {
			OMEIS_DoError ("Attempt to write to a read-only file");
			return (-5);
	}

	/* if its a new file, set the signature and version */
	if (rorw == 'n') {
		head->mySig = OME_IS_PIXL_SIG;
		head->vers  = OME_IS_PIXL_VER;
		if (!myPixels->size_rep) {
			if (stat (myPixels->path_rep , &fStat) != 0)
				return (-8);
			myPixels->size_rep = fStat.st_size;
		}
		return OME_IS_PIXL_VER;
	}
	
	/* check the signature and version if they're in the file */
	if (head->mySig != OME_IS_PIXL_SIG ||
		head->vers  != OME_IS_PIXL_VER){
		
		int ret; /* variable stores the pixel file's original version */
		
		/* release the read lock for the file, we will need to upgrade to write */
		lockRepFile (myPixels->fd_info,'u',0LL,0LL);
		if ( (ret=updateHeaderFile(myPixels, head->vers)) < 0){	
				OMEIS_DoError ("Incompatible file type. Update failed.");
			return (-10);
		}
		
		/* all write updates were done to the file */
		lockRepFile (myPixels->fd_info,'r',0LL,0LL);
		return ret;
	}
	
	/* if we get here we are opening an already updated pixels header file */
	myPixels->planeInfos = (planeInfo *) ( (u_int8_t *) mmap_info + sizeof(pixHeader));
	myPixels->stackInfos = (stackInfo *) ( (u_int8_t *) mmap_info + (sizeof (planeInfo) * head->dz * head->dc * head->dt)  + sizeof(pixHeader) );

	return OME_IS_PIXL_VER;	
}


int openPixelsFile (PixelsRep *myPixels, char rorw) {
void *mmap_rep=NULL;
pixHeader *head;
struct stat fStat;
int open_flags=0, mmap_flags=0;
int ret;
int pixel_file_vers;

	if (rorw == 'r' || rorw == 'i') {
		open_flags = O_RDONLY;
		mmap_flags = PROT_READ;
	} else if (rorw == 'w' || rorw == 'n') {
		open_flags = O_RDWR;
		mmap_flags = PROT_READ|PROT_WRITE;
	}
	
	if ( (pixel_file_vers = openHeaderFile(myPixels, rorw)) < 0){
		OMEIS_DoError ("Unable to open Header File ");
		return (-1);
	}

	/* open and mmap the repository file unless we're just getting info */
	/* for pixel files of version 1, 2 and 3 the statistics need to be recomputed so the pixels must be loaded */
	if (rorw != 'i' || pixel_file_vers == 1 || pixel_file_vers == 2 || pixel_file_vers == 3) {
		if (myPixels->fd_rep < 0) {
			if ( (myPixels->fd_rep = openRepFile (myPixels->path_rep, open_flags)) < 0) {
				/* If we ran recoverPixels successfully, we're done.
				   N.B.: recoverPixels() will mmap the recovered Pixels file, so
				   if any of the mmap logic changes below, it should be reflected
				   in recoverPixels()
				*/
				if (rorw == 'r') {
					ret = recoverPixels (myPixels, open_flags, mmap_flags, 0);
					/*  Release the write lock we issued when we couldn't find the file before */
					lockRepFile (myPixels->fd_info,'u',0LL,sizeof (pixHeader));
					return (ret);
				}
			}
			
			if (myPixels->fd_rep < 0) {
			/* Very bad juju:  The pixels file is just plain gone. That's why we're returning -11:  Way worse than -10 */
				return (-11);
			}
		}
		if ( (mmap_rep = mmap (NULL, myPixels->size_rep, mmap_flags, MAP_SHARED, myPixels->fd_rep, 0LL)) == (void *) -1)
			return (-4);
		myPixels->pixels = mmap_rep;
	} else {
		/* just getting info, so no rep file for you. */
		myPixels->pixels = mmap_rep = NULL;
	}
	
	/* compute statistics if appropriate */
	if (pixel_file_vers == 1 || pixel_file_vers == 2 || pixel_file_vers == 3){
		/* we might need to recompute the statistics after an update */	
		lockRepFile (myPixels->fd_info,'u',0LL,sizeof (pixHeader));
		if (FinishStats (myPixels, (char) 0) < 0){
			OMEIS_DoError ("Unable to compute statistics while updating pixel file");
			return (-1);
		}
	}
	lockRepFile (myPixels->fd_info,'u',0LL,sizeof (pixHeader));
	return (1);
}


static int
openConvertFile (PixelsRep *myPixels, char rorw) {
int myFlags;
int myAccess, myOpen, myMode = 0600;

	if (rorw == 'r') {
		myAccess = O_RDONLY;
		myOpen = O_RDONLY;
	} else if (rorw == 'w') {
		myAccess = O_WRONLY;
		myOpen = O_WRONLY | O_APPEND | O_CREAT;
	} else
		return (0);

/* return if already opened with correct access. */
	if (myPixels->fd_conv >= 0) {
		myFlags = fcntl (myPixels->fd_conv, F_GETFL, 0);
		if (myFlags < 0 || ((myFlags & O_ACCMODE) != myAccess)) {
			close (myPixels->fd_conv);
		} else {
			lseek (myPixels->fd_conv, 0, SEEK_SET);
			return (1);
		}
	}

/* Open the closed fd */
	if ( (myPixels->fd_conv = open (myPixels->path_conv, myOpen, myMode)) < 0) {
		OMEIS_DoError ("openConvertFile (PixelsID=%llu). Couldn't open convert file=%s (%c): %s",
				(unsigned long long)myPixels->ID,myPixels->path_conv,
				rorw,strerror (errno));
		return (0);
	} else {
		return (1);
	}
}

static void
closeConvertFile (PixelsRep *myPixels) {
	if (myPixels->fd_conv >= 0) {
		close (myPixels->fd_conv);
		myPixels->fd_conv = -1;
	}
}


int
isConvertVerified (PixelsRep *myPixels) {
int convFD;
convertFileRec convRec, conv0Rec;
int isVerified=0;
size_t nRec=0, nIO=0;
char done = 0;

	memset(&conv0Rec, 0, sizeof(convertFileRec));

	if ( !openConvertFile (myPixels, 'r') ) {
		OMEIS_DoError ("Could not open %s: %s",myPixels->path_conv,strerror( errno ));
		return (0);
	}
	convFD = myPixels->fd_conv;

	while (!done) {
		nIO = read (convFD, (void *)(&convRec), sizeof (convertFileRec));
		if (nIO == 0) {
			done = 1;
			break;
		}
		if (nIO != sizeof (convertFileRec) ) {
			OMEIS_DoError ("Error reading convert record from %s: %s",
				myPixels->path_conv,strerror( errno ));
			break;
		}
		nRec++;
	}

	if (!done) {
	/* An error occurred */
		close (convFD);
		return (0);
	}

	if ( done && nRec > 1 && !memcmp (&convRec,&conv0Rec,sizeof(convertFileRec)) )
		isVerified = 1;

	return (isVerified);

}

/*
  This function attempts to recover a Pixels file from a set of Convert commands
  stored in a ".convert" file.
  The recovery is taken to a point where myPixels->fd_rep is set to a file opened
  and mmapped with the given flags.
  myPixels must have the header opened and read or mmapped in myPixels->header.
  if the verify parameter is true, then the convert commands from a ".convert" file are
  replayed into a ".verify" Pixels file, and a sha1 is calculated from the file.
  If the sha1 digest matches the one in the header, a convertFileRec of all 0's is appended to the file.
  Return conditions:
    If verify is true, then a result of 1 means the sha1s were identical.
    A result of < 1 means that they weren't for a variety of reasons.  The intended meaning is:
    "Check to see if these pixels are recoverable from their convert file"
    A return of 0 in this case means the file couldn't be opened.  Usually because there is no ".convert" file.

    If verify is false, then this will return 1 if the recovery was successfull, and < 1 if it wasn't.
    The intended meaning is "recover the pixels or else..."
    A 0 will never be returned if verify is false.
    Regardless of wether verify is true or false, if the ".convert" file wasn't previously verified,
    it will be after this call.
    The ".convert" file won't actually be erased unless there were no errors durring reading or verification,
    yet it failed to generate identical sha1s.
*/
int recoverPixels (PixelsRep *myPixels, int open_flags, int mmap_flags, char verify) {
char oldRepPath[OMEIS_PATH_SIZE], verRepPath[OMEIS_PATH_SIZE];
int convFD;
convertFileRec convRec, conv0Rec, conv1Rec;
FileRep *myFile = NULL;
size_t nIO=0, nPixPlane=0;
void *mmap_rep=NULL;
char *path_root="Pixels/";
char *verifySuff="verify",*doVerify=NULL, isVerified=0;
u_int8_t sha1[OME_DIGEST_LENGTH];
char done=0;
int i;


	strncpy (oldRepPath,myPixels->path_rep,OMEIS_PATH_SIZE-1);
	
	memset(&conv0Rec, 0, sizeof(convertFileRec));
	
	if (verify) {
		doVerify = verifySuff;
		sprintf (verRepPath,"%s.%s",myPixels->path_rep,verifySuff);
		unlink (verRepPath);
	}

	if ( !openConvertFile (myPixels, 'r') ) {
		OMEIS_DoError ("Could not open %s: %s",myPixels->path_conv,strerror( errno ));
		if (verify) return (0);
		else return (-101);
	}
	convFD = myPixels->fd_conv;

	strcpy (myPixels->path_rep,path_root);
	myPixels->fd_rep = newRepFile (myPixels->ID, myPixels->path_rep, myPixels->size_rep, doVerify);
	if (myPixels->fd_rep < 0) {
		OMEIS_DoError ("Could not make new repository file %s: %s",myPixels->path_rep,strerror( errno ));
		return (-102);
	}

	if ( (mmap_rep = mmap (NULL, myPixels->size_rep, PROT_READ|PROT_WRITE, MAP_SHARED, myPixels->fd_rep, 0LL)) == (void *) -1) {
		OMEIS_DoError ("Could not mmap new repository file %s: %s",myPixels->path_rep,strerror( errno ));
		closeConvertFile (myPixels);
		close (myPixels->fd_rep);
		myPixels->fd_rep = -1;
		return (-103);
	}
	myPixels->pixels = mmap_rep;


	nPixPlane = myPixels->head->dx * myPixels->head->dy;
/*
  Process the convert file
*/
	while (!done) {
		nIO = read (convFD, (void *)(&convRec), sizeof (convertFileRec));
		if (nIO == 0) {
			done = 1;
			break;
		}
		if (nIO != sizeof (convertFileRec) ) {
			OMEIS_DoError ("Error reading convert record from %s: %s",
				myPixels->path_conv,strerror( errno ));
			break;
		}
	/*
	  This is probably not the most efficient thing in the world, but we'll stash a single
	  FileRep, and check the ID of the convRec against the stashed one.  If they're different
	  we'll just throw ours away and get a new one.
	*/
		if (convRec.FileID && (!myFile || myFile->ID != convRec.FileID)) {
			if (myFile) freeFileRep (myFile);
			if ( !(myFile = GetFileRep (convRec.FileID,0,0)) ) {
				OMEIS_DoError ("Error opening FileID=%llu for conversion: %s",
					(unsigned long long)convRec.FileID,strerror( errno ));
				break;
			}
		}

		if (convRec.isTIFF && convRec.FileID) {
			nIO = ConvertTIFF (myPixels, myFile,
				convRec.spec.tiff.theZ, convRec.spec.tiff.theC, convRec.spec.tiff.theT, convRec.spec.tiff.dir_index, 0);
			if (nIO != nPixPlane) {
				OMEIS_DoError ("Error recovering %s: %s. Expected to read %llu pixels, but got only %llu.",
					myPixels->path_rep, strerror( errno ), (unsigned long long)nPixPlane, (unsigned long long)nIO);
				break;
			}
		} else if (convRec.FileID) {
			if ( (convRec.isBigEndian && !bigEndian()) || (!convRec.isBigEndian && bigEndian()) )
				myPixels->doSwap = 1;
			nIO = ConvertFile (myPixels, myFile,
				(size_t)convRec.spec.file.file_offset, (size_t)convRec.spec.file.pix_offset, (size_t)convRec.spec.file.nPix, 0);
			if (nIO != (size_t)convRec.spec.file.nPix) {
				OMEIS_DoError ("Error recovering %s: %s. Expected to read %llu pixels, but got only %llu.",
					myPixels->path_rep, strerror( errno ), (unsigned long long)convRec.spec.file.nPix, (unsigned long long)nIO);
				break;
			}
		}
	}

	/* Free our file cache */
	if (myFile) freeFileRep (myFile);

	if (!done) {
	/* An error occurred */
		closeConvertFile (myPixels);
		munmap (mmap_rep, myPixels->size_rep);
		myPixels->pixels = NULL;
		close (myPixels->fd_rep);
		myPixels->fd_rep = -1;
		unlink (myPixels->path_rep);
		strncpy (myPixels->path_rep,oldRepPath,OMEIS_PATH_SIZE-1);
		OMEIS_DoError ("Error recovering %s", myPixels->path_rep);
		return (-104);
	}
	
	if ( done && !memcmp (&convRec,&conv0Rec,sizeof(convertFileRec)) )
		isVerified = 1;

	if (!isVerified) {
	/* Calculate the SHA1 for the file we generated, and compare to the one in the header */
		if (get_md_from_buffer (myPixels->pixels, (size_t)myPixels->size_rep, (unsigned char *)sha1) < 0) {
			OMEIS_DoError ("Unable to retrieve SHA1 for Pixels file during verification.");
			closeConvertFile (myPixels);
			munmap (mmap_rep, myPixels->size_rep);
			myPixels->pixels = NULL;
			close (myPixels->fd_rep);
			myPixels->fd_rep = -1;
			unlink (myPixels->path_rep);
			strncpy (myPixels->path_rep,oldRepPath,OMEIS_PATH_SIZE-1);
			return(-107);
		}
		if (memcmp (sha1, myPixels->head->sha1, OME_DIGEST_LENGTH)) {
			closeConvertFile (myPixels);
			unlink (myPixels->path_conv);
			munmap (mmap_rep, myPixels->size_rep);
			myPixels->pixels = NULL;
			close (myPixels->fd_rep);
			myPixels->fd_rep = -1;
			unlink (myPixels->path_rep);
			OMEIS_DoError ("Verification failed - %s file deleted.",myPixels->path_conv);
			strncpy (myPixels->path_rep,oldRepPath,OMEIS_PATH_SIZE-1);
			return (-108);
		} else {
		/* Mark the convert file as verified */
		/* since we opened it read-only above, we have to reopen it for writing now */
			if ( !openConvertFile (myPixels, 'w') ) {
				OMEIS_DoError ("Could not open %s for writing (marking as verified): %s",myPixels->path_conv,
					strerror( errno ));
			} else {
				nIO = write (myPixels->fd_conv, (const void *)&conv0Rec, sizeof (convertFileRec));
				if (nIO != sizeof (convertFileRec))
					OMEIS_DoError ("Could not write verification to convert file %s: %s",myPixels->path_conv,
						strerror( errno ));
				else
				/* This hasn't been verified before, but it is now, so make it read-only. */
					chmod (myPixels->path_conv,0400);

				closeConvertFile (myPixels);
			}
		}
	} else
		closeConvertFile (myPixels);

/* Clean up the new Pixels file */
	munmap (mmap_rep, myPixels->size_rep);
	myPixels->pixels = NULL;
	close (myPixels->fd_rep);
	myPixels->fd_rep = -1;


	if (doVerify) {
	/* Delete the Pixels file we just made */
		unlink (myPixels->path_rep);
		strncpy (myPixels->path_rep,oldRepPath,OMEIS_PATH_SIZE-1);
	} else {
	/* Set the file to read-only */
		strncpy (myPixels->path_rep,oldRepPath,OMEIS_PATH_SIZE-1);
		fchmod (myPixels->fd_rep,0400);	
		if ( (myPixels->fd_rep = openRepFile (myPixels->path_rep, open_flags)) < 0 ) {
			unlink (myPixels->path_rep);
			OMEIS_DoError ("Couldn't open reconstituted Pixels file - %s deleted.",myPixels->path_rep);
			return (-109);
		}	
	/* mmap it the way it was requested */
		if ( (mmap_rep = mmap (NULL, myPixels->size_rep, mmap_flags, MAP_SHARED, myPixels->fd_rep, 0LL)) == (void *) -1) {
			close (myPixels->fd_rep);
			unlink (myPixels->path_rep);
			OMEIS_DoError ("Couldn't mmap reconstituted Pixels file - %s deleted.",myPixels->path_rep);
			return (-110);
		}
		myPixels->pixels = mmap_rep;
	}		
	
	return (1);
}



/*
  The next section is the external interface for PixelsRep:
  NewPixels - Starts a new pixels file in the repository
  GetPixelsRep - Gets a pre-existing pixels file by ID
  FinishPixels - converts a pixels file from write only to read only.
  
* This call makes a new Repository Pixels file.
* the file will be the correct size, and open and ready for writing.
* The function returns a pointer to the PixelsRep struct
* If anything goes wrong, the function returns NULL.
* 
*/
PixelsRep *NewPixels (
	ome_dim dx,
	ome_dim dy,
	ome_dim dz,
	ome_dim dc,
	ome_dim dt,
	ome_dim bp, /* bp is bytes per pixel */
	char isSigned,
	char isFloat
)
{
char error[OMEIS_ERROR_SIZE];
pixHeader *head;
PixelsRep *myPixels;
size_t size;
int result;

	if (! (myPixels = newPixelsRep (0LL)) ) {
		OMEIS_DoError ("BAH! - no memory");
		return (NULL);
	}
	myPixels->ID = nextID(myPixels->path_ID);
	if (myPixels->ID <= 0 && errno) {
		OMEIS_DoError ("Couldn't get next Pixels ID: %s",strerror (errno));
		freePixelsRep (myPixels);
		return (NULL);
	} else if (myPixels->ID <= 0){
		OMEIS_DoError ("Happy New Year !!!");
		freePixelsRep (myPixels);
		return (NULL);
	}

	size  = sizeof (pixHeader);
	size += sizeof (planeInfo) * dz * dc * dt;
	size += sizeof (stackInfo) * dc * dt;

	myPixels->size_info = size;
	myPixels->fd_info = newRepFile (myPixels->ID, myPixels->path_info, size, "info");
	if (myPixels->fd_info < 0) {
		OMEIS_DoError ("Couldn't open repository info file for PixelsID %llu (%s).",(unsigned long long)myPixels->ID,myPixels->path_info);
		freePixelsRep (myPixels);
		return (NULL);
	}

	size = dx * dy * dz * dc * dt * bp;
	myPixels->size_rep = size;

	myPixels->fd_rep = newRepFile (myPixels->ID, myPixels->path_rep, size, NULL);

	if (myPixels->fd_rep < 0) {
		OMEIS_DoError ("Couldn't open repository file for PixelsID %llu (%s).",(unsigned long long)myPixels->ID,myPixels->path_rep);
		freePixelsRep (myPixels);
		return (NULL);
	}
	
	if ( (result = openPixelsFile (myPixels, 'n')) < 0) {
		OMEIS_DoError ("openPixelsFile failed.");
		freePixelsRep (myPixels);
		return (NULL);
	}
	head = myPixels->head;
	head->dx = dx;
	head->dy = dy;
	head->dz = dz;
	head->dc = dc;
	head->dt = dt;
	head->bp = bp;
	head->isSigned = (isSigned ? 1 : 0);
	head->isFloat  = (isFloat  ? 1 : 0);
	
	/*
	  Since we called openPixelsFile with 'n', it didn't have the dx, dy, dz, etc,
	  so it did not assign where the infos are in relation to head.
	  So we must assign them here.
	*/
	myPixels->planeInfos = (planeInfo *) ( (char *)head + sizeof(pixHeader));
	myPixels->stackInfos = (stackInfo *) ( (char *)head + sizeof(pixHeader) + (sizeof (planeInfo) * dz * dc * dt));

	/* release the lock created by newRepFile */
	lockRepFile (myPixels->fd_rep,'u',0LL,0LL);
	
	/* set the path of the convert file */
	strcpy (myPixels->path_conv,myPixels->path_rep);
	strcat (myPixels->path_conv,".convert");
	
	/* set the path of the thumbnail file */
	strcpy (myPixels->path_thumb,myPixels->path_rep);
	strcat (myPixels->path_thumb,".thumb");

	return (myPixels);
}

/*
* This call opens an existing Pixels file for reading or writing.
* rorw can be 'r' or 'w'.
* bigEndian indicates wether I/O will be from/to a bigEndian source.
* The file's header information must already be set - done by NewPixels
* The function returns a pointer to the Pixels struct.
* The file's header is read-locked by openPixelsFile().
* If anything goes wrong, the function returns NULL.
*/
PixelsRep *GetPixelsRep (OID ID, char rorw, char isBigEndian)
{
PixelsRep *myPixels;
pixHeader *head;
int result;

	if (!ID) return (NULL);

	if (! (myPixels = newPixelsRep (ID))) {
		OMEIS_DoError ("Could not get a Pixels object.");
		return (NULL);
	}


	if ( (result = openPixelsFile (myPixels,rorw)) < 0) {
		OMEIS_DoError ("Could not open pixels file (ID=%llu). Result=%d",
				(unsigned long long) ID,result);
		freePixelsRep (myPixels);
		return (NULL);
	}

	if (! (head = myPixels->head) ) {
		OMEIS_DoError ("Pixels header is undefined.");
		freePixelsRep (myPixels);
		return (NULL);
	}
	
	if ( isBigEndian != bigEndian() && head->bp > 1) myPixels->doSwap = 1;

	return (myPixels);
}

/*
  If myID is 0, walk the entire repository verifying that pixels recovered with the convert commands
  match sha1s with the sha1s in the header.
  If the ".convert" file isn't verified (a convert record of all zeros at the end), then the file
  is recovered into a ".verify" file and its sha1 digest is computed.  If the sha1s match, the ".convert"
  file is marked as verified, and the original Pixels file is deleted.
  If the sha1s don't match, the ".convert" file is deleted.
  After calling this, there will be either a verified ".convert" file or a Pixels file, but not both.
*/

void
PurgePixels (OID myID) {
OID theID;
PixelsRep *myPixels;
char iamBigEndian, path_rep[OMEIS_PATH_SIZE];


	iamBigEndian = bigEndian();

	if (myID != 0) {
		myPixels = GetPixelsRep (myID, 'i', iamBigEndian);
		if (myPixels) {
			if (!isConvertVerified(myPixels)) {
				recoverPixels (myPixels, 0, 0, 1);
			}
			if (isConvertVerified(myPixels)) {
				strncpy (path_rep,myPixels->path_rep,OMEIS_PATH_SIZE-1);
				freePixelsRep (myPixels);
				unlink (path_rep);
			} else {
				freePixelsRep (myPixels);
			}
		}
	} else {
		myPixels = newPixelsRep (0LL);
		theID = lastID (myPixels->path_ID);
		freePixelsRep (myPixels);
		while (theID) {
			myPixels = GetPixelsRep (theID, 'i', iamBigEndian);
			if (myPixels) {
				if (!isConvertVerified(myPixels)) {
					recoverPixels (myPixels, 0, 0, 1);
				}
				if (isConvertVerified(myPixels)) {
					strncpy (path_rep,myPixels->path_rep,OMEIS_PATH_SIZE-1);
					freePixelsRep (myPixels);
					unlink (path_rep);
				} else {
					freePixelsRep (myPixels);
				}
			}
			theID--;
		}
	}
}

int
CheckCoords (PixelsRep * myPixels,
             ome_coord theX,
             ome_coord theY,
             ome_coord theZ,
             ome_coord theC,
             ome_coord theT)
{
	pixHeader *head;

	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);

	if (theX >= head->dx || theX < 0 ||
        theY >= head->dy || theY < 0 ||
        theZ >= head->dz || theZ < 0 ||
        theC >= head->dc || theC < 0 ||
        theT >= head->dt || theT < 0 ) {
		OMEIS_DoError ("Pix->CheckCoords:  Coordinates out of range.");
		return (0);
	}
	return (1);
}

/*
  Note that this is a byte offset - not a pixel offset.
*/
size_t GetOffset (PixelsRep *myPixels, ome_coord theX, ome_coord theY, ome_coord theZ, ome_coord theC, ome_coord theT) {
pixHeader *head;

	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	return ((((((theT*head->dc) + theC)*head->dz + theZ)*head->dy + theY)*head->dx + theX)*head->bp);
}





/*
  This reads the pixels at offset and writes nPix pixels to IO_stream or IO_mem
  Note that the offset parameter is a byte offset from (GetOffset),
  but the number returned is the number of pixels (not bytes).
*/
size_t DoPixelIO (PixelsRep *myPixels, size_t offset, size_t nPix, char rorw) {
size_t nIO=0;
size_t nBytes;
char *pixels,*pix_P;
pixHeader *head;
unsigned char bp;
size_t file_off;
char *IO_buf;
unsigned char *swap_buf;
unsigned long chunk_size;
unsigned long written=0;

	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	if (! (pixels = myPixels->pixels) ) return (0);
	if (! (bp = head->bp) ) return (0);
	
	nBytes = nPix*bp;
	file_off = offset;
	swap_buf = myPixels->swap_buf;
	chunk_size = OMEIS_IO_BUF_SIZE / bp;
	pix_P = pixels + offset;

	if (lockRepFile (myPixels->fd_rep,rorw,file_off,nBytes) < 0) return (0);

	if (myPixels->IO_stream) {
		if (rorw == 'w') {
			if (myPixels->doSwap && bp > 1) {
				nBytes = chunk_size*bp;
				while (written < nPix) {
					if (written+chunk_size > nPix) {
						chunk_size = nPix-written;
						nBytes = chunk_size*bp;
					}
					if ( (nIO = fread (swap_buf,bp,chunk_size,myPixels->IO_stream)) < chunk_size) return (written+nIO);
					else written += chunk_size;
					byteSwap (swap_buf, chunk_size, bp);
					memcpy (pix_P, swap_buf, nBytes);
					pix_P += nBytes;
				}
				nIO = written;
			} else nIO = fread (pix_P,bp,nPix,myPixels->IO_stream);
		} else {
			if (myPixels->doSwap && bp > 1) {
				nBytes = chunk_size*bp;
				while (written < nPix) {
					if (written+chunk_size > nPix) {
						chunk_size = nPix-written;
						nBytes = chunk_size*bp;
					}
					memcpy (swap_buf, pix_P, nBytes);
					byteSwap (swap_buf, chunk_size, bp);
					if ( (nIO = fwrite (swap_buf,bp,chunk_size,myPixels->IO_stream)) < chunk_size) return (written+nIO);
					else written += chunk_size;
					pix_P += nBytes;
				}
				nIO = written;
			} else nIO = fwrite (pix_P,bp,nPix,myPixels->IO_stream);
		}
	} else if (myPixels->IO_buf) {
		IO_buf = (char *)myPixels->IO_buf;
		if (rorw == 'w') {
			if (myPixels->doSwap && bp > 1) {
				nBytes = chunk_size*bp;
				while (written < nPix) {
					if (written+chunk_size > nPix) {
						chunk_size = nPix-written;
						nBytes = chunk_size*bp;
					}
					memcpy (swap_buf, IO_buf+myPixels->IO_buf_off, nBytes);
					written += chunk_size;
					byteSwap (swap_buf, chunk_size, bp);
					memcpy (pix_P, swap_buf, nBytes);
					pix_P += nBytes;
					myPixels->IO_buf_off += nBytes;
				}
				nIO = written;
			} else {
				memcpy (pix_P, IO_buf+myPixels->IO_buf_off, nBytes);
				myPixels->IO_buf_off += nBytes;
				nIO = nPix;
			}
		} else {
			if (myPixels->doSwap && bp > 1) {
				nBytes = chunk_size*bp;
				while (written < nPix) {
					if (written+chunk_size > nPix) {
						chunk_size = nPix-written;
						nBytes = chunk_size*bp;
					}
					memcpy (swap_buf, pix_P, nBytes);
					byteSwap (swap_buf, chunk_size, bp);
					memcpy (IO_buf+myPixels->IO_buf_off, pix_P, nBytes);
					written += chunk_size;
					pix_P += nBytes;
					myPixels->IO_buf_off += nBytes;
				}
				nIO = written;
			} else {
				memcpy (IO_buf+myPixels->IO_buf_off, pix_P, nBytes);
				myPixels->IO_buf_off += nBytes;
				nIO = nPix;
			}
		}
	}

	lockRepFile (myPixels->fd_rep,'u',file_off,nBytes);

	return (nIO);
}


/*
  These functions deal with re-scaling pixel intensity.
  The scaling information may be statisticaly based or fixed.
  fixChannelSpec fixes channel scaling information if specified with a statistical basis.
*/

void fixChannelSpec (PixelsRep *myPixels, channelSpecType *chSpec) {
stackInfo *stackInfoP;
pixHeader *head;
size_t stack_offset;

	if (!chSpec) return;
	if (chSpec->isFixed) return;

	if (!myPixels) return;
	if (! (head = myPixels->head) ) return;
	
	if (chSpec->channel < 0 || chSpec->channel > head->dc) return;
	if (chSpec->time < 0 || chSpec->time > head->dt) return;

	stack_offset = (chSpec->time*head->dc) + chSpec->channel;
	if (! (stackInfoP = myPixels->stackInfos) )return;
	stackInfoP += stack_offset;

	if (! stackInfoP->stats_OK) return;

	if (!chSpec->isOn) {
		chSpec->scale = 0.0;
		chSpec->black = chSpec->white = 0;
		chSpec->gamma = 1.0;
	} else {
		switch (chSpec->basis) {
			case GEOMEAN_BASIS:
				chSpec->black = stackInfoP->geomean + (chSpec->black * stackInfoP->geosigma);
				chSpec->white = stackInfoP->geomean + (chSpec->white * stackInfoP->geosigma);
			break;
			case MEAN_BASIS:
				chSpec->black = stackInfoP->mean + (chSpec->black * stackInfoP->sigma);
				chSpec->white = stackInfoP->mean + (chSpec->white * stackInfoP->sigma);
			break;
			default:
			break;
		}

		if (chSpec->black < stackInfoP->min) chSpec->black = stackInfoP->min;
		if (chSpec->black > stackInfoP->max) chSpec->black = stackInfoP->max;
		if (chSpec->white < stackInfoP->min) chSpec->white = stackInfoP->min;
		if (chSpec->white > stackInfoP->max) chSpec->white = stackInfoP->max;
		if (chSpec->white <= chSpec->black) chSpec->white = chSpec->black+1;
		chSpec->scale =  255.0 / (chSpec->white - chSpec->black);
	}
	
	
	chSpec->basis = FIXED_BASIS;
	chSpec->isFixed = 1;
}



/*
  This reads the pixels at offset, scales them according to chSpec,
  and writes them to buf.  The omeis pixels are scaled down to unsigned char values.
  The jump parameter is used to jump to the next pixel in *buf
  (i.e. 1 for grayscale, 3 for RGB, 4 for RGBA).
*/
void ScalePixels (
	PixelsRep *myPixels, size_t offset, size_t nPix,
	unsigned char *buf, size_t jump,
	channelSpecType *chSpec)
{
size_t nIO=0, nBytes;
pixHeader *head;
unsigned char *thePix, *lastPix;
unsigned char bp;
register float theVal;
float scale, blk;

	if (!myPixels) return;
	if (! (head = myPixels->head) ) return;
	if (! (bp = head->bp) ) return;
	if (! buf || !nPix) return;
	if (! chSpec->isOn ) {
		if (jump ==1) buf = memset(buf, 0, nPix);
		else while (nPix--) {
			*buf = 0;
			buf += jump;
		}
		return;
	}

	nBytes = nPix*bp;

	thePix = ((char *)myPixels->pixels) + offset;
	lastPix = thePix + (nPix*bp);

	if (lockRepFile (myPixels->fd_rep,'r',offset,nBytes) < 0) return;

	if (!chSpec->isFixed) fixChannelSpec (myPixels,chSpec);
	if (!chSpec->isFixed) return;

	scale = chSpec->scale;
	blk = (float) chSpec->black;

	if (head->bp == 1 && head->isSigned) {
		char *sCharP = (char *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*sCharP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (char) theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 1 && !head->isSigned) {
		unsigned char *uCharP = (unsigned char *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*uCharP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (unsigned char)theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 2 && head->isSigned) {
		short *sShrtP = (short *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*sShrtP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (short)theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 2 && !head->isSigned) {
		unsigned short *uShrtP = (unsigned short *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*uShrtP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (unsigned short)theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && head->isSigned && !head->isFloat) {
		long *sLongP = (long *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*sLongP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (long)theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && !head->isSigned && !head->isFloat) {
		unsigned long *uLongP = (unsigned long *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*uLongP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = (unsigned long)theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && head->isFloat) {
		float *floatP = (float *)thePix;
		while (nIO < nPix) {
			theVal = ((float) (*floatP++) - blk)*scale;
			if (theVal < 0) theVal = 0;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	}
	lockRepFile (myPixels->fd_rep,'u',offset,nBytes);
}


/* This is a high level interface to set a pixel plane from a memory buffer. */
size_t setPixelPlane (PixelsRep *thePixels, void *buf , ome_coord theZ, ome_coord theC, ome_coord theT ) {
size_t offset=0;
size_t nPix, nIO=0;

	nPix = thePixels->head->dx * thePixels->head->dy;
	if (!CheckCoords (thePixels, 0, 0, theZ, theC, theT)){
		return (0);
	}

	offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
	thePixels->IO_stream = NULL;
	thePixels->IO_buf = buf;
	thePixels->IO_buf_off = 0;
	thePixels->doSwap = 0;

	nIO = DoPixelIO(thePixels, offset, nPix, 'w');
	return( nIO );

}


/* This is a high level interface to get a pixel plane from a memory buffer. */
size_t getPixelPlane (PixelsRep *thePixels, void *buf , ome_coord theZ, ome_coord theC, ome_coord theT ) {
size_t offset=0;
size_t nPix, nIO=0;

	nPix = thePixels->head->dx * thePixels->head->dy;
	if (!CheckCoords (thePixels, 0, 0, theZ, theC, theT)){
		return (0);
	}

	offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
	thePixels->IO_stream = NULL;
	thePixels->IO_buf = buf;
	thePixels->IO_buf_off = 0;

	nIO = DoPixelIO(thePixels, offset, nPix, 'r');
	return( nIO );

}


size_t DoROI (PixelsRep *myPixels,
	ome_coord X0, ome_coord Y0, ome_coord Z0, ome_coord W0, ome_coord T0,
	ome_coord X1, ome_coord Y1, ome_coord Z1, ome_coord W1, ome_coord T1, char rorw
)
{
pixHeader *head;
ome_dim dx,dy,dz,dc,dt,bp;
ome_coord x,y,z,w,t;
size_t sizeX, nIO_t=0, nIO=0;
char *pix;
size_t off0, off1;

	if (!myPixels) return (0);
	if (! (pix = (char *)myPixels->pixels) ) return (0);
	if (! (head = myPixels->head) ) return (0);
	if ( ! CheckCoords (myPixels, X0, Y0, Z0, W0, T0) ) return (0);
	off0 = GetOffset (myPixels, X0, Y0, Z0, W0, T0);
	if ( !CheckCoords (myPixels, X1, Y1, Z1, W1, T1) ) return (0);
	off1 = GetOffset (myPixels, X1, Y1, Z1, W1, T1);
	if (off0 >= off1) return (0);
	dx = head->dx;
	dy = head->dy;
	dz = head->dz;
	dc = head->dc;
	dt = head->dt;
	bp = head->bp;

	sizeX = X1-X0+1;
	x=X0;
	for (t=T0;t <= T1; t++) {
		for (w=W0;w <= W1; w++) {
			for (z=Z0;z <= Z1; z++) {
				for (y=Y0;y <= Y1; y++) {
					nIO = DoPixelIO (myPixels,(((((t*dc) + w)*dz + z)*dy + y)*dx + x)*bp, sizeX, rorw);
					nIO_t += nIO;
					if (nIO < sizeX) return (nIO_t);
				}
			}
		}
	}

	return (nIO);
}


/*
  This copies theInfo to/from the repository file
  N.B. (FIXME):  There is no locking taking place in the header!
*/

static
int DoPlaneInfoIO (PixelsRep *myPixels, planeInfo *theInfo, ome_coord z, ome_coord c, ome_coord t, char rorw) {
pixHeader *head;
size_t nBytes = sizeof (planeInfo);
size_t file_off,plane_offset;
	
	if (!myPixels) return (0);
	if (!myPixels->planeInfos) return (0);
	if (!CheckCoords (myPixels,0,0,z,c,t)) return (0);
	if (! (head = myPixels->head) ) return (0);

	plane_offset = (((t*head->dc) + c)*head->dz) + z;
	file_off  = ((char *)myPixels->planeInfos - (char *)myPixels->head) + (plane_offset*nBytes);

	if (lockRepFile (myPixels->fd_info,rorw,file_off,nBytes) < 0) {
		OMEIS_DoError ("Could't get file lock");
		return (0);
	}

	if (rorw == 'w')
		memcpy (myPixels->planeInfos+plane_offset, theInfo, nBytes);
	else
		memcpy (theInfo, myPixels->planeInfos+plane_offset, nBytes);
	lockRepFile (myPixels->fd_info,'u',file_off,nBytes);
	return (1);
}

static
int DoStackInfoIO (PixelsRep *myPixels, stackInfo *theInfo, ome_coord c, ome_coord t, char rorw) {
pixHeader *head;
size_t nBytes = sizeof (stackInfo);
size_t file_off,stack_offset;

	if (!myPixels) return (0);
	if (!myPixels->stackInfos) return (0);
	if (!CheckCoords (myPixels,0,0,0,c,t)) return (0);
	if (! (head = myPixels->head) ) return (0);

	stack_offset = (t*head->dc) + c;
	file_off  = ((char *)myPixels->stackInfos - (char *)myPixels->head) + (stack_offset*nBytes);

	if (lockRepFile (myPixels->fd_info,rorw,file_off,nBytes) < 0) return (0);
	if (rorw == 'w')
		memcpy (myPixels->stackInfos+stack_offset, theInfo, nBytes);
	else
		memcpy (theInfo, myPixels->stackInfos+stack_offset, nBytes);
	lockRepFile (myPixels->fd_info,'u',file_off,nBytes);

	return (1);
}


/*
  This is the plane statistics calculator.  It does not check if the statistics
  are OK before doing it's job, so calling this will all ways result in a new
  statistics calculation.
*/
int DoPlaneStats (PixelsRep *myPixels, ome_coord z, ome_coord c, ome_coord t) {
planeInfo myPlaneInfo;
pixHeader *head;
ome_dim dx, dy, nPix;
ome_coord x, y;
size_t pix_off;
char *thePix;
unsigned char  *uCharP;
unsigned short *uShrtP;
unsigned long  *uLongP;
char  *sCharP;
short *sShrtP;
long  *sLongP;
float *floatP;
register float theVal,logOffset=1.0,min=FLT_MAX,max=0.0,sum_i=0.0,sum_i2=0.0,sum_log_i=0.0,sum_xi=0.0,sum_yi=0.0,sum_zi=0.0;
int i;
int do_hist = 1;

	if (!myPixels) return (0);
	if (!myPixels->stackInfos) return (0);
	if (!CheckCoords (myPixels,0,0,z,c,t)) return (0);
	if (! (head = myPixels->head) ) return (0);

	dx = head->dx;
	dy = head->dy;
	nPix = dx*dy;
	pix_off = GetOffset (myPixels, 0, 0, z, c, t);
	
	thePix = ((char *)myPixels->pixels) + pix_off;
	memset (&myPlaneInfo, 0, sizeof(planeInfo));
	
	if (head->bp == 1 && head->isSigned) {
		sCharP = thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sCharP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		/* FIXME:  When min = 0, logOffset should be something other than 1.0, I think. */
		logOffset = min > 0 ? 0 : -min > 0 ? -min + 1.0 : 1.0;

		sCharP = thePix;
		
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *sCharP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
			
	} else if (head->bp == 1 && !head->isSigned) {
		uCharP = (unsigned char *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uCharP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		logOffset = min > 0 ? 0 : 1.0;

		uCharP = (unsigned char *) thePix;
		
		
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *uCharP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	} else if (head->bp == 2 && head->isSigned) {
		sShrtP = (short *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sShrtP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		/* FIXME:  When min = 0, logOffset should be something other than 1.0, I think. */
		logOffset = min > 0 ? 0 : -min > 0 ? -min + 1.0 : 1.0;

		sShrtP = (short *) thePix;
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *sShrtP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	} else if (head->bp == 2 && !head->isSigned) {
		uShrtP = (unsigned short *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uShrtP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		logOffset = min > 0 ? 0 : 1.0;

		uShrtP = (unsigned short *) thePix;
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *uShrtP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	} else if (head->bp == 4 && head->isSigned && !head->isFloat) {
		sLongP = (long *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sLongP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		/* FIXME:  When min = 0, logOffset should be something other than 1.0, I think. */
		logOffset = min > 0 ? 0 : -min > 0 ? -min + 1.0 : 1.0;

		sLongP = (long *) thePix;
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *sLongP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	} else if (head->bp == 4 && !head->isSigned && !head->isFloat) {
		uLongP = (unsigned long *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uLongP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		logOffset = min > 0 ? 0 : 1.0;

		uLongP = (unsigned long *) thePix;
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *uLongP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	} else if (head->bp == 4 && head->isFloat) {
		floatP = (float *) thePix;
		
		/* compute plane statistics */
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal =  *floatP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}

		/* FIXME:  When min = 0, logOffset should be something other than 1.0, I think. */
		logOffset = min > 0 ? 0 : -min > 0 ? -min + 1.0 : 1.0;

		floatP = (float *) thePix;
		/* Second pass: sum_log_i, plane histogram */
		if (max-min <= 0){
			do_hist = 0;
			myPlaneInfo.hist[NUM_BINS/2] = nPix;
		}
		
		for (i=0;i<nPix;i++) {
			theVal = (float) *floatP++;
			if (do_hist)
				myPlaneInfo.hist[(int) (((theVal-min)/(max-min))*(NUM_BINS-1))]++;
			sum_log_i +=  log (theVal+logOffset);
		}
	}
	
	myPlaneInfo.sum_xi    = sum_xi;
	myPlaneInfo.sum_yi    = sum_yi;
	myPlaneInfo.sum_zi    = sum_zi;
	myPlaneInfo.sum_i     = sum_i;  
	myPlaneInfo.sum_i2    = sum_i2;
	myPlaneInfo.sum_log_i = sum_log_i;
	myPlaneInfo.min       = min;
	myPlaneInfo.max       = max;

	myPlaneInfo.mean = sum_i / nPix;
	myPlaneInfo.geomean = exp ( sum_log_i / nPix ) - logOffset;

	/* sigma using the amean */
	myPlaneInfo.sigma = (float) sqrt (fabs ( 
		(sum_i2 - (sum_i * sum_i) / nPix) /
		(nPix - 1.0) ));

	/* geosigma: distance between point and geometric mean*/
	 myPlaneInfo.geosigma = (float) sqrt (fabs(
	 	(sum_i2-2*myPlaneInfo.geomean * sum_i + myPlaneInfo.geomean * myPlaneInfo.geomean) /
	 	(nPix - 1.0)));
	 	
	myPlaneInfo.centroid_x = sum_xi / sum_i;
	myPlaneInfo.centroid_y = sum_yi / sum_i;
	
	myPlaneInfo.stats_OK = 1;
	return ( DoPlaneInfoIO (myPixels, &myPlaneInfo, z, c, t, 'w'));
}


/*
  This is the stack statistics calculator.  It checks if the stack statisticks
  are OK, and if not checks if each plane statistics is OK, calling
  DoPlaneStats if it isn't.
*/
int DoStackStats (PixelsRep *myPixels, ome_coord c, ome_coord t) {
stackInfo myStackInfo;
pixHeader *head;
ome_dim dz;
ome_coord z;
stackInfo *stackInfoP;
planeInfo *planeInfoP;
size_t plane_offset,stack_offset;
register float geomean=0.0,min=FLT_MAX,max=FLT_MIN,sum_i=0.0,sum_i2=0.0,sum_log_i=0.0,sum_xi=0.0,sum_yi=0.0,sum_zi=0.0,nPix;
int i;

	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	dz = head->dz;

	plane_offset = ((t*head->dc) + c)*dz;
	stack_offset = (t*head->dc) + c;

	if (! (stackInfoP = myPixels->stackInfos + stack_offset) ) return (0);
	if (stackInfoP->stats_OK) return (1);
	if (! (planeInfoP = myPixels->planeInfos + plane_offset) ) return (0);

	memset (&myStackInfo, 0, sizeof(stackInfo));
	for (z = 0; z < dz; z++) {
		if (! planeInfoP->stats_OK)
			DoPlaneStats (myPixels, z, c, t);
		sum_xi    += planeInfoP->sum_xi;
		sum_yi    += planeInfoP->sum_yi;
		sum_zi    += planeInfoP->sum_zi;
		sum_i     += planeInfoP->sum_i;
		sum_i2    += planeInfoP->sum_i2;
		sum_log_i += planeInfoP->sum_log_i;
		geomean   += planeInfoP->geomean;
		if (planeInfoP->min < min) min = planeInfoP->min;
		if (planeInfoP->max > max) max = planeInfoP->max;

		/* sum the plane histogram vectors to get the stack vector */
		for (i = 0; i<NUM_BINS; i++)
			myStackInfo.hist[i] += planeInfoP->hist[i];
		planeInfoP++;
	}
	nPix = head->dx*head->dy*dz;

	myStackInfo.sum_xi    = sum_xi;
	myStackInfo.sum_yi    = sum_yi;
	myStackInfo.sum_zi    = sum_zi;
	myStackInfo.sum_i     = sum_i;  
	myStackInfo.sum_i2    = sum_i2;
	myStackInfo.sum_log_i = sum_log_i;
	myStackInfo.min       = min;
	myStackInfo.max       = max;

	myStackInfo.mean = sum_i / nPix;
	
	/* Yup, readem and weep.  Its an arithmetic average of geomeans */
	myStackInfo.geomean = geomean / dz;

	/* sigma using the amean (classical) */
	myStackInfo.sigma = (float) sqrt (fabs (
		(sum_i2	 - (sum_i * sum_i) / nPix) /
		(nPix - 1.0) ));

	/* geosigma: distance between point and geometric mean*/
	 myStackInfo.geosigma = (float) sqrt (fabs(
	 	(sum_i2-2*myStackInfo.geomean * sum_i + myStackInfo.geomean * myStackInfo.geomean) /
	 	(nPix - 1.0)));

	myStackInfo.centroid_x = sum_xi / sum_i;
	myStackInfo.centroid_y = sum_yi / sum_i;
	myStackInfo.centroid_z = sum_zi / sum_i;

	myStackInfo.stats_OK = 1;
	return (DoStackInfoIO (myPixels, &myStackInfo, c, t, 'w') );
}

/*
  This makes sure all the statistics are calculated.  It accept a force parameter, which makes
  it calculate the statistics regardless of the value of stats_OK.
  
  It also computes the stack and plane histograms.
*/
int FinishStats (PixelsRep *myPixels, char force) {
	ome_dim  dc, dz, dt;
	ome_coord z, c, t;
	pixHeader *head;
	stackInfo *stackInfoP;
	planeInfo *planeInfoP;
	int i,j;
	
	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	if (! (stackInfoP = myPixels->stackInfos) ) return (0);
	if (! (planeInfoP = myPixels->planeInfos) ) return (0);
		
	dz = head->dz;
	dc = head->dc;
	dt = head->dt;
	for (t = 0; t < dt; t++) {
		for (c = 0; c < dc; c++) {
			if (force) 
				stackInfoP->stats_OK = 0;

			for (z = 0; z < dz; z++) {				
				if (force)
					planeInfoP->stats_OK = 0;
				if (!planeInfoP->stats_OK)
					/* lets fondle the planeInfoP data */
					if (!DoPlaneStats (myPixels, z, c, t))
						return 0;
				planeInfoP++;
			}
			
			if (!DoStackStats (myPixels, c, t)) return (0);
			stackInfoP++;
		}
	}
	return (1);
}

static
void deletePixels (PixelsRep *myPixels) {

	if (!myPixels->is_mmapped) {
		if (myPixels->planeInfos) free (myPixels->planeInfos);
		if (myPixels->stackInfos) free (myPixels->stackInfos);
		if (myPixels->head) free (myPixels->head);
		if (myPixels->pixels) free (myPixels->pixels);
	} else {
		munmap (myPixels->head, myPixels->size_info);
		munmap (myPixels->pixels, myPixels->size_rep);
	}
	myPixels->is_mmapped = 0;
	myPixels->planeInfos = NULL;
	myPixels->stackInfos = NULL;
	myPixels->head = NULL;
	myPixels->pixels = NULL;
	

	if (myPixels->fd_info >=0 ) close (myPixels->fd_info);
	if (myPixels->path_info) {
		chmod (myPixels->path_info,0600);
		unlink (myPixels->path_info);
	}
	myPixels->fd_info = -1;

	if (myPixels->fd_rep >=0 ) close (myPixels->fd_rep);
	if (myPixels->path_rep) {
		chmod (myPixels->path_rep,0600);
		unlink (myPixels->path_rep);
	}
	myPixels->fd_rep = -1;

	closeConvertFile (myPixels);
	if (myPixels->path_conv) {
		chmod (myPixels->path_conv,0600);
		unlink (myPixels->path_conv);
	}

	if (myPixels->path_thumb) {
		chmod (myPixels->path_thumb,0600);
		unlink (myPixels->path_thumb);
	}

}



int ExpungePixels (PixelsRep *myPixels) {
OID existOID;

	if (! myPixels->DB)	
		/* if we can't get its SHA1 entry thats really bad */
		if (! (myPixels->DB = sha1DB_open (myPixels->path_DB)) ) {
			OMEIS_DoError ("In ExpungePixels, Error opening SHA1 DB for PixelsID=%llu",
						   	(unsigned long long)myPixels->ID);
			return (0);
		}

	if ( existOID = sha1DB_get (myPixels->DB, myPixels->head->sha1) ) {
		sha1DB_del (myPixels->DB, myPixels->head->sha1);
	} else {
		OMEIS_DoError ("In ExpungePixels, Pixel's SHA1 not in DB for PixelsID=%llu ?!",
						(unsigned long long)myPixels->ID);
		sha1DB_close (myPixels->DB);
		return (0);
	}
	sha1DB_close (myPixels->DB);
	
	deletePixels (myPixels);
	
	return (1);
	
	
}


OID FinishPixels (PixelsRep *myPixels, char force) {
OID existOID;

	if (!myPixels) return (0);

	/* wait until we can get a write lock on the whole file */
	lockRepFile (myPixels->fd_rep,'w',0LL,0LL);
	
	/* Make sure all the stats are up to date */
	if (!FinishStats (myPixels,force)) {
		OMEIS_DoError ("Unable to finish stats.");
		return (0);
	}

	/* Get the SHA1 message digest */
	if (get_md_from_buffer (myPixels->pixels, myPixels->size_rep, myPixels->head->sha1) < 0) {
		OMEIS_DoError ("Unable to retrieve SHA1.");
		return(0);
	}

	/* Open the DB file if necessary */
	if (! myPixels->DB)
		if (! (myPixels->DB = sha1DB_open (myPixels->path_DB)) ) {
			OMEIS_DoError ("Unable to open sha1DB.");
			return(0);
		}

	/* Check if SHA1 exists */
	if ( (existOID = sha1DB_get (myPixels->DB, myPixels->head->sha1)) ) {
		sha1DB_close (myPixels->DB);
		myPixels->DB = NULL;
		deletePixels (myPixels);
		myPixels->ID = existOID;
		return (existOID);
	}

	myPixels->head->isFinished = 1;

	if (myPixels->is_mmapped) {
		if (msync (myPixels->head , myPixels->size_info , MS_SYNC) != 0) {
			OMEIS_DoError ("Unable to msync header: %s.", strerror (errno));
			return (0);
		}

		if (msync (myPixels->pixels , myPixels->size_rep , MS_SYNC) != 0) {
			OMEIS_DoError ("Unable to msync pixels: %s.", strerror (errno));
			return (0);
		}
	}
	

	/* put the SHA1 in the DB */
	if ( sha1DB_put (myPixels->DB, myPixels->head->sha1, myPixels->ID) ) {
		sha1DB_close (myPixels->DB);
		myPixels->DB = NULL;
		OMEIS_DoError ("Unable to put sha1 into sha1DB.");
		return (0);
	}

	/* Close the DB (and release the exclusive lock) */
	sha1DB_close (myPixels->DB);
	myPixels->DB = NULL;

	fchmod (myPixels->fd_rep,0400);
	fchmod (myPixels->fd_info,0400);
//	chmod (myPixels->path_conv,0600);

	return (myPixels->ID);
}


size_t ConvertFile (
	PixelsRep *myPixels,
	FileRep   *myFile,
	size_t     file_offset,
	size_t     pix_offset,
	size_t     nPix,
	char       writeRec) {

pixHeader *head;
unsigned long nIO;
convertFileRec convRec;
FILE *convFileInfo;
char convFileInfoPth[MAXPATHLEN];
char isBigEndian=1,bp;

	if (!myFile || !myPixels) return (0);
	if (! (head = myPixels->head) ) {
		OMEIS_DoError ("ConvertFile(PixelsID=%llu). Pixels header is not set.",(unsigned long long)myPixels->ID);
		return (0);
	}
	bp = head->bp;

	if ( myFile->size_rep < file_offset + (nPix*bp)) {
		OMEIS_DoError ("ConvertFile(PixelsID=%llu). Attempt to read past end of file ID=%llu.  File size=%lu,  Offset=%lu, # pixels=%lu (%lu bytes)",
			(unsigned long long)myPixels->ID,(unsigned long long)myFile->ID,
			(unsigned long)(myFile->size_rep), (unsigned long)file_offset,
			(unsigned long)nPix, (unsigned long)(nPix*bp));
		return (0);
	}

	if ( pix_offset + (nPix*bp) > myPixels->size_rep) {
		OMEIS_DoError ("ConvertFile(PixelsID=%llu). Attempt to write past end of pixels.  Pixels size=%lu,  Pix offset=%lu, # pixels=%lu (%lu bytes)",
			(unsigned long long)myPixels->ID, (unsigned long)(myPixels->size_rep), (unsigned long)pix_offset,
			(unsigned long)nPix, (unsigned long)(nPix*bp));
		return (0);
	}

	myPixels->IO_buf = (u_int8_t *) myFile->file_buf + file_offset;
	myPixels->IO_buf_off = 0;
	nIO = DoPixelIO (myPixels, pix_offset, nPix, 'w');
	if (nIO != nPix) {
		OMEIS_DoError ("ConvertFile(). Number of pixels converted (%lu) does not match number in request (%lu)",
			nIO, (unsigned long)nPix);
		return (nIO);
	}


	if (writeRec) {
		memset(&convRec, 0, sizeof(convertFileRec));
		if ( (myPixels->doSwap && bigEndian()) || (!myPixels->doSwap && !bigEndian()) ) isBigEndian = 0;
		convRec.FileID                = (u_int8_t)  myFile->ID;
		convRec.isBigEndian           = (u_int8_t)  isBigEndian;
		convRec.spec.file.file_offset = (u_int64_t) file_offset;
		convRec.spec.file.pix_offset  = (u_int64_t) pix_offset;
		convRec.spec.file.nPix        = (u_int64_t) nPix;

		if (!openConvertFile (myPixels, 'w'))
			OMEIS_DoError ("ConvertFile (PixelsID=%llu). Couldn't open convert file=%s for writing.",
				(unsigned long long)myPixels->ID,myPixels->path_conv);
		else {
			write (myPixels->fd_conv, (const void *)&convRec, sizeof (convertFileRec));
			closeConvertFile (myPixels);
		}
	}

	return (nIO);
}


size_t ConvertTIFF (
	PixelsRep *myPixels,
	FileRep   *myFile,
	ome_coord theZ,
	ome_coord theC,
	ome_coord theT,
	unsigned long tiffDir,
	char writeRec) {

pixHeader *head;
char file_path[MAXPATHLEN],bp;
unsigned long nIO=0, nOut;
size_t pix_offset;
size_t nPix;
convertFileRec convRec;
FILE *convFileInfo;
char convFileInfoPth[MAXPATHLEN];
TIFF *tiff = NULL;
tdata_t read_buf;
uint16* write_buf_unpack; /* tmp write buffer for unpacking bits */
uint8*  write_buf_rgb;    /* tmp write buffer for extracting rgb */
tstrip_t strip;
uint32 width = 0;
uint32 height = 0;
uint16 chans = 0,pc,is_rgb;
uint16 read_bitspp, write_bytespp;
tsize_t stripSize;
char doSwap;
int numPixPerStrip, numStrips; 	/* predict how many TiffStrips need to be read */

	if (!myFile || !myPixels) return (0);

	if (! (head = myPixels->head) ) {
		OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). Pixels header is not set.",
				(unsigned long long)myPixels->ID);
		return (0);
	}
	
	bp = head->bp;

	if (!CheckCoords (myPixels, 0, 0, theZ, theC, theT)){
		OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). Coordinates theZ=%d, theC=%d, theT=%d are out of range (%d,%d,%d)",
			(unsigned long long)myPixels->ID, theZ, theC, theT, head->dz, head->dc, head->dt);
		return (0);
	}
	if (myFile->fd_rep < 0) {
		if ( (myFile->fd_rep = openRepFile (myFile->path_rep, O_RDONLY)) < 0) {
			OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). Couldn't open File ID=%llu.",
					(unsigned long long)myPixels->ID,(unsigned long long)myFile->ID);
			return (0);
		}
	}

	/* Wait for a read lock */
	lockRepFile (myFile->fd_rep, 'r', 0LL, 0LL);	
	
    if (! (tiff = TIFFFdOpen(myFile->fd_rep, myFile->path_rep, "r")) ) {
		OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). Couldn't open File ID=%llu as a TIFF file.",
			(unsigned long long)myPixels->ID,
			(unsigned long long)myFile->ID);
    	return (0);
    }
    if (TIFFSetDirectory(tiff, (tdir_t)tiffDir) != 1) {
		OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). Couldn't set TIFF directory to %lu.",(unsigned long long)myPixels->ID,tiffDir);
		TIFFClose(tiff);
    	return (0);
    }
    
	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);
	TIFFGetField(tiff, TIFFTAG_SAMPLESPERPIXEL, &chans);
	TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &read_bitspp);
	TIFFGetField(tiff, TIFFTAG_PLANARCONFIG, &pc);
	TIFFGetField(tiff, TIFFTAG_PHOTOMETRIC, &is_rgb);  

	/* convert bits per pixel to bytes per pixel */
	if (read_bitspp <= 8)
		write_bytespp = 1;
	else if (read_bitspp > 8 && read_bitspp <= 16)
		write_bytespp = 2;
	else 
		write_bytespp = 4;
		
	/* sanity check */
	if (width != (uint32)(head->dx) || height != (uint32)(head->dy) || (chans > 1 && is_rgb != PHOTOMETRIC_RGB) || write_bytespp != (uint16)(head->bp) ||
		(is_rgb != PHOTOMETRIC_RGB && pc != PLANARCONFIG_CONTIG ) ){
			int nc=0;
			
			TIFFClose(tiff);
			OMEIS_DoError ("ConvertTIFF (PixelsID=%llu). TIFF (ID=%llu) <-> Pixels mismatch.",
				(unsigned long long)myPixels->ID,(unsigned long long)myFile->ID);
			OMEIS_DoError ("\tWidth x Height:    Pixels (%d,%d) TIFF (%u,%u)",(int)head->dx,(int)head->dy,(unsigned)width,(unsigned)height);
			OMEIS_DoError ("\tSamples per pixel: Pixels (%d) TIFF (%d)",(int)1,(int)chans);
			OMEIS_DoError ("\tBits per sample:   Pixels (%d) TIFF (%d)",(int)head->bp*8,(int)read_bitspp);
			OMEIS_DoError ("\tPlanar Config:     Pixels (%d) TIFF (%d)",(int)PLANARCONFIG_CONTIG,(int)pc);
			return (0);
	}

	/* allocate read and write buffer if neccessary */
	if (! (read_buf = _TIFFmalloc(TIFFStripSize(tiff))) ) {
		OMEIS_DoError ("ConvertTIFF (PixelsID=%llu):  Couldn't allocate %lu bytes for TIFF strip buffer.",(unsigned long long)myPixels->ID,TIFFStripSize(tiff));
		TIFFClose(tiff);
		return (0);
	}

	/* allocate a scratch buffer for bit-unpacking if neccessary */
	if (read_bitspp%8 != 0)
		if (! (write_buf_unpack = (uint16*) malloc(TIFFStripSize(tiff)*8/read_bitspp * write_bytespp)) ) {
			OMEIS_DoError ("ConvertTIFF (PixelsID=%llu):  Couldn't allocate %lu bytes for TIFF temporary bit-unpacking, buffer.",(unsigned long long)myPixels->ID,TIFFStripSize(tiff)*8/read_bitspp * write_bytespp);
		_TIFFfree(read_buf);
		TIFFClose(tiff);
		return (0);
	}
	
	/* allocate a scratch buffer for channel unpacking if neccessary */
	if (is_rgb == PHOTOMETRIC_RGB && pc == PLANARCONFIG_CONTIG)
		if (! (write_buf_rgb = (uint8*) malloc(TIFFStripSize(tiff)/3) )) {
			OMEIS_DoError ("ConvertTIFF (PixelsID=%llu):  Couldn't allocate %lu bytes for TIFF temporary channel buffer.\n",(unsigned long long)myPixels->ID,TIFFStripSize(tiff)*8/read_bitspp * write_bytespp);
		_TIFFfree(read_buf);
		TIFFClose(tiff);
		return (0);
	}
	myPixels->IO_buf_off = 0;
	doSwap = myPixels->doSwap;
	myPixels->doSwap = 0;
	
	/* is this an rgb image with packed channels */
	if (is_rgb == PHOTOMETRIC_RGB && pc == PLANARCONFIG_CONTIG){
		size_t red_offset   = GetOffset (myPixels, 0, 0, theZ, 0, theT);
		size_t green_offset = GetOffset (myPixels, 0, 0, theZ, 1, theT);
		size_t blue_offset  = GetOffset (myPixels, 0, 0, theZ, 2, theT);
		myPixels->IO_buf = write_buf_rgb;
		pix_offset = 0;
		
		for (strip = 0; strip<TIFFNumberOfStrips(tiff) && nIO<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);
			nPix = (8*stripSize) / read_bitspp / 3;
			
			/* write the red, green, and blue parts of the pixel into different channels*/
			myPixels->IO_buf_off = 0;
			extractRGBChannels(read_buf, nPix, 0, write_buf_rgb); 
			nOut = DoPixelIO (myPixels, red_offset   + pix_offset, nPix, 'w');
			
			myPixels->IO_buf_off = 0;
			extractRGBChannels(read_buf, nPix, 1, write_buf_rgb);
			nOut = DoPixelIO (myPixels, green_offset + pix_offset, nPix, 'w');
			
			myPixels->IO_buf_off = 0;
			extractRGBChannels(read_buf, nPix, 2, write_buf_rgb);
			nOut = DoPixelIO (myPixels, blue_offset  + pix_offset, nPix, 'w');
			
			pix_offset += nPix*write_bytespp;
			nIO += nOut;
		}
		free(write_buf_rgb); 
	
	
	} else if (is_rgb == PHOTOMETRIC_RGB && pc == PLANARCONFIG_SEPARATE) {
		int red_nOut = 0;
		int green_nOut = 0;
		int blue_nOut = 0;

		size_t red_offset   = GetOffset (myPixels, 0, 0, theZ, 0, theT);
		size_t green_offset = GetOffset (myPixels, 0, 0, theZ, 1, theT);
		size_t blue_offset  = GetOffset (myPixels, 0, 0, theZ, 2, theT);
		
		myPixels->IO_buf = read_buf;
		myPixels->IO_buf_off = 0;
		
		/* red channels */
		pix_offset = red_offset;
		for (strip = 0; strip<TIFFNumberOfStrips(tiff) && red_nOut<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);		
			nPix = (8*stripSize) / read_bitspp;
			myPixels->IO_buf_off = 0;
			
			nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
			pix_offset += stripSize;
			red_nOut += nOut;
		}
		
		/* green channels */
		pix_offset = green_offset;
		for (; strip<TIFFNumberOfStrips(tiff) && green_nOut<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);		
			nPix = (8*stripSize) / read_bitspp;
			myPixels->IO_buf_off = 0;
			
			nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
			pix_offset += stripSize;
			green_nOut += nOut;
		}
		
		/* blue channels */
		pix_offset = blue_offset;
		for (; strip<TIFFNumberOfStrips(tiff) && blue_nOut<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);		
			nPix = (8*stripSize) / read_bitspp;
			myPixels->IO_buf_off = 0;
			
			nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
			pix_offset += stripSize;
			blue_nOut += nOut;
		}
		
		if ((red_nOut != green_nOut) || (blue_nOut != green_nOut)) {
			OMEIS_DoError ("ConvertTIFF (PixelsID=%llu):  Number of Red (%d) Green (%d) and Blue (%d) pixels is non equal.\n",
							red_nOut,green_nOut, blue_nOut);
			_TIFFfree(read_buf);
			TIFFClose(tiff);
			return (0);		
		}
		
		nIO = red_nOut;
		
	/* do we need to do bit unpacking */
	} else if (read_bitspp % 8 == 0) {
		myPixels->IO_buf = read_buf;
		myPixels->IO_buf_off = 0;
		pix_offset = GetOffset (myPixels, 0, 0, theZ, theC, theT);
		for (strip = 0; strip<TIFFNumberOfStrips(tiff) && nIO<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);		
			nPix = (8*stripSize) / read_bitspp;
			myPixels->IO_buf_off = 0;
			
			nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
			pix_offset += stripSize;
			nIO += nOut;
		}
	/* its a standard one channel tiff */
	} else {
		myPixels->IO_buf = write_buf_unpack;
		myPixels->IO_buf_off = 0;
		pix_offset = GetOffset (myPixels, 0, 0, theZ, theC, theT);
		for (strip = 0; strip<TIFFNumberOfStrips(tiff) && nIO<(head->dx)*(head->dy); strip++) {
			stripSize = TIFFReadEncodedStrip(tiff, strip, read_buf, (tsize_t) -1);		
			nPix = (stripSize*8) / read_bitspp;
			myPixels->IO_buf_off = 0;
			
			/* unpack bits to write_buf from read_buf*/
			unpackBits((uint8*) read_buf, read_bitspp, write_buf_unpack, write_bytespp, nPix);
			
			nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
			pix_offset += nPix*write_bytespp;
			nIO += nOut;
		}
		free(write_buf_unpack);
	}
	
	myPixels->doSwap = doSwap;
	_TIFFfree(read_buf);
	TIFFClose(tiff);
	if (writeRec) {
		memset(&convRec, 0, sizeof(convertFileRec));
		convRec.FileID              = (u_int8_t)  myFile->ID;
		convRec.isTIFF              = (u_int8_t)  1;
		convRec.spec.tiff.theZ      = (ome_coord) theZ;
		convRec.spec.tiff.theC      = (ome_coord) theC;
		convRec.spec.tiff.theT      = (ome_coord) theT;
		convRec.spec.tiff.dir_index = (u_int32_t) tiffDir;
	
		if (!openConvertFile (myPixels, 'w')) {
			OMEIS_DoError ("ConvertFile (PixelsID=%llu). Couldn't open convert file=%s for writing.",
				(unsigned long long)myPixels->ID,myPixels->path_conv);
		} else {
			write (myPixels->fd_conv, (const void *)&convRec, sizeof (convertFileRec));
			closeConvertFile (myPixels);
		}
	}
	return (nIO);
}

/* warning. this function is a mine field. contact me (Tom) if you are thinking of changing it*/
static int
unpackBits (void* read_buf, int read_bitspp, void* write_buf, int write_bytespp, int nlength)
{
	int i,j;
	uint16 r_byte1;
	uint16 r_byte2;
	uint16 r_byte3;
	uint16* w_byte1;
	uint16* w_byte2;
	uint16 mask1 = 0x00F0;
	uint16 mask2 = 0x000F;
	
	w_byte1 = malloc(sizeof(uint8) * write_bytespp);
	w_byte2 = malloc(sizeof(uint8) * write_bytespp);
	
	if (read_bitspp != 12){
		OMEIS_DoError ("HALT! un_pack_bits in Pixels.c was incorrectly called. Currently read_bitspp can only equal 12 ");
		return;
	}
	
	for (i=0,j=0; (j+1) < nlength; i+=3,j+=2) {
		r_byte1 = (uint16) *( (uint8*) read_buf + sizeof(uint8)*i );
		r_byte2 = (uint16) *( (uint8*) read_buf + sizeof(uint8)*(i+1) );
		r_byte3 = (uint16) *( (uint8*) read_buf + sizeof(uint8)*(i+2) );
		
		
		*w_byte1 =  (uint16) ( (r_byte1<<4) + ((r_byte2 & mask1)>>4) );
		*w_byte2 =  (uint16) ( ((r_byte2 & mask2) << 8) + r_byte3 );
		
		memcpy ( (uint16*) (write_buf + sizeof(uint8)*write_bytespp*j),     w_byte1, sizeof(uint16) );
		memcpy ( (uint16*) (write_buf + sizeof(uint8)*write_bytespp*(j+1)), w_byte2, sizeof(uint16) );
		
	}
	
	free (w_byte1);
	free (w_byte2);
}
/*
	This function extracts every third element of the read_buf and writes it to
	the write_buf. If chan=0 Red, if chan=1 Green, and if chan=2 Blue values are
	extracted.
*/
void extractRGBChannels(uint8* read_buf, int nPix, int chan, uint8* write_buf_rgb)
{
int i;
	for (i=0; i<nPix; i++)
		write_buf_rgb[i] = read_buf[chan+3*i];
}
/*
  GetArchive (PixelsRep myPixels)
  Collects all the files that were used to generate the Pixels (if any)
  makes a tar/gz or zip archive of them in a file with the same filepath as the pixels, with a .tgz extension.
static
int GetArchive (PixelsRep myPixels, char *format) {
	return (0);
}
*/

