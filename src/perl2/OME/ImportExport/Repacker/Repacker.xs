#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <byteswap.h>


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
	char *ptr, *newp;
	short int *ship, *shop;
	long int  *lnip, *lnop;
	int i, vals;
	short int sh;
	short int outsh;
	long int ln;
	long int outln;

	ptr = SvPV(s, len);
	if (!((bpp == 1) || (bpp == 2) || (bpp == 4))) {
	    len = 0;
	} else if ((src_is_little != host_is_little) && (bpp != 1)) {
	    newp = (char *)(calloc(1, len+1));
	    if (!newp) {
		len = 0;
            } else {
		vals = cnt/bpp;
		if (bpp == 2) {
		    ship = (short int *)ptr;
		    shop = (short int *)newp;
		    for (i = 0; i < vals; i++) {
			sh = *ship++;
			*shop++ = bswap_16(sh);
		    }
		} else {
		    lnip = (long int *)ptr;
		    lnop = (long int *)newp;
		    for (i = 0; i < vals; i++) {
			ln = *lnip++;
			*lnop++ = bswap_32(ln);
		    }
		}
	    }

	    sv_setpvn(s, newp, len);
	    free(newp);
	}
					
	RETVAL = len;
    OUTPUT:
	RETVAL


