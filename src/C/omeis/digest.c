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
 * Written by:	Chris Allan <callan@blackcat.ca>   01/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <openssl/evp.h>
#include <errno.h>

#include "digest.h"
#include "OMEIS_Error.h"

int
get_md_from_file (char * filename, unsigned char * md_value)
{
	int fd;

	/* Sanity check (FATAL) */
	assert(filename != NULL);
	assert(md_value != NULL);

	if ((fd = (open(filename, O_RDONLY))) == -1) {
		OMEIS_DoError ("Error opening %s: %s",filename,strerror(errno));
		return (-1);
	}

	if (get_md_from_fd (fd, md_value) < 0) {
		OMEIS_DoError ("Problem retrieving SHA1.");
		close(fd);
		return (-1);
	}

	close(fd);
	return(1);
}

int
get_md_from_buffer (void * buf, size_t buf_len, unsigned char * md_value)
{
	EVP_MD_CTX mdctx;  /* Message digest context */
	const EVP_MD *md;  /* Message digest */
	unsigned int md_len;

	/* Sanity check (FATAL) */
	assert(buf != NULL);
	assert(buf_len > 0);

	OpenSSL_add_all_digests();

	md = EVP_get_digestbyname(OME_DIGEST);
	
	if (!md) {
		OMEIS_DoError ("Failure during digest lookup for: '%s'", OME_DIGEST);
		return(-1);  /* Failure in namelookup */
	}
	
	EVP_DigestInit(&mdctx, md);
	
	EVP_DigestUpdate(&mdctx, buf, buf_len);

	EVP_DigestFinal(&mdctx, md_value, &md_len);

	return (1);  /* Success */
}



int
get_md_from_fd (int fd, unsigned char * md_value)
{
	EVP_MD_CTX mdctx;  /* Message digest context */
	const EVP_MD *md;  /* Message digest */
	ssize_t rlen;      /* Read length */
	unsigned char buf[MD_BUFSIZE];
	unsigned int md_len;

	/* Sanity check (FATAL) */
	assert(fd > 0);
	assert(md_value != NULL);

	OpenSSL_add_all_digests();

	md = EVP_get_digestbyname(OME_DIGEST);
	
	if (!md) {
		OMEIS_DoError ("Failure during digest lookup for: '%s'", OME_DIGEST);
		return(-1);  /* Failure in namelookup */
	}
	
	EVP_DigestInit(&mdctx, md);

	do {
		rlen = read(fd, buf, MD_BUFSIZE);
		EVP_DigestUpdate(&mdctx, buf, rlen);
	} while (rlen > 0);

	if (rlen < 0) {
		OMEIS_DoError ("Error reading from fd: %s",strerror(errno));
		return(-1);  /* Error reading from fd */
	}

	EVP_DigestFinal(&mdctx, md_value, &md_len);

	return (1);  /* Success */
}

void 
print_md (unsigned char * md_value)
{
	int i;

	/* Sanity check (FATAL) */
	assert(md_value != NULL);

	for (i = 0; i < OME_DIGEST_LENGTH; i++)
		printf("%02x", md_value[i]);
}

