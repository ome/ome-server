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

#include <errno.h>

#include "sha1DB.h"
#include "OMEIS_Error.h"

/*
  Sometimes DB access fails for no particular reason (read and write).
  For example, 2 failures in 64,000 NewPixels/FinishPixels calls
  from 64 processes on a 4-core box.  Of course, just retrying the DB call
  doesn't help - all retries fail.  Must actually close and reopen the DB.
  In testing, the second try has always worked.
  
  Subsequent changes (5/06 by IGG) to this code were to use a separate lock file instead of
  using the DB file as the lock file, or allowing Berkeley DB to manage all locking.
  This was necessary as certain versions of Berkeley DB were still not operating
  well during concurrent access.
  The use of a separate lock file made a big difference in the stability during
  concurrent access.  It is not known as of this writing if the multiple tries
  is still necessary on any platforms or Berkely DB versions.
*/
#define MAX_TRIES 25

/*
* internal prototypes
*/
DB *sha1DB_open (const char *file, char rorw);
int sha1DB_close (DB *myDB);
DB *sha1DB_init (const char *file, int db_flags);
int sha1DB_lock (const char *file, char rorw);
int sha1DB_unlock (int fd);



DB *sha1DB_init (const char *file, int db_flags) {
int err, fd;
DB *myDB;

/*
  After waiting for the lock set by the external API call,
  the DB is either ready or we need a new one
*/
	myDB = dbopen (file,O_EXCL | O_CREAT | O_RDWR, 0600, DB_BTREE, NULL);

/*
  If this failed, it means another process has made the DB, so we open it the normal way
*/
	if (!myDB) {
		myDB = dbopen (file, db_flags, 0600, DB_BTREE, NULL);
	} else {
/* We just made the DB */
		sha1DB_close (myDB);
		myDB = dbopen (file,db_flags, 0600, DB_BTREE, NULL);
	}
	
	if (!myDB) OMEIS_DoError ("sha1DB_init FAILED");
	return (myDB);
}




int sha1DB_lock (const char *file, char rorw) {
char lock_file[OMEIS_PATH_SIZE];
struct flock fl;
int fd;

	/* Set up the lock structure */
	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_whence = SEEK_SET;
	if (rorw == 'r') {
		fl.l_type = F_RDLCK;
	} else if (rorw == 'w') {
		fl.l_type = F_WRLCK;
	}
	sprintf (lock_file,"%s-lock",file);
	fd = open (lock_file,O_CREAT | O_RDWR, 0600);
	if (fd < 0) return (fd);

	/* Block until we get the lock */
	fcntl(fd, F_SETLKW, &fl);

	return (fd);
}

int sha1DB_unlock (int fd) {
struct flock fl;

	/* Set up the lock structure */
	fl.l_start = 0;
	fl.l_len = 0;
	fl.l_pid = 0;
	fl.l_whence = SEEK_SET;
	fl.l_type = F_UNLCK;

	if (fd < 0) return (fd);

	/* release the lock */
	fcntl(fd, F_SETLKW, &fl);
	close (fd);

	return (0);
}



DB *sha1DB_open (const char *file, char rorw) {
DB *myDB;
int retVal,db_flags;
int fd_lck;


	if (rorw == 'r') {
		db_flags = O_RDONLY;
	} else if (rorw == 'w') {
		db_flags = O_RDWR;
	}
	/*
	  This will either create and open a non-existant file in an atomic transaction
	  or fail to return a valid fd.
	*/
	myDB = dbopen (file,db_flags, 0600, DB_BTREE, NULL);
	if (!myDB) {
		myDB = sha1DB_init (file,db_flags);
		if (!myDB) return (NULL);
	}
	
	return (myDB);
}


int sha1DB_close (DB *myDB) {
int err;
struct flock fl;
char lock_file[OMEIS_PATH_SIZE];

	if (!myDB) return (-1);
	err = (myDB->sync)(myDB,0);
	err = (myDB->close)(myDB);

	return (err);
}

OID sha1DB_get (const char *file, void *md_value) {
DBT key, value;
OID theOID=0;
DB *myDB;
int retVal=-1,tries=MAX_TRIES;
int fd_lck;


	fd_lck = sha1DB_lock (file,'r');

	while (tries && (retVal < 0)) {
		memset(&key, 0, sizeof(key));
		memset(&value, 0, sizeof(value));
		key.size = OME_DIGEST_LENGTH;
		key.data = md_value;
		tries--;
		myDB = sha1DB_open (file,'r');
		if (!myDB) continue;

		retVal = (myDB->get)(myDB, &key, &value, 0);
		if (retVal == 0)
			theOID = *((OID *)(value.data));
		else {
			theOID = 0;
		}
		sha1DB_close (myDB);
	}
	
	if (retVal != 0) OMEIS_DoError ("sha1DB_get failed after %d tries",MAX_TRIES);

	sha1DB_unlock (fd_lck);
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
int fd_lck;

	fd_lck = sha1DB_lock (file,'w');

	while (tries && (retVal < 0)) {
		/* Set up what we're writing */
		memset(&key, 0, sizeof(DBT));
		memset(&value, 0, sizeof(DBT));
		key.size = OME_DIGEST_LENGTH;
		key.data = md_value;
		value.size = sizeof (OID);
		value.data = (void *) &theOID;

		tries--;
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;
		
		// Set the key/value in the DB
		retVal = (myDB->put)(myDB, &key, &value, R_NOOVERWRITE);
		sha1DB_close (myDB);
	}

	if (retVal != 0) OMEIS_DoError ("sha1DB_put failed after %d tries",MAX_TRIES);

	sha1DB_unlock (fd_lck);
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
int fd_lck;


	fd_lck = sha1DB_lock (file,'w');
	
	while (tries && (retVal < 0)) {
		/* Set up what we're writing */
		memset(&key, 0, sizeof(key));
		memset(&value, 0, sizeof(value));
		key.size = OME_DIGEST_LENGTH;
		key.data = md_value;
		value.size = sizeof (OID);
		value.data = (void *) &theOID;

		tries--;
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;
		// Delete the key
		retVal = (myDB->del)(myDB, &key, 0);
		// Set the key/value
		retVal = (myDB->put)(myDB, &key, &value, R_NOOVERWRITE);
		sha1DB_close (myDB);
	}

	if (retVal != 0) OMEIS_DoError ("sha1DB_update failed after %d tries",MAX_TRIES);

	sha1DB_unlock (fd_lck);
	return (retVal);
}

int sha1DB_del (const char *file, void *md_value) {
DB *myDB;
DBT key;
int retVal=-1,tries=MAX_TRIES;
int fd_lck;


	fd_lck = sha1DB_lock (file,'w');

	while (tries && (retVal < 0)) {
		memset(&key, 0, sizeof(key));
		key.size = OME_DIGEST_LENGTH;
		key.data = md_value;

		tries--;
		myDB = sha1DB_open (file,'w');
		if (!myDB) continue;

		retVal = (myDB->del)(myDB, &key, 0);
		sha1DB_close (myDB);
	}

	if (retVal != 0) OMEIS_DoError ("sha1DB_update failed after %d tries",MAX_TRIES);

	sha1DB_unlock (fd_lck);
	return (retVal);
}


