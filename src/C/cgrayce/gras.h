/****************************************************************************/
/*                                                                          */
/*      gras.h                                                              */
/*   header file to accompany gras.c                                        */
/*                                                                          */
/*     Grayscale rasters.                                                   */
/*                                                                          */
/*     A grayscale raster is a rectangular array of numbers, such as one    */
/*     would use to represent a graylevel image.                            */
/*                                                                          */
/*     For nonrectangular arrays see obj.h.                                 */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Cristopher Grayce                                     */
/*     This file is part of OME.                                            */
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
/*                                                                          */
/****************************************************************************/

#ifndef _GRAS_
#define _GRAS_

#include "util.h"

/* A generic unsigned integer raster structure */
typedef struct {
  int nx ;                    /* columns */
  int ny ;                    /* rows */
  int nxmax ;                 /* max columns */
  int nymax ;                 /* max rows */
  unsigned max ;              /* max value */
  unsigned min ;              /* min value */
  unsigned *data ;            /* data */
  unsigned **ras ;            /* ras[i][j] = data in i'th row, j'th col */
} gras_t ;

/* A generic floating point raster structure */
typedef struct {
  int nx ;                    /* columns */
  int ny ;                    /* rows */
  int nxmax ;                 /* max columns */
  int nymax ;                 /* max rows */
  double max ;                /* max value */
  double min ;                /* min value */
  double *data ;              /* data */
  double **ras ;              /* ras[i][j] = data in i'th row, j'th col */
} fras_t ;

/******************************************************************************

  Initializers.

  */
extern rc_t gras_init(gras_t *gr, int ny, int nx) ;
extern rc_t fras_init(fras_t *fr, int ny, int nx) ;

/******************************************************************************

  Free raster.

  */
extern void gras_free(gras_t *gr) ;
extern void fras_free(fras_t *gr) ;

/******************************************************************************

  Verify space exists  for nx x ny data.

  */
extern rc_t gras_chksz(gras_t *gr, int ny, int nx) ;
extern rc_t fras_chksz(fras_t *fr, int ny, int nx) ;

/******************************************************************************

  Calculate max and min.

  */
extern void gras_maxmin(gras_t *gr) ;
extern void fras_maxmin(fras_t *fr) ;

/******************************************************************************

  Return mean and perhaps variance of data.

  */
extern double gras_mean(const gras_t *gr, double *var) ;
extern double fras_mean(const fras_t *fr, double *var) ;

/******************************************************************************

  Return minimum depth (bits/entry) needed to store an integer
  raster, assuming only an integral number of bytes of bits is permissible.   
  That is, the depth returned is always a multiple of 8.

  */
extern int gras_depth(const gras_t *gr) ;

/******************************************************************************

  Construct lists of y and x coordinates for the 8 or less nearest 
  neighbors of the pixel at (y,x) in raster gr.  

  Returns number in list.

  => There can be < 8 neighbors when the pixel is in a corner or near 
     an edge.

  */
extern int gras_nn8(const gras_t *gr, int *ylist, int *xlist, int y, int x) ;
  
/******************************************************************************

  Mark pixels in gr_mk if their gray values in gr are >= min and < max.

  */
extern rc_t gras_mark_gray(const gras_t *gr, gras_t *gr_mk, 
			   unsigned min, unsigned max) ;
  
/******************************************************************************

  Mark pixels as background 
  if they sit in square patches of side length 2*hpsz+1 with
  intensity distributions less than sdmax standard deviations different
  from the average `background' intensity distribution.  Determine
  the `background' intensity distribution by fitting a Gaussian to the
  largest amplitude peak in the intensity histogram.

  */
extern rc_t gras_mark_prob(const gras_t *gr, gras_t *gr_mk, 
			   int hpsz, double sdmax) ;
  
/******************************************************************************

  Copy raster gr_src to raster gr_dst, 
  enhancing contrast by linear stretching.

  */
extern rc_t gras_con_lin(gras_t *gr_dst, const gras_t *gr_src, int bits) ;

/******************************************************************************

  Paint things on rasters.

*/
extern void gras_paint_number(gras_t *gr, int y, int x, int num) ;
extern void gras_paint_vline(gras_t *gr, int x0, int g) ;
extern void gras_paint_grid(gras_t *gr, int y0, int x0, int dy, int dx, int g);

#endif




