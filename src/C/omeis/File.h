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

#ifndef File_h
#define File_h

#include "repository.h"
#include "sha1DB.h"


/* -------- */
/* Typedefs */
/* -------- */

typedef struct {
	char sha1[OME_DIGEST_LENGTH];
	char name[256];
} FileInfo;

typedef struct {
	OID ID;
	char path_ID[256];
	char path_rep[256];
	char path_info[256];
	char path_DB[256];
	int  fd_rep;
	int  fd_info;
	DB *DB;
	size_t size_rep;
	size_t size_info;
    size_t size_buf;
	char is_mmapped;
	FileInfo file_info;
	void *file_buf;
} FileRep;


/* ------------------- */
/* External Prototypes */
/* ------------------- */

FileRep *
newFileRep (OID ID);

FileRep *
GetFileRep (OID ID, size_t offset, size_t length);

int
DeleteFile (FileRep *myFile);

FileRep *
NewFile (char *filename, size_t size);

OID
FinishFile (FileRep *myFile);

int
GetFileInfo (FileRep *myFile);

OID
UploadFile (char *filename, size_t size, unsigned char isLocalFile);

void
freeFileRep (FileRep *myFile);


#endif /* File_h */
