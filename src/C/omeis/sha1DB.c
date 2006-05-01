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
#include "OMEIS_Error.h"

/*
  Sometimes DB writes fail for no particular reason.
  For example, 2 failures in 64,000 NewPixels/FinishPixels calls
  from 64 processes on a 4-core box.  Of course, just retrying the DB call
  doesn't help - all retries fail.  Must actually close and reopen the DB.
  In testing, the second try has always worked.
*/
#define MAX_TRIES 25

/*
* internal prototypes
*/
DB *sha1DB_open (const char *file, char rorw);
int sha1DB_close (DB *myDB);



DB *sha1DB_open (const char *file, char rorw) {
DB *myDB;
int fd, fdDB;
int retVal;
struct flock fl;

	/* Set up the lock structure */
	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_whence = SEEK_SET;
	if (rorw == 'r') fl.l_type = F_RDLCK;
	else if (rorw == 'w')  fl.l_type = F_WRLCK;

	/*
	  This will either create and open a non-existant file in an atomic transaction
	  or fail to return a valid fd.
	*/
	fd = open (file,O_CREAT | O_RDWR | O_EXCL, 0600);
	if (fd > -1) {
	/* we just made a new DB */
		fcntl(fd, F_SETLKW, &fl);
	} else {
	/* everybody else ends up here */
		fd = open (file,O_RDWR, 0600);
		fcntl(fd, F_SETLKW, &fl);
	}
	myDB = dbopen (file,O_RDWR, 0600, DB_BTREE, NULL);

	if (!myDB) {
		return (NULL);
	}

	/* Block until we get the lock */
	fdDB = (myDB->fd) (myDB);
	fcntl(fdDB, F_SETLKW, &fl);
	
	close (fd);

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

	err = (myDB->sync)(myDB,0);
	err = (myDB->close)(myDB);
	return (err);
}

OID sha1DB_get (const char *file, void *md_value) {
DBT key, value;
OID theOID=0;
DB *myDB;

	
	myDB = sha1DB_open (file,'r');
	if (!myDB) return (0);

	memset(&key, 0, sizeof(key));
	memset(&value, 0, sizeof(value));
	key.size = OME_DIGEST_LENGTH;
	key.data = md_value;
	if ( ((myDB->get)(myDB, &key, &value, 0)) == 0)
		theOID = *((OID *)(value.data));
	else
		theOID = 0;

	sha1DB_close (myDB);

	return (theOID);
}

/*
  Returns 1 if duplicate
*/
int sha1DB_put (const char *file, void *md_value, OID theOID) {
DBT key, value;
int retVal=-1,tries=MAX_TRIES;
DB *myDB;
OID oldOID=0;
	
	
	

	/* Set up what we're writing */
	memset(&key, 0, sizeof(DBT));
	memset(&value, 0, sizeof(DBT));
	key.size = OME_DIGEST_LENGTH;
	key.data = md_value;
	value.size = sizeof (OID);
	value.data = (void *) &theOID;

	while (tries && (retVal < 0)) {
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;
		
		// Set the key/value in the DB
		retVal = (myDB->put)(myDB, &key, &value, R_NOOVERWRITE);
		sha1DB_close (myDB);
		tries--;
		if (retVal < 0) OMEIS_DoError ("Tring sha1DB_put again, tries=%d",tries);
	}

	return (retVal);
}



/*
  Returns 1 if duplicate
*/
int sha1DB_update (const char *file, void *md_value, OID theOID) {
DBT key, value;
int retVal=-1,tries=MAX_TRIES;
DB *myDB;
OID oldOID=0;
	

	/* Set up what we're writing */
	memset(&key, 0, sizeof(key));
	memset(&value, 0, sizeof(value));
	key.size = OME_DIGEST_LENGTH;
	key.data = md_value;
	value.size = sizeof (OID);
	value.data = (void *) &theOID;
	
	while (tries && (retVal < 0)) {
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;
		// Delete the key
		retVal = (myDB->del)(myDB, &key, 0);
		// Set the key/value
		retVal = (myDB->put)(myDB, &key, &value, R_NOOVERWRITE);
		sha1DB_close (myDB);
		tries--;
		if (retVal < 0) OMEIS_DoError ("Tring sha1DB_update again, tries=%d",tries);
	}

	return (retVal);
}

int sha1DB_del (const char *file, void *md_value) {
DB *myDB;
DBT key;
int retVal=-1,tries=MAX_TRIES;


	memset(&key, 0, sizeof(key));
	key.size = OME_DIGEST_LENGTH;
	key.data = md_value;

	while (tries && (retVal < 0)) {
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;

		retVal = (myDB->del)(myDB, &key, 0);
		sha1DB_close (myDB);
		tries--;
		if (retVal < 0) OMEIS_DoError ("Tring sha1DB_del again, tries=%d",tries);
	}

	return (retVal);
}


