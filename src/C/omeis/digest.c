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

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "digest.h"

int
get_md_from_file (char * filename, unsigned char * md_value)
{
	int fd;

	/* Sanity check (FATAL) */
	if (filename == NULL || md_value == NULL) {
		fprintf(stderr, "FATAL: NULL filename to get_md_from_file().\n");
		return(-255);
	}

	if ((fd = (open(filename, O_RDONLY))) == -1) {
		perror(filename);
		return (-1);
	}

	if (get_md_from_fd (fd, md_value) < 0) {
		fprintf(stderr, "Problem retrieving SHA1.\n");
		close(fd);

		return (-1);
	}

	close(fd);
	return(1);

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
	if (fd < 0 || md_value == NULL) {
		fprintf(stderr, "FATAL: NULL fd or md_vale to get_md_from_fd().\n");
		return(-255);
	}

	OpenSSL_add_all_digests();

	md = EVP_get_digestbyname(OME_DIGEST);
	
	if (!md) {
		fprintf(stderr, "Failure during digest lookup for: '%s'\n", OME_DIGEST);
		return(-1);  /* Failure in namelookup */
	}
	
	EVP_DigestInit(&mdctx, md);

	do {
		rlen = read(fd, buf, MD_BUFSIZE);
		EVP_DigestUpdate(&mdctx, buf, rlen);
	} while (rlen > 0);

	if (rlen < 0) {
		perror("fd_read");	
		return(-1);  /* Error reading from fd */
	}

	EVP_DigestFinal(&mdctx, md_value, &md_len);

	return (1);  /* Success */
}

void 
print_md (unsigned char *md_value)
{
	int i;

	for (i = 0; i < OME_DIGEST_LENGTH; i++)
		printf("%02x", md_value[i]);
}

