#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


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
	SV *s;
	int cnt
	int bpp
	int src_is_little
	int host_is_little
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
