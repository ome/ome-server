/******************************************************************************

  Mosaic images.

  We sometimes want to paint several objects onto one `mosaic' image
  raster, so we can look at them all at once.

*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <limits.h>
#include "util.h"
#include "obj.h"
#include "geo.h"
#include "img_file.h"
#include "mosaic.h"

/* standard options to ID mosaics */
static const int id_org_flags = (MOSAIC_ID | MOSAIC_GRID | MOSAIC_SILH) ;
static const int id_str_flags = (MOSAIC_ID | MOSAIC_SILH) ;
static const unsigned id_bg = 0 ;
static const unsigned id_fg = 128 ;

#define BORDER 10   /* border around objects when relevant */

/* roughly how many objects we expect per list */
#define ORG_CHUNK 100

/******************************************************************************

  The basic mosaic maker.

  org   = list of origins for the objects.
  ny,nx = size of the mosaic raster.
  bg    = color of pixels not part of any object.
  fg    = color of object pixels when (flags & MOSAIC_SILH).

*/
static rc_t mosaic(gras_t *gr, const objl_t *ol, const pixl_t *org,
		   int ny, int nx, unsigned bg, unsigned fg, int flags) {

  int i,j,nx_y,x,y,o ;
  double xcom,ycom ;
  obj_t *ob ;
  const char *me = "mosaic" ;

  if (gras_chksz(gr,ny,nx) != OK) return(memfail(__FILE__,__LINE__,me)) ;
  for(i=0;i<ny;i++) for(j=0;j<nx;j++) gr->ras[i][j] = bg ;
  if (flags & MOSAIC_GRID) gras_paint_grid(gr,0,0,100,100,255) ;
  if (flags & MOSAIC_OBJ_VLINE)
    for(o=0;o<ol->n;o++) gras_paint_vline(gr,org->x[o] - BORDER/2,255) ;
  for(o=0;o<ol->n;o++) {
    ob = ol->obj[o] ;
    for(i=0;i<ob->ny;i++) {
      nx_y = ob->nx_y[i] ;
      for(j=0;j<nx_y;j++) {
	y = org->y[o] + ob->yras[i][j] ;
	x = org->x[o] + ob->xras[i][j] ;
	gr->ras[y][x] = ((flags & MOSAIC_SILH) ? fg : ob->gras[i][j]) ;
      } ;
    } ;
    if (flags & MOSAIC_ID) {
      geo_com_rel(ob,&ycom,&xcom) ;
      y = org->y[o] + (int)floor(ycom) ;
      x = org->x[o] + (int)floor(xcom) ;
      gras_paint_number(gr,y,x,o) ;
    } ;
  } ;
  gras_maxmin(gr) ;
  return(OK) ;
}

/******************************************************************************

  Make one long strip mosaic.

  */
static rc_t mosaic_strip(gras_t *gr, const objl_t *ol, 
			 unsigned bg, unsigned fg, int mflags) {

  pixl_t org ;
  int o,nx,ny,x,y ;
  rc_t check ;
  const char *me = "mosaic_strip" ;

  pixl_init(&org,ORG_CHUNK) ;
  nx = 0 ; ny = 0 ;
  for(o=0;o<ol->n;o++) {
    x = (nx += BORDER) ; y = BORDER ;
    if (pixl_add(&org,y,x) != OK) return(memfail(__FILE__,__LINE__,me)) ;
    ny = MAX(ny,ol->obj[o]->ny) ; 
    nx += ol->obj[o]->nx ; 
  } ;
  ny += 2*BORDER ;
  check = mosaic(gr,ol,&org,ny,nx,bg,fg,mflags) ;
  pixl_free(&org) ;
  return(check) ;
}

/******************************************************************************

  Make a mosaic with the objects in their original relative positions.

*/
static rc_t mosaic_org(gras_t *gr, const objl_t *ol, 
		       unsigned bg, unsigned fg, int mflags,
		       const gras_t *gr_o) {

  pixl_t org ;
  int o,nx,ny,x,y,xo,yo ;
  rc_t check ;
  const char *me = "mosaic_org" ;

  pixl_init(&org,ORG_CHUNK) ;
  if (gr_o) {
    nx = gr_o->nx ; ny = gr_o->ny ; xo = yo = 0 ;
  } else {
    xo = yo = INT_MAX ; nx = ny = 0 ;
    for(o=0;o<ol->n;o++) {
      xo = MIN(xo,ol->obj[o]->xorg) ;
      yo = MIN(yo,ol->obj[o]->yorg) ;
      nx = MAX(nx,ol->obj[o]->xorg + ol->obj[o]->nx) ;
      ny = MAX(ny,ol->obj[o]->yorg + ol->obj[o]->ny) ;
    } ;
    nx -= xo ; ny -= yo ;
    xo += BORDER ; yo += BORDER ; nx += 2*BORDER ; ny += 2*BORDER ;
  } ;
  for(o=0;o<ol->n;o++) {
    x = ol->obj[o]->xorg - xo ; 
    y = ol->obj[o]->yorg - yo ; 
    if (pixl_add(&org,y,x) != OK) return(memfail(__FILE__,__LINE__,me)) ;
  } ;
  check = mosaic(gr,ol,&org,ny,nx,bg,fg,mflags) ;
  pixl_free(&org) ;
  return(check) ;
}

/******************************************************************************

  Dump a black-and-white identification mosaic image,

  => if (gr != 0) the mosaic raster is set to exactly the same size as gr.  
     Otherwise the mosaic will be just big enough to hold the objects.
     This may be smaller than the original raster.

*/
rc_t mosaic_dump(const objl_t *ol, const char *fn, const gras_t *gr_o) {

  gras_t gr ;
  const char *fn_default = "ID-mosaic.tif" ;
  const char *me = "mosaic_dump_org" ;

  if (!fn || !strlen(fn)) fn = fn_unique(fn_default) ;
  gras_init(&gr,0,0) ;
  if ((mosaic_org(&gr,ol,id_bg,id_fg,id_org_flags,gr_o) != OK) ||
      (tiff_dump_gras(fn,&gr) != OK) )
    return(subfail(__FILE__,__LINE__,me)) ;
  gras_free(&gr) ;
  if (verbosity < MSG_FATAL) 
    printf("%s [%s:%d]: wrote ID mosaic to \"%s\".\n",me,__FILE__,__LINE__,fn);
  return(OK) ;
}

/******************************************************************************

  Dump a black-and-white identification mosaic image,
  with the objects in one long strip sorted according to prop.

*/
rc_t mosaic_dump_sort(objl_t *ol, const char *fn, geo_t prop) {

  gras_t gr ;
  const char *fn_default = "ID-mosaic.tif" ;
  const char *me = "mosaic_dump_sort" ;

  if (!fn || !strlen(fn)) fn = fn_unique(fn_default) ;
  gras_init(&gr,0,0) ;
  if ((geo_sort(ol,prop,0) != OK) ||
      (mosaic_strip(&gr,ol,id_bg,id_fg,id_str_flags) != OK) )
    return(subfail(__FILE__,__LINE__,me)) ;
  if (tiff_dump_gras(fn,&gr) != OK) return(subfail(__FILE__,__LINE__,me)) ;
  gras_free(&gr) ;
  if (verbosity < MSG_FATAL) 
    printf("%s [%s:%d]: wrote ID mosaic to \"%s\".\n",me,__FILE__,__LINE__,fn);
  return(OK) ;
}
