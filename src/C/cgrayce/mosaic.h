/****************************************************************************/
/*                                                                          */
/*  mosaic.h                                                                */
/*                                                                          */
/*  header file to accompany mosaic.c                                       */
/*                                                                          */
/*  We sometimes want to paint several objects onto one `mosaic' image      */
/*  raster, so we can look at them all at once.                             */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
/*     This file is part of OME.                                            */
/*                                                                          */ 
/*     OME is free software; you can redistribute it and/or modify          */
/*     it under the terms of the GNU Lesser General Public License as       */
/*     published by the Free Software Foundation; either version 2.1 of     */
/*     the License, or (at your option) any later version.                  */
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

#ifndef _MOSAIC_
#define _MOSAIC_

#include "obj.h"  
#include "geo.h"
#include "gras.h"

/* various options to the mosaic makers */
#define MOSAIC_SILH  (1<<1)     /* draw silhouettes of objects only */
#define MOSAIC_ID    (1<<2)     /* draw object numbers on objects */
#define MOSAIC_GRID  (1<<3)     /* draw a grid on the mosaic */
#define MOSAIC_OBJ_VLINE (1<<4)  /* draw a vertical bar after every object */

/******************************************************************************

  Dump a black-and-white identification mosaic image.

  => if (gr != 0) the mosaic raster is set to exactly the same size as gr.  
     Otherwise the mosaic will be just big enough to hold the objects.
     This may be smaller than the original raster.

*/
extern rc_t mosaic_dump(const objl_t *ol, const char *fn, const gras_t *gr) ;

/******************************************************************************

  Dump a black-and-white identification mosaic image,
  with the objects in one long strip sorted according to prop.

*/
extern rc_t mosaic_dump_sort(objl_t *ol, const char *fn, geo_t prop) ;

#endif
