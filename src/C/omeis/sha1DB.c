/*
  Binary Insertion Sort
  
  Record        - the index file is made up of contiguous Records
  Record.digest - the digest of the Record  - DIGEST_LENGTH bytes
  Record.ID     - the ID of the Record      - ID_LENGTH bytes
  
  mmap
  nRecords
  
  insert         - wether to actually insert the Record.
    The mmap must have a zero record at int(nRecords/2) if insert is true.
    The mmap will have a zero record at int(nRecords/2) when it returns.
  
*/

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

/* O_EXLOCK is a BSD extension */
#ifdef __DARWIN__
	myDB = dbopen (file,O_CREAT|O_RDWR|O_EXLOCK, 0600, DB_BTREE, NULL);
#else
	myDB = dbopen (file,O_CREAT|O_RDWR, 0600, DB_BTREE, NULL);
#endif
	
	return (myDB);
}

int sha1DB_close (DB *myDB) {
int err;
	err = (myDB->close)(myDB);
	free (myDB);
	return (err);
}

OID sha1DB_get (DB *myDB, unsigned char *md_value) {
DBT key, value;
OID theOID;

	key.size = OME_DIGEST_LENGTH;
	key.data = (void *)md_value;
	value.size = sizeof (OID);
	value.data = (void *) &theOID;

	if ( ((myDB->get)(myDB, &key, &value, 0)) == 0)
		return (* ( (OID *)(value.data) ) );
	else
		return ((OID)0);
}


int sha1DB_put (DB *myDB, unsigned char *md_value, OID theOID) {
DBT key, value;

	key.size = OME_DIGEST_LENGTH;
	key.data = (void *)md_value;
	value.size = sizeof (OID);
	value.data = (void *) &theOID;

	return ((myDB->put)(myDB, &key, &value, R_NOOVERWRITE));
}


