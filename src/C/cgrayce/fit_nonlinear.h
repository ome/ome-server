/*************************************************************************

  Nonlinear curve fitting.

  That is, find the parameters a_i such that:

  y = Sum_i f_i(x ; a_i) is a good fit to presented x,y data.

  See Numerical Receipes section 15.5.

*/
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
