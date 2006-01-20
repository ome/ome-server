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
 
#include <stdio.h>
#include <stdlib.h>

#include "itkOMEIS.h"

unsigned int nDims (pixHeader* ph)
{
	unsigned int NDims;
	
	if (ph->dt == 1 && ph->dc == 1 &&
		ph->dz == 1 && ph->dy == 1)
		NDims = 1;
	else if (ph->dt == 1 && ph->dc == 1 &&
			 ph->dz == 1)
		NDims = 2;
	else if (ph->dt == 1 && ph->dc == 1)
		NDims = 3;
	else if (ph->dt == 1)
		NDims = 4;
	else
		NDims = 5;
		
	return NDims;
}

char* OMEIStoMETDatatype (pixHeader* head)
{
	char* result = (char*) malloc (sizeof(char)*16);
	
	if (head->bp == 1 && head->isSigned == 1) {
		sprintf(result, "MET_CHAR");
	} else if (head->bp == 1 && head->isSigned == 0) {
		sprintf(result, "MET_UCHAR");
	} else if (head->bp == 2 && head->isSigned == 1) {
		sprintf(result, "MET_SHORT");
	} else if (head->bp == 2 && head->isSigned == 0) {
		sprintf(result, "MET_USHORT");
	} else if (head->bp == 4 && head->isSigned == 1 && head->isFloat == 0) {
		sprintf(result, "MET_INT");
	} else if (head->bp == 4 && head->isSigned == 0 && head->isFloat == 0) {
		sprintf(result, "MET_UINT");
	} else if (head->isFloat == 1) {
		sprintf(result, "MET_FLOAT");
	} else {
		fprintf (stderr, "Huge error. OMEIStoMETDataype\n");
		exit(EXIT_FAILURE);
	}
	
	return result;
}

