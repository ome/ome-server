/****************************************************************************/
/*                                                                          */
/*  ome_info.c                                                              */
/*                                                                          */
/*  OME module                                                              */
/*       Examine properties of an image file.                               */
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
#include "gras.h"
#include "img_file.h"
#include "util.h"

#define DO_PIXEL  (1<<0)

verb_t verbosity = MSG_DEBUG ;

static int do_mode = 0 ;

/************************************************************************

  Usage complaint.

  */
static int usage(const char *id) {

  const char *fmt = 
    "\nUsage: %s [options] imagefile\n\n"
    "Prints information about a TIFF image file.\n\n"
    "Options:\n"
    "   -p   \tPrint all pixel values.\n"
    ;
  printf(fmt,id) ;
  return(FATAL) ;
}

/************************************************************************

  The walrus.

  */
int main(int argc, char *argv[]) {

  gras_t gr ;
  int ai,xi,yi ;
  char *arg,*fn_in ;

  /* parse options, if given */
  ai = 1 ;
  while ((ai < argc) && *(argv[ai]) == '-') {
    arg = argv[ai]+1 ;
    if (!strcmp("p",arg)) {
      do_mode |= DO_PIXEL ;
    } else {
      return(usage(argv[0])) ;
    } ;
    ai += 1 ;
  } ;
  if (ai >= argc) return(usage(argv[0])) ;
  fn_in = argv[ai++] ;

  /* load image file */
  gras_init(&gr,0,0) ;
  if (tiff_load_gras(fn_in,&gr) != OK) return(FATAL) ;

  printf("pixel max,min: %d,%d\n",gr.max,gr.min) ;

  if (do_mode & DO_PIXEL) {
    printf("actual pixel values:\n") ;
    printf("     ") ; for(xi=0;xi<gr.nx;xi++) printf("%5d ",xi); printf("\n") ; 
    printf("    |") ; for(xi=0;xi<gr.nx;xi++) printf("------") ; printf("\n") ;
    for(yi=0;yi<gr.ny;yi++) {
      printf("%3d |",yi) ;
      for(xi=0;xi<gr.nx;xi++) printf("%5d ",gr.ras[yi][xi]) ; printf("\n") ;
    } ;
  } ;

  return(OK) ;
}
  
  

      


  
