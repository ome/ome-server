/****************************************************************************/
/*                                                                          */
/*   pixl.h                                                                 */
/*                                                                          */
/*   header file to accompany pixl.c                                        */
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

#ifndef _PIXL_
#define _PIXL_


/************************************************************************
 *  Pixel lists.
 *
 * Usually these are temporary things we create from rasters on the
 * way to creating objects.  Hence, we create a list of pixel lists in
 * use (the workspace stack).  Pixel lists can be pushed onto the stack
 * when they are initialized.  If they are later popped off the stack,
 * the space which may have been allocated to them will be freed.
*/

/* a pixel list */
typedef struct {
  int n ;           /* number of pixels */
  int sz ;          /* allocated size of x,y lists */
  int chunk ;       /* how much we increase allocated size when we must */
  int *x ;          /* the list of x and y positions */
  int *y ;
} pixl_t ;

/************************************************************************
 *
 * Initialize, free, check size, add a new pixel.
 *
*/
extern void pixl_init(pixl_t *pl, int chunk) ;
extern void pixl_free(pixl_t *pl) ;
extern rc_t pixl_chksz(pixl_t *pl, int sz) ;
extern rc_t pixl_add(pixl_t *pl, int y, int x) ;

/************************************************************************
 *
 * Implement a stack of temporary pixel lists.
 *
*/
extern rc_t pixl_push(pixl_t *pl) ;
extern void pixl_pop(int n) ;

/************************************************************************
 *
 * Return, popping the last npl pixel lists off the workspace stack.
 *
*/
rc_t pixl_clean(rc_t rc, const char *file, int line, 
		const char *id, const char *msg, int npl) ;

#endif
