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
Title:	findSpots
Purpose:  This program reads in a 5D image contained in an OME repository format (a raw pixel dump in XYZWT order),
	then finds all "spots" that are above the specified threshold at the specified wavelegth, and bigger than the specified size.
	The program then reports various statistics that it has collected about these "spots".
Inputs:	 There are four required inputs separated by spaces.
The order of the inputs is not important.
The inputs are Path, Dims, XYZmean, XYZgeoMean, XYZsigma, SpotWave, and Threshold.
Usage:
>findSpots Path=/some/path/to/image.orf Dims=[640,480,30,3,60,2]  <threshold> <min. vol.> <optional arguments> <output options>
<dataset> a path to a file in OME repository format.
<spot wavelegth> is the wavelegth from which to pick out "spots"
	If this parameter is a bare integer (not ending in nm), then that wavelength number will be used from the DV file.
		Wave number are numbered from 0.
<threshold>	 all contiguous pixels that are above threshold will be considered to comprise a
	single spot.
	The threshold can be a bare integer, in which case this will be intepreted as an absolute pixel intensity
	The threshold can be of the form gmean<n>s or mean<n>s, in which case the global threshold will be <n> standard
		deviations above the geometric mean (gmean<n>s) or the regular mean (mean<n>s).
	The threshold can be one of the following words (not case sensitive) to determine an automatic threshold:
		MOMENT - Moment preservation method.
		OTSU - Otsu's discriminant method.
		ME - Maximum entropy method.
		KITTLER - Kittler's method of minimum error.
<min. val.>	 All spots that are smaller in volume than this volume will not be reported.
<optional arguments>
	-box=x0,y0,z0,x1,y1,z1  The specified bounding box will be used instead of the dataset's dimentions
	-time<n1>-<n2> begin and end timepoints.  Default=all. -time4- will do t4 to the end, etc.
Example:
findSpots DVfile 600 300 12
	
Algorithm:	The entire image stack is read into memory at all wavelegths, one timepoint at a time.  The pixels in the
	specified wavelegth are traveresed one by one.	If a pixel's value exceeds threshold then it
	becomes a seed pixel, and is passed to Eat_Spot.  Eat_Spot generates new seed pixels
	which are defined to be neighboring pixels that are above threshold.  The newly generated seed pixels
	are fed back into Eat_Spot, which generates new seed pixels and so on until every pixel in the spot is
	visited at least once.	Since previously visited pixels cannot be seed pixels (they are set to a value
	below threshold once they are visited), and neither can pixels below threshold, eventually Eat_Spot runs
	out of seed pixels, and exits.	In its most elegant implementation, Eat_Spot is a recursive algorithm, but
	that is not precisely how it is implemented here (although an unused example is provided for posterity).
	The depth of recursion can be quite large for 3D data sets, and depending on how the OS and the compiler
	implement recursive calls, can be quite memory inefficient.	 Also, it is difficult to tell in ANSI C if
	you are about to run out of recursive depth (i.e. stack space), so once you do, you get a nasty core dump.
	Presently, Eat_Spot is implemented as a "simulated" recursive algorithm to aleviate these problems.
	Eat_Spot pushes all seed pixels onto a LIFO stack.	Then it pops the pixels off one by one, and
	for each pixel poped, pushes six more adjacent pixels onto the stack.  Pixels are pushed onto the
	stack only if they exceed the threshold value.	This poping/pushing continues until the stack is
	empty. 

Data Structures:  The main data structure is the list of spots.	 In this incarnation, there is a separate list
	for each time-point.  The list at each timepoint is a dynamically allocated bi-directional circularly linked
	list.  These time-point lists are linked together such that each member of a time-point-list points to the
	head of the list for the next timepoint.  How can you have a head in a circularly linked list?	Turns out
	exactly one spot in each list is invalid.  This assures us at least one spot in each list.	The
	invalid spot->next is the head.	 Conversely theHead->previous is the invalid spot.	How do we know a spot is invalid?
	It has a volume of 0.  Unlike the spot list for each timepoint (which is circular) the list of timepoints
	is NULL-terminated and is also one-directional.	 Think of the time-point lists as rings that grow in diameter
	with the addition of spots.  Each member of a time-point's ring (i.e. spot) points to the head of the next
	timepoint's ring, forming a cylinder of sorts.  The whole thing is entirely composed of spot structures.
	Starting with the "first" spot of any time point, if we go down the ->next pointer, we will end up where we
	started immediately after we encounter the invalid spot.  If we travel down the ->nextTimePointList we will go
	through the list of timepoint lists untill we encounter NULL.  These linkages are made as the stack of images gets
	processed.  After all of the spots have been found, we go down (or around, rather) the list of spots for each
	timepoint and find the "nearest neghbor" in the next timepoint.  We link the nearest neighbor through the
	->nextTimePoint pointer.  This way, if we start at a spot in t0 and travel down the ->nextTimePoint linked
	list (NULL terminated, uni-directional), we will visit the "same" spot in consecutive timepoints until we reach
	NULL.
	
	The other somewhat interesting structure is the LIFO stack used in the "simulated" recursive Eat_Spot algorithm.
	We have to allocate the stack dynamically, but we only need to store a single value - the index of the pixel on the
	stack.	So it seems kind of silly to store a pointer to the next index for each index when the pointer is a long
	and the index is a long.  So we allocate the stack in "chunks" of indexes rather than one at a time.  This is
	again a bi-directional circularly linked list of chunks.  Each chunk contians CHUNK_SIZE indexes.  As Eat_Spot pushes
	more indexes on the stack eventually we run out of room in the current chunk.  So we allocate a new chunk.
	SImilarly as we pop values off the stack, we dxeallocate chunks as they are emptied.  Besides the array of indexes, and the
	pointers fore and aft, each chunk stores the last valid index in the index array to help us keep track of how full
	the chunk is.  There is more detailed description of how the stack itself is pushed and poped further down
	in the bowels of the program.
	
	The other structures aren't very interesting or exotic - they are simply the structure of the DV header, and a local
	structure of the DV header that stores additional things for ease of manipulation.	This second local structure deals
	with timepoints by maintaining a link between individual 3D stacks.  This is implemented in a simple unidirectional
	NULL-terminated linked list.  Since the timepoints are processed independantly one at a time, the memory allocated to
	the 3D stack is de-allocated once processing of that 3D stack is done.  The other information is maintained, though.
	Spots keep a pointer to the stack that they came from.  Obviously, it would not be a good idea to reference the actual
	image data once its memory is deallocated.
*/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
#include "iolib/failio.h"
#include "iolib/argarray.h"

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
#define X_PLUS 1
#define X_MINUS 2
#define Y_PLUS 3
#define Y_MINUS 4
#define Z_PLUS 5
#define Z_MINUS 6

#define HEADING 1
#define VALUES 2
#define DATABASE_HEADING 3
#define DATABASE_VALUES 4

#define OUTARGS 5

#define PI 3.14159265358979323846264338327
#define SQUARE_ROOT_OF_2 1.4142135623731

#define BORDER_PIXEL -123
#define SPOT_PIXEL -456


/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################            DEFINITION OF VARIABLE TYPES            ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

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
typedef struct dv_point Point5D;




/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################              DEFINITION OF STRUCTURES              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/


struct dv_point {
	coordinate x;
	coordinate y;
	coordinate z;
	coordinate w;
	coordinate t;
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
	
/*
* These are pre-set to help us navigate through the stack.
* If we add y_increment to a pointer into the stack, then the pointer
* will point to the next pixel down.  Likewise for z_increment and wave_increment
*/
	unsigned long y_increment,z_increment,wave_increment;

	DVstack* next;
};









/*#########################*/
/*#	  IndexStackStruct	  #*/
/*#########################*/
/*
* This structure contains the LIFO stack used by Eat_Spot.	The stack is dynamically allocated
* in CHUNK_SIZE increments (chunks).  I set CHUNK_SIZE such that one of these structures occupies 32k.
* The dynamic stack is implemented as a circular double-linked list of chunks.	The first element of
* the list is pointed to by theStack.  The last element of the stack is pointed to by
* theStack->prevChunk.	The last element of this structure (theStack->last) contains the last
* valid index in a given stack chunk.  The last index in the stack is thus always
* theStack->prevChunk->index[theStack->prevChunk->last].  If there is more than one chunk
* in the stack, then ->last is set to CHUNK_SIZE for all chunks in the stack other than
* theStack->prevChunk (which is allways the last chunk in the stack).  The chunks are allocated
* as needed in Push_Stack, and deallocated as needed in Pop_Stack.
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
	char flag;
	CoordList next;
};




/*#########################*/
/*#      SpotStruct       #*/
/*#########################*/
/*
 * This is the structure that is used to store information about each
 * spot.  The list of spots is a circular double-linked list.  New spots are added
 * before the head of the list.
 */
struct spotStructure {
	long ID;
	int nwaves;
	int itsWave;  /* this is the wave index for the wavelegth that this
						is a spot from */
	DVstack *itsStack;
/*
* This is an index to the timepoint this spot came from.  It is in the same format as would be passed to
* ReadDVstack.	The first timepoint is 0.
*/
	short itsTimePoint;	 

/*
* When looking for spots, these bounds are used to set the spot limits.	 They
* may be different from the bounds of the image stack.
*/
	short clip_Xmin,clip_Ymin,clip_Zmin;
	short clip_Xmax,clip_Ymax,clip_Zmax;

/*
* The minimum and maximum coordinates form a "minimal box" around the spot.
* Since the box's sides lie along the X,Y,Z axes, it is not necessarily the
* smallest box - it is simply the range of the spot's X,Y,Z coordinates.
*/
	short min_x,min_y,min_z;
	short max_x,max_y,max_z;

/*
* The mean coordinates give the center of volume for the spot.
*/
	float mean_x,mean_y,mean_z;

/*
* These can be thought of as horizontal, vertical and Z-axis "dispersions" for the spot.
*/
	float sigma_x,sigma_y,sigma_z;


/* number of pixels that make up the spot */
	unsigned long volume;

/* The maximum size of the stack generated to find the spot. */
	unsigned long max_stack;

/* The spot has a different centroid at each wavelegth */
	float centroid_x[MAXWAVES];
	float centroid_y[MAXWAVES];
	float centroid_z[MAXWAVES];

/*
* This is a pointer to the closest spot in the next timepoint.
* We have no way of knowing if this spot moved there or if its another
* spot that becomes the nearest neighbor.  Ideally its the same spot and this
* pointer points to its next position.
*/
	SpotStruct *nextTimePoint;

/*
* These are the vectors to the "same" spot in the next timepoint.  They are
* expressed in pixel coordinates.
*/
	float vecX,vecY,vecZ;

/*
* This is the integral - sum of intensisties of the pixels that make up the spot.
* There is a value for each wavelegth.	Same for the rest of the intensity stats.
*/
	float sum_i[MAXWAVES];
	float sum_i2[MAXWAVES];
	float min_i[MAXWAVES];
	float max_i[MAXWAVES];
	float mean_i[MAXWAVES];
	float geomean_i[MAXWAVES];
	float sigma_i[MAXWAVES];

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
* These values are used internally in the spot-finding algorithm to keep
* track of where we are.  They have no meaning outside of the algorithm.
*/
	short cur_x,cur_y,cur_z;

/*
* this is a linked list of border pixels around the spot.
*/
	CoordList borderPixels;
	unsigned long borderCount;
	double perimiter;
	double formFactor;
	double surfaceArea;
	short seedX;
	short seedY;
	short seedZ;

/*
* This is a circular double-linked list for ease of maneuverability (and obfuscation).
* New members are added to the head->previous. New memeber->next then
* points to the head, and new member->previous points to the old head->previous.
*/

	SpotStruct *next;
	SpotStruct *previous;

/*
* This pointer points to a list of spots in the next timepoint.
* This pointer is only valid at the head of a list of spots for a given timepoint. Otherwise
* its NULL.  Sure its not the best data structure organization.  So sue me.
*/
	SpotStruct *nextTimePointList;
};










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################               DEFINITION OF FUNCTIONS              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

void InitializeDVstack (DVstack* inStack, Point5D dims);
void ReadDVstack (DVstack* inStack, FILE *fp, Point5D dims, long time);
void ReadWaveStats (DVstack* inStack, argiterator_t* iter, size_t nWaves);
void Calculate_Stack_Stats (DVstack *theStackG,int theWave);
void Push_Stack (PixPtr index, IndexStack theStack);
PixPtr Pop_Stack (IndexStack theStack);
void Eat_Spot_Rec (PixPtr index);
void Eat_Spot(PixPtr index);
void Index_To_Coords (DVstack* inStack, PixPtr index,short *X,short *Y,short *Z);
void Update_Spot (DVstack* inStack, PixPtr index);
PixPtr Get_Index_From_Coords (SpotPtr theSpot, short X,short Y,short Z);
void Get_Perimiter (SpotPtr theSpot);
void SwapListElements (CoordList previousElement1, CoordList previousElement2);
void Get_Surface_Area (SpotPtr theSpot);
double Get_Surface_Area_CC (char *c, int n);
PixPtr Update_Index (PixPtr index, char direction);
void Set_Border_Pixel (short X, short Y, short Z);
SpotPtr New_Spot (SpotPtr spotList,DVstack *theStackG, int itsWave, short itsTime);
void Zero_Spot (SpotPtr theSpotG,DVstack *theStackG, int itsWave, short itsTime);
void Update_Spot_Stats (SpotPtr theSpotG);
void Output_Spot (SpotPtr theSpotG, int argc, char**argv,int outArgs, char saywhat);
void Write_Output (SpotPtr theSpotListHead,int argc, char**argv,int outArgs);
void Compose_inArgs (char *inArgs, int argc, char**argv);

pixel Set_Threshold (const char *arg, DVstack *theStack);
double *Get_Prob_Hist (DVstack *theStack, unsigned short *histSizePtr);
pixel Get_Thresh_Moment (DVstack *theStack);
pixel Get_Thresh_Otsu (DVstack *theStack);
pixel Get_Thresh_ME (DVstack *theStack);
pixel Get_Thresh_Kittler (DVstack *theStack);

void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);








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
SpotPtr theSpotG;
pixel thresholdG;
long stack_size = 0;
unsigned long max_stack_size = 0;
char doBorderG=1;
short DV_REV_ENDIAN_MAGIC;










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                       FUNCTIONS                    ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/


/*#########################*/
/*#                       #*/
/*#     ReadDVstack       #*/
/*#                       #*/
/*#########################*/
/*
 * The following routines read one timepoint into the provided DVstack.
*/

void ReadDVstack (DVstack* inStack, FILE* fp, Point5D dims, long time)
{
	size_t timepointSize = inStack->wave_increment * dims.w * sizeof(pixel);
	Seek (fp, time * timepointSize);
	Read (fp, inStack->stack, timepointSize);
}

void InitializeDVstack (DVstack* inStack, Point5D dims)
{
	memset (inStack, 0, sizeof(DVstack));
	inStack->nwaves = dims.w;
	inStack->max_x = dims.x - 1;
	inStack->max_y = dims.y - 1;
	inStack->max_z = dims.z - 1;
	inStack->y_increment = dims.x;
	inStack->z_increment = dims.x * dims.y;
	inStack->wave_increment = dims.x * dims.y * dims.z;
	if (!inStack->stack)
		inStack->stack = (PixPtr) Allocate (inStack->wave_increment * dims.w * sizeof(pixel), "for image data");
}

void ReadWaveStats (DVstack* inStack, argiterator_t* iter, size_t timepoint)
{
	size_t i;
	size_t readTimepoint = 0;
	size_t readWave = 0;
	for (i = 0; i < inStack->nwaves; ++ i) {
		const char* argPtr = Argiter_NextString (iter);
		if (!argPtr) {
			fprintf (stderr, "Error: missing statistics for wave %d\n", i);
			exit(-1);
		}
		sscanf (argPtr, "%d,%hd,%d,%hd,%hd,%f,%f,%f", &readWave, &inStack->wave[i], &readTimepoint,
				&inStack->min_i[i], &inStack->max_i[i], &inStack->mean_i[i],
				&inStack->geomean_i[i], &inStack->sigma_i[i]);
		if (readTimepoint != timepoint || readWave != i) {
			fprintf (stderr, "Error: wave %d stats are missing in list for timepoint %d\n", i, timepoint);
			exit(-1);
		}
	}
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
double sum_i=0,sum_i2=0,sum_log_i=0,numWavePix,theVal, sd, offset=100.0,min,max;

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
/*#      Push_Stack       #*/
/*#                       #*/
/*#########################*/
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
		return;
	if (*index < 0)
		return;
	if (*index <= thresholdG)
		return;
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
	* The new chunk comes in as the chunk right before theStack.
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










/*#########################*/
/*#                       #*/
/*#         Pop_Stack     #*/
/*#                       #*/
/*#########################*/
/*
* This function returns the last index in the LIFO stack.  It deallocates memmory if
* returning the last index in a chunk.	It won't free the very last chunk in the stack - the
* one pointed to by theStack.
*/
PixPtr Pop_Stack (IndexStack theStack)
{
PixPtr theIndex;
IndexStack lastChunk;


/* the last chunk of the stack is allways theStack->lastChunk */
	lastChunk = theStack->prevChunk;
	
/* If lastChunk->last is less than 0, the stack is empty, so return NULL. */
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










/*#########################*/
/*#                       #*/
/*#         Eat_Spot      #*/
/*#                       #*/
/*#########################*/
void Eat_Spot (PixPtr index)
{
static IndexStack theStack;

/*
* If there is no stack, then make one.
*/
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


	
	Index_To_Coords (theStackG, index,&(theSpotG->seedX),&(theSpotG->seedY),&(theSpotG->seedZ) );
/*
* We update the spot's statistics based on the properties of this pixel (position, intensity, etc).
* This is the seed pixel.
*/
	Update_Spot (theStackG, index);

/*
* We set this pixel to SPOT_PIXEL so that we don't count it again.
*/
	*index = SPOT_PIXEL;
	
/*
* We push the indexes of the pixels in all six directions onto the stack.  Update_Index returns a new index
* based on the specified direction.  It will return NULL if the specified directions causes an index that's
* out of bounds.  The index gets passed to Push_Stack, which checks if the pixel pointed to by index is above
* threshold.  If so, it gets pushed on the stack.  At most, we would have pushed the six pixels that surround
* the seed pixel.
*/
	Push_Stack (Update_Index(index,X_PLUS),theStack);
	Push_Stack (Update_Index(index,X_MINUS),theStack);
	Push_Stack (Update_Index(index,Y_PLUS),theStack);
	Push_Stack (Update_Index(index,Y_MINUS),theStack);
	if (theSpotG->clip_Zmax-theSpotG->clip_Zmin)
	{
		Push_Stack (Update_Index(index,Z_PLUS),theStack);
		Push_Stack (Update_Index(index,Z_MINUS),theStack);
	}
/*
* We've processed the seed pixel, so now its time to pop the first pixel from the stack.
*/
	index = Pop_Stack (theStack);
	
/*
* This is where the action is.  The index supplied by Pop_Stack will be NULL when the stack is empty.
*/
	while (index != NULL)
		{
		
		/*
		* If the index popped is greater than threshold then we update the spot with the pixel
		* and push its neighbors.  I thought only pixels above threshold were pushed on the stack
		* so why are we checking pixels popped off?  Because the pixel is set to threshold only once
		* the spot is updated with it, and a given pixel may have been pushed on to the stack through
		* any of its neighbors, in effect having multiple copies of the same pixel on the stack.  We
		* must only visit it once, and once we do its set to threshold, but since the other copies are
		* still on the stack, we have to check each time.  We check before pushing them mainly to keep
		* stack size reasonable, not to make sure that we visit each one only once.
		*/
		if (*index > thresholdG)
		{
			
		/*
		* If we found a valid pixel, then basically do the same thing we did before.
		*/
			Update_Spot (theStackG, index);
			*index = SPOT_PIXEL;
			Push_Stack (Update_Index(index,X_PLUS),theStack);
			Push_Stack (Update_Index(index,X_MINUS),theStack);
			Push_Stack (Update_Index(index,Y_PLUS),theStack);
			Push_Stack (Update_Index(index,Y_MINUS),theStack);
			if (theSpotG->clip_Zmax-theSpotG->clip_Zmin)
			{
				Push_Stack (Update_Index(index,Z_PLUS),theStack);
				Push_Stack (Update_Index(index,Z_MINUS),theStack);
			}
		}

		/*
		* pop another pixel off the stack and begin again.
		*/
		index = Pop_Stack (theStack);
		}
}










/*#########################*/
/*#                       #*/
/*#         Eat_Spot      #*/
/*#       - emeritus -    #*/
/*#########################*/
/*
* This is the core of the recursive algorithm.	It calls two accessory functions
* to do some calculations.	These should not add to the stack load (recursion depth).
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
	Update_Spot (theStackG, index);

/*
* To prevent re-considering this pixel, we set it to threshold.
*/
	*index = thresholdG;

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





void Index_To_Coords (DVstack* inStack, PixPtr index,short *Xp,short *Yp,short *Zp)
{
unsigned long index2;
short X,Y,Z;

/*
* First,  subtract the stack pointer from index,  thus getting
* a "true" index.
*/
	index2 = index - inStack->stack;

/*
* Second,	subtract the wave increment to get an index into the stack.
*/
	index2 -= (theSpotG->itsWave * inStack->wave_increment);

/*
* The z coordinate is the wave index divided by the size of a z-section.
* The integer division is a truncation.
*/
	Z = index2 / (inStack->z_increment);

/*
* Then we subtract the z coordinate * section size to get an index into the section.
*/
	index2 -= (Z * (inStack->z_increment));

/*
* The y coordinate is the index divided by the width.
*/
	Y = index2 / (inStack->y_increment);

/*
* Lastly,	if we subtract the y coordinate * width from the index,	 we will be left
* with the x coordinate.
*/
	index2 -= (Y * (inStack->y_increment));
	X = index2;

	*Xp = X;
	*Yp = Y;
	*Zp = Z;
/*
* It is important to note that these coordinates are based on the origin being (0,0,0) not
* as DV defines it at (1,1,1).  For now, we will leave the internal coordinate base at (0,0,0),
* and add the vector (1,1,1) to the displayed coordinates.  This is an interim solution
* pending something more elegant and consistent.  Ideally, this would be to have DV move
* its coordinate base to (0,0,0) as is done in the rest of the known universe.  Having
* written something in FORTRAN with arrays based on index 1 is no excuse not to follow convention.
*/

}





/*#########################*/
/*#                       #*/
/*#       Update_Spot     #*/
/*#                       #*/
/*#########################*/
/*
* This functions assumes index points to a valid spot pixel, and updates the 
* spot accumulators in the global spot structure.
*/
void Update_Spot (DVstack* inStack, PixPtr index)
{
int i;
float floatIndex;


/*
* We need to back-calculate the coordinates from the index.
*/
	Index_To_Coords (theStackG,index,&(theSpotG->cur_x),&(theSpotG->cur_y),&(theSpotG->cur_z));
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
		floatIndex = (float)*index;
	/*
	* Update the wave-specific accumulators, minima, maxima, etc.
	*/
		if (*index < theSpotG->min_i[i])
			theSpotG->min_i[i] = *index;
		if (*index > theSpotG->max_i[i])
			theSpotG->max_i[i] = *index;
		theSpotG->sum_i[i] += *index;
		theSpotG->sum_i2[i] += (floatIndex * floatIndex);
		theSpotG->sum_xi[i] += floatIndex * theSpotG->cur_x;
		theSpotG->sum_yi[i] += floatIndex * theSpotG->cur_y;
		theSpotG->sum_zi[i] += floatIndex * theSpotG->cur_z;
		theSpotG->geomean_i[i] += (float) log ( (double)*index );
	
	/*
	* To get to the same pixel in the next wave, all we need to do is add
	* the size of a wave to the index.
	*/
		index += theStackG->wave_increment;
	}

	
	return;
}










/*#########################*/
/*#                       #*/
/*#      Update_Index     #*/
/*#                       #*/
/*#########################*/
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
* Initially, we set a pointer to NULL.	If we are in bounds, then it will
* be set to a valid pointer.  Otherwise, we'll return with NULL.
*/
PixPtr theIndex = NULL;
char doBorder=0;
short X,Y,Z;

	X = theSpotG->cur_x;
	Y = theSpotG->cur_y;
	Z = theSpotG->cur_z;
/*
* Return NULL if we are on the border.
*/
	switch (direction)
	{
	case X_PLUS:
		if (X < theSpotG->clip_Xmax)
			theIndex = index + 1;
		else if (X == theSpotG->clip_Xmax)
			doBorder = 1;
	break;
	case X_MINUS:
		if (X > theSpotG->clip_Xmin)
			theIndex = index - 1;
		else if (X == theSpotG->clip_Xmin)
			doBorder = 1;
	break;

	case Y_PLUS:
		if (Y < theSpotG->clip_Ymax)
			theIndex = index + theStackG->y_increment;
		else if (Y == theSpotG->clip_Ymax)
			doBorder = 1;
	break;
	case Y_MINUS:
		if (Y > theSpotG->clip_Ymin)
			theIndex = index - theStackG->y_increment;
		else if (Y == theSpotG->clip_Ymin)
			doBorder = 1;
	break;

	case Z_PLUS:
		if (Z < theSpotG->clip_Zmax)
			theIndex = index + theStackG->z_increment;
		else if (Z == theSpotG->clip_Zmax)
			doBorder = 1;
	break;
	case Z_MINUS:
		if (Z > theSpotG->clip_Zmin)
			theIndex = index - theStackG->z_increment;
		else if (Z == theSpotG->clip_Zmin)
			doBorder = 1;
	break;
	}  /* switch (direction */

	if (theIndex && *theIndex < 0)
		return (NULL);

	if (theIndex && *theIndex <= thresholdG)
		doBorder = 1;

	if (doBorder)
		Set_Border_Pixel (X,Y,Z);

	return (theIndex);
}


PixPtr Get_Index_From_Coords (SpotPtr theSpot, short X,short Y,short Z)
{
PixPtr index;
DVstack *itsStack;

	itsStack = theSpot->itsStack;
	index = itsStack->stack;
	index += (theSpot->itsWave * itsStack->wave_increment);
	index += (Z * (itsStack->z_increment));
	index += (Y * (itsStack->y_increment));
	index += X;
	return (index);

}





void Set_Border_Pixel (short X, short Y, short Z)
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
* but I was too lazy to do that.
*/

/*
	if ( (theSpotG->borderPixels != NULL) &&
	    (X == theSpotG->borderPixels->X) &&
	    (Y == theSpotG->borderPixels->Y) &&
	    (Z == theSpotG->borderPixels->Z) )
		return;
*/
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
	
	newPixel->X = X;
	newPixel->Y = Y;
	newPixel->Z = Z;
	newPixel->flag = 0;
	newPixel->next = theSpotG->borderPixels;
	theSpotG->borderPixels = newPixel;
	theSpotG->borderCount++;


	return;
}








/*#########################*/
/*#                       #*/
/*#        New_Spot       #*/
/*#                       #*/
/*#########################*/
/*
* This routine allocates memory for a new spot, links it to the spot list,
* and calls Zero_Spot to 
* initialize all the variables of the spot structure and make it ready to use.
*/
SpotPtr New_Spot (SpotPtr spotList,DVstack *inStack, int itsWave, short itsTime)
{
SpotPtr newSpot=NULL;
static unsigned long ID=0;

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
* The spot list grows as an expanding circle, which can be traveled in either direction.
* Kind of exotic, no?
*/
	if (spotList != NULL)
		{
	/*
	* newSpot's previous points to what the spotList's previous used to point to.
	* newSpot's next points to the spotList.
	* the spotList's previous points to the newSpot,
	* The spot that used to be before spotList now has its next pointing to newSpot.
	* Got that?
	*/
		newSpot->ID = ID++;
		newSpot->previous = spotList->previous;
		newSpot->next = spotList;
		spotList->previous->next = newSpot;
		spotList->previous = newSpot;
		newSpot->nextTimePointList = spotList->nextTimePointList;
		}
	/* brand new spot list */
	else
		{
		newSpot->ID = ID++;
		newSpot->previous = newSpot;
		newSpot->next = newSpot;
		newSpot->nextTimePointList = NULL;
		}
	newSpot->nextTimePoint = NULL;
	newSpot->itsStack = inStack;
/*	
* Zero-out the accumulators, etc.
*/
	newSpot->borderPixels = NULL;
	Zero_Spot (newSpot, inStack, itsWave, itsTime);
	
	return (newSpot);
}










/*#########################*/
/*#                       #*/
/*#       Zero_Spot       #*/
/*#                       #*/
/*#########################*/
void Zero_Spot (SpotPtr zeroSpot,DVstack *itsStack, int itsWave, short itsTime)

{
int i;
CoordList borderPixel;


	zeroSpot->itsStack = itsStack;
	zeroSpot->nwaves = itsStack->nwaves;
	zeroSpot->itsWave = itsWave;
	zeroSpot->itsTimePoint = itsTime;
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

/*
* A spot cannot have a volume of zero if its valid, so this is a convenient variable to check
* that we have a valid spot (not a place-holder).
*/
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
	zeroSpot->borderCount = 0;
	zeroSpot->seedX=0;
	zeroSpot->seedY=0;
	zeroSpot->seedZ=0;
	
	
}










/*#########################*/
/*#                       #*/
/*#   Update_Spot_Stats   #*/
/*#                       #*/
/*#########################*/
/*
* This routine gets called after the accumulators are filled - i.e. after the whole
* spot has been "eaten" in order to calculate some final statistics.
*/
void Update_Spot_Stats (SpotPtr updateSpot)
{
int i;
float spotVol;
CoordList borderPixel,previousPixel;
PixPtr pixPtr;

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
	
/*
* Set border pixels to the border pixel value
*/
	pixPtr = updateSpot->itsStack->stack;
	pixPtr += (updateSpot->itsWave * updateSpot->itsStack->wave_increment);
	borderPixel = updateSpot->borderPixels;
	previousPixel = borderPixel;
	while (borderPixel)
	{
		pixPtr = Get_Index_From_Coords (updateSpot,borderPixel->X,borderPixel->Y,borderPixel->Z);
		if (*pixPtr == SPOT_PIXEL)
			*pixPtr = BORDER_PIXEL;
		else
			{
/*
#ifdef DEBUG
fprintf (stderr,"Deleting Spot #%ld (%d,%d,%d) = %d\n",updateSpot->ID,borderPixel->X,borderPixel->Y,borderPixel->Z,*pixPtr);
fflush (stderr);
#endif
*/
			previousPixel->next = borderPixel->next;
			free (borderPixel);
			borderPixel = previousPixel;
			updateSpot->borderCount--;
			}
		previousPixel = borderPixel;
		if (borderPixel)
			borderPixel = borderPixel->next;
	}
/*
* calculate stuff from the border pixels.
*/
	if (updateSpot->itsStack->max_z)
		Get_Surface_Area (updateSpot);
	else
		Get_Perimiter (updateSpot);
}



/*	Compute the chain code of the object beginning at pixel (i,j).
	Return the code as NN integers in the array C.			*/
void chain8 (SpotPtr theSpot, char *c, short i, short j, int *nn)
{
	int val,n,m,q,r, di[9],dj[9],ii, d, dii;
	int lastdir, jj;
	int xMin,xMax,yMin,yMax,nMax;
	int x,y;
	PixPtr data;

	xMin = theSpot->itsStack->min_x;
	xMax = theSpot->itsStack->max_x;
	yMin = theSpot->itsStack->min_y;
	yMax = theSpot->itsStack->max_y;
	data = theSpot->itsStack->stack;

/*	Table given index offset for each of the 8 directions.		*/
	di[0] = 0;	di[1] = -1;	di[2] = -1;	di[3] = -1;
	dj[0] = 1;	dj[1] = 1;	dj[2] = 0;	dj[3] = -1;
	di[4] = 0;	di[5] = 1;	di[6] = 1;	di[7] = 1;
	dj[4] = -1;	dj[5] = -1;	dj[6] = 0;	dj[7] = 1;

	nMax = *nn;
	for (ii=0; ii<nMax; ii++) c[ii] = -1;	/* Clear the code table */
	data = Get_Index_From_Coords (theSpot,i,j,0);
	val = *data;	n = 0;	/* Initialize for starting pixel */
	q = i;	r = j;  lastdir = 4;

	do {
		m = 0;
		dii = -1;	d = 100;
		for (ii=lastdir+1; ii<lastdir+8; ii++) {	/* Look for next */
			jj = ii%8;
			x = di[jj]+q;
			y = dj[jj]+r;
			data = Get_Index_From_Coords (theSpot,x,y,0);
			if ( (x <= xMax) && (x >= xMin) && (y <= yMax) && (y >= yMin) )
				if ( *data == val) {
				   dii = jj;	m = 1;
				   break;
			} 
	   }

	   if (m) {	/* Found a next pixel ... */
	   	if (n<nMax) c[n++] = dii;	/* Save direction as code */
	   	q += di[dii];	r += dj[dii];
	   	lastdir = (dii+5)%8;
	   } else break;	/* NO next pixel */
	   if (n>nMax) break;
	} while ( (q!=i) || (r!=j) );	/* Stop when next to start pixel */

	if ( (q!=i) || (r!=j) )
	{
		fprintf (stderr,"WARNING: Failed to achieve closure in Spot %ld!\n",theSpot->ID);
		fflush (stderr);
	}
	*nn = n;
}



double Get_Surface_Area_CC (char *c, int n)
{
	int i,x,y;
	double a;

	a = 0.0;	x = n;	y = n;
	for (i=0; i<n; i++) {
	  switch (c[i]) {
case 0:		a -= y;	x++;
		break;

case 1:		a -= (y + 0.5);	y++; x++;
		break;

case 2:		y++;
		break;

case 3:		a += (y + 0.5);	y++;	x--;
		break;

case 4:		a += y;	x--;
		break;

case 5:		a += (y-0.5);	y--;	x--;
		break;

case 6:		y--;
		break;

case 7:		a -= (y-0.5);	y--; x++;
		break;
	  }
	}
/*
#ifdef DEBUG
	fprintf (stderr,"Chain code area is %10.4f (%d,%d)\n", a, x, y);
#endif
*/
	return (fabs(a));
}



void Get_Perimiter (SpotPtr theSpot)
{
int nCodes,i;
double perimiter=0.0;
char *chainCode;

	nCodes = theSpot->borderCount;
	chainCode = (char *) malloc (sizeof (char) * nCodes);
	if (!chainCode)
	{
	fprintf (stderr,"Could not allocate memory for chain code\n");
	exit (-1);
	}
	
	chain8 (theSpot, chainCode, theSpot->seedX, theSpot->seedY, &nCodes);

	perimiter = 0.0;
	for (i=0; i<nCodes; i++)
	   if (chainCode[i]%2) perimiter += SQUARE_ROOT_OF_2;
	   else perimiter += 1.0;


	theSpot->surfaceArea = Get_Surface_Area_CC (chainCode,nCodes);

	free (chainCode);

	theSpot->perimiter = perimiter;
	theSpot->formFactor = (4.0*PI*theSpot->surfaceArea) / (perimiter*perimiter);
}



void SwapListElements (CoordList pixel1, CoordList pixel2)
{
int swap;

	swap = pixel2->X;
	pixel2->X = pixel1->X;
	pixel1->X = swap;

	swap = pixel2->Y;
	pixel2->Y = pixel1->Y;
	pixel1->Y = swap;

	swap = pixel2->Z;
	pixel2->Z = pixel1->Z;
	pixel1->Z = swap;

	swap = pixel2->flag;
	pixel2->flag = pixel1->flag;
	pixel1->flag = swap;
	
}



void Get_Surface_Area (SpotPtr theSpot)
{
double surfaceArea = 0;
/*
* FIXME:  Total hack of computing surface area by using the number of perimiter pixels.  Makes
* no account of anisotropic space.  The formula is correct, though. Hmm, I wonder since the volume is in the
* same anisotropic space wether things will conveniently take care of themselves....probably not.  Even if
* it does, it will work for the form factor, but not for the actual surface area.
*/
	theSpot->surfaceArea = (double) theSpot->borderCount;
	theSpot->formFactor = ( 36.0*PI*pow ((double)theSpot->volume,2) ) / pow (surfaceArea,3);
}



/*#########################*/
/*#                       #*/
/*#    Compose_inArgs     #*/
/*#                       #*/
/*#########################*/
/*
* This little functions composes the string that will be sent to output when the -aID option
* is used.  This string contains all the input arguments that affect this run.  The string pointer
* passed in must point to some allocated memory.  This function does not allocate memory.
*/
void Compose_inArgs (char *inArgs, int argc, char**argv)
{
int i;


	sprintf (inArgs,"%s %s %s",argv[2],argv[3],argv[4]);
	for (i=0;i<argc;i++)
	    {
	    if (!strcmp (argv[i],"-iwght"))
	        {
	        strcat (inArgs," ");
	        strcat (inArgs,argv[i]);
	        strcat (inArgs," ");
	        strcat (inArgs,argv[i+1]);
	        }
		else if (!strncmp (argv[i],"-time",5))
			{
			strcat (inArgs," ");
			strcat (inArgs,argv[i]);
			}
		}
}









/*#########################*/
/*#                       #*/
/*#      Output_Spot      #*/
/*#                       #*/
/*#########################*/
/*
* This is the output routine.  It should be fairly straight-forward to add
* other options here if the examples are followed.
*/
void Output_Spot (SpotPtr outSpot, int argc, char**argv,int outArgs, char saywhat)
{
int theArg,i,theWave;
DVstack *itsStack;
char doDB = 0;
static char inArgs[255]="-",aIDcontrolString[32]="-",dIDcontrolString[32]="-";


	if (outSpot == NULL)
		return;
	

	if (saywhat == DATABASE_HEADING)
		{
		doDB = 1;
		saywhat = HEADING;
		}
	else if (saywhat == DATABASE_VALUES)
		{
		doDB = 1;
		saywhat = VALUES;
		}
	else
		doDB = 0;
  

	itsStack = outSpot->itsStack;
/*
* We are going to loop through the arguments. and as we encounter a valid output argument,
* write stuff to stdout.
*/
	theArg = outArgs;
	while (theArg < argc)
	{
/* -ID :	 Ouput spot ID */
		if (!strcmp ( argv[theArg],"-ID"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"  ID   ");
			else
				fprintf (stdout,"%7ld",outSpot->ID);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -ID */
	

/* -dID :	 dataset ID  - filename*/
		if (!strcmp ( argv[theArg],"-tID"))
		{
			if (strlen (dIDcontrolString) < 2)
				sprintf (dIDcontrolString,"%%%ds",strlen(argv[1]));
			if (saywhat == HEADING)
				fprintf (stdout,dIDcontrolString,"filename");
			else
				fprintf (stdout,dIDcontrolString,argv[1]);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -tID */
	

/* -aID :	 Output the arguments for this run (argument identifier) */
		if (!strcmp ( argv[theArg],"-tID"))
		{

			if (strlen (inArgs) < 2 )
				{
				Compose_inArgs (inArgs,argc,argv);
				sprintf (aIDcontrolString,"%%%ds",strlen(inArgs));
				}
			if (saywhat == HEADING)
				fprintf (stdout,aIDcontrolString,"args.");
			else
			    fprintf (stdout,aIDcontrolString,inArgs);
		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -tID */
	

/* -v :	 Ouput volume */
		if (!strcmp ( argv[theArg],"-v"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"volume ");
			else
				fprintf (stdout,"%7ld",outSpot->volume);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -ff :  Display the spot's form-factor (1 for sphere or circle in 2D, <1 if deviates) */
		if (!strcmp ( argv[theArg],"-ff"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"Form Factor");
			else
				fprintf (stdout,"%11.9f",outSpot->formFactor);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -sa :  Display the spot's surface area */
		if (!strcmp ( argv[theArg],"-sa"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"Surf. Area");
			else
				fprintf (stdout,"%10.2f",outSpot->surfaceArea);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -per :  Display the spot's perimiter */
		if (!strcmp ( argv[theArg],"-per"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"perimiter");
			else
				fprintf (stdout,"%9.2f",outSpot->perimiter);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -stack :	 Ouput maximum stack size */
		if (!strcmp ( argv[theArg],"-stack"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"stack	");
			else
				fprintf (stdout,"%7ld",outSpot->max_stack);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -stack */
	

/* -mc :  Ouput mean coordinates (center of volume)	 */
		else if (!strcmp ( argv[theArg],"-mc"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"mean X\tmean Y\tmean Z");
			else
				fprintf (stdout,"%6.1f\t%6.1f\t%6.1f",
				outSpot->mean_x,outSpot->mean_y,outSpot->mean_z);
			fprintf (stdout,"\t");
		} /* -mc */
	
	
/* -c <n> :	 Ouput centroids (center of mass - different at each wavelegth) */
		else if (!strcmp ( argv[theArg],"-c"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
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
			}
			else for (i=0;i<outSpot->nwaves;i++)
			{
				if (saywhat == HEADING)
					fprintf (stdout,"c[%3d]X\tc[%3d]Y\tc[%3d]Z",
						itsStack->wave[i], 
						itsStack->wave[i], 
						itsStack->wave[i]);
				else
					fprintf (stdout,"%7.1f\t%7.1f\t%7.1f",
						outSpot->centroid_x[i],
						outSpot->centroid_y[i],
						outSpot->centroid_z[i]);
				if (i < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
			theArg++;
		} /* -c */
	
	
/* -i <n> :	 Ouput Integrals */
		else if (!strcmp (argv[theArg],"-i"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout, " i[%3d]  ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%9.1f",outSpot->sum_i[theWave]);
				}
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
			fprintf (stdout,"\t");
			theArg++;
		} /* -i */



/* -m <n> :	 Ouput means */
		else if (!strcmp (argv[theArg],"-m"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout, "m[%3d] ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.1f",outSpot->mean_i[theWave]);
				}
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
			fprintf (stdout,"\t");
			theArg++;
		} /* -m */



/* -ms <n> :  Ouput means - number of standard deviations above the wavelegth's mean */
		else if (!strcmp (argv[theArg],"-ms"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout, "ms[%3d]",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.3f",
							(outSpot->mean_i[theWave]-itsStack->mean_i[theWave])/itsStack->sigma_i[theWave]);
				}
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
			fprintf (stdout,"\t");
			theArg++;
		} /* -ms */



/* -g <n> :	 Ouput geometric means */
		else if (!strcmp (argv[theArg],"-g"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout, "g[%3d] ",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.1f",outSpot->geomean_i[theWave]);
				}
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
			fprintf (stdout,"\t");
			theArg++;
		} /* -g */



/* -gs <n> :  Ouput geometric means - number of standard deviations above the wavelegth's geometric mean */
		else if (!strcmp (argv[theArg],"-gs"))
		{
			theWave = atoi(argv[theArg+1]);
			if (theWave != 0)
			{
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout, "gs[%3d]",itsStack->wave[theWave]);
					else
						fprintf (stdout,"%7.3f",
							(outSpot->geomean_i[theWave]-itsStack->geomean_i[theWave])/itsStack->sigma_i[theWave]);
				}
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
			fprintf (stdout,"\t");
			theArg++;
		} /* -gs */
    	else if (!strcmp ( argv[theArg],"-tm") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout," Mean  \t");
			else
				fprintf (stdout,"%7.1f\t",outSpot->itsStack->mean_i[outSpot->itsWave]);
    		}
    	else if (!strcmp ( argv[theArg],"-tSD") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout,"  SD   \t");
			else
				fprintf (stdout,"%7.2f\t",outSpot->itsStack->sigma_i[outSpot->itsWave]);
    		}
    	else if (!strcmp ( argv[theArg],"-tt") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout," t  \t");
			else
				fprintf (stdout,"%4d\t",outSpot->itsTimePoint);
    		}
    	else if (!strcmp ( argv[theArg],"-th") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout,"Thresh.\t");
			else
				fprintf (stdout,"%7d\t",outSpot->itsStack->threshold);
    		}


	theArg++;
	} /* while theArg < argc */

}





void Write_Output (SpotPtr theSpotListHead,int argc, char**argv,int outArgs)
{
SpotPtr theSpot,theTimepointListHead;
char done=0,doDB=0,doLabels=1;
int thisTime,i;


	for (i=0;i<argc;i++)
		{
		if (!strcmp ( argv[i],"-db"))
			doDB=1;
		if (!strcmp ( argv[i],"-nl"))
			doLabels=0;
		}
/*
* Write column headings if we're supposed to.  If we've suppressed column headings or we're writing a dabase, don't
* print these out.  If we're doing database style, then we'll print them in output spot wherever the user wants them.
*/
	if (doLabels && !doDB)
		for (i=0;i<argc;i++)
			{
			if (!strcmp ( argv[i],"-tm"))
				fprintf (stdout," Mean  \t");
			if (!strcmp ( argv[i],"-tSD"))
				fprintf (stdout,"  SD   \t");
			if (!strcmp ( argv[i],"-tt"))
				fprintf (stdout," t  \t");
			if (!strcmp ( argv[i],"-th"))
				fprintf (stdout,"Thresh.\t");
			}
/*
*Call Output_Spot once for each spot in the first timepoint, telling it to output the
* column headings.
*/
	if (doLabels && ! doDB)
		{
		theSpot = theSpotListHead;
		while (theSpot->next != theSpotListHead)
			{
			Output_Spot (theSpot,argc,argv,outArgs,HEADING);
			theSpot = theSpot->next;
			}
		fprintf (stdout,"\n");
		}
	else if (doLabels && doDB)
		{
		Output_Spot (theSpotListHead,argc,argv,outArgs,DATABASE_HEADING);
		fprintf (stdout,"\n");
		}
/*
We want to write the output so that all the spots for a given timepoint are in one row, and 
subsequent rows are subsequent timepoints.  Obviously, we need to have the spot columns match up so
that we can read trajectories down one column, say.

There are two ways to accomplish this.  Either make the dataset coherent in terms of trajectories,
or keep the dataset as it is, and deal with trajectories for this kind of output only.
The dataset in its current state is not coherent in terms
of trajectories, but it is complete.  By coherency I mean that a spot may have appeared in timepoint 2
that did not exist in timepoint 0.  This spot would not appear in this output, becase it does not belong
to any trajectory - all trajectories that we output begin at t0.  The other case is that two trajectories
join either from a colision, which will remain unresolved, or becaue a spot disapeared somewhere along the
line and its nearest neighbor in the following timepoint is in fact an unrelated spot.  A consistent dataset
would have the same number of spots in each timepoint, ordered such that traveling down any timepoint's spot
list would have you visit its spots in the same order.  This would necessitate deleting spots that are not
part of any trajectory, and also duplicate any spots due to joined trajectories.  

Since we did all this hard work to find these spots, I am loathe to delete and duplicate them willy-nilly.
For this reason I chose option two, which is to just travel down a trajectory starting with t0 down however
many timepoints to the timepoint you want and output the spot there.  This would have to be done for every
single spot.  Not that big a deal computationally, we get to keep all the spots the way they are, and we get
the output we want.
*/
	thisTime = theSpotListHead->itsTimePoint;
	theSpot = theSpotListHead;
	while (!done)
		{
		theTimepointListHead = theSpot;
		if (!doDB)
			for (i=0;i<argc;i++)
				{
				if (!strcmp ( argv[i],"-tm"))
					fprintf (stdout,"%7.1f\t",theSpot->itsStack->mean_i[theSpot->itsWave]);
				if (!strcmp ( argv[i],"-tSD"))
					fprintf (stdout,"%7.2f\t",theSpot->itsStack->sigma_i[theSpot->itsWave]);
				if (!strcmp ( argv[i],"-tt"))
					fprintf (stdout,"%4d\t",theSpot->itsTimePoint);
				if (!strcmp ( argv[i],"-th"))
					fprintf (stdout,"%7d\t",theSpot->itsStack->threshold);
				}
	/*
	* Go through all the spots for the timepoint.
	*/
		while (theSpot->next != theTimepointListHead)
			{
			if (doDB)
				{
				Output_Spot (theSpot,argc,argv,outArgs,DATABASE_VALUES);
				fprintf (stdout,"\n");
				}
			else
				Output_Spot (theSpot,argc,argv,outArgs,VALUES);
		
		/*
		* Advance to the next spot in the first timepoint.
		*/
			theSpot = theSpot->next;
			}
		
		theSpot = theSpot->next;
	/*
	* Write a newline to output.
	*/
		if (!doDB)
			fprintf (stdout,"\n");
		fflush (stdout);

	/*
	* Advance the timepoint by moving theSpot to the nextTimePointList.
	* This is done only to get the next timepoint, and to know when we're done.
	*/
		theSpot = theSpot->nextTimePointList;
		if (theSpot == NULL)
			done = 1;
		else
			thisTime = theSpot->itsTimePoint;
		}
	
}

pixel Set_Threshold (const char *arg, DVstack *theStack)
{
float nSigmas;
int theThreshold;
int spotWave;
char argUC[128];
char* argUCptr;
const char* argPtr;


	argUCptr = argUC;
	argPtr = arg;
	while (*argPtr) {*argUCptr++ = toupper (*argPtr++); }
	*argUCptr++ = '\0';

	spotWave = theStack->spotWave;

	if (!strncmp(argUC,"MEAN",4))
		{
		nSigmas = 0;
		if (strlen (argUC) > 4)
			sscanf (strrchr(argUC,'N')+1,"%fS",&nSigmas);
		theThreshold = (int) (theStack->mean_i[spotWave] + (theStack->sigma_i[spotWave]*nSigmas));
		}
	else if (!strncmp(argUC,"GMEAN",5))
		{
		nSigmas = 0;
		if (strlen (argUC) > 5)
			sscanf (strrchr(argUC,'N')+1,"%fS",&nSigmas);
		theThreshold = (int) (theStack->geomean_i[spotWave] + (theStack->sigma_i[spotWave]*nSigmas));
		}

	else if (!strcmp (argUC,"MOMENT"))
		theThreshold = Get_Thresh_Moment (theStack);
	else if (!strcmp (argUC,"OTSU"))
		theThreshold = Get_Thresh_Otsu (theStack);
	else if (!strcmp (argUC,"ME"))
		theThreshold = Get_Thresh_ME (theStack);
	else if (!strcmp (argUC,"KITTLER"))
		theThreshold = Get_Thresh_Kittler (theStack);
	else
		sscanf (argUC,"%d",&theThreshold);


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
	theWave = theStack->spotWave;
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
double psi = 0, psiMax=0.0;
unsigned long i,j;
pixel thresh = 0;

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
	return (thresh);

}






















/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                     MAIN PROGRAM                   ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

int main (int argc, char **argv)
{
DVstack* theOldStack = NULL,*theStackListHead = NULL;
FILE *fp= NULL;
long i;
int spotWave,minSpotVol,time;
PixPtr index,maxIndex;
SpotPtr theSpotList=NULL,theSpotListHead=NULL;
int tStart=0,tStop=0;
Point5D dims = { 0, 0, 0, 0, 0};
const char* argval = NULL;
const char* threshold = NULL;
argarray_t args;
argiterator_t argiter = 0;
const char* c_rgRequiredArgs[64] = {
	"Dims"  , "dimensions of the input file",
	"WaveStats","per-wave per-timepoint statists",
	"",""
};

/*
* The following line is commented out because it is not
* needed for UNIX.	 It IS needed for MetroWerks CodeWarrior to
* get command line arguments.
*/
#ifdef __MWERKS__
argc = ccommand(&argv);
#endif

/*
 * Initialize argument parser. Read args from stdin and add the args from CLI
*/
	Argarray_Initialize (&args);
	Argarray_ImportDashCLI (&args, argc, argv);

/*
* Write the command line arguments to stdout - mainly so that
* the command line ends up in a log file.  If the user issued -nl, then supress
* this output also.
*/
#ifdef DEBUG
	if (!Argarray_NameExists (&args, "db"))
		Argarray_DumpArgs (&args);
#endif

/*
* Check to see that we got an appropriate number of arguments.  If not, print out a helpfull
* usage message to stderr.
*/
	if (argc < OUTARGS)
	{
		fprintf (stderr,"Usage:\n");
		fprintf (stderr,"\t%s <DV filename> <waveindex> <threshold> <min spot vol> [<optional arguments> <output arguments>]\n", Argarray_GetString(&args,"AppName"));
		fprintf (stderr,"Note that the brackets (<>) are used to delineate options in this usage message.\n");
		fprintf (stderr,"Do not use brackets when actually putting in arguments.\n");
		fprintf (stderr,"On stdin the following arguments must be given:\n");
		fprintf (stderr,"\tDims=<width>,<height>,<z-depth>,<nwaves>,<ntimepoints>\n");
		fprintf (stderr,"\tWaveStats=\n");
		fprintf (stderr,"\t<waveindex>,<wavelength>,<timepoint>,<min_intensity>,<max_i>,<mean_i>,<geometric_mean_i>,<sigma>\n");
		fprintf (stderr,"\t... [one entry per wave per timepoint] ...\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"<thresholds>:\n");
		fprintf (stderr,"\tnumber:  If a number is entered for this field, then it will be used as the threshold.\n");
		fprintf (stderr,"\tmean:	The mean pixel value at the specified waveindex will be used as the threshold.\n");
		fprintf (stderr,"\tmean<n>s:	The mean pixel value plus <n> standard deviations will be used as threshold.\n");
		fprintf (stderr,"\tgmean:	 The geometric mean of the specified waveindex will be used as threshold.\n");
		fprintf (stderr,"\tgmean<n>s:	 The geometric mean plus <n> standard deviations will be used for threshold.\n");
		fprintf (stderr,"\tmoment:  The moment preservation method.\n");
		fprintf (stderr,"\totsu:  The Otsu's determinant threshold.\n");
		fprintf (stderr,"\tme:  The maximum entropy method.\n");
		fprintf (stderr,"\tkittler:  The Kittler method of minimum error.\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"<optional arguments>:\n");
		fprintf (stderr,"\t-time <n1>-<n2> begin and end timepoints.  Default is all timepoints. -time 4- will do t4 to the end, etc.\n");
		fprintf (stderr,"\t-polyVec <filename> output tracking vectors to DV 2-D polygon file.\n");
		fprintf (stderr,"\t-polyTra <filename> output trajectories to DV 2-D polygon file.\n");
		fprintf (stderr,"\t-iwght <fraction> weight of spot's average intensity for finding spots in t+1 (def. = 0.0).\n");
		fprintf (stderr,"\t<Output arguments>:\n");
		fprintf (stderr,"\t-db Format output for database import - tab-delimited text.\n");
		fprintf (stderr,"\t    Database format is one line per spot.  Any summary information specified (-tm, -tt, etc) will be\n");
		fprintf (stderr,"\t    displayed once for each spot - not once per timepoint. Column order will be as specified in <Output arguments>,\n");
		fprintf (stderr,"\t    Spots in a trajectory will have the same ID, but different timepoints.  For now, only spots in trajectories starting\n");
		fprintf (stderr,"\t    with t0 are displayed\n");
		fprintf (stderr,"\t-nl Supress column headings.  Usefull if database does not recognize column headings (i.e. FileMaker)\n");
		fprintf (stderr,"\t-ID Display the spot's ID# - a 'serial number' unique to each spot in this dataset.\n");
		fprintf (stderr,"\t-tID Display the trajectory ID# - a 'serial number' unique to to each trajectory in this dataset.\n");
		fprintf (stderr,"\t-dID Dataset ID - Usefull if combining many datasets in a database.  The ID is the filename, and will\n");
		fprintf (stderr,"\t     be the same for all spots in this dataset.\n");
		fprintf (stderr,"\t-aID Argument ID.  Display input arguments - text containing the required arguments for this run - everything except\n");
		fprintf (stderr,"\t     the filename, polyVec, polyTra and <output arguments>.  The arguments are separated by a space, not a tab.\n");
		fprintf (stderr,"\t-c <waveindex>: Display centroids (center of mass).\n");
		fprintf (stderr,"\t-i <waveindex>:  Display integral - sum of pixel values\n");
		fprintf (stderr,"\t-m <waveindex> Display mean pixel value.\n");
		fprintf (stderr,"\t-g <waveindex> Display the geometric mean pixel value.\n");
		fprintf (stderr,"\t-ms <waveindex> Same as -m, but number of std. deviations over the waveindex's mean.\n");
		fprintf (stderr,"\t-gs <waveindex> Same as -g, but number of std. deviations over the waveindex's geometric mean.\n");
		fprintf (stderr,"\t-mc Display the average coordinate values of the spot (center of volume).\n");
		fprintf (stderr,"\t-v Display the spot's volume\n");
		fprintf (stderr,"\t-ff Display the spot's form-factor (1 for sphere in 3D or circle in 2D, <1 if deviates)\n");
		fprintf (stderr,"\t-per Display the spot's perimiter\n");
		fprintf (stderr,"\t-sa Display the spot's surface area\n");
		fprintf (stderr,"\t### Time series data ###\n");
		fprintf (stderr,"\t-tm Display mean pixel value of the entire timepoint for the spot's waveindex - once/timepoint\n");
		fprintf (stderr,"\t-tSD Display the standard deviation of the entire timepoint for the spot's waveindex - once/timepoint\n");
		fprintf (stderr,"\t-tt Display the timepoint number (once/timepoint).\n");
		fprintf (stderr,"\t-th Display the threshold used for the timepoint (once/timepoint).\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"Output:\n");
		fprintf (stderr,"\tThe output is a table of vectors.  There is one row (line) for each timepoint.  The requested output is\n");
		fprintf (stderr,"\tplaced in columns with one set of columns for each feature (or 'spot').\n");
		fprintf (stderr,"\tThe option -tm, -tSD -tt -th may be specified any number of times in any order\n");
		fprintf (stderr,"\t(or not at all).  They will be displayed once per timepoint (once per line of output) before the other outputs.\n");
		fprintf (stderr,"\tN.B.:  The number of sets of columns in the output is the number of spots found in the first timepoint.\n");
		fprintf (stderr,"\tIf spots appear at later timepoints, they will not be in the output.\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"Example:\n");
		fprintf (stderr,"\tfindSpotsOME lookatemgo.r3d_d3d 528 gmean4.5s 10 -polyTra polyFoo -iwght 0.05 -time5- -tt -tm -tSD\n");
		fprintf (stderr,"\n");	

		exit (-1);
	}

	/* Get the stdin arguments */
	fprintf (stderr,"Please enter Dims and WaveStats (or ^D to abort):\n");
	Argarray_ImportPOSTFromStdin (&args);
	if (!Argarray_VerifyRequiredArgs (&args, &c_rgRequiredArgs[0]))
		exit (-1);

	/*
	 * Get the image dimensions
	 */
	sscanf (Argarray_GetString(&args,"Dims"), "%hd,%hd,%hd,%hd,%hd", &dims.x, &dims.y, &dims.z, &dims.w, &dims.t);

	/*
	* Open the DV file, with error checking.
	*/

	/*
	* Get the spot wavelegth and the minimum spot volume.
	*/
	Argiter_Initialize (&args, &argiter, "AppName");
	fp = OpenFile (Argiter_NextString (&argiter), "r");
	spotWave = Argiter_NextInteger (&argiter);
	threshold = Argiter_NextString (&argiter);
	minSpotVol = Argiter_NextInteger (&argiter);

	/*
	* Read the timespan option
	*/
	argval = Argarray_GetString (&args, "time");
	if (argval)
		sscanf (argval, "%d-%d", &tStart, &tStop);

/*
* Set the timepoint range to use.
* tStart and tStop start out being 0.  If they were not specified then we use all of them
* if they were specified then they will be based on time0 = 1, rather time0 = 0
* (as per DV convention), so we subtract one from each of them.  If we end up with negative tStart
* we set it to 0 (default).  If tStop is less than or equal to tStart, then tStop is the number
* of timepoints in the file.
*/
	tStart--;
	tStop--;
	if (tStart < 0)
		tStart = 0;
	if (tStop < tStart)
		tStop = dims.t;
/*
* We are going to output the thresholds - one per timepoint - on a single line.
	fprintf (stdout,"Timepoint:\t");
	for (time=tStart;time < tStop;time++)
		fprintf (stdout,"%4d\t",time);
	fprintf (stdout,"\nThreshold:\t");
*/

/*
* ################   MAIN  LOOOP   ################ *
*/

	/*
	* Get the wave statistics
	*/
	Argiter_Initialize (&args, &argiter, "WaveStats");
	/* skip stats for unused timepoints */
	/* FIXME: remove the ugly empty stack hack when the stack list is gone */
	theStackG = (DVstack*) malloc (sizeof(DVstack));
	InitializeDVstack (theStackG, dims);
	for (time = 0; time < tStart; ++ time)
		ReadWaveStats (theStackG, &argiter, time);
	free (theStackG);
	theStackG = NULL;

	for (time = tStart; time < tStop; time++) {
/*
* Read in the stack of images.
*/
		theStackG = (DVstack*) malloc (sizeof(DVstack));
		InitializeDVstack (theStackG, dims);
		ReadDVstack (theStackG, fp, dims, time);
		ReadWaveStats (theStackG, &argiter, time);

		/* put the stack in the stack list */
		if (theStackListHead == NULL)
			theStackListHead = theStackG;
		else
			theOldStack->next = theStackG;
		theOldStack = theStackG;
		theStackG->next = NULL;
#ifdef DEBUG
fprintf (stderr,"read DV stack\n");
fflush (stderr);
#endif
	/*
	 * Write out the waves we found in the DV file
		fprintf (stdout,"Wave:	   ");
		for (i=0;i<theStackG->nwaves;i++)
			fprintf (stdout,"\t%7d",(int)theStackG->wave[i]);
		fprintf (stdout,"\n");
	 */
		
#ifdef DEBUG
		fprintf (stderr,"Wave:	   ");
		for (i=0;i<theStackG->nwaves;i++)
			fprintf (stderr,"\t%7d",(int)theStackG->wave[i]);
		fprintf (stderr,"\n");
		fflush (stderr);
#endif
	/*
	* Get_Wave_Index returns an index that's out of bounds ( > waves in stack)
	* if it could not find an appropriate index.
	*/
		if (spotWave >= theStackG->nwaves)
		{
			fprintf (stderr,"Could not find wavelength %d in file %s\n", spotWave, argv[1]);
			exit (-1);
		}
	
	theStackG->spotWave = spotWave;
	
	/*
	* Calculate statistics for the stack.
	*/
		for (i=0;i<theStackG->nwaves;i++)
			Calculate_Stack_Stats (theStackG,i);
	
#ifdef DEBUG
fprintf (stderr,"Calculated stats\n");
fflush (stderr);
#endif
	
	/*
	* figure out what to set the threshold to.
	*/
		thresholdG = Set_Threshold (threshold,theStackG);
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

/*
* Instead of ouputing all the gobelty gook above, we are just going to print the threshold
* and a tab.
	fprintf (stdout,"%4d\t",(int) thresholdG);
	fflush (stdout);
*/
	
	
		
	
	
	/*
	* Allocate memory for the first spot.
	* theSpotG will allways point to the spot-in-progress.	Once completed,
	* a new spot is allocated, and that new spot is then pointed to by
	* theSpotG.	 In this way, theSpotG is allways the last spot in the list,
	* and it is never a valid spot - it is either blank or in progress.
	*/
	
		theSpotG = New_Spot (NULL,theStackG,spotWave,time);
		if (theSpotG == NULL)
		{
			fprintf (stderr,"Could not allocate memory for spot.\n");
			exit (-1);
		}
	
	/*
	* We make a new list pointed to by theSpotList for each timepoint.
	* If this is the first timepoint, then we point theSpotListHead to theSpotG.
	* Otherwise we set nextTimePointList of theSpotList (which is still the previous TP's list)
	* to theSpotG.
	*/
		if (theSpotListHead == NULL)
			theSpotListHead = theSpotG;
		else
			theSpotList->nextTimePointList = theSpotG;

	/*
	* Once our list is safely attached, we set theSpotList to the new spot.
	*/
		theSpotList = theSpotG;
	
	
	/*
	* Set index to point to the first pixel in the wave which we will use
	* to pick out spots.
	*/
		index = theStackG->stack + (theStackG->wave_increment*spotWave);
	
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
				if (theSpotG->volume >= minSpotVol)
					{
					Update_Spot_Stats (theSpotG);
					theSpotG = New_Spot (theSpotList,theStackG,spotWave,time);
					}
			
			/*
			* If the spot was smaller than the minimum size, we need to make sure
			* all the accumulators and such are zeroed-out.
			*/
				else
					Zero_Spot (theSpotG,theStackG,spotWave,time);
			} /* The index was > threshold so we ate a spot. */
			index++;
		} /* loop for all the pixels in a timepoint */
	} /* loop for all the timepoints. */

/*
* Write a newline at the end of the thresholds.
	fprintf (stdout,"\n");
*/

/*
* Output of spot info is handled by Write_Output
*/
	Write_Output (theSpotListHead, argc, argv, OUTARGS);
	
	Argarray_Destroy (&args);
/*
* Exit gracefully.
*/	
	return (0);
}

