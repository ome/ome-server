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
 
Title:	trackSpots
Purpose:  This program reads in a stack of Delta Vision images contained in
	a DeltaVision file.	 The program then finds all "spots" that are above the specified
	threshold at the specified wavelegth, and bigger than the specified size.  The program then
	calculates the trajectory of each spot from the timepoints in the image file.  
	The program then reports various statistics that it has collected about these "spots"
	and their trajectories - according to the user's specification.
Inputs:	 There are four required inputs separated by spaces.
The order of the inputs is important.
Usage:
>findSpots <DV file> <spot wavelngth> <threshold> <min. vol.> <optional arguments> <output options>
<DV file> is the name of the DeltaVision file.
<spot wavelegth> is the wavelegth from which to pick out "spots"
<threshold>	 all contiguous pixels that are above threshold will be considered to comprise a
	single spot.
<min. val.>	 All spots that are smaller in volume than this volume will not be reported.
<output options>  A set of options to specify what is displayed about each spot.  The options
	may be specified in any order, and any number of times.	 The result will be a tab-delimited
	table with one row per spot.  When a wavelegth is required for an option, if a wavelegth of
	0 is specifie then the specified information will be displayed about all wavelegths that
	exist in the file, in the order in which they appear in the file.
	The output options:
	-c <wavelegth>:
		Display centroids.	Since a centroid can be thought of as a center of mass, there is
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
		Display the average coordinate values of the spot.	This is the center of volume.
		X, Y, Z will be displayed.
	-v
		Display the spot's volume - the total number of pixels that make up the spot.
	There are other statistics that are maintained for each spot, unfortunately there
	are as yet no output options to cause them to be displayed.
Example:
findSpots DVfile 600 300 12 -v -c 600 -i 0 -mean 456
	
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

#define MAXDIST 1e10
#define OUTARGS 5


#define TIFF_MAGIC 3232
#define DV_MAGIC -16224








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










/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################               DEFINITION OF FUNCTIONS              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

DVhead *ReadDVHeader( DVhead *head, FILE *fp );
DVstack *ReadDVstack(FILE *fp,DVhead *head,long time );
void Calculate_Stack_Stats (DVstack *theStackG,int theWave);
void Push_Stack (PixPtr index, IndexStack theStack);
PixPtr Pop_Stack (IndexStack theStack);
void Eat_Spot_Rec (PixPtr index);
void Eat_Spot(PixPtr index);
void Update_Spot(PixPtr index);
PixPtr Update_Index (PixPtr index, char direction);
SpotPtr New_Spot (SpotPtr spotList,DVstack *theStackG, char itsWave, short itsTime);
void Zero_Spot (SpotPtr theSpotG,DVstack *theStackG, char itsWave, short itsTime);
void Update_Spot_Stats (SpotPtr theSpotG);
void Output_Spot (SpotPtr theSpotG, int argc, char**argv,int outArgs, char saywhat);
int Get_Wavelngth_Index (DVstack *theStackG, int waveLngth);
void Write_Output (SpotPtr theSpotListHead,int argc, char**argv,int outArgs);
void Write_Polygon_File (FILE *polyOut,char doVectors,SpotPtr theSpotListHead,int tStart,int tStop);
double Get_Spot_Dist_Centroid (SpotPtr fromSpot,SpotPtr toSpot);
double Get_Distance_Score (SpotPtr fromSpot,SpotPtr toSpot,float intnsWght);
void Calculate_Spot_Vector (SpotPtr theSpot);
void Compose_inArgs (char *inArgs, int argc, char**argv);


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
	char nwaves;
	char itsWave;  /* this is the wave index for the wavelegth that this
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
* The trajectory ID
*/
	long trajID;

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
* Return if index is NULL or index points to a pixel below threshold.
*/
	if (index == NULL) return;
	if (*index <= thresholdG) return;

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

/*
* We update the spot's statistics based on the properties of this pixel (position, intensity, etc).
* This is the seed pixel.
*/
	Update_Spot (index);

/*
* We set this pixel to threshold so that we don't count it again.
*/
	*index = thresholdG;
	
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
	Push_Stack (Update_Index(index,Z_PLUS),theStack);
	Push_Stack (Update_Index(index,Z_MINUS),theStack);

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
			Update_Spot (index);
			*index = thresholdG;
			Push_Stack (Update_Index(index,X_PLUS),theStack);
			Push_Stack (Update_Index(index,X_MINUS),theStack);
			Push_Stack (Update_Index(index,Y_PLUS),theStack);
			Push_Stack (Update_Index(index,Y_MINUS),theStack);
			Push_Stack (Update_Index(index,Z_PLUS),theStack);
			Push_Stack (Update_Index(index,Z_MINUS),theStack);
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
	Update_Spot (index);

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










/*#########################*/
/*#                       #*/
/*#       Update_Spot     #*/
/*#                       #*/
/*#########################*/
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
float floatIndex;


/*
* We need to back-calculate the coordinates from the index.
*/

/*
* First,  subtract the stack pointer from index,  thus getting
* a "true" index.
*/
	index2 = index - theStackG->stack;

/*
* Second,	subtract the wave increment to get an index into the stack.
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
* Lastly,	if we subtract the y coordinate * width from the index,	 we will be left
* with the x coordinate.
*/
	index2 -= (theSpotG->cur_y * (theStackG->y_increment));
	theSpotG->cur_x = index2;

/*
* It is important to note that these coordinates are based on the origin being (0,0,0) not
* as DV defines it at (1,1,1).  For now, we will leave the internal coordinate base at (0,0,0),
* and add the vector (1,1,1) to the displayed coordinates.  This is an interim solution
* pending something more elegant and consistent.  Ideally, this would be to have DV move
* its coordinate base to (0,0,0) as is done in the rest of the known universe.  Having
* written something in FORTRAN with arrays based on index 1 is no excuse not to follow convention.
*/

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
SpotPtr New_Spot (SpotPtr spotList,DVstack *inStack, char itsWave, short itsTime)
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
	Zero_Spot (newSpot, inStack, itsWave, itsTime);
	
	return (newSpot);
}










/*#########################*/
/*#                       #*/
/*#       Zero_Spot       #*/
/*#                       #*/
/*#########################*/
void Zero_Spot (SpotPtr zeroSpot,DVstack *itsStack, char itsWave, short itsTime)

{
unsigned char i;


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
	

/* -tID :	 Output trajectory ID */
		if (!strcmp ( argv[theArg],"-tID"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"traj.ID");
			else
				fprintf (stdout,"%7ld",outSpot->trajID);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -tID */
	

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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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
				theWave = Get_Wavelngth_Index (itsStack,theWave);
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



/* -tv :  Display the spot's trajectory vector - vector to this spot in next timepoint.	 */
		else if (!strcmp ( argv[theArg],"-tv"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"  dX  \t  dY  \t  dZ  ");
			else
				if (outSpot->nextTimePoint != NULL)
					fprintf (stdout,"%6.2f\t%6.2f\t%6.2f",
						outSpot->vecX,outSpot->vecY,outSpot->vecZ);
				else
					fprintf (stdout,"------\t------\t------");
			fprintf (stdout,"\t");
		} /* -tv */
	
	
/* -td :  Display the distance the spot traveled to the next timepoint (in um). 	 */
		else if (!strcmp ( argv[theArg],"-td"))
		{
			if (saywhat == HEADING)
				fprintf (stdout," dist. ");
			else
				if (outSpot->nextTimePoint != NULL)
					fprintf (stdout,"%7.3f",
						Get_Spot_Dist_Centroid (outSpot,outSpot->nextTimePoint) );
				else
					fprintf (stdout,"-------");
			fprintf (stdout,"\t");
		} /* -td */

    	else if (!strcmp ( argv[theArg],"-tm") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout," Mean  \t");
			else
				fprintf (stdout,"%7.1f\t",outSpot->itsStack->mean_i[(int)outSpot->itsWave]);
    		}
    	else if (!strcmp ( argv[theArg],"-tSD") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout,"  SD   \t");
			else
				fprintf (stdout,"%7.2f\t",outSpot->itsStack->sigma_i[(int)outSpot->itsWave]);
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

	theWaveIndx = MAXWAVES+1;
	for (i=0; i < MAXWAVES; i++)
		if (inStack->wave[i] == waveLngth) theWaveIndx = i;
	return (theWaveIndx);
}










/*#########################*/
/*#                       #*/
/*# Get_Spot_Dist_Centroid#*/
/*#                       #*/
/*#########################*/
/*
* Get the distance between the centroids of the two spots.  The centroids are from the
* wavelegth used to find the spot.
*/
double Get_Spot_Dist_Centroid (SpotPtr fromSpot,SpotPtr toSpot)
{
float dX,dY,dZ;
short theWave;

	if (toSpot == NULL || fromSpot == NULL)
		return (-1.0);
	theWave = toSpot->itsWave;
	dX = toSpot->centroid_x[theWave] - fromSpot->centroid_x[theWave];
	dY = toSpot->centroid_y[theWave] - fromSpot->centroid_y[theWave];
	dZ = toSpot->centroid_z[theWave] - fromSpot->centroid_z[theWave];

	dX *= theStackG->head->xlen;
	dY *= theStackG->head->ylen;
	dZ *= theStackG->head->zlen;

	dX *= dX;
	dY *= dY;
	dZ *= dZ;

	return (sqrt (dX+dY+dZ) );
}










/*#########################*/
/*#                       #*/
/*#  Get_Distance_Score   #*/
/*#                       #*/
/*#########################*/
/*
* This routine considers factors other than distance to calculate a "distance" score between two
* spots.  Besides distance, currently it uses the integral as an additional "distance" parameter
* which is weighed by intnsWght.  What is returned is essentially a residual (R value) across all these
* parameters.
*/
double Get_Distance_Score (SpotPtr fromSpot,SpotPtr toSpot,float intnsWght)
{
double dX,dY,dZ,dI;
short theWave;

	theWave = toSpot->itsWave;
	dX = toSpot->centroid_x[theWave] - fromSpot->centroid_x[theWave];
	dY = toSpot->centroid_y[theWave] - fromSpot->centroid_y[theWave];
	dZ = toSpot->centroid_z[theWave] - fromSpot->centroid_z[theWave];
	dX *= theStackG->head->xlen;
	dY *= theStackG->head->ylen;
	dZ *= theStackG->head->zlen;
	dX *= dX;
	dY *= dY;
	dZ *= dZ;

	dI = abs(toSpot->mean_i[theWave] - fromSpot->mean_i[theWave]);
	dI *= intnsWght;

/*
	dV = toSpot->volume - fromSpot->volume;
	dV *= dV;
*/
	

	return (sqrt (dX+dY+dZ)+dI );
}









/*#########################*/
/*#                       #*/
/*# Calculate_Spot_Vector #*/
/*#                       #*/
/*#########################*/
void Calculate_Spot_Vector (SpotPtr theSpot)
{
short theWave;
/*
* just calculate the vector to the spot in the next timepoint
*/
	theWave = theSpot->itsWave;
	theSpot->vecX = theSpot->nextTimePoint->centroid_x[theWave] - theSpot->centroid_x[theWave];
	theSpot->vecY = theSpot->nextTimePoint->centroid_y[theWave] - theSpot->centroid_y[theWave];
	theSpot->vecZ = theSpot->nextTimePoint->centroid_z[theWave] - theSpot->centroid_z[theWave];
}









void Write_Output (SpotPtr theSpotListHead,int argc, char**argv,int outArgs)
{
SpotPtr theSpot,theTrajectorySpot,theTimepointSpot;
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
	theTimepointSpot = theSpotListHead;
	while (!done)
		{
		theSpot = theSpotListHead;
		if (!doDB)
			for (i=0;i<argc;i++)
				{
				if (!strcmp ( argv[i],"-tm"))
					fprintf (stdout,"%7.1f\t",theTimepointSpot->itsStack->mean_i[(int)theSpot->itsWave]);
				if (!strcmp ( argv[i],"-tSD"))
					fprintf (stdout,"%7.2f\t",theTimepointSpot->itsStack->sigma_i[(int)theSpot->itsWave]);
				if (!strcmp ( argv[i],"-tt"))
					fprintf (stdout,"%4d\t",theTimepointSpot->itsTimePoint);
				if (!strcmp ( argv[i],"-th"))
					fprintf (stdout,"%7d\t",theTimepointSpot->itsStack->threshold);
				}
	/*
	* Go through all the spots for the first timepoint.
	*/
		while (theSpot->next != theSpotListHead)
			{
			long trajID=0;
		/*
		* Travel down the trajectory until we get to the right timepoint, then output the spot.
		*/
			theTrajectorySpot = theSpot;
	        trajID = theTrajectorySpot->trajID;
			while (theTrajectorySpot != NULL && theTrajectorySpot->itsTimePoint != thisTime)
				theTrajectorySpot = theTrajectorySpot->nextTimePoint;
            theTrajectorySpot->trajID = trajID;
			if (doDB)
				{
				Output_Spot (theTrajectorySpot,argc,argv,outArgs,DATABASE_VALUES);
				fprintf (stdout,"\n");
				}
			else
				Output_Spot (theTrajectorySpot,argc,argv,outArgs,VALUES);
		
		/*
		* Advance to the next spot in the first timepoint.
		*/
			theSpot = theSpot->next;
			}
		
	/*
	* Write a newline to output.
	*/
		if (!doDB)
			fprintf (stdout,"\n");
		fflush (stdout);
		
	/*
	* Advance the timepoint by moving theTimepointSpot to the nextTimePointList.
	* This is done only to get the next timepoint, and to know when we're done.
	*/
		theTimepointSpot = theTimepointSpot->nextTimePointList;
		if (theTimepointSpot == NULL)
			done = 1;
		else
			thisTime = theTimepointSpot->itsTimePoint;
		}
	
}










void Write_Polygon_File (FILE *polyOut,char doVectors,SpotPtr theSpotListHead,int tStart,int tStop)
{
SpotPtr theSpot,theSpotNextTime;
int time;

	fprintf(polyOut,"#POLYGON_FILE\n");


/*
* We travel down the list of spots in the first timepoint.  For each spot encountered there,
* we travel down the list of ->nextTimePoint, which points to the same spot in the next
* timepoint.  Before we move down the next timepoint, we output the vector to the next
* timepoint.
* The first three columns are the coordinates of the spot in the first time-point.
* Subsequent sets of three columns are the vectors to the spot in the next timepoint.
*/
	theSpot = theSpotListHead;
	while (theSpot->next != theSpotListHead)
		{
		fprintf (stdout,"%7.2f\t%7.2f\t%7.2f\t",
			theSpot->centroid_x[(int)theSpot->itsWave],
			theSpot->centroid_y[(int)theSpot->itsWave],
			theSpot->centroid_z[(int)theSpot->itsWave]);
		theSpotNextTime = theSpot;
		while (theSpotNextTime->nextTimePoint != NULL)
			{
		/*
		* Each polygon is a line that is a 2 dimmentional projection of the three
		* dimmentional vector to the spot in the next time-point.  That's a fancy way
		* of saying that we don't output the Z coordinate.  The polygon has four points,
		* two of which are the spot's centroid and two of which are the centroid plus
		* the vector to the next spot.
		* DV incorrectly has its coordinate base at (1,1,1) instead of (0,0,0), so we add
		* the vector (1,1,1) to the coordinates we send to DV.
		*/
			if (doVectors)
				{
				fprintf (polyOut,"section %d %d %d\n",theSpotNextTime->itsWave,0,theSpotNextTime->itsTimePoint);
				fprintf (polyOut,"polygon 0 1 4\n");
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecX+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecY+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecX+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecY+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+1));
				}
			else for (time=tStart;time < tStop;time++)
				{
				fprintf (polyOut,"section %d %d %d\n",theSpotNextTime->itsWave,0,time);
				fprintf (polyOut,"polygon 0 1 4\n");
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecX+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecY+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecX+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+theSpotNextTime->vecY+1));
				fprintf (polyOut,"point %d %d\n",
					(int) (theSpotNextTime->centroid_x[(int)theSpotNextTime->itsWave]+1),
					(int) (theSpotNextTime->centroid_y[(int)theSpotNextTime->itsWave]+1));
				}
			theSpotNextTime = theSpotNextTime->nextTimePoint;
			}
		theSpot = theSpot->next;
		}
	fprintf (polyOut,"end\n");
}





























/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                     MAIN PROGRAM                   ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

int main( int argc, char **argv )
{
DVhead head;
DVstack *theOldStack,*theStackListHead;
FILE *fp= NULL,*polyOut=NULL;
char *file = NULL;
char evaluate=0,doVectors=0;
long i;
int spotWaveLngth,spotWave,minSpotVol,theThreshold,time;
PixPtr index,maxIndex;
SpotPtr theSpotList=NULL,theSpotListHead=NULL,theSpotNextTime=NULL,theSpot=NULL;
float nSigmas,theDist,minDist,intnsWght=0.0;
int tStart=0,tStop=0;
long trajID = 0;
char firstTimepoint = 1;


/*
* The following line is commented out because it is not
* needed for UNIX.	 It IS needed for MetroWerks CodeWarrior to
* get command line arguments.
*/
#ifdef __MWERKS__
argc = ccommand(&argv);
#endif

/*
* Write the command line arguments to stdout - mainly so that
* the command line ends up in a log file.  If the user issued -nl, then supress
* this output also.
*/
	for (i=0;i<argc && strcmp (argv[i],"-db");i++);

    if (i == argc)
        {
    	for (i=0;i<argc;i++)
    		fprintf (stdout,"%s ",argv[i]);
    	fprintf (stdout,"\n");
    	}

/*
* Check to see that we got an appropriate number of arguments.  If not, print out a helpfull
* usage message to stderr.
*/
	if (argc < OUTARGS)
	{
		fprintf (stderr,"Usage:\n%s <%s> <%s> <%s> <%s> <%s> <%s>\n",
				argv[0],"DV filename","spot wavelegth","threshold","min. spot vol.",
				"optional arguments","output arguments");
		fprintf (stderr,"Note that the brackets (<>) are used to delineate options in this usage message.\n");
		fprintf (stderr,"Do not use brackets when actually putting in arguments.\n");
		fprintf (stderr,"<thresholds>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"number:  If a number is entered for this field, then it will be used as the threshold.",
			"mean:	The mean pixel value at the specified wavelegth will be used as the threshold.",
			"mean<n>s:	The mean pixel value plus <n> standard deviations will be used as threshold.",
			"gmean:	 The geometric mean of the specified wavelegth will be used as threshold.",
			"gmean<n>s:	 The geometric mean plus <n> standard deviations will be used for threshold.");
		fprintf (stderr,"<optional arguments>:\n\t%s\n\t%s\n\t%s\n\t%s",
			"-time<n1>-<n2> begin and end timepoints.  Default=all. -time4- will do t4 to the end, etc.",
			"-polyVec <filename> output tracking vectors to DV 2-D polygon file.",
			"-polyTra <filename> output trajectories to DV 2-D polygon file.",
			"-iwght <fraction> weight of spot's average intensity for finding spots in t+1 (def. = 0.0).");
		fprintf (stderr,"<Output arguments>:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"-db Format output for database import - tab-delimited text.",
			"    Database format is one line per spot.  Any summary information specified (-tm, -tt, etc) will be",
			"    displayed once for each spot - not once per timepoint. Column order will be as specified in <Output arguments>,",
			"    Spots in a trajectory will have the same ID, but different timepoints.  For now, only spots in trajectories starting",
			"    with t0 are displayed."
			"-nl Supress column headings.  Usefull if database does not recognize column headings (i.e. FileMaker)",
			"-ID Display the spot's ID# - a 'serial number' unique to each spot in this dataset.",
			"-tID Display the trajectory ID# - a 'serial number' unique to to each trajectory in this dataset.",
			"-dID Dataset ID - Usefull if combining many datasets in a database.  The ID is the filename, and will",
			"     be the same for all spots in this dataset.",
			"-aID Argument ID.  Display input arguments - text containing the required arguments for this run - everything except",
			"     the filename, polyVec, polyTra and <output arguments>.  The arguments are separated by a space, not a tab.",
			"-c <wavelegth>: Display centroids (center of mass).",
			"-i <wavelegth>:  Display integral - sum of pixel values",
			"-m <wavelegth> Display mean pixel value.",
			"-g <wavelegth> Display the geometric mean pixel value.",
			"-ms <wavelegth> Same as -m, but number of std. deviations over the wavelegth's mean.",
			"-gs <wavelegth> Same as -g, but number of std. deviations over the wavelegth's geometric mean.",
			"-mc Display the average coordinate values of the spot (center of volume).",
			"-v Display the spot's volume",
			"### Time series data ###",
			"-tm Display mean pixel value of the entire timepoint for the spot's wavelegth - once/timepoint",
			"-tSD Display the standard deviation of the entire timepoint for the spot's wavelegth - once/timepoint",
			"-tt Display the timepoint number (once/timepoint).",
			"-th Display the threshold used for the timepoint (once/timepoint).",
			"-tv Display the spot's trajectory vector - vector to this spot in next timepoint (pixel coordinates).",
			"-td Display the distance the spot traveled to the next timepoint (in um). ");
			
		fprintf (stderr,"Output:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n",
			"The output is a table of vectors.  There is one row (line) for each timepoint.  The requested output is",
			"placed in columns with one set of columns for each feature (or 'spot').  For example, if tracking",
			"vectors only are requested (-tv), then there will be three columns (dX,dY,dZ) per spot.",
			"If there are additional outputs besides the trajectory vectors, then there will be more than three",
			"columns per spot.  The option -tm, -tSD -tt -th may be specified any number of times in any order",
			"(or not at all).  They will be displayed once per timepoint (once per line of output) before the other outputs.",
			"N.B.:  The number of sets of columns in the output is the number of spots found in the first timepoint.",
			"If spots appear at later timepoints, they will not be in the output.  Likewise if spots disapear after",
			"the first timepoint, at the time of disapearance two trajectories will converge on one spot, and the",
			"trajectory of the disapeared spot will be identical to the spot it 'colided' with.");
		fprintf (stderr,"Example:\n\t%s\n",
			"trackSpots lookatemgo.r3d_d3d 528 gmean4.5s 10 -polyTra polyFoo -iwght 0.05 -time5- -tt -tm -tSD");

		exit (-1);
	}

/*
* Get the spot wavelegth and the minimum spot volume.
*/
	
	sscanf (argv[2],"%d",&spotWaveLngth);

	sscanf (argv[4],"%d",&minSpotVol);

/*
* Read the "-poly" option.
*/
	for (i=5;i<argc;i++)
		{
		if (!strncmp (argv[i],"-poly",5))
			{
			polyOut = fopen (argv[i+1],"w+");
			if (polyOut == NULL)
				{
				fprintf (stderr,"Could not open file '%s' for writing polygons.\n",argv[i+1]);
				exit (-1);
				}
			evaluate = 1;
			if (!strcmp (argv[i],"-polyVec"))
				doVectors = 1;
			}
		}

/*
* Read the intensity weight option
*/
	for (i=5;i<argc;i++)
		{
		if (!strcmp (argv[i],"-iwght"))
			sscanf (argv[i+1],"%f",&intnsWght);
		}


/*
* Read the timespan option
*/
	for (i=5;i<argc;i++)
		{
		if (!strncmp (argv[i],"-time",5))
			sscanf (argv[i]+5,"%d-%d",&tStart,&tStop);
		}


/*
* Get the DV input file.
*/
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
		fprintf(stderr,"File '%s' could not be opened.\n",file );
		exit(-1);
	}

/*
* OK, if we're here we got the parameters and an open DV file, so now we read the header.
*/
	if (!ReadDVHeader( &head, fp ))
	{
		fprintf (stderr,"Couldn't read DeltaVision file\n");
		exit (-1);
	}	

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
	if ( !(tStop > tStart) )
		tStop = head.numtimes;
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
	theStackG = NULL;
	theStackListHead = NULL;
	for (time=tStart;time < tStop;time++)
		{
/*
* If this is not the first stack we ever read, then free the stack for the previous timepoint.
*/
		if (theStackG != NULL)
			{
			free (theStackG->stack);
			theStackG->stack = NULL;
			}
		
/*
* Read in the stack of images.
*/
		theStackG = ReadDVstack(fp,&head,time);
		if (theStackG == NULL)
			{
			fprintf(stderr,"Problem reading file or allocating memmory - EXIT\n");
			exit (-1);
			}

#ifdef DEBUG
fprintf (stderr,"read DV stack\n");
fflush (stderr);
#endif
		if (theStackListHead == NULL)
			theStackListHead = theStackG;
		else
			theOldStack->next = theStackG;
		theOldStack = theStackG;
		theStackG->next = NULL;

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
	* Get the wave index of the spot wavelegth.
	*/
		spotWave = Get_Wavelngth_Index (theStackG, spotWaveLngth);
	
	/*
	* Get_Wave_Index returns an index that's out of bounds ( > waves in stack)
	* if it could not find an appropriate index.
	*/
		if (spotWave >= theStackG->nwaves)
		{
			fprintf (stderr,"Could not find wavelength %d nm in file %s\n",
					spotWaveLngth,file);
			exit (-1);
		}
	
	
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
		if (!strncmp(argv[3],"mean",4))
			{
			nSigmas = 0;
			if (strlen (argv[3]) > 4)
				sscanf (strrchr(argv[3],'n')+1,"%fs",&nSigmas);
			theThreshold = (int) (theStackG->mean_i[spotWave] + (theStackG->sigma_i[spotWave]*nSigmas));
			}
		else if (!strncmp(argv[3],"gmean",5))
			{
			nSigmas = 0;
			if (strlen (argv[3]) > 5)
				sscanf (strrchr(argv[3],'n')+1,"%fs",&nSigmas);
			theThreshold = (int) (theStackG->geomean_i[spotWave] + (theStackG->sigma_i[spotWave]*nSigmas));
			}
		else
			sscanf (argv[3],"%d",&theThreshold);
	
		thresholdG = (pixel) theThreshold;
		theStackG->threshold = thresholdG;
#ifdef DEBUG
fprintf (stderr,"spotWave: %d\n",spotWave);
fprintf (stderr,"theStackG->geomean_i[spotWave]: %f\n",theStackG->geomean_i[spotWave]);
fprintf (stderr,"theStackG->sigma_i[spotWave]: %f\n",theStackG->sigma_i[spotWave]);
fprintf (stderr,"nSigmas: %f\n",nSigmas);
fprintf (stderr,"theThreshold: %d\n",theThreshold);
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
* Now that we have the list of lists, we need to go through each spot in each timepoint and find
* the nearest neighbor in the subsequent timepoint.
* Note that a nearest neighbor is not necessarily one that is nearest in distance.  In can be
* one that is nearest in any combination of spot attributes.  Presently, a weighed intensity is used with
* distance a "nearest neighbor" criterion.  Intensity refers to the average intensity of the spot rather
* than total integral.  The weight is not presently scaled, and intensities can vary a great deal more than
* distances, so use it carefully.
*/
	theSpotList = theSpotListHead;
	
/*
* Going down the list of time-point-lists.  Since there is no place-holder timepoint list,
* if we only go until nextTimePointList is NULL, then we won't try to determine a vector
* for the last timepoint list.  That would be a no-no because we will step into the vortex
* that is located at the end of time itself.
* Note that we don't actually set vecX,vecY,vecZ to anything in the spots in this last timepoint list.
* The pointers are all properly NULL terminated, but the vector components contain 0 (from Zero_Spot) - 
* even though officially they are undefined.  Point being, it is up to whoever does anything with these
* vectors to make sure they don't belong to a spot in the last timepoint.
*/
	while (theSpotList->nextTimePointList != NULL)
		{

		theSpot = theSpotList;
	
	/*
	* Go down the list of spots for this timepoint.
	*/
		while (theSpot->next != theSpotList)
			{
			if (firstTimepoint)
			    {
			    theSpot->trajID = trajID;
			    trajID++;
                }
			theSpotNextTime = theSpotList->nextTimePointList;
			minDist = MAXDIST;
			
		/*
		* Go down the list of spots in the next timepoint to find this spot's nearest neighbor.
		*/
			while (theSpotNextTime->next != theSpotList->nextTimePointList)
				{
				theDist = Get_Distance_Score (theSpot,theSpotNextTime,intnsWght);
				if (theDist < minDist)
					{
					minDist = theDist;
					theSpot->nextTimePoint = theSpotNextTime;
					}
				theSpotNextTime = theSpotNextTime->next;
				} /* find nearest neighbor */

			if (theSpot->nextTimePoint != NULL)
				theSpot->nextTimePoint->trajID = theSpot->trajID;
			Calculate_Spot_Vector (theSpot);
			theSpot = theSpot->next;
			} /* This timepoint's list of spots */

		theSpotList = theSpotList->nextTimePointList;
		firstTimepoint = 0;
		}/* The list of time-point-lists */

/*
* Finally, we output the vectors.
* Output of spot info is handled by Write_Output
* If we are evaluating, i.e. outputing polygons for viewing in DV, output the header for
* the polygon file.
*/
	Write_Output (theSpotListHead,argc,argv,OUTARGS);
	if (evaluate)
		{
		Write_Polygon_File (polyOut,doVectors,theSpotListHead,tStart,tStop);
		fclose (polyOut);
		}

	
/*
* Exit gracefully.
*/	
	return (0);
}
