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

/* ----------- */
/* Definitions */
/* ----------- */

#define OME_IS_FILE_SIG 0x46494C45 /* FILE in ASCII */
#define OME_IS_FILE_VER 2
/* Version log:
  1 -> 2 (igg@nih.gov):
  	Added mySig, vers, isAlias and nAliases to FileInfo.
  	N.B.:  Version 1 infos are detected by virtue of their fixed known size:
  		OME_DIGEST_LENGTH + OMEIS_PATH_SIZE.
*/


/* -------- */
/* Typedefs */
/* -------- */

typedef struct {
	u_int32_t mySig;
	u_int8_t vers;
	OID ID;
	char sha1[OME_DIGEST_LENGTH];
	char name[OMEIS_PATH_SIZE];
	OID isAlias;
	u_int32_t nAliases;
} FileInfo;

typedef struct {
	OID ID;
	char name[OMEIS_PATH_SIZE];
} FileAlias;

typedef struct {
	OID ID;
	char path_ID[OMEIS_PATH_SIZE];
	char path_rep[OMEIS_PATH_SIZE];
	char path_info[OMEIS_PATH_SIZE];
	char path_DB[OMEIS_PATH_SIZE];
	int  fd_rep;
	int  fd_info;
	DB *DB;
	size_t size_rep;
	size_t size_info;
    size_t size_buf;
	char is_mmapped;
	FileInfo file_info;
	FileAlias *aliases;
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

int
ExpungeFile (FileRep *myFile);

FileRep *
NewFile (char *filename, size_t size);

OID
FinishFile (FileRep *myFile);

int
GetFileInfo (FileRep *myFile);

int
GetFileAliases (FileRep *myFile);

OID
UploadFile (char *filename, size_t size, unsigned char isLocalFile);

void
freeFileRep (FileRep *myFile);


#endif /* File_h */
