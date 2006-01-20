/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2005 Open Microscopy Environment
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
 * Written by:	Tom J. Macura <tmacura@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */

#ifndef HTTP_OMEIS_H
#define HTTP_OMEIS_H

#include <sys/types.h>
#include <curl/curl.h>
#include <curl/types.h>

/* Copied from Pixels.h, but trimmed */
typedef int32_t ome_coord;
typedef int32_t ome_dim;
typedef u_int64_t OID;

#define OME_DIGEST_CHAR_LENGTH 41
typedef struct {
/*	u_int32_t mySig;
	u_int8_t vers; */
	u_int8_t isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	u_int8_t bp;             /* bytes per pixel */
	u_int8_t isSigned;       /* signed integers or not */
	u_int8_t isFloat;        /* floating point or not */
	u_int8_t sha1[OME_DIGEST_CHAR_LENGTH]; /* SHA1 digest */
/*	u_int8_t reserved[15]; */ /* buffer to 64 (60?)assuming OME_DIGEST_LENGTH=20 */
} pixHeader;

typedef struct {
	char url[128];
	char sessionKey[128];
} omeis;

/* External Functions */
omeis* openConnectionOMEIS (const char* url, const char* sessionKey);
OID newPixels (const omeis* is, const pixHeader* head);
pixHeader* pixelsInfo (const omeis* is, OID pixelsID);
char* pixelsSHA1 (const omeis *is, OID pixelsID);
int setPixels (const omeis *is, OID pixelsID, void* pixels);
void* getPixels (const omeis* is, OID pixelsID);
OID finishPixels (const omeis* is, OID pixelsID);
OID deletePixels (const omeis* is, OID pixelsID);
char* getLocalPath (const omeis *is, OID pixelsID);
int setROI (const omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1, void* pixels);
void* getROI (const omeis *is, OID pixelsID, int x0, int y0, int z0, int c0, int t0,
			int x1, int y1, int z1, int c1, int t1);
#endif
