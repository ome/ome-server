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
 * Written by:    
 * 
 *------------------------------------------------------------------------------
 */






#include "OMEdb.h"
#include <stdio.h>
#include <math.h>



#define TRUE 1
#define FALSE 0

typedef struct dv_data DV;
typedef struct dv_image DV_IMAGE;

int myvalueofthis;
int DEBUG_SPAWNSPOTS = 0;

/*
 * This is the standard DV header - it holds critical image/stack information
 * including # of wavelengths, # of timepoints, etc.
 */

struct dv_data {
	int   numCol,numRow,numSections;            /* nsec +AD0- nz-nw+ACo-nt */
	int   mode;
	int   nxst, nyst, nzst;
	int   mx, my, mz;
	float xlen, ylen, zlen;
	float alpha, beta, gamma;
	int   mapc, mapr, maps;
	float amin, amax, amean;
	int   ispg, next;
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
	int   nlab;
	char  label[800];
};


void ReadDVHeader( DV *head, FILE *fp );

/*
 * This structure holds a single DV image stack - it only keeps track of
 * very limited information
 */

struct dv_image {
	short int *stack;
	int rows;
	int cols;
	int Z;
	int W;
	int T;
};

/*
 * This is a task object that goes onto a task queue - it keeps track of
 * tasks you have queued up to spare you the trouble of ... I don't know.
 * It just works better with a GUI/forking.
 */

typedef struct task TASK;

struct task {
	char name[256];
	char output[256];
	FILE *infp;
	FILE *outfp;
	int x1, x2;
	int y1, y2;
	int points;
	int dist;
	int size;
	int thresh;
	int brief;
	int adjacent;
	int mode;
	int id;
	DV head;
	TASK *next;
	OMEdb dbHandle;
	long analysisID;
};

/*
 * This structure holds information about a particular file for X displaying.
 * Since X display doesn't work right now and I can't do any snazzy mouse
 * interface thing, this isn't important for the moment.
 */

/*
 * Queue of tasks - searches that you have set up to be performed, later.
 * Can make them editable, if you like, without difficulty, although I
 * didn't feel the need.
 */
TASK *task_list;

/* More X-display stuff that isn't important and might disappear later */
DV_IMAGE gImage;
DV head;
int gZ=0;
int gW=0;
int gT=0;


FILE *fp=NULL;

/* 
 * Number of tasks to perform - when you fork, this is reset to 0
 * and your child keeps track of how many tasks it has finished
 */
int numT=0;

/*
 * Use adjacent planes or not
 */
int useAdjacent;

/* Task ID index - keeps track of which IDs have been assigned, so you don't
 * assign the same one twice. Task IDs let you look up a task faster, for
 * whatever insane reason you might want to do that. */
int curr_id = 0;




/*
 * Read a single image stack from file into 'img', which must be allocated
 * previously. It needs header information from FILE in order to work,
 * so that it knows dimensions/size of bytes, etc. */
void ReadDVImage( FILE *fp, DV_IMAGE *img, DV head, int Z, int W, int T )
{
	int Rows = head.numRow, Cols = head.numCol;
	int numZ,num,i;

	img->stack = (short int*)malloc(Cols*Rows*sizeof(short int));
	img->rows = Rows;
	img->cols = Cols;
	img->Z	  = Z;
	img->W	  = W;
	img->T	  = T;
	numZ = head.numSections / (head.NumWaves * head.numtimes);
	num = T * numZ * head.NumWaves + W * numZ + Z;
	fseek( fp, 1024+head.next+num*Rows*Cols*2, SEEK_SET );
	i = fread( img->stack, sizeof(short int), Cols*Rows, fp );
}


/* Gives 3D distance between (x1,y1,z2) and (x2,y2,z3), where
 * x,y,z are in pixels from image with header 'head' */
float dist3d( int x1, int y1, int z1, int x2, int y2, int z2, DV head )
{
	float d = (x1 - x2) * (x1 - x2) * (head.xlen) * (head.xlen)
		+ (y1 - y2) * (y1 - y2) * (head.ylen) * (head.ylen)
		+ (z1 - z2) * (z1 - z2) * (head.zlen) * (head.zlen);

	return sqrtf(d);
}

/* Gives 2d distances similar to dist3d */
float dist2d( int x1, int y1, int x2, int y2 )
{
	float d = (x1 - x2) * (x1 - x2)
		+ (y1 - y2) * (y1 - y2);

	return sqrtf(d);
}

/* Macros - should be self-explanatory. In case they're not:
 * X - gives X coordinate of byte-position 'num' in image 'img'
 * Y - same as X, except Y.
 * N - gives byte-position for image for a given X, Y
 * MAX, MIN - Max and Min, duh */
#define X(num, img)		((num)%(img).cols)
#define Y(num, img)		(((num)-(num)%(img).cols)/(img).cols)
#define N(x,y, img)		(x+(y)*(img).cols)
#define MAX(a,b)		(((a) > (b)) ? (a) : (b))
#define MIN(a,b)		(((a) < (b)) ? (a) : (b))

/*
 * Attempts to define the spot-like features of a spot. This, hopefully,
 * will spare you from playing threshold games, although the hard-wiring
 * might be unhealthy in the end. The way this works is:
 * Count up and average the ring around the pixel 'coord'. If it is hotter
 * than the value of 'coord', you lose a point. If it is colder, you get a
 * point. Then repeat the process, except compare each successive ring to
 * the one that came before it (ring = a square). Return the score */

int edgeFind( DV_IMAGE img, int coord, int size )
{
	// Okay, try and make a guess over how good the center is - if it's
	// crappy in general, return a 0.. if it's decent, return a 1

	int score = 0,i,x,y,count,average;
	short *p;
	x = X(coord,img);
	y = Y(coord,img);

	printf( "Coord value is %d (%d, %d).\n", img.stack[coord], x, y );
	count = 0;

	average = img.stack[coord]*100;
	for (i = 1; i <= size; i++)
	{
		// okay, compare 'average value' to average of ring-around-the
		// center of radius i
		count = 0;

		// &img.stack[coord] = center. -i = x offset, -i*img.cols = y offset
		p = img.stack + coord - i - i*img.cols;
		printf( "P is %d. ", *p );

		// move counterclockwise
		x = 0;
		while (x++ < i*2+1) { count += *p++; }
		x=0; p += img.cols-1;
		while (x++ < i*2) { count += *p; p += img.cols-1; }
		x=0; p--;
		while (x++ < i*2) { count += *p--; }
		x=0; p -= img.cols-1;
		while (x++ < i*2-1) { count += *p; p -= img.cols-1; }
		printf( "Count is %d, i is %d. Average: %d\n",
			count, i, count*100 / (8*i) );
		count = count * 100 / (8*i);
		if (count < average) score++;
		else score--;
		average = count;
	}
	return score;
}

/* Cross find - a different version of 'edgeFind' that doesn't count rings
 * so you don't have strange averaging problems. Cross find uses less data
 * to make its conclusions than edgeFind, but appears to be faster and more
 * accurate. I like it.
 *
 * Correction - I changed my mind, it's too prone to random errors and doesn't
 * pick up on noisy data well enough.
 */

int crossFind( DV_IMAGE img,int coord, int size )
{
	int score = 0;
	// Okay, so basically you want to see a downward gradient from the
	// central point to the ends of a cross.You get a score for all of these. If
	// it does NOT satisfy the gradient, you're not on a spot.
	// That is, you want to see this:
	//
	//         1
	//         2
	//         3
	//   1 2 3 4 3 2 1 
	//         3
	//         2
	//         1
	// If, in stepping outward from the gradient, you step from a low value
	// to a high value, you lose a point, else you gain a point.
	int i=0;
	while (i++ < size) {
		score -= (img.stack[coord-i] < img.stack[coord-i+1])?-1:1; 
	} i=0;
	while (i++ < size) {
		score -= (img.stack[coord+i] < img.stack[coord+i-1])?-1:1; 
	} i=0;
	while (i++ < size) {
		score -= (img.stack[coord+i*img.cols] <
			img.stack[coord+(i-1)*img.cols])?-1:1;
	} i=0;
	while (i++ < size) {
		score -= (img.stack[coord+i*img.cols]<
			img.stack[coord+(i-1)*img.cols])?-1:1;
	}
	return score;
}

/*
 * Small utility for groupCompare below - this just bins a 3x3 box together
 */
int box3(DV_IMAGE img, int coord)
{
    int sco=0, c;
    c = coord;
    sco += img.stack[c]+img.stack[c-1]+img.stack[c+1];
    c = coord+img.cols;
    sco += img.stack[c]+img.stack[c-1]+img.stack[c+1];
    c = coord-img.cols;
    sco += img.stack[c]+img.stack[c-1]+img.stack[c+1];
    return sco;
}

/*
 * Okay this is my new favorite.. basically bins the spot into 3x3 boxes
 * and compares the central box to the surrounding ones.. hopefully this
 * really crude mechanism is worth it's salt.
 */
int groupCompare(DV_IMAGE img, int coord, int size)
{
	int sco = 0,cen,amt;
	cen = box3(img,coord);
	amt = box3(img,coord+3); sco += cen - amt;
	amt = box3(img,coord-3); sco += cen - amt;
	amt = box3(img,coord+3*img.cols); sco += cen - amt;
	amt = box3(img,coord-3*img.cols); sco += cen - amt;
	amt = box3(img,coord+3+3*img.cols); sco += cen - amt;
	amt = box3(img,coord-3+3*img.cols); sco += cen - amt;
	amt = box3(img,coord+3-3*img.cols); sco += cen - amt;
	amt = box3(img,coord-3-3*img.cols); sco += cen - amt;

	return sco;
}

char migratingSpot( int c1, int Z1, int c2, int Z2, 
	DV head, DV_IMAGE img1, FILE *fp, int T, int W, int dist )
{
	DV_IMAGE img2;
	int x1 = X(c1,img1);
	int y1 = Y(c1,img1);
	int x2 = X(c2,img1);
	int y2 = Y(c2,img1);

	ReadDVImage(fp,&img2,head,Z2,W,T);

	if (groupCompare(img1, c1, 0) > 250 
	&& groupCompare(img1,c2,0) < 250
	&& groupCompare(img2,c2,0) > 250
	&& groupCompare(img1,c1,0) < 250
	&& dist2d(x1,y1,x2,y2) < dist*2)
	{
		free(img2.stack);
	return TRUE;
	}
	free(img2.stack);
	return FALSE;
}

/* Returns a 2D array of ints that contains, basically, your results.
 * The way this works is as follows:
 * In general, you search through a stack, smooth a 's' by 's' box, and look
 * for boxes with the highest average value. These are hopefully your
 * spots. You repeat this process over all your Z planes, and pick the best 
 * looking spots. If you are using adjacent planes, smoothing occurs in
 * 3 dimensions - that is, it will use data from the plane directly above
 * and below you to smooth as well. To a first approximation squares and
 * circles are identical at this resolution, so spot = a square, here.
 * However there are complications, including:
 * 1) picking the same spot twice. You can avoid this by distance parameters.
 * That is, if a spot is too close to one of the other spots, don't use it.
 * However, if a picked spot is close to an existing spot, and it is hotter
 * than the existing spot, replace the existing spot with that value.
 * That is, if 4,4 has been picked, and 4,5 is hotter than 4,4 then you should
 * use 4,4. If you are uncareful about this swapping you will accidentally
 * nudge your way into picking the same spot 50 times, through odd creeping
 * mechanisms that are fairly subtle.
 * 2) Picking the same spot in adjacent planes. That is, if 4,4 is hot in 
 * plane 3, and 4,4 is hot in plane 4, it may somtime pick both of these.
 * The solution (and this is the only real solution) to this is: don't pick
 * spots from the same Z - that is, (1) uses 2D distance, not 3D distance,
 * and ignores Z. So if 4,4,3 is hot and 4,4,9 is hot, 4,4,9 will be ignored
 * unless it is hotter than 4,4,3, because it is in the same planar location,
 * even though it is quite far away, distance-wise. This saves much confusion
 * and will rarely cause you data problems, since the chances of two spots
 * lining up vertically are slim.
 * 3) Picking background when you don't know how many spots you have.
 * If I am looking for 6 spots, and there are only 3 in the picture,
 * obviously some of the time it will pick background. Later on when it
 * outputs, it will weed these out based on spot characteristics via
 * 'edgeFind', which essentially measures the gradient value of a spot
 * The returned array contains, for each spot, in the following order:
 * 0 - Z value of spot center
 * 1 - total average intensity of the spot
 * 2 - 'score' of the spot
 * 3 - X value of spot center
 * 4 - Y value of spot center
 * 5 - debugging values
 */
int **FindBrightestPoints(DV head,int s, int numPoints, int T, int W, FILE *fp,
							int a, int b, int m, int n, int dist, int thresh)
{
	int j,z,numZ;
	int **Points;
	int size = s,score;
	int ru,se,pe;
	static DV_IMAGE img;
	static DV_IMAGE above;
	static DV_IMAGE below;
	if (size%2==0) size++;

	Points = (int**)malloc(numPoints*sizeof(int*));
	for (j = 0; j < numPoints; j++) {
		Points[j] = (int *)malloc(6*sizeof(int));
		Points[j][0] = 0;
		Points[j][1] = 0;
		Points[j][2] = 0;
		Points[j][3] = 0;
		Points[j][4] = 0;
		Points[j][5] = 0;
	}
	numZ = head.numSections / (head.NumWaves * head.numtimes);
	for (z = 0; z < numZ; z++) {

	if (useAdjacent) {
	if (!z)
	{
	ReadDVImage(fp,&below,head,z,W,T);
	}
	else
	below = img;
	}

	if (useAdjacent)
	{
	if (!z)
	img = below;
	else
	img = above;
	}
	else
	ReadDVImage( fp, &img, head, z, W, T );

	if (useAdjacent) {
	if (z < numZ-1)
	{
	ReadDVImage(fp,&above,head,z+1,W,T);
	}
	else
	above = img;
	}

	ru = N(a,b,img);
	se = N(a,b+1,img) - N(m,b,img) - 1;
	pe = 1+N(m,n,img);


	/* Okay here you zip through the points in the plane */
	for(j=ru;j<pe;j++)
	{
		//int minx, miny, maxx,maxy;
		int x,y; // , cr;
		int tot = 0;
		int min = -1;

		/* The current pixel is fairly dim, so continue on.. */
		if (img.stack[j] < min/100.0) continue;

		// Fill the box of squares around j
		x = X(j,img);
		y = Y(j,img);
		/* minx = MAX(0,x-(size-1)/2);
		miny = MAX(0,y-(size-1)/2);
		maxx = MIN(img.cols-1,x+(size-1)/2);
		maxy = MIN(img.rows-1,y+(size-1)/2);
		int f,g;
		for (g = minx; g <= maxx; g++) {
		for (f = miny; f <= maxy; f++) {
				cr = N(g,f,img);
				tot += img.stack[cr];
				if (useAdjacent) {
				tot += above.stack[cr];
				tot += below.stack[cr];
				}
			}
		} */

		tot = groupCompare(img,j,5);

		score=tot;
		if (tot > thresh)
		//if ((score = groupCompare( img,j, 4)) > 250)
		{
			/* Fill in empty points. If you have no empty points, then
			 * replace the LOWEST point value less than tot.
			 * Before you make any replacements, do a comprehensive
			 * check for redundancies - first check for a redundancy,
			 */
			 int WasADuplicate = FALSE;
			 int dupC = -1,q,q2;
			 for (q = 0; q < numPoints; q++)
				if (dist2d(Points[q][3], Points[q][4],x, y) < (dist*5)/6)
				{
					if (tot > Points[q][1]) {
					if (dupC == -1)
					dupC = q;
					else if (Points[q][1] > Points[dupC][1])
					dupC = q;
					}
					WasADuplicate = TRUE;
				}
			if (dupC != -1) {
				if (DEBUG_SPAWNSPOTS) {
					printf( "[%3d,%3d,%3d,%5d]->[%3d,%3d,%3d,%5d]\n",
						Points[dupC][3], Points[dupC][4], Points[dupC][0],
						Points[dupC][1],
						x, y, z, tot );
					fflush(stdout);
				}
				Points[dupC][0] = z;
				Points[dupC][1] = tot;
				Points[dupC][2] = score;
				Points[dupC][3] = x;
				Points[dupC][4] = y;
				Points[dupC][5] = 0;
				// Wax 'creepers' - spots that have somehow encroached
				// on your territory
				for (q2 = 0; q2 < numPoints; q2++)
				{
					if (q2==dupC)continue;
					if (dist2d(Points[q2][3], Points[q2][4],x, y) < dist
					&& Points[q2][1] < tot)
					{
				if (DEBUG_SPAWNSPOTS) {
					printf( "!%d,%d,%d!\n",
						Points[q2][3], Points[q2][4], Points[q2][0] );
				}
						Points[q2][0] = 0;
						Points[q2][1] = 0;
						Points[q2][2] = 0;
						Points[q2][3] = 0;
						Points[q2][4] = 0;
						Points[q2][5] = 0;
					}
				}
			}
			if (!WasADuplicate) {
			int NotSubbed = TRUE;
			for (q = 0; q < numPoints; q++)
			{
				if (Points[q][1] == 0)
				{
				if (DEBUG_SPAWNSPOTS) {
					printf( "[%3d,%3d,%3d,%5d]->[%3d,%3d,%3d,%5d]\n",
						Points[q][3], Points[q][4], Points[q][0],
						Points[q][1],
						x, y, z, tot );
					fflush(stdout);
				}
					Points[q][0] = z;
					Points[q][1] = tot;
					Points[q][2] = score;
					Points[q][3] = x;
					Points[q][4] = y;
					Points[q][5] = 0;
					NotSubbed = FALSE;
					break;
				}
			}
			if (NotSubbed) {
				int min, cho=-1;
				min = 1<<(8*sizeof(int)-2);
				for (q = 0; q < numPoints; q++) {
					if (Points[q][1] < min)
					{
						cho = q;
						min = Points[q][1];
					}
				}
				if (min < tot && cho != -1)
				{
				if (DEBUG_SPAWNSPOTS) {
					printf( "[%3d,%3d,%3d,%5d]->[%3d,%3d,%3d,%5d]\n",
						Points[cho][3], Points[cho][4], Points[cho][0],
						Points[cho][1],
						x, y, z, tot );
					fflush(stdout);
				}
					Points[cho][0] = z;
					Points[cho][1] = tot;
					Points[cho][2] = score;
					Points[cho][3] = x;
					Points[cho][4] = y;
					Points[cho][5] = 0;
					NotSubbed = FALSE;
				}
			}
			}
		}
		if (x==m) j += se;
	}
	if (!useAdjacent)
	{
	free(img.stack);
	}
	else if (z==numZ-1)
	{
		free(img.stack);
		free(above.stack);
		free(below.stack);
	}
	else if (z)
	free(below.stack);
	}
	return Points;
}




/* 
* A command line wrapper for SpawnSpots
* Interprets the comamnd line (argc and argv passed in), filling out
* a task structure that gets allocated here.  If there are fatal errors, will exit (-1)
* If there are other errors, returns NULL.
* Fatal errors:
*	Could not open deltavision file.
*	Could not get output file name.
*	Could not open temporary file for writing.
*	Deltavision file is not in DeltaVision format (t->head.nDVID != -16224).
* Ouput file is open for writing without checking if it exists. If it does, it will be
* overwritten.
* The returned task can be passed directly to run_task(task)
* arg[1] = DV file name
* arg[2] = distance
* arg[3] = size
* arg[4] = threshold
* arg[5] = x1
* arg[6] = y1
* arg[7] = x2
* arg[8] = y2
* arg[9] = points
* arg[10] = adjacend (0=false, any other number is true, anything else is false)
* arg[11] = database connection string - passed to PQconnectdb as defined in libpq.h.
*/
TASK *make_task (int argc, char * argv[])
{
TASK *t;
char message[256],attrNames[256],attrValues[256];
char progName[]="spawnSpots";
long datasetID,programID;


	t = (TASK*) malloc(sizeof(TASK));

	t->id = ++curr_id;
	strcpy (t->name,argv[1]);

/*
* Fatal error if can't open OME connection.
*/
	t->dbHandle = OME_Get_DB_Handle_From_String (argv[11]);

/*
* Get the programID
*/
	programID = OME_Get_Program_ID (t->dbHandle,progName);
	if (!(programID))
	{
		sprintf (message,"Program '%s' is not registered with OME.",progName);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (t->dbHandle);
	}

/*
* Fatal error if deltavision file not registered with OME.
*/
	datasetID = OME_Get_Dataset_ID (t->dbHandle,argv[1]);
	if (datasetID == 0)
	{
		sprintf (message,"Dataset '%s' is not registered with OME.",argv[1]);
		OME_Error (OME_FATAL_ERROR,message);
		OME_Exit (t->dbHandle);
	}

/*
* Fatal error if can't open deltavision file.
*/
	if ((t->infp = OME_Open_Dataset_File (t->dbHandle,datasetID,"r")) == NULL)
	{
		sprintf (message,"Could not open DeltaVision File %s.",t->name);
		OME_Error(OME_FATAL_ERROR,message);
		--curr_id;
		free(t);
		exit (-1);
	}
#ifdef DEBUG
fprintf (stdout,"Opened Dataset File\n");
fflush (stdout);
#endif

/*
* Fatal error if not a deltavision file.
*/
	ReadDVHeader( &t->head, t->infp );
	if (t->head.nDVID != -16224)
	{
		sprintf (message,"%s doesn't seem to be a DeltaVision file.",t->name);
		OME_Error(OME_FATAL_ERROR,message);
		--curr_id;
		fclose(t->infp);
/*
		fclose(t->outfp);
*/
		free(t);
		exit (-1);
	}

	t->dist =atoi(argv[2]);
	if (t->dist < 1) t->dist = 1;

	t->size = atoi(argv[3]);
	if (t->size < 1) t->size = 1;

	t->thresh = atoi(argv[4]);
	if (t->thresh < 1) t->thresh = 1;

	t->x1 = atoi(argv[5]);
	t->y1 = atoi(argv[6]);
	t->x2 = atoi(argv[7]);
	t->y2 = atoi(argv[8]);
	if (t->x1 < 0) t->x1 = 1;
	if (t->x2 < 0) t->x2 = 1;
	if (t->y1 < 0) t->y1 = 1;
	if (t->y2 < 0) t->y2 = 1;

	t->points = atoi(argv[9]);
	if (t->points < 1) t->points = 1;
	if (t->points > 50) t->points = 50;

	t->adjacent =  atoi(argv[10]);

/*
* Set the analysis attributes, and check if this is a repeat.
* If this is an exact repeat of an existing analysis, then exit.
*/
	sprintf (attrValues,"%d, %d, %d, %d, %d, %d, %d, %d, ",
		t->dist,t->size,t->thresh,t->x1,t->y1,t->x2,t->y2,t->points);
	if (t->adjacent) strcat (attrValues,"true");
	else strcat (attrValues,"false");
	sprintf (attrNames,"DISTANCE,SIZE,THRESHOLD,X1,Y1,X2,Y2,POINTS,ADJACENT");
	if ((t->analysisID=OME_Get_Analysis_ID_From_Inputs (t->dbHandle,programID,datasetID,attrNames,attrValues)) )
	{
		OME_DB_Finish (t->dbHandle);
		exit (t->analysisID);
	}

	t->analysisID = OME_Register_Analysis (t->dbHandle,programID,datasetID,attrNames,attrValues);
#ifdef DEBUG
fprintf (stdout,"Registered analysis, executing program...\n");
fflush (stdout);
#endif
	return(t);
}


/* Runs a task - essentially, for each timepoint, finds the brightest spots,
 * chucks out the ones it doesn't like, and prints them out to the output
 * file specified by the task. Called after forking by child.
 */
void run_task( TASK *t )
{
char values[128];
int i;

// Appears to work, find the brightest points
	if (t->adjacent)
	useAdjacent = TRUE;
	else
	useAdjacent = FALSE;
	t->brief = TRUE;
/*
	fprintf( t->outfp,"# In %s\n"
					  "# Out %s\n"
					  "# Dist: %d Size %d (%d,%d) to (%d,%d)\n"
					  "# %d points. %s, %s.\n",
		t->name, t->output, t->dist, t->size, t->x1, t->y1, t->x2, t->y2,
		t->points, t->brief?"Brief":"Extended", 
		t->adjacent?"Adjacent planes":"Single planes");
	if (t->points == 3)
		fprintf (t->outfp,"%4s\t%4s\t%4s\t%4s\t%7s\n","Time","X","Y","Z","Dist");
	else
		fprintf (t->outfp,"%4s\t%4s\t%4s\t%4s\n","Time","X","Y","Z");
*/
	for (i = 0; i < t->head.numtimes; i++ ) {
		int **fake,**Points,k,abort=FALSE,j,num,*temp;
#ifdef DEBUG
fprintf (stdout,"timepoint %3d...",i);
fflush (stdout);
#endif
		fake = FindBrightestPoints( t->head, t->size, t->points+1, 
			i, 0, t->infp, t->x1, t->y1, t->x2, t->y2, t->dist, t->thresh );
#ifdef DEBUG
fprintf (stdout,"back from FindBrightestPoints");
fflush (stdout);
#endif

		/* Dump one of your points - or more */
		Points = (int**)malloc((t->points+1)*sizeof(int*));

		// sort your fake list based on brightness
/*
* Not sure that this is an actual sort..., or what the point of it is, but seems harmless enough.
*/
		for (k = 0; k < t->points+1; k++)
		for (j = i; j < t->points+1; j++)
		{
			if (fake[k][1] < fake[j][1])
			{
				temp = fake[k];
				fake[k] = fake[j];
				fake[j] = temp;
			}
		}

		// throw out the crappy points
/*
* Not sure at all what this does other than cause core dumps.  Probably the intention was
* to throw out points that were too close, but the new count (num) never gets used again,
* leading to the possibility of acessing unassigned Point pointers.
* Besides, FindBrightestPoints seems to check t->dist anyway...
*/
		num = 0;
		for (k = 0; k < t->points+1; k++) {
			//ReadDVImage(t->infp,&img,t->head,fake[k][0],0,i);
			//q = crossVerify(img, N(fake[k][3],fake[k][4],img), t->size);
			//fprintf(stderr,"I:%d\n",q);
			//if (q<0)
			//fake[k] = NULL;
			//else
/*
			cont = FALSE;
			if (!fake[k][1]) continue;
			for (q = 0; q < num; q++)
				if (dist2d(fake[k][3], fake[k][4], Points[q][3], Points[q][4])
				<= t->dist) cont = TRUE;
			if (cont) continue;
*/
			Points[num++] = fake[k];
		}
		//for (k=num;k < t->points+1;k++)
		//Points[k] = NULL;

		if (abort)
		{
			if (!t->brief)
			{
			fprintf( stderr, "Error! Skipping this round..\n" );
			}
			else 
			{
			fprintf( stderr, "%d, 0, 0, 0, 0, 0, 0, 0\n",
				i+1 );
			}
		}
		else
		{
		int j;
		long featureID;
/*
			fprintf( t->outfp, "Time %d\n", i+1 );
			for (int j = 0; j < t->points; j++ )
				fprintf( t->outfp, "%d) Z: %d V: %d J: %d X: %d, Y: %d\n",
					j+1, Points[j][0]+1, Points[j][1], Points[j][2], 
					Points[j][3]+1, Points[j][4]+1 );
*/
			
			if (t->points == 3)
			{
				float a[3], temp;
				int pos[3]={2,0,1}, tmp;
#ifdef DEBUG
fprintf (stdout,"...3 points");
fflush (stdout);
#endif
				a[0] = dist3d( Points[0][3], Points[0][4], Points[0][0],
					Points[1][3], Points[1][4], Points[1][0], t->head );
#ifdef DEBUG
fprintf (stdout,"...a[0]=%5.3f",a[0]);
fflush (stdout);
#endif
				a[1] = dist3d( Points[2][3], Points[2][4], Points[2][0],
					Points[1][3], Points[1][4], Points[1][0], t->head );
#ifdef DEBUG
fprintf (stdout,"...a[1]=%5.3f",a[1]);
fflush (stdout);
#endif
				a[2] = dist3d( Points[0][3], Points[0][4], Points[0][0],
					Points[2][3], Points[2][4], Points[2][0], t->head );
#ifdef DEBUG
fprintf (stdout,"...a[2]=%5.3f",a[2]);
fflush (stdout);
#endif
				if (a[0] > a[1]) { temp = a[0]; a[0] = a[1]; a[1] = temp; 
					pos[0] = 0; pos[1] = 2; }
				if (a[1] > a[2]) { temp = a[1]; a[1] = a[2]; a[2] = temp; 
					tmp = pos[2]; pos[2] = pos[1]; pos[1] = tmp; }
				if (a[0] > a[1]) { temp = a[0]; a[0] = a[1]; a[1] = temp; 
					tmp = pos[0]; pos[0] = pos[1]; pos[1] = tmp; }
				temp = (2*a[0]*a[0]*a[1]*a[1]
						+ 2*a[2]*a[2]*a[1]*a[1]
						+ 2*a[0]*a[0]*a[2]*a[2] 
						- a[0]*a[0]*a[0]*a[0] 
						- a[1]*a[1]*a[1]*a[1] 
						- a[2]*a[2]*a[2]*a[2] );
				if (temp < 0) temp = -temp;
				temp = sqrtf(temp) / (2*a[2]);
/*
				fprintf( t->outfp, "Distance from spot (Point %d) to axis: %f\n",
					pos[2]+1, temp );
*/
#ifdef DEBUG
fprintf (stdout,"...adding features\n");
fflush (stdout);
#endif
				for (j = 0; j < t->points; j++ )
				{
					featureID = OME_Add_Feature (t->dbHandle,t->analysisID);
					sprintf (values,"%d,%d,%d",Points[j][3],Points[j][4],Points[j][0]);
					OME_Add_Attribute_Values (t->dbHandle,featureID,t->analysisID,
						"LOCATION","X,Y,Z",values);

					sprintf (values,"%d",i);
					OME_Add_Attribute_Values (t->dbHandle,featureID,t->analysisID,
						"TIMEPOINT","TIMEPOINT",values);

					if (j == pos[2])
						sprintf (values,"%f",temp);
					else
						sprintf (values,"%f",0.0);
					OME_Add_Attribute_Values (t->dbHandle,featureID,t->analysisID,
						"DISTANCE_TO_SPINDLE_AXIS","DISTANCE",values);
				}
			}
			else
				for (j = 0; j < t->points; j++ )
				{
					featureID = OME_Add_Feature (t->dbHandle,t->analysisID);
					sprintf (values,"%d,%d,%d",Points[j][3],Points[j][4],Points[j][0]);
					OME_Add_Attribute_Values (t->dbHandle,featureID,t->analysisID,
						"LOCATION","X,Y,Z",values);

					sprintf (values,"%d",i);
					OME_Add_Attribute_Values (t->dbHandle,featureID,t->analysisID,
						"TIMEPOINT","TIMEPOINT",values);

				}

		}

		for (j = 0; j < t->points+1; j++)
			free(fake[j]);
		free(Points);
		free(fake);
		}
/*
	fclose (t->outfp);
*/
	fclose (t->infp);
	OME_DB_Finish (t->dbHandle);
}


/*
* Main calls make_task to make a task structure from
* the command line arguments, then calls run_task to actually run the task.
* After running the task, Main parses the output in the output file and sends it to
* the OME database.
* There are two possible output format - either 3 points or not 3 points.
* not three point:
* Time	X	Y	Z
* Three point
* Time	X	Y	Z	Dist
* Time is the timepoint, Dist is the distance between the point and the "spindle-pole-axis", which
* is the defined to be between the two points furthest apart from each other.
*/

int main (int argc, char *argv[])
{
TASK *task;

	task = make_task (argc,argv);
	run_task (task);
	return (task->analysisID);
}
