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

/*
  This is some place-holder code for a B-Tree implementation to do reverse lookups
  SHA1 -> File/PixelsID
  
  Don't mind the noise with the parameters - this is just to avoid unused parameter warnings.
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
char foo = *file;
	return (1);
}

int sha1DB_close (DB *myDB) {
	myDB = 0;
	return (0);
}

OID sha1DB_get (DB *myDB, unsigned char *md_value) {
char foo = *md_value;
	return (0);
}


int sha1DB_put (DB *myDB, unsigned char *md_value, OID theOID) {
char foo = *md_value;
char OID = 0;
	myDB = 0;

	return (0);
}


