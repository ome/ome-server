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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */

#ifndef cgi_h
#define cgi_h

/* ------------------- */
/* External Prototypes */
/* ------------------- */
char **
getcgivars(void);

char **
getCLIvars(int argc, char **argv);

char *
get_param (char **cgivars, char *param);

char *
get_lc_param (char **cgivars, char *param);

void
HTTP_DoError (char *method, const char *template, ...)
	__attribute__ ((format (printf, 2, 3)));

void
HTTP_ResultType (char *mimeType);

#endif /* cgi_h */
