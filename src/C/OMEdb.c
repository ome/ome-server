/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
 * Written by:    Ilya G. Goldberg <igg@nih.gov>
 * 
 *------------------------------------------------------------------------------
 */




#include "OMEdb.h"

union   fmt_tag { int i_val; long l_val; double f_val; char c_val; };


/*
    printf style version of OMEexecSQLf.
    supported formats:
        %s -- string            (type char *)
        %d -- integer           (type int)
        %l -- long integer      (type long)
        %f -- real              (type double -- floats promoted to double in va_arg calls, C-ANSI standard)
*/
OMEres OMEexecSQLf(OMEdb dbHandle, char *query, ...)
{
    char            sql_cmd[OME_SQLBUFSIZE], *p, *q, *s;
    char            buf[64];
    union fmt_tag   tag;
    va_list         argp;

    va_start(argp, query);

    for(p = query, q = sql_cmd; p && *p != '\0'; p++)
    {
        if(((int)(q - &sql_cmd[0])) > OME_SQLBUFSIZE - 1)
        {
            break;
        }

        if(*p != '%')
        {
            *q = *p;
            q++;
            continue;
        }
        else
        {
            p++;
            if(*p == 's')
            {
                for(s = va_arg(argp, char *); s; s++)
                {
                    *q = *s;
                    q++;
                }
            } 
            else if(*p == 'd')
            {
                tag.i_val = va_arg(argp, int);
                sprintf(buf, "%d", tag.i_val);
                strcat(q, buf);
                q += strlen(buf);
            }
            else if(*p == 'l')
            {
                tag.l_val = va_arg(argp, long);
                sprintf(buf, "%ld", tag.l_val);
                strcat(q, buf);
                q += strlen(buf);
            }
            else if(*p == 'f')
            {
                tag.f_val = va_arg(argp, double);
                sprintf(buf, "%lf", tag.f_val);
                strcat(q, buf);
                q += strlen(buf);
            }
            else if(*p == '%')
            {
                *q = *p; q++;
            }
            else
            {
                /* unknown format, skip */
#if defined(DEBUG)
                fprintf(stderr, "Unknown format: %%%c", *p);
#endif
            }
        }
    }
   
    *q = '\0';
    va_end(argp);

    return(OMEexecSQL(dbHandle, sql_cmd));
}    
                
            
        
    
    

OMEres OMEexecSQL (OMEdb dbHandle,char *query)
{
/*
#ifdef DEBUG
printf ("New OMEres\n");
#endif
*/
	return ( PQexec (dbHandle,query) );
}

void OMEclearRes (OMEres theRes)
{
/*
#ifdef DEBUG
printf ("Clear OMEres\n");
#endif
*/
	PQclear (theRes);
}


void OME_Exit (OMEdb dbHandle)
{
	PQfinish(dbHandle);
	exit(-1);
}

void OME_DB_Finish (OMEdb dbHandle)
{
OMEres theRes;

	theRes = OMEexecSQL (dbHandle,"COMMIT");
	if (!theRes || PQresultStatus(theRes) != PGRES_COMMAND_OK)
	{
		OMEclearRes(theRes);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not issue a COMMIT command.");
		OME_Exit (dbHandle);
	}

	OMEclearRes(theRes);
	PQfinish(dbHandle);
}



void OME_DB_Commit (OMEdb dbHandle)
{
OMEres theRes;

	theRes = OMEexecSQL (dbHandle,"COMMIT");
	OMEclearRes(theRes);
	theRes = OMEexecSQL (dbHandle,"BEGIN");
	OMEclearRes(theRes);
}



void OME_Error (int OME_Error_Type,char *message)
{
	switch (OME_Error_Type)
		{
		case OME_FATAL_ERROR:
			fprintf (stderr,"OME FATAL ERROR: ");
			break;
		case OME_WARNING:
			fprintf (stderr,"OME WARNING: ");
			break;
		case OME_INFO:
			fprintf (stderr,"OME INFO: ");
			break;
		}
	fprintf (stderr,"%s\n",message);
}


void OME_DB_Error (int OME_Error_Type,OMEdb dbHandle,char *message)
{
char message2[256];

	sprintf (message2,"%s\nDB message: %s",message,PQerrorMessage(dbHandle));
	OME_Error (OME_Error_Type,message2);
}



OMEdb OME_Get_DB_Handle_From_String (char *connectString)
{
OMEdb dbHandle;
OMEres theRes;


	dbHandle = PQconnectdb ( connectString );
	if (PQstatus(dbHandle) == CONNECTION_BAD)
		{
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not make connection to the database.");
		OME_Exit (dbHandle);
		}

#ifdef DEBUG
{
static char buf[BUFSIZ];
FILE *trace_fp;

trace_fp = fopen("/tmp/trace.out","w");
setvbuf (trace_fp, buf, _IONBF, BUFSIZ);

PQtrace(dbHandle,trace_fp);
}
#endif
	theRes = OMEexecSQL (dbHandle,"BEGIN");
	if (!theRes || PQresultStatus(theRes) != PGRES_COMMAND_OK)
	{
		OMEclearRes(theRes);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not issue a BEGIN command.");
		OME_Exit (dbHandle);
	}

	OMEclearRes(theRes);
	return (dbHandle);


}


OMEdb OME_Get_DB_Handle ()
{
char connectString[OME_SQLBUFSIZE];
char connectTag[]="OMEdb Connect: ";
FILE *OMErc;
OMEdb dbHandle;
OMEres theRes;


	OMErc = OME_Get_OMErc();
	if (OMErc == NULL)
		{
		OME_Error (OME_FATAL_ERROR,"The OME resource file could not be opened.");
		exit (-1);
		}


	fgets (connectString,255,OMErc);
	while (!feof (OMErc))
		if (!strncmp (connectString,connectTag,strlen (connectTag))) break;
	if (strncmp (connectString,connectTag,strlen (connectTag)))
		{
		OME_Error (OME_FATAL_ERROR,"Could not find the connection string in ~/.OMErc.");
		fclose (OMErc);
		exit (-1);
		}
	
	fclose (OMErc);

	dbHandle = PQconnectdb ( connectString + strlen (connectTag) );
	if (PQstatus(dbHandle) == CONNECTION_BAD)
		{
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not make connection to the database.");
		OME_Exit (dbHandle);
		}

#ifdef DEBUG
PQtrace(dbHandle,fopen("trace.out","w"));
#endif
	theRes = OMEexecSQL (dbHandle,"BEGIN");
	if (!theRes || PQresultStatus(theRes) != PGRES_COMMAND_OK)
	{
		OMEclearRes(theRes);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not issue a BEGIN command.");
		OME_Exit (dbHandle);
	}

	OMEclearRes(theRes);

	return (dbHandle);

}


FILE *OME_Get_OMErc ()
{
    char rcPath[PATH_MAX];

    sprintf(rcPath, "%s/%s", getenv("HOME"), OME_RC_FILE);
    return(fopen(rcPath, "r"));
}



char *OME_Get_Local_User (char *userName)
{
	if (getlogin())
		{
		strcpy ( userName,getlogin() );
		return (userName);
		}
	else
		{
		strcpy ( userName,"");
		return (NULL);
		}
}


char *OME_Get_Local_Host (char *hostName)
{
	 
	if ( gethostname (hostName, OME_HOSTLEN))
		return (NULL);
	else
		return (hostName);
}


char *OME_Get_Local_WD (char *CWD, size_t size)
{
	return ( getcwd(CWD,size) );
}


char *OME_Get_Local_Dataset_Path (char *datasetName, char *datasetPath)
{
/*
* This function uses rel2abs.c to compute an absolute path to the dataset.
* The base path we pass to rel2abs is the CWD that we get from OME_Get_Local_WD
* The relative path is the datasetName.  rel2abs will return the absolute path
* to datasetName.  Since the OME database stores the absolute path to the directory
* contining the dataset, we truncate the absolute path at the datasetName.
* WARNING:  This function will modify datasetName to contain ONLY the name if it also
* contains a relative path.
* N.B.:  This function is not very well named.  It is simply a path processor - it does
* not check for the existance of any paths or files - only correct syntax.
* Send this function a relative path in *datasetName (relative to CWD), and it
* will return the absolute path (up to and including the last path delimiter, but not
* including the name passed in *datasetName) in *datasetPath, and modify the *datasetName
* so that it contains only the name.  The absolute path to the dataset is then:
* strcat (datasetPath,datasetName);
*/
char pathDelim='/';
char path[PATH_MAX],CWD[PATH_MAX],*chrPtr;

	if (!rel2abs(datasetName,OME_Get_Local_WD (CWD,127),path, PATH_MAX))
		return (NULL);
	
#ifdef DEBUG
fprintf (stdout,"absolute path: %s\n",path);
#endif
/*
* Look backwards in path for a path delimiter.
* the new datasetName will consist of everything between the last path delimiter
* and the NULL terminus.
* The datasetPath will containing everything returned by rel2abs upto and including
* the last path delimiter.
*/
	chrPtr = strrchr(path,pathDelim);
	if (chrPtr)
		{
		chrPtr++;
		strcpy (datasetName,chrPtr);
		}
	strcpy (datasetPath,path);
	chrPtr = datasetPath + (strlen(path)-strlen(datasetName));
	*chrPtr = 0;
#ifdef DEBUG
fprintf (stdout,"path (%d): %s\n",strlen (path),path);
fprintf (stdout,"datasetName (%d): %s\n",strlen (datasetName),datasetName);
fprintf (stdout,"datasetPath (%d): %s\n",strlen (datasetPath),datasetPath);
#endif

	return (datasetPath);
		
}





ome_id_t OME_Get_DB_User_ID (OMEdb dbHandle)
{
char query[OME_SQLBUFSIZE],message[256],userName[256],*chrPtr;
OMEres res;
ome_id_t userID;
/*
* See if the user exists.
* OME_NAME is the user name in the database.  Get the string from the dbHandle,
* Look up the experimenter_id from the experimenters table.
* If there are duplicate entries, exit with FATAL_ERROR.
* If there are no entries, add the user, then call OME_Set_Experimenter_Attributes.
*/
	chrPtr = PQuser(dbHandle);
	if (chrPtr)
		strcpy (userName,chrPtr);
	else
	{
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not get the user name from the database");
		OME_Exit (dbHandle);
	}

	sprintf (query,"SELECT experimenter_id FROM experimenters WHERE ome_name='%s'",
		userName);
	res = OMEexecSQL(dbHandle,query);
	if (PQntuples(res) == 1)
	{
		userID = atoi (PQgetvalue(res,0,0));
		OMEclearRes(res);
	}
	else if (PQntuples(res) > 1)
	{
		sprintf (message,"There is more than one OME user with OME_NAME='%s'",userName);
		OMEclearRes(res);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}
	else
	{
		OMEclearRes(res);
		res = OMEexecSQL(dbHandle,"SELECT nextval('EXPERIMENTER_SEQ')");
		if (PQntuples(res) != 1)
		{
			OMEclearRes(res);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not get the next value from EXPERIMENTER_SEQ");
			OME_Exit (dbHandle);
		}
		userID = atoi (PQgetvalue(res,0,0));
		OMEclearRes(res);

		sprintf (query,"INSERT INTO experimenters (experimenter_ID,OME_name)\
						VALUES (%ld,'%s')",userID,userName);
		res = OMEexecSQL(dbHandle,query);
		if (PQresultStatus(res) != PGRES_COMMAND_OK)
		{
			OMEclearRes(res);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not add entry for current user into ANALYSES table.");
			OME_Exit (dbHandle);
		}
		OMEclearRes(res);

		OME_Set_Experimenter_Attributes (dbHandle,userID);
	}
	return (userID);
}





/*
* Deprecated - no longer applicable
*/
char *OME_Get_Output_Table (OMEdb dbHandle, ome_id_t programID ,char *tableName)
{
char query[OME_SQLBUFSIZE];
OMEres res;
char *returnValue=NULL;

	*tableName = '\0';
	if (!programID)
		return (NULL);

	sprintf (query,"SELECT output_table FROM programs WHERE program_ID=%ld",programID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not query the PROGRAMS table");
		OME_Exit (dbHandle);
	}
	
	if (PQntuples(res) > 0)
	{
		strcpy (tableName,PQgetvalue(res,0,0));
		returnValue = tableName;
	}

	OMEclearRes(res);
	return (returnValue);
}




char *OME_Get_Input_Table (OMEdb dbHandle, ome_id_t programID ,char *tableName)
{
char query[OME_SQLBUFSIZE];
OMEres res;
char *returnValue=NULL;

	*tableName = '\0';
	if (!programID)
		return (NULL);

	sprintf (query,"SELECT input_table FROM programs WHERE program_id=%ld",programID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not query the PROGRAMS table");
		OME_Exit (dbHandle);
	}
	
	if (PQntuples(res) > 0)
	{
		strcpy (tableName,PQgetvalue(res,0,0));
		returnValue = tableName;
	}

	OMEclearRes(res);
	return (returnValue);


}




ome_id_t OME_Get_Program_ID (OMEdb dbHandle,char *programName)
{
char query[OME_SQLBUFSIZE];
OMEres res;
ome_id_t programID=0;

	sprintf (query,"SELECT program_id FROM programs WHERE program_name='%s'",programName);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not query the PROGRAMS table");
		OME_Exit (dbHandle);
	}
	if (PQntuples(res) > 0)
		programID = atoi (PQgetvalue(res,0,0));

	OMEclearRes(res);
	return (programID);

}


char *OME_Get_Program_Path (OMEdb dbHandle, ome_id_t programID,char *programPath)
{
char query[OME_SQLBUFSIZE],*returnVal=NULL;
OMEres res;

	*programPath = '\0';
	sprintf (query,"SELECT path FROM programs WHERE program_id=%ld",programID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not query the PROGRAMS table");
		OME_Exit (dbHandle);
	}
	if (PQntuples(res) > 0)
		returnVal = strcpy (programPath,PQgetvalue(res,0,0));

	OMEclearRes(res);
	return (returnVal);

}





ome_id_t OME_Register_Analysis (OMEdb dbHandle, ome_id_t programID, ome_id_t datasetID,
				char *attrNames, char *attrValues)
{
/*
* By this time, the program (programName) has an output table and a relevant datasetID in the database.
* If this is not true, then we generate a FATAL_ERROR.
* This function adds a new instance to the ANALYSES table, and a new instance to the
* input table for the specified programID.
*/

char query[OME_SQLBUFSIZE],message[256];
ome_id_t analysisID,userID;
OMEres res;


	userID = OME_Get_DB_User_ID (dbHandle);
	if (!userID)
	{
		sprintf (message,"Could not get user ID for user with OME_NAME='%s'",PQuser(dbHandle));
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}
	
	res = OMEexecSQL (dbHandle,"SELECT nextval('ANALYSIS_SEQ')");
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not get the next value from ANALYSIS_SEQ");
		OME_Exit (dbHandle);
	}
	analysisID = atoi (PQgetvalue(res,0,0));
	OMEclearRes(res);


	sprintf (query,"INSERT INTO analyses (analysis_ID,experimenter_ID,dataset_ID,program_id,timestamp)\
					VALUES (%ld,%ld,%ld,%ld,CURRENT_TIMESTAMP)",
					analysisID,userID,datasetID,programID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not add entry for this analysis into ANALYSES table.");
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);

	
	OME_Set_Analysis_Inputs (dbHandle,analysisID,attrNames,attrValues);
	return (analysisID);

}




/*
* This does some text processing, converting for example:
* attrNames = "attr1,attr2,attr3"
* AttrValues = "4,5,6"
* logic = "AND"
* TO:
* attrNamesValues = "attr1=4 AND attr2=5 AND attr3=6"
* The attribute names and values must be separated by commas.
* FIXME:  attrNames and attrValues with commas in single quotes are not handled correctly, for example:
* attrNames = "attr1,attr2,attr3"
* AttrValues = "4,'this, that',5,6"
* Also, this function will return a broken attribute string - if number of names doesn't match
* number of values - without reporting an error.
*/
void OME_Combine_Attribute_Names_Values (char *attrNames,char *attrValues,char *attrNamesValues,char *logic)
{
char *logicPtr;
char *attrNamesValuesPtr;
/*
* 1.  Get first non-comma and non-'\0' character in attrNames.
* 2.  If this is not the first time through, copy logic to attrNamesValues.
* 3.  Copy from attrNames to attrNamesValues until we reach a comma or '\0'.
* 4.  Copy '=' to attrNamesValues
* 5.  Copy from attrValues to attrNamesValues until we reach a comma or '\0'.
* 6.  Go to step 1.
*/
	*attrNamesValues = '\0';
	attrNamesValuesPtr = attrNamesValues;
	while (*attrNames)
	{
		while ( *attrNames && *attrNames == ',' ) attrNames++;
		logicPtr = logic;
		if (*attrNamesValues)
		{
			*attrNamesValuesPtr++ = ' ';
			while (*logicPtr) *attrNamesValuesPtr++ = *logicPtr++;
			*attrNamesValuesPtr++ = ' ';
		}
		while (*attrNames && *attrNames != ',' ) *attrNamesValuesPtr++ = *attrNames++;
		*attrNamesValuesPtr++ = '=';
		while ( *attrValues && *attrValues == ',' ) attrValues++;
		while (*attrValues && *attrValues != ',' ) *attrNamesValuesPtr++ = *attrValues++;
	}

	*attrNamesValuesPtr = '\0';	
}





/*
* This function will return an ANALYSIS_ID that matches all of the specified attributes and
* values.
* This should be called to make sure we are not performing a duplicate analysis.
*/
ome_id_t OME_Get_Analysis_ID_From_Inputs (OMEdb dbHandle, ome_id_t programID,
	 ome_id_t datasetID, char *attrNames, char *attrValues)
{
OMEres res;
char query[OME_SQLBUFSIZE],message[256],attrNamesValues[256],inTable[64];
ome_id_t analysisID;

/*
* Make a proper string for the query in the form of "attr1=1 AND attr2=234"
*/
	OME_Combine_Attribute_Names_Values (attrNames,attrValues,attrNamesValues,"AND");

/*
* Get the program input table.
*/
	OME_Get_Input_Table (dbHandle,programID ,inTable);

/*
* Do the select.
*/
	sprintf (query,"SELECT analysis_id from analyses where dataset_id=%ld AND \
		analysis_id IN (SELECT analysis_id FROM %s where %s)",datasetID,inTable,attrNamesValues);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	
	analysisID = (PQntuples(res) > 0) ? atoi (PQgetvalue(res,0,0)) : 0;
	OMEclearRes(res);
	return (analysisID);
}





/*
* return 1 if analysis ID is expired, 0 otherwise.
*/
char OME_Expired_Analysis (OMEdb dbHandle, ome_id_t analysisID)
{
char query[OME_SQLBUFSIZE];
OMEres res;
char isExpired=0;

	sprintf (query,"SELECT status FROM analyses where ANALYSIS_ID=%ld",analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not SELECT status FROM ANALYSES table.");
		OME_Exit (dbHandle);
	}
	
	isExpired = strncmp (PQgetvalue(res,0,0),"EXPIRED",7);
	OMEclearRes(res);

	return (!isExpired);
	
}





void OME_Set_Analysis_Inputs (OMEdb dbHandle, ome_id_t analysisID, char *attrNames, char *attrValues)
{
char query[OME_SQLBUFSIZE],message[256],inTableName[64];
OMEres res;
ome_id_t programID;

/*
* Make sure the analysisId is good, and if so, get the PROGRAM_ID.
*/

	sprintf (query,"SELECT program_ID FROM analyses where ANALYSIS_ID=%ld",analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not SELECT FROM ANALYSES table.");
		OME_Exit (dbHandle);
	}

	if (PQntuples(res) < 1)
	{
		OMEclearRes(res);
		OME_Error (OME_FATAL_ERROR,"Could not find specified ANALYSIS_ID");
		OME_Exit (dbHandle);
	}
	else if (PQntuples(res) > 1)
	{
		OMEclearRes(res);
		OME_Error (OME_FATAL_ERROR,"Database is corrupt: Specified ANALYSIS_ID is not unique !!!!!!");
		OME_Exit (dbHandle);
	}

	programID = atoi (PQgetvalue(res,0,0));
	OMEclearRes(res);

/*
* Get the input table for the program ID
*/
	OME_Get_Input_Table (dbHandle,programID ,inTableName);

/*
* Add the specified attributes and values to the table.
*/
	sprintf (query,"INSERT INTO %s (analysis_id,%s) VALUES (%ld,%s)",
					inTableName,attrNames,analysisID,attrValues);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not add input parameters to '%s' table.",inTableName);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);

	
}




void OME_Add_Attribute_Values (OMEdb dbHandle, ome_id_t featureID, ome_id_t analysisID, char *tableName, char *attrNames, char *attrValues)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];
/*
* This function creates an attribute for the feature by setting the specified attrNames in the
* specified tableName to the specified attrValues.  If the statement fails, its an OME_FATAL_ERROR!
* FIXME:  Need to check that the specified attribute is a legal one for this analysis.
*/
	sprintf (query,"INSERT INTO %s (attribute_of,analysis_id,%s) VALUES (%ld,%ld,%s)",
					tableName,attrNames,featureID,analysisID,attrValues);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);
}



/*
* This does an update on a single attribute, setting it to a given value for the given feature.
* The SQL statement is:
* UPDATE <tableName> SET <attrName> = <attrValue> WHERE attribute_of=<featureID> and analysisID=<analysisID>
* If the statement fails, its a fatal error.  No other checks are done.
* If no features are found, then there is no error.
* N.B.:  attrValue is a char*
*/
void OME_Set_Feature_Attribute (OMEdb dbHandle, ome_id_t featureID, ome_id_t analysisID, char *tableName, char *attrName, char *attrValue)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];

/*
* This does an update.
*/
	sprintf (query,"UPDATE %s SET %s = %s WHERE attribute_of = %ld AND analysis_id = %ld",
					tableName,attrName,attrValue,featureID,analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute UPDATE.  query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);
}


/*
* This does an update on a single attribute, setting it to a given value for the given feature.
* The SQL statement is:
* UPDATE <tableName> SET <attrName> = <attrValue> WHERE attribute_of=<featureID> and analysisID=<analysisID>
* If the statement fails, its a fatal error.  No other checks are done.
* If no features are found, then there is no error.
* N.B.:  attrValue is a long
*/
void OME_Set_Feature_Attribute_Long (OMEdb dbHandle, ome_id_t featureID, ome_id_t analysisID, char *tableName, char *attrName, long attrValue)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];

/*
* This does an update.
*/
	sprintf (query,"UPDATE %s SET %s = %ld WHERE attribute_of = %ld AND analysis_id = %ld",
					tableName,attrName,attrValue,featureID,analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute UPDATE.  query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);
}



long *OME_Get_Feature_Attributes_As_Longs (OMEdb dbHandle, ome_id_t *featureID, ome_id_t analysisID,char *tableName, char *attrName)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];
long numIDs=0,numCols=0;
ome_id_t *featureIDptr;
long *resultArray,*resultArrayPtr;
int i,j;

/*
* This function allocates memory to hold the results of the query.
* The Select is done one at a time to ensure that the order of attributes matches the
* order of feature IDs.  The array of featureIDs ends with featureID[n]=0
* Reurns NULL if error.  Caller MUST call free() on returned pointer!
* In this case, each select is cast as a long.
* If the select on a feature doesn't return a tuple, then the corresponding array element is set to 0.
* FIXME: There aught to be a better and faster way of doing this, and maybe some way to deal with NULLs
*/

/*
* Count the number of elements we have
*/
	featureIDptr = featureID;
	while (*featureIDptr++ != 0)
		numIDs++;

	if (!numIDs)
		return (NULL);

/*
* Do a select on the first ID.  This will tell us how wide the returned array is.
*/
	sprintf (query,"SELECT %s FROM %s where attribute_of=%ld AND analysis_id=%ld",
		attrName,tableName,featureID[0],analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	numCols = PQnfields(res);

/*
* Do a malloc.
*/
	resultArray = (long *) malloc (sizeof(long)*numCols*numIDs);
	if (!resultArray)
		return (NULL);
	resultArrayPtr = resultArray;

/*
* Put the result of the first search into resultArray.
*/
	for (i=0;i<numCols;i++)
		*resultArrayPtr++ = (PQntuples(res) > 0) ? atoi (PQgetvalue(res,0,i)) : 0;
	OMEclearRes(res);

/*
* Do the rest of the queries
*/
	for (i = 1; i < numIDs; i++)
	{
		sprintf (query,"SELECT %s FROM %s where attribute_of=%ld AND analysis_id=%ld",
			attrName,tableName,featureID[i],analysisID);
		res = OMEexecSQL(dbHandle,query);
		if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
		{
			OMEclearRes(res);
			sprintf (message,"Could not execute query: %s",query);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
			OME_Exit (dbHandle);
		}
		for (j=0;j<numCols;j++)
			*resultArrayPtr++ = (PQntuples(res) > 0) ? atoi (PQgetvalue(res,0,j)) : 0;

		OMEclearRes(res);
	}

	return (resultArray);
}




ome_id_t *OME_Get_Feature_IDs (OMEdb dbHandle, ome_id_t analysisID)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];
long numIDs=0;
long *resultArray,*resultArrayPtr;
int i;

/*
* This function allocates memory to hold the results of the query.
* The results of this query is an array of longs.
*/

/*
* Do the select.
*/
	sprintf (query,"SELECT feature_ID FROM features where analysis_id=%ld",analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	numIDs = PQntuples(res);

/*
* Do a malloc.
*/
	resultArray = (long *) malloc (sizeof(long)*numIDs);
	if (!resultArray)
		return (NULL);
	resultArrayPtr = resultArray;
/*
* Put tuples into the array.
*/
	for (i = 0; i < numIDs; i++)
		*resultArrayPtr++ = atoi (PQgetvalue(res,i,0));
	
	OMEclearRes(res);

	return (resultArray);
}






long OME_Get_Feature_Count (OMEdb dbHandle, ome_id_t analysisID)
{
OMEres res;
char query[OME_SQLBUFSIZE];
char message [256];
long numIDs=0;

	sprintf (query,"SELECT count(*) FROM features where analysis_id=%ld",analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not execute query: %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}

	numIDs = atoi (PQgetvalue(res,0,0));
	OMEclearRes(res);
	return (numIDs);
}












int OME_Get_ID_From_Menu (
	OMEdb dbHandle,
	char *IDColumn,
	char *selectStatement,
	char *extraItem,
	int extraMatch,
	char *prompt,
	char *result)
{
OMEres res;
int field,tuple,nFields,nTuples,lngth,resultField;
ome_id_t ID;
#define MAX_COLS 32
int colLngth[MAX_COLS];
char controlString[MAX_COLS][10];
char query[OME_SQLBUFSIZE];

	sprintf (query,"DECLARE mycursor CURSOR FOR %s",selectStatement);
	res = OMEexecSQL(dbHandle, query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		sprintf(result, "DECLARE CURSOR command failed");
		OMEclearRes(res);
		return(-1);
	}

	OMEclearRes(res);
	res = OMEexecSQL(dbHandle, "FETCH ALL in mycursor");
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		sprintf(result, "FETCH ALL command didn't return tuples properly");
		res = OMEexecSQL(dbHandle, "CLOSE mycursor");
		OMEclearRes(res);
		return(-1);
	}


	nFields = PQnfields(res);
	nTuples = PQntuples(res);
	if (nFields > MAX_COLS)
		{
		OMEclearRes(res);
		sprintf(result, "Too many columns in querry");
		res = OMEexecSQL(dbHandle, "CLOSE mycursor");
		OMEclearRes(res);
		return(-1);
		}

	resultField = PQfnumber(res,IDColumn);
	if (resultField < 0)
		{
		OMEclearRes(res);
		sprintf(result, "ID Column not in select statement");
		res = OMEexecSQL(dbHandle, "CLOSE mycursor");
		OMEclearRes(res);
		return(-1);
		}


	for (field=0;field<nFields;field++)
		{
		colLngth[field] = strlen (PQfname(res, field));
		for (tuple=0;tuple<nTuples;tuple++)
			{
			lngth = PQgetlength(res,tuple,field);
			if (lngth > colLngth[field]) colLngth[field] = lngth;
			}
		sprintf (controlString[field],"|%%-%ds ",colLngth[field]);
		fprintf(stdout,controlString[field], PQfname(res, field));
		}
	printf ("|\n+");
	for (field=0;field<nFields;field++)
		{
		for (tuple=0;tuple<colLngth[field];tuple++)
			printf ("-");
		printf ("-+");
		}
	printf ("\n");

	/* next, print out the instances */
	for (tuple = 0; tuple < nTuples; tuple++)
	{
		for (field = 0; field < nFields; field++)
			printf(controlString[field], PQgetvalue(res, tuple, field));
		printf("|\n");
	}
	printf ("\n");
	if (extraItem) printf ("%s\n",extraItem);
	ID=0;
	while (!ID)
		{
		printf (prompt);
		fflush (stdout);
		scanf ("%s",result);
		if (extraItem)
			if (!strncmp (result,extraItem,extraMatch)) ID = 0;
		for (tuple=0;tuple<nTuples;tuple++)
			if (!strcmp (PQgetvalue(res,tuple, resultField),result)) ID = atoi (result);
		}

	OMEclearRes(res);
	res = OMEexecSQL(dbHandle, "CLOSE mycursor");
	OMEclearRes(res);
	return (ID);
}


ome_id_t OME_Add_Dataset (OMEdb dbHandle,char *datasetName)
{
/*
* A dataset description is constructed from the datasetName, the current WD, the local host and the path.
* If the dataset description is not found in the database, then it will be added to the datase
* and the fields DATASET_ID, NAME, PATH, HOST, and INSERTED will be set.
* We call the user-interface function OME_Set_Dataset_Attributes to finish filling stuff in.
* If the dataset query is ambiguous, then the database is corrupted, and return FATAL_ERROR.
* We cannot have more than one dataset with the same name, host and path.
*/
char query[OME_SQLBUFSIZE],message[256];
OMEres res;
ome_id_t datasetID=0;
char localHost[256],datasetPath[256],name[256];

/*
* Oops.  Return error without abort.
*/
	if (!datasetName)
		return (-1);
	
	strcpy (name,datasetName);

	if (!OME_Get_Local_Dataset_Path (name,datasetPath))
	{
		sprintf (message,"Could not determine the absolute path of '%s'.",datasetName);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}

	if (!OME_Get_Local_Host (localHost) )
	{
		OME_Error (OME_FATAL_ERROR,"Could not determine the address of the local host");
		OME_Exit (dbHandle);
	}
#ifdef DEBUG
fprintf (stdout,"in OME_Add_Dataset: host name '%s'\n",localHost);
#endif

	sprintf (query,"SELECT dataset_id FROM datasets WHERE name='%s' AND path='%s' and host='%s'",
		name,datasetPath,localHost);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on DATASETS table.");
		OMEclearRes(res);
		OME_Exit (dbHandle);
	}
	
	
	if (PQntuples(res) > 1)
	{
		OMEclearRes(res);
		sprintf (message,"The OME dabase contains more than one dataset with NAME='%s', PATH='%s' and HOST='%s'",
				name,datasetPath,localHost);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}



	else if (PQntuples(res) < 1)
	{
		OMEclearRes(res);
		res = OMEexecSQL(dbHandle,"SELECT nextval('DATASET_SEQ')");
		if (PQntuples(res) != 1)
		{
			OMEclearRes(res);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not determine next value for DATASET_SEQ sequence");
			OME_Exit (dbHandle);
		}

		datasetID = atoi (PQgetvalue(res,0,0));
		OMEclearRes(res);

		sprintf (query,"INSERT INTO datasets (\
						DATASET_ID,NAME,PATH,HOST,INSERTED)\
			VALUES (%ld,'%s','%s','%s',CURRENT_TIMESTAMP)",
			datasetID,name,datasetPath,localHost);
		res = OMEexecSQL(dbHandle,query);
		if (PQresultStatus(res) != PGRES_COMMAND_OK)
		{
			OMEclearRes(res);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not add entry for this dataset into DATASETS table.");
			OME_Exit (dbHandle);
		}
		OME_Set_Dataset_Attributes (dbHandle,datasetID);
		OMEclearRes(res);
	}
	else
	{
		datasetID = atoi (PQgetvalue(res,0,0));
		OMEclearRes(res);
	}

	return (datasetID);
}




ome_id_t OME_Get_Dataset_ID (OMEdb dbHandle,char *datasetName)
{
/*
* A dataset description is constructed from the datasetName, the current WD, the local host and the path.
* If the number of datasets matching these criteria is more or less than one, return 0 (an invalid ID)
* Otherwise, return the ID.
*/
char query[OME_SQLBUFSIZE],message[256];
OMEres res;
ome_id_t datasetID=0;
char localHost[256],datasetPath[256],name[256];

/*
* Oops.  Return error without abort.
*/
	if (!datasetName)
	{
#ifdef DEBUG
fprintf (stderr,"in OME_Get_Dataset_ID: datasetName is NULL!\n");
#endif
		return (0);
	}
	strcpy (name,datasetName);

	if (!OME_Get_Local_Dataset_Path (name,datasetPath))
	{
		sprintf (message,"Could not determine the absolute path of '%s'.",datasetName);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}
#ifdef DEBUG
fprintf (stdout,"in OME_Get_Dataset_ID: dataset name '%s', path '%s'\n",name,datasetPath);
#endif

	if (!OME_Get_Local_Host (localHost) )
	{
		OME_Error (OME_FATAL_ERROR,"Could not determine the address of the local host");
		OME_Exit (dbHandle);
	}
#ifdef DEBUG
fprintf (stdout,"in OME_Get_Dataset_ID: host name '%s'\n",localHost);
#endif

	sprintf (query,"SELECT dataset_id FROM datasets WHERE name='%s' AND path='%s' and host='%s'",
		name,datasetPath,localHost);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on DATASETS table.");
		OME_Exit (dbHandle);
	}
	
	
	if (PQntuples(res) == 1)
		datasetID = atoi (PQgetvalue(res,0,0));
	OMEclearRes(res);
#ifdef DEBUG
fprintf (stdout,"in OME_Get_Dataset_ID: datasetID=%ld\n",datasetID);
fflush (stdout);
#endif
	return (datasetID);
}



FILE *OME_Open_Dataset_File (OMEdb dbHandle, ome_id_t datasetID,char *rwString)
{
FILE *datasetFile=NULL;
char datasetPath[256];
char query[OME_SQLBUFSIZE];
OMEres res;

	sprintf (query,"SELECT name,path,host FROM datasets WHERE dataset_id=%ld",datasetID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on DATASETS table.");
		OME_Exit (dbHandle);
	}

	if (PQntuples(res) == 1)
	{
		strcpy(datasetPath,PQgetvalue (res,0,1) );
		strcat (datasetPath,PQgetvalue (res,0,0) );
#ifdef DEBUG
printf("Opening dataset file: %s\n",datasetPath);
#endif
		datasetFile = fopen (datasetPath,rwString);
	}
	
	OMEclearRes(res);
	return (datasetFile);

		
}

void OME_Modify_Dataset (OMEdb dbHandle, ome_id_t datasetID,char *attributes)
{
char query[OME_SQLBUFSIZE];
OMEres res;

	sprintf (query,"UPDATE datasets SET %s WHERE dataset_id=%ld",attributes,datasetID);
    printf("Query = %s\n", query);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on DATASETS table.");
		OME_Exit (dbHandle);
	}

	OMEclearRes(res);
}

void OME_Add_Attributes (OMEdb dbHandle, char *tableName,char *attributes,char *values)
{
char query[OME_SQLBUFSIZE],message[256];
OMEres res;

	sprintf (query,"INSERT INTO %s (%s) VALUES (%s)",tableName,attributes,values);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		sprintf (message,"Could not %s",query);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,message);
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);
}

char *OME_Get_Attributes (OMEdb dbHandle, char *tableName,char *attributes,char *where)
{
/*
* first call, attributes are a string of comma-separated attribute names.  This sets up a cursor.
* In subsequent calls, OME_Get_Attributes returns a pointer to attributes, which now contains the results
* of the query.  Keep calling OME_Get_Attributes, and it will return subsequent rows.  If there are no more
* rows, OME_Get_Attributes returns NULL.
*/
static int tuple=0,nTuples=0;
static OMEres res=NULL;
int field,nFields=0;
char query[OME_SQLBUFSIZE],*returnVal=NULL;

	if (attributes && tableName && where)
	{
		if (res)
			{
			OMEclearRes(res);
			res = NULL;
			tuple = 0;
			nTuples=0;
			}
			
			
		sprintf (query,"SELECT %s FROM %s WHERE %s",attributes,tableName,where);
	
		res = OMEexecSQL(dbHandle,query);
		if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
		{
			OMEclearRes(res);
			sprintf (query,"Could not execute querry on %s table.",tableName);
			OME_DB_Error (OME_FATAL_ERROR,dbHandle,query);
			OME_Exit (dbHandle);
		}
	}

	else if (attributes && res && (tuple < nTuples) )
	{
		nFields = PQnfields(res)-1;
		strcpy (attributes,"");
		for (field=0;field < nFields; field++)
		{
			strcat (attributes,PQgetvalue (res,tuple,field) );
			strcat (attributes,",");
		}
		strcat (attributes,PQgetvalue (res,tuple,field+1) );
		tuple++;
		returnVal = attributes;
	}
	
	else
	{
		if (attributes)
			strcpy (attributes,"");
		returnVal = NULL;
		OMEclearRes(res);
		res = NULL;
		tuple = 0;
	}

	return (returnVal);
}





void OME_Set_Experimenter_Attributes (OMEdb dbHandle, ome_id_t userID)
{
}

void OME_Set_Analysis_Attributes (OMEdb dbHandle, ome_id_t analysisID)
{
}

void OME_Set_Dataset_Attributes (OMEdb dbHandle, ome_id_t datasetID)
{
}

ome_id_t OME_Add_Feature (OMEdb dbHandle, ome_id_t analysisID)
{
char query[OME_SQLBUFSIZE];
OMEres res;
ome_id_t featureID;

/*
* This adds an entry into the FEATURES table, and returns the FEATURE_ID.
*/

/*
* Find the analysisID in the database.  Return 0 if not found.
*/
	if (analysisID == 0)
		return (0);

	sprintf (query,"SELECT analysis_id FROM analyses WHERE analysis_id=%ld",analysisID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on ANALYSES table.");
		OMEclearRes(res);
		OME_Exit (dbHandle);
	}
	
	
	if (PQntuples(res) != 1)
	{
		OMEclearRes(res);
		return (0);
	}
	OMEclearRes(res);

/*
* Get the feature ID.
*/
	res = OMEexecSQL(dbHandle,"SELECT nextval('FEATURE_SEQ')");
	if (PQntuples(res) != 1)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not determine next value for FEATURE_SEQ sequence");
		OME_Exit (dbHandle);
	}

	featureID = atoi (PQgetvalue(res,0,0));
	OMEclearRes(res);

/*
* Add the feature.
*/
	sprintf (query,"INSERT INTO features (feature_id,analysis_id) VALUES (%ld,%ld)",featureID,analysisID);
	
	res = OMEexecSQL(dbHandle,query);
	if (PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not add entry into ANALYSES table.");
		OME_Exit (dbHandle);
	}
	OMEclearRes(res);

	return (featureID);
}



long Get_Num_Timepoints (OMEdb dbHandle, ome_id_t datasetID)
{
char query[OME_SQLBUFSIZE];
OMEres res;
long numtimes;

	sprintf (query,"SELECT num_times FROM attributes_dataset_xyzwt WHERE dataset_id=%ld",datasetID);
	res = OMEexecSQL(dbHandle,query);
	if (!res || PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		OMEclearRes(res);
		OME_DB_Error (OME_FATAL_ERROR,dbHandle,"Could not execute querry on DATASETS table.");
		OME_Exit (dbHandle);
	}

	numtimes = atoi (PQgetvalue(res,0,0));

	OMEclearRes(res);
	
	return (numtimes);
}
