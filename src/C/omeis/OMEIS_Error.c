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
 * Written by:	Ilya Goldberg <igg@nih.gov> 7/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <string.h> 
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>

#include "OMEIS_Error.h"


/* Defining instance of our error_string */
static char OMEIS_ERROR_STR [OMEIS_ERROR_SIZE];

char *
OMEIS_GetError () {
	return (OMEIS_ERROR_STR);
}

void
OMEIS_ClearError () {
	memset(OMEIS_ERROR_STR, 0, OMEIS_ERROR_SIZE);
}

int
OMEIS_CheckError () {
	if (*OMEIS_ERROR_STR == '\0') return (0);
	else return (1);
}


void
OMEIS_ReportError (char *method, char *ID_label, unsigned long long ID, const char *template, ...) {
va_list ap;
/*
403 Forbidden Authorization failure
500 Server Error 
*/
	if (getenv("REQUEST_METHOD")) {
		fprintf (stdout,"Status: 500 %s\r\n","Server Error");
		fprintf (stdout,"Content-Type: text/plain\r\n\r\n");
		if (ID_label) {
			fprintf (stdout,"Error calling %s with %s=%llu: ", method, ID_label, ID);
			fprintf (stderr,"Error calling %s with %s=%llu: ", method, ID_label, ID);
		} else {
			fprintf (stdout,"Error calling %s: ", method);
			fprintf (stderr,"Error calling %s: ", method);
		}
		if (strlen (template)) {
			va_start (ap, template);
			vfprintf (stdout, template, ap);
			va_end (ap);
			va_start (ap, template);
			vfprintf (stderr, template, ap);
			va_end (ap);
			fprintf (stdout,"\n");
			fprintf (stderr,"\n");
		}
		if (errno) {
			fprintf (stdout,"System Error: %s\n", strerror (errno));
			fprintf (stderr,"System Error: %s\n", strerror (errno));
		}
		if (strlen (OMEIS_ERROR_STR)) {
			fprintf (stdout,"OMEIS Error: %s", OMEIS_ERROR_STR);
			fprintf (stderr,"OMEIS Error: %s", OMEIS_ERROR_STR);
		}
	} else {
		if (ID_label) {
			fprintf (stderr,"Error calling %s with %s=%llu: ", method, ID_label, ID);
		} else {
			fprintf (stderr,"Error calling %s: ", method);
		}
		if (strlen (template)) {
			va_start (ap, template);
			vfprintf (stderr, template, ap);
			va_end (ap);
			fprintf (stderr,"\n");
		}
		if (errno) {
			fprintf (stderr,"System Error: %s\n", strerror (errno));
		}
		if (strlen (OMEIS_ERROR_STR)) {
			fprintf (stderr,"OMEIS Error: %s", OMEIS_ERROR_STR);
		}
	}
}


void OMEIS_DoError (const char *template, ...) {
va_list ap;
size_t lngth= strlen (OMEIS_ERROR_STR);

/*
  This is kind of stupid because it always prints this file and line.
	snprintf (OMEIS_ERROR_STR+lngth,OMEIS_ERROR_SIZE-lngth-1,"Error in %s at line %d: ", __FILE__ , __LINE__);
	Either put it in a macro, or a #define, or just pass these into OMEIS_DoError every time.
	Leaving this out for now.
*/
	lngth= strlen (OMEIS_ERROR_STR);
	va_start (ap, template);
	vsnprintf (OMEIS_ERROR_STR + lngth, OMEIS_ERROR_SIZE-lngth-1, template, ap);
	va_end (ap);
	lngth = strlen (OMEIS_ERROR_STR);
	if (*(OMEIS_ERROR_STR+lngth-1) != '\n') {
		*(OMEIS_ERROR_STR+lngth) = '\n';
		*(OMEIS_ERROR_STR+lngth+1) = '\0';
	}
}
