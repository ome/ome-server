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
 * Written by:    
 * 
 *------------------------------------------------------------------------------
 */





/* repository.h
 *
 * 		Functions for working with OME repository files.
*/

#ifndef REPOSITORY_H
#define REPOSITORY_H

#include <stdio.h>

typedef unsigned short	    color_t;	/* Single-pixel value in the repository */
typedef unsigned long int   coord_t;
typedef struct {
    coord_t	x;
    coord_t	y;
    coord_t	z;
    coord_t	w;
    coord_t	t;
} SPoint5D;

typedef enum {
	mode_Readonly,
	mode_Writeonly,
	mode_Readwrite,
	mode_Last
} openmode_t;

typedef enum {
	rsize_Pixel,
	rsize_Line,
	rsize_Plane,
	rsize_Wave,
	rsize_Timepoint,
	rsize_Repository,
	rsize_Last
} rsize_t;

typedef struct {
	FILE*       m_File;
	SPoint5D    m_Dims;
	size_t      m_Skips [rsize_Last];
	openmode_t	m_OpenMode;
} repository_t;

void OpenRepository (repository_t* rp, const char* filename, SPoint5D dims, openmode_t mode);
void CloseRepository (repository_t* rp);
size_t GetRepositoryElementSize (repository_t* rp, rsize_t si);
void ReadTimepoint (repository_t* rp, coord_t timepoint, void* buffer);
void ReadWave (repository_t* rp, coord_t wave, coord_t timepoint, void* buffer);
void ReadPlane (repository_t* rp, coord_t plane, coord_t wave, coord_t timepoint, void* buffer);

/* This is used in parsing the Dims=x,y,z,w,t argument */
SPoint5D StringToPoint (const char* str);

#endif

