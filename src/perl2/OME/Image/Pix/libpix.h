/*
# OME/Image/Pix/pixlib/GetPix.h

# Copyright (C) 2002 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* This returns a 5-dimensional array of unsigned integers */
typedef struct
{
	char  path[256];	/* Path to the repository-format file */
	int  dx,dy,dz,dt,dw,bp; /* Image dimensions bp is bytes per pixel */
} Pix;

Pix *NewPix      (char* path, int dx, int dy, int dz, int dw, int dt, int bp);

void FreePix  (Pix *pPix);

char *GetPixels (Pix *pPix);
char *GetPlane (Pix *pPix, int theZ, int theW, int theT);
char *GetStack (Pix *pPix, int theW, int theT);
char *GetROI (Pix *pPix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
);

size_t SetPixels (Pix *pPix, char *thePix);
size_t SetPlane (Pix *pPix, char *thePix, int theZ, int theW, int theT);
size_t SetStack (Pix *pPix, char *thePix, int theW, int theT);
size_t SetROI (Pix *pPix, char *thePix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
);

/* PRIVATE methods */
FILE *GetPixFileUpdate (Pix *pPix);
