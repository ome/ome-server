/****************************************************************************/
/*                                                                          */
/*  ome_hist.c                                                              */
/*                                                                          */
/*  OME module -    Write histograms of grayscale rasters stored in TIFF files. */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
/*     This file is part of OME.                                            */
/*                                                                          */ 
/*     OME is free software; you can redistribute it and/or modify          */
/*     it under the terms of the GNU General Public License as published by */
/*     the Free Software Foundation; either version 2 of the License, or    */
/*     (at your option) any later version.                                  */
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include "datafile.h"
#include "img_file.h"
#include "gras.h"
#include "hist.h"
#include "util.h"

#define DO_CLIP  (1<<0)
#define DO_FIT   (1<<1)
#define DO_UNPAD (1<<2)

verb_t verbosity = MSG_WARN ;

static int do_mode = DO_UNPAD ;
static int binsz = 1 ;
static double cmin,cmax ;
static const char *suffix = "_hst.dat" ;
static const char *fn_default = "hist.dat" ;

/* options for Gaussian fitting */
static const double tol = 1.0e-10 ;
static const int itmax = 500 ;

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "\nUsage: %s [options] imagefile [histogram_file]\n\n"
    "Dump histogram of pixel intensities.\n\n"
    "Options:\n\n"
    "   -b <n>\n"
    "      Set binsize n (default n=1).\n\n"
    "   -keep\n"
    "      Keep all bins.  Default is to remove leading and trailing bins\n"
    "      with no pixels in them.\n\n" 
    "   -clip <min>,<max>\n"
    "      Clip histogram so that it contains between min and max fraction\n"
    "      of the total number of pixels, e.g. 0.1,0.9 throws away the\n"
    "      dimmest 10%% and brightest 10%% of the pixels.\n\n"
    "   -fit <n>\n"
    "      Try to model histogram as the sum of n Gaussian (normal)\n"
    "      distributions.\n\n"
    "   -v <n>\n"
    "      Set verbosity n,%d=debug,%d=warn,%d=fatal,%d=none (default n=%d).\n"
    ;
    
  printf(fmt,id,MSG_DEBUG,MSG_WARN,MSG_FATAL,MSG_NONE,verbosity) ;
  return(FATAL) ;
}

/************************************************************************

  The walrus.

  */
int main(int argc, char *argv[]) {

  gras_t gr ;
  hist_t hs,hs_cum ;
  datafile_reg_t dfr ;
  int ai,ng,i,j ;
  double x,y,xsq ;
  double *amp,*ctr,*wid ;
  char *fn,*fn_in,*arg ;
  char *fn_out = 0 ;
  FILE *fp ;

  /* parse options, if given */
  ai = 1 ;
  while ((ai < argc) && *(argv[ai]) == '-') {
    arg = argv[ai]+1 ;
    if (!strcmp("b",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      binsz = atoi(argv[ai]) ;
    } else if (!strcmp("clip",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      if (!getarg_dd(argv[ai],&cmin,&cmax)) return(badarg(argv[ai])) ;
      do_mode |= DO_CLIP ;
    } else if (!strcmp("keep",arg)) {
      do_mode &= ~DO_UNPAD ;
    } else if (!strcmp("fit",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      ng = atoi(argv[ai]) ;
      do_mode |= DO_FIT ;
    } else if (!strcmp("v",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;      
      verbosity = atoi(argv[ai]) ;
    } else {
      return(usage(argv[0])) ;
    } ;
    ai += 1 ;
  } ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_in = argv[ai++] ;
  if (ai < argc) fn_out = argv[ai++] ;

  /* load image file */
  gras_init(&gr,0,0) ;
  if (tiff_load_gras(fn_in,&gr) != OK) return(FATAL) ;

  /* take care of the normal case here */
  if ((do_mode == DO_UNPAD) && (binsz == 1)) {
    fn = fn_related(fn_out,fn_in,suffix,fn_default) ;
    return(hist_dump_gras(&gr,fn,fn_in)) ;
  } ;

  /* take care of a more complex case */

  if (hist_plain(&hs,&gr,binsz) != OK) return(FATAL) ;
  if ((do_mode & DO_UNPAD) && (hist_unpad(&hs,&hs) != OK)) return(FATAL) ; 
  if ((do_mode & DO_CLIP) && (hist_plain_clip(&hs,&hs,cmin,cmax) != OK))
    return(FATAL) ; 
  if (hist_plain2cum(&hs_cum,&hs) != OK) return(FATAL) ;

  /* fitting? */
  if (do_mode & DO_FIT) {
    if (!(amp = (double *)malloc(ng*sizeof(double))) ||
	!(ctr = (double *)malloc(ng*sizeof(double))) ||
	!(wid = (double *)malloc(ng*sizeof(double))) ) {
      if (verbosity < MSG_NONE) 
	printf("* can\'t allocate fitting workspace.\n") ;
      return(FATAL) ;
    } ;
    hist_fit_gauss(&xsq,amp,ctr,wid,&hs,tol,itmax,ng) ;
  } ;

  /* dump more complex data file */
  fn = fn_related(fn_out,fn_in,suffix,fn_default) ;
  datafile_init(&dfr,argv[0],__FILE__,__DATE__,__TIME__) ;
  if (!(fp = datafile_open((char *)fn,0,&dfr))) return(FATAL) ;
  fprintf(fp,"# contents = image pixel intensity histogram\n") ;
  fprintf(fp,"# image file = %s\n",fn_in) ;
  fprintf(fp,"# binsize = %d\n",binsz) ;
  if (do_mode & DO_CLIP) fprintf(fp,"# clip min,max  = %f,%f\n",cmin,cmax) ;
  if (do_mode & DO_FIT) {
    fprintf(fp,"# Gaussians fitted = %d\n",ng) ;
    fprintf(fp,"# final figure of merit = %f\n",xsq) ;
    for(i=0;i<ng;i++)
      fprintf(fp,"# Gaussian %d = %f (amplitude) %f (center) %f (width)\n",
	      i,amp[i],ctr[i],wid[i]) ;
  } ;
  fprintf(fp,"# format = intensity N(intensity) N_cumulative(intensity)") ;
  if (do_mode & DO_FIT) 
    fprintf(fp," N_fit(intensity) Gaussian_0(intensity) ...") ;
  fprintf(fp,"\n") ;
  for(i=0;i<hs.n;i++) {
    fprintf(fp,"%d %d %d",hs.x[i],hs.y[i],hs_cum.y[i]) ;
    if (do_mode & DO_FIT) {
      x = (double)hs.x[i] ;
      y = 0.0 ;
      for(j=0;j<ng;j++) y += amp[j] * exp(-SQ((x-ctr[j])/wid[j])) ;
      fprintf(fp," %f",y) ;
      for(j=0;j<ng;j++) {
	y = amp[j] * exp(-(x-ctr[j])*(x-ctr[j])/(wid[j]*wid[j])) ;    
	fprintf(fp," %f",y) ;
      } ;
    } ;
    fprintf(fp,"\n") ;
  } ;
  fclose(fp) ;
  if (verbosity < MSG_FATAL) printf("Wrote \"%s\".\n",fn) ;

  return(OK) ;
}
