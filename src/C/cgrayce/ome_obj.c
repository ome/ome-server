/************************************************************************

   Find objects in a TIFF grayscale image and report their properties.

*/
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>
#include "util.h"
#include "img_file.h"
#include "gras.h"
#include "hist.h"
#include "mosaic.h"
#include "obj.h"
#include "geo.h"

/* we ignore objects not entirely within the image frame */
#define IGNORE_PARTIALS  (1)

/* modes for defining background */
typedef enum { BG_THRESH, BG_PROB } bg_mode_t ;

/* different things we might do */
#define DO_NOTHING (1<<0) 
#define DO_INFO    (1<<1) 
#define DO_DUMP    (1<<2)
#define DO_MOSAIC  (1<<3)

static int       do_mode = DO_NOTHING ;
static bg_mode_t bg_mode = BG_THRESH ;
static geo_t s_mode = GEO_NONE ;  /* constants defined in geo.h */
static geo_t p_mode = GEO_NONE ;
static int bgmin = 0 ; 
static int bgmax = 1 ;
static int hpsz = 1 ;
static double sdmax = 2.0 ;
static int obg = 0 ;
static int obits = 0 ;
static char fn_info[255] = "" ;
static const char *suffix_info = "_info.dat" ;
static char fn_mosaic[255] = "" ;
static const char *suffix_mosaic = "_ID-mosaic.tif" ;
static char dir_dump[255] = "" ;
static const char *suffix_dump = "_objs" ;
static char mosaic_pos[5] = "" ;
/* default = ignore very small objects, change by setting -Parea */
static int amin = 10 ;      
static int amax ;
static double pmin,pmax ;
static char *fn_in ;

verb_t verbosity = MSG_WARN ;

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "\nUsage: %s [options] imagefile\n\n"
    "Describes foreground objects in an image file.\n\n"
    "Options:\n\n"
    "   -Bthresh [<min>,<max>]\n"
    "      Define the background by graylevel threshold:\n"
    "      All pixels >= min and < max (default min=%d,max=%d) are considered\n"
    "      background. This is the default background definition.\n\n"
    "   -Bprob [<sz>,<sd>]\n"
    "      Define the background by graylevel probability:\n"
    "      First, determine background graylevel probability distribution\n"
    "      by fitting Gaussians to the image graylevel histogram.  Then,\n"
    "      define a pixel as background if it and its nearest neighbors in a\n"
    "      square patch of side length 2*sz+1 (default sz=%d) are less than\n"
    "      sd standard deviations different from the average background\n"
    "      patch (default sd=%5.2f).\n\n"
    "   -P<prop> <min>,<max>\n"
    "      Prune objects, permitting only those to remain which have prop\n"
    "      between min and max to remain.  prop must be one of: area,aspect,\n"
    "      or comp, meaning respectively object area measured in pixels,\n"
    "      object aspect (width/length) ratio, varying between 0.0 and 1.0,\n"
    "      and object compactness, varying between 1.0 (most compact) and\n"
    "      +infinity (most ramified).\n\n"
    "   -S<prop>\n"
    "      Sort objects by prop, where prop is one of area,aspect,comp.\n\n"
    "   -info [fn=<filename>]\n"
    "      Write a text data file describing objects found and not pruned.\n\n"
    "   -mosaic [pos=<pos>] [fn=<filename>]\n"
    "      Write an image file showing silhouettes of objects found.\n"
    "      If given, pos specifies positions of the objects in the image,\n"
    "      pos=org means use the original positions in the image, pos=sort\n"
    "      means let the positions depend on the results of any sorting.\n"
    "      Default is pos=org.\n\n"
    "   -dump [obg] [dir=<dirname>]\n"
    "      Write each object found to a separate image file in a separate\n"
    "      directory, with background gray level obg (default obg=%d).\n\n"
    "   -b <n>\n"
    "      Set bits/pixel of output images to n (default n=bits/pixel of\n"
    "      input image, except for mosaics, which are always 8-bit).\n\n"
    "   -v <n>\n"
    "      Set verbosity n, 0=debug,1=warn,2=fatal,3=none (default n=%d).\n\n"
    ;
    
  if (verbosity != MSG_NONE) printf(fmt,id,bgmin,bgmax,hpsz,sdmax,obg,
				    verbosity) ;
  return(FATAL) ;
}
 
/************************************************************************

  The walrus.

*/
int main(int argc, char *argv[]) {

  gras_t gr_in,gr_mk ;
  objl_t ol ;
  int ai ;
  char *arg,*fn ;

  /* parse options */
  ai = 1 ;
  while ((ai < argc) && *(argv[ai]) == '-') {
    arg = argv[ai]+1 ;
    if (!strcmp("Bthresh",arg)) {
      if ((ai+1 < argc) && getarg_ii(argv[ai+1],&bgmin,&bgmax)) ai += 1 ;
      bg_mode = BG_THRESH ;
    } else if (!strcmp("Bprob",arg)) {
      if ((ai+1 < argc) && getarg_id(argv[ai+1],&hpsz,&sdmax)) ai += 1 ;      
      bg_mode = BG_PROB ;
    } else if (!strncmp("P",arg,1)) {
      if ((p_mode = s2geo(arg+1)) == GEO_NONE) return(badarg(arg)) ;
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      if (p_mode == GEO_AREA) {
	if (!getarg_ii(argv[ai],&amin,&amax)) return(badarg(argv[ai])) ;
      } else {
	if (!getarg_dd(argv[ai],&pmin,&pmax)) return(badarg(argv[ai])) ;
      } ;
    } else if (!strncmp("S",arg,1)) {
      if ((s_mode = s2geo(arg+1)) == GEO_NONE) return(badarg(arg)) ;      
    } else if (!strcmp("info",arg)) {
      if ((ai+1 < argc) && getarg_s(argv[ai+1],"fn",fn_info)) ai += 1;
      do_mode |= DO_INFO ;
    } else if (!strcmp("dump",arg)) {
      if ((ai+1 < argc) && getarg_i(argv[ai+1],&obg)) ai += 1 ;
      if ((ai+1 < argc) && getarg_s(argv[ai+1],"dir",dir_dump)) ai += 1;
      do_mode |= DO_DUMP ;
    } else if (!strcmp("mosaic",arg)) {
      if ((ai+1 < argc) && getarg_s(argv[ai+1],"pos",mosaic_pos)) ai += 1;
      if ((ai+1 < argc) && getarg_s(argv[ai+1],"fn",fn_mosaic)) ai += 1;
      do_mode |= DO_MOSAIC ;
    } else if (!strcmp("b",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;      
      obits = atoi(argv[ai]) ;
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

  /* load image */
  gras_init(&gr_in,0,0) ;
  if (tiff_load_gras(fn_in,&gr_in) != OK) return(FATAL) ;
  if (!obits) obits = gras_depth(&gr_in) ;

  /* define the background */
  gras_init(&gr_mk,gr_in.ny,gr_in.nx) ;
  switch (bg_mode) {
  default :
  case BG_THRESH :
    if (gras_mark_gray(&gr_in,&gr_mk,bgmin,bgmax) != OK) return(FATAL) ;
    break ;
  case BG_PROB :
    if (gras_mark_prob(&gr_in,&gr_mk,hpsz,sdmax) != OK) return(FATAL) ;
    break ;
  } ;

  /* get all the foreground objects */
  objl_init(&ol,100) ;
  if (objl_marked(&ol,&gr_in,&gr_mk,amin,IGNORE_PARTIALS) != OK) return(FATAL);

  /* prune unwanted objects */
  if (p_mode == GEO_AREA) {
    if (geo_prune_i(&ol,p_mode,amin,amax) != OK) return(FATAL) ;
  } else {
    if (geo_prune_f(&ol,p_mode,pmin,pmax) != OK) return(FATAL) ;    
  } ;

  /* sort */
  geo_sort(&ol,s_mode,0) ;

  /* take any further indicated action */
  if (do_mode & DO_INFO) {
    fn = fn_related(fn_info,fn_in,suffix_info,0) ;
    geo_dump_info(&ol,fn,s_mode,fn_in) ;
  } ;
  if (do_mode & DO_MOSAIC) {
    fn = fn_related(fn_mosaic,fn_in,suffix_mosaic,0) ;    
    if (!strlen(mosaic_pos) || !strncasecmp(mosaic_pos,"org",3)) {
      mosaic_dump(&ol,fn,&gr_in) ;
    } else {
      mosaic_dump_sort(&ol,fn,0) ;
    } ;
  } ;
  fn = fn_related(dir_dump,fn_in,suffix_dump,0) ;
  if (do_mode & DO_DUMP) objl_dump_img(&ol,fn,obg,obits) ;
  
  if (verbosity < MSG_NONE) printf("Found %d objects\n",ol.n) ;

  return(OK) ;
}


  
