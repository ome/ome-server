/****************************************************************************/
/*                                                                          */
/*  ome_tmcp.c                                                              */
/*                                                                          */
/*  OME module                                                              */
/*      performs analysis: TMCP correlation - Total Movement Cell Position  */
/*                                                                          */
/*     Author:  Brian S. Hughes (bshughes@mit.edu)                          */
/*     Copyright 2001 Brian S. Hughes                                       */
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
/*   This program finds the distance between a neuron's nucleus and its     */
/*   dendrites. It is given two images of the same field; one image         */
/*   shows only the cells' nucleii, while the other image shows only        */
/*   the dendrites. This program assumes that a dendrite belongs to         */
/*   the nucleus closest to it. The program measures the distance           */
/*   between each dendrite and its associated nucleus, and emits a          */
/*   figure that is the weighted average of all these distances in the      */
/*   image. This figure can be taken as an indication of the robustness     */
/*   of the cell sample's growth.                                           */
/*                                                                          */
/*   This program doesn't know neurons - it just calculates, for all dots   */
/*   in an image, how far away the closest dot in a second image lies.      */
/*                                                                          */
/* BUGS                                                                     */
/*  If two or more neurons overlap, it's unlikely that this program will    */
/*  accurately match each dendrite with its own neuron.                     */
/*                                                                          */
/****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "gras.h"
#include "img_file.h"
#include "obj.h"
#include "geo.h"
#include "util.h"
#include "tmcp.h"


typedef struct {
  int thold;
  verb_t verbosity;
  char* fn_tst;
  char* fn_ref;
  char* fn_msk;
  char* batch_file;
} ARGS;


/* Externally visible storage */
verb_t verbosity = MSG_FATAL;

static int skip_internals = TRUE;


/* Prototypes */
static int process_images(ARGS *argsp);
static int usage(const char *id, ARGS* argsp);
static int parse_args(int argc, char *argv[], ARGS* argsp);
static int load_images(char* tst_nm, gras_t *gr_tstp, 
		       char* ref_nm, gras_t *gr_refp);



/*****************************************************************************/
int main(int argc, char *argv[]) {

  ARGS our_args;
  int num_scan;
  int stat = OK;
  FILE* fp;

  our_args.batch_file = NULL;
  /* First parse input arguments */
  if (parse_args(argc, argv, &our_args) == FALSE)
    return(usage(argv[0], &our_args));

  /* If user provided a batch file, process it line by line */
  if (our_args.batch_file) {
    if ((fp = fopen(our_args.batch_file, "r")) == NULL) {
      stat = FATAL;
    }
    else {
      while (!feof(fp)) {
	num_scan = fscanf(fp, "%as%as%d", &our_args.fn_tst, &our_args.fn_ref,
	       &our_args.thold);
	if (num_scan == 3) {
	  if (process_images(&our_args) == FALSE) {
	    stat = FATAL;
	  }
	  free(our_args.fn_tst);
	  free(our_args.fn_ref);
	}
	else if (!feof(fp)) {
	  if (our_args.verbosity != MSG_NONE) {
	    printf("Error reading input list from %s\n", our_args.batch_file);
	  }
	  stat = FATAL;
	  break;
	}
      }
    }
  }
  else {
    if (process_images(&our_args) == FALSE) {
      stat = FATAL;
    }
  }

  return(stat);
}



/* Process the input images, and produce a single numberic score from the
 * analysis. First load the images into a gras_t structure via the
 * routine load_images(). Next find the minimum distance between every spot
 * above a background level in the 2nd image, and one of the non-null spots
 * in the 1st image. Each minimum distance gets weighted by the intensity
 * of the reference spot. The numeric score is the ratio of the sum of
 * the weighted distances to the sum of the reference dots' intensities.
 */

static int process_images(ARGS *argsp)
{
  gras_t gr_tst, gr_ref;
  int was_blank;
  long signalSum=0;
  double weightedDistance=0;
  double averageDistance=0;

  if ((argsp->verbosity == MSG_WARN) || (argsp->verbosity == MSG_DEBUG)) {
    printf("%s\t%s %d\n", argsp->fn_tst, argsp->fn_ref, argsp->thold);
  }
  if (load_images(argsp->fn_tst, &gr_tst,
		  argsp->fn_ref, &gr_ref) == FALSE)
    return(FALSE);


  distanceBetween(argsp->thold, &gr_tst, &gr_ref, &signalSum,
		  &weightedDistance, &was_blank, argsp->verbosity, skip_internals);

  averageDistance=weightedDistance/signalSum;

  if (argsp->verbosity != MSG_NONE) {
    if (was_blank != 1) 
      printf("%f\n", averageDistance);
    if (was_blank == 1) 
      printf("%s\n", "NaN");
  }
  
  return(OK);
}



/******************************************************************************

  Usage complaint.

  */
static int usage(const char *id, ARGS* argsp) {

  const char *fmt =
    "\n"
    "Usage: %s [options] test_imagefile ref_imagefile\n"
    "       Returns TMCP correlation.\n"
    "  Options:\n"
    "   -v <n>              \tSet verbosity to n (%d=debug,%d=all,%d=fatal,%d=none)\n"
    "   -i                  \tInclude points inside objects in calculations\n"
    "   -t <threshold_value>\tSet threshold value in test image (default=0)\n"
    "                        Ignored if -f option present\n"
    "   -f <batch file name>\tUse file containing lines of the form:\n"
    "                        <test file name> <ref filename> <threshold>\n"
    "\n";
    
  if (argsp->verbosity != MSG_NONE) 
    printf(fmt, id, MSG_DEBUG, MSG_WARN, MSG_FATAL, MSG_NONE);
  return(FATAL) ;
}

/******************************************************************************

  Argument parser

  */

static int parse_args(int argc, char *argv[], ARGS* argsp)
{
  int ai   = 1;
  int success = TRUE;
  int batch = FALSE;

  argsp->thold = 0;
  argsp->verbosity = MSG_WARN;
  argsp->fn_tst = argsp->fn_ref = NULL;

  for (ai = 1;  ((argc > ai) && (*(argv[ai]) == '-')); ai++) {
    switch(*(argv[ai]+1)) {
    case 'f' :
      batch = TRUE;
      if (++ai >= argc)
	success = FALSE;
      else
	argsp->batch_file = argv[ai];
      break;
    case 't' :
      if (++ai >= argc)
	success = FALSE;
      else
	argsp->thold = atoi(argv[ai]);
      break;
    case 'v' :
      if (++ai >= argc)
	success = FALSE;
      else
	argsp->verbosity = atoi(argv[ai]);
      break;
    case 'i':
      skip_internals = FALSE;
      break;
    default :
      success = FALSE;
    }

    if (batch == TRUE)
      break;
  }

  if ((success) && (!batch)) {
      if (ai >= argc)
	success = FALSE;
      else {
	argsp->fn_tst = argv[ai++] ;
	if (ai >= argc)
	  success = FALSE;
	else
	  argsp->fn_ref = argv[ai++];
      }
    }

  verbosity = argsp->verbosity;

  return(success);
}



/*****************************************************************************/
/*                                                                           */
/*     Load in image files, and optionally a mask file                       */

static int load_images(char* tst_nm, gras_t *gr_tstp, 
		       char* ref_nm, gras_t *gr_refp)
{
  int  stat = FALSE;

  gras_init(gr_tstp, 0, 0);
  gras_init(gr_refp, 0,0);
  if (tiff_load_gras(tst_nm, gr_tstp) == OK) {
    if (tiff_load_gras(ref_nm, gr_refp) == OK) {
      stat = TRUE;
    }
  }

  return(stat);
}


