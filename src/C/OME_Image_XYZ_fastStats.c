/*
# Copyright (C) 2002 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

typedef struct stats {
	unsigned int min,max;
	float mean,geomean,sigma;
	float centroid_x,centroid_y,centroid_z;
	float sum_i, sum_i2,sum_log_i;
	float sum_xi,sum_yi,sum_zi;
	float numSamples;
} statsStruct;
typedef statsStruct *statsPtr;




char *get_param (char **cgivars, char*param);
int inList(char **cgivars, char *str);
char x2c(char *what);
void unescape_url(char *url);
char **getcgivars(void);
char **getCLIvars(int argc, char **argv);
void usage(int argc, char **argv);

void Get_Image_Stats (char *dims);
void Zero_Accumulators (statsPtr theStats);
void Load_Accumulators (statsPtr theStats, statsPtr sums, unsigned long numSamples);
void Dump_Stats (statsPtr theStats, unsigned int theW, unsigned int theT);

int main (int argc, char **argv)
{
	int i;
	char *dims;
	char isCGI=0;
	char **cgivars;

	if (argc > 1) {
		cgivars = getCLIvars(argc,argv);
	} else {
		cgivars = getcgivars();
		if (cgivars) isCGI = 1;
	}
	if (!cgivars) {
		usage(argc,argv);
		exit (-1);
	}
		
	dims = get_param (cgivars,"Dims");
	if (!dims) {
		fprintf (stderr,"Dims parameter not set.\n");
		usage(argc,argv);
		exit (-1);
	}
	
	
	if (isCGI)
		fprintf (stdout,"Content-type: text/plain\n\n");

	fprintf (stdout,"Wave\tTime\tMin\tMax\tMean\tGeoMean\tSigma\tCentroid_x\tCentroid_y\tCentroid_z\n");
	/* This dumps stuff directly on stdout */
	Get_Image_Stats (dims);

	for(i=0; cgivars[i]; i++)
		free (cgivars[i]);

	free (cgivars);
	
	return (0);
}





void Get_Image_Stats (char *dims)
{
	unsigned int numX, numY, numZ, numW, numT, numB;
	float sum_i,sum_i2,sum_log_i,sum_xi,sum_yi,sum_zi;
	int rowsPerChunk;
	int theZ, theW, theT, i, min, max;
	int numInts, numStackStats, numFloats;
	statsPtr planeStats,planeStatsPtr,theStatsPtr;
	statsStruct theStats;
	unsigned int numSamples;

	numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&numX,&numY,&numZ,&numW,&numT,&numB);
	if (numInts < 6 || numX < 1 || numY < 1 || numZ < 1 || numW < 1 || numT < 1 || numB < 1) {
		fprintf (stderr,"All 6 dimension sizes (X,Y,Z,W,T,NumBytes) must be > 0: #dims=%d, Dims=%s\n",numInts,dims);
		exit (-1);
	}
	
	numStackStats = numZ * numW * numT;
	planeStats = (statsPtr) malloc (numStackStats * sizeof (statsStruct) );
	for (i = 0; i < numStackStats; i++) {
		numFloats = fscanf (stdin,"%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,%f",&theZ,&theW,&theT,&min,&max,&sum_i,&sum_i2,&sum_log_i,&sum_xi,&sum_yi,&sum_zi);
		if (numFloats < 6) {
			fprintf (stderr,"Must have 6 sums, found %d\n",numFloats);
			exit (-1);
		}
		
		if (theZ < 0 || theZ >= numZ || theW < 0 || theW >= numW || theT < 0 || theT >= numT) {
			fprintf (stderr,"Dimensions out of range! (Z,W,T) = (%d,%d,%d).  Dimensions = (%d,%d,%d)\n",theZ,theW,theT,numZ,numW,numT);
			exit (-1);
		}
		theStatsPtr = planeStats+ ( ((theT*numW) + theW)*numZ + theZ);
		theStatsPtr->min        = min;
		theStatsPtr->max        = max;
		theStatsPtr->sum_i      = sum_i;
		theStatsPtr->sum_i2     = sum_i2;
		theStatsPtr->sum_log_i  = sum_log_i;
		theStatsPtr->sum_xi     = sum_xi;
		theStatsPtr->sum_yi     = sum_yi;
		theStatsPtr->sum_zi     = sum_zi;
	}


	rowsPerChunk = numY;
	numSamples = numX*rowsPerChunk;
	planeStatsPtr = planeStats;
	Zero_Accumulators (&theStats);

	for (theT = 0; theT < numT; theT++) {
		for (theW = 0; theW < numW; theW++) {
			Zero_Accumulators (&theStats);
			for (theZ=0; theZ < numZ; theZ++) {
				Load_Accumulators (&theStats, planeStatsPtr, numSamples);
/*
				fprintf (stdout,"SUMS:  %d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\n",
							 theW,theT,theZ,planeStatsPtr->sum_i, planeStatsPtr->sum_i2, planeStatsPtr->sum_log_i, planeStatsPtr->sum_xi, planeStatsPtr->sum_yi, planeStatsPtr->sum_zi
				);
*/
			planeStatsPtr++;
			}
			Dump_Stats (&theStats, theW, theT);
			fflush (stdout);
		}
	}
	
	free (planeStats);
}


void Zero_Accumulators (statsPtr theStats)
{

	theStats->min        = 65537;
	theStats->max        =     0;
	theStats->mean       =     0.0;
	theStats->geomean    =     0.0;
	theStats->sigma      =     0.0;
	theStats->centroid_x =     0.0;
	theStats->centroid_y =     0.0;
	theStats->centroid_z =     0.0;
	theStats->sum_i      =     0.0;
	theStats->sum_i2     =     0.0;
	theStats->sum_log_i  =     0.0;
	theStats->sum_xi     =     0.0;
	theStats->sum_yi     =     0.0;
	theStats->sum_zi     =     0.0;
	theStats->numSamples =     0.0;
}


void Load_Accumulators (statsPtr theStats, statsPtr sums, unsigned long numSamples)
{

	if (sums->min < theStats->min) theStats->min = sums->min;
	if (sums->max > theStats->max) theStats->max = sums->max;
	theStats->sum_i      += sums->sum_i;
	theStats->sum_i2     += sums->sum_i2;
	theStats->sum_log_i  += sums->sum_log_i;
	theStats->sum_xi     += sums->sum_xi;
	theStats->sum_yi     += sums->sum_yi;
	theStats->sum_zi     += sums->sum_zi;
	theStats->numSamples += numSamples;

}


void Dump_Stats (statsPtr theStats, unsigned int theW, unsigned int theT)
{
float sd,logOffset = 1.0;

	theStats->mean = theStats->sum_i / theStats->numSamples;
	theStats->geomean = exp ( theStats->sum_log_i / theStats->numSamples ) - logOffset;

	sd = fabs ( (theStats->sum_i2	 - (theStats->sum_i * theStats->sum_i) / theStats->numSamples) /  (theStats->numSamples - 1.0) );
	theStats->sigma = (float) sqrt (sd);

	theStats->centroid_x = theStats->sum_xi / theStats->sum_i;
	theStats->centroid_y = theStats->sum_yi / theStats->sum_i;
	theStats->centroid_z = theStats->sum_zi / theStats->sum_i;
	fprintf (stdout,"%d\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\n",
		theW,theT,theStats->min,theStats->max,theStats->mean,theStats->geomean,theStats->sigma,
		theStats->centroid_x,theStats->centroid_y,theStats->centroid_z
	);

}



void usage(int argc, char **argv)
{
	fprintf (stderr,"Usage (can be used as CGI or CLI, produces a tab-delimited table of statistics on stdout - with text/plain header for CGI):\n");
	fprintf (stderr,
		"%s Dims=X,Y,Z,W,T,BytesPerPix\nSum_i,Sum_i2,Sum_log(i),Sum_Xi,Sum_Yi,Sum_Zi (one set per plane on stdin)\n",argv[0]);
	fprintf (stderr,"The column headings will be first line on standard out:\n");
	fprintf (stderr,"Wave\tTime\tMin\tMax\tMean\tGeoMean\tSigma\tCentroid_x\tCentroid_y\tCentroid_z\n");
}




int inList(char **cgivars, char *str)
{
	register int k = 0;
	int returnVal = 0;
	
	for(k=0; cgivars[k]; k += 2){
		
		if( strstr(cgivars[k],str) ){
			returnVal = 1;
			break;
		}
	}
	
	return( returnVal );
}

char *get_param (char **cgivars, char *param)
{
	register int k = 0;
	char *returnVal = 0;

	for(k=0; cgivars[k]; k += 2){
		
		if( strstr(cgivars[k],param) ){
			returnVal = cgivars[k+1];
			break;
		}
	}
	
	return returnVal;
}

/** Convert a two-char hex string into the char it represents **/
char x2c(char *what)
{
   register char digit;

   digit = (what[0] >= 'A' ? ((what[0] & 0xdf) - 'A')+10 : (what[0] - '0'));
   digit *= 16;
   digit += (what[1] >= 'A' ? ((what[1] & 0xdf) - 'A')+10 : (what[1] - '0'));
   return(digit);
}


/** Reduce any %xx escape sequences to the characters they represent **/
void unescape_url(char *url)
{
	register int i,j;

	for(i=0,j=0; url[j]; ++i,++j){
		
		if( (url[i] = url[j]) == '%' ){
			url[i] = x2c(&url[j+1]);
			j+= 2;
		}
	}
	
	url[i] = '\0';
}


/** Read the CGI input and place all name/val pairs into list.		  **/
/** Returns list containing name1, value1, name2, value2, ... , NULL  **/
char **getcgivars(void)
{
	register int i;
	char *request_method;
	int content_length;
	char *cgiinput;
	char **cgivars;
	char **pairlist;
	int paircount;
	char *nvpair;
	char *eqpos;



	request_method = (char *)getenv("REQUEST_METHOD");
	if (!request_method) return (0);
	
	if( !strcmp(request_method, "GET") || !strcmp(request_method, "HEAD") ){
		cgiinput = strdup((char *)getenv("QUERY_STRING"));
	}else if(!strcmp(request_method, "POST")){
		if( strcmp(getenv("CONTENT_TYPE"), "application/x-www-form-urlencoded")){
			fprintf(stderr,"getcgivars(): Unsupported Content-Type.\n");
			exit(1);
		}
		if( !(content_length = atoi(getenv("CONTENT_LENGTH"))) ){
			fprintf(stderr,"getcgivars(): No Content-Length was sent with the POST request.\n");
			exit(1);
		}
		if( !(cgiinput = (char *) malloc(content_length+1)) ){
			fprintf(stderr,"getcgivars(): Could not malloc for cgiinput.\n");
			exit(1);
		}
		if( !fread(cgiinput, content_length, 1, stdin)){
			fprintf(stderr,"Couldn't read CGI input from STDIN.\n");
			exit(1);
		}
		cgiinput[content_length]='\0';
	}else{
		fprintf(stderr,"getcgivars(): unsupported REQUEST_METHOD\n");
		exit(1);
	}

	/** Change all plusses back to spaces **/
	
	for(i=0; cgiinput[i]; i++){
		 if( cgiinput[i] == '+'){
			 cgiinput[i] = ' ';
		 }
	}
	
	/** First, split on "&" to extract the name-value pairs into pairlist **/
	
	pairlist = (char **) malloc(256*sizeof(char **));
	paircount = 0;
	nvpair = strtok(cgiinput,"&");
	
	while( nvpair){
		pairlist[paircount++] = strdup(nvpair);
		
		if( !(paircount%256) ){
			pairlist = (char **) realloc(pairlist,(paircount+256)*sizeof(char **));
		}
		nvpair = strtok(NULL,"&");
	}
	
	pairlist[paircount] = 0;	/* terminate the list with NULL */

	/** Then, from the list of pairs, extract the names and values **/
	
	cgivars = (char **) malloc((paircount*2+1)*sizeof(char **));
	
	for(i=0; i<paircount; i++){
		
		if( (eqpos = strchr(pairlist[i],'=')) ){
			*eqpos = '\0';
			unescape_url(cgivars[i*2+1] = strdup(eqpos+1));
		}else{
			unescape_url(cgivars[i*2+1] = strdup(""));
		}
		
		unescape_url(cgivars[i*2] = strdup(pairlist[i]));
	}
	
	cgivars[paircount*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Free anything that needs to be freed **/
	
	free(cgiinput);
	
	for(i=0; pairlist[i]; i++){
		 free(pairlist[i]);
	}
	
	free(pairlist);

	/** Return the list of name-value strings **/
	
	return cgivars ;
}

/** Read the CLI input and place all name/val pairs into list.		  **/
/** Returns list containing name1, value1, name2, value2, ... , NULL  **/
char **getCLIvars(int argc, char **argv)
{
	register int i;
	char **cgivars;
	char *eqpos;

	
	
	/** Then, from the list of pairs, extract the names and values **/
	
	cgivars = (char **) malloc((argc*2+1)*sizeof(char **));
	
	for(i=0; i<argc; i++){
		
		if( (eqpos = strchr(argv[i],'=')) ){
			*eqpos = '\0';
			cgivars[i*2+1] = strdup(eqpos+1);
		}else{
			cgivars[i*2+1] = strdup("");
		}
		
		cgivars[i*2] = strdup(argv[i]);
	}
	
	cgivars[argc*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Return the list of name-value strings **/
	
	return cgivars ;
}
