/* Copyright (C) 2003 Open Microscopy Environment
 * Author:  
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



/* repository.c
 *
 * 		Functions for working with OME repository.
 */

#include "repository.h"
#include "failio.h"

void OpenRepository (repository_t* rp, const char* filename, SPoint5D dims, openmode_t mode)
{
const char* c_rgModes [mode_Last] = { "r", "w", "rw" };
	rp->m_File = OpenFile (filename, c_rgModes[mode]);
	rp->m_OpenMode = mode;
	rp->m_Dims = dims;
	rp->m_Skips [rsize_Pixel] = sizeof(color_t);
	rp->m_Skips [rsize_Line] = rp->m_Skips [rsize_Pixel] * dims.x;
	rp->m_Skips [rsize_Plane] = rp->m_Skips [rsize_Line] * dims.y;
	rp->m_Skips [rsize_Wave] = rp->m_Skips [rsize_Plane] * dims.z;
	rp->m_Skips [rsize_Timepoint] = rp->m_Skips [rsize_Wave] * dims.w;
	rp->m_Skips [rsize_Repository] = rp->m_Skips [rsize_Timepoint] * dims.t;
}

void CloseRepository (repository_t* rp)
{
	CloseFile (rp->m_File);
	rp->m_File = NULL;
}

size_t GetRepositoryElementSize (repository_t* rp, rsize_t si)
{
	return (rp->m_Skips [si]);
}

void ReadTimepoint (repository_t* rp, coord_t timepoint, void* buffer)
{
	Seek (rp->m_File, rp->m_Skips [rsize_Timepoint] * timepoint);
	Read (rp->m_File, buffer, rp->m_Skips [rsize_Timepoint]);
}

void ReadWave (repository_t* rp, coord_t wave, coord_t timepoint, void* buffer)
{
	size_t offset = rp->m_Skips[rsize_Timepoint] * timepoint +
					rp->m_Skips[rsize_Wave] * wave;
	Seek (rp->m_File, offset);
	Read (rp->m_File, buffer, rp->m_Skips [rsize_Wave]);
}

void ReadPlane (repository_t* rp, coord_t plane, coord_t wave, coord_t timepoint, void* buffer)
{
	size_t offset = rp->m_Skips[rsize_Timepoint] * timepoint +
					rp->m_Skips[rsize_Wave] * wave +
					rp->m_Skips[rsize_Plane] * plane;
	Seek (rp->m_File, offset);
	Read (rp->m_File, buffer, rp->m_Skips [rsize_Plane]);
}

SPoint5D StringToPoint (const char* str)
{
	coord_t vars [5] = { 0, 0, 0, 0, 0 };
	SPoint5D pt = { 0, 0, 0, 0, 0 };
	int i, c = 0;
	if (!str)
		return (pt);
	for (i = 0; i < 5; ++ i, ++ c)
		for (; str[c] >= '0' && str[c] <= '9'; ++ c)
			vars[i] = vars[i] * 10 + (str[c] - '0');
	pt.x = vars[0];
	pt.y = vars[1];
	pt.z = vars[2];
	pt.w = vars[3];
	pt.t = vars[4];
	return (pt);
}

