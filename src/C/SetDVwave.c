/* Copyright (C) 2003 Open Microscopy Environment
 * Author:  Ilya G. Goldberg <igg@nih.gov>
 * 
 *     This library is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU Lesser General Public
 *     License as published by the Free Software Foundation; either
 *     version 2.1 of the License, or (at your option) any later version.
 *
 *     This library is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *     Lesser General Public License for more details.
 *
 *     You should have received a copy of the GNU Lesser General Public
 *     License along with this library; if not, write to the Free Software
 *     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <stdio.h>
#include <stdlib.h>
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
int WriteDVHeader( DVhead *head, FILE *fp );
DVstack *ReadDVstack(FILE *fp,DVhead *head,long time );
void Calculate_Stack_Stats (DVstack *inStack,int theWave);

void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);






int main (int argc,char **argv)
{
int i;
int theWavelength;
FILE *fp;
DVhead theHead;
int numHeads;

	if (argc < 3)
	{
		fprintf (stderr,"%s nnn file [file ...]\nWhere nnn is the new wavelength value\n",argv[0]);
		exit (-1);
	}
	theWavelength = atoi (argv[1]);
	
	for (i=2; i< argc; i++)
	{
		fp = fopen (argv[i],"rw+");
		if (!fp)
			fprintf (stderr,"File '%s' could not be opened.\n",argv[i]);
		else
		{
			ReadDVHeader (&theHead,fp);
			theHead.iwav1 = theWavelength;
			numHeads = WriteDVHeader (&theHead,fp);
			if (numHeads != 1)
				fprintf (stderr,"Problem writing header to file '%s' - %d bytes written.\n",argv[i],numHeads*1024);
			fclose (fp);
		}
		
	}
	
	return (0);
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
/*#     WriteDVHeader      #*/
/*#                       #*/
/*#########################*/
/*
* This dumps the header structure into the DV file.
* it does a rewind on the file.  The position of the stream pointer is right after the head.
*/
int WriteDVHeader( DVhead *head, FILE *fp )
{
int retVal;
	rewind (fp);
	if (head->nDVID == DV_REV_ENDIAN_MAGIC)
		BSUtilsSwapHeader ( (char *)head);
	head->nDVID = DV_REV_ENDIAN_MAGIC;

	retVal = (int)fwrite( head, 1024, 1, fp );

	if (head->nDVID == DV_REV_ENDIAN_MAGIC)
		BSUtilsSwapHeader ( (char *)head);
	head->nDVID = DV_REV_ENDIAN_MAGIC;

	return (retVal);
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


