/************************************************************************

   Copy a grayscale TIFF image while altering stuff.

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
#include "img_file.h"
#include "gras.h"
#include "util.h"

verb_t verbosity = MSG_WARN ;

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "Usage: %s [options] inputfile [outputfile]\n"
    "Options:\n"
    "   -b <n>\tConvert to n-bit grayscale (n=8,16)\n"
    "   -C <n>\tMaximize contrast by method n (1=linear)\n"
    "   -c <n>\tConvert to compression n (1=none,5=LZW)\n"
    "Copy grayscale TIFF file, possibly altering it.\n"
    ;
  printf(fmt,id) ;
  return(FATAL) ;
}

/************************************************************************

  The walrus.

*/
int main(int argc, char *argv[]) {

  int bits = 8 ;
  int comp = 1 ;
  int con = 0 ;
  gras_t g1 ;
  int ai ;
  char *fn_in,*fn_out,*arg ;

  /* parse options, if given */
  ai = 1 ;
  while ((ai < argc) && *(argv[ai]) == '-') {
    arg = argv[ai]+1 ;
    if (!strcmp("b",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      bits = atoi(argv[ai]) ;
      if ((bits != 8) && (bits != 16)) return(badarg(argv[ai])) ;
    } else if (!strcmp("c",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      comp = atoi(argv[ai]) ;
      if ((comp != 1)  && (comp != 5)) return(badarg(argv[ai])) ;
    } else if (!strcmp("C",arg)) {
      if ((ai += 1) >= argc) return(usage(argv[0])) ;
      con = atoi(argv[ai]) ;
      if (con != 1) return(badarg(argv[ai])) ;
    } else {
      return(usage(argv[0])) ;
    } ;
    ai += 1 ;
  } ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_out = fn_in = argv[ai++] ;
  if (ai < argc) fn_out = argv[ai++] ;

  gras_init(&g1,0,0) ;
  if (tiff_load_gras(fn_in,&g1) != OK) return(FATAL) ;

  /* make sure we don't lose information if we are squeezing image */
  if ((gras_depth(&g1) > bits) && (con == 0)) {
    printf("image is losing depth => setting contrast stretch.\n") ;
    con = 1 ;
  } ;

  switch (con) {
  default :
  case 0 :
    break ;
  case 1 :
    if (gras_con_lin(&g1,&g1,bits) != OK) return(FATAL) ;
    break ;
  } ;

  img_set_outparm(IMG_FILE_OUT_BITS,bits) ;
  img_set_outparm(IMG_FILE_OUT_COMP,comp) ;
  /* avoid tragedy */
  if (fn_out == fn_in) {
    fn_out = fn_unique(fn_out) ;
    printf("dumping new image to \"%s\".\n",fn_out) ;
  } ;
  if (tiff_dump_gras(fn_out,&g1) != OK) return(FATAL) ;
  return(OK) ;
}


  
