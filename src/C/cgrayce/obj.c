/************************************************************************

  Routines which create and manipulate objects and object lists.

  */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "util.h"
#include "gras.h"
#include "pixl.h"
#include "voronoy.h"
#include "datafile.h"
#include "img_file.h"
#include "obj.h"

/******************************************************************************

  Initialize an object.  We require:

  n  = the number of pixels in the object.
  ny = the number of rows of pixels 
  nx = the maximum number of columns of pixels.

  */
static rc_t obj_init(obj_t *ob, int n, int ny, int nx) {
  
  const char *me = "obj_init" ;

  ob->n = n ;
  ob->nx = nx ;
  ob->ny = ny ;
  ob->yorg = 0 ;
  ob->xorg = 0 ;
  if (!(ob->nx_y  = (int *)malloc(ny * sizeof(int))) ||
      !(ob->gras  = (unsigned **)malloc(ny * sizeof(unsigned *))) ||
      !(ob->gdata = (unsigned  *)malloc(n  * sizeof(unsigned))) ||
      !(ob->xdata = (int  *)malloc(n * sizeof(int))) ||
      !(ob->xras  = (int **)malloc(ny * sizeof(int *))) ||
      !(ob->ydata = (int  *)malloc(n * sizeof(int))) ||
      !(ob->yras  = (int **)malloc(ny * sizeof(int *))) )
    return(memfail(__FILE__,__LINE__,me)) ;
  return(OK) ;
}

/************************************************************************

  Free space allocated for object's data storage.  

  */
static void obj_free(obj_t *ob) {
  
  free(ob->nx_y) ;
  free(ob->gras) ;
  free(ob->gdata) ;
  free(ob->xras) ;
  free(ob->xdata) ;
  free(ob->yras) ;
  free(ob->ydata) ;
}

/************************************************************************

  Initialize an object list.  We require:

  chunk = when we have to allocate space for more objects, we do it
          in chunks of `chunk' objects. 

  */
void objl_init(objl_t *ol, int chunk) {

  ol->n = 0 ;
  ol->sz = 0 ;
  ol->obj = 0 ;
  ol->chunk = chunk ;
}

/************************************************************************

  Free space allocated for an object list.

  */
void objl_free(objl_t *ol) {

  free(ol->obj) ;  ol->obj = 0 ;
  ol->n = ol->sz = 0 ;
}

/******************************************************************************

  Free space allocated for an object list, and all its component objects.

  => Each object must have been allocated dynamically, e.g. by objl_next_obj.

  */
void objl_free_all(objl_t *ol) {

  int o ;

  for(o=0;o<ol->n;o++) { obj_free(ol->obj[o]) ; free(ol->obj[o]) ; } ;
  objl_free(ol) ;
}

/************************************************************************

  Make sure an object list has space for sz objects.

*/
static rc_t objl_chksz(objl_t *ol, int sz) {

  int want ;
  const char *me = "objl_chksz" ;

  if (ol->sz < sz) {
    want = MAX(sz, ol->sz + ol->chunk) ;
    if (!(ol->obj = (obj_t **)realloc(ol->obj,want*sizeof(obj_t *))))
      return(memfail(__FILE__,__LINE__,me)) ;
    ol->sz = want ;
  } ;
  return(OK) ;
}

/************************************************************************

  Copy an object list.

  */
rc_t objl_copy(objl_t *dest, const objl_t *src) {

  const char *me = "objl_copy" ;

  if (objl_chksz(dest,src->n) != OK)
    return(memfail(__FILE__,__LINE__,me)) ;
  dest->n = src->n ;
  memcpy(dest->obj,src->obj,src->n * sizeof(obj_t *)) ;
  return(OK) ;
}

/************************************************************************

  Add an uninitialized object to an object list, 
  and return a pointer to it.

*/
static obj_t *objl_next_obj(objl_t *ol) {

  static obj_t *obj ;
  const char *me = "objl_next_obj" ;

  if ((objl_chksz(ol,ol->n + 1) != OK) ||
      !(obj = (obj_t *)malloc(sizeof(obj_t))))
    return(pmemfail(__FILE__,__LINE__,me)) ;
  ol->obj[ol->n++] = obj ;
  return(obj) ;
}

/************************************************************************

  Create a new object from a list of pixels.

  => ob must point to an uninitialized object.

  */
static rc_t pixl2obj(obj_t *ob, const gras_t *gr, pixl_t *pl) {
  
  int ymax,ymin,xmax,xmin,ny,nx,n,i,k,x,m,y,nx_y ;
  const char *me = "pixl2obj" ;

  n = pl->n ;
  list_maxmin(&ymax,&ymin,pl->y,n) ;
  list_maxmin(&xmax,&xmin,pl->x,n) ;
  ny = ymax - ymin + 1 ; nx = xmax - xmin + 1 ; 
  if (obj_init(ob,n,ny,nx) != OK) return(memfail(__FILE__,__LINE__,me)) ;
  ob->yorg = ymin ; ob->xorg = xmin ;
  sort_ii_asc(n,pl->y,pl->x) ;
  for(k=0,i=0;i<ny;i++) {
    if (k >= n) break ;
    ob->gras[i] = ob->gdata + k ;
    ob->xras[i] = ob->xdata + k ;
    ob->yras[i] = ob->ydata + k ;
    y = pl->y[k] ;
    for(nx_y=0; (k+nx_y < n) && (pl->y[k+nx_y] == y); nx_y++) ;
    ob->nx_y[i] = nx_y ;
    sort_i_asc(nx_y,pl->x+k) ;    
    for(m=k;m<k+nx_y;m++) {
      y = pl->y[m] ; x = pl->x[m] ; 
      ob->gdata[m] = gr->ras[y][x] ;
      ob->ydata[m] = y - ymin ;
      ob->xdata[m] = x - xmin ;
    } 
    k += nx_y ;
  } ;
  return(OK) ;
}

/************************************************************************

  Create a list of those pixels inside a Voronoy polygon.

  */
static rc_t voy2pixl(pixl_t *pl, const voy_t *voy) {

  double xbox[2] ;
  double ybox[2] ;
  int imin,imax,jmin,jmax,i,j ;
  const char *me = "voy2pixl" ;

  pl->n = 0 ;
  voy_box(xbox,ybox,voy) ;
  imin = (int)floor(ybox[0]) ; imax = 1 + (int)ceil(ybox[1]) ;
  jmin = (int)floor(xbox[0]) ; jmax = 1 + (int)ceil(xbox[1]) ;
  for(i=imin;i<imax;i++) {
    for(j=jmin;j<jmax;j++) {
      if (voy_p_inside(voy,(double)j,(double)i) && (pixl_add(pl,i,j) != OK))
	return(memfail(__FILE__,__LINE__,me)) ;
    } ;
  } ;
  return(OK) ;
}

/******************************************************************************

  Create a list of the next set of contiguous pixels not marked in gr->mk. 
  Mark every pixel found in gr->mk.

  The idea is that this routine be called repeatedly, returning lists of
  contiguous patches of unmarked pixels, until there are none left.

  => pl must point to an initialized pixel list.

  => We rely on gr_mk->nymax == gr_mk->ny, gr_mk->nxmax == gr->nx  !!

  */
static rc_t nomark2pixl(pixl_t *pl, const gras_t *gr_mk) {

  const int seed_pixl_chunk = 10000 ;
  int xnn[8], ynn[8] ;
  pixl_t sa,sb ;
  const unsigned *data ;
  const unsigned **ras ;
  pixl_t *snew,*sold,*stmp ;
  int i,k,y,x,nx,ny,ys,xs,nn,n ;
  const char *me = "nomark2pixl" ;

  nx = gr_mk->nx ; ny = gr_mk->ny ; n = nx * ny ; 
  data = (const unsigned *)gr_mk->data ; 
  ras = (const unsigned **)gr_mk->ras ;

  /* find first seed pixel -- must do this fast because it potentially
   * involves a search through the entire raster every time. */
  if (!data[n-1]) {
    y = ny - 1 ; x = nx - 1 ; 
  } else {
    gr_mk->data[n-1] = 0 ; 
    for(k=0;data[k];k++); 
    gr_mk->data[n-1] = 1 ;
    if (k == n-1) return(NO) ;
    y = k/nx ; x = k % nx ;
  } ;

  /* initialize our seed lists */
  pl->n = 0 ;
  snew = &sa ; sold = &sb ; 
  pixl_init(snew,seed_pixl_chunk) ; pixl_push(snew) ;
  pixl_init(sold,seed_pixl_chunk) ; pixl_push(sold) ;

  /* add 1st seed to seed/object pixel lists */
  if ((pixl_add(pl,y,x) != OK) || (pixl_add(snew,y,x) != OK))
    return(pixl_clean(FATAL,__FILE__,__LINE__,me,"memory failure",2)) ;
  /* mark it on the raster */
  gr_mk->ras[y][x] = 1 ;

  /* step through old seed list, creating new seed list */
  do {
    stmp = snew ; snew = sold ; sold = stmp ; 
    snew->n = 0 ;
    for(i=0;i<sold->n;i++) {
      ys = sold->y[i] ; xs = sold->x[i] ;
      nn = gras_nn8(gr_mk,ynn,xnn,ys,xs) ;
      for(k=0;k<nn;k++) {
	y = ynn[k] ; x = xnn[k] ;
	if (ras[y][x]) continue ;
	/* add this neighbor to the seed and object pixel lists */
	if ((pixl_add(pl,y,x) != OK) || (pixl_add(snew,y,x) != OK))
	  return(pixl_clean(FATAL,__FILE__,__LINE__,me,"memory failure",2)) ;
	/* mark this neighbor on the raster */
	gr_mk->ras[y][x] = 1 ;
      } ;
    } ;
  } while (snew->n) ;
  return(pixl_clean(OK,__FILE__,__LINE__,me,0,2)) ;
}

/************************************************************************

  Create a list of all objects in a grayscale raster gr
  by finding all contiguous areas in gr_mk which have not been marked.

  => If szmin > 0 all objects of area less than szmin pixels are ignored.

  => If inflag > 0 objects which intersect image boundaries are ignored.

*/
rc_t objl_marked(objl_t *ol, const gras_t *gr, gras_t *gr_mk,
		 int szmin, int inflag) {

  const int chunk = 1000 ;
  stat_t o_stat,oig_sz_stat,oig_in_stat ;
  pixl_t pl ;
  obj_t *obj ;
  rc_t check ;
  int xmax,xmin,ymax,ymin ;
  const char *me = "objl_marked" ;

  pixl_init(&pl,chunk) ;  
  stat_init(&o_stat) ; stat_init(&oig_sz_stat) ; stat_init(&oig_in_stat) ;
  while ((check = nomark2pixl(&pl,gr_mk)) == OK) {
    if (pl.n < szmin) { stat_update(&oig_sz_stat,pl.n) ; continue ; } ;
    if (inflag) {
      list_maxmin(&ymax,&ymin,pl.y,pl.n) ; list_maxmin(&xmax,&xmin,pl.x,pl.n) ;
      if ((ymin <= 0) || (ymax >= gr->ny - 1) || 
	  (xmin <= 0) || (xmax >= gr->nx - 1) ) {
	stat_update(&oig_in_stat,pl.n) ; continue ;
      } ;
    } ;
    if (!(obj = objl_next_obj(ol))) return(memfail(__FILE__,__LINE__,me)) ;
    if (pixl2obj(obj,gr,&pl) != OK) return(subfail(__FILE__,__LINE__,me));
    stat_update(&o_stat,pl.n) ;
  } ;
  if (check == FATAL) return(subfail(__FILE__,__LINE__,me)) ;
  if ((verbosity == MSG_DEBUG) && (o_stat.n > 0)) {
    printf("%s [%s:%d]: found %d objects\n"
	   "   size: %d (min) %d (max) %5.1f (avg)\n",
	   me,__FILE__,__LINE__,o_stat.n,
	   o_stat.min,o_stat.max,o_stat.av) ;
  } ;
  if (verbosity < MSG_FATAL) {
    if (oig_sz_stat.n)
      printf("%s [%s:%d]: ignored %d objects less than minimum size %d\n"
	     "   size: %d (min) %d (max) %5.1f (avg)\n",
	     me,__FILE__,__LINE__,oig_sz_stat.n,szmin,
	     oig_sz_stat.min,oig_sz_stat.max,oig_sz_stat.av) ;
    if (oig_in_stat.n)
      printf("%s [%s:%d]: ignored %d objects not entirely within image\n"
	     "   size: %d (min) %d (max) %5.1f (avg)\n",
	     me,__FILE__,__LINE__,oig_in_stat.n,
	     oig_in_stat.min,oig_in_stat.max,oig_in_stat.av) ;
  } ;
  pixl_free(&pl) ;
  return(OK) ;
}

/************************************************************************

  Create a list of all objects in a grayscale raster gr
  by breaking it into a set of Voronoy polygons around the set yc,xc of 
  n centers.  The pixels under each polygon become the objects.

*/
rc_t objl_voy(objl_t *ol, const gras_t *gr, 
	      const double *yc, const double *xc, int n) {

  const int chunk = 1000 ;
  pixl_t pl ;
  obj_t *obj ;
  voyl_t voyl ;
  double xbox[4], ybox[4] ;
  int i ;
  const char *me = "objl_voy" ;

  /*
   * make a box that encloses the raster -- we add jigger factors about
   * half a pixel wide here so that the box is slightly irregular; the 
   * floating math has hysterics whenever things are EXACTLY on boundaries.
   *
   */
  xbox[0] = 0.0                  - 0.51 ; 
  ybox[0] = 0.0                  - 0.52 ;
  xbox[1] = (double)(gr->nx - 1) + 0.53 ;
  ybox[1] = 0.0                  - 0.54 ;
  xbox[2] = (double)(gr->nx - 1) + 0.55 ;
  ybox[2] = (double)(gr->ny - 1) + 0.56 ;
  xbox[3] = 0.0                  - 0.57 ; 
  ybox[3] = (double)(gr->ny-1)   + 0.58 ;

  pixl_init(&pl,chunk) ;
  voyl_init(&voyl,n) ;
  if (voyl_voyize(&voyl,xc,yc,xbox,ybox,4,n))
    return(subfail(__FILE__,__LINE__,me)) ;
  for(i=0;i<voyl.n;i++) {
    if (voy2pixl(&pl,voyl.voy[i])!= OK) return(subfail(__FILE__,__LINE__,me));
    if (!(obj = objl_next_obj(ol))) return(memfail(__FILE__,__LINE__,me)) ;
    if (pixl2obj(obj,gr,&pl) != OK) return(subfail(__FILE__,__LINE__,me)) ;
  } ;
  if (verbosity < MSG_FATAL)
    printf("%s [%s:%d]: turned %d Voronoy polygons into objects.\n",
	   me,__FILE__,__LINE__,voyl.n) ;
  voyl_free_all(&voyl) ;
  pixl_free(&pl) ;
  return(OK) ;
} 

/************************************************************************

  Create a list of the pixels in an object.  

  => if glist != 0 return in it a list of the intensities of the pixels.

  */
rc_t obj2pixl(const obj_t *ob, pixl_t *pl, unsigned **glist) {

  int i ;
  const char *me = "obj2pixl" ;

  if ((pixl_chksz(pl,ob->n) != OK) ||
      (glist && !(*glist = (unsigned *)malloc(ob->n * sizeof(unsigned)))) )
    return(memfail(__FILE__,__LINE__,me)) ;
  pl->n = ob->n ;
  memcpy(pl->y,ob->ydata,ob->n * sizeof(int)) ;
  memcpy(pl->x,ob->xdata,ob->n * sizeof(int)) ;
  for(i=0;i<ob->n;i++) pl->y[i] += ob->yorg ;
  for(i=0;i<ob->n;i++) pl->x[i] += ob->xorg ;
  if (glist) memcpy(*glist,ob->gdata,ob->n * sizeof(unsigned)) ;
  return(OK) ;
} ;  

/************************************************************************

  Paint an object onto a raster.
  bg is the background color, that is the color of the pixels of gr
  which are not part of the object.

*/
static rc_t obj_paint(gras_t *gr, const obj_t *ob, unsigned bg) {

  int nx,ny,i,j,nx_y,x,y ;
  unsigned g ;
  const char *me = "obj_paint" ;

  ny = ob->ny ; nx = ob->nx ;
  if (gras_chksz(gr,ny,nx) != OK) return(memfail(__FILE__,__LINE__,me)) ;
  for(i=0;i<ny;i++) for(j=0;j<nx;j++) gr->ras[i][j] = bg ;
  for(i=0;i<ny;i++) {
    nx_y = ob->nx_y[i] ;
    for(j=0;j<nx_y;j++) {
      y = ob->yras[i][j] ;
      x = ob->xras[i][j] ;
      g = ob->gras[i][j] ;
      gr->ras[y][x] = g ;
    } ;
  } ;
  gras_maxmin(gr) ;
  return(OK) ;
}

/******************************************************************************

  Paint each object on an object list 
  onto a separate raster and dump to a TIFF file in directory dir.

*/
rc_t objl_dump_img(const objl_t *ol, const char *dir,
		   unsigned bg, int obits) {

  gras_t gr ;
  int ibits,o ;
  int bits_warn = 0 ;
  char *old_dir, *fn ;
  const char *dir_default = "obj-images" ;
  const char *fn_out = "object.tif" ;
  const char *me = "objl_dump_img" ;

  if (!dir || !strlen(dir)) dir = fn_unique(dir_default) ;
  if (!(old_dir = cd_make(dir))) return(subfail(__FILE__,__LINE__,me)) ;
  gras_init(&gr,0,0) ;
  for(o=0;o<ol->n;o++) {
    if (obj_paint(&gr,ol->obj[o],bg) != OK)
      return(subfail(__FILE__,__LINE__,me)) ;
    if (obits < (ibits = gras_depth(&gr))) {
      if (bits_warn++)
	printf("%s [%s:%d]: reducing depth of object image(s) from %d to %d\n",
	       me,__FILE__,__LINE__,ibits,obits) ;
      if (gras_con_lin(&gr,&gr,obits) != OK) 
	return(subfail(__FILE__,__LINE__,me)) ;
    } ;
    fn = fn_seq(fn_out,0) ;      
    img_set_outparm(IMG_FILE_OUT_BITS,obits) ;
    if (tiff_dump_gras(fn,&gr) != OK) return(subfail(__FILE__,__LINE__,me)) ;
  } ;
  chdir(old_dir) ;
  gras_free(&gr) ;
  if (verbosity < MSG_FATAL)
    printf("%s [%s:%d]: wrote %d object image files to \"%s\".\n",
	   me,__FILE__,__LINE__,o,dir) ;
  return(OK) ;
}  

