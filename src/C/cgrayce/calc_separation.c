/****************************************************************************/
/*                                                                          */
/*   Calc_separation.c                                                      */
/*                                                                          */
/*   Routine and helpers used to calcuate nearest distance between a point  */
/*   in an image and a cell body held in a second image.                    */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/*   Author:  Brian S. Hughes (bshughes@mit.edu)                            */
/*   Copyright 2001 Brian S. Hughes                                         */
/*   This file is part of OME.                                              */
/*                                                                          */
/*                                                                          */ 
/*     OME is free software; you can redistribute it and/or modify          */
/*     it under the terms of the GNU Lesser General Public License as       */
/*     published by the Free Software Foundation; either version 2.1 of     */
/*     the License, or (at your option) any later version.                  */
/*                                                                          */
/*     OME is distributed in the hope that it will be useful,               */
/*     but WITHOUT ANY WARRANTY; without even the implied warranty of       */
/*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        */
/*     GNU General Public License for more details.                         */
/*                                                                          */
/*     You should have received a copy of the GNU General Public License    */
/*     along with OME; if not, write to the Free Software Foundation, Inc.  */
/*        59 Temple Place, Suite 330, Boston, MA  02111-1307  USA           */
/*                                                                          */
/****************************************************************************/


#include <stdio.h>
#include <math.h>

#include "tmcp.h"


#define CHECK_DISTANCE(x_or_y) \
     if (x_or_y >= 0) { \
       if (refpixel[y][x]) { \
	 deltax = x_img-x; \
	 deltay = y_img-y; \
	 distanceInt = (deltax*deltax) + (deltay*deltay); \
	 if (distanceInt < shortestDistance) { \
	   shortestDistance = distanceInt; \
	 } \
       } \
     }


/* local prototypes */
static void calc_sep(int** refpixel, int x, int y, int maxx, int maxy, 
		     int img2, int is_blank, long* signalSump,
		     double* weightedDistancep, int skip_internals);


static int refThreshhold=0;
static int skipped = 0;



int distanceBetween(int imageThreshold, gras_t* gr_tstp, gras_t* gr_refp,
		    long* signalSump, double* weightedDistancep,
		    int* was_blank, int verbosity, int skip_internals)
{
  int   i;
  int   y, x = 0;
  int   ny, nx;
  int   maxx, maxy;
  int   blank = 1;

  int   dn1, dn2;
  int*  refdata;
  int** refpixel;

  int ones = 0, points = 0;

  ny = gr_tstp->ny;
  nx = gr_tstp->nx;

  /* Build [x, y] reference pixel array from reference image. */

  /* 1st allocate a buffer for pixels     */
  if ((refdata = calloc(nx * ny, sizeof(int))) == NULL) {
    return(FALSE);
  }
  /* and buffer to access these pixels in double indexed array format */
  if ((refpixel = calloc(ny, sizeof(int *))) == NULL) {
    return(FALSE);
  }

  /* Fill in y elements of refpixel w/ pntr to their x rasters */
  for (i = 0; i < ny; i++) {
    refpixel[i] = refdata + i*nx;
  }


  for (y = 0; y < ny ; y++) {
    for (x = 0; x < nx; x++) {
      points++;
      dn1 = gr_tstp->ras[y][x];
      if (dn1 > refThreshhold) {
	refpixel[y][x] = 1;
	blank=0;
	ones++;
      }
    }
  }

  if (verbosity == MSG_DEBUG) {
    printf("\t%f%% of reference array set to 1\n", (100*((double)ones/(double)points)));
  }


  /* Now iterate through ref. file, calculating minimal distances
     * between areas in one image file and areas in the other image file */

  maxx = x-1;  // set the boundaries of the image
  maxy = y-1;
  for (y = 0; y < gr_refp->ny ; y++) {
    for (x = 0; x < gr_refp->nx; x++) {
      dn2 = gr_refp->ras[y][x] - imageThreshold;
      /* If corresponding points in both images are of interest ... */
      if (dn2 > 0) {
	  /*if ((dn1 = refpixel[y][x]) > 0) {*/
	  calc_sep(refpixel, x, y, maxx, maxy, dn2, blank, 
		   signalSump, weightedDistancep, skip_internals);
	  /*}  */
      }
    }
  }

  *was_blank = blank;

  if (verbosity == MSG_DEBUG) {
    if (skip_internals) {
      printf("%d points skipped\n", skipped);
    }
  }

  return(TRUE);

}


/* Calculate minimum separation by square counting method.
 * Draw a minimum bounding box around the passed pixel location in
 * the 2nd (analog) image. For any pixels on the box boundary that
 * interesects any part of an object in the 1st (binary) image,
 * calculate the distance between the intersection and the center
 * of the box. Record that distance if it is the minimum so far.
 * After traversing the bounding box's boundary, enlarge the box
 * by one pixel in each direction, and traverse its boundary again.
 * Stop when the width of the box is greater than the minimum separation,
 * or you've run off the edges of the image.
 */

static void calc_sep(int** refpixel, int x_img, int y_img, int maxx, int maxy, 
		     int img2, int is_blank, long* signalSump,
		     double* weightedDistancep, int skip_internals)
{
  int shortestDistance = 2000000000; /* something big to start with */
  int x, y;
  int x_right, x_left, y_top, y_bottom;
  int deltax, deltay;
  int count;
  int iterate = TRUE;
  int distanceInt = shortestDistance;


  if (is_blank == 1) {
    shortestDistance = 0;
    iterate = FALSE;
  }
  else if (refpixel[y_img][x_img] == 1) {
    shortestDistance = 0;
    if (skip_internals) {
      skipped++;
      iterate = FALSE;
      img2 = 0;
    }
  }
  if (iterate) {
    for (count = 1; ((shortestDistance == 2000000000) ||
		     ((count*count)<=shortestDistance )); count++) {
      /* Get box boundaries for this iteration */
      x_right = x_img + count;
      x_left = x_img - count;
      y_top = y_img + count;
      y_bottom = y_img - count;

      /* The next 4 sections of code examine each pixel around the border  */
      /* of the current bounding box. You could collapse much of this code */
      /* into a subroutine which would be called repeatedly, but at the    */
      /* cost of many subroutine call times. Leave it unfolded like this.  */

    /* scan bottom row of box */
      y = y_img - count;
      if (y >= 0) {
	for (x = x_img - count; x <= x_right; x++) {
	  if ( x > maxx) {
	    break;
	  }
	  CHECK_DISTANCE(x);
	}
      }

      /* Scan top row of box */
      y = y_img + count;
      if (y <= maxy) {
	for (x = x_img - count; x <= x_right; x++) {
	  if ( x > maxx) {
	    break;
	  }
	  CHECK_DISTANCE(x);
	}
      }

      /* scan right side of box */
      x = x_img + count;
      if (x <= maxx) {
	for (y = y_img - count; y <= y_top; y++) {
	  if (y > maxy) {
	    break;
	  }
	  CHECK_DISTANCE(y);
	}
      }

      /* and finally scan the left side of the box */
      x = x_img - count;
      if (x >= 0) {
	for (y = y_img - count; y <= y_top; y++) {
	  if (y > maxy) {
	    break;
	  }
	  CHECK_DISTANCE(y);
	}
      }
    }
  }

  *signalSump = *signalSump + img2;
  *weightedDistancep = *weightedDistancep + sqrt(shortestDistance)*img2;


}
