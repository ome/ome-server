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
#include <stdarg.h>
#include <stdlib.h>
#include <string.h> 
#include <ctype.h> 
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/param.h>

#include "Pixels.h"
#include "File.h"
#include "cgi.h"
#include "method.h"
#include "composite.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif

static
int
dispatch (char **param)
{
	PixelsRep *thePixels;
	FileRep *theFile;
	pixHeader *head;
	size_t nPix=0, nIO=0;
	char *theParam,rorw='r',iam_BigEndian=1;
	OID ID=0;
	size_t offset=0, file_offset=0;
	unsigned long long scan_off;
	unsigned char isLocalFile;
	char *dims;
	int isSigned,isFloat;
	int numInts,numX,numY,numZ,numC,numT,numB;
	int force,result;
	unsigned long z,dz,c,dc,t,dt;
	planeInfo *planeInfoP;
	stackInfo *stackInfoP;
	unsigned long uploadSize;
	unsigned long length;
	OID fileID;
	struct stat fStat;
	FILE *file;
	char file_path[MAXPATHLEN];
	char buf[4096];
	
	/* Co-ordinates */
	ome_coord theC = -1, theT = -1, theZ = -1, theY = -1;

/*
char **cgivars=param;
	while (*cgivars) {
		fprintf (stderr,"[%s]",*cgivars);cgivars++;fprintf (stderr," = [%s]\n",*cgivars);cgivars++;
	}
*/

	/* XXX: char * method should be able to disappear at some point */
	char *method;
	unsigned int m_val;


	if (! (method = get_param (param,"Method")) ) {
		HTTP_DoError (method,"Method parameter missing");
		return (-1);
	}
	
	m_val = get_method_by_name(method);
	/* END (method operations) */

	/* ID requirements */
	if ( (theParam = get_param (param,"PixelsID")) )
		sscanf (theParam,"%llu",&ID);
	else if (m_val != M_NEWPIXELS    &&
			 m_val != M_FILEINFO     &&
			 m_val != M_FILESHA1     &&
			 m_val != M_READFILE     &&
			 m_val != M_UPLOADFILE   &&
			 m_val != M_GETLOCALPATH) {
			HTTP_DoError (method,"PixelsID Parameter missing");
			return (-1);
	}

    if ((theParam = get_param(param,"IsLocalFile")))
        sscanf(theParam,"%hhu",&isLocalFile);
    else
        isLocalFile = 0;


	if ( (theParam = get_param (param,"theZ")) )
		sscanf (theParam,"%d",&theZ);

	if ( (theParam = get_param (param,"theC")) )
		sscanf (theParam,"%d",&theC);

	if ( (theParam = get_param (param,"theT")) )
		sscanf (theParam,"%d",&theT);
	
	if ( (theParam = get_param (param,"theY")) )
		sscanf (theParam,"%d",&theZ);

	if ( (theParam = get_lc_param (param,"BigEndian")) ) {
		if (!strcmp (theParam,"0") || !strcmp (theParam,"false") ) iam_BigEndian=0;
	}

	/* ---------------------- */
	/* SIMPLE METHOD DISPATCH */
	switch (m_val) {
		case M_NEWPIXELS:
			isSigned = 0;
			isFloat = 0;
		
			if (! (dims = get_param (param,"Dims")) ) {
				HTTP_DoError (method,"Dims Parameter missing");
				return (-1);
			}
			numInts = sscanf (dims,"%d,%d,%d,%d,%d,%d",&numX,&numY,&numZ,&numC,&numT,&numB);
			if (numInts < 6 || numX < 1 || numY < 1 || numZ < 1 || numC < 1 || numT < 1 || numB < 1) {
				HTTP_DoError (method,"Dims improperly formed.  Expecting numX,numY,numZ,numC,numT,numB.  All positive integers.");
				return (-1);
			}

			if ( (theParam = get_lc_param (param,"IsSigned")) ) {
				if (!strcmp (theParam,"1") || !strcmp (theParam,"true") ) isSigned=1;
			}

			if ( (theParam = get_lc_param (param,"IsFloat")) ) {
				if (!strcmp (theParam,"1") || !strcmp (theParam,"true") ) isFloat=1;
			}
			
			if ( !(numB == 1 || numB == 2 || numB == 4) ) {
				HTTP_DoError (method,"Bytes per pixel must be 1, 2 or 4, not %d", numB);
				return (-1);
			}
			
			if ( numB != 4 && isFloat ) {
				HTTP_DoError (method,"Bytes per pixel must be 4 for floating-point pixels, not %d", numB);
				return (-1);
			}

			if (! (thePixels = NewPixels (numX,numY,numZ,numC,numT,numB,isSigned,isFloat)) ) {
				HTTP_DoError (method,strerror( errno ) );
				return (-1);
			}

			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%llu\n",thePixels->ID);
			freePixelsRep (thePixels);

			break;
		case M_PIXELSINFO:
        	if (!ID) return (-1);

			if (! (thePixels = GetPixelsRep (ID,'i',1)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			HTTP_ResultType ("text/plain");
			fprintf(stdout,"Dims=%d,%d,%d,%d,%d,%hhu\n",
					head->dx,head->dy,head->dz,head->dc,head->dt,head->bp);
			fprintf(stdout,"Finished=%hhu\nSigned=%hhu\nFloat=%hhu\n",
					head->isFinished,head->isSigned,head->isFloat);

			fprintf(stdout,"SHA1=");
			print_md(head->sha1);
			fprintf(stdout,"\n");

			freePixelsRep (thePixels); 

			break;
		case M_PIXELSSHA1:
        	if (!ID) return (-1);

			if (! (thePixels = GetPixelsRep (ID,'i',1)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			HTTP_ResultType ("text/plain");
			print_md(head->sha1);
			fprintf(stdout,"\n");

			freePixelsRep (thePixels); 

			break;

		case M_FINISHPIXELS:
			force = 0;
			result = 0;

			if (!ID) return (-1);
			if ( (theParam = get_param (param,"Force")) )
				sscanf (theParam,"%d",&force);

			if (! (thePixels = GetPixelsRep (ID,'w',iam_BigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}
	
			result = FinishPixels (thePixels,force);
			freePixelsRep (thePixels);
		
			if ( result < 0) {
				if (errno) HTTP_DoError (method,"Result=%d, Message=%s",result,strerror( errno ) );
				else HTTP_DoError (method,"Result=%d, Message=%s",result,"Access control error - check error log for details" );
				return (-1);
			} else {
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%llu\n",ID);
			}

			break;
		case M_GETPLANESTATS:
			if (!ID) return (-1);
		
			if (! (thePixels = GetPixelsRep (ID,'r',bigEndian())) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			if (! (planeInfoP = thePixels->planeInfos) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			dz = head->dz;
			dc = head->dc;
			dt = head->dt;
			HTTP_ResultType ("text/plain");

			for (t = 0; t < dt; t++)
				for (c = 0; c < dc; c++)
					for (z = 0; z < dz; z++) {
						fprintf (stdout,"%lu\t%lu\t%lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n",
							 c,t,z,planeInfoP->min,planeInfoP->max,planeInfoP->mean,planeInfoP->sigma,planeInfoP->geomean,planeInfoP->geosigma,
							 planeInfoP->centroid_x, planeInfoP->centroid_y,
							 planeInfoP->sum_i, planeInfoP->sum_i2, planeInfoP->sum_log_i,
							 planeInfoP->sum_xi, planeInfoP->sum_yi, planeInfoP->sum_zi
						);
						planeInfoP++;
					}

			freePixelsRep (thePixels);

			break;
		case M_GETSTACKSTATS:
			if (!ID) return (-1);
		
			if (! (thePixels = GetPixelsRep (ID,'r',bigEndian())) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			if (! (stackInfoP = thePixels->stackInfos) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}

			head = thePixels->head;

			dz = head->dz;
			dc = head->dc;
			dt = head->dt;
			HTTP_ResultType ("text/plain");

			for (t = 0; t < dt; t++)
				for (c = 0; c < dc; c++) {
					fprintf (stdout,"%lu\t%lu\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n",
						 c,t,stackInfoP->min,stackInfoP->max,stackInfoP->mean,stackInfoP->sigma,stackInfoP->geomean,stackInfoP->geosigma,
						 stackInfoP->centroid_x, stackInfoP->centroid_y, stackInfoP->centroid_z,
						 stackInfoP->sum_i, stackInfoP->sum_i2, stackInfoP->sum_log_i,
						 stackInfoP->sum_xi, stackInfoP->sum_yi, stackInfoP->sum_zi
					);
					stackInfoP++;
				}

			freePixelsRep (thePixels);

			break;
		case M_UPLOADFILE:
			uploadSize = 0;
			if ( (theParam = get_param (param,"UploadSize")) )
				sscanf (theParam,"%lu",&uploadSize);
			else {
				HTTP_DoError (method,"UploadSize must be specified!");
				return (-1);
			}
			if ( (ID = UploadFile (get_param (param,"File"),uploadSize,isLocalFile) ) == 0) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			} else {
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%llu\n",ID);
			}

			break;
		case M_GETLOCALPATH:
			fileID = 0;

			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);

			if (ID) {
				if (! (thePixels = GetPixelsRep (ID,'i',bigEndian())) ) {
					if (errno) HTTP_DoError (method,strerror( errno ) );
					else  HTTP_DoError (method,"Access control error - check error log for details" );
					return (-1);
				}
				strcpy (file_path,thePixels->path_rep);
				freePixelsRep (thePixels);
			} else if (fileID) {
				strcpy (file_path,"Files/");
				if (! getRepPath (fileID,file_path,0)) {
					HTTP_DoError (method,"Could not get repository path for FileID=%llu",fileID);
					return (-1);
				}		
			} else strcpy (file_path,"");

			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%s\n",file_path);

			break;
		case M_FILEINFO:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( !(theFile = GetFileRep (fileID)) ) {
				HTTP_DoError (method,"Could not open FileID=%llu!",fileID);
				return (-1);
			}
			
			if (GetFileInfo (theFile) < 0) {
				freeFileRep (theFile);
				HTTP_DoError (method,"Could not get info for FileID=%llu!",fileID);
				return (-1);
			}

			HTTP_ResultType ("text/plain");
			fprintf (stdout,"Name=%s\nLength=%lu\nSHA1=",theFile->file_info.name,(unsigned long)theFile->size_rep);

			/* Print our lovely and useful SHA1. */
			print_md(theFile->file_info.sha1);  /* Convenience provided by digest.c */
			printf("\n");
			freeFileRep (theFile);

			break;
		case M_FILESHA1:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( !(theFile = GetFileRep (fileID)) ) {
				HTTP_DoError (method,"Could not open FileID=%llu!",fileID);
				return (-1);
			}
			
			if (GetFileInfo (theFile) < 0) {
				freeFileRep (theFile);
				HTTP_DoError (method,"Could not get info for FileID=%llu!",fileID);
				return (-1);
			}


			HTTP_ResultType ("text/plain");

			/* Print our lovely and useful SHA1. */
			print_md(theFile->file_info.sha1);  /* Convenience provided by digest.c */
			printf("\n");
			freeFileRep (theFile);

			break;
		case M_READFILE:
			offset = 0;
			length = 0;
			
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( (theParam = get_param (param,"Offset")) )
            {
				sscanf (theParam,"%llu",&scan_off);
				offset = (size_t)scan_off;
            }

			if ( !(theFile = GetFileRep (fileID)) ) {
				HTTP_DoError (method,"Could not open FileID=%llu!",fileID);
				return (-1);
			}

			if ( (theParam = get_param (param,"Length")) )
				sscanf (theParam,"%lu",&length);
			else
				length = theFile->size_rep;

			HTTP_ResultType ("application/octet-stream");
			fwrite (theFile->file_buf,length,1,stdout);
			freeFileRep (theFile);

			break;
		case M_IMPORTOMEFILE:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}
	
			strcpy (file_path,"Files/");
			if (! getRepPath (fileID,file_path,0)) {
				HTTP_DoError (method,"Could not get repository path for FileID=%llu",fileID);
				return (-1);
			}
	
			
			HTTP_ResultType ("text/xml");
			parse_xml_file( file_path );

			break;
		case M_CONVERT:
		case M_CONVERTSTACK:
		case M_CONVERTPLANE:
		case M_CONVERTTIFF:
		case M_CONVERTROWS:
			if ( (theParam = get_param (param,"FileID")) )
				sscanf (theParam,"%llu",&fileID);
			else {
				HTTP_DoError (method,"FileID must be specified!");
				return (-1);
			}

			if ( (theParam = get_param (param,"Offset")) ) {
				sscanf (theParam,"%llu",&scan_off);
				file_offset = (size_t)scan_off;
			}
		
			if (! (thePixels = GetPixelsRep (ID,'w',iam_BigEndian)) ) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				return (-1);
			}
			head = thePixels->head;
			nPix = head->dx*head->dy*head->dz*head->dc*head->dt;
			offset = 0;

			if (m_val == M_CONVERTSTACK) {
				if (theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theC and theT must be specified to do operations on stacks." );
					return (-1);
				}
				nPix = head->dx*head->dy*head->dz;
				if (!CheckCoords (thePixels, 0, 0, 0, theC, theT)){
					HTTP_DoError (method,"Parameters theC, theT (%d,%d) must be in range (%d,%d).",theC,theT,head->dc-1,head->dt-1);
					return (-1);
				}
				offset = GetOffset (thePixels, 0, 0, 0, theC, theT);
			} else if (m_val == M_CONVERTPLANE || m_val == M_CONVERTTIFF) {
				if (theZ < 0 || theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theZ, theC and theT must be specified to do operations on planes." );
					return (-1);
				}
				nPix = head->dx*head->dy;
				if (!CheckCoords (thePixels, 0, 0, theZ, theC, theT)){
					HTTP_DoError (method,"Parameters theZ, theC, theT (%d,%d,%d) must be in range (%d,%d,%d).",theZ,theC,theT,head->dz-1,head->dc-1,head->dt-1);
					return (-1);
				}
				offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
			} else if (m_val == M_CONVERTROWS) {
				long nRows=1;

				if ( (theParam = get_param (param,"nRows")) )
					sscanf (theParam,"%ld",&nRows);
				if (theY < 0 ||theZ < 0 || theC < 0 || theT < 0) {
					freePixelsRep (thePixels);
					HTTP_DoError (method,"Parameters theY, theZ, theC and theT must be specified to do operations on rows." );
					return (-1);
				}

				nPix = nRows*head->dy;
				if (!CheckCoords (thePixels, 0, theY, theZ, theC, theT)){
					HTTP_DoError (method,"Parameters theY, theZ, theC, theT (%d,%d,%d,%d) must be in range (%d,%d,%d,%d).",
						theY,theZ,theC,theT,head->dy-1,head->dz-1,head->dc-1,head->dt-1);
					return (-1);
				}
				if (theY+nRows-1 >= head->dy) {
					HTTP_DoError (method,"theY + nRows (%d + %d = %d) must be less than dY (%d).",
						theY,nRows,theY+nRows,head->dy);
					return (-1);
				}
				offset = GetOffset (thePixels, 0, theY, theZ, theC, theT);
			}

			if (m_val == M_CONVERTTIFF)
				nIO = ConvertTIFF (thePixels, fileID, theZ, theC, theT);
			else
				nIO = ConvertFile (thePixels, fileID, file_offset, offset, nPix);
			if (nIO < nPix) {
				if (errno) HTTP_DoError (method,strerror( errno ) );
				else if (strlen (thePixels->error_str)) HTTP_DoError (method,thePixels->error_str);
				else  HTTP_DoError (method,"Access control error - check error log for details" );
				freePixelsRep (thePixels);
				return (-1);
			} else {
				freePixelsRep (thePixels);
				HTTP_ResultType ("text/plain");
				fprintf (stdout,"%ld\n", (long) nIO);
			}

			break;
			
			case M_COMPOSITE:
				if (theZ < 0 || theT < 0) {
					HTTP_DoError (method,"Parameters theZ, and theT must be specified for the composite method." );
					return (-1);
				}
				if (! (thePixels = GetPixelsRep (ID,'r',bigEndian())) ) {
					if (errno) HTTP_DoError (method,strerror( errno ) );
					else  HTTP_DoError (method,"Access control error - check error log for details" );
					return (-1);
				}
				
				DoComposite (thePixels, theZ, theT, param);
			break;
			
			case M_GETTHUMB:
				strcpy (file_path,"Pixels/");
				if (! getRepPath (ID,file_path,0)) {
					HTTP_DoError (method,"Could not get repository path for PixelsID=%llu",ID);
					return (-1);
				}
				strcat (file_path,".thumb");

				if ( stat (file_path,&fStat) != 0 ) {
					HTTP_DoError (method,"Could not get information for thumbnail at %s",file_path);
					return (-1);
				}

				if ( !(file=fopen(file_path, "r")) ) {
					HTTP_DoError (method,"Could not get information for thumbnail at %s",file_path);
					return (-1);
				}

				HTTP_ResultType ("image/jpeg");
				while ((nIO = fread(buf,1,sizeof(buf),file)) > 0)
					if ( fwrite(buf,nIO,1,stdout ) != 1) break;
				fclose(file); 

			break;
	} /* END case (method) */

	/* ----------------------- */
	/* COMPLEX METHOD DISPATCH */
	if (m_val == M_SETPIXELS || m_val == M_GETPIXELS ||
		m_val == M_SETPLANE  || m_val == M_GETPLANE  ||
		m_val == M_SETSTACK  || m_val == M_GETSTACK) {
		char *filename = NULL;
		if (!ID) return (-1);


		if (strstr (method,"Set")) {
            rorw = 'w';
            if (!(filename = get_param(param,"Pixels"))) {
                HTTP_DoError(method,"No pixels filename specified");
            }
		} else rorw = 'r';

		if (! (thePixels = GetPixelsRep (ID,rorw,iam_BigEndian)) ) {
			if (errno) HTTP_DoError (method,strerror( errno ) );
			else  HTTP_DoError (method,"Access control error - check error log for details" );
			return (-1);
		}

		head = thePixels->head;
		if (strstr (method,"Pixels")) {
			nPix = head->dx*head->dy*head->dz*head->dc*head->dt;
			offset = 0;
		} else if (strstr (method,"Stack")) {
			if (theC < 0 || theT < 0) {
				freePixelsRep (thePixels);
				HTTP_DoError (method,"Parameters theC and theT must be specified to do operations on stacks." );
				return (-1);
			}
			nPix = head->dx*head->dy*head->dz;
			if (!CheckCoords (thePixels, 0, 0, 0, theC, theT)){
				HTTP_DoError (method,"Parameters theC, theT (%d,%d) must be in range (%d,%d).",theC,theT,head->dc-1,head->dt-1);
				return (-1);
			}
			offset = GetOffset (thePixels, 0, 0, 0, theC, theT);
		} else if (strstr (method,"Plane")) {
			if (theZ < 0 || theC < 0 || theT < 0) {
				freePixelsRep (thePixels);
				HTTP_DoError (method,"Parameters theZ, theC and theT must be specified to do operations on planes." );
				return (-1);
			}
			nPix = head->dx*head->dy;
			if (!CheckCoords (thePixels, 0, 0, theZ, theC, theT)){
				HTTP_DoError (method,"Parameters theZ, theC, theT (%d,%d,%d) must be in range (%d,%d,%d).",theZ,theC,theT,head->dz-1,head->dc-1,head->dt-1);
				return (-1);
			}
			offset = GetOffset (thePixels, 0, 0, theZ, theC, theT);
		}

		if (rorw == 'w')
			thePixels->IO_stream = openInputFile(filename,isLocalFile);
		else {
			thePixels->IO_stream = stdout;
			HTTP_ResultType ("application/octet-stream");
		}

		/*
		  Since we're going to stream to/from stdout/stdin at this point,
		  we can't report an error in a sensible way, so don't bother checking.
		  Its up to the client to figure out if the right number of pixels were read/written.
		*/
		nIO = DoPixelIO (thePixels, offset, nPix, rorw);
		if (rorw == 'w') {
            closeInputFile(thePixels->IO_stream,isLocalFile);
			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%ld\n", (long) nIO);
		}

		freePixelsRep (thePixels);
	}

	else if (m_val == M_SETROI || m_val == M_GETROI) {
		char *ROI;
		int x0,y0,z0,c0,t0,x1,y1,z1,c1,t1;
        char *filename=NULL;

		if (!ID) return (-1);
		if (m_val == M_SETROI) {
            rorw = 'w';
            if (!(filename = get_param(param,"Pixels"))) {
                HTTP_DoError(method,"No pixels filename specified");
            }
		} else rorw = 'r';

		if ( !(ROI = get_param (param,"ROI")) ) {
			HTTP_DoError (method,"ROI Parameter required for the %s method",method);
			return (-1);
		}

		numInts = sscanf (ROI,"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",&x0,&y0,&z0,&c0,&t0,&x1,&y1,&z1,&c1,&t1);
		if (numInts < 10) {
			HTTP_DoError (method,"ROI improperly formed.  Expected x0,y0,z0,c0,t0,x1,y1,z1,c1,t1");
			return (-1);
		}

		if (! (thePixels = GetPixelsRep (ID,rorw,iam_BigEndian)) ) {
			if (errno) HTTP_DoError (method,strerror( errno ) );
			else  HTTP_DoError (method,"Access control error - check error log for details" );
			return (-1);
		}

		if (rorw == 'w')
			thePixels->IO_stream = openInputFile(filename,isLocalFile);
		else {
			thePixels->IO_stream = stdout;
			HTTP_ResultType ("application/octet-stream");
		}
		nIO = DoROI (thePixels,x0,y0,z0,c0,t0,x1,y1,z1,c1,t1, rorw);
		if (rorw == 'w') {
            closeInputFile(thePixels->IO_stream,isLocalFile);
			HTTP_ResultType ("text/plain");
			fprintf (stdout,"%ld\n", (long) nIO);
		}
		freePixelsRep (thePixels);
	}

	
	
	return (1);
}

static
void usage (void) {

	fprintf (stderr,"Bad usage.  Missing parameters.\n");
}

int main (int argc,char **argv) {
char isCGI=0;
char **in_params;

	if (chdir (OMEIS_ROOT)) {
		char error[256];
		sprintf (error,"Could not change working directory to %s",OMEIS_ROOT);
		perror (error);
		exit (-1);
	}
	in_params = getCLIvars(argc,argv) ;
	if( !in_params ) {
		in_params = getcgivars() ;
		if( !in_params ) {
			usage() ;
			exit (-1) ;
		} else	isCGI = 1 ;
	} else	isCGI = 0 ;

	if (dispatch (in_params))
		return (0);
	else
		exit (-1);
}
