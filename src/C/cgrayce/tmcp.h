/****************************************************************************/
/*                                                                          */
/*  tmcp.h                                                                  */
/*                                                                          */
/*   header file to accompany ome_tmcp.c                                    */
/*                                                                          */
/*   Author:  Brian S. Hughes (bshughes@mit.edu)                            */
/*   Copyright 2001 Brian S. Hughes                                         */
/*   This file is part of OME.                                              */
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
/*                                                                          */
/****************************************************************************/

#ifndef _OME_PKG_H
#define _OME_PKG_H

#include "gras.h"

#define TRUE 1
#define FALSE 0

int distanceBetween(int imageThreshold, gras_t* gr_tstp, gras_t* gr_refp, long* signalSump, double* weightedDistancep, int* was_blank, int verbosity, int skip_internals);


#endif
