/*
Title:	BinarizeGlobal
Author: Ilya G. Goldberg, 2001
Copyright 1999-2001 Ilya G. Goldberg
This file is part of OME.
 
     OME is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.
 
     OME is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
 
     You should have received a copy of the GNU General Public License
     along with OME; if not, write to the Free Software
     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 

Purpose:  This program generates binary images using a global threshold from DeltaVsision (SoftWorx)
          or TIFF files.
Inputs:	 There is one required and two optional parameters
Usage:
>BinarizeGlobal <dataset> [-out=filename -type=<threshold> -value=<value> -wave=<wavelength>]
<dataset> a path to a file that can be either TIFF or DeltaVision.
<wavelegth> is the wavelegth from which to pick out "spots"
	This parameter will be ignored if the file is a TIFF file.  Use '0' for TIFF files.
	If this parameter ends in nm, that wavelength (in nm) will be read from the DV file.
	If this parameter is a bare integer (not ending in nm), then that wavelength number will be used from the DV file.
		Wave number are numbered from 0.
<threshold>	The threshold can be one of the following words (not case sensitive):
		MOMENT - Moment preservation method.
		OTSU - Otsu's discriminant method.
		ME - Maximum entropy method.
		KITTLER - Kittler's method of minimum error.
		ABS - An absolute value than can be specified with the -value=<number> parameter.
		MEAN - Use a threshold relative to the mean of the dataset (or wavelength)
		GEO - Use a threshold relative to the geometric mean of the dataset (or wavelength).
		Specify the number of standard deviations above/below the mean/geomean
		  using the -value=<number> parameter.
Example:
BinarizeGlobal DVfile -out=DVfile.bin -type=ME -wave=528
BinarizeGlobal DVfile -out=DVfile.bin -type=GEO -value=4.5 -wave=528
	
*/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
#include <tiffio.h>
#include "readTIFF.h"

/*
* The following line is commented out because it is not
* needed for UNIX.	 It IS needed for MetroWerks CodeWarrior to
* get command line arguments.	There is one more line like this in main.
#include <console.h>
*/
#ifdef __MWERKS__
#include <console.h>
#endif










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################              DEFINITION OF CONSTANTS               ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

#define CHUNK_SIZE 8189
#define MAXWAVES 5
#define BIGFLOAT 1.0E30

#define HEADING 1
#define VALUES 2
#define DATABASE_HEADING 3
#define DATABASE_VALUES 4

#define MAXDIST 1e10
#define OUTARGS 1

#define TIFF_MAGIC 3232
#define DV_MAGIC -16224

#define PI 3.14159265358979323846264338327
#define SQUARE_ROOT_OF_2 1.4142135623731


/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################            DEFINITION OF VARIABLE TYPES            ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

typedef struct dv_head DVhead;
typedef struct spotStructure SpotStruct;
typedef SpotStruct *SpotPtr;
typedef short pixel;
typedef pixel *PixPtr;
typedef struct dv_stack DVstack;
typedef struct dv_stack_info DVstackInfo;
typedef struct IndexStackStructure IndexStackStruct;
typedef IndexStackStruct *IndexStack;
typedef struct CoordListStructure CoordListStruct;
typedef CoordListStruct *CoordList;
typedef short coordinate;










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################               DEFINITION OF FUNCTIONS              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

DVhead *ReadDVHeader( DVhead *head, FILE *fp );
void SetTIFFptr (DVhead *head, TIFF *tiff);
TIFF *GetTIFFptr (DVhead *head);
DVstack *ReadDVstack(FILE *fp,DVhead *head,long wave, long time );
void Calculate_Stack_Stats (DVstack *theStackG,int theWave);
int Get_Wavelngth_Index (DVstack *theStackG, int waveLngth);

void Get_Args (int argc, char **argv, int *wave, int *time, char *outFilename);
pixel Set_Threshold (int argc, char **argv,DVstack *theStack);
double *Get_Prob_Hist (DVstack *theStack, unsigned short *histSizePtr);
pixel Get_Thresh_Moment (DVstack *theStack);
pixel Get_Thresh_Otsu (DVstack *theStack);
pixel Get_Thresh_ME (DVstack *theStack);
pixel Get_Thresh_Kittler (DVstack *theStack);

void Threshold_SoftWorx (DVstack *theStack,long theshold);
void Threshold_TIFF (DVstack *theStack,long theshold);
void Threshold_Pixels (DVstack *theStack,long theshold);

void Do_Usage (char *argv0);
void Write_TIFF_File (DVstack *theStack,char *theFilename);
void Write_SoftWorx_File (DVstack *theStack,char *outFilename);
void Write_Output_File (DVstack *theStack,char *theFilename);


void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);








/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################              DEFINITION OF STRUCTURES              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

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
	char  label[800];  /* FIXME:  This is used as a nasty way to stash a *TIFF ! */
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
	int nwaves;
	short max_x,max_y,max_z;	/* This is the width, height, thickness, respectively */
	short min_x,min_y,min_z;	/* These should be set to 0 */
	PixPtr stack;			/* This points to the actual image stack.  The entire stack is */
			/* a contiguous block of pixels, which is X*Y*Z*nwaves long.  The order is the */
			/* same as exists in the DV file.  All the Z sections of one wavelegth followed by */
			/* all the Z sections of the next wavelegth, etc. */

	char *outBuf;
	short wave[MAXWAVES];	/* These are the wavelegths in the stack, and the order in which they */
							/* appear in the stack */
	pixel max_i[MAXWAVES];	/* each wavelegth has its own min, max, etc */
	pixel min_i[MAXWAVES];
	float mean_i[MAXWAVES];
	float geomean_i[MAXWAVES];
	float sigma_i[MAXWAVES];

/*
* The integration threshold.
*/
	int threshold;
	int spotWave;
	int time;
	
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
/*#   GLOBAL VARIABLES    #*/
/*#                       #*/
/*#########################*/
/*
* These variables are global - Since we are no longer using recursion, they probably
* don't need to be, and probably won't be for long.
*/

DVstack *theStackG;
pixel thresholdG;
short DV_REV_ENDIAN_MAGIC;










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                       FUNCTIONS                    ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

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
* If the read is successfull, we return a pointer to the header structure, and NULL otherwise.
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
/*#    ReadTIFFHeader     #*/
/*#                       #*/
/*#########################*/
/*
* This just fills the header structure with what's in the file.
*/
TIFF *ReadTIFFHeader( DVhead *head, char *file, FILE **fp )
{
TIFF *tiff;
uint32 width,height;
uint16 bits;

	tiff = TIFFOpen(file,"r");
	if (!tiff ) return NULL;
	TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &bits);
	if (bits != 16)
	{
		fprintf (stderr,"Reading of non-16-bit TIFF files is not presently supported.\n");
		exit (-1);
	}

	head->numImages=1;
	head->xlen=1;
	head->ylen=1;
	head->zlen=1;
	head->min1 = 0;
	head->max1 = 0;
	head->amean = 0;
	head->nDVID = TIFF_MAGIC;
	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);
	head->numCol = width;
	head->numRow = height;
	head->numtimes=1;
	head->NumWaves=1;
	head->iwav1=999;
	SetTIFFptr (head,tiff);
	return (tiff);
}



void SetTIFFptr (DVhead *head, TIFF *tiff)
{
TIFF **tiffHndl;
/* FIXME:  This is kind of nasty, but not too bad especially once isolated */
/* What I've done is stuff the *TIFF into the first howevermany bytes of the label field. */
/* Its actually safe because the label field is only valid for DV files, and we're dealing with a TIFF file. */
/* Also, the label field has 800 bytes, which is more than plently to stash a pointer */
/* Also the pointer assignment is done with casts which should be architecture safe - i.e. we're not */
/* relying on a long to be big enough to contain a pointer.  All we're relying on is that 800 char are long enough. */

/* First cast the label field as a pointer to a TIFF pointer (instead of a char pointer) */
	tiffHndl = (TIFF **) (head->label);

/* Dereference the TIFF pointer pointer and stash the TIFF pointer there */
/* This should over-write however many chars are needed to stash the pointer */
	*tiffHndl = tiff;
}


TIFF *GetTIFFptr (DVhead *head)
{
TIFF *tiff;

/* We've over-written a pointers worth of chars in the label array to store a TIFF pointer */
/* The way we make a TIFF pointer out of that is we casi the label array as a TIFF pointer pointer and dereference it */
	tiff = *( (TIFF **) (head->label));
	return (tiff);
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


DVstack *ReadDVstack(FILE *fp,DVhead *head,long wave, long time )
{
unsigned long Rows,Cols,numZ,num,numWaves,numRead;
DVstack *inStack;
int i;

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
	inStack->stack = (PixPtr) malloc(Cols*Rows*numZ*sizeof(pixel));
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
* The wavelegths and their maxima and minima are stored as discrete
* variables in the head, so we must convert them into arrays.
*/
	for (i=0;i<MAXWAVES;i++)
		inStack->wave[i] = inStack->max_i[i] = inStack->min_i[i] = inStack->mean_i[i] =
			inStack->geomean_i[i] = inStack->sigma_i[i] = 0;

	if (inStack->nwaves > 0)
		{
		inStack->wave[0] = head->iwav1;
		inStack->max_i[0] =	 head->max1;
		inStack->min_i[0] =	 head->min1;
		inStack->mean_i[0] = 0;
		}

	if (inStack->nwaves > 1)
		{
		inStack->wave[1] = head->iwav2;
		inStack->max_i[1] =	 head->max2;
		inStack->min_i[1] =	 head->min2;
		inStack->mean_i[1] = 0;
		}
		
	if (inStack->nwaves > 2)
		{
		inStack->wave[2] = head->iwav3;
		inStack->max_i[2] =	 head->max3;
		inStack->min_i[2] =	 head->min3;
		inStack->mean_i[2] = 0;
		}
		
	if (inStack->nwaves > 3)
		{
		inStack->wave[3] = head->iwav4;
		inStack->max_i[3] =	 head->max4;
		inStack->min_i[3] =	 head->min4;
		inStack->mean_i[3] = 0;
		}
		
	if (inStack->nwaves > 4)
		{
		inStack->wave[4] = head->iwav5;
		inStack->max_i[4] =	 head->max5;
		inStack->min_i[4] =	 head->min5;
		inStack->mean_i[4] = 0;
		}

/*
* Read the raster out of the DV file.
*/
	if (head->nDVID != TIFF_MAGIC)
	{
	/*
	* This is the number of images before the time-point we want.
	*/
		num = time * numZ * numWaves;
		num += wave;

	/* We set the file pointer to the begining of our timepoint */
		fseek( fp, 1024+head->next+num*Rows*Cols*sizeof(pixel), SEEK_SET );

	/* and we suck the file into our structure */
		numRead = fread( inStack->stack, sizeof(pixel), Cols*Rows*numZ, fp );

	/*
	* If we didn't read enough pixels, then something went wrong.  Deallocate memory and return NULL.
	*/
		if (numRead != Cols*Rows*numZ)
			{
			free (inStack->stack);
			free (inStack);
			fprintf (stderr,"Number of pixels in file does not match number in header.\n");
			return (NULL);
			}

	/* Swap bytes if needed. */
	if (head->nDVID == DV_REV_ENDIAN_MAGIC)
		BSUtilsSwap2Byte ( (char *) (inStack->stack), Cols*Rows*numZ);

	}

/*
* Read the raster out of a TIFF file.
*/
	else
	{
	int errNum;
	TIFF *tiff;

		tiff = GetTIFFptr (head);
		errNum = ReadTIFFData (tiff,(unsigned char *)inStack->stack);
		if (errNum)
		{
		char errMsg[256];

			free (inStack->stack);
			free (inStack);
			fprintf (stderr,"Problem reading TIFF file.\n%s\n",GetReadTIFFError (errNum,errMsg) );
			return (NULL);
		}
	}

	return (inStack);
}










/*#########################*/
/*#                       #*/
/*# Calculate_Stack_Stats #*/
/*#                       #*/
/*#########################*/
/*
* This function calculates some statistics for the image stack.
* Statistics are calculated for one wavelegth at a time.
* The statistics are stored in the stack structure, so nothing is returned.
*/
void Calculate_Stack_Stats (DVstack *inStack,int theWave)
{
PixPtr index,lastPix;
double sum_i=0,sum_i2=0,sum_log_i=0,numWavePix,theVal, sd, offset=1.0,min,max;

/*
* Set a pointer to point to the first z of the wave we want.
*/
	index = inStack->stack + (inStack->wave_increment * theWave);

/*
* set a pixel to point to the end of this wave.
*/
	lastPix = index + inStack->wave_increment;

/*
* Set initial values for min and max
*/
	min = max = (double) *index;
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
		if (theVal < min) min = theVal;
		if (theVal > max) max = theVal;
		index++;
	}

/*
* Calculate the actual statistics from the accumulators
*/
	numWavePix = (double) (inStack->wave_increment);
	inStack->min_i[theWave] = min;
	inStack->max_i[theWave] = max;
	inStack->mean_i[theWave] = sum_i / numWavePix;
	inStack->geomean_i[theWave] = exp ( sum_log_i / numWavePix ) - offset;

	sd = sqrt ( (sum_i2	 - (sum_i * sum_i) / numWavePix)/  (numWavePix - 1.0) );
	inStack->sigma_i[theWave] = (float) fabs (sd);
}




















/*#########################*/
/*#                       #*/
/*#  Get_Wavelngth_Index  #*/
/*#                       #*/
/*#########################*/
/*
* This routine gets used by the output routine to easily get the
* wave index from a wavelegth.	If the specified wavelegth does not
* exist in the DVstack, then an out-of-bounds index is returned (MAXWAVES+1).
*/
int Get_Wavelngth_Index (DVstack *inStack, int waveLngth)
{
int theWaveIndx,i;

	if (inStack->head->nDVID != TIFF_MAGIC)
	{
		theWaveIndx = MAXWAVES+1;
		for (i=0; i < MAXWAVES; i++)
			if (inStack->wave[i] == waveLngth) theWaveIndx = i;
	}
	else
		theWaveIndx = 0;

	return (theWaveIndx);
}






















void Get_Args (int argc, char **argv, int *wave, int *time, char *outFilename)
{
int spotWave=0,i,timePoint=0;


	for (i=0;i<argc;i++) {
		if (!strncmp (argv[i],"-wave",5) ) {
			sscanf (argv[i],"-wave=%d",&spotWave);
		}
		else if (!strncmp (argv[i],"-time",5) ) {
			sscanf (argv[i],"-time=%d",&timePoint);
		}
		else if (!strncmp (argv[i],"-out",4) ) {
			strcpy (outFilename,argv[i]+5);
		}
	}

	*wave = spotWave;
	*time = timePoint;
}



pixel Set_Threshold (int argc, char **argv,DVstack *theStack)
{
float nSigmas;
int theThreshold=0;
int spotWave,i;
char type[32],tmp[32],*charPtr1,*charPtr2;
float value=0.0;


	Calculate_Stack_Stats (theStack,0);
	strcpy (type,"ABS");
	
	spotWave = theStack->spotWave;

	for (i=0;i<argc;i++) {
		if (!strncmp (argv[i],"-type",5) ) {
			sscanf (argv[i],"-type=%s",tmp);
			charPtr1 = tmp;
			charPtr2 = type;
			while (*charPtr1) {*charPtr2++ = toupper (*charPtr1++); }
			*charPtr2++ = '\0';
		}
		else if (!strncmp (argv[i],"-value",6) ) {
			sscanf (argv[i],"-value=%f",&value);
		}
	}
	

	if (!strncmp(type,"MEAN",4))
		{
		nSigmas = value;
		theThreshold = (int) (theStack->mean_i[spotWave] + (theStack->sigma_i[spotWave]*nSigmas));
#ifdef DEBUG
fprintf (stderr,"Mean + %f sigmas threshold: %d\n",nSigmas,(int) theThreshold);
fflush (stderr);
#endif
		}
	else if (!strncmp(type,"GEO",3))
		{
		nSigmas = value;
		theThreshold = (int) (theStack->geomean_i[spotWave] + (theStack->sigma_i[spotWave]*nSigmas));
#ifdef DEBUG
fprintf (stderr,"Geometric mean + %f sigmas threshold: %d\n",nSigmas,(int) theThreshold);
fflush (stderr);
#endif
		}

	else if (!strcmp (type,"MOMENT"))
		theThreshold = Get_Thresh_Moment (theStack);
	else if (!strcmp (type,"OTSU"))
		theThreshold = Get_Thresh_Otsu (theStack);
	else if (!strcmp (type,"ME"))
		theThreshold = Get_Thresh_ME (theStack);
	else if (!strcmp (type,"KITTLER"))
		theThreshold = Get_Thresh_Kittler (theStack);
	else
		theThreshold = (pixel) value;

	if (theThreshold > theStack->max_i[spotWave])
		theThreshold = theStack->max_i[spotWave];

	return ((pixel)theThreshold);
	
}



double *Get_Prob_Hist (DVstack *theStack, unsigned short *histSizePtr)
{
unsigned long theWave,i;
unsigned short histSize;
unsigned long *theHist,*theHistPtr;
double *theHistProb,*theHistProbPtr,nPix;
pixel *index,*lastPix;

/*
* Allocate a histogram the size of the dynamic range of the stack.
* Also allocate the probability histogram that we will return.
*/
	theWave = 0;
	*histSizePtr = histSize = (theStack->max_i[theWave])+1;

	theHist = (unsigned long *) malloc (histSize*sizeof(unsigned long));
	theHistProb = (double *) malloc (histSize*sizeof(double));
	if (!theHist || !theHistProb)
	{
		fprintf (stderr,"Could not allocate memory for histogram.\n");
		exit (-1);
	}
	theHistPtr = theHist;
	for (i=0;i<histSize;i++)
		*theHistPtr++ = 0;

/*
* Set a pointer to point to the first z of the wave we want.
*/
	index = theStack->stack + (theStack->wave_increment * theWave);

/*
* set a pixel to point to the end of this wave.
*/
	lastPix = index + theStack->wave_increment;

	nPix = (double) (lastPix - index);
/*
* crunch through pixels while we're in between the two pointers.
*/
	while (index < lastPix)
	{
		theHist[*index]++;
		index++;
	}
	
	theHistProbPtr = theHistProb;
	theHistPtr = theHist;
	for (i=0;i<histSize;i++)
		*theHistProbPtr++ = (double) (*theHistPtr++) / nPix;
	
	free (theHist);
	return (theHistProb);
}


pixel Get_Thresh_Moment (DVstack *theStack)
{
unsigned short histSize;
double *probHist,*probHistPtr,prob;
double m1=0.0, m2=0.0, m3=0.0;
double cd, c0, c1, z0, z1, pd, p0, p1;
double pDistr = 0.0;
unsigned long i;
pixel thresh=0;

	probHist = Get_Prob_Hist (theStack, &histSize);

	probHistPtr = probHist;
	for (i = 0; i < histSize; i++)
	{
		prob = *probHistPtr++;
		m1 += i * prob;
		m2 += i * i * prob;
		m3 += i * i * i * prob;
	}

	cd = m2 - m1 * m1;
	c0 = (-m2 * m2 + m1 * m3) / cd;
	c1 = (-m3 + m2 * m1) / cd;
	z0 = 0.5 * (-c1 - sqrt (c1 * c1 - 4.0 * c0));
	z1 = 0.5 * (-c1 + sqrt (c1 * c1 - 4.0 * c0));

	pd = z1 - z0;
	p0 = (z1 - m1) / pd;
	p1 = 1.0 - p0;

	probHistPtr = probHist;
	for (thresh = 0; thresh < histSize; thresh++)
	{
		pDistr += *probHistPtr++;
		if (pDistr > p0)
			break;
	}

	
	free (probHist);
#ifdef DEBUG
fprintf (stderr,"Moment threshold: %d\n",(int) thresh);
fflush (stderr);
#endif
	return (thresh);

}



pixel Get_Thresh_Otsu (DVstack *theStack)
{
unsigned short histSize,histSize_1;
double *probHist;
double varWMin=BIGFLOAT;
double m0Low,m0High,m1Low,m1High,varLow,varHigh;
double varWithin;
unsigned long i,j;
pixel thresh=0;

	probHist = Get_Prob_Hist (theStack, &histSize);

	histSize_1 = histSize - 1;
	for (i = 1; i < histSize_1; i++)
	{
		m0Low = m0High = m1Low = m1High = varLow = varHigh = 0.0;
		for (j = 0; j <= i; j++)
		{
			m0Low += probHist[j];
			m1Low += j * probHist[j];
		}
		m1Low = (m0Low != 0.0) ? m1Low / m0Low : i;
		for (j = i + 1; j < histSize; j++)
		{
			m0High += probHist[j];
			m1High += j * probHist[j];
		}
		m1High = (m0High != 0.0) ? m1High / m0High : i;
		for (j = 0; j <= i; j++)
			varLow += (j - m1Low) * (j - m1Low) * probHist[j];
		for (j = i + 1; j < histSize; j++)
			varHigh += (j - m1High) * (j - m1High) * probHist[j];

		varWithin = m0Low * varLow + m0High * varHigh;
		if (varWithin < varWMin)
		{
			varWMin = varWithin;
			thresh = i;
		}
	}
#ifdef DEBUG
fprintf (stderr,"Otsu's discriminant method threshold: %d\n",(int) thresh);
fflush (stderr);
#endif
	
	free (probHist);
	return (thresh);

}



pixel Get_Thresh_ME (DVstack *theStack)
{
unsigned short histSize;
double *probHist,*probHistPtr,prob;
double Hn=0.0, Ps=0.0, Hs=0.0;
double psi, psiMax=0.0;
unsigned long i,j;
pixel thresh;

	probHist = Get_Prob_Hist (theStack, &histSize);

	probHistPtr = probHist;
	for (i=0; i < histSize; i++)
	{
		prob = *probHistPtr++;
		if (prob)
			Hn -= prob * log (prob);
	}
	for (i = 1; i < histSize; i++)
	{
		for (j = 0; j < i; j++)
		{
			prob = probHist[j];
			Ps += prob;
			if (prob)
				Hs -= prob * log (prob);
		}

		if (Ps > 0.0 && Ps < 1.0)
			psi = log (Ps - Ps * Ps) + Hs / Ps + (Hn - Hs) / (1.0 - Ps);
		if (psi > psiMax)
		{
			psiMax = psi;
			thresh = i;
		}
	}
	
	free (probHist);

#ifdef DEBUG
fprintf (stderr,"Maximum Entropy threshold: %d\n",(int) thresh);
fflush (stderr);
#endif

	return (thresh);

}


pixel Get_Thresh_Kittler (DVstack *theStack)
{
unsigned short histSize,histSize_1;
double *probHist,*probHistPtr,prob;
double m0Low,m0High,m1Low,m1High,varLow,varHigh;
double term1, term2;
double stdDevLow, stdDevHigh;
double discr, discrMin, discrMax, discrM1;
unsigned long i,j;
pixel thresh;

	probHist = Get_Prob_Hist (theStack, &histSize);

	histSize_1 = histSize - 1;
	discr = discrM1 = discrMax = discrMin = 0.0;
	for (i = 1, thresh = 0; i < histSize_1; i++)
	{
		m0Low = m0High = m1Low = m1High = varLow = varHigh = 0.0;

		probHistPtr = probHist;
		for (j = 0; j <= i; j++)
		{
			prob = *probHistPtr++;
			m0Low += prob;
			m1Low += j * prob;
		}

		m1Low = (m0Low != 0.0) ? m1Low / m0Low : i;

		for (j = i + 1; j < histSize; j++)
		{
			prob = *probHistPtr++;
			m0High += prob;
			m1High += j * prob;
		}

		m1High = (m0High != 0.0) ? m1High / m0High : i;

		probHistPtr = probHist;
		for (j = 0; j <= i; j++)
			varLow += (j - m1Low) * (j - m1Low) * *probHistPtr++;
		stdDevLow = sqrt (varLow);

		for (j = i + 1; j < histSize; j++)
			varHigh += (j - m1High) * (j - m1High) * *probHistPtr++;
		stdDevHigh = sqrt (varHigh);

		if (stdDevLow == 0.0)
			stdDevLow = m0Low;
		if (stdDevHigh == 0.0)
			stdDevHigh = m0High;
		term1 = (m0Low != 0.0) ? m0Low * log (stdDevLow / m0Low) : 0.0;
		term2 = (m0High != 0.0) ? m0High * log (stdDevHigh / m0High) : 0.0;
		discr = term1 + term2;
		if (discr < discrM1)
			discrMin = discr;
		if (discrMin != 0.0 && discr >= discrM1)
			break;
		discrM1 = discr;
	}

	thresh = i;

	free (probHist);
#ifdef DEBUG
fprintf (stderr,"Kittler threshold: %d\n",(int) thresh);
fflush (stderr);
#endif
	return (thresh);

}






















/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                     MAIN PROGRAM                   ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

int main( int argc, char **argv )
{
DVhead head;
FILE *fp= NULL,*outFile=NULL;
char *file = NULL;
char outFilename[256] = "";
long i;
int spotWave=0,time=0;
TIFF *tiff;

/*
* The following line is commented out because it is not
* needed for UNIX.	 It IS needed for MetroWerks CodeWarrior to
* get command line arguments.
*/
#ifdef __MWERKS__
argc = ccommand(&argv);
#endif


/*
* Check to see that we got an appropriate number of arguments.  If not, print out a helpfull
* usage message to stderr.
*/
	if (argc < OUTARGS)
	{
		Do_Usage(argv[0]);
		exit (-1);
	}

	Get_Args (argc,argv,&spotWave,&time,outFilename);

/*
* Get the DV input file.
*/
	file = argv[1];
	if (file == NULL)
	{
		fprintf(stderr, "You must specify a file.\n" );
		Do_Usage(argv[0]);		
		exit(-1);
	}

/*
* Open the DV file, with error checking.
*/
	fp = fopen( file, "r" );
	if (fp == NULL)
	{
		fprintf(stderr,"File '%s' could not be opened.\n",file );
		exit(-1);
	}

/*
* OK, if we're here we got the parameters and an open DV file, so now we read the header.
* If the header-reader returned NULL, then we try to read it as TIFF.
*/

	if (! ReadDVHeader( &head, fp ) )
		{
		fclose (fp);
		tiff = ReadTIFFHeader (&head, file, &fp);
		if (! tiff)
			{
			fprintf (stderr,"'%s' doesn't seem to be a SoftWorx or a TIFF file\n",file);
			exit (-1);
			}
		spotWave = 0;
		}

/*
* Read in the Z stack of images.
*/
	theStackG = ReadDVstack(fp,&head,spotWave,time);
	if (theStackG == NULL)
		{
		fprintf(stderr,"Problem reading file or allocating memmory - EXIT\n");
		exit (-1);
		}

#ifdef DEBUG
fprintf (stderr,"read DV stack\n");
fflush (stderr);
#endif

/*
* figure out what to set the threshold to.
*/
	theStackG->spotWave = spotWave;
	theStackG->time = time;
	thresholdG = Set_Threshold (argc,argv,theStackG);
	theStackG->threshold = thresholdG;

#ifdef DEBUG
fprintf (stderr,"spotWave: %d\n",spotWave);
fprintf (stderr,"theStackG->geomean_i[spotWave]: %f\n",theStackG->geomean_i[spotWave]);
fprintf (stderr,"theStackG->sigma_i[spotWave]: %f\n",theStackG->sigma_i[spotWave]);
fflush (stderr);
#endif

#ifdef DEBUG
	fprintf (stderr,"Max:	   ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stderr,"\t%7d",(int)theStackG->max_i[i]);
	fprintf (stderr,"\n");
	
	fprintf (stderr,"Min:	   ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stderr,"\t%7d",(int)theStackG->min_i[i]);
	fprintf (stderr,"\n");
	

	fprintf (stderr,"Mean:	   ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stderr,"\t%7.1f",theStackG->mean_i[i]);
	fprintf (stderr,"\n");
	
	fprintf (stderr,"Geo. mean:");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stderr,"\t%7.1f",theStackG->geomean_i[i]);
	fprintf (stderr,"\n");
	
	fprintf (stderr,"Sigma:	   ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stderr,"\t%7.1f",theStackG->sigma_i[i]);
	fprintf (stderr,"\n");
	
	fprintf (stderr,"Integration threshold:	 %d\n",(int) thresholdG);
	fflush (stderr);
#endif


fprintf (stdout,"%d\n",(int) thresholdG);
fflush (stdout);
	
	
		
	
	
	if (strcmp (outFilename,"")) {
		outFile = fopen (outFilename,"w");
		if (outFile == NULL)
		{
			fprintf(stderr,"File '%s' could not be opened for writing.\n",outFilename );
			exit(-1);
		}
		fclose (outFile);
	
		Threshold_Pixels (theStackG,thresholdG);
	/*
	* Dump the output file
	*/
		Write_Output_File (theStackG,outFilename);
	} /* If we are outputing a binary image */


	
/*
* Exit gracefully.
*/	
	return (0);
}



void Threshold_Pixels (DVstack *theStack,long theshold) {

	if (theStack->head->nDVID == TIFF_MAGIC) {
		Threshold_TIFF (theStack,theshold);
	} else {
		Threshold_SoftWorx (theStack,theshold);
	}
}


void Threshold_TIFF (DVstack *theStack,long theshold) {
PixPtr index_in,maxIndex;
unsigned char *index_out;


	index_in = theStack->stack;
	maxIndex = index_in + theStackG->wave_increment;

	index_out = malloc (theStack->head->numCol * theStack->head->numRow);
	if (index_out == NULL) {
		fprintf (stderr,"Could not allocate memory for binary image\n");
		exit (-1);
	}
	theStack->outBuf = index_out;

	while (index_in < maxIndex) {
		if (*index_in++ > theshold) *index_out++ = 255;
		else *index_out++ = 0;
	} /* loop for all the pixels in a timepoint */
		

	
}


void Threshold_SoftWorx (DVstack *theStack,long theshold) {
PixPtr index_in,maxIndex;
unsigned short *index_out;

	index_in = theStack->stack;
	maxIndex = index_in + theStackG->wave_increment;


	index_out = index_in;

	while (index_in < maxIndex) {
		if (*index_in++ > theshold) *index_out++ = 4095;
		else *index_out++ = 0;
	} /* loop for all the pixels in a timepoint */
}
	




void Write_Output_File (DVstack *theStack,char *theFilename)
{
	if (theStack->head->nDVID == TIFF_MAGIC) Write_TIFF_File (theStack,theFilename);
	else Write_SoftWorx_File (theStack,theFilename);
}


void Write_SoftWorx_File (DVstack *theStack,char *outFilename)
{
DVhead *head;
unsigned long Rows,Cols,numZ,numWaves;
size_t numWrote;
FILE *outFile;

	outFile = fopen (outFilename,"w");
	if (outFile == NULL)
	{
		fprintf(stderr,"File '%s' could not be opened for writing.\n",outFilename );
		exit(-1);
	}

	head = theStack->head;

	Rows = head->numRow;
	Cols = head->numCol;
	numWaves = head->NumWaves;
	numZ = head->numImages / (numWaves * head->numtimes);


	head->numImages = numZ;
	head->NumWaves = 1;
	head->iwav1 = theStack->wave[theStack->spotWave];
	head->max1 = 255;
	head->min1 = 0;
	
	head->nDVID = DV_MAGIC;
	
	if (numWrote != 1) {
		fprintf (stderr,"Problem writing header to output file.\n");
		exit (-1);
	}
	
	numWrote = fwrite (theStack->stack,sizeof(pixel),Cols*Rows*numZ,outFile);
	if (numWrote != Cols*Rows*numZ) {
		fprintf (stderr,"Problem writing pixels to output file.\n");
		exit (-1);
	}
	
	fclose (outFile);
}

void Write_TIFF_File (DVstack *theStack,char *theFilename)
{
int err;
char errMsg[255];

	err=WriteTIFFData (theFilename,theStack->outBuf,8,theStack->head->numRow,theStack->head->numCol);
	if (err) {
		fprintf (stderr,"%s\n",GetReadTIFFError (err,errMsg));
	}
}


void Do_Usage (char *argv0)
{
		fprintf (stderr,"Usage:\n%s <%s> [-type=<%s> -value=<%s> -wave=<%s> -time=<%s> -out=<%s>]\n",
				argv0,"filename","threshold type","threshold value","wavelength in nm",
				"timepoint number","output file");
		fprintf (stderr,"Note that the brackets (<>) are used to delineate options in this usage message.\n");
		fprintf (stderr,"Do not use brackets when actually putting in arguments.\n");
		fprintf (stderr,"<threshold type>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"MOMENT - Moment preservation method.",
			"OTSU - Otsu's discriminant method.",
			"ME - Maximum entropy method.",
			"KITTLER - Kittler's method of minimum error.",
			"ABS - An absolute value than can be specified with the -value=<number> parameter.",
			"MEAN - Use a threshold relative to the mean of the dataset (or wavelength)",
			"GEO - Use a threshold relative to the geometric mean of the dataset (or wavelength)."
			);
		fprintf (stderr,"<threshold value>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"If -type=MEAN or -type=GEO, this floating point number will be interpreted as the number of sigmas above",
			"  or below (if negative) the mean or geometric mean of the specified wavelength",
			"If -type=ABS, this integer will be interpreted as the pixel intensity to set the threshold at.",
			"If -value is not specified, it defaults to 0.0",
			"This parameter is ignored for other threshold types."
			);
		fprintf (stderr,"-time and -wave default to the first timepoint and the first wave in a SoftWorx file\n");
		fprintf (stderr,"Output:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"The pixel intensity used for the global threshold is reported to stdout.",
			"If no output file is given with the -out parameter, no binary image will be created.",
			"The output file will be the same file type as the input file.",
			"In the case of a TIFF input file, the output file will allways be an 8-bit greyscale TIFF.",
			"For SoftWorx files, the output file will only contain the specified wavelength+timepoint",
			"The pixels in the output file below the threshold will be set to 0.",
			"The pixels above the threshold will be set to 255 for TIFF and 4095 for SoftWorx."
			);
		fprintf (stderr,"Example:\n\t%s %s\n\t%s %s\n",
			argv0,"DVfile -out=DVfile.bin -type=ME -wave=528 -time=1",
			argv0,"file.tiff -out=fileBIN.tiff -type=GEO -value=4.5");
		fprintf (stderr,"N.B.:  The file type may be TIFF or SoftWorx (DeltaVision)\n");
}
