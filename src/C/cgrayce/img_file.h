/****************************************************************************/
/*                                                                          */
/*      img_file.h                                                          */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Cristopher Grayce                                     */
/*     This file is part of OME.                                            */
/*                                                                          */
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
/*   Load/dump image files, so far only in TIFF format.                     */
/*                                                                          */
/*  ==> Requires libtiff, see <http://www.libtiff.org/>                     */
/*                                                                          */
/****************************************************************************/


#ifndef _IMG_FILE_
#define _IMG_FILE_

#include "util.h"
#include "gras.h"

/* the user-modifiable output parameters */
typedef enum { 
  IMG_FILE_OUT_BITS ,          /* bits per pixel */
  IMG_FILE_OUT_COMP            /* compression scheme */
} img_file_out_parm ;

/************************************************************************

  Request to modify output parameters.

  */
extern void img_set_outparm(img_file_out_parm parm, int val) ;

/************************************************************************

 Open a TIFF file and load a grayscale raster.  
 
 */
extern rc_t tiff_load_gras(const char *fn, gras_t *gras) ;

/************************************************************************

 Open a TIFF file and dump a grayscale raster.

 */
extern rc_t tiff_dump_gras(const char *fn, gras_t *gras) ;
 
/************************************************************************

  Open a TIFF file and print first directory contents.

 */
extern rc_t tiff_info(const char *fn) ;

#endif
