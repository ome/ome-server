// acquired from http://www.episec.com/people/edelkind/c.html
#include "base64.h"
#include <string.h>

char b64string[] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

long base64_encode (char *to, char *from, unsigned int len)
{
	char *fromp = from;
	char *top = to;
	unsigned char cbyte;
	unsigned char obyte;
	char end[3];

	for (; len >= 3; len -= 3) {
		cbyte = *fromp++;
		*top++ = b64string[(int)(cbyte >> 2)];
		obyte = (cbyte << 4) & 0x30;		/* 0011 0000 */

		cbyte = *fromp++;
		obyte |= (cbyte >> 4);			/* 0000 1111 */
		*top++ = b64string[(int)obyte];
		obyte = (cbyte << 2) & 0x3C;		/* 0011 1100 */

		cbyte = *fromp++;
		obyte |= (cbyte >> 6);			/* 0000 0011 */
		*top++ = b64string[(int)obyte];
		*top++ = b64string[(int)(cbyte & 0x3F)];/* 0011 1111 */
	}

	if (len) {
		end[0] = *fromp++;
		if (--len) end[1] = *fromp++; else end[1] = 0;
		end[2] = 0;

		cbyte = end[0];
		*top++ = b64string[(int)(cbyte >> 2)];
		obyte = (cbyte << 4) & 0x30;		/* 0011 0000 */

		cbyte = end[1];
		obyte |= (cbyte >> 4);
		*top++ = b64string[(int)obyte];
		obyte = (cbyte << 2) & 0x3C;		/* 0011 1100 */

		if (len) *top++ = b64string[(int)obyte];
		else *top++ = '=';
		*top++ = '=';
	}
//	*top = 0;
	return top - to;
}
