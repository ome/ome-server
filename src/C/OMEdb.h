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


#if !defined(__ome_db_h__)
#define __ome_db_h__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <stdarg.h>
#include "libpq-fe.h"


/* standard type def'ns */
typedef long        ome_id_t;
typedef PGconn *    OMEdb;
typedef PGresult *  OMEres;

/* standard constants */
enum
{
    OME_SQLBUFSIZE  = 512,
    OME_HOSTLEN     = 255
};

/* misc def'ns */
#define OME_RC_FILE ".OMErc"


char *rel2abs(const char *path, const char *base, char *result, const size_t size);

OMEres OMEexecSQL (OMEdb dbHandle,char *query);
OMEres OMEexecSQLf(OMEdb, char *, ...);
void OMEclearRes (OMEres theRes);
void OME_Exit (OMEdb dbHandle);
void OME_DB_Finish (OMEdb dbHandle);
void OME_DB_Commit (OMEdb dbHandle);
void OME_Error (int OME_Error_Type,char *message);
void OME_DB_Error (int OME_Error_Type,OMEdb dbHandle,char *message);
OMEdb OME_Get_DB_Handle_From_String (char *connectString);
OMEdb OME_Get_DB_Handle ();
FILE *OME_Get_OMErc ();
char *OME_Get_Local_User (char *userName);
char *OME_Get_Local_Host (char *hostName);
char *OME_Get_Local_WD (char *CWD, size_t size);
char *OME_Get_Local_Dataset_Path (char *datasetName, char *datasetPath);
long OME_Get_DB_User_ID (OMEdb dbHandle);
char *OME_Get_Output_Table (OMEdb dbHandle, long programID ,char *tableName);
char *OME_Get_Input_Table (OMEdb dbHandle,long programID ,char *tableName);
long OME_Get_Program_ID (OMEdb dbHandle,char *programName);
char *OME_Get_Program_Path (OMEdb dbHandle,long programID,char *programPath);
long OME_Register_Analysis (OMEdb dbHandle,long programID,long datasetID,
				char *attrNames, char *attrValues);
void OME_Combine_Attribute_Names_Values (char *attrNames,char *attrValues,char *attrNamesValues,char *logic);
long OME_Get_Analysis_ID_From_Inputs (OMEdb dbHandle, long programID,
	 long datasetID, char *attrNames, char *attrValues);
char OME_Expired_Analysis (OMEdb dbHandle, long analysisID);
void OME_Set_Analysis_Inputs (OMEdb dbHandle, long analysisID, char *attrNames, char *attrValues);
void OME_Add_Attribute_Values (OMEdb dbHandle, long featureID, long analysisID, char *tableName, char *attrNames, char *attrValues);
void OME_Set_Feature_Attribute (OMEdb dbHandle, long featureID, long analysisID, char *tableName, char *attrName, char *attrValue);
void OME_Set_Feature_Attribute_long (OMEdb dbHandle, long featureID, long analysisID, char *tableName, char *attrName, long attrValue);
long *OME_Get_Feature_Attributes_As_longs (OMEdb dbHandle, long *featureID, long analysisID,char *tableName, char *attrName);
long *OME_Get_Feature_IDs (OMEdb dbHandle, long analysisID);
long OME_Get_Feature_Count (OMEdb dbHandle, long analysisID);
int OME_Get_ID_From_Menu (
	OMEdb dbHandle,
	char *IDColumn,
	char *selectStatement,
	char *extraItem,
	int extraMatch,
	char *prompt,
	char *result);
long OME_Add_Dataset (OMEdb dbHandle,char *datasetName);
long OME_Get_Dataset_ID (OMEdb dbHandle,char *datasetName);
FILE *OME_Open_Dataset_File (OMEdb dbHandle, long datasetID,char *rwString);
void OME_Modify_Dataset (OMEdb dbHandle, long datasetID,char *attributes);
void OME_Add_Attributes (OMEdb dbHandle, char *tableName,char *attributes,char *values);
char *OME_Get_Attributes (OMEdb dbHandle, char *tableName,char *attributes,char *where);
void OME_Set_Experimenter_Attributes (OMEdb dbHandle,long userID);
void OME_Set_Analysis_Attributes (OMEdb dbHandle,long analysisID);
void OME_Set_Dataset_Attributes (OMEdb dbHandle,long datasetID);
long OME_Add_Feature (OMEdb dbHandle, long analysisID);
long Get_Num_Timepoints (OMEdb dbHandle, long datasetID);


/*
* In OME_DV.c
*/

long OME_Import_DV (OMEdb dbHandle, long datasetID);

#define OME_FATAL_ERROR 1
#define OME_ERROR 2
#define OME_WARNING 3
#define OME_INFO 4

#endif  // ifdef __ome_db_h__
