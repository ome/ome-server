/****************************************************************************/
/*                                                                          */
/*  fit_linear.h                                                            */
/*                                                                          */
/*  header file to accompany fit_linear.h                                   */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
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

#ifndef _FIT_
#define _FIT_

typedef enum { FIT_OK = 0,
	       FIT_FATAL = -1 } fit_rc ;

/******************************************************************************

  Fit to a polynomial.

  a[i] = i'th fitting parameter
  x,y = n data points
  ys = if !0 n standard deviation errors on y data.
  dolist = if !0 then if (dolist[i] == 1) i'th power of x will be
           included in fit.  If 0 then all powers up to o will be included.
  tol = smallest variation of figure-of-merit considered convergence.
  n = number of data points.
  o = highest power of polynomial included in fit.

  => only if dolist = 0 does a[i] correspond to the coefficient of the
     i'th power of x.  That is, for o=3 we might have:

     dolist = {1,1,1}  or (dolist == 0) => y = a[0] + a[1] x + a[2] x^2

     dolist = {1,0,1}  => y = a[0] + a[1] x^2

     dolist = {0,0,1}  => y = a[0] x^2

  */
extern fit_rc fit_poly(double *a, 
		       const double *x, const double *y, const double *ys,
		       const int *dolist, 
		       double tol, int n, int o) ;

/******************************************************************************

  Fit to a sum of Legendre polynomials.

  a[i] = i'th fitting parameter
  x,y = n data points
  ys = if !0 n standard deviation errors on y data.
  dolist = if !0 then if (dolist[i] == 1) i'th polynomial will be
           included in fit.  If 0 then all up to order o will be included.
  tol = smallest variation of figure-of-merit considered convergence.
  n = number of data points.
  o = highest power of Legendre polynomial included in fit.

  => only if dolist = 0 does a[i] correspond to the coefficient of the
     i'th Legendre polynomial.  That is, for o=3 we might have:

   dolist = {1,1,1}, (dolist == 0) => y = a[0] P0(x) + a[1] P1(x) + a[2] P2(x)

   dolist = {1,0,1}  => y = a[0] P0(x) + a[1] P2(x)

   dolist = {0,0,1}  => y = a[0] P2(x)

  */
extern fit_rc fit_legendre(double *a, 
			   const double *x, const double *y, const double *ys,
			   const int *dolist, 
			   double tol, int n, int o) ;

#endif
