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
#include "httpOMEIS.h"
#include "matrix.h"

int OMEIStoMATLABDatatype (pixHeader* head)
{
	if (head->bp == 1 && head->isSigned == 1) {
		return mxINT8_CLASS;
	} else if (head->bp == 1 && head->isSigned == 0) {
		return mxUINT8_CLASS;
	} else if (head->bp == 2 && head->isSigned == 1) {
		return mxINT16_CLASS;
	} else if (head->bp == 2 && head->isSigned == 0) {
		return mxUINT16_CLASS;	
	} else if (head->bp == 4 && head->isSigned == 1 && head->isFloat == 0) {
		return mxINT32_CLASS;
	} else if (head->bp == 4 && head->isSigned == 0 && head->isFloat == 0) {
		return mxUINT32_CLASS;
	} else if (head->isFloat == 1) {
		return mxSINGLE_CLASS;
	}
	
	return 0;
}
#endif