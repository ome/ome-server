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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */

#ifndef repository_h
#define repository_h

#include <sys/types.h>
#include <stdio.h>
#include "digest.h"


/* -------- */
/* Typedefs */
/* -------- */

/* OID */
typedef u_int64_t OID;

/* -------- */
/* Defines */
/* -------- */
/*  This is the standard size of an IO buffer */
#define OMEIS_IO_BUF_SIZE 8192
#define OMEIS_PATH_SIZE    256

/* ------------------- */
/* External Prototypes */
/* ------------------- */

OID
nextID (char *idFile);

OID
lastID (char *idFile);

char *
getRepPath (OID theID, char *path, char makePath);

int
lockRepFile (int fd, char lock, size_t from, size_t length);

int
newRepFile (OID theID, char *path, size_t size, char *suffix);

int
openRepFile (const char *filename, int flags);

FILE *
openInputFile(char *filename, unsigned char isLocalFile);

void
closeInputFile(FILE *infile, unsigned char isLocalFile);

void
byteSwap (unsigned char * theBuf, size_t length, char bp);

int
bigEndian (void);

#endif /* repository_h */
