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
 * Written by:    Ilya G. Goldberg <igg@nih.gov>
 * 
 *------------------------------------------------------------------------------
 */




#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define MAXWAVES 5
typedef struct dv_head DVhead;
typedef short pixel;
typedef pixel *PixPtr;
typedef struct dv_stack DVstack;


short DV_REV_ENDIAN_MAGIC;
#define TIFF_MAGIC 3232
#define DV_MAGIC -16224

/*#########################*/
/*#        DVhead         #*/
/*#########################*/
/*
* this is the structure of the first 1024 bytes of the DeltaVision file.
* 
*/
struct dv_head {
	long   numCol,numRow,numImages;			   /* nsec +AD0- nz-nw+ACo-nt */
	long   mode;
	long   nxst, nyst, nzst;
	long   mx, my, mz;
	float xlen, ylen, zlen;
	float alpha, beta, gamma;
	long   mapc, mapr, maps;
	float min1, max1, amean;
	long   ispg, next;
	short nDVID,nblank;			 /* nblank preserves byte boundary */
	char  ibyte[28];
	short nint,nreal;
	short nres,nzfact;
	float min2,max2,min3,max3,min4,max4;
	short filetype, lens, n1, n2, v1, v2;
	float min5,max5;
	short numtimes;
	short imagesequence;
	float tiltx, tilty, tiltz;
	short NumWaves, iwav1, iwav2, iwav3, iwav4, iwav5;
	float zorig, xorig, yorig;
	long   nlab;
	char  label[800];
};











/*#########################*/
/*#       DVstack         #*/
/*#########################*/
/*
* This structure will contain the whole image stack.  The actual image data (->stack) will be
* de-allocated after each time-point is processed.  This is unidirectional linked list.  The
* time-points are linked through ->next.
* Note that there are two very different kinds of stack in this program - the image stack
* as defined in this structure and the LIFO stack that is used for finding spots.
*/
struct dv_stack {
	char nwaves;
	short max_x,max_y,max_z;	/* This is the width, height, thickness, respectively */
	short min_x,min_y,min_z;	/* These should be set to 0 */
	PixPtr stack;			/* This points to the actual image stack.  The entire stack is */
			/* a contiguous block of pixels, which is X*Y*Z*nwaves long.  The order is the */
			/* same as exists in the DV file.  All the Z sections of one wavelength followed by */
			/* all the Z sections of the next wavelength, etc. */

	short wave[MAXWAVES];	/* These are the wavelengths in the stack, and the order in which they */
							/* appear in the stack */
	pixel max_i[MAXWAVES];	/* each wavelength has its own min, max, etc */
	pixel min_i[MAXWAVES];
	float mean_i[MAXWAVES];
	float geomean_i[MAXWAVES];
	float sigma_i[MAXWAVES];

/*
* The integration threshold.
*/
	int threshold;
	
/*
* These are pre-set to help us navigate through the stack.
* If we add y_increment to a pointer into the stack, then the pointer
* will point to the next pixel down.  Likewise for z_increment and wave_increment
*/
	unsigned long y_increment,z_increment,wave_increment;
	DVhead *head;
	DVstack *next;
};





/*#########################*/
/*#                       #*/
/*#      Prototypes       #*/
/*#                       #*/
/*#########################*/
DVhead *ReadDVHeader( DVhead *head, FILE *fp );
DVstack *ReadDVstack(FILE *fp,DVhead *head,long time );
void Calculate_Stack_Stats (DVstack *inStack,int theWave);

void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);

void DumpGrey (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long greyWave,long greyClip,long greyThresh,float greyScale);
void DumpGrey2 (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long greyWave,long greyClip,long greyThresh,float greyScale);

void DumpRGB2 (char *theDVfileName,DVhead *theDVhead,long timePoint,long zSection,
	long redWave,long redClip,long redThresh,float redScale,
	long greenWave,long greenClip,long greenThresh,float greenScale,
	long blueWave,long blueClip,long blueThresh,float blueScale);
void DumpRGB (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long redWave,long redClip,long redThresh,float redScale,
	long greenWave,long greenClip,long greenThresh,float greenScale,
	long blueWave,long blueClip,long blueThresh,float blueScale);
unsigned long GetPlaneOffset (DVhead *head,long Z, long W,long T);



/*#########################*/
/*#                       #*/
/*#     ReadDVHeader      #*/
/*#                       #*/
/*#########################*/
/*
* This just fills the header structure with what's in the file.
* Note that this is not endian-neutral.  Attempting to read a file
* generated on a machine with a different endian-ness than the one
* this is running on will result in a scrambled header, and probably a core dump.
*/
DVhead *ReadDVHeader( DVhead *head, FILE *fp )
{

/* Read the header as a big-fat-chunk. */
	fread( head, 1024, 1, fp );

/* See if the DV file has a good DV magic number */
	if (head->nDVID != DV_MAGIC)
	{
		DV_REV_ENDIAN_MAGIC = head->nDVID;
		BSUtilsSwapHeader ( (char *)head);
		if (head->nDVID != DV_MAGIC)
			return (NULL);
		else
		{
			head->nDVID = DV_REV_ENDIAN_MAGIC;
		}
			
	}
	else
		return (head);
	
	return (head);
}










/*#########################*/
/*#                       #*/
/*#     ReadDVstack       #*/
/*#                       #*/
/*#########################*/
/*
* This reads the whole DV file into memory, and returns a pointer to the stack
* structure.  This routine expects an open file pointer for the DV file, a 
* pointer to a valid and filled-in head structure, and the time-point.  Note that
* the first time point is time=0.
*/


DVstack *ReadDVstack(FILE *fp,DVhead *head,long time )
{
unsigned long Rows,Cols,numZ,num,numWaves,numRead;
DVstack *inStack;

	Rows = head->numRow;
	Cols = head->numCol;
	numWaves = head->NumWaves;
	numZ = head->numImages / (numWaves * head->numtimes);


/*
* Allocate memory for the structure
*/
	inStack = (DVstack *) malloc (sizeof (DVstack));
	if (inStack == NULL)
		{
		fprintf (stderr,"Could not allocate sufficient memmory for image structure.\n");
		return (NULL);
		}

/*
* Allocate memory for the pixels.
* To be good citizens, its good to deallocate what was successfully
* allocated before aborting due to an error.
*/
	inStack->stack = (PixPtr) malloc(Cols*Rows*numZ*numWaves*sizeof(pixel));
	if (inStack->stack == NULL)
		{
		free (inStack);
		fprintf (stderr,"Could not allocate sufficient memmory for image.\n");
		return (NULL);
		}


/*
* Here we set some usefull variables in the stack structure.
*/
	inStack->nwaves = numWaves;
	inStack->min_x = inStack->min_y = inStack->min_z = 0;
	inStack->max_x = Cols-1;
	inStack->max_y = Rows-1;
	inStack->max_z = numZ-1;
	inStack->y_increment = Cols;
	inStack->z_increment = Cols * Rows;
	inStack->wave_increment = Cols * Rows * numZ;
	inStack->head = head;

/*
* within the program, a wave is always refered to by its index.
* The index is the order in which it appears in the DV file.
* The wavelengths and their maxima and minima are stored as discrete
* variables in the head, so we must convert them into arrays.
*/
	inStack->wave[0] = head->iwav1;
	inStack->max_i[0] =	 head->max1;
	inStack->min_i[0] =	 head->min1;
	inStack->mean_i[0] = 0;
	inStack->wave[1] = head->iwav2;
	inStack->max_i[1] =	 head->max2;
	inStack->min_i[1] =	 head->min2;
	inStack->mean_i[0] = 0;
	inStack->wave[2] = head->iwav3;
	inStack->max_i[2] =	 head->max3;
	inStack->min_i[2] =	 head->min3;
	inStack->mean_i[0] = 0;
	inStack->wave[3] = head->iwav4;
	inStack->max_i[3] =	 head->max4;
	inStack->min_i[3] =	 head->min4;
	inStack->mean_i[0] = 0;
	inStack->wave[4] = head->iwav5;
	inStack->max_i[4] =	 head->max5;
	inStack->min_i[4] =	 head->min5;
	inStack->mean_i[0] = 0;

/*
* This is the number of images before the time-point we want.
*/
	num = time * numZ * numWaves;

/* We set the file pointer to the begining of our timepoint */
	fseek( fp, 1024+head->next+num*Rows*Cols*2, SEEK_SET );

/* and we suck the file into our structure */
	numRead = fread( inStack->stack, sizeof(pixel), Cols*Rows*numZ*numWaves, fp );

/*
* If we didn't read enough pixels, then something went wrong.  Deallocate memory and return NULL.
*/
	if (numRead != Cols*Rows*numWaves*numZ)
		{
		free (inStack->stack);
		free (inStack);
		fprintf (stderr,"Number of pixels in file does not match number in header.\n");
		return (NULL);
		}

	/* Swap bytes if needed. */
	if (head->nDVID == DV_REV_ENDIAN_MAGIC)
		BSUtilsSwap2Byte ( (char *) (inStack->stack), Cols*Rows*numZ*numWaves);


	return (inStack);
}










/*#########################*/
/*#                       #*/
/*#     ReadDVslice       #*/
/*#                       #*/
/*#########################*/
/*
* This reads the specified z, section, wavelength and timepoint into memory, returning a block
* of contiguous memory contianing the pixels (byte-swapped if necessary).
*/


PixPtr ReadDVslice (FILE *fp,DVhead *head,long time,long z,long w)
{
unsigned long Rows,Cols,numZ,num=0,numWaves,numRead;
PixPtr thePixels;

	Rows = head->numRow;
	Cols = head->numCol;
	numWaves = head->NumWaves;
	if (w < 0 || w > numWaves)
		return (NULL);
	numZ = head->numImages / (numWaves * head->numtimes);
	if (z < 0 || z > numZ)
		return (NULL);


/*
* Allocate memory for the pixels.
* To be good citizens, its good to deallocate what was successfully
* allocated before aborting due to an error.
*/
	thePixels = (PixPtr) malloc(Cols*Rows*sizeof(pixel));
	if (thePixels == NULL)
		return (NULL);



/*
* This is the number of images before the time-point we want.
*/
/* Image sequence. 0=ZTW, 1=WZT, 2=ZWT */
	if (head->imagesequence == 0)
		num  = z + (time * numZ) + (w * numZ * head->numtimes);
	else if (head->imagesequence == 1)
		num  = w + (z * numWaves) + (time * numWaves * numZ);
	else if (head->imagesequence == 2)
		num  = z + (w * numZ) + (time * numZ * numWaves);

/* We set the file pointer to the begining of our timepoint */
	fseek( fp, 1024+head->next+(num*Rows*Cols*2), SEEK_SET );

/* and we suck the file into our structure */
	numRead = fread( thePixels, sizeof(pixel), Cols*Rows, fp );

/*
* If we didn't read enough pixels, then something went wrong.  Deallocate memory and return NULL.
*/
	if (numRead != Cols*Rows)
		{
		free (thePixels);
		fprintf (stderr,"Number of pixels in file does not match number in header.\n");
		return (NULL);
		}

	/* Swap bytes if needed. */
	if (head->nDVID == DV_REV_ENDIAN_MAGIC)
		BSUtilsSwap2Byte ( (char *) (thePixels), Cols*Rows);


	return (thePixels);
}










/*#########################*/
/*#                       #*/
/*# Calculate_Stack_Stats #*/
/*#                       #*/
/*#########################*/
/*
* This function calculates some statistics for the image stack.
* Statistics are calculated for one wavelength at a time.
* The statistics are stored in the stack structure, so nothing is returned.
*/
void Calculate_Stack_Stats (DVstack *inStack,int theWave)
{
PixPtr index,lastPix;
double sum_i=0,sum_i2=0,sum_log_i=0,numWavePix,theVal, sd, offset=100.0;

/*
* Set a pointer to point to the first z of the wave we want.
*/
	index = inStack->stack + (inStack->wave_increment * theWave);

/*
* set a pixel to point to the end of this wave.
*/
	lastPix = index + inStack->wave_increment;

/*
* crunch through pixels while we're in between the two pointers.
*/
	while (index < lastPix)
	{
		theVal = (double) *index;
		sum_i += theVal;
		sum_i2 += (theVal*theVal);
/*
* offset is used so that we don't compute logs of values less than or equal to zero.
*/
		sum_log_i +=  log (theVal+offset);
		index++;
	}

/*
* Calculate the actual statistics from the accumulators
*/
	numWavePix = (double) (inStack->wave_increment);
	inStack->mean_i[theWave] = sum_i / numWavePix;
	inStack->geomean_i[theWave] = exp ( sum_log_i / numWavePix ) - offset;

	sd = sqrt ( (sum_i2	 - (sum_i * sum_i) / numWavePix)/  (numWavePix - 1.0) );
	inStack->sigma_i[theWave] = (float) fabs (sd);
}



void Get_Slice_Stats (PixPtr thePixels,long length,long *minPix,long *maxPix,float *meanPix) 
{
PixPtr pixEnd;
long min,max;
float sum=0.0;
pixel thePixel;

	pixEnd = thePixels+length;
	min = max = *thePixels;
	while (thePixels != pixEnd) {
		thePixel = *thePixels++;
		sum += thePixel;
		if (thePixel < min) min = thePixel;
		if (thePixel > max) max = thePixel;		
	}
	
	*minPix = min;
	*maxPix = max;
	*meanPix = sum / (float) length;
}



char *ScaleDVslice (PixPtr thePix,unsigned long length,long clip, long thresh, float scale)
{
char *charPix,*charPixPtr,*charPixEnd,scaledThresh,scaledClip;
pixel thePixel;

	charPix = charPixPtr = (char *)malloc (sizeof(char)*length);
	if (!charPix) {
		fprintf (stderr,"Could not allocate memory for scaled pixels.\n");
		exit (-1);
	}
	charPixEnd = charPix + length;
	
	scaledThresh = (char) (thresh / scale);
	scaledClip = (char) (clip / scale);
	while (charPixPtr != charPixEnd) {
		thePixel = *thePix++;
		if (thePixel < thresh) *charPixPtr++ = 0;
		else if (thePixel > clip) *charPixPtr++ = 255;
		else *charPixPtr++ = (char) ((float) (thePixel-thresh) / scale);
	}
	return (charPix);
}



void GetMinMax (pixel *mins,pixel *maxs, DVhead *head) {
	if (head->NumWaves > 0)
		{
		maxs[0] = head->max1;
		mins[0] = head->min1;
		}

	if (head->NumWaves > 1)
		{
		maxs[1] = head->max2;
		mins[1] =	 head->min2;
		}
		
	if (head->NumWaves > 2)
		{
		maxs[2] = head->max3;
		mins[2] = head->min3;
		}

	if (head->NumWaves > 3)
		{
		maxs[3] = head->max4;
		mins[3] = head->min4;
		}

	if (head->NumWaves > 4)
		{
		maxs[4] = head->max5;
		mins[4] = head->min5;
		}

}





void DumpGrey (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long greyWave,long greyClip,long greyThresh,float greyScale) {

unsigned long length=theDVhead->numRow*theDVhead->numCol;
unsigned long offset=GetPlaneOffset (theDVhead,zSection,greyWave,timePoint);
unsigned long i,numRead;
pixel greyPixel;
PixPtr greyPix=NULL,greyPixPtr=NULL;

/* We set the file pointer to the begining of our timepoint */
	fseek( theDVfile, offset, SEEK_SET );

	if (greyWave > -1) {
		greyPix = greyPixPtr = (PixPtr) malloc (sizeof(pixel)*length);
		if (!greyPix) {
			fprintf (stderr,"Couldn't allocate memory for red pixels\n");
			exit (-1);
		}
		numRead = fread( greyPix, sizeof(pixel), length, theDVfile );
		if (numRead != length)
			{
			fprintf (stderr,"Number of pixels in file does not match number in header.\n");
			if (greyPix) free (greyPix);
			exit (-1);
			}
		if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC)
			BSUtilsSwap2Byte ( (char *) (greyPix), length);
	}
	for (i=0;i<length;i++) {
		greyPixel = *greyPixPtr++;
		putc (greyPixel > greyThresh ? greyPixel < greyClip ? ((greyPixel-greyThresh)/greyScale) : 255 : 0 ,stdout);
	}
	
	free (greyPix);

}





void DumpGrey2 (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long greyWave,long greyClip,long greyThresh,float greyScale)
{

unsigned long length=theDVhead->numRow*theDVhead->numCol;
unsigned long numZ = theDVhead->numImages / (theDVhead->NumWaves*theDVhead->numtimes);
unsigned long planeOffset = (timePoint * numZ * theDVhead->NumWaves) + (greyWave * numZ) + zSection;
unsigned long offset=1024+theDVhead->next+(planeOffset*2*length);
unsigned long i;
pixel thePixel;

/* We set the file pointer to the begining of our timepoint */
	fseek( theDVfile, offset, SEEK_SET );

	if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC) {
		for (i=0;i<length;i++) {
			thePixel = (getc(theDVfile) >> 8) | getc (theDVfile);
			putc (thePixel > greyThresh ? thePixel < greyClip ? ((thePixel-greyThresh)/greyScale) : 255 : 0 ,stdout);
		}
	} else {
		for (i=0;i<length;i++) {
			thePixel = (getc(theDVfile) << 8) | getc (theDVfile);
			putc (thePixel > greyThresh ? thePixel < greyClip ? ((thePixel-greyThresh)/greyScale) : 255 : 0 ,stdout);
		}
	}

}

void DumpRGB2 (char *theDVfileName,DVhead *theDVhead,long timePoint,long zSection,
	long redWave,long redClip,long redThresh,float redScale,
	long greenWave,long greenClip,long greenThresh,float greenScale,
	long blueWave,long blueClip,long blueThresh,float blueScale) {
unsigned long length=theDVhead->numRow*theDVhead->numCol;
unsigned long numZ = theDVhead->numImages / (theDVhead->NumWaves*theDVhead->numtimes);
unsigned long redPlaneOffset = (timePoint * numZ * theDVhead->NumWaves) + (redWave * numZ) + zSection;
unsigned long redOffset=1024+theDVhead->next+(redPlaneOffset*2*length);
unsigned long greenPlaneOffset = (timePoint * numZ * theDVhead->NumWaves) + (greenWave * numZ) + zSection;
unsigned long greenOffset=1024+theDVhead->next+(greenPlaneOffset*2*length);
unsigned long bluePlaneOffset = (timePoint * numZ * theDVhead->NumWaves) + (blueWave * numZ) + zSection;
unsigned long blueOffset=1024+theDVhead->next+(bluePlaneOffset*2*length);
unsigned long i;
pixel redPixel,greenPixel,bluePixel;
FILE *redStream=NULL,*greenStream=NULL,*blueStream=NULL;

/*
fprintf (stderr,"redWave %d, redClip %d, redThresh %d, redScale %f, redOffset %d\n",redWave,redClip,redThresh,redScale,redOffset);
fprintf (stderr,"greenWave %d, greenClip %d, greenThresh %d, greenScale %f, greenOffset %d\n",greenWave,greenClip,greenThresh,greenScale,greenOffset);
fprintf (stderr,"blueWave %d, blueClip %d, blueThresh %d, blueScale %f, blueOffset %d\n",blueWave,blueClip,blueThresh,blueScale,blueOffset);
*/

	if (redWave > -1) {
		redStream = fopen (theDVfileName,"r");
		fseek( redStream, redOffset, SEEK_SET );
	}
	if (greenWave > -1) {
		greenStream = fopen (theDVfileName,"r");
		fseek( greenStream, greenOffset, SEEK_SET );
	}
	if (blueWave > -1) {
		blueStream = fopen (theDVfileName,"r");
		fseek( blueStream, blueOffset, SEEK_SET );
	}


	if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC) {
		for (i=0;i<length;i++) {
			redPixel = (getc(redStream) >> 8) | getc (redStream);
			putc (redPixel > redThresh ? redPixel < redClip ? ((redPixel-redThresh)/redScale) : 255 : 0 ,stdout);
			greenPixel = (getc(greenStream) >> 8) | getc (greenStream);
			putc (greenPixel > greenThresh ? greenPixel < greenClip ? ((greenPixel-greenThresh)/greenScale) : 255 : 0 ,stdout);
			bluePixel = (getc(blueStream) >> 8) | getc (blueStream);
			putc (bluePixel > blueThresh ? bluePixel < blueClip ? ((bluePixel-blueThresh)/blueScale) : 255 : 0 ,stdout);
		}
	} else {
		for (i=0;i<length;i++) {
			redPixel = (getc(redStream) << 8) | getc (redStream);
			putc (redPixel > redThresh ? redPixel < redClip ? ((redPixel-redThresh)/redScale) : 255 : 0 ,stdout);
			greenPixel = (getc(greenStream) << 8) | getc (greenStream);
			putc (greenPixel > greenThresh ? greenPixel < greenClip ? ((greenPixel-greenThresh)/greenScale) : 255 : 0 ,stdout);
			bluePixel = (getc(blueStream) << 8) | getc (blueStream);
			putc (bluePixel > blueThresh ? bluePixel < blueClip ? ((bluePixel-blueThresh)/blueScale) : 255 : 0 ,stdout);
		}
	}
	
	if (redWave > -1) fclose (redStream);
	if (greenWave > -1) fclose (greenStream);
	if (blueWave > -1) fclose (blueStream);



}



void DumpRGB (FILE *theDVfile,DVhead *theDVhead,long timePoint,long zSection,
	long redWave,long redClip,long redThresh,float redScale,
	long greenWave,long greenClip,long greenThresh,float greenScale,
	long blueWave,long blueClip,long blueThresh,float blueScale) {
unsigned long length=theDVhead->numRow*theDVhead->numCol;
unsigned long redOffset   = GetPlaneOffset (theDVhead,zSection,redWave,   timePoint);
unsigned long greenOffset = GetPlaneOffset (theDVhead,zSection,greenWave, timePoint);
unsigned long blueOffset  = GetPlaneOffset (theDVhead,zSection,blueWave,  timePoint);
unsigned long i;
pixel redPixel,greenPixel,bluePixel;
PixPtr redPix=NULL,greenPix=NULL,bluePix=NULL,redPixPtr=NULL,greenPixPtr=NULL,bluePixPtr=NULL;
unsigned long numRead;
/*
fprintf (stderr,"redWave %d, redClip %d, redThresh %d, redScale %f, redOffset %d\n",redWave,redClip,redThresh,redScale,redOffset);
fprintf (stderr,"greenWave %d, greenClip %d, greenThresh %d, greenScale %f, greenOffset %d\n",greenWave,greenClip,greenThresh,greenScale,greenOffset);
fprintf (stderr,"blueWave %d, blueClip %d, blueThresh %d, blueScale %f, blueOffset %d\n",blueWave,blueClip,blueThresh,blueScale,blueOffset);
*/

	if (redWave > -1) {
		fseek( theDVfile, redOffset, SEEK_SET );
		redPix = redPixPtr = (PixPtr) malloc (sizeof(pixel)*length);
		if (!redPix) {
			fprintf (stderr,"Couldn't allocate memory for red pixels\n");
			if (redPix) free (redPix);
			if (greenPix) free (greenPix);
			if (bluePix) free (bluePix);
			exit (-1);
		}
		numRead = fread( redPix, sizeof(pixel), length, theDVfile );
		if (numRead != length)
			{
			fprintf (stderr,"Number of pixels in file does not match number in header.\n");
			if (redPix) free (redPix);
			if (greenPix) free (greenPix);
			if (bluePix) free (bluePix);
			exit (-1);
			}
		if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC)
			BSUtilsSwap2Byte ( (char *) (redPix), length);
	}

	if (greenWave > -1) {
		fseek( theDVfile, greenOffset, SEEK_SET );
		greenPix = greenPixPtr = (PixPtr) malloc (sizeof(pixel)*length);
		if (!greenPix) {
			fprintf (stderr,"Couldn't allocate memory for green pixels\n");
			if (redPix) free (redPix);
			if (greenPix) free (greenPix);
			if (bluePix) free (bluePix);
			exit (-1);
		}
		numRead = fread( greenPix, sizeof(pixel), length, theDVfile );
		if (numRead != length)
			{
			fprintf (stderr,"Number of pixels in file does not match number in header.\n");
			if (redPix) free (redPix);
			if (greenPix) free (greenPix);
			if (bluePix) free (bluePix);
			exit (-1);
			}
		if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC)
			BSUtilsSwap2Byte ( (char *) (greenPix), length);
	}
	if (blueWave > -1) {
		fseek( theDVfile, blueOffset, SEEK_SET );
		bluePix = bluePixPtr = (PixPtr) malloc (sizeof(pixel)*length);
		if (!bluePix) {
			fprintf (stderr,"Couldn't allocate memory for blue pixels\n");
			exit (-1);
		}
		numRead = fread( bluePix, sizeof(pixel), length, theDVfile );
		if (numRead != length)
			{
			fprintf (stderr,"Number of pixels in file does not match number in header.\n");
			if (redPix) free (redPix);
			if (greenPix) free (greenPix);
			if (bluePix) free (bluePix);
			exit (-1);
			}
		if (theDVhead->nDVID == DV_REV_ENDIAN_MAGIC)
			BSUtilsSwap2Byte ( (char *) (bluePix), length);
	}

	for (i=0;i<length;i++) {
		redPixel = redPix ? *redPixPtr++ : 0;
		greenPixel = greenPix ? *greenPixPtr++ : 0;
		bluePixel = bluePix ? *bluePixPtr++ : 0;
		putc (redPixel > redThresh ? redPixel < redClip ? ((redPixel-redThresh)/redScale) : 255 : 0 ,stdout);
		putc (greenPixel > greenThresh ? greenPixel < greenClip ? ((greenPixel-greenThresh)/greenScale) : 255 : 0 ,stdout);
		putc (bluePixel > blueThresh ? bluePixel < blueClip ? ((bluePixel-blueThresh)/blueScale) : 255 : 0 ,stdout);
	}
	
	if (redPix) free (redPix);
	if (greenPix) free (greenPix);
	if (bluePix) free (bluePix);


}


unsigned long GetPlaneOffset (DVhead *head,long Z, long W,long T)
{
int theSection;
int numZ;

	numZ = head->numImages / (head->NumWaves * head->numtimes);
/* Image sequence. 0=ZTW, 1=WZT, 2=ZWT */
	if (head->imagesequence == 0)
		theSection  = Z + (T * numZ) + (W * numZ * head->numtimes);
	else if (head->imagesequence == 1)
		theSection  = W + (Z * head->NumWaves) + (T * head->NumWaves * numZ);
	else if (head->imagesequence == 2)
		theSection  = Z + (W * numZ) + (T * numZ * head->NumWaves);
	else return (NULL);
		
	return (1024 + head->next + theSection*2*(head->numRow*head->numCol));
	
}




int main (int argc, char **argv)
{
char filePath[256];
long zSection=-1,timePoint=-1;
long greyWave=-1,redWave=-1,greenWave=-1,blueWave=-1;
long greyThresh=-1,redThresh=-1,greenThresh=-1,blueThresh=-1;
long greyClip=-1,redClip=-1,greenClip=-1,blueClip=-1;
float greyScale=-1.0,redScale=-1.0,greenScale=-1.0,blueScale=-1.0;
long i;
DVhead theDVhead;
FILE *theDVfile;
long numZ;
pixel *mins,*maxs;




	strcpy (filePath,"");
	for (i=0; i < argc; i++) {
		if (!strncmp (argv[i],"Path=",5) )
			sscanf (argv[i],"Path=%s",filePath);
		if (!strncmp (argv[i],"z=",2) )
			sscanf (argv[i],"z=%ld",&zSection);
		if (!strncmp (argv[i],"t=",2) )
			sscanf (argv[i],"t=%ld",&timePoint);
		if (!strncmp (argv[i],"Wave=",5) )
			sscanf (argv[i],"Wave=%ld",&greyWave);
		if (!strncmp (argv[i],"GreyWave=",9) )
			sscanf (argv[i],"GreyWave=%ld",&greyWave);
		if (!strncmp (argv[i],"RedWave=",8) )
			sscanf (argv[i],"RedWave=%ld",&redWave);
		if (!strncmp (argv[i],"GreenWave=",10) )
			sscanf (argv[i],"GreenWave=%ld",&greenWave);
		if (!strncmp (argv[i],"BlueWave=",9) )
			sscanf (argv[i],"BlueWave=%ld",&blueWave);
		if (!strncmp (argv[i],"thresh=",7) )
			sscanf (argv[i],"thresh=%ld",&greyThresh);
		if (!strncmp (argv[i],"GreyThresh=",11) )
			sscanf (argv[i],"GreyThresh=%ld",&greyThresh);
		if (!strncmp (argv[i],"RedThresh=",10) )
			sscanf (argv[i],"RedThresh=%ld",&redThresh);
		if (!strncmp (argv[i],"GreenThresh=",12) )
			sscanf (argv[i],"GreenThresh=%ld",&greenThresh);
		if (!strncmp (argv[i],"BlueThresh=",11) )
			sscanf (argv[i],"BlueThresh=%ld",&blueThresh);
		if (!strncmp (argv[i],"clip=",5) )
			sscanf (argv[i],"clip=%ld",&greyClip);
		if (!strncmp (argv[i],"GreyClip=",9) )
			sscanf (argv[i],"GreyClip=%ld",&greyClip);
		if (!strncmp (argv[i],"RedClip=",8) )
			sscanf (argv[i],"RedClip=%ld",&redClip);
		if (!strncmp (argv[i],"GreenClip=",10) )
			sscanf (argv[i],"GreenClip=%ld",&greenClip);
		if (!strncmp (argv[i],"BlueClip=",9) )
			sscanf (argv[i],"BlueClip=%ld",&blueClip);
		if (!strncmp (argv[i],"scale=",6) )
			sscanf (argv[i],"scale=%f",&greyScale);
		if (!strncmp (argv[i],"GreyScale=",10) )
			sscanf (argv[i],"GreyScale=%f",&greyScale);
		if (!strncmp (argv[i],"RedScale=",9) )
			sscanf (argv[i],"RedScale=%f",&redScale);
		if (!strncmp (argv[i],"GreenScale=",11) )
			sscanf (argv[i],"GreenScale=%f",&greenScale);
		if (!strncmp (argv[i],"BlueScale=",10) )
			sscanf (argv[i],"BlueScale=%f",&blueScale);
	}
	if (strlen (filePath) < 1) {
		fprintf (stderr,"You must supply a Path argument (Path='some/path/to/file.DV')\n");
		exit (-1);
	}

	theDVfile = fopen (filePath,"r");
	if (theDVfile == NULL) {
		fprintf (stderr,"Couldn't open file '%s'.\n",filePath);
		exit (-1);
	}

	if (ReadDVHeader(&theDVhead, theDVfile ) == NULL) {
		fprintf (stderr,"The file '%s' doesn't seem to be a SoftWorx file.\n",filePath);
		exit (-1);
	}		
	numZ = theDVhead.numImages / (theDVhead.NumWaves * theDVhead.numtimes);
	mins = (pixel *) malloc (sizeof(pixel)*theDVhead.NumWaves);
	maxs = (pixel *) malloc (sizeof(pixel)*theDVhead.NumWaves);
	if (!mins || !maxs) {
		fprintf (stderr,"Couldn't allocate a few measely bytes to store mins and maxs.\n");
		exit (-1);
	}
	GetMinMax (mins,maxs,&theDVhead);

	if (zSection == -1)
		zSection = numZ / 2;
	
	if (timePoint == -1)
		timePoint = 0;

/* If none of the waves were specified, make a greyscale image of the 0th wave. */
	if (redWave == -1 && greenWave == -1 && blueWave == -1 && greyWave == -1)
		greyWave = 0;

/* If any of the Red, Green or Blue waves were specified, then unset the grey wave */
	if (redWave != -1 || greenWave != -1 || blueWave != -1)
		greyWave = -1;

/* If grey wave is set at this point, then unset red, green and blue. */
	if (greyWave != -1)
		redWave = greenWave = blueWave = -1;

	if (greyWave != -1) {
		if (greyWave > theDVhead.NumWaves) greyWave = theDVhead.NumWaves;
		if (greyWave < 0) greyWave = 0;
		if (greyClip == -1) greyClip = maxs[greyWave];
		if (greyThresh == -1) greyThresh = mins[greyWave];
		if (greyThresh > maxs[greyWave]) greyThresh = maxs[greyWave];
		if (greyThresh < mins[greyWave]) greyThresh = mins[greyWave];
		if (greyClip > maxs[greyWave]) greyClip = maxs[greyWave];
		if (greyClip < mins[greyWave]) greyClip = mins[greyWave];
		if (greyClip < greyThresh) {
			greyClip = maxs[greyWave];
			greyThresh = mins[greyWave];
		}
		if (greyScale == -1) greyScale = (float)(greyClip-greyThresh)/255.0;
		DumpGrey (theDVfile,&theDVhead,timePoint,zSection,greyWave,greyClip,greyThresh,greyScale);
	} else {
		if (redWave != -1) {
			if (redWave > theDVhead.NumWaves) redWave = theDVhead.NumWaves;
			if (redWave < 0) redWave = 0;
			if (redClip == -1) redClip = maxs[redWave];
			if (redThresh == -1) redThresh = mins[redWave];
			if (redThresh > maxs[redWave]) redThresh = maxs[redWave];
			if (redThresh < mins[redWave]) redThresh = mins[redWave];
			if (redClip > maxs[redWave]) redClip = maxs[redWave];
			if (redClip < mins[redWave]) redClip = mins[redWave];
			if (redClip < redThresh) {
				redClip = maxs[redWave];
				redThresh = mins[redWave];
			}
			if (redScale == -1) redScale = (float)(redClip-redThresh)/255.0;
		}
		if (greenWave != -1) {
			if (greenWave > theDVhead.NumWaves) greenWave = theDVhead.NumWaves;
			if (greenWave < 0) greenWave = 0;
			if (greenClip == -1) greenClip = maxs[greenWave];
			if (greenThresh == -1) greenThresh = mins[greenWave];
			if (greenThresh > maxs[greenWave]) greenThresh = maxs[greenWave];
			if (greenThresh < mins[greenWave]) greenThresh = mins[greenWave];
			if (greenClip > maxs[greenWave]) greenClip = maxs[greenWave];
			if (greenClip < mins[greenWave]) greenClip = mins[greenWave];
			if (greenClip < greenThresh) {
				greenClip = maxs[greenWave];
				greenThresh = mins[greenWave];
			}
			if (greenScale == -1) greenScale = (float)(greenClip-greenThresh)/255.0;
		}
		if (blueWave != -1) {
			if (blueWave > theDVhead.NumWaves) blueWave = theDVhead.NumWaves;
			if (blueWave < 0) blueWave = 0;
			if (blueClip == -1) blueClip = maxs[blueWave];
			if (blueThresh == -1) blueThresh = mins[blueWave];
			if (blueThresh > maxs[blueWave]) blueThresh = maxs[blueWave];
			if (blueThresh < mins[blueWave]) blueThresh = mins[blueWave];
			if (blueClip > maxs[blueWave]) blueClip = maxs[blueWave];
			if (blueClip < mins[blueWave]) blueClip = mins[blueWave];
			if (blueClip < blueThresh) {
				blueClip = maxs[blueWave];
				blueThresh = mins[blueWave];
			}
			if (blueScale == -1) blueScale = (float)(blueClip-blueThresh)/255.0;
		}


		DumpRGB (theDVfile,&theDVhead,timePoint,zSection,
			redWave,redClip,redThresh,redScale,
			greenWave,greenClip,greenThresh,greenScale,
			blueWave,blueClip,blueThresh,blueScale);
	}
	fclose (theDVfile);
	return (0);
}

