/******************************************************************************

  Nonlinear curve fitting.

  That is, find the parameters a_i such that:

  y = Sum f_i[x ; a_i] is a good fit to presented x,y data.

  See Numerical Receipes section 15.5.

*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "fit_nonlinear.h"

#define OK      FIT_NONL_OK
#define FATAL   FIT_NONL_FATAL
#define NO      FIT_NONL_NO

#define CHUNK 5

/* the figure of merit */
static double xsq ;

/* workspace */
static double *alpha_dat = 0 ;
static double *new_alpha_dat = 0 ;
static double **alpha = 0 ;
static double **new_alpha = 0 ;
static double *beta = 0 ;
static double *new_beta = 0 ;
static double *new_a = 0 ;
static double *dyda = 0 ;

static int yfit_o = 0 ;
static double *yfit_a = 0 ;
static double *yfit_dyda = 0 ;
static int *yfit_i = 0 ;

#define MAX(a,b) ((a) > (b) ? (a) : (b))

/**************************************************************************

  Failure returning integer.
  
*/
static int punt(int rc, int line, const char *id, const char *msg) {

  printf("* %s [%s:%d]: %s\n",id,__FILE__,line,msg) ;
  return(rc) ;
}

/*************************************************************************

  NR Gauss-Jordan elimination.

*/
static int gaussj(double **a, double *b, int m) {

#define GAUSS_CHUNK 20
#define SWAP(a,b) {temp=(a);(a)=(b);(b)=temp;}

  static int *indxc = 0 ;
  static int *indxr = 0 ;
  static int *ipiv = 0 ;
  static int last_m = 0 ;
  int i,icol,irow,j,k,l,ll,want;
  double big,dum,pivinv,temp;
  const char *me = "gaussj" ;

  if (m > last_m) {
    want = MAX(last_m,m+GAUSS_CHUNK) ;
    if (!(indxc = (int *)realloc(indxc,want*sizeof(int))) ||
	!(indxr = (int *)realloc(indxr,want*sizeof(int))) ||
	!(ipiv =  (int *)realloc(ipiv,want*sizeof(int))) )
      return(punt(FATAL,__LINE__,me,"can\'t allocate workspace.")) ;
    last_m = want ;
  } ;
  for (j=0;j<m;j++) ipiv[j]=0;
  for (i=0;i<m;i++) {
    big=0.0;
    for (j=0;j<m;j++)
      if (ipiv[j] != 1)
	for (k=0;k<m;k++) {
	  if (ipiv[k] == 0) {
	    if (fabs(a[j][k]) >= big) {
	      big=fabs(a[j][k]);
	      irow=j;
	      icol=k;
	    } ;
	  } else if (ipiv[k] > 1) 
	    return(punt(FATAL,__LINE__,me,"singular matrix")) ;
	} ;
    ipiv[icol] += 1 ;
    if (irow != icol) {
      for (l=0;l<m;l++) SWAP(a[irow][l],a[icol][l]) ;
      SWAP(b[irow],b[icol]) ;
    }
    indxr[i]=irow;
    indxc[i]=icol;
    if (a[icol][icol] == 0.0) 
      return(punt(FATAL,__LINE__,me,"singular matrix.")) ;
    pivinv=1.0/a[icol][icol];
    a[icol][icol]=1.0;
    for (l=0;l<m;l++) a[icol][l] *= pivinv;
    b[icol] *= pivinv ;
    for (ll=0;ll<m;ll++)
      if (ll != icol) {
	dum=a[ll][icol];
	a[ll][icol]=0.0;
	for (l=0;l<m;l++) a[ll][l] -= a[icol][l]*dum;
	b[ll] -= b[icol]*dum ;
      } ;
  } ;
  for (l=m-1;l>=0;l--) {
    if (indxr[l] != indxc[l])
      for (k=0;k<m;k++)	SWAP(a[k][indxr[l]],a[k][indxc[l]]) ;
  }
  return(OK) ;
}

/*************************************************************************

  Allocate memory.

*/
static int check_memory(int o) {

  static int osz = 0 ;
  int want,i ;
  const char *me = "check_memory" ;

  if (o > osz) {
    want = MAX(o,osz + CHUNK) ;
    if (!(alpha_dat     = (double  *)realloc(alpha_dat,
					 want*want*sizeof(double))) ||
	!(new_alpha_dat = (double  *)realloc(new_alpha_dat,
					 want*want*sizeof(double))) ||
	!(alpha     = (double **)realloc(alpha,want * sizeof(double *))) ||
	!(new_alpha = (double **)realloc(new_alpha,want * sizeof(double *))) ||
	!(beta      = (double  *)realloc(beta,    want * sizeof(double))) ||
	!(new_beta  = (double  *)realloc(new_beta,want * sizeof(double))) ||
	!(new_a     = (double  *)realloc(new_a,   want * sizeof(double))) ||
	!(dyda      = (double  *)realloc(dyda,    want * sizeof(double))) )
      return(punt(FATAL,__LINE__,me,"can\'t allocate workspace.")) ;
    for(i=0;i<o;i++) alpha[i] = alpha_dat + i*o ;
    for(i=0;i<o;i++) new_alpha[i] = new_alpha_dat + i*o ;
    osz = o ;
  } ;
  return(OK) ;
}

/*************************************************************************

  Allocate yfit memory.

*/
static int check_mem_yfit(int o) {

  static int osz = 0 ;
  int want ;
  const char *me = "check_mem_yfit" ;
  
  if (o > osz) {
    want = MAX(o,osz + CHUNK) ;
    if (!(yfit_a = (double *)malloc(o*sizeof(double))) ||
	!(yfit_dyda = (double *)malloc(o*sizeof(double))) ||
	!(yfit_i = (int *)malloc(o*sizeof(int))) )
      return(punt(FATAL,__LINE__,me,"can\'t allocate workspace.")) ;
    osz = o ;
  } ;
  return(OK) ;
}

/*************************************************************************

  NR Levenberg-Marquardt routine, see section 15.5.

*/
static int fit_mrq(double *a, 
		   double (*yfit)(double *dyda, double *a, double x, int o),
		   const double *x, const double *y, const double *sig,
		   int n, int o, int its, double tol) {

  double alamda,ymod,sig2i,dy,wt,new_xsq,dxsq ;
  int i,j,k,itn ;
  const char *me = "fit_mrq" ;

  xsq = 1.0e+30 ; 
  alamda = 0.001 ;
  if (check_memory(o) != OK) return(FATAL) ;
  memcpy(new_a,a,o*sizeof(double)) ;
  for(itn = 0 ; itn < its ; itn++) {
    for(j=0;j<o*o;j++) new_alpha_dat[j] = 0.0 ;
    for(j=0;j<o  ;j++) new_beta[j] = 0.0;
    new_xsq = 0.0 ;
    for (i=0;i<n;i++) {
      ymod = yfit(dyda,new_a,x[i],o) ;
      sig2i = (sig ? 1.0/(sig[i]*sig[i]) : 1.0) ;
      dy=y[i]-ymod;
      for (j=0;j<o;j++) {
	wt=dyda[j]*sig2i;
	for (k=0;k<=j;k++) new_alpha[j][k] += wt*dyda[k];
	new_beta[j] += dy*wt;
      } ;
      new_xsq += dy*dy*sig2i;
    } ;
#ifdef FOO
    printf("%d new_xsq %e diff %e\n",itn,new_xsq,(xsq - new_xsq)/xsq) ;
    printf("new_a = %f %f %f %f %f %f\n",
	   new_a[0],new_a[1],new_a[2],new_a[3],new_a[4],new_a[5]) ;
    printf("alamda = %f\n",alamda) ;
#endif
    for(j=0;j<o;j++) for(k=j+1;k<o;k++) new_alpha[j][k] = new_alpha[k][j];
    if (new_xsq < xsq) {
      dxsq = xsq - new_xsq ;
      if ((dxsq < tol) || dxsq < tol*xsq) break ;
      xsq = new_xsq ;
      memcpy(alpha_dat,new_alpha_dat,o*o*sizeof(double)) ;
      memcpy(beta,new_beta,o*sizeof(double)) ;
      memcpy(a,new_a,o*sizeof(double)) ;
      if (itn) alamda *= 0.1 ;
    } else {
      memcpy(new_alpha_dat,alpha_dat,o*o*sizeof(double)) ;
      memcpy(new_beta,beta,o*sizeof(double)) ;
      alamda *= 10.0 ;
    } ;
    for(j=0;j<o;j++) new_alpha[j][j] *= (1.0 + alamda) ;
    if (gaussj(new_alpha,new_beta,o) != OK)
      return(punt(FATAL,__LINE__,me,"Gauss-Jordan elimination failed.")) ;
    for(j=0;j<o;j++) new_a[j] = a[j] + new_beta[j] ;
  } ;
  if (itn == its) 
    return(punt(NO,__LINE__,me,"no convergence.")) ;
  return(OK) ;
}

/*************************************************************************

  Provide approximation to data via sum of yfit_o/3 Gaussians.

*/
static double yfit_gauss(double *dyda, double *a, double x, int o) {

  double amp,ctr,wid,y,arg,ex,f1 ;
  int i ;

  for(i=0;i<o;i++) yfit_a[yfit_i[i]] = a[i] ;
  
  y = 0.0 ;
  for(i=0;i<yfit_o;i+=3) {
    amp = yfit_a[i] ;
    ctr = yfit_a[i+1] ;
    wid = yfit_a[i+2] ;
    arg = (x - ctr)/wid ;
    ex = exp(-arg*arg) ;
    y += amp*ex ;
    f1 = amp*ex*2.0*arg ;
    yfit_dyda[i] = ex ;
    yfit_dyda[i+1] = f1/wid ;
    yfit_dyda[i+2] = f1*arg/wid ;
  } ;

  for(i=0;i<o;i++) dyda[i] = yfit_dyda[yfit_i[i]] ;

  return(y) ;
}

/******************************************************************************

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
fit_nonl_rc fit_gauss(double *fom, double *amp, double *ctr, double *wid,
		      const int *afrz, const int *cfrz, const int *wfrz,
		      const double *x, const double *y, const double *ysd, 
		      int n, int ng, int itmax, double tol) {

  static double *a = 0 ;
  static int ngsz = 0 ;
  int o,check,i ;
  const char *me = "fit_gauss" ;

  if (ng > ngsz) {
    if (!(a = (double *)malloc(3*ng*sizeof(double))))
      return(punt(FATAL,__LINE__,me,"can\'t allocate workspace.")) ;
    ngsz = ng ;
  } ;
  
  if (check_mem_yfit(3*ng) != OK)
    return(punt(FATAL,__LINE__,me,"can\'t allocate yfit workspace.")) ;

  for(i=0;i<ng;i++) {
    yfit_a[3*i  ] = amp[i] ;
    yfit_a[3*i+1] = ctr[i] ;
    yfit_a[3*i+2] = wid[i] ;
  } ;

  o = 0 ; yfit_o = 0 ;
  for(i=0;i<ng;i++) {
    if (!afrz || !afrz[i]) { yfit_i[o] = yfit_o ; a[o++] = amp[i] ; } ;
    yfit_a[yfit_o++] = amp[i] ;
    if (!cfrz || !cfrz[i]) { yfit_i[o] = yfit_o ; a[o++] = ctr[i] ; } ;
    yfit_a[yfit_o++] = ctr[i] ;
    if (!wfrz || !wfrz[i]) { yfit_i[o] = yfit_o ; a[o++] = wid[i] ; } ;
    yfit_a[yfit_o++] = wid[i] ;
  } ;

  check = fit_mrq(a,yfit_gauss,x,y,ysd,n,o,itmax,tol) ;

  for(i=0;i<o;i++) yfit_a[yfit_i[i]] = a[i] ;

  for(i=0;i<ng;i++) amp[i] = yfit_a[3*i] ;
  for(i=0;i<ng;i++) ctr[i] = yfit_a[3*i+1] ;
  for(i=0;i<ng;i++) wid[i] = yfit_a[3*i+2] ;

  if (fom) *fom = xsq ;
  return(check) ;
}

