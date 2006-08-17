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
#include "omeis-http/httpOMEIS.h"


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
#define MAX_HIST_SIZE 4096
#define X_PLUS 1
#define X_MINUS 2
#define Y_PLUS 3
#define Y_MINUS 4
#define Z_PLUS 5
#define Z_MINUS 6

/* Pixel types */
#define PIX_T_FLOAT  1
#define PIX_T_UINT8  2
#define PIX_T_UINT16 3
#define PIX_T_UINT32 4
#define PIX_T_INT8   5
#define PIX_T_INT16  6
#define PIX_T_INT32  7

#define HEADING 1
#define VALUES 2
#define DATABASE_HEADING 3
#define DATABASE_VALUES 4

#define OUTARGS 6

#define PI 3.14159265358979323846264338327
#define SQUARE_ROOT_OF_2 1.4142135623731

#define MASK_THRESHOLD 128 /* pixels above (not equal) to threshold are spots */
#define MASK_PIXEL 0
#define SPOT_PIXEL 255
#define BORDER_PIXEL 1
#define PROCESSED_SPOT_PIXEL 3


/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################            DEFINITION OF VARIABLE TYPES            ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

typedef u_int8_t MaskPixel;
typedef MaskPixel *MaskPtr;
typedef void *PixPtr;
typedef unsigned long coordinate;




/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################              DEFINITION OF STRUCTURES              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/


typedef struct {
	coordinate x;
	coordinate y;
	coordinate z;
	coordinate w;
	coordinate t;
} Point5D;



/*#########################*/
/*#       PixStack        #*/
/*#########################*/
/*
* This structure will contain the whole image stack.  The actual image data (->stack) will be
* de-allocated after each time-point is processed.  This is unidirectional linked list.  The
* time-points are linked through ->next.
* Note that there are two very different kinds of stack in this program - the image stack
* as defined in this structure and the LIFO stack that is used for finding spots.
*/
typedef struct pix_stack {
	int nwaves;
	coordinate max_x,max_y,max_z;  /* This is the width, height, thickness, respectively */
	coordinate min_x,min_y,min_z;  /* These should be set to 0 */

	PixPtr *stacks; /*  An array of channels (wavelengths) each containing an XYZ set of pixels */

	/* things from libhttpOMEIS */
	OID       PixelsID;
	omeis     *is;    /* the omeis object returned by openConnectionOMEIS */
	pixHeader *ph;    /* the header object returned by pixelsInfo */
	pixStats **stats; /* the statistics returned by getStackStats */
	
	int pixType;  /* an enumeration of the various pixel types */

	double (*PixValueIdx)(void *theStack, size_t pix_indx);
	double (*PixValueCrd)(struct pix_stack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
/*
* The integration threshold + channel.
*/
	double threshold;

	coordinate spotWave;
	coordinate timepoint; /* this is the last timepoint read by ReadTimepoint */
	
/*
* These are pre-set to help us navigate through the stack using indexes.
*/
	size_t y_increment,z_increment,nPix;

/* an 8-bit XYZ mask of the spot pixels */
	MaskPtr mask;

/* The list of spots */
	struct spotStructure *spots;
/* The current timepoint's spotlist head. */
	struct spotStructure *currSpotList;
	size_t  nSpots;

	struct pix_stack* next;
} PixStack;









/*#########################*/
/*#   IndexStack          #*/
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
typedef struct IndexStackStructure {
	MaskPtr index[CHUNK_SIZE];
	struct IndexStackStructure *nextChunk;
	struct IndexStackStructure *prevChunk;
	long last; /* less than 0 if empty. */
} IndexStackStruct;
typedef IndexStackStruct *IndexStack;







/*
* This structure is a linked list of coordinates that is used to store boundary
* pixels.  The pixels are stored as X,Y,Z triplets.  The structure also has a next
* variable to point to the next set of coordinates.
*/
typedef struct CoordListStructure {
	coordinate X,Y,Z;
	char flag;
	struct CoordListStructure *next;
} CoordListStruct;
typedef CoordListStruct *CoordList;




/*#########################*/
/*#      SpotStats        #*/
/*#########################*/
/*
* One of these per spot per wavelength
*/
typedef struct
{

/* The spot has a different centroid at each wavelegth */
	double centroid_x;
	double centroid_y;
	double centroid_z;

/*
* This is the integral - sum of intensisties of the pixels that make up the spot.
* There is a value for each wavelegth.	Same for the rest of the intensity stats.
*/
	double sum_i;
	double sum_i2;
	double min_i;
	double max_i;
	double mean_i;
	double geomean_i;
	double sigma_i;
	double geosigma_i;

/*
* These accumulators are used to calculate the centroids.
*/
	double sum_xi;
	double sum_yi;
	double sum_zi;
} SpotStats;



/*#########################*/
/*#      Spot             #*/
/*#########################*/
/*
 * This is the structure that is used to store information about each
 * spot.  The list of spots is a circular double-linked list.  New spots are added
 * before the head of the list.
 */
typedef struct spotStructure {
	unsigned long ID;
	coordinate nwaves;
	coordinate itsWave;  /* this is the wave index for the wavelegth that this
						is a spot from */
	PixStack *itsStack;
/*
* This is an index to the timepoint this spot came from.  It is in the same format as would be passed to
* ReadTimepoint.	The first timepoint is 0.
*/
	coordinate itsTimePoint;	 

/*
* When looking for spots, these bounds are used to set the spot limits.	 They
* may be different from the bounds of the image stack.
*/
	coordinate clip_Xmin,clip_Ymin,clip_Zmin;
	coordinate clip_Xmax,clip_Ymax,clip_Zmax;

/*
* We copy the threshold from the stack, because it may be recalculated at each timepoint
*/
	double threshold;

/*
* The minimum and maximum coordinates form a "minimal box" around the spot.
* Since the box's sides lie along the X,Y,Z axes, it is not necessarily the
* smallest box - it is simply the range of the spot's X,Y,Z coordinates.
*/
	coordinate min_x,min_y,min_z;
	coordinate max_x,max_y,max_z;

/*
* The mean coordinates give the center of volume for the spot.
*/
	double mean_x,mean_y,mean_z;

/*
* These can be thought of as horizontal, vertical and Z-axis "dispersions" for the spot.
*/
	double sigma_x,sigma_y,sigma_z;


/* number of pixels that make up the spot */
	size_t volume;

/* per-wavelength stats */
	SpotStats *stats;

/*
* This is a pointer to the closest spot in the next timepoint.
* We have no way of knowing if this spot moved there or if its another
* spot that becomes the nearest neighbor.  Ideally its the same spot and this
* pointer points to its next position.
*/
	struct spotStructure *nextTimePoint;

/*
* These are the vectors to the "same" spot in the next timepoint.  They are
* expressed in pixel coordinates.
*/
	double vecX,vecY,vecZ;

/*
* These accumulators are used to calculate position information.
*/
	double sum_x, sum_y, sum_z;
	double sum_x2, sum_y2, sum_z2;

/*
* These values are used internally in the spot-finding algorithm to keep
* track of where we are.  They have no meaning outside of the algorithm.
*/
	coordinate cur_x,cur_y,cur_z;

/*
* this is a linked list of border pixels around the spot.
*/
	CoordList borderPixels;
	unsigned long borderCount;
	double perimeter;
	double formFactor;
	double surfaceArea;
	coordinate seedX;
	coordinate seedY;
	coordinate seedZ;

/*
* This is a circular double-linked list for ease of maneuverability (and obfuscation).
* New members are added to the head->previous. New memeber->next then
* points to the head, and new member->previous points to the old head->previous.
*/

	struct spotStructure *next;
	struct spotStructure *previous;

/*
* This pointer points to a list of spots in the next timepoint.
* This pointer is only valid at the head of a list of spots for a given timepoint. Otherwise
* its NULL.  Sure its not the best data structure organization.  So sue me.
*/
	struct spotStructure *nextTimePointList;
	struct spotStructure *itsHead; /* point to the head of the list for a given timepoint list */
} Spot;
typedef Spot *SpotPtr;

typedef struct  {
	unsigned long nRows,nCols;
	char ***cells; /* 2-D array of char *'s into the *table block */
	char *table; /* NULL-delimited cell values in a contiguous memory block. */
	unsigned long xCol,yCol,zCol,tCol;
} spotsTable;









/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################               DEFINITION OF FUNCTIONS              ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

PixStack* NewPixStack (const char *omeis_url, OID PixelsID);
coordinate ReadTimepoint (PixStack* theStack, coordinate theT);
void Push_Stack (MaskPtr maskIndex, IndexStack theStack);
MaskPtr Pop_Stack (IndexStack theStack);
void Eat_Spot_Rec (SpotPtr theSpot, MaskPtr maskIndex);
void Eat_Spot (SpotPtr theSpot, MaskPtr maskIndex);
void Index_To_Coords (PixStack* theStack, MaskPtr maskIndex,coordinate *X,coordinate *Y,coordinate *Z);
void Update_Spot (SpotPtr theSpot, MaskPtr maskIndex);
MaskPtr Coords_To_Index (PixStack* theStack, coordinate X,coordinate Y,coordinate Z);
void Get_Perimiter (SpotPtr theSpot);
void SwapListElements (CoordList previousElement1, CoordList previousElement2);
void Get_Surface_Area (SpotPtr theSpot);
double Get_Surface_Area_CC (char *c, int n);
MaskPtr Update_Index (SpotPtr theSpot, MaskPtr maskIndex, char direction);
void Set_Border_Pixel (SpotPtr theSpot, coordinate X, coordinate Y, coordinate Z);
SpotPtr New_Spot (PixStack *theStack, coordinate itsWave, coordinate itsTime);
void Zero_Spot (SpotPtr theSpot,PixStack *theStack, coordinate itsWave, coordinate itsTime);
void Finish_Spot_Stats (SpotPtr theSpot);
void Output_Spot (SpotPtr theSpot, int argc, char**argv,int outArgs, char saywhat);
void Write_Output (SpotPtr theSpotList,int argc, char**argv,int outArgs);
void SetSpots2SpotsDist (spotsTable *theSpotsTable, SpotPtr theSpotListHead);
void Write_Spots2spots (spotsTable *theSpotsTable);
int getArg (int argc, char **argv, const char *arg);
spotsTable *readSpotsTable (const char *spotsListFilename,int argc, char**argv);



double Set_Threshold (const char *arg, PixStack *theStack);
double *Get_Prob_Hist (PixStack *theStack, unsigned short *histSizePtr);
double Get_Thresh_Moment (PixStack *theStack);
double Get_Thresh_Otsu (PixStack *theStack);
double Get_Thresh_ME (PixStack *theStack);
double Get_Thresh_Kittler (PixStack *theStack);

double PixValueIdx_u_int8 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_u_int16 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_u_int32 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_int8 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_int16 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_int32 (PixPtr theStack, size_t pix_indx);
double PixValueIdx_float (PixPtr theStack, size_t pix_indx);
double PixValueCrd_u_int8 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_u_int16 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_u_int32 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_int8 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_int16 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_int32 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);
double PixValueCrd_float (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC);



void usage(char **argv);




/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                       FUNCTIONS                    ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/



/*#########################*/
/*#                       #*/
/*#     NewPixStack       #*/
/*#                       #*/
/*#########################*/
/*
 * The following routine allocates a new PixStack,
 * and fills in its values by calling httpOMEIS.
 * It also allocates room for a mask that will be used for thresholding
*/

PixStack* NewPixStack (const char *omeis_url, OID PixelsID)
{
	PixStack* theStack;
	coordinate nwaves;
	pixHeader *ph;    /* the header object returned by pixelsInfo */

	theStack = calloc (1,sizeof(PixStack));
	if (theStack == NULL) {
		fprintf (stderr,"Could not retreive information for PixelsID=%llu\n",(unsigned long long)PixelsID);
		return NULL;
	}
	
	theStack->PixelsID = PixelsID;
#ifdef DEBUG
fprintf (stderr,"opening connection to %s\n",omeis_url);
fflush (stderr);
#endif

	theStack->is = openConnectionOMEIS(omeis_url, "0000");
#ifdef DEBUG
if (theStack->is) fprintf (stderr,"opened connection to %s\n",omeis_url);
else fprintf (stderr,"failed to open connection to %s\n",omeis_url);
fflush (stderr);
#endif
	theStack->ph = pixelsInfo (theStack->is, PixelsID);
	theStack->stats = getStackStats (theStack->is, PixelsID);

	if (theStack->is == NULL || theStack->ph == NULL || theStack->stats == NULL) {
		if (theStack->is != NULL) free (theStack->is);
		if (theStack->ph != NULL) free (theStack->ph);
		if (theStack->stats != NULL) freeStackStats (theStack->stats);
		free (theStack);
		fprintf (stderr,"Could not retreive information for PixelsID=%llu\n",(unsigned long long)PixelsID);
		return NULL;
	}

	ph = theStack->ph;

	nwaves = theStack->nwaves = ph->dc;
	theStack->max_x = ph->dx - 1;
	theStack->max_y = ph->dy - 1;
	theStack->max_z = ph->dz - 1;
	theStack->y_increment = ph->dx;
	theStack->z_increment = ph->dx * ph->dy;
	theStack->nPix = ph->dx * ph->dy * ph->dz;
	theStack->stacks = NULL;

	if (ph->isFloat) {
		theStack->pixType = PIX_T_FLOAT;
		theStack->PixValueIdx = PixValueIdx_float;
		theStack->PixValueCrd = PixValueCrd_float;
	} else if (ph->isSigned && ph->bp == 1 ) {
		theStack->pixType = PIX_T_INT8;
		theStack->PixValueIdx = PixValueIdx_int8;
		theStack->PixValueCrd = PixValueCrd_int8;
	} else if (ph->isSigned && ph->bp == 2 ) {
		theStack->pixType = PIX_T_INT16;
		theStack->PixValueIdx = PixValueIdx_int16;
		theStack->PixValueCrd = PixValueCrd_int16;
	} else if (ph->isSigned && ph->bp == 4 ) {
		theStack->pixType = PIX_T_INT32;
		theStack->PixValueIdx = PixValueIdx_int32;
		theStack->PixValueCrd = PixValueCrd_int32;
	} else if (!ph->isSigned && ph->bp == 1 ) {
		theStack->pixType = PIX_T_UINT8;
		theStack->PixValueIdx = PixValueIdx_u_int8;
		theStack->PixValueCrd = PixValueCrd_u_int8;
	} else if (!ph->isSigned && ph->bp == 2 ) {
		theStack->pixType = PIX_T_UINT16;
		theStack->PixValueIdx = PixValueIdx_u_int16;
		theStack->PixValueCrd = PixValueCrd_u_int16;
	} else if (!ph->isSigned && ph->bp == 4 ) {
		theStack->pixType = PIX_T_UINT32;
		theStack->PixValueIdx = PixValueIdx_u_int32;
		theStack->PixValueCrd = PixValueCrd_u_int32;
	}
	
	/*
	* Allocate memory for the array of pointers to the XYZ stacks
	* xyzPixels = theStack->stacks[theC]
	*/
	if ( (theStack->stacks = (PixPtr *) calloc (nwaves, sizeof(PixPtr *))) == NULL) {
		fprintf (stderr,"Could not allocate memory while initializing PixelsID=%llu\n",(unsigned long long)PixelsID);
		free (theStack->is);
		freeStackStats (theStack->stats);
		free (theStack);
	}

	/*
	* Allocate memory for an 8-bit mask
	*/
	if ( (theStack->mask = (MaskPtr) calloc (theStack->nPix,sizeof(MaskPixel))) == NULL) {
		fprintf (stderr,"Could not allocate memory while initializing PixelsID=%llu\n",(unsigned long long)PixelsID);
		free (theStack->stacks);
		free (theStack->is);
		freeStackStats (theStack->stats);
		free (theStack);
	}
	
	/*
	* The list of spots
	*/
	theStack->spots = NULL;
	theStack->nSpots = 0;
	return (theStack);
}




/*#########################*/
/*#                       #*/
/*#     ReadTimepoint     #*/
/*#                       #*/
/*#########################*/
/*
 * The following routines read one timepoint into the provided PixStack.
*/

coordinate ReadTimepoint (PixStack* theStack, coordinate theT)
{
coordinate theC, nwaves, j;

	nwaves = theStack->nwaves;
	for (theC=0;theC<nwaves;theC++) {
		if (theStack->stacks[theC] != NULL) free (theStack->stacks[theC]);
		theStack->stacks[theC] = getStack (theStack->is,theStack->PixelsID,theC,theT);
		if (theStack->stacks[theC] == NULL) {
			for (j=0;j<theC;j++) {
				free (theStack->stacks[j]);
				theStack->stacks[j] = NULL;
				return 0;
			}
		}
	}
	theStack->timepoint = theT;
	return nwaves;

}




/*######################################*/
/*#                                    #*/
/*#     MakeThresholdMask_lightSpots   #*/
/*#     MakeThresholdMask_darkSpots    #*/
/*#                                    #*/
/*######################################*/
/* This sets the stack's pre-allocated mask using the 
 * stack's global threshold.
*/
void MakeThresholdMask_lightSpots (PixStack* theStack) {
coordinate theC;
double threshold;
MaskPtr maskPtr, lastMaskPtr;
size_t nPix;

u_int8_t *u_int8_p;
u_int16_t *u_int16_p;
u_int32_t *u_int32_p;
int8_t *int8_p;
int16_t *int16_p;
int32_t *int32_p;
float *float_p;
	
	theC = theStack->spotWave;
	threshold = theStack->threshold;
	
	maskPtr = theStack->mask;
	nPix = theStack->nPix;
	lastMaskPtr = maskPtr + nPix;
	
	switch (theStack->pixType) {
		case PIX_T_FLOAT:
			float_p = (float *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*float_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT8:
			u_int8_p = (u_int8_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int8_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT16:
			u_int16_p = (u_int16_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int16_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT32:
			u_int32_p = (u_int32_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int32_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT8:
			int8_p = (int8_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int8_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT16:
			int16_p = (int16_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int16_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT32:
			int32_p = (int32_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int32_p++ > threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		default:
		break;
	}

	
}

void MakeThresholdMask_darkSpots (PixStack* theStack) {
coordinate theC;
double threshold;
MaskPtr maskPtr, lastMaskPtr;
size_t nPix;

u_int8_t *u_int8_p;
u_int16_t *u_int16_p;
u_int32_t *u_int32_p;
int8_t *int8_p;
int16_t *int16_p;
int32_t *int32_p;
float *float_p;
	
	theC = theStack->spotWave;
	threshold = theStack->threshold;
	
	maskPtr = theStack->mask;
	nPix = theStack->nPix;
	lastMaskPtr = maskPtr + nPix;
	
	switch (theStack->pixType) {
		case PIX_T_FLOAT:
			float_p = (float *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*float_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT8:
			u_int8_p = (u_int8_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int8_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT16:
			u_int16_p = (u_int16_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int16_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_UINT32:
			u_int32_p = (u_int32_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*u_int32_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT8:
			int8_p = (int8_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int8_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT16:
			int16_p = (int16_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int16_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		case PIX_T_INT32:
			int32_p = (int32_t *) (theStack->stacks[theC]);
			while (maskPtr < lastMaskPtr) {
				if (*int32_p++ <= threshold) *maskPtr++ = SPOT_PIXEL;
				else *maskPtr++ = MASK_PIXEL;
			}
		break;
		default:
		break;
	}

	
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
void Push_Stack (MaskPtr maskIndex, IndexStack theStack)
{
IndexStack lastChunk;

/*
* Determine if we are at a border pixel.  There are two kinds of border pixels.  We treat them
* the same, but they have slightly different meanings. If a spot bleeds over the edge of the image,
* then the border of the image determines one of the spot borders.  In this case a border pixel
* will actually be a spot pixel.  If the index was set to NULL by Update_Index we are at the
* spot border as determioned by the image border.
* Otherwise, the border pixels are the ones just outside the spot, and *maskIndex will be
* less than threshold.  This kind of border pixels is not a spot pixel.
* Either way, we set a border pixel and return.
*/
	if ( maskIndex == NULL )
		return;
	if (*maskIndex <= MASK_THRESHOLD)
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
	lastChunk->index[lastChunk->last] = maskIndex;
	
}










/*#########################*/
/*#                       #*/
/*#         Pop_Stack     #*/
/*#                       #*/
/*#########################*/
/*
* This function returns the last index in the LIFO stack.  It deallocates memory if
* returning the last index in a chunk.	It won't free the very last chunk in the stack - the
* one pointed to by theStack.
*/
MaskPtr Pop_Stack (IndexStack theStack)
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
* Finally, return the last index in the stack.
*/
	return (theIndex);
}










/*#########################*/
/*#                       #*/
/*#         Eat_Spot      #*/
/*#                       #*/
/*#########################*/
void Eat_Spot (SpotPtr theSpot, MaskPtr maskIndex)
{
static IndexStack theLIFOstack;
PixStack *theStack;

/*
* If there is no LIFO, then make one.
*/
	if (theLIFOstack == NULL)
		{
		theLIFOstack = (IndexStack) malloc (sizeof(IndexStackStruct));
		if (theLIFOstack == NULL)
			{
			fprintf (stderr,"FATAL ERROR: Could not allocate memory for pixel indexes.\n");
			exit (-1);
			}
		theLIFOstack->nextChunk = theLIFOstack;
		theLIFOstack->prevChunk = theLIFOstack;
		theLIFOstack->last = -1;
		}


	theStack = theSpot->itsStack;
	
	Index_To_Coords (theStack, maskIndex,&(theSpot->seedX),&(theSpot->seedY),&(theSpot->seedZ) );
/*
* We update the spot's statistics based on the properties of this pixel (position, intensity, etc).
* This is the seed pixel.
*/
	Update_Spot (theSpot, maskIndex);

/*
* We set this pixel to PROCESSED_SPOT_PIXEL so that we don't count it again.
*/
	*maskIndex = PROCESSED_SPOT_PIXEL;
	
/*
* We push the indexes of the pixels in all six directions onto the stack.  Update_Index returns a new index
* based on the specified direction.  It will return NULL if the specified directions causes an index that's
* out of bounds.  The index gets passed to Push_Stack, which checks if the pixel pointed to by index is above
* threshold.  If so, it gets pushed on the stack.  At most, we would have pushed the six pixels that surround
* the seed pixel.
*/
	Push_Stack (Update_Index(theSpot,maskIndex,X_PLUS),theLIFOstack);
	Push_Stack (Update_Index(theSpot,maskIndex,X_MINUS),theLIFOstack);
	Push_Stack (Update_Index(theSpot,maskIndex,Y_PLUS),theLIFOstack);
	Push_Stack (Update_Index(theSpot,maskIndex,Y_MINUS),theLIFOstack);
	if (theSpot->clip_Zmax-theSpot->clip_Zmin)
	{
		Push_Stack (Update_Index(theSpot,maskIndex,Z_PLUS),theLIFOstack);
		Push_Stack (Update_Index(theSpot,maskIndex,Z_MINUS),theLIFOstack);
	}
/*
* We've processed the seed pixel, so now its time to pop the first pixel from the stack.
*/
	maskIndex = Pop_Stack (theLIFOstack);
	
/*
* This is where the action is.  The maskIndex supplied by Pop_Stack will be NULL when the stack is empty.
*/
	while (maskIndex != NULL)
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
		if (*maskIndex > MASK_THRESHOLD)
		{
			
		/*
		* If we found a valid pixel, then basically do the same thing we did before.
		*/
			Update_Spot (theSpot, maskIndex);
			*maskIndex = PROCESSED_SPOT_PIXEL;
			Push_Stack (Update_Index(theSpot,maskIndex,X_PLUS),theLIFOstack);
			Push_Stack (Update_Index(theSpot,maskIndex,X_MINUS),theLIFOstack);
			Push_Stack (Update_Index(theSpot,maskIndex,Y_PLUS),theLIFOstack);
			Push_Stack (Update_Index(theSpot,maskIndex,Y_MINUS),theLIFOstack);
			if (theSpot->clip_Zmax-theSpot->clip_Zmin)
			{
				Push_Stack (Update_Index(theSpot,maskIndex,Z_PLUS),theLIFOstack);
				Push_Stack (Update_Index(theSpot,maskIndex,Z_MINUS),theLIFOstack);
			}
		}

		/*
		* pop another pixel off the stack and begin again.
		*/
		maskIndex = Pop_Stack (theLIFOstack);
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
void Eat_Spot_Rec (SpotPtr theSpot, MaskPtr maskIndex)
{
/*
extern pixel thresholdG;
*/

/*
* Update_Index returns NULL if we try to go out of bounds (theSpot->clip),
* so we should check for that first, and return immediately.
*/
	if (maskIndex == NULL) return;

/*
* Also, we want to return if the index is pointing to a pixel less than or
* equal to threshold.
*/
	if (*maskIndex <= MASK_THRESHOLD) return;

/*
* At this point index is pointing at a spot pixel, so we call Update_Spot
* to update the spot statistics with this pixel.
*/
	Update_Spot (theSpot, maskIndex);

/*
* To prevent re-considering this pixel, we set it to threshold.
*/
	*maskIndex = PROCESSED_SPOT_PIXEL;

/*
* For each of the six directions, we call Update_Index with a direction, which returns
* a new index which we immediately pass recursively to Eat_Spot.
*/
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,X_PLUS));
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,X_MINUS));
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,Y_PLUS));
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,Y_MINUS));
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,Z_PLUS));
	Eat_Spot_Rec (theSpot, Update_Index(theSpot, maskIndex,Z_MINUS));
	return;
}





void Index_To_Coords (PixStack* theStack, MaskPtr maskIndex,coordinate *Xp,coordinate *Yp,coordinate *Zp)
{
size_t maskIndex2;
coordinate X,Y,Z;

/*
* First,  subtract the stack pointer from index,  thus getting
* a "true" index.
*/
	maskIndex2 = maskIndex - theStack->mask;

/*
* The z coordinate is the wave index divided by the size of a z-section.
* The integer division is a truncation.
*/
	Z = maskIndex2 / (theStack->z_increment);

/*
* Then we subtract the z coordinate * section size to get an index into the section.
*/
	maskIndex2 -= (Z * (theStack->z_increment));

/*
* The y coordinate is the index divided by the width.
*/
	Y = maskIndex2 / (theStack->y_increment);

/*
* Lastly,	if we subtract the y coordinate * width from the index,	 we will be left
* with the x coordinate.
*/
	maskIndex2 -= (Y * (theStack->y_increment));
	X = maskIndex2;

	*Xp = X;
	*Yp = Y;
	*Zp = Z;
/*
* It is important to note that these coordinates are based on the origin being (0,0,0) not (1,1,1).
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
void Update_Spot (SpotPtr theSpot, MaskPtr maskIndex)
{
coordinate theC;
double pixVal;
size_t pixIndx;
double (*GetPixValueIdx)(void *theStack, size_t pixelIndex);
SpotStats *theSpotCstats;


/*
* We need to back-calculate the coordinates from the index.
*/
	Index_To_Coords (theSpot->itsStack, maskIndex, &(theSpot->cur_x),&(theSpot->cur_y),&(theSpot->cur_z));
	pixIndx = maskIndex - theSpot->itsStack->mask;

/*
* Set spoot coordinate maxima and minima according to the
* current coordinates.
*/
	if (theSpot->cur_x > theSpot->max_x)
		theSpot->max_x = theSpot->cur_x;
	if (theSpot->cur_x < theSpot->min_x)
		theSpot->min_x = theSpot->cur_x;
	if (theSpot->cur_y > theSpot->max_y)
		theSpot->max_y = theSpot->cur_y;
	if (theSpot->cur_y < theSpot->min_y)
		theSpot->min_y = theSpot->cur_y;
	if (theSpot->cur_z > theSpot->max_z)
		theSpot->max_z = theSpot->cur_z;
	if (theSpot->cur_z < theSpot->min_z)
		theSpot->min_z = theSpot->cur_z;

/*
* Increment the volume counter.
*/
	theSpot->volume++;

/*
* update the coordinate accumulators and the coordinate sum of squares accumulators.
*/
	theSpot->sum_x += theSpot->cur_x;
	theSpot->sum_y += theSpot->cur_y;
	theSpot->sum_z += theSpot->cur_z;
	theSpot->sum_x2 += ((float)theSpot->cur_x * (float)theSpot->cur_x);
	theSpot->sum_y2 += ((float)theSpot->cur_y * (float)theSpot->cur_y);
	theSpot->sum_z2 += ((float)theSpot->cur_z * (float)theSpot->cur_z);

/*
* Then we do a bunch of things once for each wave.
*/
	GetPixValueIdx = theSpot->itsStack->PixValueIdx;
	for (theC=0;theC<theSpot->nwaves;theC++)
	{
		pixVal = GetPixValueIdx (theSpot->itsStack->stacks[theC],pixIndx);
		theSpotCstats = &(theSpot->stats[theC]);
	/*
	* Update the wave-specific accumulators, minima, maxima, etc.
	*/
		if (pixVal < theSpotCstats->min_i)
			theSpotCstats->min_i = pixVal;
		if (pixVal > theSpotCstats->max_i)
			theSpotCstats->max_i = pixVal;
		theSpotCstats->sum_i += pixVal;
		theSpotCstats->sum_i2 += (pixVal * pixVal);
		theSpotCstats->sum_xi += pixVal * theSpot->cur_x;
		theSpotCstats->sum_yi += pixVal * theSpot->cur_y;
		theSpotCstats->sum_zi += pixVal * theSpot->cur_z;
		theSpotCstats->geomean_i += log ( pixVal );
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
MaskPtr Update_Index (SpotPtr theSpot, MaskPtr maskIndex, char direction)
{
/*
extern SpotPtr theSpot;
extern PixStack *theStack;
*/

/*
* Initially, we set a pointer to NULL.	If we are in bounds, then it will
* be set to a valid pointer.  Otherwise, we'll return with NULL.
*/
MaskPtr theIndex = NULL;
char doBorder=0;
coordinate X,Y,Z;

	X = theSpot->cur_x;
	Y = theSpot->cur_y;
	Z = theSpot->cur_z;
/*
* Return NULL if we are on the border.
*/
	switch (direction)
	{
	case X_PLUS:
		if (X < theSpot->clip_Xmax)
			theIndex = maskIndex + 1;
		else if (X == theSpot->clip_Xmax)
			doBorder = 1;
	break;
	case X_MINUS:
		if (X > theSpot->clip_Xmin)
			theIndex = maskIndex - 1;
		else if (X == theSpot->clip_Xmin)
			doBorder = 1;
	break;

	case Y_PLUS:
		if (Y < theSpot->clip_Ymax)
			theIndex = maskIndex + theSpot->itsStack->y_increment;
		else if (Y == theSpot->clip_Ymax)
			doBorder = 1;
	break;
	case Y_MINUS:
		if (Y > theSpot->clip_Ymin)
			theIndex = maskIndex - theSpot->itsStack->y_increment;
		else if (Y == theSpot->clip_Ymin)
			doBorder = 1;
	break;

	case Z_PLUS:
		if (Z < theSpot->clip_Zmax)
			theIndex = maskIndex + theSpot->itsStack->z_increment;
		else if (Z == theSpot->clip_Zmax)
			doBorder = 1;
	break;
	case Z_MINUS:
		if (Z > theSpot->clip_Zmin)
			theIndex = maskIndex - theSpot->itsStack->z_increment;
		else if (Z == theSpot->clip_Zmin)
			doBorder = 1;
	break;
	}  /* switch (direction */

	/* if this is NULL, then we went out of bounds. */
	if (theIndex != NULL) {
		/* If we landed on a mask pixel, then we are currently on a border pixel */
		if (*theIndex == MASK_PIXEL) doBorder = 1;
		/* If we didn't land on a MASK_PIXEL or SPOT_PIXEL, then we already visited here */
		else if (*theIndex != SPOT_PIXEL) theIndex = NULL;
	}
	
	if (theIndex != NULL && doBorder)
		Set_Border_Pixel (theSpot, X,Y,Z);

	return (theIndex);
}


MaskPtr Coords_To_Index (PixStack* theStack, coordinate X,coordinate Y,coordinate Z)
{
MaskPtr maskIndex;

	maskIndex = theStack->mask;
	maskIndex += (Z * (theStack->z_increment));
	maskIndex += (Y * (theStack->y_increment));
	maskIndex += X;
	return (maskIndex);

}





void Set_Border_Pixel (SpotPtr theSpot, coordinate X, coordinate Y, coordinate Z)
{
CoordList newPixel;

/*
* allocate memory for the border pixel.
*/
	newPixel = (CoordList) calloc (1,sizeof(CoordListStruct));
	if (newPixel == NULL)
		{
		fprintf (stderr,"Could not allocate memory to store spot border pixels.\n");
		fprintf (stderr,"No border pixels will be reported.\n");
		return;
		}
	newPixel->X = X;
	newPixel->Y = Y;
	newPixel->Z = Z;
	newPixel->flag = 0;
	newPixel->next = theSpot->borderPixels;
	theSpot->borderPixels = newPixel;
	theSpot->borderCount++;

/*
* calculate the ammount of surface area this border pixel has exposed
* The exposed surface area is incremented for each neighboring pixel == MASK_PIXEL
* This models surface area as a membrane stretched very tightly around the spot, tracing
* the contour of every pixel.  This is probably not correct.  A 1-pixel spot would
* have a surface area of 6.  If modeled as a sphere, it would have a SA of pi (~3).
* a 3x3x3 pixel spot would have an SA of 54 when modeled as a cube, and an SA of 28.3
* if modeled as a sphere.  Modeling SA by contouring pixels leads to an artificially high SA
* because spots tend to have rough edges due to noise.
* As a simple approximation, a 3x3x3 pixel spot has 26 permiter pixels, which is close to the sphere model.
* This approximation improves as the spots get larger.
* Since in these types of images (fluorescence microscopy) we are generally interested in SA/volume ratio as an
* indicator of shape rather than artificially high SAs due to roughness of the contour (where the roughness is caused by
* noise rather than biological effects), we're reporting the number of perimeter pixels as an approximation of a "smoothed" SA.
	maskPixel = Coords_To_Index (theSpot->itsStack, X, Y, Z);
	y_incr = theSpot->itsStack->y_increment;
	z_incr = theSpot->itsStack->z_increment;


	if (X == theSpot->clip_Xmax) sa++;
	else if (*(maskPixel+1) == MASK_PIXEL) sa++;
	if (X == theSpot->clip_Xmin) sa++;
	else if (*(maskPixel-1) == MASK_PIXEL) sa++;

	if (Y == theSpot->clip_Ymax) sa++;
	else if (*(maskPixel+y_incr) == MASK_PIXEL) sa++;
	if (Y == theSpot->clip_Ymin) sa++;
	else if (*(maskPixel-y_incr) == MASK_PIXEL) sa++;

	if (Z == theSpot->clip_Zmax) sa++;
	else if (*(maskPixel+z_incr) == MASK_PIXEL) sa++;
	if (Z == theSpot->clip_Zmin) sa++;
	else if (*(maskPixel-z_incr) == MASK_PIXEL) sa++;


*/

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
SpotPtr New_Spot (PixStack *theStack, coordinate itsWave, coordinate itsTime)
{
SpotPtr newSpot=NULL;
static unsigned long ID=0;

SpotPtr spotList,currSpotList;

/*
* Allocate memory for the spot and stats array.
*/
	newSpot = (SpotPtr) calloc (1,sizeof(struct spotStructure));
	if (newSpot == NULL)
		return (NULL);
	if ( (newSpot->stats = calloc (theStack->nwaves, sizeof(SpotStats))) == NULL ) {
		free (newSpot);
		return (NULL);
	}

/*
* If theStack->spots is NULL, then this is the first spot in the list, 
* so the new spot's previous and next pointers point to itself.
* If theStack->spots is not NULL, then we have to add this spot to the list.  It will be added
* just before the head of the list - or, since this is a circular list, at the end.
* The spot list grows as an expanding circle, which can be traveled in either direction.
* Kind of exotic, no?
*/
	spotList = theStack->spots;
	currSpotList = theStack->currSpotList;
	if (currSpotList != NULL && itsTime == currSpotList->itsTimePoint)
		{
	/*
	* newSpot's previous points to what the currSpotList's previous used to point to.
	* newSpot's next points to the currSpotList.
	* the currSpotList's previous points to the newSpot,
	* The spot that used to be before currSpotList now has its next pointing to newSpot.
	* Got that?
	*/
		newSpot->ID = ID++;
		newSpot->previous = currSpotList->previous;
		newSpot->next = currSpotList;
		currSpotList->previous->next = newSpot;
		currSpotList->previous = newSpot;
		newSpot->nextTimePointList = NULL;
	}
	/* New spot list */
	else {
		newSpot->ID = ID++;
		newSpot->previous = newSpot;
		newSpot->next = newSpot;
		newSpot->nextTimePointList = NULL;
		if (currSpotList == NULL) {
		/* this is the first spot in the first timepoint */
			spotList = theStack->spots = newSpot;
		} else {
		/* this is a new timepoint list */
			currSpotList->nextTimePointList = newSpot;
		}
		currSpotList = theStack->currSpotList = newSpot;
	}
	newSpot->itsStack = theStack;
	newSpot->itsHead = currSpotList;

/*	
* Zero-out the accumulators, etc.
*/
	newSpot->borderPixels = NULL;

	Zero_Spot (newSpot, theStack, itsWave, itsTime);
	
	return (newSpot);
}










/*#########################*/
/*#                       #*/
/*#       Zero_Spot       #*/
/*#                       #*/
/*#########################*/
void Zero_Spot (SpotPtr theSpot,PixStack *theStack, coordinate itsWave, coordinate itsTime)
{
coordinate theC;
CoordList borderPixel;


	theSpot->itsStack = theStack;
	theSpot->nwaves = theStack->nwaves;
	theSpot->threshold = theStack->threshold;
	theSpot->itsWave = itsWave;
	theSpot->itsTimePoint = itsTime;
	theSpot->clip_Xmin = theStack->min_x;
	theSpot->clip_Xmax = theStack->max_x;
	theSpot->clip_Ymin = theStack->min_y;
	theSpot->clip_Ymax = theStack->max_y;
	theSpot->clip_Zmin = theStack->min_z;
	theSpot->clip_Zmax = theStack->max_z;

/*
* Note that these are set backwards !
*/
	theSpot->min_x = theStack->max_x;
	theSpot->max_x = theStack->min_x;
	theSpot->min_y = theStack->max_y;
	theSpot->max_y = theStack->min_y;
	theSpot->min_z = theStack->max_z;
	theSpot->max_z = theStack->min_z;

	theSpot->mean_x = theSpot->mean_y = theSpot->mean_z = 0;
	theSpot->sigma_x = theSpot->sigma_y = theSpot->sigma_z = 0;

/*
* A spot cannot have a volume of zero if its valid, so this is a convenient variable to check
* that we have a valid spot (not a place-holder).
*/
	theSpot->volume = 0;

	theSpot->sum_x = theSpot->sum_y = theSpot->sum_z = 0;
	theSpot->sum_x2 = theSpot->sum_y2 = theSpot->sum_z2 = 0;
	theSpot->cur_x = theSpot->cur_y = theSpot->cur_z = 0;

	for (theC=0;theC<theStack->nwaves;theC++)
		{
		theSpot->stats[theC].centroid_x = 0;
		theSpot->stats[theC].centroid_y = 0;
		theSpot->stats[theC].centroid_z = 0;
		theSpot->stats[theC].sum_i = 0;
		theSpot->stats[theC].sum_i2 = 0;
		theSpot->stats[theC].min_i = BIGFLOAT;
		theSpot->stats[theC].max_i = 0;
		theSpot->stats[theC].mean_i = 0;
		theSpot->stats[theC].geomean_i = 0;
		theSpot->stats[theC].sigma_i = 0;
		theSpot->stats[theC].sum_xi = 0;
		theSpot->stats[theC].sum_yi = 0;
		theSpot->stats[theC].sum_zi = 0;
		theSpot->stats[theC].geosigma_i = 0;
		}
	
	while (theSpot->borderPixels != NULL)
	{
		borderPixel = theSpot->borderPixels;
		theSpot->borderPixels = theSpot->borderPixels->next;
		free (borderPixel);
	}
	theSpot->borderCount = 0;
	theSpot->seedX=0;
	theSpot->seedY=0;
	theSpot->seedZ=0;
	
	
}










/*#########################*/
/*#                       #*/
/*#   Finish_Spot_Stats   #*/
/*#                       #*/
/*#########################*/
/*
* This routine gets called after the accumulators are filled - i.e. after the whole
* spot has been "eaten" in order to calculate some final statistics.
*/
void Finish_Spot_Stats (SpotPtr theSpot)
{
coordinate theC;
float spotVol;
CoordList borderPixel,previousPixel;
MaskPtr maskPtr;
float geomean;
SpotStats *theSpotStats;

	spotVol = (float) theSpot->volume;
	theSpot->mean_x = theSpot->sum_x / spotVol;
	theSpot->mean_y = theSpot->sum_y / spotVol;
	theSpot->mean_z = theSpot->sum_z / spotVol;
	theSpot->sigma_x = sqrt ((theSpot->sum_x2-(theSpot->sum_x*theSpot->sum_x)/spotVol)/(spotVol-1.0));
	theSpot->sigma_y = sqrt ((theSpot->sum_y2-(theSpot->sum_y*theSpot->sum_y)/spotVol)/(spotVol-1.0));
	theSpot->sigma_z = sqrt ((theSpot->sum_z2-(theSpot->sum_z*theSpot->sum_z)/spotVol)/(spotVol-1.0));

	for (theC=0;theC<theSpot->nwaves;theC++)
	{
		theSpotStats = &(theSpot->stats[theC]);
		theSpotStats->centroid_x = theSpotStats->sum_xi / theSpotStats->sum_i;
		theSpotStats->centroid_y = theSpotStats->sum_yi / theSpotStats->sum_i;
		theSpotStats->centroid_z = theSpotStats->sum_zi / theSpotStats->sum_i;
		theSpotStats->sigma_i = sqrt ((theSpotStats->sum_i2-(theSpotStats->sum_i*theSpotStats->sum_i)/spotVol)/(spotVol-1.0)); 
		theSpotStats->mean_i = theSpotStats->sum_i / spotVol;
		geomean= exp (theSpotStats->geomean_i / spotVol );
		/* theSpotStats->geomean_i = exp (theSpotStats->geomean_i / spotVol ); */
		
		theSpotStats->geomean_i = geomean;
		theSpotStats->geosigma_i =sqrt( (theSpotStats->sum_i2-2* geomean *theSpotStats->sum_i+geomean * geomean)/(spotVol-1.0));
	

	}
	
/*
* Set border pixels to the border pixel value
*/
	maskPtr = theSpot->itsStack->mask;
	borderPixel = theSpot->borderPixels;
	previousPixel = borderPixel;
	while (borderPixel)
	{
		maskPtr = Coords_To_Index (theSpot->itsStack,borderPixel->X,borderPixel->Y,borderPixel->Z);
		if (*maskPtr == PROCESSED_SPOT_PIXEL)
			*maskPtr = BORDER_PIXEL;
		else {
/*
#ifdef DEBUG
fprintf (stderr,"Deleting Spot #%ld (%d,%d,%d) = %d\n",theSpot->ID,borderPixel->X,borderPixel->Y,borderPixel->Z,*maskPtr);
fflush (stderr);
#endif
*/
			previousPixel->next = borderPixel->next;
			free (borderPixel);
			borderPixel = previousPixel;
			theSpot->borderCount--;
		}
		previousPixel = borderPixel;
		if (borderPixel)
			borderPixel = borderPixel->next;
	}
/*
* calculate stuff from the border pixels.
*/
	if (theSpot->clip_Zmax - theSpot->clip_Zmin)
		Get_Surface_Area (theSpot);
	else
		Get_Perimiter (theSpot);
}



/*	Compute the chain code of the object beginning at pixel (i,j).
	Return the code as NN integers in the array c.
*/
void chain8 (SpotPtr theSpot, char *c, short i, short j, int *nn)
{
	int val,n,m,q,r, di[9],dj[9],ii, d, dii;
	int lastdir, jj;
	int xMin,xMax,yMin,yMax,nMax;
	int x,y;
	MaskPtr data;

	xMin = theSpot->itsStack->min_x;
	xMax = theSpot->itsStack->max_x;
	yMin = theSpot->itsStack->min_y;
	yMax = theSpot->itsStack->max_y;
	data = theSpot->itsStack->mask;

/*	Table given index offset for each of the 8 directions.		*/
	di[0] = 0;	di[1] = -1;	di[2] = -1;	di[3] = -1;
	dj[0] = 1;	dj[1] = 1;	dj[2] = 0;	dj[3] = -1;
	di[4] = 0;	di[5] = 1;	di[6] = 1;	di[7] = 1;
	dj[4] = -1;	dj[5] = -1;	dj[6] = 0;	dj[7] = 1;

	nMax = *nn;
	for (ii=0; ii<nMax; ii++) c[ii] = -1;	/* Clear the code table */
	data = Coords_To_Index (theSpot->itsStack,i,j,0);
	val = *data;	n = 0;	/* Initialize for starting pixel */
	q = i;	r = j;  lastdir = 4;

	do {
		m = 0;
		dii = -1;	d = 100;
		for (ii=lastdir+1; ii<lastdir+8; ii++) {	/* Look for next */
			jj = ii%8;
			x = di[jj]+q;
			y = dj[jj]+r;
			data = Coords_To_Index (theSpot->itsStack,x,y,0);
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
		fprintf (stderr,"WARNING: Failed to achieve closure in Spot %lu!\n",theSpot->ID);
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
double perimeter=0.0;
char *chainCode;

	nCodes = theSpot->borderCount;
	chainCode = (char *) malloc (sizeof (char) * nCodes);
	if (!chainCode)
	{
	fprintf (stderr,"Could not allocate memory for chain code\n");
	exit (-1);
	}
	
	chain8 (theSpot, chainCode, theSpot->seedX, theSpot->seedY, &nCodes);

	perimeter = 0.0;
	for (i=0; i<nCodes; i++)
	   if (chainCode[i]%2) perimeter += SQUARE_ROOT_OF_2;
	   else perimeter += 1.0;


	theSpot->surfaceArea = Get_Surface_Area_CC (chainCode,nCodes);

	free (chainCode);

	theSpot->perimeter = perimeter;
	theSpot->formFactor = (4.0*PI*theSpot->surfaceArea) / (perimeter*perimeter);
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
* FIXME:  Total hack of computing surface area by using the number of perimeter pixels.  Makes
* no account of anisotropic space, but otherwise a decent approximation if all the dimensions are 1.
* Hmm, I wonder since the volume is in the
* same anisotropic space wether things will conveniently take care of themselves....probably not.
* At any rate, it will work for the form factor if not for the actual surface area.
*/
	surfaceArea = theSpot->surfaceArea = theSpot->borderCount;
	theSpot->formFactor = ( 36.0*PI*pow ((double)theSpot->volume,2.0) ) / pow (surfaceArea,3.0);
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
int arg;
coordinate theWave=0;
PixStack *theStack;
char doDB = 0;
char *endPtr;
static char dIDcontrolString[32]="-";


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
  

	theStack = outSpot->itsStack;
/*
* We are going to loop through the arguments. and as we encounter a valid output argument,
* write stuff to stdout.
*/
	arg = outArgs;
	while (arg < argc)
	{
/* -ID :	 Ouput spot ID */
		if (!strcmp ( argv[arg],"-ID"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"  ID   ");
			else
				fprintf (stdout,"%7lu",outSpot->ID);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -ID */
	

/* -dID :	 Pixels ID from the command line */
		if (!strcmp ( argv[arg],"-dID"))
		{
			if (strlen (dIDcontrolString) < 2)
				sprintf (dIDcontrolString,"%%%ds",(int)strlen(argv[2]));
			if (saywhat == HEADING)
				fprintf (stdout,dIDcontrolString,"PixelsID");
			else
				fprintf (stdout,dIDcontrolString,argv[2]);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -tID */
		

/* -v :	 Ouput volume */
		if (!strcmp ( argv[arg],"-v"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"volume ");
			else
				fprintf (stdout,"%llu",(unsigned long long)outSpot->volume);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -ff :  Display the spot's form-factor (1 for sphere or circle in 2D, <1 if deviates) */
		if (!strcmp ( argv[arg],"-ff"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"Form Factor");
			else
				fprintf (stdout,"%f",outSpot->formFactor);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -sa :  Display the spot's surface area */
		if (!strcmp ( argv[arg],"-sa"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"Surf. Area");
			else
				 fprintf (stdout,"%f",outSpot->surfaceArea);
				
		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -per :  Display the spot's perimeter */
		if (!strcmp ( argv[arg],"-per"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"perimeter");
			else
				fprintf (stdout,"%f",outSpot->perimeter);

		/* If there are more arguments to come, spit out a tab character. */
			fprintf (stdout,"\t");
		} /* -v */
	

/* -mc :  Ouput mean coordinates (center of volume)	 */
		else if (!strcmp ( argv[arg],"-mc"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"mean X\tmean Y\tmean Z");
			else
				fprintf (stdout,"%f\t%f\t%f",
					outSpot->mean_x,outSpot->mean_y,outSpot->mean_z);
			fprintf (stdout,"\t");
		} /* -mc */
	

/* -sd :  Ouput std. deviation for the spot's X, Y and Z (dispersion) */
		else if (!strcmp ( argv[arg],"-sd"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"sigma X\tsigma Y\tsigma Z");
			else
				fprintf (stdout,"%f\t%f\t%f",
					outSpot->sigma_x,outSpot->sigma_y,outSpot->sigma_z);
			fprintf (stdout,"\t");
		} /* -sd */
	

/* -box :  Ouput min and max values for the spot's X, Y and Z coordinates (bounding box) */
		else if (!strcmp ( argv[arg],"-box"))
		{
			if (saywhat == HEADING)
				fprintf (stdout,"min X\tmin Y\tmin Z\tmax X\tmax Y\tmax Z");
			else
				fprintf (stdout,"%lu\t%lu\t%lu\t%lu\t%lu\t%lu",
					outSpot->min_x,outSpot->min_y,outSpot->min_z,outSpot->max_x,outSpot->max_y,outSpot->max_z);
			fprintf (stdout,"\t");
		} /* -sd */
	
	
/* -c <n> :	 Ouput centroids (center of mass - different at each wavelegth) */
		else if (!strcmp ( argv[arg],"-c")) {
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves)
				{
					if (saywhat == HEADING)
						fprintf (stdout,"c[%3lu]X\tc[%3lu]Y\tc[%3lu]Z",
							theWave, theWave, theWave);
					else
						fprintf (stdout,"%f\t%f\t%f",
							outSpot->stats[theWave].centroid_x,
							outSpot->stats[theWave].centroid_y,
							outSpot->stats[theWave].centroid_z);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout,"c[%3lu]X\tc[%3lu]Y\tc[%3lu]Z",theWave,theWave,theWave);
				else
					fprintf (stdout,"%f\t%f\t%f",
						outSpot->stats[theWave].centroid_x,
						outSpot->stats[theWave].centroid_y,
						outSpot->stats[theWave].centroid_z);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -c */
	
	
/* -i <n> :	 Ouput Integrals */
		else if (!strcmp (argv[arg],"-i"))
		{
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves) {
					if (saywhat == HEADING)
						fprintf (stdout, " i[%3lu]  ",theWave);
					else
						fprintf (stdout,"%f",outSpot->stats[theWave].sum_i);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout, " i[%3lu]  ",theWave);
				else
					fprintf (stdout,"%f",outSpot->stats[theWave].sum_i);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -i */



/* -m <n> :	 Ouput means */
		else if (!strcmp (argv[arg],"-m"))
		{
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves) {
					if (saywhat == HEADING)
						fprintf (stdout, "m[%3lu] ",theWave);
					else
						fprintf (stdout,"%f",outSpot->stats[theWave].mean_i);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout, "m[%3lu] ",theWave);
				else
					fprintf (stdout,"%f",outSpot->stats[theWave].mean_i);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -m */



/* -ms <n> :  Ouput means - number of standard deviations above the wavelegth's mean */
		else if (!strcmp (argv[arg],"-ms"))
		{
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves) {
					if (saywhat == HEADING)
						fprintf (stdout, "ms[%3lu]",theWave);
					else
						fprintf (stdout,"%f",
							(outSpot->stats[theWave].mean_i - theStack->stats[theWave][outSpot->itsTimePoint].mean)
							/ theStack->stats[theWave][outSpot->itsTimePoint].sigma);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout, "ms[%3lu]",theWave);
				else
					fprintf (stdout,"%f",
						(outSpot->stats[theWave].mean_i - theStack->stats[theWave][outSpot->itsTimePoint].mean)
						/ theStack->stats[theWave][outSpot->itsTimePoint].sigma);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -ms */



/* -g <n> :	 Ouput geometric means */
		else if (!strcmp (argv[arg],"-g")) {
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves) {
					if (saywhat == HEADING)
						fprintf (stdout, "g[%3lu] ",theWave);
					else
						fprintf (stdout,"%f",outSpot->stats[theWave].geomean_i);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout, "g[%3lu] ",theWave);
				else
					fprintf (stdout,"%f",outSpot->stats[theWave].geomean_i);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -g */



/* -gs <n> :  Ouput geometric means - number of standard deviations above the wavelegth's geometric mean */
		else if (!strcmp (argv[arg],"-gs")) {
			if (arg+1 < argc) theWave = strtoul(argv[arg+1], &endPtr, 10);
			else endPtr = argv[arg+1];
			if (endPtr != argv[arg+1]) { /* at least some of the argument had some digits */
				arg++;
				if (theWave < outSpot->nwaves) {
					if (saywhat == HEADING)
						fprintf (stdout, "gs[%3lu]",theWave);
					else
						fprintf (stdout,"%f",
							(outSpot->stats[theWave].geomean_i - theStack->stats[theWave][outSpot->itsTimePoint].geomean)
							/ theStack->stats[theWave][outSpot->itsTimePoint].geosigma);
				}
			} else for (theWave = 0; theWave < outSpot->nwaves; theWave++) {
				if (saywhat == HEADING)
					fprintf (stdout, "gs[%3lu]",theWave);
				else
					fprintf (stdout,"%f",
						(outSpot->stats[theWave].geomean_i - theStack->stats[theWave][outSpot->itsTimePoint].geomean)
						/ theStack->stats[theWave][outSpot->itsTimePoint].geosigma);
				if (theWave < outSpot->nwaves-1)
					fprintf (stdout,"\t");
			}
			fprintf (stdout,"\t");
		} /* -gs */
    	else if (!strcmp ( argv[arg],"-tm") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout," Mean  \t");
			else
				fprintf (stdout,"%f\t",theStack->stats[outSpot->itsWave][outSpot->itsTimePoint].mean);
    		}
    	else if (!strcmp ( argv[arg],"-tSD") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout,"  SD   \t");
			else
				fprintf (stdout,"%f\t",outSpot->itsStack->stats[outSpot->itsWave][outSpot->itsTimePoint].sigma);
    		}
    	else if (!strcmp ( argv[arg],"-tt") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout," t  \t");
			else
				fprintf (stdout,"%lu\t",outSpot->itsTimePoint);
    		}
    	else if (!strcmp ( argv[arg],"-th") && doDB)
    	    {
			if (saywhat == HEADING)
				fprintf (stdout,"Thresh.\t");
			else
				fprintf (stdout,"%lf\t",outSpot->threshold);
    		}


	arg++;
	} /* while arg < argc */

}


void SetSpots2SpotsDist (spotsTable *theSpotsTable, SpotPtr theSpotListHead) {
SpotPtr theSpot;
int thisTime;
CoordList borderPixel;

unsigned long nRows, nCols, theR;
unsigned long xCol, yCol, zCol, tCol;
float min_dist,dist;
float min_dX,dX,min_dY,dY,min_dZ,dZ;
char dist_set = 0;
float theX,theY,theZ,theT;
char *endPtr;
MaskPtr mask_pixel;

	nRows = theSpotsTable->nRows;
	nCols = theSpotsTable->nCols;
	xCol = theSpotsTable->xCol;
	yCol = theSpotsTable->yCol;
	zCol = theSpotsTable->zCol;
	tCol = theSpotsTable->tCol;

	if (!( (xCol < nCols-4 && yCol < nCols-4 && zCol < nCols-4) &&
		(xCol || yCol || zCol) )) { /* these really shouldn't be 0 */
			return;
	}
	
	for (theR=1; theR < nRows; theR++) {

		thisTime = theSpotListHead->itsTimePoint;
		theSpot = theSpotListHead;

		if (tCol) {
			theT = strtof (theSpotsTable->cells[theR][tCol], &endPtr);
			if (theT != thisTime) continue;
		}
		else theT = 0;
		
		theX = strtof (theSpotsTable->cells[theR][xCol], &endPtr);
		theY = strtof (theSpotsTable->cells[theR][yCol], &endPtr);
		if (zCol) theZ = strtof (theSpotsTable->cells[theR][zCol], &endPtr);
		else theZ = 0;
		
		/* Skip it if the coordinates are out of bounds */
		if ( (theX > theSpot->clip_Xmax)
			|| (theX < theSpot->clip_Xmin)
			|| (theY > theSpot->clip_Ymax)
			|| (theY < theSpot->clip_Ymin)
			|| (theZ > theSpot->clip_Zmax)
			|| (theZ < theSpot->clip_Zmin) ) {
				fprintf (stderr,"Skipping (%f,%f,%f) - coordinates out of bounds\n",theX,theY,theZ);
				continue;
		}
//fprintf (stderr,"From (%f,%f,%f)",theX,theY,theZ);

		min_dX = theSpot->itsStack->max_x;
		min_dY = theSpot->itsStack->max_y;
		min_dZ = theSpot->itsStack->max_z;
		dist_set = 0;
		min_dist = sqrt (min_dX*min_dX + min_dY*min_dY + min_dZ*min_dZ);
		while (theSpot->next != theSpotListHead) {
//fprintf (stderr,"[%lu]",(unsigned long)theSpot->volume);
			if (! theSpot->volume) {
				theSpot = theSpot->next;
				continue;
			}

			borderPixel = theSpot->borderPixels;
			while (borderPixel) {
				dX = borderPixel->X - theX;
				dY = borderPixel->Y - theY;
				if (zCol) dZ = borderPixel->Z - theZ;
				else dZ = 0;
				dist = sqrt (dX*dX + dY*dY + dZ*dZ);
				if (dist < min_dist) {
					dist_set = 1;
					min_dist = dist;
					min_dX = dX;
					min_dY = dY;
					min_dZ = dZ;
				}
				borderPixel = borderPixel->next;
			}

		/*
		* Advance to the next spot in this timepoint.
		*/
			theSpot = theSpot->next;
		}
		
		/* finish the row */
		if (!dist_set) min_dX = min_dY = min_dZ = min_dist = 0.0; /* no border pixels ? */
		
		/* Check to see if we're inside or outside */
		mask_pixel = Coords_To_Index (theSpot->itsStack,theX,theY,theZ);
		if (*mask_pixel == PROCESSED_SPOT_PIXEL) min_dist = -min_dist;
		
		sprintf (theSpotsTable->cells[theR][nCols-4],"%f",min_dX);
		sprintf (theSpotsTable->cells[theR][nCols-3],"%f",min_dY);
		sprintf (theSpotsTable->cells[theR][nCols-2],"%f",min_dZ);
		sprintf (theSpotsTable->cells[theR][nCols-1],"%f",min_dist);
//fprintf (stderr,"to (%f,%f,%f)\n",min_dX,min_dY,min_dZ);
	}

}



void Write_Spots2spots (spotsTable *theSpotsTable) {
unsigned long nRows, nCols, theR, theC;

	nRows = theSpotsTable->nRows;
	nCols = theSpotsTable->nCols;
	
	
	/*
	* Set labels for outputs
	*/
	strcpy (theSpotsTable->cells[0][nCols-4],"dX");
	strcpy (theSpotsTable->cells[0][nCols-3],"dY");
	strcpy (theSpotsTable->cells[0][nCols-2],"dZ");
	strcpy (theSpotsTable->cells[0][nCols-1],"dist.");
	
	for (theR=0; theR < nRows; theR++) {
		/* print out the table that was read in */
		for (theC=0; theC < nCols; theC++) {
			printf ("%s",theSpotsTable->cells[theR][theC]);
			if (theC < nCols-1) printf ("\t");
		}
		printf ("\n");
	}
}


void Write_Output (SpotPtr theSpotListHead,int argc, char**argv,int outArgs)
{
SpotPtr theSpot,theTimepointListHead;
char done=0,doDB=1,doLabels=1;
int thisTime,i;
PixStack *theStack;

	theStack = theSpotListHead->itsStack;
	if (getArg (argc,argv,"-nl") > -1) doLabels=0;

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
					fprintf (stdout,"%f\t",theStack->stats[theSpot->itsWave][theSpot->itsTimePoint].mean);
				if (!strcmp ( argv[i],"-tSD"))
					fprintf (stdout,"%f\t",theStack->stats[theSpot->itsWave][theSpot->itsTimePoint].sigma);
				if (!strcmp ( argv[i],"-tt"))
					fprintf (stdout,"%lu\t",theSpot->itsTimePoint);
				if (!strcmp ( argv[i],"-th"))
					fprintf (stdout,"%lf\t",theStack->threshold);
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
		theSpot = theSpot->itsHead->nextTimePointList;
		if (theSpot == NULL)
			done = 1;
		else
			thisTime = theSpot->itsTimePoint;
		}
	
}

double Set_Threshold (const char *arg, PixStack *theStack)
{
float nSigmas;
double theThreshold;
coordinate theC,theT;
char argUC[128];
char* argUCptr;
const char* argPtr;


	argUCptr = argUC;
	argPtr = arg;
	while (*argPtr) {*argUCptr++ = toupper (*argPtr++); }
	*argUCptr++ = '\0';

	theC = theStack->spotWave;
	theT = theStack->timepoint;

	if (!strncmp(argUC,"MEAN",4)) {
		nSigmas = 0;
		if (strlen (argUC) > 4)
			sscanf (strrchr(argUC,'N')+1,"%fS",&nSigmas);
		theThreshold = theStack->stats[theC][theT].mean + (theStack->stats[theC][theT].sigma*nSigmas);
	} else if (!strncmp(argUC,"GMEAN",5)) {
		nSigmas = 0;
		if (strlen (argUC) > 5)
			sscanf (strrchr(argUC,'N')+1,"%fS",&nSigmas);
		theThreshold = theStack->stats[theC][theT].geomean + (theStack->stats[theC][theT].geosigma*nSigmas);
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
		sscanf (argUC,"%lf",&theThreshold);


	if (theThreshold > theStack->stats[theC][theT].max)
		theThreshold = theStack->stats[theC][theT].max;
	return (theThreshold);
}



double *Get_Prob_Hist (PixStack *theStack, unsigned short *histSizePtr)
{
coordinate theC,theT;
size_t nPix;

unsigned short histSize, theBin;
double max,min,range;
unsigned long long *intHist;
double *probHist;
double scale;

u_int8_t *u_int8_p0, *u_int8_p1;
u_int16_t *u_int16_p0, *u_int16_p1;
u_int32_t *u_int32_p0, *u_int32_p1;
int8_t *int8_p0, *int8_p1;
int16_t *int16_p0, *int16_p1;
int32_t *int32_p0, *int32_p1;
float *float_p0, *float_p1;
	
	theC = theStack->spotWave;
	theT = theStack->timepoint;
	nPix = theStack->nPix;
	max = theStack->stats[theC][theT].max;
	min = theStack->stats[theC][theT].min;
	range = max - min;
	
	if (range <= 0) {
		*histSizePtr = 0;
		return (NULL);
	}
	
	if ( theStack->pixType == PIX_T_FLOAT || range > MAX_HIST_SIZE ) {
		histSize = MAX_HIST_SIZE;
	} else {
		histSize = (unsigned short)range;
	}

	*histSizePtr = histSize;
	scale = (histSize - 1.0) / range;

	if ( (intHist = calloc (histSize, sizeof (unsigned long long))) == NULL) return (NULL);
	if ( (probHist = malloc (sizeof (double) * histSize)) == NULL ) {
		free (intHist);
		return (NULL);
	}

	switch (theStack->pixType) {
		case PIX_T_FLOAT:
			float_p0 = (float *) (theStack->stacks[theC]);
			float_p1 = float_p0 + nPix;
			while (float_p0 < float_p1) {
				intHist[(int) ((*float_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_UINT8:
			u_int8_p0 = (u_int8_t *) (theStack->stacks[theC]);
			u_int8_p1 = u_int8_p0 + nPix;
			while (u_int8_p0 < u_int8_p1) {
				intHist[(int) ((*u_int8_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_UINT16:
			u_int16_p0 = (u_int16_t *) (theStack->stacks[theC]);
			u_int16_p1 = u_int16_p0 + nPix;
			while (u_int16_p0 < u_int16_p1) {
				intHist[(int) ((*u_int16_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_UINT32:
			u_int32_p0 = (u_int32_t *) (theStack->stacks[theC]);
			u_int32_p1 = u_int32_p0 + nPix;
			while (u_int32_p0 < u_int32_p1) {
				intHist[(int) ((*u_int32_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_INT8:
			int8_p0 = (int8_t *) (theStack->stacks[theC]);
			int8_p1 = int8_p0 + nPix;
			while (int8_p0 < int8_p1) {
				intHist[(int) ((*int8_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_INT16:
			int16_p0 = (int16_t *) (theStack->stacks[theC]);
			int16_p1 = int16_p0 + nPix;
			while (int16_p0 < int16_p1) {
				intHist[(int) ((*int16_p0++-min)*scale)]++;
			}
		break;
		case PIX_T_INT32:
			int32_p0 = (int32_t *) (theStack->stacks[theC]);
			int32_p1 = int32_p0 + nPix;
			while (int32_p0 < int32_p1) {
				intHist[(int) ((*int32_p1++-min)*scale)]++;
			}
		break;
		default:
		break;
	}
	
	for (theBin = 0; theBin < histSize; theBin++) {
		probHist[theBin] = (double) intHist[theBin] / (double) nPix;
	}
	
	free (intHist);
	
	return (probHist);

	
}


double Get_Thresh_Moment (PixStack *theStack)
{
unsigned short histSize;
double *probHist,*probHistPtr,prob;
double m1=0.0, m2=0.0, m3=0.0;
double cd, c0, c1, z0, z1, pd, p0, p1;
double pDistr = 0.0;
unsigned long i;
double thresh=0.0;
unsigned short hist_thresh=0;
double scale;

	probHist = Get_Prob_Hist (theStack, &histSize);
	if (histSize && probHist == NULL) return ( (
		theStack->stats[theStack->spotWave][theStack->timepoint].max - 
		theStack->stats[theStack->spotWave][theStack->timepoint].min) / 2.0
	);

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
	for (hist_thresh = 0; hist_thresh < histSize; hist_thresh++)
	{
		pDistr += *probHistPtr++;
		if (pDistr > p0)
			break;
	}

	if (probHist) free (probHist);
	
	/* re-scale the threshold.
	* the hiostogram bin is determined like this:
	* hist[((value - min)*scale)]++;
	* where min is the stack minimum, and scale = (histSize - 1.0) / range
	*/
	if (histSize) {
		scale = (histSize - 1.0) / (
			theStack->stats[theStack->spotWave][theStack->timepoint].max - 
			theStack->stats[theStack->spotWave][theStack->timepoint].min
		);
		if (scale != 0) {
			thresh = (double) hist_thresh / scale;
			thresh += theStack->stats[theStack->spotWave][theStack->timepoint].min;
		} else {
			thresh = theStack->stats[theStack->spotWave][theStack->timepoint].max;
		}
	} else {
		/* Degenerate case: all the pixels are of one value */
		thresh = theStack->stats[theStack->spotWave][theStack->timepoint].min;
	}
	
	return (thresh);
}



double Get_Thresh_Otsu (PixStack *theStack)
{
unsigned short histSize,histSize_1;
double *probHist;
double varWMin=BIGFLOAT;
double m0Low,m0High,m1Low,m1High,varLow,varHigh;
double varWithin;
unsigned long i,j;
double thresh=0.0;
unsigned short hist_thresh=0;
double scale;

	probHist = Get_Prob_Hist (theStack, &histSize);
	if (histSize && probHist == NULL) return ( (
		theStack->stats[theStack->spotWave][theStack->timepoint].max - 
		theStack->stats[theStack->spotWave][theStack->timepoint].min) / 2.0
	);


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
			hist_thresh = i;
		}
	}

	if (probHist) free (probHist);
	
	/* re-scale the threshold.
	* the hiostogram bin is determined like this:
	* hist[((value - min)*scale)]++;
	* where min is the stack minimum, and scale = (histSize - 1.0) / range
	*/
	if (histSize) {
		scale = (histSize - 1.0) / (
			theStack->stats[theStack->spotWave][theStack->timepoint].max - 
			theStack->stats[theStack->spotWave][theStack->timepoint].min
		);
		if (scale != 0) {
			thresh = (double) hist_thresh / scale;
			thresh += theStack->stats[theStack->spotWave][theStack->timepoint].min;
		} else {
			thresh = theStack->stats[theStack->spotWave][theStack->timepoint].max;
		}
	} else {
		/* Degenerate case: all the pixels are of one value */
		thresh = theStack->stats[theStack->spotWave][theStack->timepoint].min;
	}

#ifdef DEBUG
fprintf (stderr,"Otsu's discriminant method threshold: %lf\n", thresh);
fflush (stderr);
#endif
	

	return (thresh);

}



double Get_Thresh_ME (PixStack *theStack)
{
unsigned short histSize;
double *probHist,*probHistPtr,prob;
double Hn=0.0, Ps=0.0, Hs=0.0;
double psi = 0, psiMax=0.0;
unsigned long i,j;
double thresh=0.0;
unsigned short hist_thresh=0;
double scale;

	probHist = Get_Prob_Hist (theStack, &histSize);
	if (histSize && probHist == NULL) return ( (
		theStack->stats[theStack->spotWave][theStack->timepoint].max - 
		theStack->stats[theStack->spotWave][theStack->timepoint].min) / 2.0
	);


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
			hist_thresh = i;
		}
	}
	
	if (probHist) free (probHist);
	
	/* re-scale the threshold.
	* the hiostogram bin is determined like this:
	* hist[((value - min)*scale)]++;
	* where min is the stack minimum, and scale = (histSize - 1.0) / range
	*/
	if (histSize) {
		scale = (histSize - 1.0) / (
			theStack->stats[theStack->spotWave][theStack->timepoint].max - 
			theStack->stats[theStack->spotWave][theStack->timepoint].min
		);
		if (scale != 0) {
			thresh = (double) hist_thresh / scale;
			thresh += theStack->stats[theStack->spotWave][theStack->timepoint].min;
		} else {
			thresh = theStack->stats[theStack->spotWave][theStack->timepoint].max;
		}
	} else {
		/* Degenerate case: all the pixels are of one value */
		thresh = theStack->stats[theStack->spotWave][theStack->timepoint].min;
	}

#ifdef DEBUG
fprintf (stderr,"Maximum Entropy threshold: %lf\n", thresh);
fflush (stderr);
#endif

	return (thresh);

}


double Get_Thresh_Kittler (PixStack *theStack)
{
unsigned short histSize,histSize_1;
double *probHist,*probHistPtr,prob;
double m0Low,m0High,m1Low,m1High,varLow,varHigh;
double term1, term2;
double stdDevLow, stdDevHigh;
double discr, discrMin, discrMax, discrM1;
unsigned long i,j;
double thresh=0.0;
unsigned short hist_thresh=0;
double scale;

	probHist = Get_Prob_Hist (theStack, &histSize);
	if (histSize && probHist == NULL) return ( (
		theStack->stats[theStack->spotWave][theStack->timepoint].max - 
		theStack->stats[theStack->spotWave][theStack->timepoint].min) / 2.0
	);


	histSize_1 = histSize - 1;
	discr = discrM1 = discrMax = discrMin = 0.0;
	for (i = 1, hist_thresh = 0; i < histSize_1; i++)
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

	hist_thresh = i;

	if (probHist) free (probHist);
	
	/* re-scale the threshold.
	* the hiostogram bin is determined like this:
	* hist[((value - min)*scale)]++;
	* where min is the stack minimum, and scale = (histSize - 1.0) / range
	*/
	if (histSize) {
		scale = (histSize - 1.0) / (
			theStack->stats[theStack->spotWave][theStack->timepoint].max - 
			theStack->stats[theStack->spotWave][theStack->timepoint].min
		);
		if (scale != 0) {
			thresh = (double) hist_thresh / scale;
			thresh += theStack->stats[theStack->spotWave][theStack->timepoint].min;
		} else {
			thresh = theStack->stats[theStack->spotWave][theStack->timepoint].max;
		}
	} else {
		/* Degenerate case: all the pixels are of one value */
		thresh = theStack->stats[theStack->spotWave][theStack->timepoint].min;
	}

#ifdef DEBUG
fprintf (stderr,"Kittler threshold: %lf\n", thresh);
fflush (stderr);
#endif

	return (thresh);

}



spotsTable *readSpotsTable (const char *spotsListFilename,int argc, char**argv) {
spotsTable *theSpotsTable;
int arg;
unsigned long xCol=0, yCol=0, zCol=0, tCol=0;
char *endPtr;

FILE *spotsListFile;
char line[1024], theC;
char *table=NULL,*linePtr,*tablePtr, **cellRows;
unsigned long nRows=0,nCols=0,nColsLine=0, theRow, theCol;
size_t table_size=0,table_nProcessed=0,line_size=0;
	
	if (!spotsListFilename || *spotsListFilename == '-') spotsListFile = stdin;
	else spotsListFile = fopen (spotsListFilename,"r");
	
	if (! spotsListFile) return NULL;
	
	/*
	* Get our X, Y, Z and T columns
	*/
	arg = 0;
	while (arg < argc)
	{
		if (!strcmp ( argv[arg],"-xCol") && (arg+1 < argc))
			xCol = strtoul(argv[arg+1], &endPtr, 10);
		else if (!strcmp ( argv[arg],"-yCol") && (arg+1 < argc)) 
			yCol = strtoul(argv[arg+1], &endPtr, 10);
		else if (!strcmp ( argv[arg],"-zCol") && (arg+1 < argc))
			zCol = strtoul(argv[arg+1], &endPtr, 10);
		else if (!strcmp ( argv[arg],"-tCol") && (arg+1 < argc))
			tCol = strtoul(argv[arg+1], &endPtr, 10);
		arg++;
	}

	
	while (! feof (spotsListFile) ) {
	/* Get to a non newline character */
		theC = fgetc (spotsListFile);
		while ( !feof (spotsListFile) && (theC == '\n' || theC == '\r' ) )
			theC = fgetc (spotsListFile);
		if (feof (spotsListFile))
			break;
	/* Get to a newline character, storing characters in line[] */
		line_size = 0;
		line[line_size++] = theC;
		while (! feof (spotsListFile) && theC != '\n' && theC != '\r' && line_size < 1022)
			line[line_size++] = theC = fgetc (spotsListFile);
	/* terminate the line so far with a \t replacing the newline */
		line_size--;
		line[line_size] = '\t';
	/* make some room for the results, and NULL-terminate */
		sprintf (line+line_size+1,"%31s\t%31s\t%31s\t%31s","","","","");
		line_size += (32*4);
	/* allocate/reallocate table */
		table_size += line_size+1;
		if (! table) table = malloc (sizeof (char) * table_size);
		else table = realloc (table, sizeof (char) * table_size);
		if (! table) {
			fprintf (stderr,"Memory could not be allocated for table.\n");
			exit (-1);
		}
		tablePtr = table + table_nProcessed;
	/* re-process the line, looking for tab characters */
		linePtr = line;
		nColsLine = 0;
		while (*linePtr) {
			if (*linePtr == '\t') {
				nColsLine++;
				*tablePtr++ = '\0';
				linePtr++;
			} else {
				*tablePtr++ = *linePtr++;
			}
			table_nProcessed++;
		}
		*tablePtr++ = '\0';
		table_nProcessed++;
		if (nRows && nColsLine && nColsLine != nCols) {
			fprintf (stderr,"Table is not square.  Columns in row %lu does not match.  Expecting %lu, got %lu.\n",
				nRows, nCols, nColsLine);
			exit (-1);
		} else {
			nCols = nColsLine;
		}
		nRows++;
	}

	nCols++;
//fprintf (stderr,"NCols: %lu\n",nCols);
	theSpotsTable = (spotsTable *) malloc (sizeof (spotsTable));
	if (! theSpotsTable) {
		fprintf (stderr,"Memory could not be allocated for table.\n");
		exit (-1);
	}
	
	theSpotsTable->nRows = nRows;
	theSpotsTable->nCols = nCols;
	theSpotsTable->table = table;
	theSpotsTable->xCol = xCol;
	theSpotsTable->yCol = yCol;
	theSpotsTable->zCol = zCol;
	theSpotsTable->tCol = tCol;
	cellRows = malloc (nRows * nCols * sizeof (char *));
	if (! cellRows) {
		fprintf (stderr,"Memory could not be allocated for table cells.\n");
		exit (-1);
	}
	theSpotsTable->cells = malloc (nRows * sizeof (char **));
	if (! theSpotsTable->cells) {
		fprintf (stderr,"Memory could not be allocated for table cells.\n");
		exit (-1);
	}

	/* set the cells pointers */
	tablePtr = table;
	for (theRow = 0; theRow < nRows; theRow++) {
		theSpotsTable->cells[theRow] = cellRows + (theRow * nCols) ;
		for (theCol = 0; theCol < nCols; theCol++) {
			theSpotsTable->cells[theRow][theCol] = tablePtr;
			while (*tablePtr++);
		}
	}

	return (theSpotsTable);
			
}



















/*########################################################################################################*/
/*##########################                                                    ##########################*/
/*##########################                     MAIN PROGRAM                   ##########################*/
/*##########################                                                    ##########################*/
/*########################################################################################################*/

int main (int argc, char **argv)
{
int minSpotVol,argIndx;
coordinate theC, theT;
MaskPtr maskIndex,maxIndex;
coordinate tStart=0,tStop=0, maskT=0;
SpotPtr theSpot;
const char* threshold = NULL;
OID PixelsID;
PixStack *theStack;
char doFadeSpots=0;
char doDarkSpots=0;
MaskPixel *maskCopy=NULL;

char *spotsListFilename, doSpots2spots=0;
spotsTable *theSpotsTable = NULL;


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
#ifdef DEBUG
	if (getArg (argc,argv, "db") > -1) {
		for (argIndx=0; argIndx < argc; argIndx++) fprintf (stderr,"%s ",argv[argIndx]);
	}
#endif

/*
* Check to see that we got an appropriate number of arguments.  If not, print out a helpfull
* usage message to stderr.
*/
	if (argc < OUTARGS)
	{
		usage (argv);
		exit (-1);
	}

	sscanf (argv[2],"%llu",&PixelsID);
	if (PixelsID == 0) {
		fprintf (stderr,"The PixelsID ('%s') cannot be 0.\n",argv[2]);
		usage(argv);
		exit (-2);
	}
	
#ifdef DEBUG
fprintf (stderr,"reading info for PixelsID %llu\n",PixelsID);
fflush (stderr);
#endif
	/* This establishes an omeis connection and calls pixelsInfo */
	theStack = NewPixStack (argv[1], PixelsID);
	if (theStack == NULL) {
		fprintf (stderr,"Could not retreive information for PixelsID=%llu\n",(unsigned long long)PixelsID);
		exit (-3);
	}
#ifdef DEBUG
fprintf (stderr,"read info for PixStack\n");
fflush (stderr);
#endif

	/*
	* Get the spot wavelegth and the minimum spot volume.
	*/
	sscanf (argv[3],"%lu",&theC);
	theStack->spotWave = theC;
	threshold = argv[4];
	sscanf (argv[5],"%d",&minSpotVol);

	/*
	* Read the timespan option
	*/
	if ( (argIndx = getArg (argc, argv, "-time")) > -1 && argIndx < argc) {
		if (argIndx+1 < argc) sscanf (argv[argIndx+1], "%lu-%lu", &tStart, &tStop);
		if (tStart == tStop) tStop++;
		if (tStart >= theStack->ph->dt)
			tStart = 0;
		if (tStop >= theStack->ph->dt || tStop < tStart)
			tStop = theStack->ph->dt;
	} else {
		tStart = 0;
		tStop = theStack->ph->dt;
	}
	
	/*
	* Decide if we're doing fadeSpots
	*/
	if ( (argIndx = getArg (argc, argv, "-fadeSpots")) > -1 && argIndx < argc) {
		doFadeSpots = 1;
		maskT = 0;
		if (argIndx+1 < argc) sscanf (argv[argIndx+1], "%lu", &maskT);
		if (maskT >= theStack->ph->dt) doFadeSpots=0;
	}
	
	/*
	* Decide if we're doing darkSpots
	*/
	if ( (argIndx = getArg (argc, argv, "-darkSpots")) > -1 && argIndx < argc) {
		doDarkSpots = 1;
	}
	
	/*
	* Decide if we're doing spots2spots
	*/
	if ( (argIndx = getArg (argc, argv, "-spotsList")) > -1 && argIndx < argc) {
		spotsListFilename = NULL;
		doSpots2spots = 0;
		if (argIndx+1 < argc) spotsListFilename = argv[argIndx+1];
		theSpotsTable = readSpotsTable (spotsListFilename, argc, argv);
		if (theSpotsTable) doSpots2spots = 1;
	}


#ifdef DEBUG
/*
* We are going to output the thresholds - one per timepoint - on a single line.
*/
	fprintf (stderr,"time argument: %s, tStart:%lu, tStop:%lu\n", argv[argIndx+1], tStart,tStop);
fflush (stderr);
#endif

/*
* ################   MAIN  LOOOP   ################ *
*/

	for (theT = tStart; theT < tStop; theT++) {
	
	/*
	* figure out what to set the threshold to from the input parameter
	* if this is the first timepoint
	*/
		if (doFadeSpots) {
			if (theT == tStart) {
			/* If its the first timepoint, we set up our mask based on the specified timepoint */
				ReadTimepoint (theStack, maskT);
				theStack->threshold = Set_Threshold (threshold,theStack);
				if (doDarkSpots)
					MakeThresholdMask_darkSpots (theStack);
				else
					MakeThresholdMask_lightSpots (theStack);
			/* make a copy of the mask, so we can use the copy on subsequent timepoints */
				if ( (maskCopy = (MaskPtr) malloc (theStack->nPix*sizeof(MaskPixel))) == NULL) {
					fprintf (stderr,"Could not allocate memory for a mask copy - exiting\n");
					exit (-1);
				}
				memcpy(maskCopy, theStack->mask, theStack->nPix * sizeof(MaskPixel));
			/* Make sure we've got the current timepoint read in */
				if (theT != maskT) ReadTimepoint (theStack, theT);
			} else {
			/* After the first timepoint, we copy the mask copy to make it the working mask */
				memcpy(theStack->mask, maskCopy, theStack->nPix * sizeof(MaskPixel));
				ReadTimepoint (theStack, theT);
			}
		} else {
		/* Calculate a mask based on the current timepoint */
			ReadTimepoint (theStack, theT);
			theStack->threshold = Set_Threshold (threshold,theStack);
			if (doDarkSpots)
				MakeThresholdMask_darkSpots (theStack);
			else
				MakeThresholdMask_lightSpots (theStack);
	}

		

#ifdef DEBUG
fprintf (stderr,"theC: %lu theT: %lu\n",theC,theT);
fprintf (stderr,"max_z: %lu\n",theStack->max_z);
fprintf (stderr,"theStack->geomean_i[theC]: %f\n",theStack->stats[theC][theT].geomean);
fprintf (stderr,"theStack->sigma_i[theC]: %f\n",theStack->stats[theC][theT].sigma);
fprintf (stderr,"Integration threshold:	 %lf\n", theStack->threshold);
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
	* theSpot will allways point to the spot-in-progress.	Once completed,
	* a new spot is allocated, and that new spot is then pointed to by
	* theSpot.	 In this way, theSpot is allways the last spot in the list,
	* and it is never a valid spot - it is either blank or in progress.
	* Note also that there is at least one spot in each time point, though it may not be valid (volume=0).
	*/
	
		theSpot = New_Spot (theStack,theC,theT);
		if (theSpot == NULL)
		{
			fprintf (stderr,"Could not allocate memory for spot.\n");
			exit (-1);
		}
	
	
	/*
	* Set up the pixel indexes to loop through.
	*/
		maskIndex = theStack->mask;
		maxIndex = maskIndex + theStack->nPix;

	/*
	* Run through the pixels in theC, making spots.
	*/
		while (maskIndex < maxIndex) {

		/*
		* If we run into a pixel that's above threshold, then call Eat_Spot to
		* eat it.
		*/
			if (*maskIndex > MASK_THRESHOLD) {
				Eat_Spot (theSpot,maskIndex);
			/*
			* If the resultant spot has a volume greater than that specified,
			* update the spot statistics, call the output routine, and make
			* a new spot to contain the next spot-in-progress.
			*/
				if (theSpot->volume >= minSpotVol) {
					Finish_Spot_Stats (theSpot);
					theSpot = New_Spot (theStack,theC,theT);
				}

			/*
			* If the spot was smaller than the minimum size, we need to make sure
			* all the accumulators and such are zeroed-out.
			*/
				else
					Zero_Spot (theSpot,theStack,theC,theT);
			} /* The index was > threshold so we ate a spot. */

		maskIndex++;
		} /* loop for all the pixels in a timepoint */
	if (doSpots2spots) SetSpots2SpotsDist (theSpotsTable,theStack->currSpotList);
	} /* loop for all the timepoints. */

/*
* Write a newline at the end of the thresholds.
	fprintf (stdout,"\n");
*/

/*
* Output of spot info is handled by Write_Output
* If we read in a table of spots, then call Write_Spots2spots
*/
	if (doSpots2spots) Write_Spots2spots (theSpotsTable);
	else Write_Output (theStack->spots, argc, argv, OUTARGS);
	
/*
* Exit gracefully.
*/	
	return (0);
}

void usage (char **argv) {
		fprintf (stderr,"Usage:\n");
		fprintf (stderr,"\t%s <OMEIS URL> <PixelsID> <waveindex> <threshold> <min spot vol> [<optional arguments> <output arguments>]\n", argv[0]);
		fprintf (stderr,"Note that the brackets (<>) are used to delineate options in this usage message.\n");
		fprintf (stderr,"Do not use brackets when actually putting in arguments.\n");
		fprintf (stderr,"<thresholds>:\n");
		fprintf (stderr,"\tnumber:    If a number is entered for this field, then this pixel value will be used as the threshold.\n");
		fprintf (stderr,"\tmean:      The mean pixel value at the specified waveindex will be used as the threshold.\n");
		fprintf (stderr,"\tmean<n>s:  The mean pixel value plus <n> standard deviations will be used as threshold.\n");
		fprintf (stderr,"\tgmean:     The geometric mean of the specified waveindex will be used as threshold.\n");
		fprintf (stderr,"\tgmean<n>s: The geometric mean plus <n> standard deviations will be used for threshold.\n");
		fprintf (stderr,"\tmoment:    The moment preservation method.\n");
		fprintf (stderr,"\totsu:      The Otsu's determinant threshold.\n");
		fprintf (stderr,"\tme:        The maximum entropy method.\n");
		fprintf (stderr,"\tkittler:   The Kittler method of minimum error.\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"<optional arguments>:\n");
		fprintf (stderr,"\t-time <n1>-<n2> begin and end timepoints.  Default is all timepoints. -time 4- will do t4 to the end, etc.  Time begins at 0\n");
		fprintf (stderr,"\t-fadeSpots <n>  Threshold the image at the <n> timepoint and use this timepoint's mask for all other timepoints. By default <n> = 0\n");
		fprintf (stderr,"\t-darkSpots      By default spots are assumed to be lighter than the background (e.g. Fluorescence labeled proteins). If this\n");
		fprintf (stderr,"\t                parameter is set, spots are assumed to be darker than background (e.g. Nucleii in H&E stained images).\n");
		fprintf (stderr,"<Output arguments>:\n");
		fprintf (stderr,"  Output is tab-delimited text with one line per spot.  Any summary information specified (-tm, -tt, etc) will be\n");
		fprintf (stderr,"  displayed once for each spot - not once per timepoint. Column order will be as specified in <Output arguments>,\n");
		fprintf (stderr,"\t-nl Supress column headings.  Usefull if database does not recognize column headings (i.e. FileMaker)\n");
		fprintf (stderr,"\t-ID Display the spot's ID# - a 'serial number' unique to each spot in this dataset.\n");
		fprintf (stderr,"\t-dID Dataset ID - Usefull if combining many images in a database.  The ID is the PixelsID supplied, and will\n");
		fprintf (stderr,"\t     be the same for all spots in this image.\n");
		fprintf (stderr,"### Channel/spectral data ###\n");
		fprintf (stderr,"  The <waveindex> parameter is optional.  If it is omitted, the indicated information is output for all wavelengths/channels\n");
		fprintf (stderr,"  Channels/wavelengths in the image are indexed starting with 0\n");
		fprintf (stderr,"\t-c <waveindex>: Display centroids (center of mass).\n");
		fprintf (stderr,"\t-i <waveindex>:  Display integral - sum of pixel values\n");
		fprintf (stderr,"\t-m <waveindex> Display mean pixel value.\n");
		fprintf (stderr,"\t-g <waveindex> Display the geometric mean pixel value.\n");
		fprintf (stderr,"\t-ms <waveindex> Same as -m, but number of std. deviations over the waveindex's mean.\n");
		fprintf (stderr,"\t-gs <waveindex> Same as -g, but number of std. deviations over the waveindex's geometric mean.\n");
		fprintf (stderr,"### Spatial data ###\n");
		fprintf (stderr,"\t-mc Display the average coordinate values of the spot (center of volume).\n");
		fprintf (stderr,"\t-v Display the spot's volume\n");
		fprintf (stderr,"\t-ff Display the spot's form-factor (1 for sphere in 3D or circle in 2D, <1 if deviates)\n");
		fprintf (stderr,"\t-per Display the spot's perimeter\n");
		fprintf (stderr,"\t-sa Display the spot's surface area\n");
		fprintf (stderr,"\t-sd Display the spot's dispersion - std. deviation of the spot's X,Y and Z\n");
		fprintf (stderr,"\t-box :  Ouput min and max values for the spot's X, Y and Z coordinates (bounding box)\n");
		fprintf (stderr,"### Time series data ###\n");
		fprintf (stderr,"\t-tm Display mean pixel value of the entire timepoint for the spot's waveindex\n");
		fprintf (stderr,"\t-tSD Display the standard deviation of the entire timepoint for the spot's waveindex\n");
		fprintf (stderr,"\t-tt Display the timepoint number\n");
		fprintf (stderr,"\t-th Display the threshold used for the timepoint\n");
		fprintf (stderr,"\n");	
		fprintf (stderr,"Example:\n");
		fprintf (stderr,"\tfindSpotsOME http://omeis.foo.com/cgi-bin/omeis 123 0 gmean1.5s 10 -tt -th -c -i -m -g -ms -gs -mc -v -sa -per -ff\n");
		fprintf (stderr,"\n");	
}

int getArg (int argc, char **argv, const char *arg) {
	while (argc > 0) {
		argc--;
		if (! strcmp (arg,argv[argc]) ) return (argc);
	}
	return (-1);
}


double PixValueIdx_u_int8 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (u_int8_t *)(theStack)+pixIndex);
}

double PixValueIdx_u_int16 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (u_int16_t *)(theStack)+pixIndex);
}

double PixValueIdx_u_int32 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (u_int32_t *)(theStack)+pixIndex);
}

double PixValueIdx_int8 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (int8_t *)(theStack)+pixIndex);
}

double PixValueIdx_int16 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (int16_t *)(theStack)+pixIndex);
}

double PixValueIdx_int32 (PixPtr theStack, size_t pixIndex) {
	return (double) *( (int32_t *)(theStack)+pixIndex);
}

double PixValueIdx_float (PixPtr theStack, size_t pixIndex) {
	return (double) *( (float *)(theStack)+pixIndex);
}

double PixValueCrd_u_int8 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (u_int8_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_u_int16 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (u_int16_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_u_int32 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (u_int32_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_int8 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (int8_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_int16 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (int16_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_int32 (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (int32_t *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}

double PixValueCrd_float (PixStack *theStack, coordinate theX, coordinate theY, coordinate theZ, coordinate theC) {
	return (double) *( (float *)(theStack->stacks[theC]) + theX + (theY * theStack->y_increment) + (theZ * theStack->z_increment) );
}


