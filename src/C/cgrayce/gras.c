/************************************************************************

  Grayscale rasters.

  A grayscale raster is a rectangular array of numbers, such as one would 
  use to represent a graylevel image.

  For nonrectangular arrays see obj.h.

  */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include "util.h"
#include "gras.h"
#include "hist.h"
#include "obj.h"

/******************************************************************************

  Initialize integer raster.

  */
rc_t gras_init(gras_t *gr, int ny, int nx) {

  int i ;
  const char *me = "gras_init" ;

  if ((nx > 0) && (ny > 0)) {
    if (!(gr->data = (unsigned  *)malloc(nx*ny * sizeof(unsigned))) ||
	!(gr->ras  = (unsigned **)malloc(ny * sizeof(unsigned *))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    for(i=0;i<ny;i++) gr->ras[i] = gr->data + i*nx ;
    gr->nymax = gr->ny = ny ;
    gr->nxmax = gr->nx = nx ;
  } else {
    gr->nymax = gr->nxmax = gr->ny = gr->nx = 0 ;
    gr->data = 0 ; gr->ras = 0 ;
  } ;
  gr->max   =  0 ;
  gr->min   = ~0 ;
  return(OK) ;
}

/******************************************************************************

  Initialize floating point raster.

  */
rc_t fras_init(fras_t *fr, int ny, int nx) {

  int i ;
  const char *me = "fras_init" ;

  if ((nx > 0) && (ny > 0)) {
    if (!(fr->data = (double *)malloc(nx*ny * sizeof(double))) ||
	!(fr->ras  = (double **)malloc(ny * sizeof(double *))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    for(i=0;i<ny;i++) fr->ras[i] = fr->data + i*nx ;
    fr->nymax = fr->ny = ny ;
    fr->nxmax = fr->nx = nx ;
  } else {
    fr->nymax = fr->nxmax = fr->ny = fr->nx = 0 ;
    fr->data = 0 ; fr->ras = 0 ;
  } ;
  fr->max   = -DBL_MAX ;
  fr->min   =  DBL_MAX ;
  return(OK) ;
}

/******************************************************************************

  Free integer raster.

  */
void gras_free(gras_t *gr) {

  free(gr->data) ; free(gr->ras) ; gr->data = 0 ; gr->ras = 0 ;
}

/******************************************************************************

  Free floating point raster.

  */
void fras_free(fras_t *fr) {

  free(fr->data) ; free(fr->ras) ; fr->data = 0 ; fr->ras = 0 ;
}

/******************************************************************************

  Verify space exists in gr for nx x ny data.

  */
rc_t gras_chksz(gras_t *gr, int ny, int nx) {

  int i ;
  const char *me = "gras_chksz" ;

  if ((ny > gr->nymax) || (nx > gr->nxmax)) {
    if (!(gr->data = (unsigned *)realloc(gr->data,ny*nx * sizeof(unsigned))) ||
	!(gr->ras  = (unsigned **)realloc(gr->ras,ny * sizeof(unsigned *))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    for(i=0;i<ny;i++) gr->ras[i] = gr->data + i*nx ;
    gr->nymax = ny ;
    gr->nxmax = nx ;
  } ;
  gr->ny = ny ;
  gr->nx = nx ;
  return(OK) ;
}

/******************************************************************************

  Verify space exists in fr for nx x ny data.

  */
rc_t fras_chksz(fras_t *fr, int ny, int nx) {

  int i ;
  const char *me = "fras_chksz" ;

  if ((ny > fr->nymax) || (nx > fr->nxmax)) {
    if (!(fr->data = (double  *)realloc(fr->data,ny*nx * sizeof(double))) ||
	!(fr->ras  = (double **)realloc(fr->ras,ny * sizeof(double *))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    for(i=0;i<ny;i++) fr->ras[i] = fr->data + i*nx ;
    fr->nymax = ny ;
    fr->nxmax = nx ;
  } ;
  fr->ny = ny ;
  fr->nx = nx ;
  return(OK) ;
}

/******************************************************************************

  Calculate max and min for integer raster.

  */
void gras_maxmin(gras_t *gr) {

  int i,j ;

  gr->max =  0 ; gr->min = ~0 ;
  for(i=0;i<gr->ny;i++)
    for(j=0;j<gr->nx;j++) {
      gr->max = MAX(gr->max,gr->ras[i][j]) ;
      gr->min = MIN(gr->min,gr->ras[i][j]) ;
    } ;
}

/******************************************************************************

  Calculate max and min for floating point raster.

  */
void fras_maxmin(fras_t *fr) {

  int i,j ;

  fr->max = -DBL_MAX ; fr->min = DBL_MAX ;
  for(i=0;i<fr->ny;i++)
    for(j=0;j<fr->nx;j++) {
      fr->max = MAX(fr->max,fr->ras[i][j]) ;
      fr->min = MIN(fr->min,fr->ras[i][j]) ;
    } ;
}

/******************************************************************************

  Return mean and perhaps variance of data in integer raster.

  */
double gras_mean(const gras_t *gr, double *var) {

  int i,j,v,v2 ;

  v = v2 = 0 ;
  for(i=0;i<gr->ny;i++) for(j=0;j<gr->nx;j++) 
    { v += gr->ras[i][j] ; v2 += SQ(gr->ras[i][j]) ; } ;
  if (var) *var = (double)v2/(double)(gr->nx * gr->ny) ;
  return((double)v/(double)(gr->nx * gr->ny)) ;
}

/******************************************************************************

  Return mean and perhaps variance of data in floating point raster.

  */
double fras_mean(const fras_t *fr, double *var) {

  int i,j ;
  double v,v2 ;

  v = v2 = 0.0 ;
  for(i=0;i<fr->ny;i++) for(j=0;j<fr->nx;j++) 
    { v += fr->ras[i][j] ; v2 += SQ(fr->ras[i][j]) ; } ;
  if (var) *var = v2/(double)(fr->nx * fr->ny) ;
  return(v/(double)(fr->nx * fr->ny)) ;
}

/******************************************************************************

  Return minimum depth (bits/entry) needed to store an integer
  raster, assuming only an integral number of bytes of bits is permissible.   
  That is, the depth returned is always a multiple of 8.

  */
int gras_depth(const gras_t *gr) {

  unsigned int bits = 8 ;

  while ((1<<bits) < gr->max) bits += 8 ;
  return(bits) ;
}

/******************************************************************************

  Construct lists of y and x coordinates for the 8 or less nearest 
  neighbors of the pixel at (y,x) in raster gr.  

  Returns number in list.

  => There can be < 8 neighbors when the pixel is in a corner or near 
     an edge.

  */
int gras_nn8(const gras_t *gr, int *ylist, int *xlist, int y, int x) {

  static const int dy[] = {-1,-1,-1, 0,  0, 1, 1, 1} ;
  static const int dx[] = {-1, 0, 1,-1,  1,-1, 0, 1} ;

  int i,xn,yn,n ;

  for(n=0,i=0;i<8;i++) {
    yn = y + dy[i] ; xn = x + dx[i] ;
    if ( (yn >= 0) && (yn < gr->ny) && (xn >= 0) && (xn < gr->nx) ) 
      { xlist[n] = xn ; ylist[n] = yn ; n += 1; } ;
  } ;
  return(n) ;
}
  
/******************************************************************************

  Mark pixels in gr_mk if their gray values in gr are >= min and < max.

  */
rc_t gras_mark_gray(const gras_t *gr, gras_t *gr_mk, 
		    unsigned min, unsigned max) {

  int i,j ;
  const char *me = "gras_mark_gray" ;

  if ((min < 0) || (max < 0) || (max < min)) {
    snprintf(msgbuf,sizeof(msgbuf),"bad gray min,max %u,%u",min,max) ;
    return(punt(__FILE__,__LINE__,me,msgbuf)) ;
  } ;
  if (gras_chksz(gr_mk,gr->ny,gr->nx) != OK) 
    return(memfail(__FILE__,__LINE__,me)) ;
  memset(gr_mk->data,0,(gr_mk->nymax)*(gr_mk->nxmax)*sizeof(unsigned)) ;
  for(i=0;i<gr->ny;i++)
    for(j=0;j<gr->nx;j++)
      if ((gr->ras[i][j] >= min) && (gr->ras[i][j] < max))
	gr_mk->ras[i][j] = 1 ;
  return(OK) ;
}
  
/******************************************************************************

  Define an uncorrelated Gaussian probability distribution of the intensity
  g_i of pixel i like so:

    P(g_i) = a exp(- [ (g_i - c)/w ]^2 )
 
    P(g_i,g_j...y_k) = P(g_i) P(g_j)...P(g_k)

  Then, this function returns the logarithm of the relative probability

    P(y_0..y_i..y_N)/[ N P(c) ]

  that N pixels in a square patch of side length 2*hpsz+1 centered at x,y
  have the intensities they do.  Got that?

  */
static double log_patchprob(const gras_t *gr, double c, double w,
			    int x, int y, int hpsz) {

  double logp ;
  int i,j,g,n ;

  n = 0 ; logp = 0.0 ;
  for(i=y-hpsz;i<=y+hpsz;i++) {
    if ((i < 0) || (i >= gr->ny)) continue ;
    for(j=x-hpsz;j<=x+hpsz;j++) {
      if ((j < 0) || (j >= gr->nx)) continue ;
      n += 1 ;
      g = gr->ras[i][j] ;
      logp += -SQ(((double)g-c)/w) ;
    } 
  } ;
  return(logp/(double)n) ;
}
  
/******************************************************************************

  Store in each pixel in fr_mk the smallest relative probability
  that the square patch of side length 2*hpsz+1 of which pixel i in 
  gr is a member has the intensities it does.  Whoa!

  */
static rc_t mark_patchprob(const gras_t *gr, fras_t *fr_mk,
			   double c, double w, int hpsz) {

  int i,j,k,m ;
  double logpp ;
  const char *me = "mark_patchprob" ;

  if (fras_chksz(fr_mk,gr->ny,gr->nx) != OK) 
    return(memfail(__FILE__,__LINE__,me)) ;
  for(i=0;i<fr_mk->ny;i++) for(j=0;j<fr_mk->nx;j++) 
    fr_mk->ras[i][j] = -DBL_MAX ;
  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      logpp = log_patchprob(gr,c,w,j,i,hpsz) ;
      for(k=i-hpsz;k<=i+hpsz;k++) {
	if ((k < 0) || (k >= gr->ny)) continue ;
	for(m=j-hpsz;m<=j+hpsz;m++) {
	  if ((m < 0) || (m >= gr->nx)) continue ;
	  if (logpp > fr_mk->ras[k][m]) fr_mk->ras[k][m] = logpp ;
	} ;
      } ;
    } ;
  } ;
  return(OK) ;
}
  
/******************************************************************************

  Mark pixels as background 
  if they sit in square patches of side length 2*hpsz+1 with
  intensity distributions less than sdmax standard deviations different
  from the average `background' intensity distribution.  Determine
  the `background' intensity distribution by fitting a Gaussian to the
  largest amplitude peak in the intensity histogram.

  */
rc_t gras_mark_prob(const gras_t *gr, gras_t *gr_mk, 
		    int hpsz, double sdmax) {

  const double tol = 1.0e-10 ;
  const int itmax = 100 ;
  const int ng = 3 ;
  double amp[3],ctr[3],wid[3] ;
  hist_t hs ;
  fras_t fr_prob ;
  double xsq,logprob ;
  int i,j ;
  const char *me = "gras_mark_prob" ;

  if ((hist_plain(&hs,gr,1) != OK) ||
      (hist_unpad(&hs,&hs) != OK) ||
      (hist_fit_gauss(&xsq,amp,ctr,wid,&hs,tol,itmax,ng) == FATAL) )
    return(subfail(__FILE__,__LINE__,me)) ;
  /* use largest amplitude Gaussian as the background */
  sort_dd_desc(ng,amp,ctr) ;
  if (verbosity == MSG_DEBUG)
    printf("%s [%s:%d]: background Gaussian:\n   amp %f ctr %f wid %f\n",
	   me,__FILE__,__LINE__,amp[0],ctr[0],wid[0]) ;
  if (gras_chksz(gr_mk,gr->ny,gr->nx) != OK) 
    return(memfail(__FILE__,__LINE__,me)) ;
  fras_init(&fr_prob,gr->ny,gr->nx) ;
  if (mark_patchprob(gr,&fr_prob,ctr[0],wid[0],hpsz) != OK)
    return(subfail(__FILE__,__LINE__,me)) ;
  memset(gr_mk->data,0,(gr_mk->nymax)*(gr_mk->nxmax)*sizeof(unsigned)) ;
  logprob = -0.5*SQ(sdmax) ;
  for(i=0;i<gr->ny;i++) for(j=0;j<gr->nx;j++)
    if (fr_prob.ras[i][j] > logprob) gr_mk->ras[i][j] = 1 ;
  fras_free(&fr_prob) ;
  return(OK) ;
}
  
/******************************************************************************

  Copy raster gr_src to raster gr_dst, 
  enhancing contrast by linear stretching.

  */
rc_t gras_con_lin(gras_t *gr_dst, const gras_t *gr_src, int bits) {

  unsigned int min,max ;
  double f1 ;
  int i,j ;
  const char *me = "gras_con_lin" ;

  if ((gr_dst != gr_src) && (gras_chksz(gr_dst,gr_src->ny,gr_src->nx) != OK))
    return(memfail(__FILE__,__LINE__,me)) ;
  max = (1<<bits)-1 ; min = 0 ;
  f1 = (double)(max - min)/(double)(gr_src->max - gr_src->min) ;
  for(i=0;i<gr_dst->ny;i++) {
    for(j=0;j<gr_dst->nx;j++) {
      gr_dst->ras[i][j] = min + 
	(int)floor(1.0e-15 + f1*(gr_src->ras[i][j] - gr_src->min)) ;
    } ;
  } ;
  gras_maxmin(gr_dst) ;
  return(OK) ;
}  

/******************************************************************************

  Paint a black-on-white digit onto an 8x5 section of raster.  
  The actual digit occupies a 6x3 section, that is, we automatically paint 
  a 1 pixel white border around the digit.

*/
static void paint_digit(gras_t *gr, int y, int x, int digit) {

  const int patterns[10][39] = {
    {0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,1,1,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,1,1,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,1,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,1,1,0,0,0,0,1,0,0,0,0,1,
     0,0,0,0,0},
    {0,0,0,0,0,0,1,1,1,0,0,1,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,1,0,0,1,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,1,0,0,1,0,0,0,0,1,1,0,0,0,1,0,1,0,0,1,0,1,0,0,0,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,0,0,1,0,
     0,0,0,0,0},
    {0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,0,0,1,1,0,0,0,0,1,0,0,1,1,0,
     0,0,0,0,0} } ;
  int i ;
  
  for(i=0;i<=39;i++) gr->ras[y+i/5][x+(i%5)] = (patterns[digit][i] ? 0 : 255) ;
}

/******************************************************************************

  Paint a number onto a raster.

*/
void gras_paint_number(gras_t *gr, int y, int x, int num) {

  int xoff = 0 ;

  do { 
    paint_digit(gr,y-8,x-xoff,num % 10) ; num /= 10 ; xoff += 5 ; 
  } while (num) ;
}

/******************************************************************************

  Paint a vertical line onto a raster.

*/
void gras_paint_vline(gras_t *gr, int x0, int g) {

  int y ;

  for(y=0;y<gr->ny;y++) gr->ras[y][x0] = g ;

}

/******************************************************************************

  Paint a grid onto a raster.

*/
void gras_paint_grid(gras_t *gr, int y0, int x0, int dy, int dx, 
		     int g) {

  int y,x,i,j ;

  while(y0>0) y0 -= dy ; while (y0<0) y0 += dy ;
  while(x0>0) x0 -= dx ; while (x0<0) x0 += dx ;
  for(x=x0;x<gr->nx;x+=dx) for(i=0;i<gr->ny;i++) gr->ras[i][x] = g ;
  for(y=y0;y<gr->ny;y+=dy) for(j=0;j<gr->nx;j++) gr->ras[y][j] = g ;
}
