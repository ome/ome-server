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
#include <string.h> 
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>


#include "repository.h"

/*
  This function will get a new unique ID by examining the contents of the
  passed-in counter file.  The number in the counterfile will be incremented,
  and written back to the file.  The incremented number is returned.  A return
  of 0 means an error has occured, and can be checked with errno.  A return of
  0 with a 0 errno means the counter has wrapped around.
*/
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

	if ((fd = open(idFile, O_CREAT|O_RDWR, 0660)) < 0) {
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
			if (mkdir(path, 0770) != 0)
				if (errno != EEXIST) /* Exist errors are OK, but return on anything else (files should get ENOTDIR) */
					return (NULL);
	}

	sprintf (pixIDstr,"%llu",theID);

	strcat (path,pixIDstr);
	
	return (path);
	
}


int lockRepFile (int fd, char lock, size_t from, size_t length) {
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
  int newRepFile (OID theID, char *path, size_t size, char *suffix)
  
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

int newRepFile (OID theID, char *path, size_t size, char *suffix) {
	int fd;
	unsigned char zero=0;

	if (! getRepPath (theID,path,1)) {
		return (-1);
	}
	
	if (suffix) {
		strcat (path,".");
		strcat (path,suffix);
	}

	if ( (fd = open (path, O_CREAT|O_EXCL|O_RDWR, 0660)) < 0) {
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
 * openInputFile(char *filename, unsigned char isLocalFile)
 * closeInputFile(FILE *infile, unsigned char isLocalFile)
 *
 * These functions allow the UploadFile and Set* methods to accept the
 * input data from a file in the local filesystem instead of from
 * STDIN.  This will only be useful if the image server is being called
 * via the command line (and not as a CGI script) from client code
 * running on the same machine.
 */
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

void closeInputFile(FILE *infile, unsigned char isLocalFile) {
    if (isLocalFile) {
        fclose(infile);
    }
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

