/******************************************************************************

  Routines which create objects and manipulate object lists.

  An object is a group of pixels in an image somehow identified as foreground.

  */
#ifndef _OBJ_
#define _OBJ_

#include "pixl.h"
#include "util.h"
#include "gras.h"

/* The object structure:
 *
 * Here's a drawing of a random object on a raster.
 * The X's are object pixels (background pixels are not shown).
 *
 *
 *     <---- nx ---->     
 *   ^ O   XXXXX   XX    nx_y[0] = 7   
 *   |      XXX   XX     nx_y[1] = 5
 *   |  X  XXXXXXXX      nx_y[2] = 9
 *  ny   XXXXXXXXXX         .
 *   |   XXXXXXXXXX         .
 *   |    XXXXXXXXXX        .
 *   v       XXXXXX      nx_y[ny-1] = 6
 *
 *  xdata[0] = 4, xdata[1] = 5, . . . xdata[n-1] = 11
 *  ydata[0] = 0, ydata[1] = 0, . . . ydata[n-1] = 6
 *  xras[0][0] = 4, xras[0][1] = 5, . . . xras[0][nx_y[0]-1] = 13
 *  yras[0][0] = 0, . . . yras[0][nx_y[0]-1] = 0
 *
 *  The components of the object structure are:
 *
 *  n         = number of pixels in the object.
 *  ny,nx     = number of rows,columns of pixels: that is, the object just
 *              fits within a rectangular square patch on the raster of size
 *              ny rows by nx columns.
 *  yorg,xorg = the coordinates in the original raster of the upper left 
 *              corner of the ny x nx patch of pixels containing the object,
 *              O in the drawing above. There may not be an object pixel at
 *              this location!
 *  nx_y[i]   = the number of columns of pixels, not including gaps, in
 *              row i (see drawing).
 *  xdata     = the x locations RELATIVE TO xorg of the n pixels.
 *  ydata     = the y locations RELATIVE TO yorg of the n pixels.
 *  xras[i]   = the nx_y[i] x locations of the ith row of pixels.
 *  yras[i]   = the nx_y[i] y locations of the ith row of pixels.
 *  gdata     = the grayvalues of the n pixels.
 *  gras[i]   = the nx_y[i] grayvalues of the ith row of pixels.
 *
 */ 
typedef struct {
  int n ;        
  int ny ;       
  int nx ;       
  int yorg ;     
  int xorg ;
  int *nx_y ;    
  int *ydata ;
  int *xdata ;   
  int **yras ;
  int **xras ;    
  unsigned *gdata ;
  unsigned **gras ;
} obj_t ;

/* the object list structure */
typedef struct {
  int n ;
  int sz ;
  int chunk ;
  obj_t **obj ;
} objl_t ;

/******************************************************************************

  Initialize, free, and copy object lists.

  => when we have to allocate space for more objects, we do it in chunks 
     of `chunk' objects. 

  */
extern void objl_init(objl_t *ol, int chunk) ;
extern void objl_free(objl_t *ol) ;
extern void objl_free_all(objl_t *ol) ;
extern rc_t objl_copy(objl_t *dest, const objl_t *src) ;

/******************************************************************************

  Create a list of all objects in a raster gr
  by finding all contiguous areas in gr_mk which have not been marked.

  => If szmin > 0 all objects of area less than szmin pixels are ignored.

  => If inflag > 0 objects which intersect image boundaries are ignored.

*/
extern rc_t objl_marked(objl_t *ol, const gras_t *gr, gras_t *gr_mk,
			int szmin, int inflag) ;

/******************************************************************************

  Create a list of all objects in a raster gr
  by breaking gr into Voronoy polygons around the set yc,xc of n centers.  

*/
extern rc_t objl_voy(objl_t *ol, const gras_t *gr, 
		     const double *yc, const double *xc, int n) ;

/******************************************************************************

  Paint each object on an object list 
  onto a separate raster and dump to an image file in directory dir.

*/
extern rc_t objl_dump_img(const objl_t *ol, const char *dir,
			  unsigned bg, int obits) ;

/************************************************************************

  Create a list of the pixels in an object.  

  => if glist != 0 return in it a list of the intensities of the pixels.

  */
extern rc_t obj2pixl(const obj_t *ob, pixl_t *pl, unsigned **glist) ;

#endif
