/************************************************************************

   Make test images.

*/
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <limits.h>
#include "img_file.h"
#include "gras.h"
#include "util.h"

verb_t verbosity = MSG_WARN ;

static enum { 
  P_CHECKS, 
  P_STRIPES, 
  P_GRAD,
  P_DGRAD, 
  P_DISK, 
  P_ROSETTE, 
  P_SQUARE,
  P_RECT
} pattern = P_CHECKS ;

static enum gmode_t { MODE_PLAIN, MODE_GAUSSIAN } bg_mode = MODE_PLAIN ;
static enum gmode_t fg_mode = MODE_PLAIN ;
static enum sz_mode_t {SZ_FIXED, SZ_RANDOM } sz_mode = SZ_FIXED ;

static double bg_mean,bg_sdev,fg_mean,fg_sdev ;
static unsigned pixmin = 0 ;
static unsigned pixmax = 255 ;
static int fszmin = 8 ;
static int fszmax = 8 ;
static int fnum = 1 ;

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "Usage: %s [options] imagefile\n"
    "Options:\n"
    "   -b <n>            \tUse n bits/pixel (n=8,16 only; default n=8)\n"
    "   -size <n>         \tSet image size to n x n pixels (default n=64)\n"
    "   -fsize <min>,<max>\tSet feature size to between min and max pixels\n"
    "                     \t   (default min=8,max=8)\n"
    "   -fnum <n>         \tSet feature number n (default n=1)\n"
    "   -max <n>          \tSet max gray to n (default 2^bits-1)\n"
    "   -min <n>          \tSet min gray to n (default 0)\n"
    "   -checks           \tMake checkerboard.\n"
    "   -stripes          \tMake stripes.\n"
    "   -grad             \tMake gradient.\n"
    "   -dgrad            \tMake gradient in both axes.\n"
    "   -disk             \tMake disk(s).\n"
    "   -rose             \tMake rosette(s).\n"
    "   -square           \tMake square(s).\n"
    "   -rect             \tMake rectangle(s).\n"
    "   -vsize            \tRandomly vary size of multiple features.\n"
    "   -Gfg <mean>,<sdev>\tUse Gaussian probability distribution of grays\n"
    "                     \t   for foreground with given mean and standard\n"
    "                     \t   deviation.  mean and deviation expressed as\n"
    "                     \t   fractions of min->max range.\n"
    "   -Gbg <mean>,<sdev>\tUse Gaussian probability distribution of grays\n"
    "                     \t   for background.\n"
    "   -c <n>            \tSet compression n (1=none,5=LZW, default=1)\n"
    "Create a TIFF file containing a test pattern.\n"
    ;
  printf(fmt,id) ;
  return(FATAL) ;
}

/************************************************************************

  Return grays.

*/
static void get_grays(unsigned *gbg, unsigned *gfg) {

  double v ;
  unsigned bg,fg ;

  switch (bg_mode) {
  default :
  case MODE_PLAIN :
    bg = pixmin ; 
    break ;
  case MODE_GAUSSIAN :
    v = (pixmax-pixmin)*(bg_mean + bg_sdev * random_gauss()) ;
    bg = MIN(pixmax,MAX(0,(unsigned)floor(v))) ;
    break ;
  } ;
  switch (fg_mode) {
  default :
  case MODE_PLAIN :
    fg = pixmax ;
    break ;
  case MODE_GAUSSIAN :
    v = (pixmax-pixmin)*(fg_mean + fg_sdev * random_gauss()) ;
    fg = MIN(pixmax,MAX(0,(unsigned)floor(v))) ;
    break ;
  } ;
  *gbg = bg ; *gfg = fg ;
}

/************************************************************************

  Return size of feature.

*/
static void get_size(int *szmin, int *szmax) {

  int tmp ;

  switch (sz_mode) {
  default :
  case SZ_FIXED :
    *szmin = fszmin ; *szmax = fszmax ;
    break ;
  case SZ_RANDOM :
    *szmin = fszmin + (int)floor((fszmax-fszmin) * DRAND) ;
    *szmax = fszmin + (int)floor((fszmax-fszmin) * DRAND) ;
    if (*szmax < *szmin) 
      { tmp = *szmax ; *szmax = *szmin ; *szmin = tmp ; } ;
    break ;
  } ;
}

/************************************************************************

  Blank.

*/
static void gras_p_blank(gras_t *gr) {

  unsigned gmin,gmax ;
  int i,j ;

  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      get_grays(&gmin,&gmax) ;
      gr->ras[i][j] = gmin ;
    } ;
  } ;
}

/************************************************************************

  Checkerboard.

*/
static void gras_p_checks(gras_t *gr, int sz) {

  unsigned sgn,gmin,gmax ;
  int i,j ;

  sgn = 0 ;
  for(i=0;i<gr->ny;i++) {
    sgn = ((i/sz) & 1) ;
    for(j=0;j<gr->nx;j++) {
      if (j && !(j % sz)) sgn = !sgn ;
      get_grays(&gmin,&gmax) ;
      gr->ras[i][j] = (sgn ? gmin : gmax) ;
    } ;
  } ;
}

/************************************************************************

  Stripes.

*/
static void gras_p_stripes(gras_t *gr, int sz) {

  unsigned sgn,gmin,gmax ;
  int i,j ;

  for(i=0;i<gr->ny;i++) {
    sgn = 0 ;
    for(j=0;j<gr->nx;j++) {
      if (!(j % sz)) sgn = !sgn ;
      get_grays(&gmin,&gmax) ;
      gr->ras[i][j] = (sgn ? gmin : gmax) ;
    } ;
  } ;
}

/************************************************************************

 x Gradient.

*/
static void gras_p_xgrad(gras_t *gr) {

  unsigned gv,gmin,gmax ;
  int i,j ;

  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      get_grays(&gmin,&gmax) ;
      gv = (int)floor(1.0e-16 + (double)gmin + 
		      (gmax-gmin)*(double)j/(double)(gr->nx - 1)) ;
      gr->ras[i][j] = gv ;
    } ;
  } ;
}

/************************************************************************

 xy Gradient.

*/
static void gras_p_xygrad(gras_t *gr) {

  unsigned gv,gmin,gmax ;
  int i,j ;

  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      get_grays(&gmin,&gmax) ;
      gv = (int)floor(1.0e-16 + (double)gmin + 
		      (gmax-gmin)*(double)(i+j)/(double)(2*gr->nx - 2)) ;
      gr->ras[i][j] = gv ;
    } ;
  } ;
}

/************************************************************************

  Square.

*/
static void gras_o_square(gras_t *gr, int y0, int x0) {

  unsigned gmin,gmax ;
  int i,j,nr,nc,x,y,min,max ;

  get_size(&min,&max) ;
  nr = nc = (int)floor(max/sqrt(2.0)) ;
  for(i=0;i<nr;i++) {
    for(j=0;j<nc;j++) {
      y = y0 - nr/2 + i ; x = x0 - nc/2 + j ;
      if ((x < 0) || (x >= gr->nx) || (y < 0) || (y >= gr->ny)) continue ;
      if ((fabs(y-y0) > max/2) || (fabs(x-x0) > max/2)) continue ;
      get_grays(&gmin,&gmax) ;
      gr->ras[y][x] = gmax ;
    } ;
  } ;
}

/************************************************************************

  Rectangle.

*/
static void gras_o_rect(gras_t *gr, int y0, int x0) {

  unsigned gmin,gmax ;
  int i,j,x,y,min,max ;

  get_size(&min,&max) ;
  printf("%d %d\n",min,max) ;
  for(i=0;i<max;i++) {
    for(j=0;j<min;j++) {
      y = y0 - max/2 + i ; x = x0 - min/2 + j ;
      if ((x < 0) || (x >= gr->nx) || (y < 0) || (y >= gr->ny)) continue ;
      if ((fabs(y-y0) > max/2) || (fabs(x-x0) > min/2)) continue ;
      get_grays(&gmin,&gmax) ;
      gr->ras[y][x] = gmax ;
    } ;
  } ;
}

/************************************************************************

  Disk

*/
static void gras_o_disk(gras_t *gr, int y0, int x0) {

  unsigned gmin,gmax ;
  int i,j,nr,nc,x,y,min,max ;

  get_size(&min,&max) ;
  nr = nc = max ;
  for(i=0;i<nr;i++) {
    for(j=0;j<nc;j++) {
      y = y0 - nr/2 + i ; x = x0 - nc/2 + j ;
      if ((x < 0) || (x >= gr->nx) || (y < 0) || (y >= gr->ny)) continue ;
      if ( SQ(y - y0) + SQ(x - x0) > SQ(0.5*max)) continue ;
      get_grays(&gmin,&gmax) ;
      gr->ras[y][x] = gmax ;
    } ;
  } ;
}

/************************************************************************

  Rosette.

*/
static void gras_o_rosette(gras_t *gr, int y0, int x0) {

  const int nr = 3 ;
  const int nc = 3 ;
  unsigned gmin,gmax ;
  int i,j,x,y ;
  const unsigned pattern[3][3] = {{1,0,1},
				  {0,1,0},
				  {1,0,1}} ;

  for(i=0;i<nr;i++) {
    for(j=0;j<nc;j++) {
      y = y0 + i ; x = x0 + j ;
      if ((x < 0) || (x >= gr->nx) || (y < 0) || (y >= gr->ny)) continue ;
      if (!pattern[i][j]) continue ;
      get_grays(&gmin,&gmax) ;
      gr->ras[y][x] = gmax ;
    } ;
  } ;
}

/************************************************************************

  Scatter features randomly but self-avoidingly.

*/
static void gras_p_scatter(gras_t *gr,
			   void (*gras_o)(gras_t *gr,int y0, int x0)) {

  int *xbeen,*ybeen ;
  unsigned gmin,gmax ;
  int n,x0,y0,i,j,k,try ;

  if (!(xbeen = (int *)malloc(fnum * sizeof(int))) ||
      !(ybeen = (int *)malloc(fnum * sizeof(int))) ) return ;
  for(i=0;i<gr->ny;i++) {
    for(j=0;j<gr->nx;j++) {
      get_grays(&gmin,&gmax) ;
      gr->ras[i][j] = gmin ;
    } ;
  } ;
  for(n=0;n<fnum;n++) {
    k = 0 ;
    x0 = (int)floor(gr->nx * DRAND) ;
    y0 = (int)floor(gr->ny * DRAND) ;
    for(try=0;(try<10000)&&(k<n);try++) {
      x0 = (int)floor(gr->nx * DRAND) ;
      y0 = (int)floor(gr->ny * DRAND) ;
      for(k=0;k<n;k++) {
	if (SQ(x0-xbeen[k]) + SQ(y0-ybeen[k]) < SQ(fszmax)) break ;
      } ;
    } ;
    if (k<n) break ;
    gras_o(gr,y0,x0) ;
    xbeen[n] = x0 ; ybeen[n] = y0 ;
  } ;
  free(xbeen) ;
  free(ybeen) ;
}

/************************************************************************

  The walrus.

*/
int main(int argc, char *argv[]) {

  int bits = 8 ;
  int comp = 1 ;
  int size = 64 ;
  gras_t gr ;
  int ai ;
  char *arg, *fn_out ;

  /* parse options, if given */
  ai = 1 ;
  while ((ai < argc) && *(argv[ai]) == '-') {
    arg = argv[ai]+1 ;
    if (!strcmp("b",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      bits = atoi(argv[ai]) ;
      if ((bits != 8) && (bits != 16)) return(badarg(argv[ai])) ;
      pixmax = (1<<bits)-1 ;
    } else if (!strcmp("size",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      size = atoi(argv[ai]) ;
    } else if (!strcmp("fsize",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      if (!getarg_ii(argv[ai],&fszmin,&fszmax)) return(badarg(argv[ai])) ;
    } else if (!strcmp("fnum",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      fnum = atoi(argv[ai]) ;
    } else if (!strcmp("max",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      pixmax = atoi(argv[ai]) ;
    } else if (!strcmp("min",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      pixmin = atoi(argv[ai]) ;
    } else if (!strcmp("checks",arg)) {      
      pattern = P_CHECKS ;
    } else if (!strcmp("stripes",arg)) {      
      pattern = P_STRIPES ;
    } else if (!strcmp("grad",arg)) {      
      pattern = P_GRAD ;
    } else if (!strcmp("dgrad",arg)) {      
      pattern = P_DGRAD ;
    } else if (!strcmp("disk",arg)) {      
      pattern = P_DISK ;
    } else if (!strcmp("rose",arg)) {      
      pattern = P_ROSETTE ;
    } else if (!strcmp("square",arg)) {      
      pattern = P_SQUARE ;
    } else if (!strcmp("rect",arg)) {      
      pattern = P_RECT ;
    } else if (!strcmp("vsize",arg)) {      
      sz_mode = SZ_RANDOM ;
    } else if (!strcmp("Gfg",arg)) {      
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      if (!getarg_dd(argv[ai],&fg_mean,&fg_sdev)) return(badarg(argv[ai])) ;
      fg_mode = MODE_GAUSSIAN ;
    } else if (!strcmp("Gbg",arg)) {      
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      if (!getarg_dd(argv[ai],&bg_mean,&bg_sdev)) return(badarg(argv[ai])) ;
      bg_mode = MODE_GAUSSIAN ;
    } else if (!strcmp("c",arg)) {      
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      comp = atoi(argv[ai]) ;
      if ((comp != 1)  && (comp != 5)) return(badarg(argv[ai])) ;
    } else {
      return(usage(argv[0])) ;
    } ;
    ai += 1 ;
  } ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_out = argv[ai++] ;

  if (gras_init(&gr,size,size) != OK) return(FATAL) ;
  srandom(time(0)) ;
  if (pixmax > (1<<bits)-1) pixmax = (1<<bits)-1 ;

  switch (pattern) {
  default :
  case P_CHECKS :
    gras_p_checks(&gr,fszmax) ;
    break ;
  case P_STRIPES :
    gras_p_stripes(&gr,fszmax) ;
    break ;
  case P_GRAD :
    gras_p_xgrad(&gr) ;
    break ;
  case P_DGRAD :
    gras_p_xygrad(&gr) ;
    break ;
  case P_DISK :
    if (fnum == 1) {
      gras_p_blank(&gr) ;
      gras_o_disk(&gr,gr.ny/2,gr.nx/2) ;
    } else {
      gras_p_scatter(&gr,gras_o_disk) ;
    } ;
    break ;
  case P_ROSETTE :
    if (fnum == 1) {
      gras_p_blank(&gr) ;
      gras_o_rosette(&gr,gr.ny/2,gr.nx/2) ;
    } else {
      gras_p_scatter(&gr,gras_o_rosette) ;
    } ;
    break ;
  case P_SQUARE :
    if (fnum == 1) {
      gras_p_blank(&gr) ;
      gras_o_square(&gr,gr.ny/2,gr.nx/2) ;
    } else {
      gras_p_scatter(&gr,gras_o_square) ;
    } ;
    break ;
  case P_RECT :
    if (fnum == 1) {
      gras_p_blank(&gr) ;
      gras_o_rect(&gr,gr.ny/2,gr.nx/2) ;
    } else {
      gras_p_scatter(&gr,gras_o_rect) ;
    } ;
    break ;
  } ;

  img_set_outparm(IMG_FILE_OUT_BITS,bits) ;
  img_set_outparm(IMG_FILE_OUT_COMP,comp) ;

  if (verbosity < MSG_FATAL)
    printf("Dumping image to \"%s\".\n",fn_out) ;

  if (tiff_dump_gras(fn_out,&gr) != OK) return(FATAL) ;
  return(OK) ;
}


  
