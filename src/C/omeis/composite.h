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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   1/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifndef OMEIS_MAGICK_H
#define OMEIS_MAGICK_H

#include <sys/types.h>
#include "Pixels.h"

#define OMEIS_THUMB_SIGNATURE           0x54484D42    /* THMB in ASCII */
#define OMEIS_THUMB_SIMPLE_COMPOSITING  0x0001

typedef struct {
	PixelsRep *thePixels;
	int theZ, theT;
	int sizeX, sizeY;
	char isRGB;
	size_t nPix;
	channelSpecType RGBAGr[5];
	char format[32];
	FILE *stream;
	void *blob;
} CompositeSpec;

/*
 * This type holds the compositing settings as they are currently
 * implemented.  The thumbnailHeader type allows for multiple versions
 * of these compositing settings -- once/if we adopt the more
 * intricate compositing settings proposed by J-M, then they will form
 * a new compositing struct and member of the union in the
 * thumbnailHeader type.
 */

typedef struct {
    ome_coord        theZ, theT;
    ome_dim          sizeX, sizeY;
    u_int8_t         isRGB;
    channelSpecType  RGBAGr[5];
} SimpleComposite;

typedef struct {
    u_int32_t  signature;
    u_int16_t  version;
    u_int32_t  thumbnail_offset;
    union {
        SimpleComposite  simple;
    } composite;
} ThumbnailHeader;

int DoComposite (PixelsRep *myPixels, int theZ, int theT, char **param);
int DoThumb (OID ID, FILE *thumbnail, ome_dim sizeX, ome_dim sizeY);

#endif
