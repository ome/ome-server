/****************************************************************************/
/*                                                                          */
/*   geo.h                                                                  */
/*   header file to accompany geo.c                                         */
/*                                                                          */
/*  Routines to calculate & make use of the geometric properties of objects */
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
/*                                                                          */
/****************************************************************************/

#ifndef _GEO_
#define _GEO_

/* the kinds of object properties we know about */
typedef enum { 
  GEO_NONE = 0,  /* a place holder meaning nothing => must be zero, tho' */
  GEO_AREA,      /* area */
  GEO_ASPECT,    /* aspect ratio (width/length) */
  GEO_RG,        /* square radius of gyration Rg^2 */
  GEO_RRG,       /* Rg^2 / Rg^2 of an ellipse of same area,aspect ratio */
  GEO_AXIS       /* principal axis (where it points */
} geo_t ;

/************************************************************************

  Convert between names and types of properties.

  */
extern geo_t s2geo(const char *name) ;

/******************************************************************************

  Center of mass, relative to object origin.

*/
extern void geo_com_rel(const obj_t *ob, double *ycom, double *xcom) ;

/******************************************************************************

  Center of mass.

*/
extern void geo_com(const obj_t *ob, double *ycom, double *xcom) ;

/******************************************************************************

  Radius of gyration squared.

*/
double geo_rg2(const obj_t *ob) ;

/******************************************************************************

  Principal moments of inertia.

*/
void geo_moi(const obj_t *ob, double *mbig, double *msmall) ;

/******************************************************************************

  Aspect ratio: 
  defined as the ratio of the smaller to the larger principal
  moment of inertia, i.e. near zero for lines, 1.0 for circles, squares,
  and other symmetric objects, between 0 and 1 for ellipses, squashed 
  circles, etc.

*/
double geo_aspect(const obj_t *ob) ;

/******************************************************************************

  Relative radius of gyration squared: 
  defined to be Rg^2 divided by Rg^2 for an ellipse of the same area and 
  aspect ratio.  A measure of the `compactness' of an object, meaning how 
  ramified and fingered it is.

*/
double geo_rrg2(const obj_t *ob) ;

/******************************************************************************

  Principal axis (where the object ``points''): 
  defined to be the y and x components of the unit eigenvector of the larger 
  moment of inertia.  The x component is positive semidefinite, that is, the
  principal axis always points towards the +x axis and lies between the +y 
  and -y axes.

  For example, yax/xax = tan(t) where t is the angle from horizontal which
  the principal axis makes.
*/
void geo_axis(const obj_t *ob, double *yax, double *xax) ;

/******************************************************************************

  Sort objects in an object list by property prop.
  If plist != 0 copy into it the sorted list of the values of the property.
  
  */
rc_t geo_sort(objl_t *ol, geo_t prop, void *plist) ;

/******************************************************************************

  Prune objects from a list which have integer properties >min, <max.

  */
rc_t geo_prune_i(objl_t *ol, geo_t prop, int min, int max) ;

/******************************************************************************

  Prune objects from a list which have floating point properties >min, <max.

  */
rc_t geo_prune_f(objl_t *ol, geo_t prop, double min, double max) ;

/************************************************************************

  Dump a text data file 
  containing geometric properties of the objects in a list, sorted
  according to prop, if this is nonzero and != GEO_NONE.

  */
rc_t geo_dump_info(objl_t *ol, const char *fn,
		   geo_t prop, const char *fn_img) ;

#endif
