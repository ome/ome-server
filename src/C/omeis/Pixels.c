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

#include "Pixels.h"
#include "File.h"


void DeletePixels (PixelsRep *myPixels);



/*
  PixelRep keeps track of everything having to do with pixel i/o to the repository.
*/
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
char *sha1DBfile="Pixels/sha1DB.idx";

	if (! (myPixels =  (PixelsRep *)malloc (sizeof (PixelsRep)))  )
		return (NULL);
	myPixels = memset(myPixels, 0, sizeof(PixelsRep));
	
	strcpy (myPixels->path_rep,root);
	strcpy (myPixels->path_info,root);
	strcpy (myPixels->path_ID,pixIDfile);
	strcpy (myPixels->path_DB,sha1DBfile);

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
		myPixels->ID = ID;
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

/*
  If this is a new pixels file, we don't know the dx, dy, dz, dc, dt at this point
*/
	if (rorw != 'n') {
		myPixels->planeInfos = (planeInfo *) ( mmap_info + sizeof(pixHeader));
		myPixels->stackInfos = (stackInfo *) ( mmap_info + (sizeof (planeInfo) * head->dz * head->dc * head->dt)  + sizeof(pixHeader) );
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
char error[256];
pixHeader *head;
PixelsRep *myPixels;
size_t size;
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
	
	/*
	  Since we called openPixelsFile with 'n', it didn't have the dx, dy, dz, etc,
	  so it did not assign where the infos are in relation to head.
	  So we must assign them here.
	*/
	myPixels->planeInfos = (planeInfo *) ( (char *)head + sizeof(pixHeader));
	myPixels->stackInfos = (stackInfo *) ( (char *)head + (sizeof (planeInfo) * dz * dc * dt)  + sizeof(pixHeader) );

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
		fprintf (stderr,"Could not open pixels file (ID=%llu). Result=%d\n",ID,result);
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
		fprintf (stderr,"Pix->CheckCoords:  Coordinates out of range.\n");
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
size_t off0, off1;

	if (!myPixels) return (0);
	if (! (pix = (char *)myPixels->pixels) ) return (0);
	if (! (head = myPixels->head) ) return (0);
	if ( ! CheckCoords (myPixels, x0, y0, z0, w0, t0) ) return (0);
	off0 = GetOffset (myPixels, x0, y0, z0, w0, t0);
	if ( !CheckCoords (myPixels, x1, y1, z1, w1, t1) ) return (0);
	off1 = GetOffset (myPixels, x1, y1, z1, w1, t1);
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
size_t file_off,plane_offset;

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
  are OK before doing it's job, so calling this will allways result in a new
  statistics calculation.
*/

static
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
size_t plane_offset,stack_offset;
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
	for (t = 0; t < dt; t++) {
		for (c = 0; c < dc; c++) {
			if (force) stackInfoP->stats_OK = 0;
			for (z = 0; z < dz; z++) {
				if (force) planeInfoP->stats_OK = 0;
				if (! planeInfoP->stats_OK)
					if (!DoPlaneStats (myPixels, z, c, t)) return (0);
				planeInfoP++;
			}
			if (!DoStackStats (myPixels, c, t)) return (0);
			stackInfoP++;
		}
	}
	return (1);
}


void DeletePixels (PixelsRep *myPixels) {
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

}

OID FinishPixels (PixelsRep *myPixels, char force) {
OID existOID;

	if (!myPixels) return (0);

	/* wait until we can get a write lock on the whole file */
	lockRepFile (myPixels->fd_rep,'w',0LL,0LL);
	
	/* Make sure all the stats are up to date */
	if (!FinishStats (myPixels,force)) return (0);

	/* Get the SHA1 message digest */
	if (get_md_from_fd (myPixels->fd_rep, myPixels->head->sha1) < 0) {
		fprintf(stderr, "Unable to retrieve SHA1.");
		return(0);
	}

	/* Open the DB file if necessary */
	if (! myPixels->DB)
		if (! (myPixels->DB = sha1DB_open (myPixels->path_DB)) ) {
			return(0);
		}

	/* Check if SHA1 exists */
	if ( (existOID = sha1DB_get (myPixels->DB, myPixels->head->sha1)) ) {
		sha1DB_close (myPixels->DB);
		myPixels->DB = NULL;
		DeletePixels (myPixels);
		return (existOID);
	}

	myPixels->head->isFinished = 1;

	if (myPixels->is_mmapped) {
		if (msync (myPixels->head , myPixels->size_info , MS_SYNC) != 0) return (0);

		if (msync (myPixels->pixels , myPixels->size_rep , MS_SYNC) != 0) return (0);
	}
	

	/* put the SHA1 in the DB */
	if ( sha1DB_put (myPixels->DB, myPixels->head->sha1, myPixels->ID) ) {
		sha1DB_close (myPixels->DB);
		myPixels->DB = NULL;
		return (0);
	}

	/* Close the DB (and release the exclusive lock) */
	sha1DB_close (myPixels->DB);
	myPixels->DB = NULL;

	fchmod (myPixels->fd_rep,0400);
	fchmod (myPixels->fd_info,0400);

	return (myPixels->ID);
}


size_t ConvertFile (PixelsRep *myPixels, OID fileID, size_t file_offset, size_t pix_offset, size_t nPix) {
pixHeader *head;
FileRep *myFile;
unsigned long nIO;
convertFileRec convFileRec;
FILE *convFileInfo;
char convFileInfoPth[MAXPATHLEN];
char isBigEndian=1,bp;

	if (!fileID || !myPixels) return (0);
	if (! (head = myPixels->head) ) {
		sprintf (myPixels->error_str,"ConvertFile(PixelsID=%llu). Pixels header is not set.",myPixels->ID);
		return (0);
	}
	bp = head->bp;

	if ( !(myFile = GetFileRep (fileID, file_offset, nPix*bp)) ) {
		sprintf (myPixels->error_str,"ConvertFile(PixelsID=%llu). Could not acess file ID=%llu",myPixels->ID,fileID);
		return (0);
	}

	if ( myFile->size_rep < file_offset + (nPix*bp)) {
		sprintf (myPixels->error_str,"ConvertFile(PixelsID=%llu). Attempt to read past end of file ID=%llu.  File size=%lu,  Offset=%lu, # pixels=%lu (%lu bytes)",
			myPixels->ID,(unsigned long long)fileID, (unsigned long)(myFile->size_rep), (unsigned long)file_offset,
			(unsigned long)nPix, (unsigned long)(nPix*bp));
		return (0);
	}

	myPixels->IO_buf = myFile->file_buf+file_offset;
	nIO = DoPixelIO (myPixels, pix_offset, nPix, 'w');
	if (nIO != nPix) {
		sprintf (myPixels->error_str,"ConvertFile(). Number of pixels converted (%lu) does not match number in request (%lu)",
			nIO, (unsigned long)nPix);
		freeFileRep (myFile);
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

	freeFileRep (myFile);
	return (nIO);
}


size_t ConvertTIFF (PixelsRep *myPixels, OID fileID, ome_coord theZ, ome_coord theC, ome_coord theT) {
pixHeader *head;
FileRep *myFile;
char file_path[MAXPATHLEN],bp;
unsigned long nIO=0, nOut;
size_t pix_offset;
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
	
	if (! (myFile = newFileRep (fileID))) {
		sprintf (myPixels->error_str,"ConvertTIFF (PixelsID=%llu). Could not acess file ID=%llu",myPixels->ID,fileID);
		return (0);
	}

	if (! (head = myPixels->head) ) {
		sprintf (myPixels->error_str,"ConvertTIFF (PixelsID=%llu). Pixels header is not set.",myPixels->ID);
		return (0);
	}

	bp = head->bp;

	if (!CheckCoords (myPixels, 0, 0, theZ, theC, theT)){
		sprintf (myPixels->error_str,"ConvertTIFF (PixelsID=%llu). Coordinates theZ=%d, theC=%d, theT=%d are out of range (%d,%d,%d)",
			myPixels->ID, theZ, theC, theT, head->dz, head->dc, head->dt);
		return (0);
	}

	pix_offset = GetOffset (myPixels, 0, 0, theZ, theC, theT);
	
    if (! (tiff = TIFFOpen(myFile->path_rep, "r")) ) {
		sprintf (myPixels->error_str,"ConvertTIFF (PixelsID=%llu). Couldn't open File ID=%llu as a TIFF file.",myPixels->ID,
			fileID);
    	return (0);
    }
    
	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);
	TIFFGetField(tiff, TIFFTAG_SAMPLESPERPIXEL, &chans);
	TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &bpp);
	TIFFGetField(tiff, TIFFTAG_PLANARCONFIG, &pc);

	bpp /= 8;

	if (width != (uint32)(head->dx) || height != (uint32)(head->dy) || chans > 1 || bpp != (uint16)(head->bp) ||
		pc != PLANARCONFIG_CONTIG ) {
			int nc=0;
			
			TIFFClose(tiff);
			nc += sprintf (myPixels->error_str+nc,"ConvertTIFF (PixelsID=%llu). TIFF (ID=%llu) <-> Pixels mismatch.\n",myPixels->ID,fileID);
			nc += sprintf (myPixels->error_str+nc,"\tWidth x Height:    Pixels (%d,%d) TIFF (%u,%u)\n",(int)head->dx,(int)head->dy,(unsigned)width,(unsigned)height);
			nc += sprintf (myPixels->error_str+nc,"\tSamples per pixel: Pixels (%d) TIFF (%d)\n",(int)1,(int)chans);
			nc += sprintf (myPixels->error_str+nc,"\tBytes per sample:  Pixels (%d) TIFF (%d)\n",(int)head->bp,(int)bpp);
			nc += sprintf (myPixels->error_str+nc,"\tPlanar Config:     Pixels (%d) TIFF (%d)\n",(int)PLANARCONFIG_CONTIG,(int)pc);
			return (0);
	}

	if (! (buf = _TIFFmalloc(TIFFStripSize(tiff))) ) {
		sprintf (myPixels->error_str,"ConvertTIFF (PixelsID=%llu):  Couldn't allocate %lu bytes for TIFF strip buffer.",myPixels->ID,TIFFStripSize(tiff));
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
	
	freeFileRep (myFile);

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
static
int GetArchive (PixelsRep myPixels, char *format) {
	return (0);
}
*/

