/**************************************************************************

  Linear curve fitting.

  That is, find the parameters a_i such that:

  y = Sum_i a_i f_i(x) is a good fit to presented x,y data.

  See Numerical Receipes section 15.4.
  
*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "fit_linear.h"

#define OK      FIT_OK
#define FATAL   FIT_FATAL

#define SQ(a) ((a)*(a))
#define SIGN(a,b) ((b) > 0.0 ? fabs(a) : - fabs(a))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) <= (b) ? (a) : (b))

/* matrix workspace */
static double *b = 0 ;
static double *w = 0 ;
static double *f = 0 ;
static double **u = 0 ;
static double **v = 0 ;
static double **cvm = 0 ;

#define N_CHUNK 100
#define O_CHUNK 10

/* yfit workspace */
static const int *yfit_do = 0 ;
static int yfit_n = 0 ;

/**************************************************************************

  Failure returning integer.
  
*/
static fit_rc punt(int line, const char *id, const char *msg) {

  printf("* %s [%s:%d]: %s\n",id,__FILE__,line,msg) ;
  return(FATAL) ;
}

/**************************************************************************

  Memory failure returning integer.
  
*/
static fit_rc memfail(int line, const char *id) {

  printf("* %s [%s:%d]: couldn\'t allocate memory.\n",id,__FILE__,line) ;
  return(FATAL) ;
}

/*************************************************************************

  Allocate memory.

*/
static int check_memory(int o, int n) {

  static double *udat = 0 ;
  static double *vdat = 0 ;
  static double *cvmdat = 0 ;
  static int osz = 0 ;
  static int nsz = 0 ;
  int ow,nw,i ;
  const char *me = "check_memory" ;

  ow = osz ;
  if (o > osz) {
    ow = MAX(o,osz + O_CHUNK) ;
    if (!(vdat   = (double * )realloc(vdat,ow*ow * sizeof(double  ))) ||
	!(v      = (double **)realloc(v,ow * sizeof(double *))) ||
	!(w      = (double * )realloc(w,ow * sizeof(double  ))) ||
	!(f      = (double * )realloc(f,ow * sizeof(double  ))) ||
	!(cvmdat = (double * )realloc(cvmdat,ow*ow * sizeof(double  ))) ||
	!(cvm    = (double **)realloc(cvm,ow * sizeof(double *))) )
      return(memfail(__LINE__,me)) ;
    for(i=0;i<ow;i++) v[i] = vdat + i*ow ;
    for(i=0;i<ow;i++) cvm[i] = cvmdat + i*ow ;
  } ;
  nw = nsz ;
  if (n > nsz) {
    nw = MAX(n,nsz + N_CHUNK) ;
    if (!(b = (double * )realloc(b,nw * sizeof(double  ))) ||
	!(u = (double **)realloc(u,nw * sizeof(double *))) )
      return(memfail(__LINE__,me)) ;
  } ;
  if ((ow != osz) || (nw != nsz)) {
    if (!(udat   = (double * )malloc(nw*ow * sizeof(double))))
      return(memfail(__LINE__,me)) ;
    for(i=0;i<nw;i++) u[i] = udat + i*ow ;
  } ;
  osz = ow ; nsz = nw ;
  return(OK) ;
}

/**************************************************************************

  NR routine to do sqrt(a^2 + b^2)
  
*/
static double dpythag(double a, double b) {

  a = fabs(a) ; b = fabs(b) ;
  if (a > b) return a*sqrt(1.0+SQ(b/a)) ;
  return (b == 0.0 ? 0.0 : b*sqrt(1.0+SQ(a/b))) ;
}

/**************************************************************************

  Back substitution after SVD: solves for x in A . x = b, assuming
  A has been decomposed into u,v and w by svdcmp.
  
*/
static int svbksb(double *x, int m, int n) {

  int jj,j,i;
  double s,*tmp;
  const char *me = "svbksb" ;

  if (!(tmp = (double *)malloc(n*sizeof(double))))
    return(punt(__LINE__,me,"can\'t allocate buffer.")) ;
  for (j=0;j<n;j++) {
    s=0.0;
    if (w[j]) {
      for (i=0;i<m;i++) s += u[i][j]*b[i];
      s /= w[j];
    }
    tmp[j]=s;
  }
  for (j=0;j<n;j++) {
    s=0.0;
    for (jj=0;jj<n;jj++) s += v[j][jj]*tmp[jj];
    x[j]=s;
  }
  free(tmp) ;
  return(OK) ;
}

/**************************************************************************

  Does singular value decomposition on m x n matrix a, 
  returning m x n matrix u in a, n x n matrices v, and in w the
  n diagonal elements of an n x n diagonal matrix wm, such that 

   a = u . wm . vT   -and-  uT.u = 1   -and-  vT.v = 1
  
*/
static int svdcmp(double **a, int m, int n) {

  double *rv1 ;
  double anorm,c,f,g,h,s,scale,x,y,z ;
  int flag,i,its,j,jj,k,l,nm;
  const char *me = "svdcmp" ;

  if (!(rv1 = (double *)malloc(n*sizeof(double))))
    return(punt(__LINE__,me,"can\'t allocate buffer.")) ;
  g=scale=anorm=0.0;
  for(i=0;i<n;i++) {
    l=i+1;
    rv1[i]=scale*g;
    g=s=scale=0.0;
    if (i<m) {
      for (k=0;k<m;k++) scale += fabs(a[k][i]);
      if (scale) {
	for (k=i;k<m;k++) {
	  a[k][i] /= scale;
	  s += a[k][i]*a[k][i];
	}
	f=a[i][i];
	g = -SIGN(sqrt(s),f);
	h=f*g-s;
	a[i][i]=f-g;
	for (j=l;j<n;j++) {
	  for (s=0.0,k=i;k<m;k++) s += a[k][i]*a[k][j];
	  f=s/h;
	  for (k=i;k<m;k++) a[k][j] += f*a[k][i];
	}
	for (k=i;k<m;k++) a[k][i] *= scale;
      }
    }
    w[i]=scale*g;
    g=s=scale=0.0;
    if (i < m && i < n) {
      for (k=l;k<n;k++) scale += fabs(a[i][k]);
      if (scale) {
	for (k=l;k<n;k++) {
	  a[i][k] /= scale;
	  s += a[i][k]*a[i][k];
	}
	f=a[i][l];
	g = -SIGN(sqrt(s),f);
	h=f*g-s;
	/* hmm */
	a[i][l]=f-g;
	for (k=l;k<n;k++) rv1[k]=a[i][k]/h;
	for (j=l;j<m;j++) {
	  for (s=0.0,k=l;k<n;k++) s += a[j][k]*a[i][k];
	  for (k=l;k<n;k++) a[j][k] += s*rv1[k];
	}
	for (k=l;k<n;k++) a[i][k] *= scale;
      }
    }
    anorm=MAX(anorm,(fabs(w[i])+fabs(rv1[i])));
  }
  for (i=n-1;i>=0;i--) {
    if (i < n-1) {
      if (g) {
	for (j=l;j<n;j++) v[j][i]=(a[i][j]/a[i][l])/g;
	for (j=l;j<n;j++) {
	  for (s=0.0,k=l;k<n;k++) s += a[i][k]*v[k][j];
	  for (k=l;k<n;k++) v[k][j] += s*v[k][i];
	}
      }
      for (j=l;j<n;j++) v[i][j]=v[j][i]=0.0;
    }
    v[i][i]=1.0;
    g=rv1[i];
    l=i;
  }
  for (i=MIN(m,n)-1;i>=0;i--) {
    l=i+1;
    g=w[i];
    for (j=l;j<n;j++) a[i][j]=0.0;
    if (g) {
      g=1.0/g;
      for (j=l;j<n;j++) {
	for (s=0.0,k=l;k<m;k++) s += a[k][i]*a[k][j];
	f=(s/a[i][i])*g;
	for (k=i;k<m;k++) a[k][j] += f*a[k][i];
      }
      for (j=i;j<m;j++) a[j][i] *= g;
    } else for (j=i;j<m;j++) a[j][i]=0.0;
    ++a[i][i];
  }
  for (k=n-1;k>=0;k--) {
    for (its=0;its<30;its++) {
      flag=1;
      for (l=k;l>=0;l--) {
	nm=l-1;
	if ((double)(fabs(rv1[l])+anorm) == anorm) {
	  flag=0;
	  break;
	}
	if ((double)(fabs(w[nm])+anorm) == anorm) break;
      }
      if (flag) {
	c=0.0;
	s=1.0;
	for (i=l;i<=k;i++) {
	  f=s*rv1[i];
	  rv1[i]=c*rv1[i];
	  if ((double)(fabs(f)+anorm) == anorm) break;
	  g=w[i];
	  h=dpythag(f,g);
	  w[i]=h;
	  h=1.0/h;
	  c=g*h;
	  s = -f*h;
	  for (j=0;j<m;j++) {
	    y=a[j][nm];
	    z=a[j][i];
	    a[j][nm]=y*c+z*s;
	    a[j][i]=z*c-y*s;
	  }
	}
      }
      z=w[k];
      if (l == k) {
	if (z < 0.0) {
	  w[k] = -z;
	  for (j=0;j<n;j++) v[j][k] = -v[j][k];
	}
	break;
      }
      if (its == 29) 
	return(punt(__LINE__,me,"no convergence in 30 iterations")) ;
      x=w[l];
      nm=k-1;
      y=w[nm];
      g=rv1[nm];
      h=rv1[k];
      f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
      g=dpythag(f,1.0);
      f=((x-z)*(x+z)+h*((y/(f+SIGN(g,f)))-h))/x;
      c=s=1.0;
      for (j=l;j<=nm;j++) {
	i=j+1;
	g=rv1[i];
	y=w[i];
	h=s*g;
	g=c*g;
	z=dpythag(f,h);
	rv1[j]=z;
	c=f/z;
	s=h/z;
	f=x*c+g*s;
	g = g*c-x*s;
	h=y*s;
	y *= c;
	for (jj=0;jj<n;jj++) {
	  x=v[jj][j];
	  z=v[jj][i];
	  v[jj][j]=x*c+z*s;
	  v[jj][i]=z*c-x*s;
	}
	z=dpythag(f,h);
	w[j]=z;
	if (z) {
	  z=1.0/z;
	  c=f*z;
	  s=h*z;
	}
	f=c*g+s*y;
	x=c*y-s*g;
	for (jj=0;jj<m;jj++) {
	  y=a[jj][j];
	  z=a[jj][i];
	  a[jj][j]=y*c+z*s;
	  a[jj][i]=z*c-y*s;
	}
      }
      rv1[l]=0.0;
      rv1[k]=f;
      w[k]=x;
    }
  }
  free(rv1) ;
  return(OK) ;
}

/**************************************************************************

  NR variance calculation for fitting parameters.
  
*/
static int svdvar(int ma) {

  int k,j,i;
  double sum,*wti;
  const char *me = "svdvar" ;

  if (!(wti = (double *)malloc(ma * sizeof(double))))
    return(punt(__LINE__,me,"can\'t allocate workspace.")) ;
  for (i=0;i<ma;i++) {
    wti[i]=0.0;
    if (w[i]) wti[i]=1.0/(w[i]*w[i]);
  }
  for (i=0;i<ma;i++) {
    for (j=0;j<=i;j++) {
      for (sum=0.0,k=0;k<ma;k++) sum += v[i][k]*v[j][k]*wti[k];
      cvm[j][i]=cvm[i][j]=sum;
    }
  }
  free(wti) ;
  return(OK) ;
}

/******************************************************************************

  General linear least squares fit routine 
  from section 15.4 of Numerical Recipes.

  yfit(x) = function which fills f[i],i=0..o-1 with the o 
            fitting functions evaluated at x.
  fom = if nonzero figure-of-merit is returned here.	    
  a  = fitting parameters
  av = if (av) error variances for the fitting parameters returned here.
  x  = n abscissas
  y  = n ordinates
  ys = if (ys) = n error standard deviations for y values
  tol = smallest fraction of maximum singular value (eigenvalues, roughly) 
        which a small singular value can equal -- smaller values are
        set to zero, assumed to indicate redundancy.  NR suggests
        of order 10^-6
  n = number of abscissas.
  o = number of fitting parameters.

  */
static fit_rc fit_lsq(void (*yfit)(), double *fom, double *a, double *av,
		      const double *x, const double *y, const double *ys,
		      double tol, int n, int o) {

  double wmax,wmin,xsq,sum ;
  int i,j ;
  const char *me = "fit_lsq" ;

  if (check_memory(o,n) != OK) return(memfail(__LINE__,me)) ;

  for(i=0;i<n;i++) {
    yfit(x[i]) ;
    for(j=0;j<o;j++) u[i][j] = f[j] * (ys ? 1.0/ys[i] : 1.0) ;
  } ;
  memcpy(b,y,n*sizeof(double)) ;
  if (ys) for(i=0;i<n;i++) b[i] /= ys[i] ;

  if (svdcmp(u,n,o) != OK)
    return(punt(__LINE__,me,"singular value decomposition failed.")) ;

  wmax = 0.0 ;
  for(wmax=0.0,j=0;j<o;j++) if (w[j] > wmax) wmax = w[j] ;
  wmin = tol * wmax ;
  for(j=0;j<o;j++) if (w[j] < wmin) w[j] = 0.0 ;
  
  if (svbksb(a,n,o) != OK) 
    return(punt(__LINE__,me,"back substitution failed.")) ;

  if (av) {
    if (svdvar(o) != OK)
      return(punt(__LINE__,me,"variance calculation failed.")) ;
    for(i=0;i<o;i++) av[i] = cvm[i][i] ;
  } ;
  if (fom) {
    xsq = 0.0 ;
    for(i=0;i<o;i++) {
      yfit(x[i]) ;
      sum = 0.0 ;
      for(j=0;j<o;j++) sum += a[j] * f[j] ;
      sum = (y[i] - sum)/(ys ? ys[i]*ys[i] : 1.0) ;
      xsq += sum*sum ;
    } ;
    *fom = xsq ;
  } ;
  
  return(OK) ;
}

/**************************************************************************

  Fitting function: polynomial.

*/
static void yfit_poly(double x) {

  double y ;
  int j,k ;

  y = 1.0 ; k = 0 ;
  for(j=0;j<=yfit_n;j++) {
    if (!yfit_do || yfit_do[j]) f[k++] = y ;
    y *= x ;
  } ;
}

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
fit_rc fit_poly(double *a, 
		const double *x, const double *y, const double *ys,
		const int *dolist, 
		double tol, int n, int o) {

  int i,m ;
  fit_rc check ;

  yfit_n = o ;
  yfit_do = dolist ;
  m = o+1 ;
  if (yfit_do) for(m=0,i=0;i<=o;i++) if (yfit_do[i]) m += 1 ;
  
  check = fit_lsq(yfit_poly,0,a,0,x,y,ys,tol,n,m) ;

  return(check) ;
}

/**************************************************************************

  Fitting function: Legendre polynomials.

*/
static void yfit_legendre(double x) {

  double fm2,fm1,fm0,f2,f1,d ;
  int j,k ;

  k = 0 ;
  if (!yfit_do || yfit_do[0]) f[k++] = 1.0 ;
  if (yfit_n < 1) return ;
  if (!yfit_do || yfit_do[1]) f[k++] = x ;
  if (yfit_n < 2) return ;
  fm2 = 1.0 ; fm1 = x ;
  f2 = x ; d = 1.0 ;
  for(j=2;j<=yfit_n;j++) {
    f1 = d ;
    f2 = f2 + 2.0 * x ;
    d += 1.0 ;
    fm0 = (f2 * fm1 - f1 * fm2)/d ;
    if (!yfit_do || yfit_do[j]) f[k++] = fm0 ;
    fm2 = fm1 ;
    fm1 = fm0 ;
  } ;
}

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
fit_rc fit_legendre(double *a, 
		    const double *x, const double *y, const double *ys,
		    const int *dolist, 
		    double tol, int n, int o) {

  int i,m ;
  fit_rc check ;

  yfit_n = o ;
  yfit_do = dolist ;
  m = o+1 ;
  if (yfit_do) for(m=0,i=0;i<=o;i++) if (yfit_do[i]) m += 1 ;
  
  check = fit_lsq(yfit_legendre,0,a,0,x,y,ys,tol,n,m) ;

  return(check) ;
}
