/************************************************************************

  Deal with pixel list workspaces.

  */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "util.h"
#include "pixl.h"

/* by how much we increase size of workspace when we must */
#define LIST_CHUNK 10

/* a stack of temporary pixel list workspaces */
static pixl_t **pixl_work = 0 ;
static int pixl_work_n = 0 ;
static int pixl_work_sz = 0 ;

/************************************************************************

  Initialize a pixel list.

  */
void pixl_init(pixl_t *pl, int chunk) {

  pl->n = pl->sz = 0 ;
  pl->chunk = chunk ;
  pl->x = 0 ; pl->y = 0 ;
}

/************************************************************************

  Free data allocated to a pixel list. 
  Must initialize with pixl_init before re-use.

  */
void pixl_free(pixl_t *pl) {

  free(pl->x) ; pl->x = 0 ;
  free(pl->y) ; pl->y = 0 ;
  pl->sz = 0 ;
}

/************************************************************************

  Make sure a pixel list is at least large enough to hold sz elements.

  */
rc_t pixl_chksz(pixl_t *pl, int sz) {

  int want ;
  const char *me = "pixl_chksz" ;

  if(pl->sz < sz) {
    want = MAX(sz,pl->sz + pl->chunk) ;
    if (!(pl->x = (int *)realloc(pl->x,want*sizeof(int))) ||
	!(pl->y = (int *)realloc(pl->y,want*sizeof(int))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    pl->sz = want ;
  }
  return(OK) ;
}

/************************************************************************

  Push a new pixel list onto the workspace stack.

  */
rc_t pixl_push(pixl_t *pl) {

  int want ;
  const char *me = "pixl_push" ;

  if (pixl_work_n >= pixl_work_sz) {
    want = pixl_work_sz + LIST_CHUNK ;
    if (!(pixl_work = (pixl_t **)realloc(pixl_work,want*sizeof(pixl_t *))))
      return(memfail(__FILE__,__LINE__,me)) ;
    pixl_work_sz = want ;
  } ;
  pixl_work[pixl_work_n++] = pl ;
  return(OK) ;
}

/************************************************************************

  Pop one or more pixel lists off the workspace stack.

  */
void pixl_pop(int n) {

  int i ;
  pixl_t *pl ;

  for(i=0; (pixl_work_n) && (i<n) ;i++) {
    pl = pixl_work[pixl_work_n-1] ;
    free(pl->x) ;
    free(pl->y) ;
    pl->x = 0 ;
    pl->y = 0 ;
    pixl_work_n -= 1 ;
  } ;
}

/************************************************************************

  Add a new pixel to a pixel list.

  */
rc_t pixl_add(pixl_t *pl, int y, int x) {

  int want ;
  const char *me = "pixl_add" ;

  if(pl->n >= pl->sz) {
    want = pl->sz + pl->chunk ;
    if (!(pl->x = (int *)realloc(pl->x,want*sizeof(int))) ||
	!(pl->y = (int *)realloc(pl->y,want*sizeof(int))) )
      return(memfail(__FILE__,__LINE__,me)) ;
    pl->sz = want ;
  }
  pl->y[pl->n] = y ; pl->x[pl->n] = x ; pl->n += 1 ;
  return(OK) ;
}

/************************************************************************

  Return, cleaning up space allocated in last npl pixel list buffers.

  */
rc_t pixl_clean(rc_t rc, const char *file, int line, 
		const char *id, const char *msg, int npl) {

  pixl_pop(npl) ;
  if (msg && (verbosity < MSG_NONE))
    printf("%s [%s:%d]: %s\n",id,file,line,msg) ;
  return(rc) ;
}


