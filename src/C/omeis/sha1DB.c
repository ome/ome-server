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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   3/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <sys/types.h>
#include <limits.h>
#include <fcntl.h>
#include <sys/time.h>
#include <string.h> 
#include <stdlib.h> 

#include "sha1DB.h"


DB *sha1DB_open (const char *file) {
DB *myDB;
int fd;
struct flock fl;

	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_type = F_WRLCK;
	fl.l_whence = SEEK_SET;
	
	myDB = dbopen (file,O_CREAT|O_RDWR, 0600, DB_BTREE, NULL);
	if (!myDB) return (NULL);
	fd = (myDB->fd) (myDB);

	/* Block until we get a write-lock */
	fcntl(fd, F_SETLKW, &fl);
	return (myDB);
}

int sha1DB_close (DB *myDB) {
int err;
int fd;
struct flock fl;

	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_type = F_UNLCK;
	fl.l_whence = SEEK_SET;
	if (!myDB) return (-1);
	fd = (myDB->fd) (myDB);

	/* release the write-lock */
	fcntl(fd, F_SETLKW, &fl);
	err = (myDB->close)(myDB);
	return (err);
}

OID sha1DB_get (DB *myDB, unsigned char *md_value) {
DBT key, value;
OID theOID=0;

	memset(&key, 0, sizeof(key));
	memset(&value, 0, sizeof(value));
	key.size = OME_DIGEST_LENGTH;
	key.data = (void *)md_value;
	if ( ((myDB->get)(myDB, &key, &value, 0)) == 0)
		theOID = *((OID *)(value.data));
	else
		theOID = 0;

	return (theOID);
}


int sha1DB_put (DB *myDB, unsigned char *md_value, OID theOID) {
DBT key, value;

	memset(&key, 0, sizeof(key));
	memset(&value, 0, sizeof(value));
	key.size = OME_DIGEST_LENGTH;
	key.data = (void *)md_value;
	value.size = sizeof (OID);
	value.data = (void *) &theOID;

	return ((myDB->put)(myDB, &key, &value, R_NOOVERWRITE));
}

int sha1DB_del (DB *myDB, unsigned char *md_value) {
DBT key;

	memset(&key, 0, sizeof(key));
	key.size = OME_DIGEST_LENGTH;
	key.data = (void *)md_value;

	return ((myDB->del)(myDB, &key, 0));
}


