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




#include <stdio.h>
#include <stdlib.h>
#include <math.h>
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
	float centroid_x[MAXWAVES];
	float centroid_y[MAXWAVES];
	float centroid_z[MAXWAVES];

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
int WriteDVHeader( DVhead *head, FILE *fp );
DVstack *ReadDVstack(FILE *fp,DVhead *head,long time );
void DumpDVStats (DVstack *theStack, int time, FILE *fp );
void Calculate_Stack_Stats (DVstack *inStack,int theWave);
void DumpDVStats_Geo (DVstack *theStack, int time, FILE *fp );
void Calculate_Stack_Stats_Geo (DVstack *inStack,int theWave);
PixPtr ReadDVslice (PixPtr theBuf, FILE *fp,DVhead *head,long time,long z,long w);

void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);






int main (int argc,char **argv)
{
int i,time,wave,doGeo=0,argcFiles=1;
FILE *fp;
DVhead theHead;
DVstack *theStack;

	if (argc < 2)
	{
		fprintf (stderr,"%s [-geo] file [file ...]\n",argv[0]);
		exit (-1);
	}
	
	if (!strcmp (argv[1],"-geo")) {
		doGeo = 1;
		argcFiles++;
	}
	
	
	for (i=argcFiles; i< argc; i++)
	{
		fp = fopen (argv[i],"r");
		if (!fp)
			fprintf (stderr,"File '%s' could not be opened.\n",argv[i]);
		else
		{
			if (! ReadDVHeader (&theHead,fp))
			{
				fprintf (stderr,"Could not read DeltaVision file.\n");
				exit (-1);
			}

			fprintf (stdout,"%6s\t%12s\t%6s\t%6s\t%6s\t%s\t%s\t%s\t%s\t%s\t%s\n",
				"Wave#","Wavelength","time","Min","Max","Mean","Geo Mean","Sigma","Centroid X","Centroid Y","Centroid Z");

			for (time=0;time<theHead.numtimes;time++) {
				theStack = ReadDVstack(fp,&theHead,time);
				for (wave=0;wave<theHead.NumWaves;wave++) {
					if (doGeo)
						Calculate_Stack_Stats_Geo (theStack,wave);
					else
						Calculate_Stack_Stats (theStack,wave);
				}
				if (!theStack) {
					fprintf (stderr,"Could not allocate sufficient memory for pixels.\n");
					exit (-1);
				}

				if (doGeo)
					DumpDVStats_Geo (theStack,time,stdout);
				else
					DumpDVStats (theStack,time,stdout);

				free (theStack);
			}
			fclose (fp);
		}
		
	}
	
	return (0);
}





void DumpDVStats (DVstack *theStack, int time, FILE *fp ) {
int wave;

	for (wave=0; wave < theStack->nwaves; wave++) {
		fprintf (fp,"%6d\t%12d\t%6d\t%6d\t%6d\t%f\t%s\t%f\t%f\t%f\t%f\n",
			wave,theStack->wave[wave],time,
			theStack->min_i[wave],
			theStack->max_i[wave],
			theStack->mean_i[wave],
			"",
			theStack->sigma_i[wave],
			theStack->centroid_x[wave],
			theStack->centroid_y[wave],
			theStack->centroid_z[wave]);
	}
}



void DumpDVStats_Geo (DVstack *theStack, int time, FILE *fp ) {
int wave;

	for (wave=0; wave < theStack->nwaves; wave++) {
		fprintf (fp,"%6d\t%12d\t%6d\t%6d\t%6d\t%f\t%f\t%f\t%f\t%f\t%f\n",
			wave,theStack->wave[wave],time,
			theStack->min_i[wave],
			theStack->max_i[wave],
			theStack->mean_i[wave],
			theStack->geomean_i[wave],
			theStack->sigma_i[wave],
			theStack->centroid_x[wave],
			theStack->centroid_y[wave],
			theStack->centroid_z[wave]);
	}
}



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
unsigned long Rows,Cols,numZ,num,numWaves,numRead,theZ,theW;
PixPtr theBuf;
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

	theBuf = inStack->stack;
	for (theW = 0; theW < numWaves; theW++) {
		for (theZ = 0; theZ < numZ; theZ++) {
			if (!ReadDVslice (theBuf, fp, head, time, theZ, theW)) {
				free (inStack->stack);
				free (inStack);
				fprintf (stderr,"Number of pixels in file does not match number in header.\n");
				return (NULL);
			}
			theBuf += (Cols * Rows);
		}
	}

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


PixPtr ReadDVslice (PixPtr theBuf, FILE *fp,DVhead *head,long time,long z,long w)
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
	if (theBuf == NULL) {
		thePixels = (PixPtr) malloc(Cols*Rows*sizeof(pixel));
	} else {
		thePixels = theBuf;
	}

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
* Statistics are calculated for one wavelegth at a time.
* The statistics are stored in the stack structure, so nothing is returned.
*/
void Calculate_Stack_Stats (DVstack *inStack,int theWave)
{
PixPtr index,lastPix;
float sum_i=0.0,sum_i2=0.0,numWavePix,theVal, sd,min,max;
float sum_xi=0.0,sum_yi=0.0,sum_zi=0.0;
int x=0,y=0,z=0;
int max_x,max_y;

	max_x=inStack->max_x;
	max_y=inStack->max_y;


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
	min = max = (float) *index;
/*
* crunch through pixels while we're in between the two pointers.
*/
	while (index < lastPix)
	{
		
		theVal = (float) *index;
		sum_xi += (theVal*x);
		sum_yi += (theVal*y);
		sum_zi += (theVal*z);

		sum_i += theVal;
		sum_i2 += (theVal*theVal);
/*
* offset is used so that we don't compute logs of values less than or equal to zero.
*/
/* It was decreed that these damn logs take too freakin long, OK?
		sum_log_i +=  log (theVal+offset);
*/
		if (theVal < min) min = theVal;
		if (theVal > max) max = theVal;
		index++;

		x++;
		if (x > max_x) {
			x = 0;
			y++;
		}
		
		if (y > max_y) {
			x = y = 0;
			z++;
		}
	}

/*
* Calculate the actual statistics from the accumulators
*/
	numWavePix = (float) (inStack->wave_increment);
	inStack->min_i[theWave] = min;
	inStack->max_i[theWave] = max;
	inStack->mean_i[theWave] = sum_i / numWavePix;
/*
	inStack->geomean_i[theWave] = exp ( sum_log_i / numWavePix ) - offset;
*/

	sd = sqrt ( (sum_i2	 - (sum_i * sum_i) / numWavePix)/  (numWavePix - 1.0) );
	inStack->sigma_i[theWave] = (float) fabs (sd);

	inStack->centroid_x[theWave] = sum_xi / sum_i;
	inStack->centroid_y[theWave] = sum_yi / sum_i;
	inStack->centroid_z[theWave] = sum_zi / sum_i;


}

/*#############################*/
/*#                           #*/
/*# Calculate_Stack_Stats_Geo #*/
/*#                           #*/
/*#############################*/
/*
* This function calculates some statistics for the image stack.
* Statistics are calculated for one wavelegth at a time.
* The statistics are stored in the stack structure, so nothing is returned.
*/
void Calculate_Stack_Stats_Geo (DVstack *inStack,int theWave)
{
PixPtr index,lastPix;
float sum_i=0.0,sum_i2=0.0,sum_log_i=0.0,numWavePix,theVal, sd, offset=100.0,min,max;
float sum_xi=0.0,sum_yi=0.0,sum_zi=0.0;
int x=0,y=0,z=0;
int max_x,max_y;

	max_x=inStack->max_x;
	max_y=inStack->max_y;


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
	min = max = (float) *index;
/*
* crunch through pixels while we're in between the two pointers.
*/
	while (index < lastPix)
	{
		
		theVal = (float) *index;
		sum_xi += (theVal*x);
		sum_yi += (theVal*y);
		sum_zi += (theVal*z);

		sum_i += theVal;
		sum_i2 += (theVal*theVal);
/*
* offset is used so that we don't compute logs of values less than or equal to zero.
*/
		sum_log_i +=  log (theVal+offset);
		if (theVal < min) min = theVal;
		if (theVal > max) max = theVal;
		index++;

		x++;
		if (x > max_x) {
			x = 0;
			y++;
		}
		
		if (y > max_y) {
			x = y = 0;
			z++;
		}
	}

/*
* Calculate the actual statistics from the accumulators
*/
	numWavePix = (float) (inStack->wave_increment);
	inStack->min_i[theWave] = min;
	inStack->max_i[theWave] = max;
	inStack->mean_i[theWave] = sum_i / numWavePix;
	inStack->geomean_i[theWave] = exp ( sum_log_i / numWavePix ) - offset;

	sd = sqrt ( (sum_i2	 - (sum_i * sum_i) / numWavePix)/  (numWavePix - 1.0) );
	inStack->sigma_i[theWave] = (float) fabs (sd);

	inStack->centroid_x[theWave] = sum_xi / sum_i;
	inStack->centroid_y[theWave] = sum_yi / sum_i;
	inStack->centroid_z[theWave] = sum_zi / sum_i;


}

