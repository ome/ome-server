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
 * Written by:	Tom Macura <tmacura@nih.gov>   5/2004
 * 
 *------------------------------------------------------------------------------
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h> 
#include <ctype.h> 
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/param.h>

#include "Pixels.h"
#include "OMEIS_Error.h"
#include "update.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif


/*

pixHeader* update_header_v1(pixHeader_v1* v1Head)
{
pixHeader* v2Head;

	if (v1Head->mySig != OME_IS_PIXL_SIG) {
		fprintf (stderr,"Incompatible signature\n");
		exit(EXIT_FAILURE);
	}
	
	if (v1Head->vers  != 1) {
		fprintf (stderr,"Incompatible version (%d)\n", (int)v1Head->vers);
		exit(EXIT_FAILURE);
	}

	memset(v2Head, 0, sizeof(pixHeader));
	v2Head->mySig          = OME_IS_PIXL_SIG;
	v2Head->vers           = 2;
	v2Head->isFinished     = v1Head->isFinished;
	v2Head->dx             = v1Head->dx;
	v2Head->dy             = v1Head->dy;
	v2Head->dz             = v1Head->dz;
	v2Head->dc             = v1Head->dc;
	v2Head->dt             = v1Head->dt;
	v2Head->bp             = v1Head->bp;
	v2Head->isSigned       = v1Head->isSigned;
	v2Head->isFloat        = v1Head->isFloat;
	memcpy (v2Head->sha1,v1Head->sha1,OME_DIGEST_LENGTH);

	return v2Head;
}
*/

/* planeInfo_v2* update_planeInfos_v1(planeInfo_v1* v1Plane, int nPlanes) */
/* { */
/* planeInfo_v2* v2Plane; */
/* int i; */
/*  */
/* 	v2Plane = malloc(sizeof(planeInfo_v2)*nPlanes);  */
/* 	for (i=0; i < nPlanes; i++) { */
/* 		v2Plane[i].stats_OK   = v1Plane[i].stats_OK; */
/* 		v2Plane[i].sum_i      = v1Plane[i].sum_i;  */
/* 		v2Plane[i].sum_i2     = v1Plane[i].sum_i2; */
/* 		v2Plane[i].sum_log_i  = v1Plane[i].sum_log_i; */
/* 		v2Plane[i].sum_xi     = v1Plane[i].sum_xi; */
/* 		v2Plane[i].sum_yi     = v1Plane[i].sum_yi; */
/* 		v2Plane[i].sum_zi     = v1Plane[i].sum_zi; */
/* 		v2Plane[i].min        = v1Plane[i].min; */
/* 		v2Plane[i].max        = v1Plane[i].max; */
/* 		v2Plane[i].mean       = v1Plane[i].mean; */
/* 		v2Plane[i].geomean    = v1Plane[i].geomean; */
/* 		v2Plane[i].sigma      = v1Plane[i].sigma; */
/* 		v2Plane[i].geosigma   = v1Plane[i].geosigma; */
/* 		v2Plane[i].centroid_x = v1Plane[i].centroid_x; */
/* 		v2Plane[i].centroid_y = v1Plane[i].centroid_y; */
/* 	} */
/*  */
/* 	return v2Plane; */
/* } */
/*  */
/* stackInfo_v2* update_stackInfos_v1(stackInfo_v1* v1Stack, int nStacks) */
/* { */
/* stackInfo_v2* v2Stack; */
/* int i; */
/*  */
/* 	v2Stack = malloc(sizeof(stackInfo_v2)*nStacks);  */
/* 	for (i=0; i < nStacks; i++) { */
/* 		v2Stack[i].stats_OK   = v1Stack[i].stats_OK; */
/* 		v2Stack[i].sum_i      = v1Stack[i].sum_i;  */
/* 		v2Stack[i].sum_i2     = v1Stack[i].sum_i2; */
/* 		v2Stack[i].sum_log_i  = v1Stack[i].sum_log_i; */
/* 		v2Stack[i].sum_xi     = v1Stack[i].sum_xi; */
/* 		v2Stack[i].sum_yi     = v1Stack[i].sum_yi; */
/* 		v2Stack[i].sum_zi     = v1Stack[i].sum_zi; */
/* 		v2Stack[i].min        = v1Stack[i].min; */
/* 		v2Stack[i].max        = v1Stack[i].max; */
/* 		v2Stack[i].mean       = v1Stack[i].mean; */
/* 		v2Stack[i].geomean    = v1Stack[i].geomean; */
/* 		v2Stack[i].sigma      = v1Stack[i].sigma; */
/* 		v2Stack[i].geosigma   = v1Stack[i].geosigma; */
/* 		v2Stack[i].centroid_x = v1Stack[i].centroid_x; */
/* 		v2Stack[i].centroid_y = v1Stack[i].centroid_y; */
/* 		v2Stack[i].centroid_z = v1Stack[i].centroid_z; */
/* 	} */
/*  */
/* 	return v2Stack; */
/* } */

void update_planeInfos_v2(planeInfo_v2* v2Plane, planeInfo* v3Plane, int nPlanes)
{
int i,j;

	for (i=0; i < nPlanes; i++) {
		/* Histogram must be recomputed */
		
		v3Plane[i].stats_OK   = 0; /*v2Plane[i].stats_OK;*/
		v3Plane[i].sum_i      = v2Plane[i].sum_i; 
		v3Plane[i].sum_i2     = v2Plane[i].sum_i2;
		v3Plane[i].sum_log_i  = v2Plane[i].sum_log_i;
		v3Plane[i].sum_xi     = v2Plane[i].sum_xi;
		v3Plane[i].sum_yi     = v2Plane[i].sum_yi;
		v3Plane[i].sum_zi     = v2Plane[i].sum_zi;
		v3Plane[i].min        = v2Plane[i].min;
		v3Plane[i].max        = v2Plane[i].max;
		v3Plane[i].mean       = v2Plane[i].mean;
		v3Plane[i].geomean    = v2Plane[i].geomean;
		v3Plane[i].sigma      = v2Plane[i].sigma;
		v3Plane[i].geosigma   = v2Plane[i].geosigma;
		v3Plane[i].centroid_x = v2Plane[i].centroid_x;
		v3Plane[i].centroid_y = v2Plane[i].centroid_y;
	}
}

void update_stackInfos_v2(stackInfo_v2* v2Stack, stackInfo* v3Stack, int nStacks)
{
int i,j;
	for (i=0; i < nStacks; i++) {
		/* Histogram must be recomputed */
		v3Stack[i].stats_OK   = 0; /*v2Stack[i].stats_OK;*/
		v3Stack[i].sum_i      = v2Stack[i].sum_i; 
		v3Stack[i].sum_i2     = v2Stack[i].sum_i2;
		v3Stack[i].sum_log_i  = v2Stack[i].sum_log_i;
		v3Stack[i].sum_xi     = v2Stack[i].sum_xi;
		v3Stack[i].sum_yi     = v2Stack[i].sum_yi;
		v3Stack[i].sum_zi     = v2Stack[i].sum_zi;
		v3Stack[i].min        = v2Stack[i].min;
		v3Stack[i].max        = v2Stack[i].max;
		v3Stack[i].mean       = v2Stack[i].mean;
		v3Stack[i].geomean    = v2Stack[i].geomean;
		v3Stack[i].sigma      = v2Stack[i].sigma;
		v3Stack[i].geosigma   = v2Stack[i].geosigma;
		v3Stack[i].centroid_x = v2Stack[i].centroid_x;
		v3Stack[i].centroid_y = v2Stack[i].centroid_y;
		v3Stack[i].centroid_z = v2Stack[i].centroid_z;
	}
}