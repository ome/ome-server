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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   3/2004
 * 
 *------------------------------------------------------------------------------
 */
 
#ifndef update_h
#define update_h

// typedef struct {
// 	ome_coord theZ, theC, theT;
// } tiffConvertSpec_v1;
// 
// typedef struct {
// 	unsigned long file_offset;
// 	unsigned long pix_offset;
// 	unsigned long nPix;
// } fileConvertSpec_v1;
// 
// typedef struct {
// 	OID FileID;
// 	char isBigEndian;
// 	char isTIFF;
// 	union {
// 		tiffConvertSpec_v1 tiff;
// 		fileConvertSpec_v1 file;
// 	} spec;
// } convertFileRec_v1;

typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y;
	char reserved[7]; /* reserved buffer (64 bytes total) */
} planeInfo_v1;

typedef struct
{
	u_int8_t stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y;
	/* MISSING: u_int32_t hist[NUM_BINS]; */
	u_int8_t reserved[7]; /* reserved buffer (64 bytes total) */
} planeInfo_v2;

typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y, centroid_z;
	char reserved[67]; /* reserved buffer (128 bytes total) */
} stackInfo_v1;

typedef struct
{
	u_int8_t stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y, centroid_z;
	/* MISSING: u_int32_t hist[NUM_BINS]; */
	u_int8_t reserved[67]; /* reserved buffer (128 bytes total) */
} stackInfo_v2;

typedef struct {
	unsigned long mySig;
	unsigned char vers;
	unsigned char isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	unsigned char bp;             /* bytes per pixel */
	unsigned char isSigned;       /* signed integers or not */
	unsigned char isFloat;        /* floating point or not */
	unsigned char sha1[OME_DIGEST_LENGTH]; /* SHA1 digest */
	char reserved[11];            /* buffer assuming OME_DIGEST_LENGTH=20 */
} pixHeader_v1;

/*
pixHeader* update_header_v1(pixHeader_v1* v1Head);
int fix_header (OID ID);
int fix_v1_header (PixelsRep *myPixels, FILE *headFP);
*/
void update_planeInfos_v2(planeInfo_v2* v2Plane, planeInfo* v3Plane, int nPlanes);
void update_stackInfos_v2(stackInfo_v2* v2Stack, stackInfo* v3Stack, int nStacks);

#endif
