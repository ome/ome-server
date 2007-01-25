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

#ifndef digest_h
#define digest_h

#define OME_DIGEST "SHA1"
#define OME_DIGEST_LENGTH 20
#define MD_BUFSIZE 16384

int
get_md_from_file (char * filename, unsigned char * md_value);

int
get_md_from_fd (int fd, unsigned char * md_value);

int
get_md_from_buffer (void * buf, size_t buf_len, unsigned char * md_value);

void 
print_md (unsigned char *md_value);

void
convert_md (char* md_asci, u_int8_t* md_value);
#endif /* digest_h */
