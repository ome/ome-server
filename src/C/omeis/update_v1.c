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
 * Written by:	Ilya G. Goldberg <igg@nih.gov>   3/2004
 * 
 *------------------------------------------------------------------------------
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

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
#include "OMEIS_Error.h"
#include "omeis.h"

#ifndef OMEIS_ROOT
#define OMEIS_ROOT "."
#endif


typedef struct {
	ome_coord theZ, theC, theT;
} tiffConvertSpec_v1;

typedef struct {
	unsigned long file_offset;
	unsigned long pix_offset;
	unsigned long nPix;
} fileConvertSpec_v1;

typedef struct {
	OID FileID;
	char isBigEndian;
	char isTIFF;
	union {
		tiffConvertSpec_v1 tiff;
		fileConvertSpec_v1 file;
	} spec;
} convertFileRec_v1;

typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y;
	char reserved[7]; /* reserved buffer (64 bytes total) */
} planeInfo_v1;


typedef struct
{
	char stats_OK;
	float sum_i, sum_i2, sum_log_i, sum_xi, sum_yi, sum_zi;
	float min, max, mean, geomean, sigma, geosigma;
	float centroid_x, centroid_y, centroid_z;
	char reserved[67]; /* reserved buffer (128 bytes total) */
} stackInfo_v1;


typedef struct {
	unsigned long mySig;
	unsigned char vers;
	unsigned char isFinished;     /* file is read only */
	ome_dim dx,dy,dz,dc,dt;       /* Pixel dimension extents */
	unsigned char bp;             /* bytes per pixel */
	unsigned char isSigned;       /* signed integers or not */
	unsigned char isFloat;        /* floating point or not */
	unsigned char sha1[OME_DIGEST_LENGTH]; /* SHA1 digest */
	char reserved[11];            /* buffer assuming OME_DIGEST_LENGTH=20 */
} pixHeader_v1;






int fix_header (OID ID);
int fix_v1_header (PixelsRep *myPixels, FILE *headFP);


int fix_header (OID ID) {
	PixelsRep *myPixels;
	FILE *headFP;
	u_int32_t u32t, u32t_sw;
	u_int64_t u64t, u64t_sw;
	u_int8_t u8t,version;
	char iamBigEndian;


	iamBigEndian = bigEndian();

	if (! (myPixels = newPixelsRep (ID)) ) {
		perror ("BAH!");
		return (0);
	}

	fprintf (stdout,"ID:%20llu: ",ID);
	if ( !(headFP = fopen (myPixels->path_info, "r")) ) {
		fprintf (stdout," *** Doesn't exist\n");
		freePixelsRep (myPixels);
		return (-2);
	}

	while (1) {

		fread (&u64t, sizeof (u_int64_t), 1, headFP);
		if (u64t == OME_IS_PIXL_SIG) {
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Version %lu,", (unsigned long)u8t);
			version = u8t;
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Finished %lu,", (unsigned long)u8t);
			if (version == 1) {
				fix_v1_header (myPixels,headFP);
				fprintf (stdout,"\n");
			} else if (version == 2) {
				fprintf (stdout," *** Already updated.\n");
			} else {
				fprintf (stdout," *** Can't update from this machine!\n");
			}
			break;
		}
	
		u64t_sw = u64t;
		byteSwap ((unsigned char *)(&u64t_sw), 1, (char) (sizeof (u_int64_t)));
		if (u64t_sw == OME_IS_PIXL_SIG) {
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Version %lu", (unsigned long)u8t);
			version = u8t;
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Finished %lu", (unsigned long)u8t);
			fprintf (stdout," *** Can't update from this machine!\n");
			break;
		}


		rewind (headFP);
		fread (&u32t, sizeof (u_int32_t), 1, headFP);
		if (u32t == OME_IS_PIXL_SIG) {
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Version %lu", (unsigned long)u8t);
			version = u8t;
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Finished %lu", (unsigned long)u8t);
			if (version == 1) {
				fix_v1_header (myPixels,headFP);
				fprintf (stdout,"\n");
			} else if (version == 2) {
				fprintf (stdout," *** Already updated.\n");
			} else {
				fprintf (stdout," *** Can't update from this machine!\n");
			}
			break;
		}

		u32t_sw = u32t;
		byteSwap ((unsigned char *)(&u32t_sw), 1, (char) (sizeof (u_int32_t)));
		if (u32t_sw == OME_IS_PIXL_SIG) {
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Version %lu", (unsigned long)u8t);
			version = u8t;
			fread (&u8t, sizeof (u_int8_t), 1, headFP);
			fprintf (stdout," Finished %lu", (unsigned long)u8t);
			fprintf (stdout," *** Can't update from this machine!\n");
			break;
		}


		fprintf (stdout,"Unknown header type\n");
		ID = 0;
		break;
	}

	freePixelsRep (myPixels);
	fclose (headFP);
	
	if (ID) {
		myPixels = GetPixelsRep (ID, 'i', iamBigEndian);
		if (myPixels) {
			if (!isConvertVerified (myPixels)) {
				recoverPixels (myPixels, 0, 0, 1);
			}
			freePixelsRep (myPixels);
		}
	}

	return (1);

}


int  fix_v1_header (PixelsRep *myPixels, FILE *headFP1) {
char convPath1[256],convPath2[256],headPath1[256],headPath2[256];
FILE *convFP1,*convFP2,*headFP2;
ome_coord nPlanes,nStacks,i;
pixHeader_v1 v1Head;
pixHeader    v2Head;
planeInfo_v1 v1Plane;
planeInfo    v2Plane;
stackInfo_v1 v1Stack;
stackInfo    v2Stack;
convertFileRec_v1 v1Rec;
convertFileRec    v2Rec;

	
	rewind (headFP1);
	strncpy (headPath1,myPixels->path_info,255);
	strncpy (headPath2,myPixels->path_info,255);
	if (strlen (headPath1) + 8 > 255) return (-101);
	if (strlen (headPath2) + 9 > 255) return (-101);
	strcat (headPath2,"2");
	if (! (headFP2 = fopen (headPath2,"w")) ) {
		fprintf (stderr,"Can't open %s for writing: %s\n",headPath2,strerror (errno));
		return (-107);
	}

	memset(&v1Head, 0, sizeof(v1Head));
	fread (&v1Head, sizeof (v1Head), 1, headFP1);
	if (v1Head.mySig != OME_IS_PIXL_SIG) {
		fprintf (stderr,"PixelsID = %llu: Incompative signature\n",
			(unsigned long long)myPixels->ID);
		return (-108);
	}
	if (v1Head.vers  == 2) {
		return (1);
	}
	
	if (v1Head.vers  != 1) {
		fprintf (stderr,"PixelsID = %llu: Incompative version (%d)\n",
			(unsigned long long)myPixels->ID,(int)v1Head.vers);
		return (-109);
	}

	memset(&v2Head, 0, sizeof(v2Head));
	v2Head.mySig          = OME_IS_PIXL_SIG;
	v2Head.vers           = OME_IS_PIXL_VER;
	v2Head.isFinished     = v1Head.isFinished;
	v2Head.dx             = v1Head.dx;
	v2Head.dy             = v1Head.dy;
	v2Head.dz             = v1Head.dz;
	v2Head.dc             = v1Head.dc;
	v2Head.dt             = v1Head.dt;
	v2Head.bp             = v1Head.bp;
	v2Head.isSigned       = v1Head.isSigned;
	v2Head.isFloat        = v1Head.isFloat;
	memcpy (v2Head.sha1,v1Head.sha1,OME_DIGEST_LENGTH);
	fwrite ((void *)(&v2Head), sizeof (v2Head), 1, headFP2);

	nPlanes = v2Head.dz * v2Head.dc * v2Head.dt;
	nStacks = v2Head.dc * v2Head.dt;
	for (i=0; i < nPlanes; i++) {
		memset(&v1Plane, 0, sizeof(planeInfo_v1));
		if ( fread ((void *)&v1Plane, sizeof (planeInfo_v1), 1, headFP1) != 1) break;

		memset(&v2Plane, 0, sizeof(planeInfo));
		v2Plane.stats_OK   = v1Plane.stats_OK;
		v2Plane.sum_i      = v1Plane.sum_i;
		v2Plane.sum_i2     = v1Plane.sum_i2;
		v2Plane.sum_log_i  = v1Plane.sum_log_i;
		v2Plane.sum_xi     = v1Plane.sum_xi;
		v2Plane.sum_yi     = v1Plane.sum_yi;
		v2Plane.sum_zi     = v1Plane.sum_zi;
		v2Plane.min        = v1Plane.min;
		v2Plane.max        = v1Plane.max;
		v2Plane.mean       = v1Plane.mean;
		v2Plane.geomean    = v1Plane.geomean;
		v2Plane.sigma      = v1Plane.sigma;
		v2Plane.geosigma   = v1Plane.geosigma;
		v2Plane.centroid_x = v1Plane.centroid_x;
		v2Plane.centroid_y = v1Plane.centroid_y;
		if (fwrite ((void *)&v2Plane, sizeof (planeInfo), 1, headFP2) != 1) break;
	}
	
	if (i < nPlanes) {
		fprintf (stderr,"Didn't write enough plane stats.  Expected %d, wrote %d\n",nPlanes, i);
		fclose (headFP2);
		return (-110);
	}
	
	for (i=0; i < nStacks; i++) {
		memset(&v1Stack, 0, sizeof(stackInfo_v1));
		if (fread ((void *)&v1Stack, sizeof (stackInfo_v1), 1, headFP1) != 1) break;

		memset(&v2Stack, 0, sizeof(stackInfo));
		v2Stack.stats_OK   = v1Stack.stats_OK;
		v2Stack.sum_i      = v1Stack.sum_i;
		v2Stack.sum_i2     = v1Stack.sum_i2;
		v2Stack.sum_log_i  = v1Stack.sum_log_i;
		v2Stack.sum_xi     = v1Stack.sum_xi;
		v2Stack.sum_yi     = v1Stack.sum_yi;
		v2Stack.sum_zi     = v1Stack.sum_zi;
		v2Stack.min        = v1Stack.min;
		v2Stack.max        = v1Stack.max;
		v2Stack.mean       = v1Stack.mean;
		v2Stack.geomean    = v1Stack.geomean;
		v2Stack.sigma      = v1Stack.sigma;
		v2Stack.geosigma   = v1Stack.geosigma;
		v2Stack.centroid_x = v1Stack.centroid_x;
		v2Stack.centroid_y = v1Stack.centroid_y;
		v2Stack.centroid_z = v1Stack.centroid_z;
		if (fwrite ((void *)&v2Stack, sizeof (stackInfo), 1, headFP2) != 1) break;
	}
	
	fclose (headFP2);

	if (i < nStacks) {
		fprintf (stderr,"Didn't write enough stack stats.  Expected %d, wrote %d\n",nStacks, i);
		return (-110);
	}

	if (unlink (headPath1) != 0) {
		fprintf (stderr,"Couldn't delete old Pixels file %s: %s\n",
			headPath1, strerror (errno) );
		return (-110);
	}

	if (rename (headPath2,headPath1) != 0) {
		fprintf (stderr,"Couldn't rename converted Pixels file %s to %s: %s\n",
			headPath2, headPath1, strerror (errno) );
		return (-111);
	}
	
	strncpy (convPath1,myPixels->path_rep,255);
	strncpy (convPath2,myPixels->path_rep,255);
	if (strlen (convPath1) + 8 > 255) return (-101);
	if (strlen (convPath2) + 9 > 255) return (-101);
	strcat (convPath1,".convert");
	strcat (convPath2,".convert2");
	if (! (convFP1 = fopen (convPath1,"r")) ) {
		return (-107);
	}
	if (! (convFP2 = fopen (convPath2,"w")) ) {
		return (-107);
	}

	while (!feof (convFP1)) {
		memset(&v1Rec, 0, sizeof(convertFileRec_v1));
		if (fread ((void *)&v1Rec, sizeof (convertFileRec_v1), 1, convFP1) != 1) break;

		memset(&v2Rec, 0, sizeof(convertFileRec));
		v2Rec.FileID      = v1Rec.FileID;
		v2Rec.isBigEndian = v1Rec.isBigEndian;
		v2Rec.isTIFF      = v1Rec.isTIFF;
		if (v2Rec.isTIFF) {
			v2Rec.spec.tiff.theZ        = v1Rec.spec.tiff.theZ;
			v2Rec.spec.tiff.theC        = v1Rec.spec.tiff.theC;
			v2Rec.spec.tiff.theT        = v1Rec.spec.tiff.theT;
			v2Rec.spec.tiff.dir_index   = 0;
		} else {
			v2Rec.spec.file.file_offset = v1Rec.spec.file.file_offset;
			v2Rec.spec.file.pix_offset  = v1Rec.spec.file.pix_offset;
			v2Rec.spec.file.nPix        = v1Rec.spec.file.nPix;
		}
		if (fwrite ((void *)&v2Rec, sizeof (convertFileRec), 1, convFP2) != 1) break;
	}
	
	if (!feof (convFP1)) {
		fclose (convFP1);
		fclose (convFP2);
		unlink (convPath2);
		fprintf (stderr,"Error updating %s: %s.  %s deleted.\n",
			convPath1, strerror (errno), convPath2 );
		return (-112);
	}

	fclose (convFP1);
	fclose (convFP2);

	if (unlink (convPath1) != 0) {
		fprintf (stderr,"Couldn't delete old Pixels file %s: %s\n",
			convPath1, strerror (errno) );
		return (-110);
	}

	if (rename (convPath2,convPath1) != 0) {
		fprintf (stderr,"Couldn't rename converted Pixels file %s to %s: %s\n",
			convPath2, convPath1, strerror (errno) );
		return (-111);
	}

	return (1);
}

int main (int argc, char **argv) {
OID theID=0;
PixelsRep *myPixels;
char iamBigEndian;
int theArg;

	iamBigEndian = bigEndian();
	
	if (argc < 2) {
		fprintf (stderr,"Update Pixels files - Convert version 1 Pixels to version 2.\n");
		fprintf (stderr,"Also verify that '.convert' files will generate the identical pixels (delete the '.convert' file if not).\n");
		fprintf (stderr,"Delete the '.convert' file if it won't make identical pixels.\n");
		fprintf (stderr,"Usage:\n%s path [PixelsID] [PixelsID]...\n",argv[0]);
		fprintf (stderr,"  Where path is the OMEIS root (containing the Pixels directory)\n");
		fprintf (stderr,"  If no PixelsID parameters are supplied, the entire repository will be updated.\n");
		exit (-1);
	}

	if (chdir (argv[1])) {
		char error[256];
		sprintf (error,"Could not change working directory to %s",argv[1]);
		perror (error);
		exit (-1);
	}
	
	theArg = 2;
	if (theArg < argc) {
		while (theArg < argc) {
			theID = strtoull(argv[theArg], NULL, 10);
			if (theID != 0) fix_header (theID);
			theArg++;
		}
	} else {
		myPixels = newPixelsRep (0LL);
		theID = lastID (myPixels->path_ID);
		if (!theID) fprintf (stderr,"Couldn't get the last ID: %s\n",strerror (errno));
		freePixelsRep (myPixels);
		while (theID) {
			fix_header (theID);
			theID--;
		}
	}
	
	return (1);
}
