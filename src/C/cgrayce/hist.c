/************************************************************************

  Grayvalue histograms.

  Plots of number of grayvalues versus grayvalue.

  */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "util.h"
#include "gras.h"
#include "fit_nonlinear.h"
#include "datafile.h"
#include "hist.h"

/*
 * When we fit a histogram with Gaussians, we initially scatter 
 * Gaussians across it, starting from the largest peak, to locate all
 * the other peaks.  The parameter below is the spacing measured 
 * in full-width-at-half-maximum (FWHM) of the largest peak.  It's a 
 * crucial parameter: too big and the nonlinear fit will fail if 
 * features in the histogram need to be reproduced by Gaussians that 
 * substantially overlap. Too large and, of course, the fit will take 
 * forever, or wander meaninglessly in a high-dimensional space of
 * functionally nearly equivalent fits.
 */
#define FIT_GAUSS_PKSPACING (2.0)

/************************************************************************

  Initialize a new histogram structure.

  */
rc_t hist_init(hist_t *hs, int bins) {

  const char *me = "hist_init" ;

  if (!(hs->x = (unsigned *)malloc(bins*sizeof(unsigned))) ||
      !(hs->y = (unsigned *)malloc(bins*sizeof(unsigned))) )
    return(memfail(__FILE__,__LINE__,me)) ;
  hs->n = hs->nmax = bins ;
  hs->binsz = 1 ;
  hs->sum = 0 ;
  return(OK) ;
}

/************************************************************************

  Free histogram.

  */
void hist_free(hist_t *hs) {

  free(hs->x) ; free(hs->y) ; hs->x = hs->y = 0 ; hs->nmax = hs->n = 0 ;
}

/************************************************************************

  Check size and possibly re-allocate a histogram structure.

  */
rc_t hist_chksz(hist_t *hs, int bins) {

  const char *me = "hist_chksz" ;

  if (bins > hs->nmax) {
    if (!(hs->x = (unsigned *)realloc(hs->x,bins*sizeof(unsigned))) ||
	!(hs->y = (unsigned *)realloc(hs->y,bins*sizeof(unsigned))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    hs->nmax = bins ;
  } ;
  return(OK) ;
}

/************************************************************************

  Return a pointer to a scratch histogram.

  */
static hist_t *get_tmp(int bins) {

  static hist_t hs_tmp ;
  static int b4 = 0 ;
  const char *me = "get_tmp" ;

  if (!(b4++) && (hist_init(&hs_tmp,bins) != OK))
    return(pmemfail(__FILE__,__LINE__,me)) ;
  if (hist_chksz(&hs_tmp,bins) != OK)       
    return(pmemfail(__FILE__,__LINE__,me)) ;
  return(&hs_tmp) ;
}

/************************************************************************

  Copy a histogram, or part of one.

  */
static rc_t hist_cpy(hist_t *hs_dest, const hist_t *hs_src, 
		     int start_bin, int end_bin) {

  hist_t *hs_wrk ;
  int newbins ;
  const char *me = "hist_cpy" ;

  if ((newbins = end_bin - start_bin) <= 0)
    return(punt(__FILE__,__LINE__,me,"bad arguments")) ;
  if (!(hs_wrk = ((hs_dest == hs_src) ? get_tmp(newbins) : hs_dest)))
    return(memfail(__FILE__,__LINE__,me)) ;
  if (hist_chksz(hs_wrk,newbins) != OK)
    return(memfail(__FILE__,__LINE__,me)) ;
  hs_wrk->n = newbins ;
  hs_wrk->binsz = hs_src->binsz ;
  hs_wrk->sum = hs_src->sum ;
  memcpy(hs_wrk->x,hs_src->x + start_bin,newbins * sizeof(unsigned)) ;
  memcpy(hs_wrk->y,hs_src->y + start_bin,newbins * sizeof(unsigned)) ;
  /* ok, so this is a little weird */
  if (hs_wrk != hs_dest) return(hist_cpy(hs_dest,hs_wrk,0,newbins)) ;
  return(OK) ;
}

/************************************************************************

  Construct a plain histogram of pixel intensities.

  */
rc_t hist_plain(hist_t *hs, const gras_t *gr, int binsz) {

  int bits,bins,i,j ;
  const char *me = "hist_plain" ;

  bits = gras_depth(gr) ;  
  bins = (1<<bits)/binsz ;
  if (bins*binsz < (1<<bits)) bins += 1 ;
  if (hist_init(hs,bins) != OK) return(memfail(__FILE__,__LINE__,me)) ;
  for(i=0;i<hs->n;i++) hs->x[i] = (i+1)*binsz - 1 ;
  memset(hs->y,0,hs->n * sizeof(unsigned)) ;
  hs->sum = 0 ;
  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      hs->y[ gr->ras[i][j] / binsz ] += 1 ;
      hs->sum += 1 ;
    } ;
  } ;
  if (verbosity == MSG_DEBUG) 
    printf("%s [%s:%d]: put %d pixels (%d -> %d) into %d bins.\n",
	   me,__FILE__,__LINE__,hs->sum,hs->x[0],hs->x[hs->n - 1],hs->n) ;
  return(OK) ;
}

/************************************************************************

  Convert a plain histogram into a cumulative histogram.

  */
rc_t hist_plain2cum(hist_t *hs_cum, const hist_t *hs_plain) {

  hist_t *hs_wrk ;
  unsigned int sum ;
  int i ;
  const char *me = "hist_plain2cum" ;

  if (hs_cum == hs_plain) {
    if (!(hs_wrk = get_tmp(hs_plain->n))) 
      return(memfail(__FILE__,__LINE__,me)) ;
  } else {
    if (hist_init(hs_cum,hs_plain->n) != OK)
      return(memfail(__FILE__,__LINE__,me)) ;
    hs_wrk = hs_cum ;
  } ;
  hs_wrk->binsz = hs_plain->binsz ;
  memcpy(hs_wrk->x,hs_plain->x,hs_plain->n*sizeof(unsigned)) ;
  for(sum=0,i=0;i<hs_plain->n;i++) hs_wrk->y[i] = (sum += hs_plain->y[i]) ;
  if (((hs_wrk->sum = sum) != hs_plain->sum) && (verbosity < MSG_FATAL))
    printf("> %s [%s:%d]: warning: computed sum disagrees with source sum.\n",
	   me,__FILE__,__LINE__) ;
  if ((hs_cum != hs_wrk) && (hist_cpy(hs_cum,hs_wrk,0,hs_wrk->n) != OK))
    return(subfail(__FILE__,__LINE__,me)) ;
  if (verbosity == MSG_DEBUG) 
    printf("%s [%s:%d]: converted plain histogram to cumulative.\n",
	   me,__FILE__,__LINE__) ;
  return(OK) ;
}

/************************************************************************

  Estimate bin, x max, y max, and full width at half maximum 
  of the largest peak in a histogram.

  */
rc_t hist_peak(int *bin, int *xmax, int *ymax, int *fwhm, 
	       const hist_t *hs) {

  int ymx,imax,i,fw,hmax,ilhw,iuhw ;
  double lwid,uwid,wid ;
  /* const char *me = "hist_peak" ; */

  for(imax=0,ymx=0,i=0;i<hs->n;i++)
    if (hs->y[i] > ymx) { ymx = hs->y[i] ; imax = i ; } ;
  hmax = ymx/2 ;
  for(ilhw=imax; (hs->y[ilhw] > hmax) && (ilhw >= 0  ); ilhw--) ;
  for(iuhw=imax; (hs->y[iuhw] > hmax) && (iuhw < hs->n); iuhw++) ;
  if ((ilhw > 0) && (iuhw < hs->n)) {
    fw = hs->x[iuhw] - hs->x[ilhw] ;
  } else if (ilhw > 0) {
    fw = 2.0*(hs->x[imax] - hs->x[ilhw]) ;
  } else if (iuhw < hs->n) {
    fw = 2.0*(hs->x[iuhw] - hs->x[imax]) ;    
  } else {
    /* complicated: assume it's a Gaussian */
    lwid = (hs->x[imax] - hs->x[ilhw])/
      sqrt(log((double)hs->y[ilhw]/(double)ymx)) ;
    uwid = (hs->x[iuhw] - hs->x[imax])/
      sqrt(log((double)hs->y[iuhw]/(double)ymx)) ;
    wid = 0.5*(lwid+uwid) ;
    /* this is sqrt(-log(0.5)) */
    wid *= 0.832554611 ;
    fw = (int)floor(wid + 0.5) ;
  } ;
  if (bin) *bin = imax ;
  if (xmax) *xmax = hs->x[imax] ;
  if (ymax) *ymax = ymx ;
  if (fwhm) *fwhm = fw ;
  return(OK) ;
}

/************************************************************************

  Copy a histogram from hs_src to hs_dat, and eliminate on the way
  prefix and suffix stretches of bins containing zero grayvalues.

  */
rc_t hist_unpad(hist_t *hs_dst, const hist_t *hs_src) {

  int ilo,ihi ;
  const char *me = "hist_unpad" ;

  for(ilo=0;(ilo < hs_src->n) && (hs_src->y[ilo] == 0);ilo++) ;
  if (ilo == hs_src->n) 
    return(punt(__FILE__,__LINE__,me,"zero histogram")) ;
  for(ihi=hs_src->n;(ihi > ilo) && (hs_src->y[ihi-1] == 0);ihi--) ;
  if (((hs_dst == hs_src) && (hist_chksz(hs_dst,ihi-ilo) != OK) ) ||
      ((hs_dst != hs_src) && (hist_init(hs_dst,ihi-ilo) != OK)  ) )
    return(memfail(__FILE__,__LINE__,me)) ;
  if (verbosity == MSG_DEBUG)
    printf("%s [%s:%d]: removed empty bins <%d and >%d.\n",
	   me,__FILE__,__LINE__,hs_src->x[ilo],hs_src->x[ihi-1]) ;
  return (hist_cpy(hs_dst,hs_src,ilo,ihi)) ;
}

/************************************************************************

  Find region in a cumulative histogram which contains 
  between frac_lo and frac_hi of the fraction of total pixels.

  */
rc_t hist_cum_region(const hist_t *hs, int *lo, int *hi,
		     double frac_lo, double frac_hi) {

  int ilo,ihi,ylo,yhi ;
  const char *me = "hist_cum_region" ;

  if ((frac_lo < 0.0) || (frac_lo > 1.0) ||
      (frac_hi < 0.0) || (frac_hi > 1.0) || (frac_hi <= frac_lo) )
    return(punt(__FILE__,__LINE__,me,"bad arguments.")) ;
  ylo = (int)floor(frac_lo * hs->sum) ;
  if (ylo < 0) ylo = 0 ;
  yhi = (int)ceil(frac_hi * hs->sum) ;
  if (yhi > hs->sum) yhi = hs->sum ;
  ilo = 0 ;
  while ((ilo<hs->n) && (hs->y[ilo] < ylo)) ilo++ ;
  if (ilo == hs->n) 
    return(punt(__FILE__,__LINE__,me,"can\'t find low index!")) ;
  ihi = ilo ;
  while ((ihi<hs->n) && (hs->y[ihi] <= yhi)) ihi++ ;
  *lo = ilo ; *hi = ihi ;
  return(OK) ;
}

/************************************************************************

  Clip a plain histogram so it contains between frac_lo and frac_hi
  fractions of the total pixels in the histogram.

  */
rc_t hist_plain_clip(hist_t *hs_dst, const hist_t *hs_src, 
		     double frac_lo, double frac_hi) {
  hist_t *hs_cum ;
  int ilo,ihi,oldsum,newsum ;
  const char *me = "hist_plain_clip" ;

  if ((frac_lo == 0.0) && (frac_hi == 1.0))
    return(hist_unpad(hs_dst,hs_src)) ;
  if (!(hs_cum = get_tmp(hs_src->n)) || (hist_plain2cum(hs_cum,hs_src) != OK)) 
    return(subfail(__FILE__,__LINE__,me)) ;
  if (hist_cum_region(hs_cum,&ilo,&ihi,frac_lo,frac_hi) != OK)
    return(subfail(__FILE__,__LINE__,me)) ;
  if ((hs_dst != hs_src) && (hist_chksz(hs_dst,ihi-ilo) != OK))
    return(memfail(__FILE__,__LINE__,me)) ;
  oldsum = hs_cum->sum ;
  newsum = hs_cum->y[ihi-1] - (ilo ? hs_cum->y[ilo-1] : 0) ;
  if (hist_cpy(hs_dst,hs_src,ilo,ihi) != OK) 
    return(subfail(__FILE__,__LINE__,me)) ;
  hs_dst->sum = newsum ;
  if (verbosity == MSG_DEBUG) 
    printf("%s [%s:%d]: clipped %d pixels (%8.4f%%).\n",me,__FILE__,__LINE__,
	   oldsum - newsum,100.0*(oldsum-newsum)/oldsum) ;
  return(OK) ;
}

/************************************************************************

  Try fitting ng Gaussians to a histogram:

  => requires fit_nonlinear.o

  xsq = place to store fit figure of merit on return
  ap = amplitudes )
  cp = centers    ) of Gaussians - must contain initial guesses on entry.
  wp = widths     )
  hs = the histogram
  tol = tolerance on fit -- fit considered good when xsq  change/iteration 
        becomes less than tol.
  itmax = how many iterations of fitting procedure will be attempted 
          before giving up.
  ng = number of Gaussians.

  */
rc_t hist_fit_gauss(double *xsq, double *ap, double *cp, double *wp,
		    const hist_t *hs, double tol, int itmax, int ng) {

  static int wf = FIT_GAUSS_PKSPACING ;   /* see note at top of file */
  double *xv, *yv,*yd, *amp, *ctr, *wid ;
  int *afz, *cfz, *wfz ;
  double xpk,ypk,pw,dx,x ;
  int ipeak,ixpk,iypk,ipw,n,npmx,i,ysig,np,check ;
  const char *me = "hist_fit_gauss" ;

  /* find characteristics of largest peak */
  hist_peak(&ipeak,&ixpk,&iypk,&ipw,hs) ;
  xpk = (double)ixpk ; ypk = (double)iypk ; pw = (double)ipw ;
  if (verbosity == MSG_DEBUG) 
    printf("%s [%s:%d]: biggest histogram peak:\n   amp %f ctr %f wid %f\n",
	   me,__FILE__,__LINE__,ypk,xpk,pw) ;

  /* allocate memory */
  n = hs->n ;
  npmx = (int)floor((double)(hs->x[hs->n - 1] - hs->x[0])/(wf*pw)) ;
  if (npmx < ng) npmx = ng ;
  npmx += 2 ;   /* safety factor */
  if (!(xv = (double *)malloc(n * sizeof(double))) ||
      !(yv = (double *)malloc(n * sizeof(double))) ||
      !(yd = (double *)malloc(n * sizeof(double))) ||
      !(amp = (double *)malloc(npmx * sizeof(double))) ||
      !(ctr = (double *)malloc(npmx * sizeof(double))) ||
      !(wid = (double *)malloc(npmx * sizeof(double))) ||
      !(afz = (int *)malloc(npmx * sizeof(int))) ||
      !(cfz = (int *)malloc(npmx * sizeof(int))) ||
      !(wfz = (int *)malloc(npmx * sizeof(int))) )
    return(memfail(__FILE__,__LINE__,me)) ;
  memset(afz,~0,npmx*sizeof(int)) ;
  memset(cfz,~0,npmx*sizeof(int)) ;
  memset(wfz,~0,npmx*sizeof(int)) ;

  /* convert x and y to double values */
  for(i=0;i<n;i++) xv[i] = (double)(hs->x[i]) ;
  for(i=0;i<n;i++) yv[i] = (double)(hs->y[i]) ;
  /* estimate uncertainties in data in a Monte-Carlo way */
  ysig = iypk/128 ;
  for(i=0;i<n;i++) yd[i] = (hs->y[i] > ysig ? sqrt(yv[i]/ypk) : 1.0) ;

  /* scatter Gaussians across histogram starting from biggest peak  */
  np = 0 ; dx = wf*pw ; x = xpk ;
  while (x > xv[0]  ) { ctr[np++] = x ; x -= dx ; } ;
  x = xpk + dx ;
  while (x < xv[n-1]) { ctr[np++] = x ; x += dx ; } ;
  for(i=0;i<np;i++) amp[i] = ypk ;
  for(i=0;i<np;i++) wid[i] = pw ;

  /* relax amplitudes */
  if (verbosity == MSG_DEBUG) 
    printf("%s [%s:%d]: finding all peaks with %d Gaussians\n",
	   me,__FILE__,__LINE__,np) ;
  check = fit_gauss(xsq,amp,ctr,wid,0,cfz,wfz,xv,yv,yd,n,np,itmax,tol) ;
  if (check == FATAL) {
    snprintf(msgbuf,sizeof(msgbuf),"could not find peaks.") ;
  } else {
    /* select ng largest peaks for complete relaxation */
    sort_dd_desc(np,amp,ctr) ;
    for(i=np;i<ng;i++) 
      { amp[i] = ypk ; ctr[i] = ctr[0] + i*pw ; wid[i] = pw ; } ;
    if (verbosity == MSG_DEBUG) {
      printf("%s [%s:%d]: using %d Gaussians for final fit,\n",
	     me,__FILE__,__LINE__,ng) ;
      printf("   centers at:") ;
      for(i=0;i<ng;i++) printf(" %f",ctr[i]) ; printf("\n") ;
    } ;
    check = fit_gauss(xsq,amp,ctr,wid,0,0,0,xv,yv,yd,n,ng,itmax,tol) ;
    if (verbosity == MSG_DEBUG) {
      printf("%s [%s:%d]: results:\n",me,__FILE__,__LINE__) ;
      for(i=0;i<ng;i++) printf("   Gaussian %d: amp %f ctr %f wid %f\n",
			       i,amp[i],ctr[i],wid[i]) ;
    } ;
    if (check == FATAL) {
      snprintf(msgbuf,sizeof(msgbuf),
	       "could not fit Gaussians to histogram.") ;
    } else {
      memcpy(ap,amp,ng*sizeof(double)) ;
      memcpy(cp,ctr,ng*sizeof(double)) ;
      memcpy(wp,wid,ng*sizeof(double)) ;
    } ;
  } ;

  free(xv); free(yv); free(yd);
  free(amp); free(ctr); free(wid) ;
  free(afz); free(cfz); free(wfz) ;

  if (check == FATAL)
    return(punt(__FILE__,__LINE__,me,msgbuf)) ;

  return(OK) ;
}

/******************************************************************************

  Assign histogram ordinates from a sum of Gaussians.

  */
void hist_model_gauss(hist_t *hs, 
		      const double *amp, const double *ctr, const double *wid, 
		      int ng) {
  double x,y ;
  int i,j ;

  for(i=0;i<hs->n;i++) {
    x = (double)hs->x[i] ;
    y = 0.0 ;
    for(j=0;j<ng;j++) y += amp[j] * exp(-SQ((x-ctr[j])/wid[j])) ;
    hs->y[i] = (int)floor(y + 0.5) ;
  } ;
}

/******************************************************************************

  Dump standard raster histogram to text data file.

  */
rc_t hist_dump_gras(const gras_t *gr, const char *fn, const char *fn_img) {

  hist_t hs, hs_cum ;
  datafile_reg_t dfr ;
  int i ;
  const char *fn_default = "hist.dat" ;
  const char *f_fmt = "1=intensity 2=pixels 3=cumulative" ;
  FILE *fp ;
  const char *me = "hist_dump_gras" ;

  if (!fn || !strlen(fn)) fn = fn_unique(fn_default) ;
  datafile_init(&dfr,me,__FILE__,__DATE__,__TIME__) ;
  if (!(fp = datafile_open((char *)fn,0,&dfr))) 
    return(subfail(__FILE__,__LINE__,me)) ;
  fprintf(fp,"# contents = image pixel intensity histogram\n") ;
  if (fn_img) fprintf(fp,"# image file = %s\n",fn_img) ;
  fprintf(fp,"# format = %s\n",f_fmt) ;
  if ((hist_plain(&hs,gr,1) != OK) || 
      (hist_unpad(&hs,&hs) != OK) ||
      (hist_plain2cum(&hs_cum,&hs) != OK) )
    return(subfail(__FILE__,__LINE__,me)) ;
  
  for(i=0;i<hs.n;i++) fprintf(fp,"%d %d %d\n",hs.x[i],hs.y[i],hs_cum.y[i]) ;
  
  fclose(fp) ;
  if (verbosity < MSG_FATAL)
    printf("%s [%s:%d]: write intensity histogram to \"%s\".\n",
	   me,__FILE__,__LINE__,fn) ;
  return(OK) ;
}
