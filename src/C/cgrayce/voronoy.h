/******************************************************************************

  Voronoy polygons.  

  Take a set of labeled points (x,y) in the plane.  Surround each labeled 
  point with walls (lines) such that every walled area around a point (every
  Voronoy polygon) contains that area of the plane which is closer to 
  the central point than to any other point.  This divides the plane into
  Voronoy polygons.

  */
#ifndef _VORONOY_
#define _VORONOY_

/* 2D point */
typedef struct { double x ; double y ; } xy_t ;

/* 2D line  
 * guaranteed to have at least point a and m set, b not guaranteed set.
 * if the line is vertical, vert is set and m = 0.0.
 */
typedef struct { xy_t a ; xy_t b ; double m ; unsigned vert ; } line_t ;

/* Voronoy polygon
 * the sides are guaranteed to be in counterclockwise order around the
 * central point, and the beginning (a) and end (b) points of each line
 * segment are guaranteed to also be in clockwise order.
 */
typedef struct {
  int n ;
  xy_t ctr ;
  line_t *side ;  
} voy_t ;

/* Voronoy polygon list */
typedef struct {
  int n ;
  int sz ;
  int chunk ;
  voy_t **voy ;
} voyl_t ;

/************************************************************************

  Initialize a Voronoy polygon list.  We require:

  chunk = when the list must be increased to accomodate more polygons,
          it's done in chunks of `chunk' polygons.

  */
extern void voyl_init(voyl_t *voyl, int chunk) ;

/******************************************************************************

  Free memory allocated to a Voronoy polygon list.

  */
extern void voyl_free(voyl_t *voyl) ;

/******************************************************************************

  Free all memory allocated to a Voronoy polygon list.  
  The individual polygons must have been allocated dynamically, e.g. by
  voyl_voyize.

  */
extern void voyl_free_all(voyl_t *voyl) ;

/******************************************************************************

  Allocate and construct a complete Voronoy polygon list.  We require:

  voyl = must point to an initialized Voronoy polygon list.
  x,y  = must point to the n x,y coordinates of the polygon centers.
  xbox,ybox = must point to the nbox x,y coordinates of the corners of the
         box that encloses all the points.

  */
extern int voyl_voyize(voyl_t *voyl, const double *x, const double *y, 
		       const double *xbox, const double *ybox, 
		       int nbox, int n) ;

/******************************************************************************

  Return 1 if a point (x,y) is inside a Voronoy polygon, 0 otherwise.

  */
extern int voy_p_inside(const voy_t *voy, double x, double y) ;

/******************************************************************************

  Put into x[0],x[1] and x[0],x[1] two (x,y) pairs that define a rectangular
  box that completely contains the given Voronoy polygon.

  */
extern void voy_box(double *x, double *y, const voy_t *voy) ;

#endif
