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


#include "omeis.h"
#include "digest.h"
#include "composite.h"
#include "method.h"
#include "xmlBinaryResolution.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif

/* ------------------- */
/* Internal Prototypes */
/* ------------------- */

static int inList(char **cgivars, char *str);
static char x2c(char *what);
static void unescape_url(char *url);
static char **getcgivars(void);
static char **getCLIvars(int argc, char **argv);

/*
  This function will get a new unique ID by examining the contents of the
  passed-in counter file.  The number in the counterfile will be incremented,
  and written back to the file.  The incremented number is returned.  A return
  of 0 means an error has occured, and can be checked with errno.  A return of
  0 with a 0 errno means the counter has wrapped around.
*/
static
OID nextID (char *idFile)
{
	struct flock fl;
	int fd;
	OID pixID = 0;
	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_type = F_WRLCK;
	fl.l_whence = SEEK_SET;

	if ((fd = open(idFile, O_CREAT|O_RDWR, 0600)) < 0) {
		return (0);
	}

	if (fcntl(fd, F_SETLKW, &fl) == -1) {
		close(fd);
		return (0);
	}

	if ((read(fd, &pixID, sizeof (OID)) < 0) || pixID == 0xFFFFFFFFFFFFFFFFULL) {
		fl.l_type = F_UNLCK;  /* set to unlock same region */
		fcntl(fd, F_SETLK, &fl);
		close(fd);
		return (0);
	}

	pixID++;

	if (lseek(fd, 0LL, SEEK_SET) != 0) {
		fl.l_type = F_UNLCK;  /* set to unlock same region */
		fcntl(fd, F_SETLK, &fl);
		close(fd);
		return (0);
	}

	if (write (fd, &pixID, sizeof (OID)) != sizeof (OID)) {
		fl.l_type = F_UNLCK;  /* set to unlock same region */
		fcntl(fd, F_SETLK, &fl);
		close(fd);
		return (0);
	}


	fl.l_type = F_UNLCK;  /* set to unlock same region */

	if (fcntl(fd, F_SETLK, &fl) == -1) {
		close(fd);
		return (0);
	}


	close(fd);
	return (pixID);
}


/*
  char *getRepPath (OID theID, char *path, char makePath)
  Get repository path from an ID.
  Optionally create the path (but not the file).
  
  We need to assign a unique file to theID.  We would like not to store all the
  files in the same directory, and we want the directory structure not to
  become unbalanced (uneven distribution of files in directories).  We also
  don't want to make 6 directory levels if we only have a few thousand files.
  We want the tree to grow normally as well.  The path also has to be unique,
  and we must account for many processes trying to do the same thing at the
  same time.  The strategery here is to break theID into 3-character chuncks,
  and make the chunks directories in a path.  The last chunk has the full ID,
  and is the filename.  unsigned 64 bit integers max out at 1.844674 x 10^19,
  so 20 characters, 6 directory levels.  Things might not work out well here if
  OID is not an unsigned long long or is larger than 64 bits.
  
  Function returns a pointer to path or NULL on error (path may be partially
  OK).  The makePath parameter (0 or 1) is used to determine if the path is
  created at the same time.
  
  N.B.: The path is not cleared, it is appended to what's already in the
  buffer, allowing for independent root filesystems.
*/
static
char *getRepPath (OID theID, char *path, char makePath) {
	char pixIDstr[21], chunk[12];
	int chunks[6], nChunks=0, i;
	OID remaining = theID;  /* remainder() is a -lm built-in */

	while (remaining > 999) {
		chunks[nChunks] = remaining % 1000;
		remaining = (remaining - chunks[nChunks++]) / 1000;
	}

	if (remaining > 0) {
		chunks[nChunks++] = remaining;
	}

	for (i=nChunks-1;i>0;i--) {
		sprintf (chunk,"Dir-%03d/",chunks[i]);
		strcat (path,chunk);
		if (makePath)
			if (mkdir(path, 0700) != 0)
				if (errno != EEXIST) /* Exist errors are OK, but return on anything else (files should get ENOTDIR) */
					return (NULL);
	}

	sprintf (pixIDstr,"%llu",theID);

	strcat (path,pixIDstr);
	
	return (path);
	
}


static
int lockRepFile (int fd, char lock, off_t from, off_t length) {
struct flock fl;

	fl.l_start = from;
	fl.l_len = length;
	fl.l_pid = 0;
	
	if (lock == 'r') fl.l_type = F_RDLCK;
	else if (lock == 'w')  fl.l_type = F_WRLCK;
	else if (lock == 'u')  fl.l_type = F_UNLCK;
	fl.l_whence = SEEK_SET;

	return (fcntl(fd, F_SETLKW, &fl));
}


/*
  int newRepFile (OID theID, char *path, off_t size, char *suffix)
  
  Make a new repository file of the specified size.  The path parameter is a
  buffer that will contain the new repository path.  This function calls
  getRepPath to get the filepath, making directories then creates a file of the
  specified size.  This function returns the file descriptor of the file opened
  for writing.  The path buffer will contain the path, including the suffix (if
  not NULL).  The file created will be of the specified size, and the entire
  file will be write-locked.  If there were errors along the way, this function
  returns <0.  Check errno for the source of the error.
  
  N.B.: The path is not cleared, it is appended to what's already in the
  buffer, allowing for independent root filesystems.
*/
static
int newRepFile (OID theID, char *path, off_t size, char *suffix) {
	int fd;
	unsigned char zero=0;

	if (! getRepPath (theID,path,1)) {
		return (-1);
	}
	
	if (suffix) {
		strcat (path,".");
		strcat (path,suffix);
	}

	if ( (fd = open (path, O_CREAT|O_EXCL|O_RDWR, 0600)) < 0) {
		return (-2);
	}
	
	lockRepFile (fd,'w',0LL,0LL);
	
	if (lseek(fd, size-1, SEEK_SET) < 0) {
		close (fd);
		return (-3);
	}

	if (write(fd, &zero, 1) < 1) {
		close (fd);
		return (-4);
	}
	
	if (lseek(fd, 0LL, SEEK_SET) < 0) {
		close (fd);
		return (-5);
	}
   
	return (fd);
}


/*
Josiah Johnston <siah@nih.gov>
* Returns 1 if the machine executing this code is bigEndian, 0 otherwise.
*/
int bigEndian(void)
{
    static int init = 1;
    static int endian_value;
    char *p;

    p = (char*)&init;
    return endian_value = p[0]?0:1;
}



/*
  PixelRep keeps track of everything having to do with pixel i/o to the repository.
*/
static
void freePixelsRep (PixelsRep *myPixels) {
	if (!myPixels->is_mmapped) {
		if (myPixels->planeInfos) free (myPixels->planeInfos);
		if (myPixels->stackInfos) free (myPixels->stackInfos);
		if (myPixels->head) free (myPixels->head);
	} else {
		munmap (myPixels->head, myPixels->size_info);
		munmap (myPixels->pixels, myPixels->size_rep);
	}

	if (myPixels->fd_info >=0 ) close (myPixels->fd_info);
	if (myPixels->fd_rep >=0 ) close (myPixels->fd_rep);
	free (myPixels);
}



/*
  The constructor doesn't do very much other than allocate and initialize
  memory.  If an ID is passed in, it will set the paths to the dependent files,
  but not open anything.
*/
static
PixelsRep *newPixelsRep (OID ID)
{
PixelsRep *myPixels;
char *root="Pixels/";
char *pixIDfile="Pixels/lastPix";

	if (! (myPixels =  (PixelsRep *)malloc (sizeof (PixelsRep)))  )
		return (NULL);
	myPixels = memset(myPixels, 0, sizeof(PixelsRep));
	
	strcpy (myPixels->path_rep,root);
	strcpy (myPixels->path_info,root);
	strcpy (myPixels->path_ID,pixIDfile);

	/* file descriptors reset to -1 */
	myPixels->fd_rep = -1;
	myPixels->fd_info = -1;

	/* If we got an ID, set the paths */
	if (ID) {
		if (! getRepPath (ID,myPixels->path_rep,0)) {
			fprintf (stderr,"Could not get path to pixels file.\n");
			freePixelsRep (myPixels);
			return (NULL);
		}
		strcpy (myPixels->path_info,myPixels->path_rep);
		strcat (myPixels->path_info,".info");
	}

	return (myPixels);
}


/*
  This opens the repository file used by PixelsRep for reading or writing.
  rorw may be set to 'w' (write), 'r' (read), 'i' (info), or 'n' (new file).
*/
static
int openPixelsFile (PixelsRep *myPixels, char rorw) {
char *mmap_info=NULL,*mmap_rep=NULL;
pixHeader *head;
struct stat fStat;
	
	if (rorw == 'r' || rorw == 'i') {
		if (myPixels->fd_rep < 0)
			if ( (myPixels->fd_rep = open (myPixels->path_rep, O_RDONLY, 0600)) < 0)
				return (-1);
		if (myPixels->fd_info < 0)
			if ( (myPixels->fd_info = open (myPixels->path_info, O_RDONLY, 0600)) < 0)
				return (-2);
		if (!myPixels->size_info) {
			fstat (myPixels->fd_info , &fStat );
			myPixels->size_info = fStat.st_size;
		}
		if ((mmap_info = (char *) mmap (NULL, myPixels->size_info, PROT_READ, MAP_SHARED, myPixels->fd_info, 0LL)) == (char *) -1)
			return (-3);
		if (!myPixels->size_rep) {
			fstat (myPixels->fd_rep , &fStat );
			myPixels->size_rep = fStat.st_size;
		}
		if ( (mmap_rep = (char *)mmap (NULL, myPixels->size_rep, PROT_READ, MAP_SHARED, myPixels->fd_rep, 0LL)) == (char *) -1)
			return (-4);
	}

	if (rorw == 'w' || rorw == 'n') {
		if (myPixels->fd_rep < 0)
			if ( (myPixels->fd_rep = open (myPixels->path_rep, O_RDWR, 0600)) < 0)
				return (-5);
		if (myPixels->fd_info < 0)
			if ( (myPixels->fd_info = open (myPixels->path_info, O_RDWR, 0600)) < 0)
				return (-6);
		if (!myPixels->size_info) {
			fstat (myPixels->fd_info , &fStat );
			myPixels->size_info = fStat.st_size;
		}
		if ( (mmap_info = (char *)mmap (NULL, myPixels->size_info, PROT_READ|PROT_WRITE , MAP_SHARED, myPixels->fd_info, 0LL)) == (char *) -1 )
			return (-7);
		if (!myPixels->size_rep) {
			if (fstat (myPixels->fd_rep , &fStat) != 0)
				return (-8);
			myPixels->size_rep = fStat.st_size;
		}
		if ( (mmap_rep = (char *)mmap (NULL, myPixels->size_rep, PROT_READ|PROT_WRITE , MAP_SHARED, myPixels->fd_rep, 0LL)) == (char *) -1 )
			return (-9);
	}

	myPixels->head = head = (pixHeader *) mmap_info;
	myPixels->pixels = (void *) mmap_rep;
	myPixels->is_mmapped = 1;
				
	if (rorw == 'n') {
		head->mySig = OME_IS_PIXL_SIG;
		head->vers  = OME_IS_PIXL_VER;
	} else {
		/* wait until we can get a read lock on the header */
		lockRepFile (myPixels->fd_rep,'r',0LL,sizeof (pixHeader));
	}

	if (head->mySig != OME_IS_PIXL_SIG ||
		head->vers  != OME_IS_PIXL_VER) {
			fprintf (stderr,"Incompatible file type\n");
			return (-10);
	}
	
	if (!head->isFinished && rorw == 'r') {
			fprintf (stderr,"Attempt to read a write-only file\n");
			return (-11);
	}

	if (head->isFinished && rorw == 'w') {
			fprintf (stderr,"Attempt to write to a read-only file\n");
			return (-12);
	}

	myPixels->planeInfos = (planeInfo *) ( mmap_info + sizeof(pixHeader));
	myPixels->stackInfos = (stackInfo *) ( mmap_info + (sizeof (planeInfo) * head->dz * head->dc * head->dt)  + sizeof(pixHeader) );

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
char error[256];
pixHeader *head;
PixelsRep *myPixels;
off_t size;
int result;


	if (! (myPixels = newPixelsRep (0LL)) ) {
		perror ("BAH!");
		return (NULL);
	}
	myPixels->ID = nextID(myPixels->path_ID);
	if (myPixels->ID <= 0 && errno) {
		perror ("Couldn't get next Pixels ID");
		freePixelsRep (myPixels);
		return (NULL);
	} else if (myPixels->ID <= 0){
		fprintf (stderr,"Happy New Year !!!\n");
		freePixelsRep (myPixels);
		return (NULL);
	}

	size = sizeof (pixHeader);
	size += sizeof (planeInfo) * dz * dc * dt;
	size += sizeof (stackInfo) * dc * dt;
	myPixels->size_info = size;
	myPixels->fd_info = newRepFile (myPixels->ID, myPixels->path_info, size, "info");
	if (myPixels->fd_info < 0) {
		sprintf (error,"Couldn't open repository info file for PixelsID %llu (%s).",myPixels->ID,myPixels->path_info);
		perror (error);
		freePixelsRep (myPixels);
		return (NULL);
	}
	
	
	size = dx * dy * dz * dc * dt * bp;
	myPixels->size_rep = size;

	myPixels->fd_rep = newRepFile (myPixels->ID, myPixels->path_rep, size, NULL);
	if (myPixels->fd_rep < 0) {
		sprintf (error,"Couldn't open repository file for PixelsID %llu (%s).",myPixels->ID,myPixels->path_rep);
		perror (error);
		freePixelsRep (myPixels);
		return (NULL);
	}

	if ( (result = openPixelsFile (myPixels, 'n')) < 0) {
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

	/* release the lock created by newRepFile */
	lockRepFile (myPixels->fd_rep,'u',0LL,0LL);
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
static
PixelsRep *GetPixelsRep (OID ID, char rorw, char isBigEndian)
{
PixelsRep *myPixels;
pixHeader *head;
int result;

	if (!ID) return (NULL);

	if (! (myPixels = newPixelsRep (ID))) {
		fprintf (stderr,"Could not get a Pixels object.\n");
		return (NULL);
	}


	if ( (result = openPixelsFile (myPixels,rorw)) < 0) {
		fprintf (stderr,"Could not open pixels file. Result=%d\n",result);
		freePixelsRep (myPixels);
		return (NULL);
	}

	if (! (head = myPixels->head) ) {
		fprintf (stderr,"Pixels header is undefined.\n");
		freePixelsRep (myPixels);
		return (NULL);
	}
	
	if ( isBigEndian != bigEndian() && head->bp > 1) myPixels->doSwap = 1;

	return (myPixels);
}

static int
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
		fprintf (stderr,"Pix->CheckCoords:  Coordinates out of range.\n");
		return (0);
	}
	return (1);
}

/*
  Note that this is a byte offset - not a pixel offset.
*/
off_t GetOffset (PixelsRep *myPixels, ome_coord theX, ome_coord theY, ome_coord theZ, ome_coord theC, ome_coord theT) {
pixHeader *head;

	if (!myPixels) return (-1);
	if (! (head = myPixels->head) ) return (-1);
	if (! CheckCoords (myPixels,theX,theY,theZ,theC,theT)) return (-1);
	return ((((((theT*head->dc) + theC)*head->dz + theZ)*head->dy + theY)*head->dx + theX)*head->bp);
}

void byteSwap (unsigned char *theBuf, size_t length, char bp)
{
char  tmp;
unsigned char *maxBuf = theBuf+(length*bp);
	
	switch (bp) {
		case 2:
			while (theBuf < maxBuf) {
				tmp = *theBuf++;
				*(theBuf-1) = *theBuf;
				*theBuf++ = tmp;
			}
		case 4:
	  /*
	   * 0 -> 3
	   * 1 -> 2
	   * 2 -> 1
	   * 3 -> 0
	   */
			while (theBuf < maxBuf) {
				tmp = theBuf [0]; theBuf [0] = theBuf [3]; theBuf [3] = tmp;
				tmp = theBuf [1]; theBuf [1] = theBuf [2]; theBuf [2] = tmp;
				theBuf += 4;
			}
		case 8:
		/*
		* 0 -> 7
		* 1 -> 6
		* 2 -> 5
		* 3 -> 4
		* ...
		*/	
			while (theBuf < maxBuf) {
				tmp = theBuf [0]; theBuf [0] = theBuf [7]; theBuf [7] = tmp;
				tmp = theBuf [1]; theBuf [1] = theBuf [6]; theBuf [6] = tmp;
				tmp = theBuf [2]; theBuf [2] = theBuf [5]; theBuf [5] = tmp;
				tmp = theBuf [3]; theBuf [3] = theBuf [4]; theBuf [4] = tmp;
				theBuf += 8;
			}
		case 16:
		/*
		* 0 -> 15
		* 1 -> 14
		* 2 -> 13
		* 3 -> 12
		* 4 -> 11
		* 5 -> 10
		* 6 -> 9
		* 7 -> 8
		* ...
		*/
			while (theBuf < maxBuf) {
				tmp = theBuf [0]; theBuf [0] = theBuf [15]; theBuf [15] = tmp;
				tmp = theBuf [1]; theBuf [1] = theBuf [14]; theBuf [14] = tmp;
				tmp = theBuf [2]; theBuf [2] = theBuf [13]; theBuf [13] = tmp;
				tmp = theBuf [3]; theBuf [3] = theBuf [12]; theBuf [12] = tmp;
				tmp = theBuf [4]; theBuf [4] = theBuf [11]; theBuf [11] = tmp;
				tmp = theBuf [5]; theBuf [5] = theBuf [10]; theBuf [10] = tmp;
				tmp = theBuf [6]; theBuf [6] = theBuf [ 9]; theBuf [ 9] = tmp;
				tmp = theBuf [7]; theBuf [7] = theBuf [ 8]; theBuf [ 8] = tmp;
				theBuf += 16;
			}
		break;
		default:
		break;
	}
}





/*
  This reads the pixels at offset and writes nPix pixels to IO_stream or IO_mem
  Note that the offset parameter is a byte offset from (GetOffset),
  but the number returned is the number of pixels (not bytes).
*/
static
size_t DoPixelIO (PixelsRep *myPixels, off_t offset, size_t nPix, char rorw) {
size_t nIO=0;
size_t nBytes;
char *pixels,*pix_P;
pixHeader *head;
unsigned char bp;
off_t file_off;
char *IO_buf;
unsigned char *swap_buf;
unsigned long chunk_size;
unsigned long written=0;

	if (offset < 0) return (0);
	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	if (! (pixels = myPixels->pixels) ) return (0);
	if (! (bp = head->bp) ) return (0);
	
	nBytes = nPix*bp;
	file_off = offset;
	swap_buf = myPixels->swap_buf;
	chunk_size = 4096 / bp;
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
off_t stack_offset;

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
		if (chSpec->white < chSpec->black) chSpec->white = chSpec->black;
	}
	
	
	chSpec->scale =  255.0 / (chSpec->white - chSpec->black);

	chSpec->isFixed = 1;
}



/*
  This reads the pixels at offset, scales them according to chSpec,
  and writes them to buf.  The omeis pixels are scaled down to unsigned char values.
  The jump parameter is used to jump to the next pixel in *buf
  (i.e. 1 for grayscale, 3 for RGB, 4 for RGBA).
*/
void ScalePixels (
	PixelsRep *myPixels, off_t offset, size_t nPix,
	unsigned char *buf, off_t jump,
	channelSpecType *chSpec)
{
size_t nIO=0, nBytes;
pixHeader *head;
unsigned char *thePix, *lastPix;
unsigned char bp;
register float theVal;
float scale;

	if (offset < 0) return;
	if (!myPixels) return;
	if (! (head = myPixels->head) ) return;
	if (! (bp = head->bp) ) return;
	if (! chSpec->isOn ) return;
	if (! buf ) return;

	nBytes = nPix*bp;

	thePix = ((char *)myPixels->pixels) + offset;
	lastPix = thePix + (nPix*bp);

	if (lockRepFile (myPixels->fd_rep,'r',offset,nBytes) < 0) return;

	if (!chSpec->isFixed) fixChannelSpec (myPixels,chSpec);
	if (!chSpec->isFixed) return;

	scale = chSpec->scale;

	if (head->bp == 1 && head->isSigned) {
		char blk = (char) chSpec->black, *sCharP = (char *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*sCharP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 1 && !head->isSigned) {
		unsigned char blk = (unsigned char) chSpec->black, *uCharP = (unsigned char *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*uCharP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 2 && head->isSigned) {
		short blk = (short) chSpec->black, *sShrtP = (short *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*sShrtP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 2 && !head->isSigned) {
		unsigned short blk = (unsigned short) chSpec->black, *uShrtP = (unsigned short *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*uShrtP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && head->isSigned && !head->isFloat) {
		long blk = (long) chSpec->black, *sLongP = (long *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*sLongP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && !head->isSigned && !head->isFloat) {
		unsigned long blk = (unsigned long) chSpec->black, *uLongP = (unsigned long *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*uLongP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
			if (theVal > 255) theVal=255;
			*buf = theVal;
			buf += jump;
			nIO++;
		}
	} else if (head->bp == 4 && head->isFloat) {
		float blk = (float) chSpec->black, *floatP = (float *)thePix;
		while (nIO < nPix) {
			theVal = (float) (*floatP++ - blk);
			if (theVal < 0) theVal = 0;
			theVal *= scale;
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
off_t offset=0;
size_t nPix, nIO=0;

	nPix = thePixels->head->dx * thePixels->head->dy;
	offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
	thePixels->IO_stream = NULL;
	thePixels->IO_buf = buf;
	thePixels->IO_buf_off = 0;
	thePixels->doSwap = 0;

	nIO = DoPixelIO(thePixels, offset, nPix, 'w');
	return( nIO );

}


static
size_t DoROI (PixelsRep *myPixels,
	ome_coord x0, ome_coord y0, ome_coord z0, ome_coord w0, ome_coord t0,
	ome_coord x1, ome_coord y1, ome_coord z1, ome_coord w1, ome_coord t1, char rorw
)
{
pixHeader *head;
ome_dim dx,dy,dz,dc,dt,bp;
ome_coord x,y,z,w,t;
size_t sizeX, nIO_t=0, nIO=0;
char *pix;
off_t off0, off1;

	if (!myPixels) return (0);
	if (! (pix = (char *)myPixels->pixels) ) return (0);
	if (! (head = myPixels->head) ) return (0);
	if ( (off0 = GetOffset (myPixels, x0, y0, z0, w0, t0)) < 0) return (0);
	if ( (off1 = GetOffset (myPixels, x1, y1, z1, w1, t1)) < 0) return (0);
	if (off0 >= off1) return (0);
	dx = head->dx;
	dy = head->dy;
	dz = head->dz;
	dc = head->dc;
	dt = head->dt;
	bp = head->bp;

	sizeX = x1-x0+1;
	x=x0;
	for (t=t0;t <= t1; t++) {
		for (w=w0;w <= w1; w++) {
			for (z=z0;z <= z1; z++) {
				for (y=y0;y <= y1; y++) {
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
off_t file_off,plane_offset;

	if (!myPixels) return (0);
	if (!myPixels->planeInfos) return (0);
	if (!CheckCoords (myPixels,0,0,z,c,t)) return (0);
	if (! (head = myPixels->head) ) return (0);

	plane_offset = (((t*head->dc) + c)*head->dz) + z;
	file_off  = ((char *)myPixels->planeInfos - (char *)myPixels->head) + (plane_offset*nBytes);

	if (lockRepFile (myPixels->fd_info,rorw,file_off,nBytes) < 0) {
		fprintf (stderr,"Could't get file lock\n");
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
off_t file_off,stack_offset;

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
  are OK before doing it's job, so calling this will allways result in a new
  statistics calculation.
*/

static
int DoPlaneStats (PixelsRep *myPixels, ome_coord z, ome_coord c, ome_coord t) {
planeInfo myPlaneInfo;
pixHeader *head;
ome_dim dx, dy, nPix;
ome_coord x, y;
off_t pix_off;
char *thePix;
unsigned char  *uCharP;
unsigned short *uShrtP;
unsigned long  *uLongP;
char  *sCharP;
short *sShrtP;
long  *sLongP;
float *floatP;
register float theVal,logOffset=1.0,min=FLT_MAX,max=0.0,sum_i=0.0,sum_i2=0.0,sum_log_i=0.0,sum_xi=0.0,sum_yi=0.0,sum_zi=0.0;


	if (!myPixels) return (0);
	if (!myPixels->stackInfos) return (0);
	if (!CheckCoords (myPixels,0,0,z,c,t)) return (0);
	if (! (head = myPixels->head) ) return (0);

	dx = head->dx;
	dy = head->dy;
	nPix = dx*dy;
	pix_off = GetOffset (myPixels, 0, 0, z, c, t);
	
	thePix = ((char *)myPixels->pixels) + pix_off;

	if (head->bp == 1 && head->isSigned) {
		sCharP = thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sCharP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 1 && !head->isSigned) {
		uCharP = (unsigned char *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uCharP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 2 && head->isSigned) {
		sShrtP = (short *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sShrtP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 2 && !head->isSigned) {
		uShrtP = (unsigned short *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uShrtP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 4 && head->isSigned && !head->isFloat) {
		sLongP = (long *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *sLongP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 4 && !head->isSigned && !head->isFloat) {
		uLongP = (unsigned long *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *uLongP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
		}
	} else if (head->bp == 4 && head->isFloat) {
		floatP = (float *) thePix;
		for (x=0;x<dx;x++) {
			for (y=0;y<dy;y++) {
				theVal = (float) *floatP++;
				sum_xi    += (theVal*x);
				sum_yi    += (theVal*y);
				sum_zi    += (theVal*z);
				sum_i     += theVal;
				sum_i2    += (theVal*theVal);
				sum_log_i +=  log (theVal+logOffset);
				if (theVal < min) min = theVal;
				if (theVal > max) max = theVal;
			}
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
	return (DoPlaneInfoIO (myPixels, &myPlaneInfo, z, c, t, 'w') );
}


/*
  This is the stack statistics calculator.  It checks if the stack statisticks
  are OK, and if not checks if each plane statistics is OK, calling
  DoPlaneStats if it isn't.
*/
static
int DoStackStats (PixelsRep *myPixels, ome_coord c, ome_coord t) {
stackInfo myStackInfo;
pixHeader *head;
ome_dim dz;
ome_coord z;
stackInfo *stackInfoP;
planeInfo *planeInfoP;
off_t plane_offset,stack_offset;
register float logOffset=1.0,min=FLT_MAX,max=FLT_MIN,sum_i=0.0,sum_i2=0.0,sum_log_i=0.0,sum_xi=0.0,sum_yi=0.0,sum_zi=0.0,nPix;

	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	dz = head->dz;

	plane_offset = ((t*head->dc) + c)*dz;
	stack_offset = (t*head->dc) + c;

	if (! (stackInfoP = myPixels->stackInfos + stack_offset) ) return (0);
	if (stackInfoP->stats_OK) return (1);
	if (! (planeInfoP = myPixels->planeInfos + plane_offset) ) return (0);
	
	for (z = 0; z < dz; z++) {
		if (! planeInfoP->stats_OK)
			DoPlaneStats (myPixels, z, c, t);
		sum_xi    += planeInfoP->sum_xi;
		sum_yi    += planeInfoP->sum_yi;
		sum_zi    += planeInfoP->sum_zi;
		sum_i     += planeInfoP->sum_i;
		sum_i2    += planeInfoP->sum_i2;
		sum_log_i += planeInfoP->sum_log_i;
		if (planeInfoP->min < min) min = planeInfoP->min;
		if (planeInfoP->max > max) max = planeInfoP->max;
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
	myStackInfo.geomean = exp ( sum_log_i / nPix ) - logOffset;

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
*/

static
int FinishStats (PixelsRep *myPixels, char force) {
	ome_dim  dc, dz, dt;
	ome_coord z, c, t;
	pixHeader *head;
	stackInfo *stackInfoP;
	planeInfo *planeInfoP;


	if (!myPixels) return (0);
	if (! (head = myPixels->head) ) return (0);
	if (! (stackInfoP = myPixels->stackInfos) ) return (0);
	if (! (planeInfoP = myPixels->planeInfos) ) return (0);
	dz = head->dz;
	dc = head->dc;
	dt = head->dt;
	for (t = 0; t < dt; t++)
		for (c = 0; c < dc; c++) {
			if (force) stackInfoP->stats_OK = 0;
			for (z = 0; z < dz; z++) {
				if (force) planeInfoP->stats_OK = 0;
				if (! planeInfoP->stats_OK)
					if (!DoPlaneStats (myPixels, z, c, t)) return (0);
				planeInfoP++;
			}
			if (! stackInfoP->stats_OK)
				if (!DoStackStats (myPixels, c, t)) return (0);
			stackInfoP++;
		}
	return (1);
}

int FinishPixels (PixelsRep *myPixels, char force) {

	if (!myPixels) return (-1);

	/* wait until we can get a write lock on the whole file */
	lockRepFile (myPixels->fd_rep,'w',0LL,0LL);
	
	/* Make sure all the stats are up to date */
	if (!FinishStats (myPixels,force)) return (-3);


	myPixels->head->isFinished = 1;

	if (myPixels->is_mmapped) {
		if (msync (myPixels->head , myPixels->size_info , MS_SYNC) != 0) return (-4);

		if (msync (myPixels->pixels , myPixels->size_rep , MS_SYNC) != 0) return (-5);
	}

	return (0);
}

/*
 * openInputFile(char *filename, unsigned char isLocalFile)
 * closeInputFile(FILE *infile, unsigned char isLocalFile)
 *
 * These functions allow the UploadFile and Set* methods to accept the
 * input data from a file in the local filesystem instead of from
 * STDIN.  This will only be useful if the image server is being called
 * via the command line (and not as a CGI script) from client code
 * running on the same machine.
 */

static
FILE *openInputFile(char *filename, unsigned char isLocalFile) {
    FILE *infile;

    if (isLocalFile) {
        if (!(infile = fopen(filename,"r"))) {
            fprintf(stderr,"Could not open local input file %s",filename);
            return NULL;
        }
    } else {
        infile = stdin;
    }

    return infile;
}

static
void closeInputFile(FILE *infile, unsigned char isLocalFile) {
    if (isLocalFile) {
        fclose(infile);
    }
}

static
int NewFile (OID *ID, char *filename, off_t size) {
char path[MAXPATHLEN];
char *filesIDfile="Files/lastFileID";
int fd;

	strcpy (path,"Files/");
	*ID = nextID(filesIDfile);
	if (*ID <= 0 && errno) {
		perror ("Couldn't get next File ID");
		return (-1);
	} else if (*ID <= 0){
		fprintf (stderr,"Happy New Year !!!\n");
		return (-1);
	}

	fd = newRepFile (*ID, path, size, NULL);
	if (fd < 0) {
		char error[256];
		sprintf (error,"Couldn't open repository file for FileID %llu (%s).",*ID,path);
		perror (error);
		return (-1);
	}

	if (filename && strlen (filename)) {
		FILE *fInfo;
		strcat (path,".name");
		if ( (fInfo = fopen (path,"w")) ) {
			fwrite (filename,1,strlen(filename),fInfo);
			fclose (fInfo);
		}
	}

	return (fd);

}

static
int DeleteFile (OID fileID) {
char path[MAXPATHLEN];
	strcpy (path,"Files/");
	if (!fileID) return (-1);
	
	if (! getRepPath (fileID,path,0)) {
		return (-2);
	}
	unlink (path);
	strcat (path,".name");
	unlink (path);
	return (0);
}

static
void FinishFile (int fd) {
	lockRepFile (fd,'u',0LL,0LL);
	close (fd);
}



/*
  UploadFile (char *filename, off_t size)
  Makes new rep file in 'Files' of the specified size.
  copies filename parameter to OID.info
  Reads stdin, writing to the file.
  returns file OID.
*/
static
OID UploadFile (char *filename, off_t size, unsigned char isLocalFile) {
OID ID;
int fd;
size_t nIO;
char *sh_mmap;
FILE *infile;

	if (  (fd = NewFile( &ID, filename, size )) == -1 ) return 0;
	if ( size > UINT_MAX ) return 0;  /* Bad mojo for mmap */

	if ( (sh_mmap = (char *)mmap (NULL, size, PROT_READ|PROT_WRITE , MAP_SHARED, fd, 0LL)) == (char *) -1 ) {
		close (fd);
		DeleteFile (ID);
		fprintf (stderr,"Couldn't mmap uploaded file %s (ID=%llu)\n",filename,ID);
		return (0);
	}

    infile = openInputFile(filename,isLocalFile);

    if (infile) {
        nIO = fread (sh_mmap,1,size,infile);
        if (nIO != size) {
            fprintf (stderr,"Could finish writing uploaded file %s (ID=%llu).  Wrote %lu, expected %lu\n",
                     filename,ID,(unsigned long)nIO,(unsigned long)size);
            ID = 0;
        }

        closeInputFile(infile,isLocalFile);
    }

	/* release the lock created by newRepFile */
	munmap (sh_mmap, size);
	FinishFile (fd);
	return (ID);
}

static
size_t ConvertFile (PixelsRep *myPixels, OID fileID, off_t file_offset, off_t pix_offset, size_t nPix) {
pixHeader *head;
int fd;
char file_path[MAXPATHLEN],bp, *sh_mmap;
unsigned long nIO;
convertFileRec convFileRec;
FILE *convFileInfo;
char convFileInfoPth[MAXPATHLEN];
char isBigEndian=1;

	strcpy (file_path,"Files/");

	if (!fileID || !myPixels) return (0);
	
	if (! getRepPath (fileID,file_path,0)) {
		return (0);
	}

	if (! (head = myPixels->head) ) return (0);
	bp = head->bp;


	if ( (fd = open (file_path, O_RDONLY, 0600)) < 0) {
		return (0);
	}
	if ( (sh_mmap = (char *)mmap (NULL, nPix*bp, PROT_READ, MAP_SHARED, fd, file_offset)) == (char *) 0 ) {
		close (fd);
		return (0);
	}



	myPixels->IO_buf = sh_mmap;
	nIO = DoPixelIO (myPixels, pix_offset, nPix, 'w');
	if (nIO != nPix) {
		munmap (sh_mmap, nPix*bp);
		close (fd);
		return (nIO);
	}

	if ( (myPixels->doSwap && bigEndian()) || (!myPixels->doSwap && !bigEndian()) ) isBigEndian = 0;
	convFileRec.FileID      = fileID;
	convFileRec.isBigEndian = isBigEndian;
	convFileRec.spec.file.file_offset = file_offset;
	convFileRec.spec.file.pix_offset  = pix_offset;
	convFileRec.spec.file.nPix        = nPix;

	sprintf (convFileInfoPth,"%s.convert",myPixels->path_rep);
	if ( (convFileInfo = fopen (convFileInfoPth,"a")) ) {
		fwrite (&convFileRec , sizeof (convertFileRec) , 1 , convFileInfo );
		fclose (convFileInfo);
	}

	munmap (sh_mmap, nPix*bp);
	close (fd);
	return (nIO);
}

static
size_t ConvertTIFF (PixelsRep *myPixels, OID fileID, ome_coord theZ, ome_coord theC, ome_coord theT) {
pixHeader *head;
char file_path[MAXPATHLEN],bp;
unsigned long nIO, nOut;
off_t pix_offset;
size_t nPix;
convertFileRec convFileRec;
FILE *convFileInfo;
char convFileInfoPth[MAXPATHLEN];
TIFF *tiff = NULL;
tdata_t buf;
tstrip_t strip;
uint32 width = 0;
uint32 height = 0;
uint16 chans = 0, bpp, pc;
tsize_t stripSize;

	strcpy (file_path,"Files/");

	if (!fileID || !myPixels) return (0);
	
	if (! getRepPath (fileID,file_path,0)) {
		return (0);
	}

	if (! (head = myPixels->head) ) return (0);
	bp = head->bp;
	if (!CheckCoords (myPixels,0,0,theZ, theC, theT)) return (0);
	if (! (head = myPixels->head) ) return (0);

	pix_offset = GetOffset (myPixels, 0, 0, theZ, theC, theT);
	
    if (! (tiff = TIFFOpen(file_path, "r")) ) {
		fprintf (stderr,"ConvertTIFF:  Couldn't open TIFF file.\n");
    	return (0);
    }
    
	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);
	TIFFGetField(tiff, TIFFTAG_SAMPLESPERPIXEL, &chans);
	TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &bpp);
	TIFFGetField(tiff, TIFFTAG_PLANARCONFIG, &pc);

	bpp /= 8;
	if (width != head->dx || height != head->dy || chans > 1 || bpp != head->bp ||
		pc != PLANARCONFIG_CONTIG ) {
			TIFFClose(tiff);
			fprintf (stderr,"ConvertTIFF:  TIFF <-> Pixels mismatch.\n");
			fprintf (stderr,"\tWidth x Height:    Pixels (%d,%d) TIFF (%u,%u)\n",(int)head->dx,(int)head->dy,(unsigned)width,(unsigned)height);
			fprintf (stderr,"\tSamples per pixel: Pixels (%d) TIFF (%d)\n",(int)1,(int)chans);
			fprintf (stderr,"\tBytes per sample:  Pixels (%d) TIFF (%d)\n",(int)head->bp,(int)bpp);
			fprintf (stderr,"\tPlanar Config:     Pixels (%d) TIFF (%d)\n",(int)PLANARCONFIG_CONTIG,(int)pc);
			return (0);
	}

	if (! (buf = _TIFFmalloc(TIFFStripSize(tiff))) ) {
		fprintf (stderr,"ConvertTIFF:  Couldn't allocate strip buffer.\n");
		return (0);
	}

	convFileRec.FileID         = fileID;
	convFileRec.isTIFF         = 1;
	convFileRec.spec.tiff.theZ = theZ;
	convFileRec.spec.tiff.theC = theC;
	convFileRec.spec.tiff.theT = theT;

	myPixels->IO_buf = buf;
	myPixels->IO_buf_off = 0;
	for (strip = 0; strip < TIFFNumberOfStrips(tiff); strip++) {
		stripSize = TIFFReadEncodedStrip(tiff, strip, buf, (tsize_t) -1);
		nPix = stripSize / bpp;
		myPixels->IO_buf_off = 0;
		nOut = DoPixelIO (myPixels, pix_offset, nPix, 'w');
		pix_offset += stripSize;
		nIO += nOut;
	}
	_TIFFfree(buf);
	TIFFClose(tiff);

	sprintf (convFileInfoPth,"%s.convert",myPixels->path_rep);
	if ( (convFileInfo = fopen (convFileInfoPth,"a")) ) {
		fwrite (&convFileRec , sizeof (convertFileRec) , 1 , convFileInfo );
		fclose (convFileInfo);
	}

	return (nIO);
}


/*
  GetArchive (PixelsRep myPixels)
  Collects all the files that were used to generate the Pixels (if any)
  makes a tar/gz or zip archive of them in a file with the same filepath as the pixels, with a .tgz extension.
*/
static
int GetArchive (PixelsRep myPixels, char *format) {
	return (0);
}

void HTTP_DoError (char *method,char *errMsg) {
/*
403 Forbidden Authorization failure
500 Server Error 
*/
	if (getenv("REQUEST_METHOD")) {
		fprintf (stdout,"Status: 500 %s\r\n",errMsg);
		fprintf (stdout,"Content-Type: text/plain\r\n\r\n");
		fprintf (stdout,"Error calling %s: %s\n", method, errMsg);
		fprintf (stderr,"Error calling %s: %s\n", method, errMsg);
	} else {
		fprintf (stderr,"Error calling %s: %s\n", method, errMsg);
	}
}

void HTTP_ResultType (char *mimeType) {

	if (getenv("REQUEST_METHOD")) {
		fprintf (stdout,"Content-Type: %s\r\n\r\n",mimeType);
	}
}

static
int
dispatch (char **param)
{
	PixelsRep *thePixels;
	pixHeader *head;
	size_t nPix=0, nIO=0;
	char *theParam,rorw='r',iam_BigEndian=1;
	OID ID=0;
	off_t offset=0;
	off_t file_offset=0;
	char error_str[256];
	unsigned char isLocalFile;
	unsigned char file_md[OME_DIGEST_LENGTH];
	char *dims;
	int isSigned,isFloat;
	int numInts,numX,numY,numZ,numC,numT,numB;
	int force,result;
	unsigned long z,dz,c,dc,t,dt;
	planeInfo *planeInfoP;
	stackInfo *stackInfoP;
	unsigned long uploadSize;
	unsigned long length;
	OID fileID;
	struct stat fStat;
	FILE *fInfo;
	char file_path[MAXPATHLEN];
	char file_name[MAXNAMELEN];
	int fd;
	char *sh_mmap;
	
	/* Co-ordinates */
	ome_coord theC = -1, theT = -1, theZ = -1, theY = -1;

/*
char **cgivars=param;
	while (*cgivars) {
		fprintf (stderr,"[%s]",*cgivars);cgivars++;fprintf (stderr," = [%s]\n",*cgivars);cgivars++;
	}
*/

	/* XXX: char * method should be able to disappear at some point */
	char *method;
	unsigned int m_val;

	error_str[0]=0;

	if (! (method = get_param (param,"Method")) ) {
		HTTP_DoError (method,"Method parameter missing");
		return (-1);
	}
	
	m_val = get_method_by_name(method);
	/* END (method operations) */

	/* ID requirements */
	if ( (theParam = get_param (param,"PixelsID")) )
		sscanf (theParam,"%llu",&ID);
	else if (m_val != M_NEWPIXELS    &&
			 m_val != M_FILEINFO     &&
			 m_val != M_FILESHA1     &&
			 m_val != M_READFILE     &&
			 m_val != M_UPLOADFILE   &&
			 m_val != M_GETLOCALPATH) {
			HTTP_DoError (method,"PixelsID Parameter missing");
			return (-1);
	}

    if ((theParam = get_param(param,"IsLocalFile")))
        sscanf(theParam,"%hhu",&isLocalFile);
    else
        isLocalFile = 0;


	if ( (theParam = get_param (param,"theZ")) )
		sscanf (theParam,"%d",&theZ);

	if ( (theParam = get_param (param,"theC")) )
		sscanf (theParam,"%d",&theC);

	if ( (theParam = get_param (param,"theT")) )
		sscanf (theParam,"%d",&theT);
	
	if ( (theParam = get_param (param,"theY")) )
		sscanf (theParam,"%d",&theZ);

	if ( (theParam = get_param (param,"BigEndian")) ) {
		if (!strcmp (theParam,"0") || !strcmp (theParam,"False") || !strcmp (theParam,"false") ) iam_BigEndian=0;
	}

	/* ---------------------- */
	/* SIMPLE METHOD DISPATCH */
	switch (m_val) {
		case M_NEWPIXELS:
			isSigned = 0;
			isFloat = 0;
		
			if (! (dims = get_param (param,"Dims")) ) {
				HTTP_DoError (method,"Dims Parameter missing");
				return (-1);
			}
			numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&numX,&numY,&numZ,&numC,&numT,&numB);
			if (numInts < 6 || numX < 1 || numY < 1 || numZ < 1 || numC < 1 || numT < 1 || numB < 1) {
				HTTP_DoError (method,"Dims improperly formed.  Expecting numX,numY,numZ,numC,numT,numB");
				return (-1);
			}

			if ( (theParam = get_param (param,"IsSigned")) )
				sscanf (theParam,"%d",&isSigned);
			if ( (theParam = get_param (param,"IsFloat")) )
				sscanf (theParam,"%d",&isFloat);

			if (! (thePixels = NewPixels (numX,numY,numZ,numC,numT,numB,isSigned,isFloat)) ) {
				HTTP_DoError (method,strerror( errno ) );
				return (-1);
			}

			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%llu\n",thePixels->ID);
			freePixelsRep (thePixels);

			break;
		case M_PIXELSINFO:
        	if (!ID) return (-1);

			if (! (thePixels = GetPixelsRep (ID,'i',1)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			HTTP_ResultType ("text/plain");
			fprintf(stdout,"Dims=%d,%d,%d,%d,%d,%hhu\n",
					head->dx,head->dy,head->dz,head->dc,head->dt,head->bp);
			fprintf(stdout,"Finished=%hhu\nSigned=%hhu\nFloat=%hhu\n",
					head->isFinished,head->isSigned,head->isFloat);

			freePixelsRep (thePixels); 

			break;
		case M_PIXELSSHA1:
        	if (!ID) return (-1);

        	if (! (thePixels = GetPixelsRep(ID,'r',1))) {
				if (errno) HTTP_DoError(method,strerror(errno));
				else HTTP_DoError(method,"Access control error - check log for details");
				
				return (-1);
			}

        	HTTP_ResultType("text/plain");

			/* Get the SHA1 message digest */
			if (get_md_from_file(thePixels->path_rep, file_md) < 0) {
				fprintf(stderr, "Unable to retrieve SHA1.");
        		freePixelsRep(thePixels);

				return(-1);
			}

			/* Free */
        	freePixelsRep(thePixels);

			/* Print our lovely and useful SHA1. */
			print_md(file_md);  /* Convenience provided by digest.c */
			printf("\n");
	
			return (0);

			break;
		case M_FINISHPIXELS:
			force = 0;
			result = 0;

			if (!ID) return (-1);
			if ( (theParam = get_param (param,"Force")) )
				sscanf (theParam,"%d",&force);

			if (! (thePixels = GetPixelsRep (ID,'w',iam_BigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}
	
			result = FinishPixels (thePixels,force);
			freePixelsRep (thePixels);
		
			if ( result < 0) {
				if (errno) sprintf (error_str,"Result=%d, Message=%s",result,strerror( errno ) );
				else sprintf (error_str,"Result=%d, Message=%s",result,"Access control error - check error log for details" );
				HTTP_DoError (method, error_str);
				return (-1);
			} else {
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%llu\n",ID);
			}

			break;
		case M_GETPLANESTATS:
			if (!ID) return (-1);
		
			if (! (thePixels = GetPixelsRep (ID,'r',bigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			if (! (planeInfoP = thePixels->planeInfos) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			dz = head->dz;
			dc = head->dc;
			dt = head->dt;
			HTTP_ResultType ("text/plain");

			for (t = 0; t < dt; t++)
				for (c = 0; c < dc; c++)
					for (z = 0; z < dz; z++) {
						fprintf (stdout,"%lu\t%lu\t%lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n",
							 c,t,z,planeInfoP->min,planeInfoP->max,planeInfoP->mean,planeInfoP->sigma,planeInfoP->geomean,planeInfoP->geosigma,
							 planeInfoP->centroid_x, planeInfoP->centroid_y,
							 planeInfoP->sum_i, planeInfoP->sum_i2, planeInfoP->sum_log_i,
							 planeInfoP->sum_xi, planeInfoP->sum_yi, planeInfoP->sum_zi
						);
						planeInfoP++;
					}

			freePixelsRep (thePixels);

			break;
		case M_GETSTACKSTATS:
			if (!ID) return (-1);
		
			if (! (thePixels = GetPixelsRep (ID,'r',bigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			if (! (stackInfoP = thePixels->stackInfos) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			dz = head->dz;
			dc = head->dc;
			dt = head->dt;
			HTTP_ResultType ("text/plain");

			for (t = 0; t < dt; t++)
				for (c = 0; c < dc; c++) {
					fprintf (stdout,"%lu\t%lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n",
						 c,t,stackInfoP->min,stackInfoP->max,stackInfoP->mean,stackInfoP->sigma,stackInfoP->geomean,stackInfoP->geosigma,
						 stackInfoP->centroid_x, stackInfoP->centroid_y, stackInfoP->centroid_z,
						 stackInfoP->sum_i, stackInfoP->sum_i2, stackInfoP->sum_log_i,
						 stackInfoP->sum_xi, stackInfoP->sum_yi, stackInfoP->sum_zi
					);
					stackInfoP++;
				}

			freePixelsRep (thePixels);

			break;
		case M_UPLOADFILE:
			uploadSize = 0;
			if ( (theParam = get_param (param,"UploadSize")) )
				sscanf (theParam,"%lu",&uploadSize);
			else {
				HTTP_DoError (method,"UploadSize must be specified!");
				return (-1);
			}
			if ( (ID = UploadFile (get_param (param,"File"),uploadSize,isLocalFile) ) == 0) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			} else {
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%llu\n",ID);
			}

			break;
		case M_GETLOCALPATH:
			fileID = 0;

			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);

			if (ID) {
				if (! (thePixels = GetPixelsRep (ID,'i',iam_BigEndian)) ) {
					if (errno) HTTP_DoError (method,strerror( errno ) );
					else  HTTP_DoError (method,"Access control error - check error log for details" );
					return (-1);
				}
				strcpy (file_path,thePixels->path_rep);
				freePixelsRep (thePixels);
			} else if (fileID) {
				strcpy (file_path,"Files/");
				if (! getRepPath (fileID,file_path,0)) {
					sprintf (error_str,"Could not get repository path for FileID=%llu",fileID);
					HTTP_DoError (method,error_str);
					return (-1);
				}		
			} else strcpy (file_path,"");

			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%s\n",file_path);

			break;
		case M_FILEINFO:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			strcpy (file_path,"Files/");
			if (! getRepPath (fileID,file_path,0)) {
				sprintf (error_str,"Could not get repository path for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);
			}
		
			if (stat (file_path, &fStat) < 0) {
				sprintf (error_str,"Could not get information for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);			
			}
		
			strcat (file_path,".name");
			strcpy (file_name,"");
			if ( (fInfo = fopen (file_path,"r")) ) {
				nIO = fread (file_name,1,255,fInfo);
				fclose (fInfo);
				if (nIO) file_name[nIO]=0;
			}


			HTTP_ResultType ("text/plain");
			fprintf (stdout,"Name=%s\nLength=%lu\n",file_name,(unsigned long)fStat.st_size);

			break;
		case M_FILESHA1:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			strcpy (file_path,"Files/");
			if (! getRepPath (fileID,file_path,0)) {
				sprintf (error_str,"Could not get repository path for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);
			}
			
			if (stat (file_path, &fStat) < 0) {
				sprintf (error_str,"Could not get information for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);			
			}
		
			strcat (file_path,".name");
			strcpy (file_name,"");
			if ( (fInfo = fopen (file_path,"r")) ) {
				nIO = fread (file_name,1,255,fInfo);
				fclose (fInfo);
				if (nIO) file_name[nIO]=0;
			}
		
			HTTP_ResultType ("text/plain");

			/* Get the SHA1 message digest */
			if (get_md_from_file(file_name, file_md) < 0) {
				fprintf(stderr, "Unable to retrieve SHA1.");
				return(-1);
			}

			/* Print our lovely and useful SHA1. */
			print_md(file_md);  /* Convenience provided by digest.c */
			printf("\n");

			break;
		case M_READFILE:
			offset = 0;
			length = 0;
			
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( (theParam = get_param (param,"Offset")) )
            {
				sscanf (theParam,"%lld",&offset);
            }
			if ( (theParam = get_param (param,"Length")) )
				sscanf (theParam,"%lu",&length);

			strcpy (file_path,"Files/");
			if (! getRepPath (fileID,file_path,0)) {
				sprintf (error_str,"Could not get repository path for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);
			}

			if ( (fd = open (file_path, O_RDONLY, 0600)) < 0) {
				sprintf (error_str,"Could not open FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);
			}
			if ( (sh_mmap = (char *)mmap (NULL, length, PROT_READ, MAP_SHARED, fd, offset)) == (char *) -1 ) {
				close (fd);
				sprintf (error_str,"Could not mmap FileID=%llu, offset=%lld, length=%lu",fileID,offset,length);
				HTTP_DoError (method,error_str);
				return (-1);
			}
		
			HTTP_ResultType ("application/octet-stream");
			fwrite (sh_mmap,length,1,stdout);
			munmap (sh_mmap, length);
			close (fd);

			break;
		case M_IMPORTOMEFILE:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}
	
			strcpy (file_path,"Files/");
			if (! getRepPath (fileID,file_path,0)) {
				sprintf (error_str,"Could not get repository path for FileID=%llu",fileID);
				HTTP_DoError (method,error_str);
				return (-1);
			}
	
			
			HTTP_ResultType ("text/xml");
			parse_xml_file( file_path );

			break;
		case M_CONVERT:
		case M_CONVERTSTACK:
		case M_CONVERTPLANE:
		case M_CONVERTTIFF:
		case M_CONVERTROWS:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( (theParam = get_param (param,"Offset")) )
				sscanf (theParam,"%lld",&file_offset);
		
			if (! (thePixels = GetPixelsRep (ID,'w',iam_BigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}
			head = thePixels->head;
			nPix = head->dx*head->dy*head->dz*head->dc*head->dt;
			offset = 0;

			if (m_val == M_CONVERTSTACK) {
				if (theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theC and theT must be specified to do operations on stacks." );
					return (-1);
				}
				nPix = head->dx*head->dy*head->dz;
				offset = GetOffset (thePixels, 0, 0, 0, theC, theT);
			} else if (m_val == M_CONVERTPLANE || m_val == M_CONVERTTIFF) {
				if (theZ < 0 || theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theZ, theC and theT must be specified to do operations on planes." );
					return (-1);
				}
				nPix = head->dx*head->dy;
				offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
			} else if (m_val == M_CONVERTROWS) {
				long nRows=1;

				if ( (theParam = get_param (param,"nRows")) )
					sscanf (theParam,"%ld",&nRows);
				if (theY < 0 ||theZ < 0 || theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theY, theZ, theC and theT must be specified to do operations on rows." );
					return (-1);
				}

				nPix = nRows*head->dy;
				offset = GetOffset (thePixels, 0, theY, theZ, theC, theT);
			}

			if (m_val == M_CONVERTTIFF)
				nIO = ConvertTIFF (thePixels, fileID, theZ, theC, theT);
			else
				nIO = ConvertFile (thePixels, fileID, file_offset, offset, nPix);
			if (nIO < nPix) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				freePixelsRep (thePixels);
				return (-1);
			} else {
				freePixelsRep (thePixels);
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%ld\n", (long) nIO);
			}

			break;
			
			case M_COMPOSITE:
				if (theZ < 0 || theT < 0) {
					HTTP_DoError (method,"Parameters theZ, and theT must be specified for the composite method." );
					return (-1);
				}
				if (! (thePixels = GetPixelsRep (ID,'r',bigEndian)) ) {
					if (errno) HTTP_DoError (method,strerror( errno ) );
					else  HTTP_DoError (method,"Access control error - check error log for details" );
					return (-1);
				}
				
				DoComposite (thePixels, theZ, theT, param);
			break;
	} /* END case (method) */

	/* ----------------------- */
	/* COMPLEX METHOD DISPATCH */
	if (m_val == M_SETPIXELS || m_val == M_GETPIXELS ||
		m_val == M_SETPLANE  || m_val == M_GETPLANE  ||
		m_val == M_SETSTACK  || m_val == M_GETSTACK) {
		char *filename = NULL;
		if (!ID) return (-1);


		if (strstr (method,"Set")) {
            rorw = 'w';
            if (!(filename = get_param(param,"Pixels"))) {
                HTTP_DoError(method,"No pixels filename specified");
            }
		} else rorw = 'r';

		if (! (thePixels = GetPixelsRep (ID,rorw,iam_BigEndian)) ) {
			if (errno) HTTP_DoError (method,strerror( errno ) );
			else  HTTP_DoError (method,"Access control error - check error log for details" );
			return (-1);
		}

		head = thePixels->head;
		if (strstr (method,"Pixels")) {
			nPix = head->dx*head->dy*head->dz*head->dc*head->dt;
			offset = 0;
		} else if (strstr (method,"Stack")) {
			if (theC < 0 || theT < 0) {
				freePixelsRep (thePixels);
				HTTP_DoError (method,"Parameters theC and theT must be specified to do operations on stacks." );
				return (-1);
			}
			nPix = head->dx*head->dy*head->dz;
			offset = GetOffset (thePixels, 0, 0, 0, theC, theT);
		} else if (strstr (method,"Plane")) {
			if (theZ < 0 || theC < 0 || theT < 0) {
				freePixelsRep (thePixels);
				HTTP_DoError (method,"Parameters theZ, theC and theT must be specified to do operations on planes." );
				return (-1);
			}
			nPix = head->dx*head->dy;
			offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
		}

		if (rorw == 'w')
			thePixels->IO_stream = openInputFile(filename,isLocalFile);
		else {
			thePixels->IO_stream = stdout;
			HTTP_ResultType ("application/octet-stream");
		}

		/*
		  Since we're going to stream to/from stdout/stdin at this point,
		  we can't report an error in a sensible way, so don't bother checking.
		  Its up to the client to figure out if the right number of pixels were read/written.
		*/
		nIO = DoPixelIO (thePixels, offset, nPix, rorw);
		if (rorw == 'w') {
            closeInputFile(thePixels->IO_stream,isLocalFile);
			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%ld\n", (long) nIO);
		}

		freePixelsRep (thePixels);
	}

	else if (m_val == M_SETROI || m_val == M_GETROI) {
		char *ROI;
		int x0,y0,z0,c0,t0,x1,y1,z1,c1,t1;
        char *filename=NULL;

		if (!ID) return (-1);
		if (m_val == M_SETROI) {
            rorw = 'w';
            if (!(filename = get_param(param,"Pixels"))) {
                HTTP_DoError(method,"No pixels filename specified");
            }
		} else rorw = 'r';

		if (m_val == M_SETROI || m_val == M_GETROI) {
			HTTP_DoError (method,"ROI Parameter missing");
			return (-1);
		}
		numInts = sscanf (ROI,"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",&x0,&y0,&z0,&c0,&t0,&x1,&y1,&z1,&c1,&t1);
		if (numInts < 10) {
			HTTP_DoError (method,"ROI improperly formed.  Expected x0,y0,z0,c0,t0,x1,y1,z1,c1,t1");
			return (-1);
		}

		if (! (thePixels = GetPixelsRep (ID,rorw,iam_BigEndian)) ) {
			if (errno) HTTP_DoError (method,strerror( errno ) );
			else  HTTP_DoError (method,"Access control error - check error log for details" );
			return (-1);
		}

		if (rorw == 'w')
			thePixels->IO_stream = openInputFile(filename,isLocalFile);
		else {
			thePixels->IO_stream = stdout;
			HTTP_ResultType ("application/octet-stream");
		}
		nIO = DoROI (thePixels,x0,y0,z0,c0,t0,x1,y1,z1,c1,t1, rorw);
		if (rorw == 'w') {
            closeInputFile(thePixels->IO_stream,isLocalFile);
			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%ld\n", (long) nIO);
		}
		freePixelsRep (thePixels);
	}

	
	
	return (1);
}

static
void usage (int argc,char **argv) {
	fprintf (stderr,"Bad usage.  Missing parameters.\n");
}

int main (int argc,char **argv) {
char isCGI=0;
char **in_params;

	if (chdir (OMEIS_ROOT)) {
		char error[256];
		sprintf (error,"Could not change working directory to %s",OMEIS_ROOT);
		perror (error);
		exit (-1);
	}
	in_params = getCLIvars(argc,argv) ;
	if( !in_params ) {
		in_params = getcgivars() ;
		if( !in_params ) {
			usage(argc,argv) ;
			exit (-1) ;
		} else	isCGI = 1 ;
	} else	isCGI = 0 ;

	if (dispatch (in_params))
		return (0);
	else
		exit (-1);
}


/**********************************
 CGI/CLI handling section below
 Most of this was cribbed from a web page, whose URL is now lost.
**********************************/

static
int inList(char **cgivars, char *str)
{
	register int k = 0;
	int returnVal = 0;
	
	for(k=0; cgivars[k]; k += 2){
		
		if( strstr(cgivars[k],str) ){
			returnVal = 1;
			break;
		}
	}
	
	return( returnVal );
}


char *get_param (char **cgivars, char *param)
{
	register int k = 0;
	char *returnVal = 0;

	for(k=0; cgivars[k]; k += 2){
		
		if( !strcmp(cgivars[k],param) ){
			returnVal = cgivars[k+1];
			break;
		}
	}
	
	return returnVal;
}


char *get_lc_param (char **cgivars, char *param)
{
	register int k = 0;
	char *returnVal = 0;

	for(k=0; cgivars[k]; k += 2){
		
		if( !strcmp(cgivars[k],param) ){
			returnVal = cgivars[k+1];
			while (*returnVal) {
				*returnVal = tolower (*returnVal);
				returnVal++;
			}
			returnVal = cgivars[k+1];
			break;
		}
	}
	
	return returnVal;
}

/** Convert a two-char hex string into the char it represents **/
static
char x2c(char *what)
{
   register char digit;

   digit = (what[0] >= 'A' ? ((what[0] & 0xdf) - 'A')+10 : (what[0] - '0'));
   digit *= 16;
   digit += (what[1] >= 'A' ? ((what[1] & 0xdf) - 'A')+10 : (what[1] - '0'));
   return(digit);
}


/** Reduce any %xx escape sequences to the characters they represent **/
static
void unescape_url(char *url)
{
	register int i,j;

	for(i=0,j=0; url[j]; ++i,++j){
		
		if( (url[i] = url[j]) == '%' ){
			url[i] = x2c(&url[j+1]);
			j+= 2;
		}
	}
	
	url[i] = '\0';
}


/** Read the CGI input and place all name/val pairs into list.		  **/
/** Returns list containing name1, value1, name2, value2, ... , NULL  **/
static
char **getcgivars(void)
{
	register int i;
	char *request_method;
	size_t content_length;
	char cgiinput[4096];
	char **cgivars;
	char **pairlist;
	int paircount;
	char *nvpair;
	char *eqpos;
	char url_encoded=1;

	request_method = getenv("REQUEST_METHOD");
	if (!request_method) return (0);
	
	if( !strcmp(request_method, "GET") || !strcmp(request_method, "HEAD") ){
		strncpy (cgiinput,getenv("QUERY_STRING"),4095);
	} else if (!strcmp(request_method, "POST")) {
		strncpy (cgiinput,getenv("QUERY_STRING"),4095);
		if( !(content_length = atoi(getenv("CONTENT_LENGTH")))  ){
			fprintf(stderr,"getcgivars(): No Content-Length was sent with the POST request.\n");
			exit(1);
		}
		if(! strcmp(getenv("CONTENT_TYPE"), "application/x-www-form-urlencoded")){
			if( content_length > 4095 ){
				fprintf(stderr,"getcgivars(): Could not malloc for cgiinput.\n");
				exit(1);
			}
			if( !fread(cgiinput, content_length, 1, stdin)){
				fprintf(stderr,"Couldn't read CGI input from STDIN.\n");
				exit(1);
			}
			cgiinput[content_length]='\0';
		} else if( strstr(getenv("CONTENT_TYPE"), "multipart/form-data")){
			char boundary[256],*charp,*charp2,done=0;
			char chunk[256],eol[3],tmp[256];
			unsigned long form_pos = 0;
			
			url_encoded = 0;
			fgets (boundary, 255 , stdin );
			form_pos += strlen (boundary);
			strcpy (eol,boundary+strlen(boundary)-2);			

			while (!feof(stdin) && !done) {
				fgets (chunk, 255 , stdin );
				form_pos += strlen (chunk);
				if (! strncmp (chunk,"Content-Disposition",19) ) {
					if (strstr (chunk,"form-data")) {
						if ( (charp = strstr (chunk,"name=\"")) ) {
							if (cgiinput[0]) strcat (cgiinput,"&");
							charp += 6;
							charp2 = tmp;
							while ( *charp != '"' && *charp != '\0') *charp2++ = *charp++;
							*charp2 = '\0';
							if (strlen(cgiinput)+strlen(tmp) < 4095)
								strcat (cgiinput,tmp);
							else {
								fprintf(stderr,"getcgivars(): Form input too long\n");
								exit(1);
							}
							if ( !strcmp (tmp,"Pixels") || !strcmp (tmp,"File") ) {
								if ( (charp = strstr (chunk,"filename=\"")) ) {
									strcat (cgiinput,"=");
									charp += 10;
									charp2 = tmp;
									while ( *charp != '"' && *charp != '\0') *charp2++ = *charp++;
									*charp2 = '\0';
									if (strlen(cgiinput)+strlen(tmp) < 4095)
										strcat (cgiinput,tmp);
									else {
										fprintf(stderr,"getcgivars(): Form input too long\n");
										exit(1);
									}
								}
								done = 1;
								while (strcmp (chunk,eol)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
								}
								
								sprintf (tmp,"&UploadSize=%ld",content_length-form_pos-strlen (boundary)-4);
								if (strlen(cgiinput)+strlen(tmp) < 4095)
									strcat (cgiinput,tmp);
								else {
									fprintf(stderr,"getcgivars(): Form input too long\n");
									exit(1);
								}
							} else if (!done) {
								while (!feof(stdin) && strcmp (boundary,chunk) && strcmp (chunk,eol)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
								}
								if (!strcmp (chunk,eol) && !feof(stdin)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
									if (strlen(cgiinput)+strlen(chunk) < 4094)
										strcat (cgiinput,"=");
										strcat (cgiinput,chunk);
									} else {
										fprintf(stderr,"getcgivars(): Form input too long\n");
										exit(1);
									}
									if ( (charp = strstr (cgiinput,eol)) ) *charp = '\0';
								}
							}
						}
					}
				}
			/*
				if (written+chunk_size > content_length) chunk_size = content_length-written;
				fread(chunk, chunk_size, 1, stdin);
				fwrite (chunk , chunk_size , 1 , stderr );
				written += chunk_size;
			*/
			}
		else {
			fprintf(stderr,"getcgivars(): Unsupported Content-Type: %s\n",getenv("CONTENT_TYPE"));
			exit(1);
		}
	}
	
	else{
		fprintf(stderr,"getcgivars(): unsupported REQUEST_METHOD\n");
		exit(1);
	}

	/** Change all plusses back to spaces **/
	if(url_encoded) {
		for(i=0; cgiinput[i]; i++){
			 if( cgiinput[i] == '+'){
				 cgiinput[i] = ' ';
			 }
		}
	}
	
	/** First, split on "&" to extract the name-value pairs into pairlist **/
	
	pairlist = (char **) malloc(256*sizeof(char **));
	paircount = 0;
	nvpair = strtok(cgiinput,"&");
	
	while (nvpair){
		pairlist[paircount++] = strcpy ((malloc(sizeof(char *) * (strlen(nvpair) + 1))), nvpair);
		
		if( !(paircount%256) ){
			pairlist = (char **) realloc(pairlist,(paircount+256)*sizeof(char **));
		}
		nvpair = strtok(NULL,"&");
	}
	
	pairlist[paircount] = 0;	/* terminate the list with NULL */

	/** Then, from the list of pairs, extract the names and values **/
	
	cgivars = (char **) malloc((paircount*2+1)*sizeof(char **));
	
	for(i=0; i<paircount; i++){
		
		if( (eqpos = strchr(pairlist[i],'=')) ){
			*eqpos = '\0';
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen(eqpos + 1) + 1)), eqpos + 1);
		}else{
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen("") + 1)), "");
		}
		cgivars[i*2] = strcpy(malloc(sizeof(char *) * strlen(pairlist[i] + 1)), pairlist[i]);

		if(url_encoded) {
			unescape_url(cgivars[i*2]);
			unescape_url(cgivars[i*2+1]);
		}
	}
	
	cgivars[paircount*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Free anything that needs to be freed **/
	
	
	for(i=0; pairlist[i]; i++){
		 free(pairlist[i]);
	}
	
	free(pairlist);

	/** Return the list of name-value strings **/
	
	return cgivars ;
}

/** Read the CLI input and place all name/val pairs into list.		  **/
/** Returns list containing name1, value1, name2, value2, ... , NULL  **/
static
char **getCLIvars(int argc, char **argv)
{
	register int i;
	char **cgivars;
	char *eqpos;

	if (argc < 2) return (NULL);
	/** Then, from the list of pairs, extract the names and values **/
	
	cgivars = (char **) malloc((argc*2+1)*sizeof(char **));
	
	for(i=0; i<argc; i++){
		
		if( (eqpos = strchr(argv[i],'=')) ){
			*eqpos = '\0';
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen(eqpos + 1) + 1)), eqpos + 1);
		}else{
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen("") + 1)), "");
		}
		
		cgivars[i*2] = strcpy(malloc(sizeof(char *) * (strlen(argv[i]) + 1)), argv[i]);
	}
	
	cgivars[argc*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Return the list of name-value strings **/
	
	return cgivars ;
}
