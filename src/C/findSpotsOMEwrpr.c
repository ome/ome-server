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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct columnKey {
char columnLabel[64];
char OME_Table[64];
char OME_Field[64];
char columnValue[64];
int wave;
} columnKey;


void Trim_Label (char *label);
int Get_Num_Columns (char *tuple);
columnKey *Get_Column_Key (char *fileName, char *columnLabels);
char *Get_Column_Value (char *tuple,int colNumber,char *result);
void Do_Line (OMEdb dbHandle,long analysisID, int waves[], char *inputLine,columnKey *theColumnKey);
char Match_Columns (char *keyColValue, char *colValue);
void Set_Column_Values (char *inputLine,columnKey *theColumnKey);
void Do_AutoInsert (OMEdb dbHandle,long featureID,long analysisID,char *tableName,columnKey *theColumnKey);
void Set_Table_Attributes_Values (char *tableName,columnKey *theColumnKey,char *attributesSQL,char *valuesSQL);
columnKey *Make_Column_Mappings (FILE *tempFile,char *columnKeyPath,int waves[]);
void Get_Command_Line (OMEdb dbHandle,int argc, char *argv[],char *tempFileName,
			char *directoryPath, char *commandString);
OMEdb Get_DB_Connection (int argc,char *argv[]);
void Get_Temp_File (char *tempFileName);
long Get_Analysis_ID (OMEdb dbHandle,int argc,char *argv[], 
		char *directoryPath, char *attrNames, char *attrValues,long *programID,long *datasetID);


/*
* There are as many columnKeys as there are columns in the input table.  If there is no
* corresponding OME mapping fot the input column, then the OME_Table and OME_Field are blank.
* The columnLabel field contains the column label exactly as it appears in the input table - the
* columnLabels string, not the mappings in fileName.  The columnLabel is set wether or not there
* is an OME mapping.  The last columnLabel is the one before (*columnLabel == '\0') .
*/
columnKey *Get_Column_Key (char *fileName, char *columnLabels)
{
FILE *columnKeyFP;
char inputLine[1024];
char keyColValue[256],colValue[256];
int nCols,column=0;
columnKey *theColumnKey;
char columnsMatch=0;

	if (!fileName || !columnLabels)
		return (NULL);

	columnKeyFP = fopen (fileName,"r");
	if (!columnKeyFP)
		return (NULL);

	nCols = Get_Num_Columns (columnLabels);
#ifdef DEBUG
fprintf (stdout,"Get_Column_Key: nCols=%d\n",nCols);
fflush (stdout);
#endif
	if (!(theColumnKey = (columnKey *)malloc (sizeof (columnKey) * (nCols+1) )) )
	{
		fclose (columnKeyFP);
		return (NULL);
	}

	while ( Get_Column_Value (columnLabels,column,colValue) )
	{
#ifdef DEBUG
fprintf (stdout,"Get_Column_Key: colValue=%s\n",colValue);
fflush (stdout);
#endif
		rewind (columnKeyFP);
		columnsMatch = 0;
		while (!feof (columnKeyFP) && !columnsMatch)
		{
			fgets (inputLine,1023,columnKeyFP);
			if (!feof (columnKeyFP) )
			    Get_Column_Value (inputLine,0,keyColValue);
			columnsMatch = Match_Columns (keyColValue,colValue);
		}
		if (columnsMatch)
		{
			Get_Column_Value (inputLine,1,theColumnKey[column].OME_Table);
			Get_Column_Value (inputLine,2,theColumnKey[column].OME_Field);
		}
		else
		{
			strcpy (theColumnKey[column].OME_Table,"");
			strcpy (theColumnKey[column].OME_Field,"");
		}
		strcpy (theColumnKey[column].columnLabel,colValue);
		theColumnKey[column].wave = 0;

		column++;
	}

	
#ifdef DEBUG
fprintf (stdout,"Get_Column_Key: column=%d\n",column);
fflush (stdout);
#endif
	strcpy (theColumnKey[column].columnLabel,"");
	strcpy (theColumnKey[column].OME_Table,"");
	strcpy (theColumnKey[column].OME_Field,"");
	strcpy (theColumnKey[column].columnValue,"");
	theColumnKey[column].wave = 0;
	fclose (columnKeyFP);
#ifdef DEBUG
fprintf (stdout,"Get_Column_Key: RETURN\n");
fflush (stdout);
#endif
	return (theColumnKey);
}

char Match_Columns (char *keyColValue, char *colValue)
{
/*
* Match everything but '?', which is a non-matching place-holder
* '?' will match any single character.
*/
if (!keyColValue || !colValue)
	return (0);
/*
#ifdef DEBUG
fprintf (stdout,"keyColValue = '%s'\tcolValue = '%s'",keyColValue,colValue);
fflush (stdout);
#endif
*/
	while ( *keyColValue && *colValue && ( (*keyColValue == *colValue) || (*keyColValue == '?') ) )
		{
		keyColValue++;
		colValue++;
		}
/*
#ifdef DEBUG
if ( (*keyColValue == *colValue) || (*keyColValue == '?') )
fprintf (stdout,"---MATCH\n");
else
fprintf (stdout,"---NO MATCH\n");
fflush (stdout);
#endif
*/
	return ( (*keyColValue == *colValue) || (*keyColValue == '?') );

}


void Trim_Label (char *label)
{
char *chrPtr;

		chrPtr = label;
		while (isspace(*chrPtr)) chrPtr++;
		strcpy (label,chrPtr);
		chrPtr = label+(strlen(label)-1);
		while (isspace(*chrPtr)) chrPtr--;
		*++chrPtr = '\0';
}

int Get_Num_Columns (char *tuple)
{
int nCols=0;
char line[1024];
	
	while (Get_Column_Value (tuple,nCols,line) ) nCols++;
	return (nCols);
}

/*
* Column format:
*<white space><non-white-space=Column value><\t><white space>
* i.e.:  Any ammount of white space followed by column value, followed by a tab, followed
* by any ammount of white space.
* This allows column values to have internal spaces as long as they begin with non-whitespace
* and end with a tab.
*/
char *Get_Column_Value (char *tuple,int colNumber,char *result)
{
char *chrPtr,*resPtr;
int col=0;

	if (colNumber < 0) return (NULL);
	chrPtr = tuple;
	resPtr = result;

	if (!chrPtr) return (NULL);
	
	while (*chrPtr != '\0' && isspace(*chrPtr) ) chrPtr++;
	if (*chrPtr == '\0') return (NULL);

	while (col < colNumber)
		{
		while (*chrPtr != '\0' && *chrPtr != '\t') chrPtr++;
		if (*chrPtr == '\0') return (NULL);

		while (*chrPtr != '\0' && isspace(*chrPtr)) chrPtr++;
		if (*chrPtr == '\0') return (NULL);
		col++;
		}
	
	while (*chrPtr != '\0' && *chrPtr != '\t') *resPtr++ = *chrPtr++;
	*resPtr++ = '\0';

	Trim_Label (result);

	return (result);
	
}





void Setup_Spectral_Info (int waves[], columnKey *theColumnKey)
{
int testWave=0,nWaves=0,column=0,inWave;


/*
* Count number of waves.
*/
	waves[0] = 0;
	while (*(theColumnKey[column].columnLabel) != '\0')
	{
		if (!strcmp (theColumnKey[column].OME_Table,"SIGNAL"))
		{
			sscanf (theColumnKey[column].columnLabel,"%*[^[][%d]",&inWave);
			theColumnKey[column].wave = inWave;
#ifdef DEBUG
fprintf (stdout,"theColumnKey[%d].columnLabel='%s', wave=%d\n",column,theColumnKey[column].columnLabel,inWave);
fflush (stdout);
#endif

			for (testWave = 0; testWave < nWaves && waves[testWave] != inWave; testWave++);
			if (testWave == nWaves)
			{
				waves[nWaves] = inWave;
				nWaves++;
			}
		}
		column++;
	}
	waves[nWaves] = 0;
}













void Do_Line (OMEdb dbHandle,long analysisID, int waves[], char *inputLine,columnKey *theColumnKey)
{
char attributesSQL[256];
char valuesSQL[256];
char value[256];
int i,wave;
long featureID=0;

/*
#ifdef DEBUG
fprintf (stdout,"Entered Do_Line\n");
fflush (stdout);
#endif
*/
	Set_Column_Values (inputLine,theColumnKey);
	strcpy (valuesSQL,"");
	strcpy (attributesSQL,"");
	featureID = OME_Add_Feature (dbHandle,analysisID);
	if (!featureID)
	{
		OME_Error (OME_FATAL_ERROR,"Could not add a feature.");
		OME_Exit (dbHandle);
	}


	Do_AutoInsert (dbHandle,featureID,analysisID,"TIMEPOINT",theColumnKey);
	Do_AutoInsert (dbHandle,featureID,analysisID,"THRESHOLD",theColumnKey);
	Do_AutoInsert (dbHandle,featureID,analysisID,"LOCATION",theColumnKey);
	Do_AutoInsert (dbHandle,featureID,analysisID,"EXTENT",theColumnKey);




/*
* Add any spectral features.
* These we do by hand, because the wavelegth of the feature is specified
* in the column label, not in a column value.
*/
	for (wave=0; waves[wave] > 0 ; wave++)
	{
		strcpy (valuesSQL,"");
		strcpy (attributesSQL,"");
		for (i=0; *(theColumnKey[i].columnLabel) ; i++)
			if (theColumnKey[i].wave == waves[wave])
			{
				strcat (attributesSQL,theColumnKey[i].OME_Field);
				strcat (attributesSQL,",");
				strcat (valuesSQL,theColumnKey[i].columnValue);
				strcat (valuesSQL,",");
			}


		strcat (attributesSQL,"WAVELENGTH");
		sprintf (value,"%d",waves[wave]);
		strcat (valuesSQL,value);
		OME_Add_Attribute_Values (dbHandle,featureID,analysisID,"SIGNAL",attributesSQL,valuesSQL);

	}

/*
#ifdef DEBUG
fprintf (stdout,"Do_Line: Done.\n");
fflush (stdout);
#endif
*/
}







void Do_AutoInsert (OMEdb dbHandle,long featureID,long analysisID,char *tableName,columnKey *theColumnKey)
{
char attributesSQL[256];
char valuesSQL[256];
/*
* Get the attribute names and values.
*/
	Set_Table_Attributes_Values (tableName,theColumnKey,attributesSQL,valuesSQL);

/*
* Add them to the feature
*/
	OME_Add_Attribute_Values (dbHandle,featureID,analysisID,tableName,attributesSQL,valuesSQL);

}


void Set_Table_Attributes_Values (char *tableName, columnKey *theColumnKey, char *attributesSQL,char *valuesSQL)
{
int i;

	strcpy (attributesSQL,"");
	strcpy (valuesSQL,"");
	for (i=0; *(theColumnKey[i].columnLabel) ; i++)
		if (!strcmp (theColumnKey[i].OME_Table,tableName))
		{
			if (*attributesSQL)
			{
				strcat (attributesSQL,",");
				strcat (valuesSQL,",");
			}
			strcat (attributesSQL,theColumnKey[i].OME_Field);
			strcat (valuesSQL,theColumnKey[i].columnValue);
		}
}


void Set_Column_Values (char *inputLine,columnKey *theColumnKey)
{
int i;
char value[256];

/*
#ifdef DEBUG
fprintf (stdout,"Entered Set_Column_Values\n");
fflush (stdout);
#endif
*/
	for (i=0; *(theColumnKey[i].columnLabel) ; i++)
	{
/*
#ifdef DEBUG
fprintf (stdout,"theColumnKey[%d].columnLabel=%s\t",i,theColumnKey[i].columnLabel);
fflush (stdout);
#endif
*/
		if (Get_Column_Value (inputLine,i,value))
			strcpy (theColumnKey[i].columnValue,value);
		else
		{
			fprintf (stderr,"NULL column value in Set_Column_Values!\n");
			exit (-1);
		}
/*
#ifdef DEBUG
fprintf (stdout,"theColumnKey[%d].columnValue=%s\n",i,theColumnKey[i].columnValue);
fflush (stdout);
#endif
*/
	}
}




OMEdb Get_DB_Connection (int argc,char *argv[])
{
OMEdb dbHandle;
char theConnString[128]="";
int i;
/*
* Read the OMEdbConnect option.  This will contain the connection
* string.  If the option wasn't specified, then try to get the string
* from the user's .OMErc file in their home directory.
*/
	for (i=0;i<argc;i++)
		if (!strncmp (argv[i],"-OMEdbConn",10))
			strcpy (theConnString,strchr(argv[i],'=')+1);

/*
* Make a connection to the database.
* The connection is made by looking in .OMErc (ususally in ~/.OMErc) for
* database connection parameters.
*/
	if (*theConnString)
		dbHandle = OME_Get_DB_Handle_From_String (theConnString);
	else
		dbHandle = OME_Get_DB_Handle ();

	if (dbHandle)
		return (dbHandle);
	else
		exit (-1);
}

void Get_Temp_File (char *tempFileName)
{
FILE *fp;
/*
* get a name for a temporary file, and make sure we can open it for writing.
*/
	if (!tmpnam (tempFileName))
	{
		fprintf (stderr,"Could not generate temporary file name!\n");
		exit (-1);
	}
	if (!(fp = fopen (tempFileName,"w+")))
	{
		fprintf (stderr,"Could not open temporary file '%s'!\n",tempFileName);
		exit (-1);
	}
	fclose (fp);
	fp=NULL;
}




long Get_Analysis_ID (OMEdb dbHandle,int argc,char *argv[], 
		char *directoryPath, char *attrNames, char *attrValues,long *programID,long *datasetID)
{
char progName[]="findSpots";  /* this is the OME program name. It is unique */
char message[256];
int tStart=0,tStop=0;
int spotWaveLngth,minSpotVol,numtimes;
int i;
FILE *fp;

/*
* The various filenames that we specified are relative to the path name of this executable.
* since we didn't necessarily invoke this program from the executable's directory, we need
* to prepend this executable's path to the filenames.
*/

/*
* Get the programID
*/
	*programID = OME_Get_Program_ID (dbHandle,progName);
	if (!(*programID))
	{
		sprintf (message,"Program '%s' is not registered with OME.",progName);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (dbHandle);
	}


/*
* Get the executable program's path from OME.
* This is the path to this very executable!.
*/
	OME_Get_Program_Path (dbHandle,*programID,directoryPath);

/*
* Get the spot wavelegth and the minimum spot volume.
*/
	
	sscanf (argv[2],"%d",&spotWaveLngth);

	sscanf (argv[4],"%d",&minSpotVol);




/*
* Read the timespan option
*/
	for (i=5;i<argc;i++)
		{
		if (!strncmp (argv[i],"-time",5))
			sscanf (argv[i]+5,"%d-%d",&tStart,&tStop);
		}
	tStart--;
	tStop--;
	if (tStart < 0)
		tStart = 0;


	*datasetID = OME_Get_Dataset_ID (dbHandle,argv[1]);
	if (!(*datasetID))
	{
		if ( !(*datasetID = OME_Add_Dataset (dbHandle,argv[1])))
		{
			sprintf (message,"Could not create dataset '%s' in OME",argv[1]);
			OME_Error (OME_FATAL_ERROR,message);
			OME_Exit (dbHandle);
		}
		fp = OME_Open_Dataset_File (dbHandle,*datasetID,"r");
		if (!fp)
		{
			sprintf (message,"Could not open dataset file '%s'",argv[1]);
			OME_Error (OME_FATAL_ERROR,message);
			OME_Exit (dbHandle);
		}
		fclose (fp);
		OME_Import_DV (dbHandle, *datasetID);
	}
#ifdef DEBUG
fprintf (stdout,"DatasetID: %ld\n",*datasetID);
#endif

/*
* Read the number of timepoints in the dataset.
*/
	numtimes = Get_Num_Timepoints (dbHandle, *datasetID);
#ifdef DEBUG
fprintf (stdout,"numtimes: %d\n",numtimes);
#endif

	if ( !(tStop > tStart) )
		tStop = numtimes;

/*
* Before registering, we check if a duplicate analysis exists.  If it does then
* we return (0), which should result in an exit.
* If the analysis doesn't exist, we get a new one, and proceed with running the program.
*/
	sprintf (attrNames,"TIME_START,TIME_STOP,WAVELENGTH,THRESHOLD,MIN_SPOT_VOL");
	sprintf (attrValues,"%d,%d,%d,'%s',%d",tStart,tStop,spotWaveLngth,argv[3],minSpotVol);
	return (OME_Get_Analysis_ID_From_Inputs (dbHandle,*programID,*datasetID,attrNames,attrValues));

}


void Get_Command_Line (OMEdb dbHandle,int argc, char *argv[],char *tempFileName,
			char *directoryPath, char *commandString)
{
char executablePath[256];
char executableName[]="findSpotsDB";              /* this is a path relative to the executable */
int i;


	sprintf (executablePath,"%s%s",directoryPath,executableName);
	

	strcpy (commandString,executablePath);
	for (i=1;i<argc;i++)
	{
		if (strncmp(argv[i],"-OMEdbConn",10))
			{
	  		strcat (commandString," ");
	  		strcat (commandString,argv[i]);
	  		}
	}

/*
* Set the output arguments
*/
	strcat (commandString," -db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v > ");
	strcat (commandString,tempFileName);

}



columnKey *Make_Column_Mappings (FILE *tempFile,char *columnKeyPath,int waves[])
{
columnKey *theColumnKey;
char inputLine[1024];

	fgets (inputLine,1023,tempFile);
#ifdef DEBUG
fprintf (stdout,"%s\n",inputLine);
fflush (stdout);
#endif

	if (!(theColumnKey = Get_Column_Key (columnKeyPath,inputLine)) )
	{
		fprintf (stderr,"Could not generate column key from key file '%s'\n",columnKeyPath);
		exit (-1);
	}

#ifdef DEBUG
fprintf (stdout,"Back from Get_Column_Key\n");
fflush (stdout);
#endif
	
	Setup_Spectral_Info (waves,theColumnKey);
#ifdef DEBUG
fprintf (stdout,"Back from Setup_Spectral_Info\n");
fflush (stdout);
#endif
	return (theColumnKey);
}







int main (int argc, char **argv)
{
OMEdb dbHandle;
long analysisID,programID,datasetID;
char columnKeyFile[]="findspotsOMEcolumns";       /* this is a path relative to the executable */
char columnKeyPath[256];
char directoryPath[256];

char inputLine[1024];
columnKey *theColumnKey;
int waves[1024];

FILE *tempFile;
char tempFileName[L_tmpnam];
char commandString[512];

char attrValues[256];
char attrNames[256];


#ifdef DEBUG
{
static char bufOut[BUFSIZ],bufErr[BUFSIZ];
/*
fclose (stdout);
fclose (stderr);
stdout = fopen ("/tmp/findSpotsOMEwrpr.stdout", "w");
stderr = fopen ("/tmp/findSpotsOMEwrpr.stderr", "w");
*/
setvbuf (stdout, bufOut, _IONBF, BUFSIZ);
setvbuf (stderr, bufErr, _IONBF, BUFSIZ);
}
#endif

/*
* First, make sure we can get a database connection.
* This function will exit (-1) on error.
*/
	dbHandle = Get_DB_Connection (argc,argv);

/*
* Check if all this has been done before.  This function checks if this program was
* previously run with the same inputs on the same dataset.  In order to do the check,
* it has to parse the command line arguments and generate everything needed to register
* the analysis.  Since we don't want to do all that again, this program returns the
* arguments we will pass to OME_Register_Analysis if we end up running the program.
*/
	analysisID = Get_Analysis_ID (dbHandle,argc,argv,directoryPath,attrNames,attrValues,&programID,&datasetID);
#ifdef DEBUG
fprintf (stdout,"AnalysisID: %ld\n",analysisID);
fflush (stdout);
#endif

	if (analysisID && ! OME_Expired_Analysis(dbHandle,analysisID))
	{
		OME_DB_Finish (dbHandle);
	/*
	* Exit without error.  FIXME (?)
	*/
		exit (analysisID);
	}

/*
* Get a temporary file name and make sure we can write to it.
* This function will exit (-1) on error.
*/
	Get_Temp_File (tempFileName);

/*
* Generate a command line to execute the program.
* Don't execute it yet.
*/
	Get_Command_Line (dbHandle,argc,argv,tempFileName,directoryPath,commandString);

/*
* Close the database connection for now.
	OME_DB_Finish (dbHandle);
*/


/*
* Execute the program, sending the output to a temporary file.
* FIXME:
* In the future, this program should run as SUID root, then set its
* UID, GID, (and effective UID and GID) to the user as authenticated by the caller.
* Then it should do a fork and an execv.
*/
#ifdef DEBUG
fprintf (stdout,"commandString: %s\n",commandString);
fflush (stdout);
#endif

	if (system (commandString))
	{
		fprintf (stderr,"Problem executing analysis.");
		exit (-1);
	}


/*
* Get the output tables for this program.
* Get the column order, and the input column -> OME table/column mapping.
* The returned array of columnKey structures has the input column labels (for posterity mainly),
* and the corresponding OME table/column mappings in the order in which they appear in the input.
* By input here we mean the output of findspots.  The output of this program is stored in the database.
*/
	tempFile = fopen (tempFileName,"r");

	sprintf (columnKeyPath,"%s%s",directoryPath,columnKeyFile);

	theColumnKey = Make_Column_Mappings (tempFile,columnKeyPath,waves);
#ifdef DEBUG
{
int fooCount;
for (fooCount=0;*(theColumnKey[fooCount].columnLabel);fooCount++)
	fprintf (stdout,"%d:\t%s\t%s\t%s\t%d\n",fooCount,
		theColumnKey[fooCount].columnLabel,
		theColumnKey[fooCount].OME_Table,
		theColumnKey[fooCount].OME_Field,
		theColumnKey[fooCount].wave);
}
fflush (stdout);
#endif



/*
* Re-make the connection to the database.
	dbHandle = Get_DB_Connection (argc,argv);
*/
#ifdef DEBUG
if (PQstatus(dbHandle) == CONNECTION_OK)
	fprintf (stdout,"Still connected after program execution.\n");
else
{
	fprintf (stdout,"Connection dropped.  Attempting reset...\n");
	PQreset(dbHandle);
	if (PQstatus(dbHandle) == CONNECTION_OK)
		fprintf (stdout,"Connection reset!\n");
	else
	{
		fprintf (stdout,"Failed to reset the connection - EXIT\n");
		exit (-1);
	}
	
}
#endif
	analysisID = OME_Register_Analysis (dbHandle,programID,datasetID,attrNames,attrValues);

/*
* Loop through the input lines, and send stuff to the database.
*/
	fgets (inputLine,1023,tempFile);
#ifdef DEBUG
fprintf (stdout,"%s\n",inputLine);
fflush (stdout);
#endif
	while (!feof (tempFile) )
	{
		Do_Line (dbHandle, analysisID,waves,inputLine,theColumnKey);
		fgets (inputLine,1023,tempFile);
	}



/*
* close and unlink the temporary file.
*/
	fclose (tempFile);
	unlink (tempFileName);
	OME_DB_Finish (dbHandle);
	return (analysisID);
}

