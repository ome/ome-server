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
#ifndef OMEIS_Error_h
#define OMEIS_Error_h

#define OMEIS_ERROR_SIZE   4096

/* ------------------- */
/* External Prototypes */
/* ------------------- */
char *
OMEIS_GetError ();

void
OMEIS_ClearError ();

int
OMEIS_CheckError ();

void
OMEIS_ReportError (char *method, char *ID_label, unsigned long long ID, const char *template, ...)
	__attribute__ ((format (printf, 4, 5)));

void
OMEIS_DoError (const char *template, ...)
	__attribute__ ((format (printf, 1, 2)));


/* ------------------- */
/* Global Error string */
/* ------------------- */
/*
  N.B.: The file omeis.h must be included by the file that contains main()
  The file that contains main() must be the only one to include omeis.h
*/
extern char OMEIS_ERROR_STR [OMEIS_ERROR_SIZE];

#endif /* OMEIS_Error_h */
