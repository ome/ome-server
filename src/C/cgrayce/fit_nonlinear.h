/****************************************************************************/
/*                                                                          */
/*  fit_nonlinear.h                                                         */
/*                                                                          */
/*  header file to accompany fit_nonlinear.c                                */
/*                                                                          */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
/*     This file is part of OME.                                            */
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

#ifndef _FIT_NONL_
#define _FIT_NONL_

/* some return codes */
typedef enum { 
  FIT_NONL_OK = 0, 
  FIT_NONL_FATAL = -1, 
  FIT_NONL_NO = 1 
} fit_nonl_rc ;

/*************************************************************************

  Fit data to sum of Gaussians.

  fom = if !0 figure-of-merit returned here.
  amp[i] = amplitude of i'th Gaussian. )
  ctr[i] = center of i'th Gaussian.    ) contain initial guesses on entry.
  wid[i] = width of i'th Gaussian.     )
  afrz,cfrz,wfrz = if !0 then if (afrz[i] == 1) amp[i] is frozen, etc.
  x = n abscissas.     
  y = n ordinates.
  ysd = if !0 contains n standard deviation errors in y.
  n = number of points.
  ng = number of Gaussians.
  itmax = max number of iterations to try.
  tol = largest relative change in fom to accept as convergence.

*/
extern fit_nonl_rc fit_gauss(double *fom, 
			     double *amp, double *ctr, double *wid,
			     const int *afrz, const int *cfrz, const int *wfrz,
			     const double *x, const double *y, 
			     const double *ysd, 
			     int n, int ng, int itmax, double tol) ;

#endif
