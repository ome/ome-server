/****************************************************************************/
/*                                                                          */
/*                                                                          */
/*                              mb_Znl.c                                    */
/*                                                                          */
/*                                                                          */
/*                           Michael Boland                                 */
/*                            09 Dec 1998                                   */
/*                                                                          */     
/*  Revisions:                                                              */
/*  9-1-04 Tom Macura <tmacura@nih.gov> modified to make the code ANSI C    */
/*         and work with included complex arithmetic library from           */
/*         Numerical Recepies in C instead of using the system's C++ STL    */
/*         Libraries.                                                       */
/*                                                                          */
/****************************************************************************/


#include "mex.h"
#include "matrix.h"
#include <math.h>
#include <sys/types.h>
#include "complex.h"

#define row 0
#define col 1

/*
	Calculates n! (uses double arithmetic to avoid overflow)
*/
double factorial(double n)
{
	if(n < 0)
		return(0.0) ;
	if(n == 0.0)
		return(1.0) ;
	else
		return(n * factorial(n-1.0)) ;
}	


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{

  int n ;                     /* degree (n) of the Zernike moment */
  int l ;                     /* angular dependence of the moment */
  double* X ;                 /* list of X coordinates of pixels */
  double* Y ;                 /* list of Y coordinates of pixels */
  double* P ;                 /* list of values of pixels */
  int outputsize[2] = {1,1} ; /* Dimensions of return variable */
  register double x, y, p ;   /* individual values of X, Y, P */
  int i ;
  fcomplex sum ;              /* Accumulator for complex moments */
  fcomplex Vnl ;              /* Inner sum in Zernike calculations */
  double* preal ;             /* Real part of return value */
  double* pimag ;             /* Imag part of return value */
  int m ;



  if (nrhs != 5) {
    mexErrMsgTxt("\n MB_Znl(N, L, X, Y, P),\n"
     "     Zernike moment generating function.  The moment of degree n and \n" 
     "     angular dependence l for the pixels defined by coordinate vectors\n"
     "     X and Y and intensity vector P.  X, Y, and P must have the same\n"
     "     length.") ;

  } else if (nlhs != 1) {
    mexErrMsgTxt("mb_Znl returns a single output.\n") ;
  }

  if ( !mxIsNumeric(prhs[0]) || (mxGetM(prhs[0]) != 1) || 
      (mxGetN(prhs[0]) != 1) ) {
    mexErrMsgTxt("The first argument (n) should be a scalar\n") ;
  }

  if ( !mxIsNumeric(prhs[1]) || (mxGetM(prhs[1]) != 1) || 
      (mxGetN(prhs[1]) != 1) ) {
    mexErrMsgTxt("The second argument (l) should be a scalar\n") ;
  }

  if ( !mxIsNumeric(prhs[2]) || (mxIsComplex(prhs[2])) ) {
    mexErrMsgTxt("The 3d argument (X) should be numeric and not complex.");
  }

  if ( !mxIsNumeric(prhs[3]) || (mxIsComplex(prhs[3])) ) {
    mexErrMsgTxt("The 3d argument (Y) should be numeric and not complex.");
  }

  if ( !mxIsNumeric(prhs[4]) || (mxIsComplex(prhs[4])) ) {
    mexErrMsgTxt("The 3d argument (P) should be numeric and not complex.");
  }

  if (mxGetM(prhs[2])!=mxGetM(prhs[3]) || 
      (mxGetM(prhs[3])!=mxGetM(prhs[4]))){
    mexErrMsgTxt("X, Y, and P must have the same number of rows.") ;
  }

  if (mxGetM(prhs[2]) < mxGetM(prhs[2])) {
    mexErrMsgTxt("X, Y, and P should be column vectors.") ;
  }

  n = (int)mxGetScalar(prhs[0]) ;
  l = (int)mxGetScalar(prhs[1]) ;

  X = mxGetPr(prhs[2]) ;
  Y = mxGetPr(prhs[3]) ;
  P = mxGetPr(prhs[4]) ;
  sum.r = 0.0;
  sum.i = 0.0;
  for(i = 0 ; i < mxGetM(prhs[2]) ; i++) {
    x = X[i] ;
    y = Y[i] ;
    p = P[i] ;
    
    Vnl.r = 0.0;
    Vnl.i = 0.0;
    for( m = 0; m <= (n-l)/2; m++) {
      double tmp = (pow((double)-1.0,(double)m)) * ( factorial(n-m) ) / 
				( factorial(m) * (factorial((n - 2.0*m + l) / 2.0)) *
	  			(factorial((n - 2.0*m - l) / 2.0)) ) *
				( pow( sqrt(x*x + y*y), (double)(n - 2*m)) );
	  
	  Vnl = Cadd (Vnl, RCmul(tmp, Rpolar(1.0, l*atan2(y,x))) );
      /*
       NOTE: This function did not work with the following:
        ...pow((x*x + y*y), (double)(n/2 -m))...
        perhaps pow does not work properly with a non-integer
        second argument.
       'not work' means that the output did not match the 'old'
        Zernike calculation routines.
      */
    }
    
    /* sum += p * conj(Vnl) ; */
	sum = Cadd(sum, RCmul(p, Conjg(Vnl)));
  }

  /* sum *= (n+1)/3.14156 ; */
  sum = RCmul((n+1)/3.14156, sum);
  

  /* Assign the returned value */

  plhs[0] = mxCreateNumericArray(2, outputsize, mxDOUBLE_CLASS, mxCOMPLEX) ;
  preal = mxGetPr(plhs[0]) ;
  pimag = mxGetPi(plhs[0]) ;

  preal[0] = sum.r ;
  pimag[0] = sum.i ;

}

