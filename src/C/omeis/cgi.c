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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   11/2003
 * 
 *------------------------------------------------------------------------------
 */

#include <stdio.h>
#include <string.h> 
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h> 

#include "cgi.h"



void HTTP_DoError (char *method, char *template, ...) {
va_list ap;
/*
403 Forbidden Authorization failure
500 Server Error 
*/
	if (getenv("REQUEST_METHOD")) {
		fprintf (stdout,"Status: 500 %s\r\n","Server Error");
		fprintf (stdout,"Content-Type: text/plain\r\n\r\n");
		fprintf (stdout,"Error calling %s: ", method);
		fprintf (stderr,"Error calling %s: ", method);
		va_start (ap, template);
		vfprintf (stdout, template, ap);
		vfprintf (stderr, template, ap);
		va_end (ap);
		fprintf (stdout,"\n");
		fprintf (stderr,"\n");
	} else {
		fprintf (stderr,"Error calling %s: ", method);
		va_start (ap, template);
		vfprintf (stderr, template, ap);
		va_end (ap);
		fprintf (stderr,"\n");
	}
}

void HTTP_ResultType (char *mimeType) {

	if (getenv("REQUEST_METHOD")) {
		fprintf (stdout,"Content-Type: %s\r\n\r\n",mimeType);
	}
}


/**********************************
 CGI/CLI handling section below
 Most of this was cribbed from a web page, whose URL is now lost.
**********************************/

static
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


char *get_lc_param (char **cgivars, char *param)
{
	register int k = 0;
	char *returnVal = 0;

	for(k=0; cgivars[k]; k += 2){
		
		if( !strcmp(cgivars[k],param) ){
			returnVal = cgivars[k+1];
			while (*returnVal) {
				*returnVal = tolower (*returnVal);
				returnVal++;
			}
			returnVal = cgivars[k+1];
			break;
		}
	}
	
	return returnVal;
}

/** Convert a two-char hex string into the char it represents **/
static
char x2c(char *what)
{
   register char digit;

   digit = (what[0] >= 'A' ? ((what[0] & 0xdf) - 'A')+10 : (what[0] - '0'));
   digit *= 16;
   digit += (what[1] >= 'A' ? ((what[1] & 0xdf) - 'A')+10 : (what[1] - '0'));
   return(digit);
}


/** Reduce any %xx escape sequences to the characters they represent **/
static
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
	size_t content_length;
	char cgiinput[4096];
	char **cgivars;
	char **pairlist;
	int paircount;
	char *nvpair;
	char *eqpos;
	char url_encoded=1;

	request_method = getenv("REQUEST_METHOD");
	if (!request_method) return (0);
	
	if( !strcmp(request_method, "GET") || !strcmp(request_method, "HEAD") ){
		strncpy (cgiinput,getenv("QUERY_STRING"),4095);
	} else if (!strcmp(request_method, "POST")) {
		strncpy (cgiinput,getenv("QUERY_STRING"),4095);
		if( !(content_length = atoi(getenv("CONTENT_LENGTH")))  ){
			fprintf(stderr,"getcgivars(): No Content-Length was sent with the POST request.\n");
			exit(1);
		}
		if(! strcmp(getenv("CONTENT_TYPE"), "application/x-www-form-urlencoded")){
			if( content_length > 4095 ){
				fprintf(stderr,"getcgivars(): Could not malloc for cgiinput.\n");
				exit(1);
			}
			if( !fread(cgiinput, content_length, 1, stdin)){
				fprintf(stderr,"Couldn't read CGI input from STDIN.\n");
				exit(1);
			}
			cgiinput[content_length]='\0';
		} else if( strstr(getenv("CONTENT_TYPE"), "multipart/form-data")){
			char boundary[256],*charp,*charp2,done=0;
			char chunk[256],eol[3],tmp[256];
			unsigned long form_pos = 0;
			
			url_encoded = 0;
			fgets (boundary, 255 , stdin );
			form_pos += strlen (boundary);
			strcpy (eol,boundary+strlen(boundary)-2);			

			while (!feof(stdin) && !done) {
				fgets (chunk, 255 , stdin );
				form_pos += strlen (chunk);
				if (! strncmp (chunk,"Content-Disposition",19) ) {
					if (strstr (chunk,"form-data")) {
						if ( (charp = strstr (chunk,"name=\"")) ) {
							if (cgiinput[0]) strcat (cgiinput,"&");
							charp += 6;
							charp2 = tmp;
							while ( *charp != '"' && *charp != '\0') *charp2++ = *charp++;
							*charp2 = '\0';
							if (strlen(cgiinput)+strlen(tmp) < 4095)
								strcat (cgiinput,tmp);
							else {
								fprintf(stderr,"getcgivars(): Form input too long\n");
								exit(1);
							}
							if ( !strcmp (tmp,"Pixels") || !strcmp (tmp,"File") ) {
								if ( (charp = strstr (chunk,"filename=\"")) ) {
									strcat (cgiinput,"=");
									charp += 10;
									charp2 = tmp;
									while ( *charp != '"' && *charp != '\0') *charp2++ = *charp++;
									*charp2 = '\0';
									if (strlen(cgiinput)+strlen(tmp) < 4095)
										strcat (cgiinput,tmp);
									else {
										fprintf(stderr,"getcgivars(): Form input too long\n");
										exit(1);
									}
								}
								done = 1;
								while (strcmp (chunk,eol)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
								}
								
								sprintf (tmp,"&UploadSize=%ld",content_length-form_pos-strlen (boundary)-4);
								if (strlen(cgiinput)+strlen(tmp) < 4095)
									strcat (cgiinput,tmp);
								else {
									fprintf(stderr,"getcgivars(): Form input too long\n");
									exit(1);
								}
							} else if (!done) {
								while (!feof(stdin) && strcmp (boundary,chunk) && strcmp (chunk,eol)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
								}
								if (!strcmp (chunk,eol) && !feof(stdin)) {
									fgets (chunk, 255 , stdin );
									form_pos += strlen (chunk);
									if (strlen(cgiinput)+strlen(chunk) < 4094)
										strcat (cgiinput,"=");
										strcat (cgiinput,chunk);
									} else {
										fprintf(stderr,"getcgivars(): Form input too long\n");
										exit(1);
									}
									if ( (charp = strstr (cgiinput,eol)) ) *charp = '\0';
								}
							}
						}
					}
				}
			/*
				if (written+chunk_size > content_length) chunk_size = content_length-written;
				fread(chunk, chunk_size, 1, stdin);
				fwrite (chunk , chunk_size , 1 , stderr );
				written += chunk_size;
			*/
			}
		else {
			fprintf(stderr,"getcgivars(): Unsupported Content-Type: %s\n",getenv("CONTENT_TYPE"));
			exit(1);
		}
	}
	
	else{
		fprintf(stderr,"getcgivars(): unsupported REQUEST_METHOD\n");
		exit(1);
	}

	/** Change all plusses back to spaces **/
	if(url_encoded) {
		for(i=0; cgiinput[i]; i++){
			 if( cgiinput[i] == '+'){
				 cgiinput[i] = ' ';
			 }
		}
	}
	
	/** First, split on "&" to extract the name-value pairs into pairlist **/
	
	pairlist = (char **) malloc(256*sizeof(char **));
	paircount = 0;
	nvpair = strtok(cgiinput,"&");
	
	while (nvpair){
		pairlist[paircount++] = strcpy ((malloc(sizeof(char *) * (strlen(nvpair) + 1))), nvpair);
		
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
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen(eqpos + 1) + 1)), eqpos + 1);
		}else{
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen("") + 1)), "");
		}
		cgivars[i*2] = strcpy(malloc(sizeof(char *) * strlen(pairlist[i] + 1)), pairlist[i]);

		if(url_encoded) {
			unescape_url(cgivars[i*2]);
			unescape_url(cgivars[i*2+1]);
		}
	}
	
	cgivars[paircount*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Free anything that needs to be freed **/
	
	
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

	if (argc < 2) return (NULL);
	/** Then, from the list of pairs, extract the names and values **/
	
	cgivars = (char **) malloc((argc*2+1)*sizeof(char **));
	
	for(i=0; i<argc; i++){
		
		if( (eqpos = strchr(argv[i],'=')) ){
			*eqpos = '\0';
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen(eqpos + 1) + 1)), eqpos + 1);
		}else{
			cgivars[i*2+1] = strcpy(malloc(sizeof(char *) * (strlen("") + 1)), "");
		}
		
		cgivars[i*2] = strcpy(malloc(sizeof(char *) * (strlen(argv[i]) + 1)), argv[i]);
	}
	
	cgivars[argc*2] = 0 ;	 /* terminate the list with NULL */
	
	/** Return the list of name-value strings **/
	
	return cgivars ;
}
