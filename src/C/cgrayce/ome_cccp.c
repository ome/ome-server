/************************************************************************

   CCCP Correlation Coefficient of Cellular Position

 */
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "gras.h"
#include "img_file.h"
#include "util.h"

/* a small test number used to check for zero denominators */
#define ZERO (1.0e-30)

verb_t verbosity = MSG_FATAL ;

static const char *here = __FILE__ ;

/************************************************************************

  Calculate correlation integral and averages.

  */
static int make_corr(double *corr, double *a1, double *a2,
		     const gras_t *gr1, const gras_t *gr2,
		     const gras_t *mask, unsigned int threshold,
		     int thold_sense) {

  int nx,ny,n,xi,yi ;
  unsigned int dn1,dn2 ;
  double sum1,sum2,sum11,sum22,sum12,ave1,ave2,c ;
  const char *me = "make_corr" ;

  if ( ((gr1->nx) != (gr2->nx)) || ((gr1->ny != gr2->ny)) )
    return(punt(here,__LINE__,me,"rasters have dissimilar dimensions")) ;
  if (mask && ( ((gr1->nx) != mask->nx) || ((gr1->ny != mask->ny)) ))
    return(punt(here,__LINE__,me,"rasters and mask have dissimilar dimensions")) ;
  nx = gr1->nx ; ny = gr1->ny ;

  n = 0 ;
  sum1 = sum2 = sum11 = sum22 = sum12 = 0.0 ;
  for(yi=0;yi<ny;yi++) {  
    for(xi=0;xi<nx;xi++) {
      if (mask) {
	if (!thold_sense && (mask->ras[yi][xi] <= threshold)) continue ;
	if ( thold_sense && (mask->ras[yi][xi] >= threshold)) continue ;
      } ;
      dn1 = gr1->ras[yi][xi] ;
      dn2 = gr2->ras[yi][xi] ;
      sum1 += dn1 ;
      sum2 += dn2 ;
      sum11 += dn1 * dn1 ;
      sum12 += dn1 * dn2 ;
      sum22 += dn2 * dn2 ;
      n += 1 ;
    } ;
  } ;
  if (verbosity == MSG_DEBUG) {
    printf("> %s [%s:%d]: pixels = %d\n",me,__FILE__,__LINE__,n) ;
    printf("> %s [%s:%d]: sum pix val img 1 = %24.16e\n",
	   me,__FILE__,__LINE__,sum1) ;
    printf("> %s [%s:%d]: sum pix val img 2 = %24.16e\n",
	   me,__FILE__,__LINE__,sum2) ;
    printf("> %s [%s:%d]: sum   val^2 img 1 = %24.16e\n",
	   me,__FILE__,__LINE__,sum11) ;
    printf("> %s [%s:%d]: sum   val^2 img 2 = %24.16e\n",
	   me,__FILE__,__LINE__,sum22) ;
    printf("> %s [%s:%d]: sum   val1 x val2 = %24.16e\n",
	   me,__FILE__,__LINE__,sum12) ;
  } ;
  if (!n) return(punt(here,__LINE__,me,"all pixels masked")) ;
  ave1 = sum1/n ; ave2 = sum2/n ;
  c = (n*sum11 - sum1*sum1)*(n*sum22 - sum2*sum2) ;
  /* this should never happen */
  if (c < -ZERO) return(punt(here,__LINE__,me,"negative argument to sqrt ?")) ;
  c = sqrt(fabs(c)) ;
  /* this happens only if one or both standard deviations are zero */
  if (c <  ZERO) return(punt(here,__LINE__,me,"zero contrast image(s) ?")) ;
  c = (n*sum12 - sum1*sum2)/c ;
  if (a1) *a1 = ave1 ;
  if (a2) *a2 = ave2 ;
  if (corr) *corr = c ;
  return(OK) ;
}

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "Usage: %s [options] imagefile1 imagefile2 [maskfile]\n"
    "Options:\n"
    "   -t <threshold_value>\tSet threshold value used with maskfile\n"
    "   -i                  \tInvert sense of threshold\n"
    "   -v <n>              \tSet verbosity n (%d=debug,%d=all,%d=fatal,%d=none)\n"
    "Returns integrated correlation between pixel values in two images.\n"
    ;
    
  if (verbosity != MSG_NONE) 
    printf(fmt,id,MSG_DEBUG,MSG_WARN,MSG_FATAL,MSG_NONE) ;
  return(FATAL) ;
}

/************************************************************************

  The walrus.

  */
int main(int argc, char *argv[]) {

  /* default mask threshold is 1 -- any value other than black */
  unsigned int thold = 1 ;
  /* default sense of threshold is: calculate when mask > threshold */
  int thold_sense = 0 ;
  gras_t gr1,gr2,mask ;
  double a1,a2,c ;
  int ai,masked ;

  /* parse options, if given */
  ai = 1 ;
  while ((argc > ai) && *(argv[ai]) == '-') {
    switch(*(argv[ai]+1)) {
    case 't' :
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      thold = atoi(argv[ai++]) ;
      break ;
    case 'i' :
      ai += 1 ;
      /* invert sense of threshold: calculate when mask < threshold */
      thold_sense = 1 ;
      break ;
    case 'v' :
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      verbosity = atoi(argv[ai++]) ;
      break ;
    default :
      return(usage(argv[0])) ;
    } ;
  } ;

  /* load data files */
  if (argc < ai + 2) return(usage(argv[0])) ;

  gras_init(&gr1,0,0) ; gras_init(&gr2,0,0) ;
  if ((tiff_load_gras(argv[ai++],&gr1) != OK) ||
      (tiff_load_gras(argv[ai++],&gr2) != OK) ) return(FATAL) ;

  /* load mask, if given */
  if (argc > ai) {
    gras_init(&mask,gr1.ny,gr1.nx) ;
    if (tiff_load_gras(argv[ai++],&mask) != OK) return(FATAL) ;
    masked = 1 ;
  } else {
    masked = 0 ;
  } ;

  /* do our calculation */
  if (make_corr(&c,&a1,&a2,&gr1,&gr2,
		(masked ? &mask : 0),thold,thold_sense) != OK) return(FATAL) ;
  printf("%f\n",c) ;

  return(OK) ;
}
