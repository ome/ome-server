/* Copyright (C) 2003 Open Microscopy Environment
*  Author:  
* 
*     This library is free software; you can redistribute it and/or
*     modify it under the terms of the GNU Lesser General Public
*     License as published by the Free Software Foundation; either
*     version 2.1 of the License, or (at your option) any later version.
*
*     This library is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*     Lesser General Public License for more details.
*
*     You should have received a copy of the GNU Lesser General Public
*     License along with this library; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/




/*
 * listtif.c -- lists a tiff file.
 */

#include "xtiffio.h"
#include <stdlib.h>

void main(int argc,char *argv[])
{
	char *fname="newtif.tif";
	int flags;

	TIFF *tif=(TIFF*)0;  /* TIFF-level descriptor */

	if (argc>1) fname=argv[1];
	
	tif=XTIFFOpen(fname,"r");
	if (!tif) goto failure;
	
	/* We want the double array listed */
	flags = TIFFPRINT_MYMULTIDOUBLES;
	
	TIFFPrintDirectory(tif,stdout,flags);
	XTIFFClose(tif);
	exit (0);
	
failure:
	printf("failure in listtif\n");
	if (tif) XTIFFClose(tif);
	exit (-1);
}

