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
 * Written by:   
 * 
 *------------------------------------------------------------------------------
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>

typedef int * Scaled;

MODULE = Repacker		PACKAGE = Repacker		


# Takes in values read from a file written on a big or little endian
# system, and converts them so they may be written to a file on the
# local host system, no matter the endian-ness of the host.
# Will only handle values that are 1, 2, or 4 bytes long.
# Input:
#       Perl string
#       cnt of bytes in string
#	# bytes per value (must be 1, 2, or 4)
#       are source values little endian (1/0)
#       is the local host little endian (1/0)
# Output:
#	cnt of output bytes (0 signals error)
# Side Effects
#	Perl string converted, in place, to host endian-ness
# Detected errors
#	can't allocate 'cnt' bytes of memory
#	bytes per value not 1, 2, or 4

int
repack(s, cnt, bpp, src_is_little, host_is_little)
	SV *s
	int cnt
	int bpp
	int src_is_little
	int host_is_little
    PROTOTYPE: $$$$$
    CODE:
	STRLEN len;

	if ((bpp == 2) && (src_is_little != host_is_little)) {
		char *ptr = SvPV(s, len);
		char holder;
		char *maxBuf = ptr+cnt;

		while (ptr < maxBuf)
		{
			holder = *ptr++;
			*(ptr-1) = *ptr;
			*ptr++ = holder;
		}
  		len = cnt;
	} else if ((bpp == 4) && (src_is_little != host_is_little)) {
		unsigned long holder;
		long *longPtr = (long *)SvPV(s, len);
		long *maxLongBuf = longPtr+(cnt/bpp);
		
		while (longPtr < maxLongBuf)
		{
		holder = *longPtr;
		*longPtr++ =  ((holder >> 24) & 0x000000FF) | 
			((holder >> 8)  & 0x0000FF00) |
			((holder << 8)  & 0x00FF0000) |
			((holder << 24) & 0xFF000000);
  		}
  		len = cnt;
	} else if ( (bpp == 1) || (bpp == 2) || (bpp == 4) ) {
		len = cnt;
	} else {
		len = 0;
	}
	RETVAL = len;
    OUTPUT:
	RETVAL







# Inverts, in place, the contents of the passed buffer. Used to reverse
# the order of white to black in an image. That which was white on input
# becomes black on output, etc..
# Input:
#       Perl string (buffer)
#       cnt of bytes in string
#	# bytes per value
# Output:
#	# pixels inverted
# Side Effects
#	Input buffer bit-wise inverted, in place
# Detected errors
#	none

int
invert(s, cnt, bpp)
	SV *s
	int cnt
	int bpp
    PROTOTYPE: $$$
    CODE:
	STRLEN len;

	unsigned char *ptr = SvPV(s, cnt);
	unsigned char *maxBuf = ptr+cnt;

	while (ptr < maxBuf)
	{
		*ptr = ~*ptr;
		ptr++;
	}
	len = cnt/bpp;
	RETVAL = len;
    OUTPUT:
	RETVAL




# Scales the input values, returning the scaled values. Algorithm is:
# each input value is 1st squared, and then multiplied by a passed constant.
# Input:
#       Perl string (buffer)
#       cnt of bytes in string
#	# bytes per value
#	this image's scaling constant
# Output:
#	New buffer containing scaled values
# Side Effects
#	The output buffer is released to Perl's runtime for garbage collection
# Detected errors
#	failure to allocate memory

Scaled
gel_scaler(s, cnt, bpp, scale)
	SV *s
	int cnt
	int bpp
	double scale
    PROTOTYPE: $$$$
    CODE:
	int    len;
	int   *newbp;
	int    itmp;
	double ftmp;
	short  stmp;

	unsigned short *ptr = (unsigned short*)SvPV(s, len);
	unsigned short *maxBuf = ptr+(cnt/bpp);
	Newz(0, newbp, cnt, int);
	RETVAL = newbp;

	if (newbp) {
		while (ptr < maxBuf)
		{
	                stmp= *ptr++;
			itmp = stmp * stmp;
	        	ftmp = itmp * scale;
			*newbp++ = ftmp;
		}
		/*
		 * These 2 calls set the stack's 1st value to point to
		 * the memory just allocated by Newz(), and mark it
		 * to be given to Perl to use & then garbage collect.
		*/
		ST(0) = sv_newmortal();
		sv_usepvn (ST(0), (char *)RETVAL, 2*cnt);
	}
	else {
		/* memory alloc failed, return 'undef' */
		ST(0) = &PL_sv_undef;
	}


