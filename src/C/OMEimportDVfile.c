/* Copyright (C) 2003 Open Microscopy Environment
 * Author:  Ilya G. Goldberg <igg@nih.gov>
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

#include "OMEdb.h"
#include <stdio.h>
int main (int argc,char **argv)
{
OMEdb dbHandle;
long datasetID;
int i;
FILE *fp;

	dbHandle = OME_Get_DB_Handle ();
	
	for (i=1; i< argc; i++)
	{
		datasetID = OME_Get_Dataset_ID (dbHandle,argv[i]);
		if (!datasetID)
		{
			datasetID = OME_Add_Dataset (dbHandle,argv[i]);
			fp = OME_Open_Dataset_File (dbHandle,datasetID,"r");
			if (!fp)
				fprintf (stderr,"Could not open dataset file '%s'\n",argv[i]);
			else
			{
				fclose (fp);
				fprintf (stdout,"Importing %s..",argv[i]);
				OME_Import_DV (dbHandle, datasetID);
				fprintf (stdout,".Done\n");
			}
		}
	}
	OME_DB_Finish (dbHandle);
	return (0);
}
