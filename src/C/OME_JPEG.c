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






#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <jpeglib.h>


char *get_param (char **cgivars, char *param);
int inList(char **cgivars, char *str);
char x2c(char *what);
void unescape_url(char *url);
char **getcgivars(void);
char **getCLIvars(int argc, char **argv);
void usage(int argc, char **argv);
void make_RGB_JPEG (char *path, char *dims, char *theZ_s, char *theT_s, char *type, char *RGBon);
void make_Gray_JPEG (char *path, char *dims, char *theZ_s, char *theT_s, char *type);
void scale_buf (unsigned char *imageBuf, unsigned short *fileBuf, int numB, int numSamples, int blck, float scale);
void scale_Gray_buf (unsigned char *imageBuf, unsigned short *fileBuf, int numB, int numSamples, int blck, float scale);



/** 
 * This program will generate a JPEG image from a repository file.
 * In order to generate the image, you'll have to supply the following
 * parameters (name/value pairs):
 *
 * 	Path=/path/to/file
 * 	Dims=X,Y,Z,W,T,BytesPerPix
 * 	theZ=Z
 *	theT=T
 *	
 * In addition to the above, you need specify the gray channel, if you
 * want a gray JPEG:
 * 
 *	Gray=GrayWave,BlckLevel,Scale
 *
 * or, alternatively, the RGB channels, if you want an RGB JPEG:
 *
 *	RGB=RedWave,BlckLevel,Scale,GrnWave,BlckLvl,Scale,BluWave,BlckLvl,Scale 
 *
 * The resulting JPEG file is spewed on stdout. 
 * This program can also be used as CGI. In this case the input has to be 
 * passed as CGI-encoded name/value pairs through the CGI interface (you can
 * either use a GET or a POST). The resulting JPEG file is still spewed on 
 * stdout, but is prefixed by the string:
 *	"Content-type: image/jpeg\n\n"
 * so that the image can be correctly returned to the browser.
 *
 *
 *
 *
 * --------------------------------------------------------------------------
 * NOTE: This program used to do the following:
 *	+ Check REQUEST_METHOD environment variable
 *	+ If set, parse CGI input
 *	+ If not, parse command line input
 *	+ Generate JPEG according to input values
 * 
 * The problem with the above is that when you invoke the program from a CGI 
 * script (actually using it as from the command line), the REQUEST_METHOD 
 * environment variable is set. As a result, the program will try to parse the 
 * CGI input, ignoring the parameters that you passed on the command line. 
 * In order to take this into account, the behavior has been modified as 
 * follows:
 *	+ Check command line input
 *	+ If input, parse
 *	+ If not, parse CGI input
 *	+ Generate JPEG according to input values
 *
*/
int main (int argc, char **argv)
{
	int i;
	char *path;
	char *dims;
	char *theZ,*theT;
	char *type,*RGBon;
	char isRGB=0;
	char isCGI=0;
	
	/* OLD CODE:	char **cgivars;	
	 * REPLACED BY:
	*/
	char	**in_params ;
	
/* OLD CODE:
	cgivars = getcgivars() ;
	if (!cgivars) {
		cgivars = getCLIvars(argc,argv);
		if (!cgivars) {
			usage(argc,argv);
			exit (-1);
		} else isCGI=0;
	} else isCGI = 1;
 *
 * REPLACED BY:
*/		
	in_params = getCLIvars(argc,argv) ;
	if( !in_params ) {
		in_params = getcgivars() ;
		if( !in_params ) {
			usage(argc,argv) ;
			exit (-1) ;
		} else	isCGI = 1 ;
	} else	isCGI = 0 ;


/* REPLACED every occurence of cgivars (OLD CODE) in main 
 * with in_params. 
*/
	path = get_param (in_params,"Path");
	if (!path) {
		fprintf (stderr,"Path parameter not set.\n");
		usage(argc,argv);
		exit (-1);
	}
	
	dims = get_param (in_params,"Dims");
	if (!dims) {
		fprintf (stderr,"Dims parameter not set.\n");
		usage(argc,argv);
		exit (-1);
	}
	
	theZ = get_param (in_params,"theZ");
	if (!theZ) {
		fprintf (stderr,"theZ parameter not set.\n");
		usage(argc,argv);
		exit (-1);
	}
	
	theT = get_param (in_params,"theT");
	if (!theT) {
		fprintf (stderr,"theT parameter not set.\n");
		usage(argc,argv);
		exit (-1);
	}
	
	type = get_param (in_params,"RGB");
	if (!type) {
		type = get_param (in_params,"Gray");
		if (!type) {
			fprintf (stderr,"Neither RGB nor Gray parameter was set.\n");
			usage(argc,argv);
			exit (-1);
		} else isRGB = 0;
	} else isRGB = 1;
	
	if (isRGB)
		RGBon = get_param (in_params,"RGBon");

/*
	for(i=0; cgivars[i]; i += 2){
		fprintf (stderr,"%s = '%s'\n",cgivars[i],cgivars[i+1]);
	}
*/

	
	if (isCGI)
		fprintf (stdout,"Content-type: image/jpeg\n\n");

	if (isRGB)
		make_RGB_JPEG (path,dims,theZ,theT,type,RGBon);
	else
		make_Gray_JPEG (path,dims,theZ,theT,type);

	for(i=0; in_params[i]; i++){
		free (in_params[i]);
	}
	free (in_params);
	
	return (0);
}




void make_RGB_JPEG (char *path, char *dims, char *theZ_s, char *theT_s, char *type, char *RGBon)
{
	FILE *imgFileR, *imgFileG, *imgFileB;
	int numX, numY, numZ, numW, numT, numB;
	int row, rowsPerChunk=10;
	int theZ, theT;
	int rWav, rBlck;
	int gWav, gBlck;
	int bWav, bBlck;
	int rOn=1,gOn=1,bOn=1;
	float rScale,gScale,bScale;
	int numInts;
	
	unsigned short *fileBufR, *fileBufG, *fileBufB;
	int i;
	unsigned long numSamples;

	JSAMPLE * imageBuf;
	int quality=80;
	struct jpeg_compress_struct cinfo, *cinfoPtr;
	struct jpeg_error_mgr jerr;
	JSAMPROW row_pointer[rowsPerChunk];	/* pointer to JSAMPLE row[s] */

	numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&numX,&numY,&numZ,&numW,&numT,&numB);
	if (numInts < 6 || numX < 1 || numY < 1 || numZ < 1 || numW < 1 || numT < 1 || numB < 1) {
		fprintf (stderr,"All 6 dimension sizes must be > 0: #dims=%d, Dims=%s\n",numInts,dims);
		exit (-1);
	}
	
	numInts  = sscanf (theZ_s,"%d",&theZ);
	numInts += sscanf (theT_s,"%d",&theT);
	if (numInts < 2 || theZ > (numZ-1) || theT > (numT-1)) {
		fprintf (stderr,"theZ and theT must be within the dimension sizes (theZ,theT) = (%d,%d)\n",theZ,theT);
		exit (-1);
	}
	
	numInts  = sscanf (type,"%d,%d,%f,%d,%d,%f,%d,%d,%f",&rWav, &rBlck, &rScale, &gWav, &gBlck, &gScale, &bWav, &bBlck, &bScale);
	if (numInts < 9) {
		fprintf (stderr,"The RGB parameter must supply 9 numbers, not %d: %s\n",numInts,type);
		exit (-1);
	}

	if (RGBon) sscanf (RGBon,"%d,%d,%d",&rOn, &gOn, &bOn);
	if (!rOn) rScale = 0.0;
	if (!gOn) gScale = 0.0;
	if (!bOn) bScale = 0.0;

	imageBuf = (JSAMPLE *)malloc (numX*3*rowsPerChunk);
	if (!imageBuf) {
		fprintf (stderr,"Could not allocate memory for image buffer\n");
		exit (-1);
	}
	for (i=0; i< rowsPerChunk;i++)
		row_pointer[i] = &imageBuf[i*numX*3];

	fileBufR = (unsigned short *)malloc (numX*numB*rowsPerChunk);
	fileBufG = (unsigned short *)malloc (numX*numB*rowsPerChunk);
	fileBufB = (unsigned short *)malloc (numX*numB*rowsPerChunk);
	if (!fileBufR || !fileBufG || !fileBufB) {
		fprintf (stderr,"Could not allocate memory for file buffer\n");
		exit (-1);
	}

	imgFileR = fopen (path,"r");
	imgFileG = fopen (path,"r");
	imgFileB = fopen (path,"r");
	if (!imgFileR || !imgFileG || !imgFileB) {
		fprintf (stderr,"File %s could not be opened for reading - B.\n",path);
		exit (-1);
	}
	fseek (imgFileR, ( ((theT*numW) + rWav)*numZ + theZ)*numX*numY*numB, SEEK_SET);
	fseek (imgFileG, ( ((theT*numW) + gWav)*numZ + theZ)*numX*numY*numB, SEEK_SET);
	fseek (imgFileB, ( ((theT*numW) + bWav)*numZ + theZ)*numX*numY*numB, SEEK_SET);

	/* Step 1: allocate and initialize error and JPEG compression object */
	cinfoPtr = &cinfo;
	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(cinfoPtr);
	
	/* Step 2: specify data destination (eg, a file) */
	jpeg_stdio_dest(cinfoPtr, stdout);
	
	/* Step 3: set parameters for compression */
	cinfo.image_width = numX; 	/* image width and height, in pixels */
	cinfo.image_height = numY;
	cinfo.input_components = 3;		/* # of color components per pixel */
	cinfo.in_color_space = JCS_RGB; 	/* colorspace of input image */

	/* Now use the library's routine to set default compression parameters. */
	jpeg_set_defaults(cinfoPtr);

	/* Now you can set any non-default parameters you wish to. */
	jpeg_set_quality(cinfoPtr, quality, TRUE);
	
	
	/* Step 4: Start compressor TRUE ensures that we will write a complete interchange-JPEG file. */
	jpeg_start_compress(cinfoPtr, TRUE);
		
	numSamples = numX*rowsPerChunk;
	row = 0;
	while (row < numY) {
		if (row + rowsPerChunk > numY) {
			rowsPerChunk = numY - row;
			numSamples = numX*rowsPerChunk;
		}
		fread( fileBufR, numB, numSamples, imgFileR );
		scale_buf (imageBuf,   fileBufR, numB, numSamples, rBlck, rScale);
		fread( fileBufG, numB, numSamples, imgFileG );
		scale_buf (imageBuf+1, fileBufG, numB, numSamples, gBlck, gScale);
		fread( fileBufB, numB, numSamples, imgFileB );
		scale_buf (imageBuf+2, fileBufB, numB, numSamples, bBlck, bScale);
/*
		for (i=0;i<10;i++) {
			fprintf (stderr,"%5d%5d%5d : %5d%5d%5d\n",fileBufR[i],fileBufG[i],fileBufB[i],imageBuf[(i*3)],imageBuf[(i*3)+1],imageBuf[(i*3)+2]);
		}
*/
/*		fwrite (imageBuf,1,numSamples*3, stdout); */
		
	/* jpeg_write_scanlines expects an array of pointers to scanlines. */
		(void) jpeg_write_scanlines(cinfoPtr, row_pointer, rowsPerChunk);

		row += rowsPerChunk;
	}
	
	/* Step 6: Finish compression */
	jpeg_finish_compress(cinfoPtr);

	/* After finish_compress, we can flush the output file, and close the input file. */
	fflush(stdout);
	fclose (imgFileR);
	fclose (imgFileG);
	fclose (imgFileB);

	/* Step 7: release JPEG compression object */
	jpeg_destroy_compress(cinfoPtr);
	
	free (fileBufR);
	free (fileBufG);
	free (fileBufB);
	free (imageBuf);
	
	/* And we're done! */
}

void make_Gray_JPEG (char *path, char *dims, char *theZ_s, char *theT_s, char *type)
{
	FILE *imgFile;
	int numX, numY, numZ, numW, numT, numB;
	int row, rowsPerChunk=10;
	int theZ, theT;
	int wave, blck;
	float scale;
	int numInts;
	
	unsigned short *fileBuf;
	int i;
	unsigned long numSamples;

	JSAMPLE * imageBuf;
	int quality=80;
	struct jpeg_compress_struct cinfo, *cinfoPtr;
	struct jpeg_error_mgr jerr;
	JSAMPROW row_pointer[rowsPerChunk];	/* pointer to JSAMPLE row[s] */

	numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&numX,&numY,&numZ,&numW,&numT,&numB);
	if (numInts < 6 || numX < 1 || numY < 1 || numZ < 1 || numW < 1 || numT < 1 || numB < 1) {
		fprintf (stderr,"All 6 dimension sizes must be > 0: #dims=%d, Dims=%s\n",numInts,dims);
		exit (-1);
	}
	
	numInts  = sscanf (theZ_s,"%d",&theZ);
	numInts += sscanf (theT_s,"%d",&theT);
	if (numInts < 2 || theZ > (numZ-1) || theT > (numT-1)) {
		fprintf (stderr,"theZ and theT must be within the dimension sizes (theZ,theT) = (%d,%d)\n",theZ,theT);
		exit (-1);
	}
	
	numInts  = sscanf (type,"%d,%d,%f",&wave, &blck, &scale);
	if (numInts < 3) {
		fprintf (stderr,"The Gray parameter must supply 3 numbers, not %d: %s\n",numInts,type);
		exit (-1);
	}

	imageBuf = (JSAMPLE *)malloc (numX*rowsPerChunk);
	if (!imageBuf) {
		fprintf (stderr,"Could not allocate memory for image buffer\n");
		exit (-1);
	}
	for (i=0; i< rowsPerChunk;i++)
		row_pointer[i] = &imageBuf[i*numX];

	fileBuf = (unsigned short *)malloc (numX*numB*rowsPerChunk);
	if (!fileBuf) {
		fprintf (stderr,"Could not allocate memory for file buffer\n");
		exit (-1);
	}

	imgFile = fopen (path,"r");
	if (!imgFile) {
		fprintf (stderr,"File %s could not be opened for reading - B.\n",path);
		exit (-1);
	}
	fseek (imgFile, ( ((theT*numW) + wave)*numZ + theZ)*numX*numY*numB, SEEK_SET);

	/* Step 1: allocate and initialize error and JPEG compression object */
	cinfoPtr = &cinfo;
	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(cinfoPtr);
	
	/* Step 2: specify data destination (eg, a file) */
	jpeg_stdio_dest(cinfoPtr, stdout);
	
	/* Step 3: set parameters for compression */
	cinfo.image_width = numX; 	/* image width and height, in pixels */
	cinfo.image_height = numY;
	cinfo.input_components = 1;		/* # of color components per pixel */
	cinfo.in_color_space = JCS_GRAYSCALE; 	/* colorspace of input image */

	/* Now use the library's routine to set default compression parameters. */
	jpeg_set_defaults(cinfoPtr);

	/* Now you can set any non-default parameters you wish to. */
	jpeg_set_quality(cinfoPtr, quality, TRUE);
	
	
	/* Step 4: Start compressor TRUE ensures that we will write a complete interchange-JPEG file. */
	jpeg_start_compress(cinfoPtr, TRUE);
		
	numSamples = numX*rowsPerChunk;
	row = 0;
	while (row < numY) {
		if (row + rowsPerChunk > numY) {
			rowsPerChunk = numY - row;
			numSamples = numX*rowsPerChunk;
		}
		fread( fileBuf, numB, numSamples, imgFile );
		scale_Gray_buf (imageBuf,   fileBuf, numB, numSamples, blck, scale);
		
	/* jpeg_write_scanlines expects an array of pointers to scanlines. */
		(void) jpeg_write_scanlines(cinfoPtr, row_pointer, rowsPerChunk);

		row += rowsPerChunk;
	}
	
	/* Step 6: Finish compression */
	jpeg_finish_compress(cinfoPtr);

	/* After finish_compress, we can flush the output file, and close the input file. */
	fflush(stdout);
	fclose (imgFile);

	/* Step 7: release JPEG compression object */
	jpeg_destroy_compress(cinfoPtr);
	
	free (fileBuf);
	
	/* And we're done! */
}


void scale_Gray_buf (unsigned char *imageBuf, unsigned short *fileBuf, int numB, int numSamples, int blck, float scale)
{
unsigned char *charPtr = (unsigned char *)fileBuf;
unsigned short *shortPtr = (unsigned short *)fileBuf;
int thePix,i;

	if (numB == 1) {
		for (i=0;i<numSamples;i++) {
			thePix = *charPtr++ - blck;
			if (thePix < 0) thePix = 0;
			thePix *= scale;
			if (thePix > 255) thePix=255;
			*imageBuf++ = thePix;
		}
	} else if (numB == 2) {
		for (i=0;i<numSamples;i++) {
			thePix = *shortPtr++ - blck;
			if (thePix < 0) thePix = 0;
			thePix *= scale;
			if (thePix > 255) thePix=255;
			*imageBuf++ = thePix;
		}
	}
}



void scale_buf (unsigned char *imageBuf, unsigned short *fileBuf, int numB, int numSamples, int blck, float scale)
{
unsigned char *charPtr = (unsigned char *)fileBuf, *charPtrEnd = charPtr + numSamples;
unsigned short *shortPtr = (unsigned short *)fileBuf, *shortPtrEnd = shortPtr + numSamples;
int thePix;

	if (numB == 1) {
		while (charPtr < charPtrEnd) {
			thePix = *charPtr++ - blck;
			if (thePix < 0) thePix = 0;
			thePix *= scale;
			if (thePix > 255) thePix=255;
			*imageBuf = thePix;
			imageBuf += 3;
		}
	} else if (numB == 2) {
		while (shortPtr < shortPtrEnd) {
			thePix = *shortPtr++ - blck;
			if (thePix < 0) thePix = 0;
			thePix *= scale;
			if (thePix > 255) thePix=255;
			*imageBuf = thePix;
			imageBuf += 3;
		}
	}
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
		
		if( !strcmp(cgivars[k],param) ){
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

	
	if (argc < 4) return (0);
	
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

void usage(int argc, char **argv)
{
	fprintf (stderr,"Usage (can be used as CGI or CLI, produces JPEG on stdout - with header for CGI):\n");
	fprintf (stderr,
		"%s Path=/path/to/file Dims=X,Y,Z,W,T,BytesPerPix theZ=Z theT=T Gray=GrayWave,BlckLevel,Scale\n\t-or-\n",argv[0]);
	fprintf (stderr,
		"%s Path=/path/to/file Dims=X,Y,Z,W,T,BytesPerPix theZ=Z theT=T RGB=RedWave,BlckLevel,Scale,GrnWave,BlckLvl,Scale,BluWave,BlckLvl,Scale\n",argv[0]);

}
