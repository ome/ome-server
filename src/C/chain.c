/*	Common routines for the Alpha image processing system		*/

#include <stdio.h>
#include <math.h>

/* The image header data structure	*/
struct header {
	int nr, nc;		/* Rows and columns in the image */
	int color;		/* Is this a color image? */
	unsigned char red[256], green[256], blue[256]; /* Color map */
};

/*	The IMAGE data structure	*/
struct image {
		struct header *info;		/* Pointer to header */
		unsigned char **data;		/* Pixel values */
};

#define SQRT2 1.414213562
#define PI 3.1415926535

/*	Return TRUE (1) if (n,m) are legal pixel coordinates
	for the image X, and return FALSE (0) otherwise.	*/

int range (struct image *x, int n, int m)
{
/*	Return 1 if (n,m) are legal (row,column) indices for image X	*/

	if (n < 0 || n >= x->info->nr) return 0;
	if (m < 0 || m >= x->info->nc) return 0;
	return 1;
}

/*	Compute the chain code of the object beginning at pixel (i,j).
	Return the code as NN integers in the array C.			*/

void chain8 (struct image *x, int *c, int i, int j, int *nn)
{
	int val,n,m,q,r, di[9],dj[9],ii, d, dii;
	int lastdir, jj;

/*	Table given index offset for each of the 8 directions.		*/
	di[0] = 0;	di[1] = -1;	di[2] = -1;	di[3] = -1;
	dj[0] = 1;	dj[1] = 1;	dj[2] = 0;	dj[3] = -1;
	di[4] = 0;	di[5] = 1;	di[6] = 1;	di[7] = 1;
	dj[4] = -1;	dj[5] = -1;	dj[6] = 0;	dj[7] = 1;

	for (ii=0; ii<200; ii++) c[ii] = -1;	/* Clear the code table */
	val = x->data[i][j];	n = 0;	/* Initialize for starting pixel */
	q = i;	r = j;  lastdir = 4;

	do {
	   m = 0;
	   dii = -1;	d = 100;
	   for (ii=lastdir+1; ii<lastdir+8; ii++) {	/* Look for next */
	      jj = ii%8;
	      if (range(x,di[jj]+q, dj[jj]+r))
		if ( x->data[di[jj]+q][dj[jj]+r] == val) {
		   dii = jj;	m = 1;
		   break;
		} 
	   }

	   if (m) {	/* Found a next pixel ... */
	   	if (n<200) c[n++] = dii;	/* Save direction as code */
	   	q += di[dii];	r += dj[dii];
	   	lastdir = (dii+5)%8;
	   } else break;	/* NO next pixel */
	   if (n>200) break;
	} while ( (q!=i) || (r!=j) );	/* Stop when next to start pixel */

	*nn = n;
}

/*	Compute and return the perimeter of a region from its chain code    */

float ccperim (int *c, int n)
{
	int i;
	float p;

	p = 0;
	for (i=0; i<n; i++)
	   if (c[i]%2) p = p + SQRT2;
	   else p = p + 1.0;
	return p;
}

/*	Compute the area given the chain code.		*/

float ccarea (int *c, int n)
{
	int i,x,y;
	float a;

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
	printf ("Chain code area is %10.4f (%d,%d)\n", a, x, y);
}
