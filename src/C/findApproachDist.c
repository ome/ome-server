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




/*
Title:  findSpots
Purpose:  This program reads in a stack of Delta Vision images contained in
	a DeltaVision file.  The program then finds all "spots" that are above the specified
	threshold at the specified wavelegth, and bigger than the specified size.
	The program then reports various statistics that it has collected about these "spots" - 
	according to the user's specification.
Inputs:  There are four required inputs separated by spaces.
The order of the inputs is important.
Usage:
>findSpots <DV file> <time-point> <spot wavelngth> <threshold> <min. vol.> <output options>
<DV file> is the name of the DeltaVision file.
<time-point> If the DV file has only one time-point, enter 1.  Otherwise,
	enter the timepoint of interest.
<spot wavelegth> is the wavelegth from which to pick out "spots"
<threshold>  all contiguous pixels that are above threshold will be considered to comprise a
	single spot.
<min. val.>  All spots that are smaller in volume than this volume will not be reported.
<output options>  A set of options to specify what is displayed about each spot.  The options
	may be specified in any order, and any number of times.  The result will be a tab-delimited
	table with one row per spot.  When a wavelegth is required for an option, if a wavelegth of
	0 is specifie then the specified information will be displayed about all wavelegths that
	exist in the file, in the order in which they appear in the file.
	The output options:
	-c <wavelegth>:
		Display centroids.  Since a centroid can be thought of as a center of mass, there is
			a different centroid defined for each wavelegth because although the pixels that
			make up the spot have the same coordinates, the pixels have different values at the
			different wavelegths.  All centroids come in sets of three: x,y,z.
	-i <wavelegth>:
		Display integral.  There is one integral for each spot at each wavelegth.
	-m <wavelegth>
		Display mean pixel value for the spot at the specified wavelegth.
	-g <wavelegth>
		Display the geometric mean pixel value for the spot at the specified wavelegth.
	-ms <wavelegth>:
		Display number of standard deviations above the mean for the spot's average pixel value.
	-gs <wavelegth>
		Display number of standard deviations above the mean for the spot's geometric mean pixel value.
	-mc
		Display the average coordinate values of the spot.  This is the center of volume.
		X, Y, Z will be displayed.
	-v
		Display the spot's volume - the total number of pixels that make up the spot.
	There are other statistics that are maintained for each spot, unfortunately there
	are as yet no output options to cause them to be displayed.
Example:
findSpots DVfile 2 600 gmean2.5s 12 -v -c 600 -i 0 -mean 456
	
Algorithm:  The entire image stack is read into memory at all wavelegths.  The pixels within the
	"spot" wavelegth are traveresed one by one.  If a pixel's value at the specified wavelegth
	exceeds threshold (a seed pixel), then a function (Eat_Spots) is called to find all of the
	spot's pixels.  Eat_Spots pushes all pixels adjacent to the seed pixel onto a LIFO stack.
	Then it pops the pixels off one by one, and for each pixel poped, pushes six more
	adjacent pixels onto the stack.  Pixels are pushed onto the stack only if they
	exceed the threshold value.  This poping/pushing continues until the stack is
	empty.  This is an implementation of a recursive algorithm that is much more elegant and simple
	to understand.  Unfortunately, the depth of recursion can be quite large, and depending on how
	the OS and the compiler implement recursive calls, can be quite memory inefficient.  Also, it is
	difficult to tell in ANSI C if you are about to run out of recursive depth (i.e. stack space),
	so once you do, you get a nasty core dump.
*/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

/*
 * The following line is commented out because it is not
 * needed for UNIX.  It IS needed for MetroWerks CodeWarrior to
 * get command line arguments.  There is one more line like this in main.
#include <console.h>
 */


/* Compiler definitions used for constants */
/* #define CHUNK_SIZE 8189  8k of indexes minus 3 for the other pointers - should be 32k bytes */
#define CHUNK_SIZE 8189
#define MAXWAVES 5
#define BIGFLOAT 1.0E30
#define X_PLUS 1
#define X_MINUS 2
#define Y_PLUS 3
#define Y_MINUS 4
#define Z_PLUS 5
#define Z_MINUS 6
#define HEADING 1
#define VALUES 2
#define DV_FILE_TYPE 1
#define RAW_FILE_TYPE 2

/* define some variable types */
typedef struct dv_head DVhead;
typedef struct spotStructure SpotStruct;
typedef SpotStruct *SpotPtr;
typedef short pixel;
typedef unsigned short coordinate;
typedef pixel *PixPtr;
typedef struct dv_stack DVstack;
typedef struct IndexStackStructure IndexStackStruct;
typedef IndexStackStruct *IndexStack;
typedef struct CoordListStructure CoordListStruct;
typedef CoordListStruct *CoordList;

/* Function prototypes */
void ReadDVHeader( DVhead *head, FILE *fp );
DVstack *ReadDVstack(FILE *fp,DVhead *head,long time, DVstack *inStack );
void Write_Border_Pixels (SpotPtr spotList,DVstack *theStackG,char *borderFileName,char borderFileType);
void Calculate_Stack_Stats (DVstack *theStackG,int theWave);
void Push_Stack (PixPtr index, IndexStack theStack);
PixPtr Pop_Stack (IndexStack theStack);
void Eat_Spot_Rec (PixPtr index);
void Eat_Spot(PixPtr index);
void Update_Spot(PixPtr index);
PixPtr Update_Index (PixPtr index, char direction);
void Set_Border_Pixel (PixPtr index, IndexStack theStack);
SpotPtr New_Spot (SpotPtr spotList,DVstack *theStackG, char itsWave);
void Zero_Spot (SpotPtr theSpotG,DVstack *theStackG, char itsWave);
void Update_Spot_Stats (SpotPtr theSpotG);
void Output_Spot (SpotPtr theSpotG, DVstack *theStackG, int argc, char**argv,int outArgs, char saywhat);
int Get_Wavelngth_Index (DVstack *theStackG, int waveLngth);



/*
* this is the structure of the first 1024 bytes of the DeltaVision file.
* 
*/
struct dv_head {
	long   numCol,numRow,numImages;            /* nsec +AD0- nz-nw+ACo-nt */
	long   mode;
	long   nxst, nyst, nzst;
	long   mx, my, mz;
	float xlen, ylen, zlen;
	float alpha, beta, gamma;
	long   mapc, mapr, maps;
	float min1, max1, amean;
	long   ispg, next;
	short nDVID,nblank;          /* nblank preserves byte boundary */
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



/*
* This structure will contain the whole image stack (the entire DV file, basically)
* Note that there are two very different kinds of stack in this program - the image stack
* as defined in this structure and the LIFO stack that is used for finding spots.
*/
struct dv_stack {
	char nwaves;
	short max_x,max_y,max_z;	/* This is the width, height, thickness, respectively */
	short min_x,min_y,min_z;	/* These should be set to 0 */
	float xlen,ylen,zlen;	/* These are the width, height, depth dimmentions of the pixels */
	PixPtr stack;			/* This points to the actual image stack.  The entire stack is */
			/* a contiguous block of pixels, which is X*Y*Z*nwaves long.  The order is the */
			/* same as exists in the DV file.  All the Z sections of one wavelegth followed by */
			/* all the Z sections of the next wavelegth, etc. */

	short wave[MAXWAVES];	/* These are the wavelegths in the stack, and the order in which they */
							/* appear in the stack */
	pixel max_i[MAXWAVES];	/* each wavelegth has its own min, max, etc */
	pixel min_i[MAXWAVES];
	float mean_i[MAXWAVES];
	float geomean_i[MAXWAVES];
	float sigma_i[MAXWAVES];
	
/*
* These are pre-set to help us navigate through the stack.
* If we add y_increment to a pointer into the stack, then the pointer
* will point to the next pixel down.  Likewise for z_increment and wave_increment
*/
	unsigned long y_increment,z_increment,wave_increment;
	DVhead *head;
	SpotPtr spotList1;
	SpotPtr spotList2;
	int threshold1;
	int threshold2;
};


/*
* This structure contains the LIFO stack used by Eat_Spot.  The stack is an internal implementation
* of a recursive algotithm to find spots.  The stack contains pointers to each pixel in the spot as
* the spot is being "found".  To aliviate excessive memmory allocation/deallocation and to reduce
* the overhead associated with storing each pixel, the stack is allocated in "chunks" - each chunk
* being an array of CHUNK_SIZE pixel pointers.  Chunks are allocated and deallocated as needed
* by the pseudo-recursive algorithm Eat_Spot.  Initially, I set CHUNK_SIZE such that the structure
* occupies 32k (assuming 32 bit pointers).
* The dynamic stack is implemented as a circular double-linked list of chunks.
* The first chunk always exists, and is pointed to by theStack.  New chunks are added to
* theStack->prevChunk.  The last variable of this structure (theStack->last) contains the last
* valid index in a given stack chunk.  The last index in the stack is thus always
* theStack->prevChunk->index[theStack->prevChunk->last].  If there is more than one chunk
* in the stack, then ->last is set to CHUNK_SIZE for all chunks in the stack other than
* theStack->prevChunk (which is allways the last chunk in the stack).  The stack is empty when
* ->last becomes less than 0.  The chunks are allocated as needed in Push_Stack, and
* deallocated as needed in Pop_Stack.
*/
struct IndexStackStructure {
	PixPtr index[CHUNK_SIZE];
	IndexStack nextChunk;
	IndexStack prevChunk;
	long last; /* less than 0 if empty. */
};


/*
* This structure is a linked list of coordinates that is used to store boundary
* pixels.  The pixels are stored as X,Y,Z triplets.  The structure also has a next
* variable to point to the next set of coordinates.
*/
struct CoordListStructure {
	coordinate X,Y,Z;
	CoordList next;
};




/*
 * This is the structure that is used to store information about each
 * spot.  The list of spots is a circular double-linked list.  New spots are added
 * before the head of the list.
 */
struct spotStructure {
    long ID;
    char nwaves;
    char itsWave;  /* this is the wave index for the wavelegth that this
                        is a spot from */

/*
* When looking for spots, these bounds are used to set the spot limits.  They
* may be different from the bounds of the image stack.
*/
    short clip_Xmin,clip_Ymin,clip_Zmin;
    short clip_Xmax,clip_Ymax,clip_Zmax;

/*
* These statistics pertain to the individual spot.
*/
    short min_x,min_y,min_z;
    short max_x,max_y,max_z;
    float mean_x,mean_y,mean_z;
    float sigma_x,sigma_y,sigma_z;

/* number of pixels that make up the spot */
    unsigned long volume;

/* The maximum size of the stack generated to find the spot. */
    unsigned long max_stack;
                      
/*
* This is the integral - sum of intensisties of the pixels that make up the spot.
* There is a value for each wavelegth.  Same for the rest of the intensity stats.
* note that the centroid is dependent on intensity - not only the coordinates, so
* there is a centroid for each of the wavelegths.
*/
    float sum_i[MAXWAVES];
    float sum_i2[MAXWAVES];
    float min_i[MAXWAVES];
    float max_i[MAXWAVES];
    float mean_i[MAXWAVES];
    float geomean_i[MAXWAVES];
    float sigma_i[MAXWAVES];

    float centroid_x[MAXWAVES];
    float centroid_y[MAXWAVES];
    float centroid_z[MAXWAVES];

/*
* These accumulators are used to calculate the centroids.
*/
    float sum_xi[MAXWAVES];
    float sum_yi[MAXWAVES];
    float sum_zi[MAXWAVES];

/*
* These accumulators are used to calculate position information.
*/
    float sum_x, sum_y, sum_z;
    float sum_x2, sum_y2, sum_z2;

/*
* These values are used internally in the recursive spot-finding algorithm to keep
* track of where we are.  They have no meaning outside of the algorithm.
*/
    short cur_x,cur_y,cur_z;

/*
* this is a linked list of border pixels around the spot.
*/
	CoordList borderPixels;

/*
* this is the distance of closest approach to a spot in spotList1.
*/
	float approach;

/*
* This is a circular double-linked list for ease of maneuverability.
* New members are added to the head->previous. New memeber->next then
* points to the head, and new member->previous points to the old head->previous.
*/

	SpotPtr next;
	SpotPtr previous;
	SpotPtr head;
	DVstack *itsStack;

};



/*
* These variables are global - basically because we don't want to be allocating
* stack memory for them when we are in the recursive algorithm.
*/

DVstack *theStackG;
SpotPtr theSpotG;
pixel thresholdG;
long stack_size = 0;
unsigned long max_stack_size = 0;
char doBorderG=1;






/*
* This just fills the header structure with what's in the file.
*/
void ReadDVHeader( DVhead *head, FILE *fp )
{
	fread( head, 1024, 1, fp );
}


void Write_Border_Pixels (
	SpotPtr spotList,
	DVstack *theStackG,
	char *borderFileName,
	char borderFileType)
{
typedef pixel *PixPtrDV;
typedef unsigned char *PixPtrRAW;
unsigned long Rows,Cols,numZ,numWaves;
DVhead *head;
PixPtrDV indexDV,max_indexDV,imageStackDV;
PixPtrRAW indexRAW,max_indexRAW,imageStackRAW;
SpotPtr theSpot;
CoordList theCoord;
FILE *fp;
int i;
pixel DVval;



	head = theStackG->head;
	Rows = head->numRow;
	Cols = head->numCol;
	numWaves = head->NumWaves;
	numZ = head->numImages / (numWaves * head->numtimes);
/*
* De-allocate memory for the DVimage stack.
*/
	free(theStackG->stack);

/*
* Allocate memory for one set of Z sections, and set all pixels to 0
*/
	if (borderFileType == DV_FILE_TYPE)
		{
		imageStackDV = (PixPtrDV) malloc (sizeof(pixel)*Rows*Cols*numZ);
		indexDV = imageStackDV;
		max_indexDV = indexDV+(Rows*Cols*numZ);
		while (indexDV < max_indexDV)
			*indexDV++ = 0;
		}
	else
		{
		imageStackRAW = (PixPtrRAW) malloc (sizeof(char)*Rows*Cols*numZ);
		indexRAW = imageStackRAW;
		max_indexRAW = indexRAW+(Rows*Cols*numZ);
		while (indexRAW < max_indexRAW)
			*indexRAW++ = 0;
		}
	
/*
* Go down the list of spots, and set every pixel in borderPixels to 255
*/
	theSpot = spotList;
	do
		{
		if (theSpot->volume > 0)
			{
			while (theSpot->borderPixels != NULL)
				{
				theCoord = theSpot->borderPixels;
				theSpot->borderPixels = theSpot->borderPixels->next;
				DVval = theStackG->max_i[spotList->itsWave];
				if (borderFileType == DV_FILE_TYPE)
					{
					indexDV = imageStackDV + theCoord->X;
					indexDV += (theCoord->Y*Cols);
					indexDV += (theCoord->Z*(Cols*Rows) );
					*indexDV = DVval;
					}
				else
					{
					indexRAW = imageStackRAW + theCoord->X;
					indexRAW += (theCoord->Y*Cols);
					indexRAW += (theCoord->Z*(Cols*Rows) );
					*indexRAW = 255;
					}
				} /* plotting border pixels */
			} /* if the spot volume > 0 */
		theSpot = theSpot->next;
		
		} while (theSpot != spotList);

	if (borderFileType == DV_FILE_TYPE)
		{
		fp = fopen (borderFileName,"w+");
		if (fp == NULL)
			{
			fprintf (stderr,"Could not open %s to write spot borders.\n",borderFileName);
			return;
			}
		head->NumWaves = 1;
		head->numtimes = 1;
		head->numImages = numZ;
		head->iwav1 = theStackG->wave[spotList->itsWave];
		head->max1 = theStackG->max_i[spotList->itsWave];
		head->min1 = theStackG->min_i[spotList->itsWave];
		fwrite( head, 1024, 1, fp );
		fwrite(imageStackDV, sizeof(pixel), Cols*Rows*numZ, fp );
		fclose (fp);
		}
	else
		{
		char tempFileName[255];
		indexRAW = imageStackRAW;
		for (i=0;i<numZ;i++)
			{
			sprintf (tempFileName,"%sZ%03d",borderFileName,i+1);
			if ( (fp=fopen(tempFileName,"w+"))==NULL)
				{
				fprintf (stderr,"Couldn't open %s to write spot borders.\n",tempFileName);
				return;
				}
			fwrite (indexRAW,sizeof (char),Cols*Rows,fp);
			indexRAW += (Cols*Rows);
			}
		}
		
}



/*
* This reads the whole DV file into memory, and returns a pointer to the stack
* structure.  This routine expects an open file pointer for the DV file, a 
* pointer to a valid and filled-in head structure, and the time-point.
* This entire program assumes that there is only one time-point in the DV file.
* A time-point can easily be specified in the input arguments for files with more than
* one time-point.
* A stack may be passed to this function, in which case it will simply re-red the entire
* DV file.  None of the values of inStack will be affected - only the data pointed to by
* inStack->stack.
* In this case, the routine will return NULL if there was a problem
* such as not enough pixels in the DV file specified.  Although the data in this case
* is almost certainly corrupted, nothing in inStack will be changed.
*/

DVstack *ReadDVstack(FILE *fp,DVhead *head,long time, DVstack *inStack )
{
unsigned long Rows,Cols,numZ,num,numWaves,numRead;
char freeOnError = 0;

	Rows = head->numRow;
	Cols = head->numCol;
	numWaves = head->NumWaves;
	numZ = head->numImages / (numWaves * head->numtimes);


/*
* Allocate memory for the structure if what was passed in is NULL.
* If it is not NULL, then assume we are just re-reading the actual data.
* leave everything inStack untouched.
*/
	if (inStack == NULL)
		{
		freeOnError = 1;
		inStack = (DVstack *) malloc (sizeof (DVstack));
		if (inStack == NULL)
			return (NULL);
	/*
	* Allocate memory for the pixels.
	* To be good citizens, its good to deallocate what was successfully
	* allocated before aborting due to an error.
	*/
		inStack->stack = (PixPtr) malloc(Cols*Rows*numZ*numWaves*sizeof(pixel));
		if (inStack->stack == NULL)
			{
			free (inStack);
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
		inStack->wave[0] = head->iwav1;
		inStack->max_i[0] =  head->max1;
		inStack->min_i[0] =  head->min1;
		inStack->mean_i[4] = 0;
		inStack->wave[1] = head->iwav2;
		inStack->max_i[1] =  head->max2;
		inStack->min_i[1] =  head->min2;
		inStack->mean_i[4] = 0;
		inStack->wave[2] = head->iwav3;
		inStack->max_i[2] =  head->max3;
		inStack->min_i[2] =  head->min3;
		inStack->mean_i[4] = 0;
		inStack->wave[3] = head->iwav4;
		inStack->max_i[3] =  head->max4;
		inStack->min_i[3] =  head->min4;
		inStack->mean_i[4] = 0;
		inStack->wave[4] = head->iwav5;
		inStack->max_i[4] =  head->max5;
		inStack->min_i[4] =  head->min5;
		inStack->mean_i[4] = 0;
	
		inStack->xlen = head->xlen;
		inStack->ylen = head->ylen;
		inStack->zlen = head->zlen;
		
		inStack->spotList1 = NULL;
		inStack->spotList2 = NULL;
		}

/*
* This is the number of images before the time-point we want.
* time is assumed to be 0 in main.
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
	
	/*
	* Do not free any memory if a stack was passed to this routine.
	*/
		if (freeOnError)
			{
			free (inStack->stack);
			free (inStack);
			}
		return (NULL);
		}


	return (inStack);
}



/*
* This function calculates some statistics for the image stack.
* Statistics are calculated for one wavelegth at a time.
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

	sd = sqrt ( (sum_i2  - (sum_i * sum_i) / numWavePix)/  (numWavePix - 1.0) );
	inStack->sigma_i[theWave] = (float) fabs (sd);
}







/*
* Puts index on the stack if *index > thresholdG, and index != NULL.
* index can be NULL if Update_Index determines we went out-of-bounds.
* The stack is dynamically allocated.  Each stack chunk
* contains an array of CHUNK_SIZE indexes, a pointer to the next chunk, a pointer
* to the last chunk, and a local index to the last entry in the array.
*/
void Push_Stack (PixPtr index, IndexStack theStack)
{
IndexStack lastChunk;

/*
* Determine if we are at a border pixel.  There are two kinds of border pixels.  We treat them
* the same, but they have slightly different meanings. If a spot bleeds over the edge of the image,
* then the border of the image determines one of the spot borders.  In this case a border pixel
* will actually be a spot pixel.  If the index was set to NULL by Update_Index we are at the
* spot border as determioned by the image border.
* Otherwise, the border pixels are the ones just outside the spot, and *index will be
* less than threshold.  This kind of border pixels is not a spot pixel.
* Either way, we set a border pixel and return.
*/
	if ( index == NULL )
		{
		Set_Border_Pixel (index,theStack);
		return;
		}
	else if (*index < 0)
		return;
	else if (*index < thresholdG)
		{
		Set_Border_Pixel (index, theStack);
		return;
		}

/*
* Get a pointer to the last chunk in the stack, and increment its index.
*/
	lastChunk = theStack->prevChunk;
	lastChunk->last++;

/*
* If incrementing the index results in exceeding the array bounds, then we need to
* allocate another chunk.
*/
	if (!(lastChunk->last < CHUNK_SIZE))
		{
		IndexStack newChunk;

	/*
	* Make sure that we never go beyond CHUNK_SIZE.
	*/
		lastChunk->last = CHUNK_SIZE;
	
	/*
	* Get a new chunk and make sure we have the memory.
	*/
		newChunk = (IndexStack) malloc (sizeof (IndexStackStruct));
		if (newChunk == NULL)
			{
			fprintf (stderr,"FATAL ERROR: Could not allocate memory for pixel indexes.\n");
			exit (-1);
			}
	
	/*
	* Link the new chunk into the circular double-linked list.
	* The new chunk comes in as the chunk right before theStack - it will be pointed to
	* by theStack->prevChunk.
	*/
		newChunk->nextChunk = theStack;
		newChunk->prevChunk = theStack->prevChunk;
		lastChunk->nextChunk = newChunk;
		theStack->prevChunk = newChunk;
		lastChunk = newChunk;
		lastChunk->last = 0;
		}
	
/*
* At this point, lastChunk points to a non-full chunk, and lastChunk->last points
* to the first available index in lastChunk.
*/
	lastChunk->index[lastChunk->last] = index;

/* Increment the counter that keeps track of the maximum stack size. */
	stack_size++;
	if (stack_size > max_stack_size)
		max_stack_size = stack_size;
	
}




/*
* This function returns the last index in the LIFO stack.  It deallocates memmory if
* returning the last index in a chunk.  It won't free the very last chunk in the stack - the
* one pointed to by theStack.
*/
PixPtr Pop_Stack (IndexStack theStack)
{
PixPtr theIndex;
IndexStack lastChunk;


/* the last chunk of the stack is allways theStack->prevChunk */
	lastChunk = theStack->prevChunk;
	
/* If prevChunk->last is less than 0, the stack is empty, so return NULL. */
	if (lastChunk->last < 0)
		return (NULL);

/* The last index in the stack is just what this says: */
	theIndex = lastChunk->index[lastChunk->last];

/* Decrement lastChunk->last because we're reducing the size of the stack. */
	lastChunk->last--;

/*
* If last got bellow zero, then this index emptied this stack chunk.  We
* de-allocate memory, but only if there is more than one chunk.
*/
	if ((lastChunk->last < 0) && (lastChunk != theStack))
		{
	
	/*
	* Since we are always deallocating theStack->prevChunk, make sure
	* the stack is still stitched together properly.
	*/
		theStack->prevChunk = lastChunk->prevChunk;
		theStack->prevChunk->nextChunk = theStack;
		free (lastChunk);
	
	/*
	* Since we deallocated, now the lastChunk->last must be de-cremented so
	* that it points to a valid index.
	*/
		theStack->prevChunk->last--;
		}
/*
* De-crement stack_size, which keeps track of maximum stack size.
*/
	stack_size--;

/*
* Finally, return the last index in the stack.
*/
	return (theIndex);
}







void Eat_Spot (PixPtr index)
{
static IndexStack theStack;

	if (theStack == NULL)
		{
		theStack = (IndexStack) malloc (sizeof(IndexStackStruct));
		if (theStack == NULL)
			{
			fprintf (stderr,"FATAL ERROR: Could not allocate memory for pixel indexes.\n");
			exit (-1);
			}
		theStack->nextChunk = theStack;
		theStack->prevChunk = theStack;
		theStack->last = -1;
		}
	
	Update_Spot (index);
	*index = -(*index);
	Push_Stack (Update_Index(index,X_PLUS),theStack);
	Push_Stack (Update_Index(index,X_MINUS),theStack);
	Push_Stack (Update_Index(index,Y_PLUS),theStack);
	Push_Stack (Update_Index(index,Y_MINUS),theStack);
	Push_Stack (Update_Index(index,Z_PLUS),theStack);
	Push_Stack (Update_Index(index,Z_MINUS),theStack);
	index = Pop_Stack (theStack);
	while (index != NULL)
		{
		if (*index > thresholdG)
			{
			Update_Spot (index);
			*index = thresholdG;
			Push_Stack (Update_Index(index,X_PLUS),theStack);
			Push_Stack (Update_Index(index,X_MINUS),theStack);
			Push_Stack (Update_Index(index,Y_PLUS),theStack);
			Push_Stack (Update_Index(index,Y_MINUS),theStack);
			Push_Stack (Update_Index(index,Z_PLUS),theStack);
			Push_Stack (Update_Index(index,Z_MINUS),theStack);
			}
		index = Pop_Stack (theStack);
		}
}

/*
* This is the core of the recursive algorithm.  It calls two accessory functions
* to do some calculations.  These should not add to the stack load (recursion depth).
* The three algorithms use the global variables defined above, specified in the
* commented-out declarations.  The pixel location is passed around recursively
* as a pointer to the pixel.  This saves some stack space compared to three
* coordinates, and is also usefull in that most of the time we are going to be
* looking at pixels that are <= threshold, which is a lot faster if we just look
* under the pointer.  Of course we need to calculate the coordinates backwards
* from the pointer once we do get to a valid pixel.
*
* This algorithm is no longer used by this program, but I thought I would leave it in
* for posterity.
*/
void Eat_Spot_Rec (PixPtr index)
{
/*
extern pixel thresholdG;
*/

/*
* Update_Index returns NULL if we try to go out of bounds (theSpotG->clip),
* so we should check for that first, and return immediately.
*/
	if (index == NULL) return;

/*
* Also, we want to return if the index is pointing to a pixel less than or
* equal to threshold.
*/
	if (*index <= thresholdG) return;

/*
* At this point index is pointing at a spot pixel, so we call Update_Spot
* to update the spot statistics with this pixel.
*/
	Update_Spot (index);

/*
* To prevent re-considering this pixel, we set it to its negative.
*/
	*index = -*index;

/*
* For each of the six directions, we call Update_Index with a direction, which returns
* a new index which we immediately pass recursively to Eat_Spot.
*/
	Eat_Spot (Update_Index(index,X_PLUS));
	Eat_Spot (Update_Index(index,X_MINUS));
	Eat_Spot (Update_Index(index,Y_PLUS));
	Eat_Spot (Update_Index(index,Y_MINUS));
	Eat_Spot (Update_Index(index,Z_PLUS));
	Eat_Spot (Update_Index(index,Z_MINUS));
	return;
}



/*
* This functions assumes index points to a valid spot pixel, and updates the 
* spot accumulators in the global spot structure.
*/
void Update_Spot(PixPtr index)
{
/*
extern SpotPtr theSpotG;
extern DVstack *theStackG;
*/
unsigned char i;
unsigned long index2;


/*
* We need to back-calculate the coordinates from the index.
*/

/*
 * First,  subtract the stack pointer from index,  thus getting
 * a "true" index.
 */
	index2 = index - theStackG->stack;

/*
 * Second,  subtract the wave increment to get an index into the stack.
 */
	index2 -= (theSpotG->itsWave * theStackG->wave_increment);

/*
 * The z coordinate is the wave index divided by the size of a z-section.
 * The integer division is a truncation.
 */
	theSpotG->cur_z = index2 / (theStackG->z_increment);

/*
 * Then we subtract the z coordinate * section size to get an index into the section.
 */
	index2 -= (theSpotG->cur_z * (theStackG->z_increment));

/*
 * The y coordinate is the index divided by the width.
 */
	theSpotG->cur_y = index2 / (theStackG->y_increment);

/*
 * Lastly,  if we subtract the y coordinate * width from the index,  we will be left
 * with the x coordinate.
 */
	index2 -= (theSpotG->cur_y * (theStackG->y_increment));
	theSpotG->cur_x = index2;


/*
* Set spoot coordinate maxima and minima according to the
* current coordinates.
*/
	if (theSpotG->cur_x > theSpotG->max_x)
		theSpotG->max_x = theSpotG->cur_x;
	if (theSpotG->cur_x < theSpotG->min_x)
		theSpotG->min_x = theSpotG->cur_x;
	if (theSpotG->cur_y > theSpotG->max_y)
		theSpotG->max_y = theSpotG->cur_y;
	if (theSpotG->cur_y < theSpotG->min_y)
		theSpotG->min_y = theSpotG->cur_y;
	if (theSpotG->cur_z > theSpotG->max_z)
		theSpotG->max_z = theSpotG->cur_z;
	if (theSpotG->cur_z < theSpotG->min_z)
		theSpotG->min_z = theSpotG->cur_z;

/*
* Increment the volume counter.
*/
	theSpotG->volume++;

/*
* update the coordinate accumulators and the coordinate sum of squares accumulators.
*/
	theSpotG->sum_x += theSpotG->cur_x;
	theSpotG->sum_y += theSpotG->cur_y;
	theSpotG->sum_z += theSpotG->cur_z;
	theSpotG->sum_x2 += ((float)theSpotG->cur_x * (float)theSpotG->cur_x);
	theSpotG->sum_y2 += ((float)theSpotG->cur_y * (float)theSpotG->cur_y);
	theSpotG->sum_z2 += ((float)theSpotG->cur_z * (float)theSpotG->cur_z);

/*
* Now we update all the wavelegth specific information.
* First, we set index to point at the same pixel in the first wave.
*/
	index  -= (theSpotG->itsWave * theStackG->wave_increment);

/*
* Then we do a bunch of things once for each wave.
*/
    for (i=0;i<theStackG->nwaves;i++)
    {
    
    /*
    * Update the wave-specific accumulators, minima, maxima, etc.
    */
    	theSpotG->sum_i[i] += *index;
    	theSpotG->sum_i2[i] += ((float)*index * (float)*index);
    	if (*index < theSpotG->min_i[i])
    		theSpotG->min_i[i] = *index;
    	if (*index > theSpotG->max_i[i])
    		theSpotG->max_i[i] = *index;
		theSpotG->sum_xi[i] += (float)*index * (float)theSpotG->cur_x;
		theSpotG->sum_yi[i] += (float)*index * (float)theSpotG->cur_y;
		theSpotG->sum_zi[i] += (float)*index * (float)theSpotG->cur_z;
		theSpotG->geomean_i[i] += (float) log ( (double)*index );
	
	/*
	* To get to the same pixel in the next wave, all we need to do is add
	* the size of a wave to the index.
	*/
		index += theStackG->wave_increment;
	}

    
	return;
}



/*
* This function updates the index based on a coordinate direction.
*/
PixPtr Update_Index (PixPtr index, char direction)
{
/*
extern SpotPtr theSpotG;
extern DVstack *theStackG;
*/

/*
* Initially, we set a pointer to NULL.  If we are in bounds, then it will
* be set to a valid pointer.  Otherwise, we'll return with NULL.
*/
PixPtr theIndex = NULL;



	switch (direction)
	{
	case X_PLUS:
		if (theSpotG->cur_x < theSpotG->clip_Xmax)
			theIndex = index + 1;
	break;
	case X_MINUS:
		if (theSpotG->cur_x > theSpotG->clip_Xmin)
			theIndex = index - 1;
	break;
	
	case Y_PLUS:
		if (theSpotG->cur_y < theSpotG->clip_Ymax)
			theIndex = index + theStackG->y_increment;
	break;
	case Y_MINUS:
		if (theSpotG->cur_y > theSpotG->clip_Ymin)
			theIndex = index - theStackG->y_increment;
	break;

	case Z_PLUS:
		if (theSpotG->cur_z < theSpotG->clip_Zmax)
			theIndex = index + theStackG->z_increment;
	break;
	case Z_MINUS:
		if (theSpotG->cur_z > theSpotG->clip_Zmin)
			theIndex = index - theStackG->z_increment;
	break;
	}  /* switch (direction */

	return (theIndex);
}


/*
struct CoordListStructure {
	coordinate X,Y,Z;
	CoordList next;
};
*/

void Set_Border_Pixel (PixPtr index, IndexStack theStack)
{
CoordList newPixel;

/*
* Return immediately if we're not doing the border.
*/
	if (!doBorderG) return;

/*
* allocate memory for the border pixel.  If there is not enough memory, its not
* a fatal error.  Just report that there is no memory for border pixels, free up memory
* already used for border pixels, set the doBorderG flag so we don't do any more border
* pixels, and get over it.
* It would prety much defeat the purpose of this if we were
* to report borders for only some of the spots, so we do not report borders for any of them.
* If we were really good, we would free up memory for the border pixels in the other spots,
* but that I was too lazy to do that.
*/
	if ( (theSpotG->borderPixels != NULL) &&
	    (theSpotG->cur_x == theSpotG->borderPixels->X) &&
	    (theSpotG->cur_y == theSpotG->borderPixels->Y) &&
	    (theSpotG->cur_z == theSpotG->borderPixels->Z) )
		return;
	newPixel = (CoordList) malloc (sizeof(CoordListStruct));
	if (newPixel == NULL)
		{
		SpotPtr theSpot;

		fprintf (stderr,"Could not allocate memory to store spot border pixels.\n");
		fprintf (stderr,"No border pixels will be reported.\n");
		doBorderG = 0;
		theSpot = theSpotG;
		do
			{
			while (theSpotG->borderPixels != NULL)
				{
				newPixel = theSpotG->borderPixels;
				theSpotG->borderPixels = theSpotG->borderPixels->next;
				free (newPixel);
				}
			theSpot = theSpot->next;
			} while (theSpot != theSpotG);
		return;
		}
	
	newPixel->X = theSpotG->cur_x;
	newPixel->Y = theSpotG->cur_y;
	newPixel->Z = theSpotG->cur_z;
	newPixel->next = theSpotG->borderPixels;
	theSpotG->borderPixels = newPixel;
	return;
}





/*
* This routine allocates memory for a new spot, links it to the spot list,
* and calls Zero_Spot to 
* initialize all the variables of the spot structure and make it ready to use.
*/
SpotPtr New_Spot (SpotPtr spotList,DVstack *inStack, char itsWave)
{
SpotPtr newSpot=NULL;


/*
* Allocate memory with error-checking.
*/
	newSpot = (SpotPtr) malloc (sizeof(struct spotStructure));
	if (newSpot == NULL)
		return (NULL);

/*
* There are two possible conditions.  Either this is the first spot in the list, or
* this is not the first spot in the list.
* If the list pointer that got passed is NULL, then this is the first spot in the list, 
* so the new spot's previous and next pointers point to itself.
* If spotList is not NULL, then we have to add this spot to the list.  It will be added
* just before the head of the list - or, since this is a circular list, at the end.
*/
	if (spotList != NULL)
		{
	/*
	* newSpot's previous points to what the spotList's previous used to point to.
	* newSpot's next points to the spotList.
	* the spotList's previous points to the newSpot,
	* The spot that used to be before spotList now has its next pointing to newSpot.
	*/
		newSpot->previous = spotList->previous;
		newSpot->next = spotList;
		spotList->previous->next = newSpot;
		spotList->previous = newSpot;
		newSpot->ID = newSpot->previous->ID + 1;
		newSpot->head = spotList;
		}
	/* brand new spot list */
	else
		{
		newSpot->previous = newSpot;
		newSpot->next = newSpot;
		newSpot->ID = 1;
		newSpot->head = newSpot;
		}

/*
* Zero-out the accumulators, etc.
*/
	newSpot->borderPixels = NULL;
	newSpot->itsStack = inStack;
	Zero_Spot (newSpot, inStack, itsWave);
	
	return (newSpot);
}





void Zero_Spot (SpotPtr zeroSpot,DVstack *itsStack, char itsWave)

{
unsigned char i;
CoordList borderPixel;

	zeroSpot->nwaves = itsStack->nwaves;
	zeroSpot->itsWave = itsWave;
	zeroSpot->clip_Xmin = itsStack->min_x;
	zeroSpot->clip_Xmax = itsStack->max_x;
	zeroSpot->clip_Ymin = itsStack->min_y;
	zeroSpot->clip_Ymax = itsStack->max_y;
	zeroSpot->clip_Zmin = itsStack->min_z;
	zeroSpot->clip_Zmax = itsStack->max_z;

/*
* Note that these are set backwards !
*/
	zeroSpot->min_x = itsStack->max_x;
	zeroSpot->max_x = itsStack->min_x;
	zeroSpot->min_y = itsStack->max_y;
	zeroSpot->max_y = itsStack->min_y;
	zeroSpot->min_z = itsStack->max_z;
	zeroSpot->max_z = itsStack->min_z;

	zeroSpot->mean_x = zeroSpot->mean_y = zeroSpot->mean_z = 0;
	zeroSpot->sigma_x = zeroSpot->sigma_y = zeroSpot->sigma_z = 0;
	zeroSpot->volume = 0;
    zeroSpot->sum_x = zeroSpot->sum_y = zeroSpot->sum_z = 0;
    zeroSpot->sum_x2 = zeroSpot->sum_y2 = zeroSpot->sum_z2 = 0;
    zeroSpot->cur_x = zeroSpot->cur_y = zeroSpot->cur_z = 0;

	for (i=0;i<itsStack->nwaves;i++)
		{
		zeroSpot->centroid_x[i] = 0;
		zeroSpot->centroid_y[i] = 0;
		zeroSpot->centroid_z[i] = 0;
		zeroSpot->sum_i[i] = 0;
		zeroSpot->sum_i2[i] = 0;
		zeroSpot->min_i[i] = BIGFLOAT;
		zeroSpot->max_i[i] = 0;
		zeroSpot->mean_i[i] = 0;
		zeroSpot->geomean_i[i] = 0;
		zeroSpot->sigma_i[i] = 0;
		zeroSpot->sum_xi[i] = 0;
		zeroSpot->sum_yi[i] = 0;
		zeroSpot->sum_zi[i] = 0;
		}
	while (zeroSpot->borderPixels != NULL)
		{
		borderPixel = zeroSpot->borderPixels;
		zeroSpot->borderPixels = zeroSpot->borderPixels->next;
		free (borderPixel);
		}

}







/*
* This routine gets called after the accumulators are filled in order to calculate some final
* statistics.
*/
void Update_Spot_Stats (SpotPtr updateSpot)
{
char i;
float spotVol,toX,toY,toZ,fromX,fromY,fromZ,xlen,ylen,zlen;
double theDist,minDist=1e30;
SpotPtr toSpot;
CoordList toCoord;
int wave1;

	spotVol = (float) updateSpot->volume;
	updateSpot->mean_x = updateSpot->sum_x / spotVol;
	updateSpot->mean_y = updateSpot->sum_y / spotVol;
	updateSpot->mean_z = updateSpot->sum_z / spotVol;
	updateSpot->sigma_x = sqrt ((updateSpot->sum_x2-(updateSpot->sum_x*updateSpot->sum_x)/spotVol)/(spotVol-1.0));
	updateSpot->sigma_y = sqrt ((updateSpot->sum_y2-(updateSpot->sum_y*updateSpot->sum_y)/spotVol)/(spotVol-1.0));
	updateSpot->sigma_z = sqrt ((updateSpot->sum_z2-(updateSpot->sum_z*updateSpot->sum_z)/spotVol)/(spotVol-1.0));
	updateSpot->max_stack = max_stack_size;
	max_stack_size = 0;

	for (i=0;i<updateSpot->nwaves;i++)
	{
		updateSpot->centroid_x[i] = updateSpot->sum_xi[i] / updateSpot->sum_i[i];
		updateSpot->centroid_y[i] = updateSpot->sum_yi[i] / updateSpot->sum_i[i];
		updateSpot->centroid_z[i] = updateSpot->sum_zi[i] / updateSpot->sum_i[i];
		updateSpot->sigma_i[i] = sqrt ((updateSpot->sum_i2[i]-(updateSpot->sum_i[i]*updateSpot->sum_i[i])/spotVol)/(spotVol-1.0));
		updateSpot->mean_i[i] = updateSpot->sum_i[i] / spotVol;
		updateSpot->geomean_i[i] = exp (updateSpot->geomean_i[i] / spotVol );
	}
	
	toSpot = updateSpot->itsStack->spotList1;
	if (toSpot == NULL)
		return;
	wave1 = toSpot->itsWave;
	xlen = updateSpot->itsStack->xlen;
	ylen = updateSpot->itsStack->ylen;
	zlen = updateSpot->itsStack->zlen;
	fromX = updateSpot->centroid_x[updateSpot->itsWave] * xlen;
	fromY = updateSpot->centroid_y[updateSpot->itsWave] * ylen;
	fromZ = updateSpot->centroid_z[updateSpot->itsWave] * zlen;
	if (updateSpot->head == updateSpot->itsStack->spotList2)
		{
		do
			{
			toCoord = toSpot->borderPixels;
			while (toCoord != NULL)
				{
				toX = toCoord->X * xlen;
				toY = toCoord->Y * ylen;
				toZ = toCoord->Z * zlen;
				theDist = ((toX-fromX)*(toX-fromX)) + ((toY-fromY)*(toY-fromY)) + ((toZ-fromZ)*(toZ-fromZ));
				theDist = sqrt (theDist);
				if (theDist < minDist)
					minDist = theDist;
				toCoord = toCoord->next;
				}
			toSpot = toSpot->next;
			}  while (toSpot != toSpot->head);
		minDist = 0.0 - minDist;
		if (updateSpot->mean_i[wave1] > (double)(updateSpot->itsStack->threshold1))
			minDist = 0.0 - minDist;
		updateSpot->approach = (float) minDist;
		}
}



/*
* This is the output routine.  It should be fairly straight-forward to add
* other options here if the examples are followed.
*/
void Output_Spot (SpotPtr outSpot, DVstack *itsStack, int argc, char**argv,int outArgs, char saywhat)
{
int theArg,i,theWave;


/*
* We are going to loop through the arguments. and as we encounter a valid output argument,
* write stuff to stdout.
*/
	theArg = outArgs;
	while (theArg < argc)
	{
/* -v :  Ouput volume */
		if (!strcmp ( argv[theArg],"-v"))
		{
			if (saywhat == HEADING)
			    fprintf (stdout,"volume ");
			else
			    fprintf (stdout,"%7ld",outSpot->volume);

		/* If there are more arguments to come, spit out a tab character. */
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
		} /* -v */
	
/* -d :  Ouput minimum distance between wavelegth1 spot boundary and wavelegth2 centroid */
		if (!strcmp ( argv[theArg],"-d"))
		{
			if (saywhat == HEADING)
			    fprintf (stdout,"dist.  ");
			else
			    fprintf (stdout,"%7.2f",outSpot->approach);

		/* If there are more arguments to come, spit out a tab character. */
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
		} /* -v */
	

/* -stack :  Ouput maximum stack size */
		if (!strcmp ( argv[theArg],"-stack"))
		{
			if (saywhat == HEADING)
			    fprintf (stdout,"stack  ");
			else
			    fprintf (stdout,"%7ld",outSpot->max_stack);

		/* If there are more arguments to come, spit out a tab character. */
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
		} /* -stack */
	

/* -mc :  Ouput mean coordinates (center of volume)  */
		else if (!strcmp ( argv[theArg],"-mc"))
		{
			if (saywhat == HEADING)
			    fprintf (stdout,"mean X\tmean Y\tmean Z");
			else
			    fprintf (stdout,"%6.1f\t%6.1f\t%6.1f",
				outSpot->mean_x,outSpot->mean_y,outSpot->mean_z);
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
		} /* -mc */
	
	
	
/* -c <n> :  Ouput centroids (center of mass - different at each wavelegth) */
		else if (!strcmp ( argv[theArg],"-c"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout,"c[%3d]X\tc[%3d]Y\tc[%3d]Z",
							itsStack->wave[theWave], 
							itsStack->wave[theWave], 
							itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.1f\t%7.1f\t%7.1f",
							outSpot->centroid_x[theWave],
							outSpot->centroid_y[theWave],
							outSpot->centroid_z[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, "c[%3d]X\t   Y   \t   Z   ",itsStack->wave[i]);
				else
					fprintf (stdout,"%7.1f\t%7.1f\t%7.1f",
						outSpot->centroid_x[i],
						outSpot->centroid_y[i],
						outSpot->centroid_z[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -c */
	
	
/* -i <n> :  Ouput Integrals */
		else if (!strcmp (argv[theArg],"-i"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout, " i[%3d]  ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%9.1f",outSpot->sum_i[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, " i[%3d]  ",itsStack->wave[i]);
				else
					fprintf (stdout,"%9.1f",outSpot->sum_i[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -i */



/* -m <n> :  Ouput means */
		else if (!strcmp (argv[theArg],"-m"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout, "m[%3d] ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.1f",outSpot->mean_i[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, "m[%3d] ",itsStack->wave[i]);
				else
					fprintf (stdout,"%7.1f",outSpot->mean_i[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -m */



/* -ms <n> :  Ouput means - number of standard deviations above the wavelegth's mean */
		else if (!strcmp (argv[theArg],"-ms"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout, "ms[%3d]",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.3f",
							(outSpot->mean_i[theWave]-itsStack->mean_i[theWave])/itsStack->sigma_i[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, "ms[%3d]",itsStack->wave[i]);
				else
					fprintf (stdout,"%7.3f",
						(outSpot->mean_i[i]-itsStack->mean_i[i])/itsStack->sigma_i[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -ms */



/* -g <n> :  Ouput geometric means */
		else if (!strcmp (argv[theArg],"-g"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout, "g[%3d] ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.1f",outSpot->geomean_i[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, "g[%3d] ",itsStack->wave[i]);
				else
					fprintf (stdout,"%7.1f",outSpot->geomean_i[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -g */



/* -gs <n> :  Ouput geometric means - number of standard deviations above the wavelegth's geometric mean */
		else if (!strcmp (argv[theArg],"-gs"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				theWave = Get_Wavelngth_Index (itsStack,theWave);
				if (theWave < outSpot->nwaves)
					if (saywhat == HEADING)
						fprintf (stdout, "gs[%3d]",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.3f",
							(outSpot->geomean_i[theWave]-itsStack->geomean_i[theWave])/itsStack->sigma_i[theWave]);
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout, "gs[%3d]",itsStack->wave[i]);
				else
					fprintf (stdout,"%7.3f",
						(outSpot->geomean_i[i]-itsStack->geomean_i[i])/itsStack->sigma_i[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			if (theArg+1 < argc)
				fprintf (stdout,"\t");
			theArg++;
		} /* -gs */




	theArg++;
	} /* while theArg < argc */

	fprintf (stdout,"\n");
	fflush (stdout);
}



/*
* This routine gets used by the output routine to easily get the
* wave index from a wavelegth.  If the specified wavelegth does not
* exist in the DVstack, then an out-of-bounds index is returned (MAXWAVES+1).
*/
int Get_Wavelngth_Index (DVstack *inStack, int waveLngth)
{
int theWaveIndx,i;

	theWaveIndx = MAXWAVES+1;
	for (i=0; i < MAXWAVES; i++)
		if (inStack->wave[i] == waveLngth) theWaveIndx = i;
	return (theWaveIndx);
}





int main( int argc, char **argv )
{
int outArg = 9;
DVhead head;
FILE *fp= NULL;
char *file = NULL;
char *borderFileName = NULL;
char borderFileType;
long i;
int theTimePoint;
int spotWaveLngth1,spotWave1,minSpotVol1,theThreshold1;
int spotWaveLngth2,spotWave2,minSpotVol2,theThreshold2;
PixPtr index,maxIndex;
SpotPtr theSpotList1,theSpotList2;
float nSigmas;


/*
 * The following line is commented out because it is not
 * needed for UNIX.  It IS needed for MetroWerks CodeWarrior to
 * get command line arguments.
argc = ccommand(&argv);
 */

/*
 * Write the command line arguments to stdout - mainly so that
 * the command line ends up in a log file.
 */
	for (i=0;i<argc;i++)
		fprintf (stdout,"%s ",argv[i]);
	fprintf (stdout,"\n");

/*
* first we read in the parameters from the command line.
*/
	if (argc < 6)
	{
		fprintf (stderr,"Usage:\n%s <%s> <%s> <%s> <%s> <%s> <%s> <%s> <%s> <%s>\n",
				argv[0],"DV filename","time point","spot wavelegth1","threshold1","min. spot vol.1",
				"spot wavelegth2","threshold2","min. spot vol.2",
				"output arguments");
		fprintf (stderr,"Note that the brackets (<>) are used to delineate options in this usage message.\n");
		fprintf (stderr,"Do not use brackets when actually putting in arguments.\n");
		fprintf (stderr,"<thresholds>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"number:  If a number is entered for this field, then it will be used as the threshold.",
			"mean:  The mean pixel value at the specified wavelegth will be used as the threshold.",
			"mean<n>s:  The mean pixel value plus <n> standard deviations will be used as threshold.",
			"gmean:  The geometric mean of the specified wavelegth will be used as threshold.",
			"gmean<n>s:  The geometric mean plus <n> standard deviations will be used for threshold.");
		fprintf (stderr,"<Output arguments>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"-c <wavelegth>: Display centroids (center of mass).",
			"-d display the minimum distance between centroids of wavelegth2 spots and boundaries of wavelegth1 spots",
			"-i <wavelegth>:  Display integral - sum of pixel values",
			"-m <wavelegth> Display mean pixel value.",
			"-g <wavelegth> Display the geometric mean pixel value.",
			"-ms <wavelegth> Same as -m, but number of std. deviations over the wavelegth's mean.",
			"-gs <wavelegth> Same as -g, but number of std. deviations over the wavelegth's geometric mean.",
			"-mc Display the average coordinate values of the spot (center of volume).",
			"-v Display the spot's volume");

		exit (-1);
	}
	
	sscanf (argv[2],"%d",&theTimePoint);

	sscanf (argv[3],"%d",&spotWaveLngth1);

	sscanf (argv[5],"%d",&minSpotVol1);

	sscanf (argv[6],"%d",&spotWaveLngth2);

	sscanf (argv[8],"%d",&minSpotVol2);
	
	file = argv[1];
	if (file == NULL)
	{
		fprintf(stderr, "You must specify a file.\n" );
		exit(-1);
	}


/*
* Open the DV file, with error checking.
*/
	fp = fopen( file, "r" );
	if (fp == NULL)
	{
		fprintf(stderr,"No such file.\n" );
		exit(-1);
	}

/*
* OK, if we're here we got the parameters and an open DV file, so now we read the header.
*/
	ReadDVHeader( &head, fp );

/*
* Read in the stack of images.
*/
	theStackG = ReadDVstack(fp,&head,theTimePoint-1,NULL);
	if (theStackG == NULL)
	{
		fprintf(stderr,"Could not allocate sufficient memory to contain the immage stack.\n");
		exit (-1);
	}

/*
 * Write out the waves we found in the DV file
 */
	fprintf (stdout,"Wave:     ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7d",(int)theStackG->wave[i]);
	fprintf (stdout,"\n");
	
/*
* Get the wave index of the spot wavelegth.
*/
	spotWave1 = Get_Wavelngth_Index (theStackG, spotWaveLngth1);
	spotWave2 = Get_Wavelngth_Index (theStackG, spotWaveLngth2);
/*
* Get_Wave_Index returns an index that's out of bounds ( > waves in stack)
* if it could not find an appropriate index.
*/
	if (spotWave1 > head.NumWaves)
	{
		fprintf (stderr,"Could not find wavelength %d nm in file %s\n",
				spotWaveLngth1,file);
		exit (-1);
	}
	if (spotWave2 > head.NumWaves)
	{
		fprintf (stderr,"Could not find wavelength %d nm in file %s\n",
				spotWaveLngth2,file);
		exit (-1);
	}


/*
* Calculate statistics for the stack.
*/
	for (i=0;i<theStackG->nwaves;i++)
		Calculate_Stack_Stats (theStackG,i);


/*
* figure out what to set the threshold1 to.
*/
	if (!strncmp(argv[4],"mean",4))
		{
		nSigmas = 0;
		if (strlen (argv[4]) > 4)
			sscanf (strrchr(argv[4],'n')+1,"%fs",&nSigmas);
		theThreshold1 = (int) (theStackG->mean_i[spotWave1] + (theStackG->sigma_i[spotWave1]*nSigmas));
		}
	else if (!strncmp(argv[4],"gmean",5))
		{
		nSigmas = 0;
		if (strlen (argv[4]) > 5)
			sscanf (strrchr(argv[4],'n')+1,"%fs",&nSigmas);
		theThreshold1 = (int) (theStackG->geomean_i[spotWave1] + (theStackG->sigma_i[spotWave1]*nSigmas));
		}
	else
		sscanf (argv[4],"%d",&theThreshold1);
	theStackG->threshold1 = theThreshold1;


/*
* figure out what to set the threshold2 to.
*/
	if (!strncmp(argv[7],"mean",4))
		{
		nSigmas = 0;
		if (strlen (argv[7]) > 4)
			sscanf (strrchr(argv[7],'n')+1,"%fs",&nSigmas);
		theThreshold2 = (int) (theStackG->mean_i[spotWave2] + (theStackG->sigma_i[spotWave2]*nSigmas));
		}
	else if (!strncmp(argv[7],"gmean",5))
		{
		nSigmas = 0;
		if (strlen (argv[7]) > 5)
			sscanf (strrchr(argv[7],'n')+1,"%fs",&nSigmas);
		theThreshold2 = (int) (theStackG->geomean_i[spotWave2] + (theStackG->sigma_i[spotWave2]*nSigmas));
		}
	else
		sscanf (argv[6],"%d",&theThreshold2);
	theStackG->threshold2 = theThreshold2;





/*
* Write statistics about this file to standard output.
*/
	fprintf (stdout,"Max:      ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7d",(int)theStackG->max_i[i]);
	fprintf (stdout,"\n");
	
	fprintf (stdout,"Min:      ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7d",(int)theStackG->min_i[i]);
	fprintf (stdout,"\n");
	

	fprintf (stdout,"Mean:     ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7.1f",theStackG->mean_i[i]);
	fprintf (stdout,"\n");
	
	fprintf (stdout,"Geo. mean:");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7.1f",theStackG->geomean_i[i]);
	fprintf (stdout,"\n");
	
	fprintf (stdout,"Sigma:    ");
	for (i=0;i<theStackG->nwaves;i++)
		fprintf (stdout,"\t%7.1f",theStackG->sigma_i[i]);
	fprintf (stdout,"\n");
	
	fprintf (stdout,"Integration threshold 1:  %d\n",(int) theThreshold1);
	fprintf (stdout,"Integration threshold 2:  %d\n",(int) theThreshold2);
	fprintf (stdout,"Pixel size (X,Y,Z): (%f,%f,%f)\n",theStackG->xlen,theStackG->ylen,theStackG->zlen);
	fflush (stdout);
					
/*
* Allocate memory for the first spot.
* theSpotG will allways point to the spot-in-progress.  Once completed,
* a new spot is allocated, and that new spot is then pointed to by
* theSpotG.  In this way, theSpotG is allways the last spot in the list,
* and it is never a valid spot - it is either blank or in progress.
*
* Since we are allocating the first spot, make sure we set spotList to it.
*/

	theSpotG = New_Spot (NULL,theStackG,spotWave1);
	theSpotList1 = theSpotG;
	theStackG->spotList1 = theSpotList1;
	if (theSpotG == NULL)
	{
		fprintf (stderr,"Could not allocate memory for spot.\n");
		exit (-1);
	}

	thresholdG = (pixel) theThreshold1;

/*
* Set index to point to the first pixel in the wave which we will use
* to pick out spots.
*/
	index = theStackG->stack + (theStackG->wave_increment*spotWave1);

/*
* Set a pointer to the end of this wave.
*/
	maxIndex = index + theStackG->wave_increment;

/*
* Run through the pixels in spotWave, making spots.
*/
	while (index < maxIndex)
	{
	
	/*
	* If we run into a pixel that's above threshold, then call Eat_Spot to
	* eat it.
	*/
		if (*index > thresholdG)
		{
			Eat_Spot (index);
		/*
		* If the resultant spot has a volume greater than that specified,
		* update the spot statistics, call the output routine, and make
		* a new spot to contain the next spot-in-progress.
		*/
			if (theSpotG->volume >= minSpotVol1)
				{
				Update_Spot_Stats (theSpotG);
				theSpotG = New_Spot (theSpotList1,theStackG,spotWave1);
				}
		
		/*
		* If the spot was smaller than the minimum size, we need to make sure
		* all the accumulators and such are zeroed-out.
		*/
			else
				Zero_Spot (theSpotG,theStackG,spotWave1);
		}
		index++;
	}

/*
* After the first round of eating spots, we have to re-read the data because Eat_Spot
* sets every pixel that's above threshold to a value below threshold so that the
* same pixel doesn't get counted more than once.  Every pass of Eat_Spot corrupts
* the data for pixels over the threshold.  The easiest solution for multiple passes
* of Eat_Spot is to simply re-read the data after each one.
*/
	theStackG = ReadDVstack(fp,&head,theTimePoint-1,theStackG);
	if (theStackG == NULL)
	{
		fprintf(stderr,"Could not re-read the DV file.\n");
		exit (-1);
	}



/*
* Allocate memory for the second spot.
* theSpotG will allways point to the spot-in-progress.  Once completed,
* a new spot is allocated, and that new spot is then pointed to by
* theSpotG.  In this way, theSpotG is allways the last spot in the list,
* and it is never a valid spot - it is either blank or in progress.
*
* Since we are allocating the first spot, make sure we set spotList to it.
*/

	theSpotG = New_Spot (NULL,theStackG,spotWave2);
	theSpotList2 = theSpotG;
	theStackG->spotList2 = theSpotList2;
	if (theSpotG == NULL)
	{
		fprintf (stderr,"Could not allocate memory for spot.\n");
		exit (-1);
	}

	thresholdG = (pixel) theThreshold2;

/*
 * Write the column headings to output.
 */
	Output_Spot (theSpotG,theStackG,argc,argv,outArg, HEADING);


/*
* Set index to point to the first pixel in the wave which we will use
* to pick out spots.
*/
	index = theStackG->stack + (theStackG->wave_increment*spotWave2);

/*
* Set a pointer to the end of this wave.
*/
	maxIndex = index + theStackG->wave_increment;

/*
* Run through the pixels in spotWave, making spots.
*/
	while (index < maxIndex)
	{
	
	/*
	* If we run into a pixel that's above threshold, then call Eat_Spot to
	* eat it.
	*/
		if (*index > thresholdG)
		{
			Eat_Spot (index);
		/*
		* If the resultant spot has a volume greater than that specified,
		* update the spot statistics, call the output routine, and make
		* a new spot to contain the next spot-in-progress.
		*/
			if (theSpotG->volume >= minSpotVol2)
				{
				Update_Spot_Stats (theSpotG);
				Output_Spot (theSpotG,theStackG,argc,argv,outArg, VALUES);
				theSpotG = New_Spot (theSpotList2,theStackG,spotWave2);
				}
		
		/*
		* If the spot was smaller than the minimum size, we need to make sure
		* all the accumulators and such are zeroed-out.
		*/
			else
				Zero_Spot (theSpotG,theStackG,spotWave2);
		}
		index++;
	}

/*
* Write out the border pixels into a file.
	if (doBorderG)
		Write_Border_Pixels (theSpotList,theStackG,borderFileName,borderFileType);
*/

/*
* Exit gracefully.
*/	
	return (0);
}
