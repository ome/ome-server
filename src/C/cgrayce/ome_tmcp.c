/******************************************************************************

   TMCP correlation.

 */
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "gras.h"
#include "img_file.h"
#include "obj.h"
#include "geo.h"
#include "util.h"

verb_t verbosity = MSG_WARN ;

/* when finding background by thresholding, threshold min/max */
static int tmin = 0 ;
static int tmax = 1 ;
/* how small an object we ignore, in pixels */
static int amin = 1 ;
/* that we ignore objects which are not entirely within the image frame */
#define IGNORE_PARTIALS (1)

/******************************************************************************

  Calculate and return TMCP correlation.

  */
static double make_corr(double xctr, double yctr,
			const int *x, const int *y, const unsigned *gv, 
			unsigned thold, int n) {

  double r2,sum ;
  unsigned g,gsum ;
  int i ;
  const char *me = "make_corr" ;
		     
  sum = 0.0 ; gsum = 0 ;
  for(i=0;i<n;i++) {
    if ((g = gv[i] - thold) < 0) g = 0 ;
    r2 = SQ(x[i] - xctr) + SQ(y[i] - yctr) ;
    sum += sqrt(r2) * gv[i] ; 
    gsum += g ;
  } ;
  if (verbosity == MSG_DEBUG) {
    printf("> %s [%s:%d]: pixels = %d\n",me,__FILE__,__LINE__,n) ;
    printf("   sum scaled pix val = %d\n",gsum) ;
    printf("   sum distance * scaled pix val = %f\n",sum) ;
  } ;
  if (gsum) return(sum/gsum) ;
  return(0.0) ;
}

/******************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "Usage: %s [options] test_imagefile ref_imagefile\n"
    "Options:\n"
    "   -t <threshold_value>\tSet threshold value in test image (default=0)\n"
    "   -v <n>              \tSet verbosity to n (%d=all,%d=fatal,%d=none,%d=debug)\n"
    "Return TMCP correlation.\n"
    ;
    
  if (verbosity != MSG_NONE) 
    printf(fmt,id,MSG_WARN,MSG_FATAL,MSG_NONE,MSG_DEBUG) ;
  return(FATAL) ;
}

/******************************************************************************

  The walrus.

  */
int main(int argc, char *argv[]) {

  int thold = 0 ;
  gras_t gr_tst, gr_ref, gr_mk ;
  objl_t oref, otst ;
  pixl_t pl ;
  double *xc,*yc ;
  double corr ;
  unsigned *g ;
  char *fn_tst, *fn_ref ;
  int ai,i ;

  /* parse options */
  ai = 1 ;
  while ((argc > ai) && *(argv[ai]) == '-') {
    switch(*(argv[ai]+1)) {
    case 't' :
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      thold = atoi(argv[ai++]) ;
      break ;
    case 'v' :
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      verbosity = atoi(argv[ai++]) ;
      break ;
    default :
      return(usage(argv[0])) ;
    } ;
  } ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_tst = argv[ai++] ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_ref = argv[ai++] ;

  /* load data files */
  gras_init(&gr_tst,0,0) ; gras_init(&gr_ref,0,0) ;
  if ((tiff_load_gras(fn_tst,&gr_tst) != OK) ||
      (tiff_load_gras(fn_ref,&gr_ref) != OK) ) return(FATAL) ;

  /* verify that test and reference images are the same size */
  if ((gr_tst.nx != gr_ref.nx) || (gr_tst.ny != gr_ref.ny))
    return(punt(__FILE__,__LINE__,argv[0],
		"test and reference images not same size")) ;
  
  /* get all the objects in the reference image */
  gras_init(&gr_mk,gr_ref.ny,gr_ref.nx) ;
  if (gras_mark_gray(&gr_ref,&gr_mk,tmin,tmax) != OK) return(FATAL) ;
  objl_init(&oref,100) ;
  if (objl_marked(&oref,&gr_ref,&gr_mk,amin,IGNORE_PARTIALS) != OK) 
    return(FATAL) ;

  if (!oref.n) return(punt(__FILE__,__LINE__,argv[0],"no objects.")) ;
  
  /* make a list of their centers of mass */
  if (!(xc = (double *)malloc(oref.n * sizeof(double))) ||
      !(yc = (double *)malloc(oref.n * sizeof(double))) )
    return(memfail(__FILE__,__LINE__,argv[0])) ;
  for(i=0;i<oref.n;i++) geo_com(oref.obj[i],yc+i,xc+i) ;

  /* get Voronoy polygon objects surrounding each COM */
  objl_init(&otst,100) ;
  if (objl_voy(&otst,&gr_tst,yc,xc,oref.n) != OK) return(FATAL) ;
  
  /* do our calculation */
  pixl_init(&pl,10000) ;
  corr = 0.0 ;
  for(i=0;i<otst.n;i++) {
    if (obj2pixl(otst.obj[i],&pl,&g) != OK) return(FATAL) ;
    corr += make_corr(xc[i],yc[i],pl.x,pl.y,g,thold,pl.n) ;
  } ;

  /* report average correlation per polygon */
  corr /= otst.n ;
  printf("%f\n",corr) ;

  return(OK) ;
}
