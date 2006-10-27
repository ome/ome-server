/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
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
 * Written by:  Tom J. Macura <tmacura@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */
 
#ifndef OME_MATLAB_H
#define OME_MATLAB_H

/* 
	mwSize, mwIndex, mwSignedIndex that were introduced with
	MATLAB 2006b. but we need to maintain backwards compatiblity.
*/

#include "tmwtypes.h"
#ifndef mwSize
typedef int mwSize;
#endif
#ifndef mwIndex
typedef int mwIndex;
#endif
#ifndef mwSignedIndex
typedef int mwSignedIndex;
#endif

#endif