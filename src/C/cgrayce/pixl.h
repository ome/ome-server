/************************************************************************

  Pixel lists.

  Usually these are temporary things we create from rasters on the
  way to creating objects.  Hence, we create a list of pixel lists in
  use (the workspace stack).  Pixel lists can be pushed onto the stack
  when they are initialized.  If they are later popped off the stack,
  the space which may have been allocated to them will be freed.

  */
#ifndef _PIXL_
#define _PIXL_

/* a pixel list */
typedef struct {
  int n ;           /* number of pixels */
  int sz ;          /* allocated size of x,y lists */
  int chunk ;       /* how much we increase allocated size when we must */
  int *x ;          /* the list of x and y positions */
  int *y ;
} pixl_t ;

/************************************************************************

  Initialize, free, check size, add a new pixel.

  */
extern void pixl_init(pixl_t *pl, int chunk) ;
extern void pixl_free(pixl_t *pl) ;
extern rc_t pixl_chksz(pixl_t *pl, int sz) ;
extern rc_t pixl_add(pixl_t *pl, int y, int x) ;

/************************************************************************

  Implement a stack of temporary pixel lists.

  */
extern rc_t pixl_push(pixl_t *pl) ;
extern void pixl_pop(int n) ;

/************************************************************************

  Return, popping the last npl pixel lists off the workspace stack.

  */
rc_t pixl_clean(rc_t rc, const char *file, int line, 
		const char *id, const char *msg, int npl) ;

#endif
