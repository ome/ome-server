/****************************************************************************/
/*                                                                          */
/*  util.h                                                                  */
/*                                                                          */
/*  header file to accompany util.c                                         */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
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
/****************************************************************************/

#ifndef _UTIL_
#define _UTIL_

#include <stdlib.h> /* to get RAND_MAX */
#include <limits.h> /* to get INT_MAX, INT_MIN */

#define SQ(a) ((a)*(a))
#define MAX(a,b) ((a) >  (b) ? (a) : (b))
#define MIN(a,b) ((a) <= (b) ? (a) : (b))
/* gives real random number between 0.0 and 1.0 */
#define DRAND ((double)random()/((double)RAND_MAX + 1.0))

/* return codes */
typedef enum { OK = 0, FATAL = -1, NO = 1 } rc_t ;
/* verbosity levels */
/* => we rely on the ordering being strictly increasing. */
typedef enum { MSG_DEBUG, MSG_WARN, MSG_FATAL, MSG_NONE } verb_t ;

/* somebody must define this: usually the main program */
extern verb_t verbosity ;

/* we define in util.c a handy message buffer for writing error messages */
extern char msgbuf[100] ;

/* generic structure for statistics on integers */
typedef struct {
  int n ;
  int max ;
  int min ;
  double tot ;
  double av ;
  double tot2 ;
  double var ;
} stat_t ;

/******************************************************************************

  Routines to write failure messages and return.

  */
extern rc_t punt(const char *file, int line, const char *id,const char *msg);
extern void *ppunt(const char *file, int line, const char *id,const char *msg);
extern rc_t memfail(const char *file, int line, const char *id) ;
extern void *pmemfail(const char *file, int line, const char *id) ;
extern rc_t subfail(const char *file, int line, const char *id) ;
extern rc_t cleanup(rc_t rc, const char *file, int line, const char *id, 
		    const char *msg, void ***bufs, int nbuf) ;
extern rc_t badarg(const char *arg) ;

/******************************************************************************

  Routine to get arguments of various forms.  Only use pointers on success.

  Return 0 on failure, 1 on success.

*/
extern int getarg_i(char *arg, int *iarg0) ;
/* of the form: <key>=<string> */
extern int getarg_s(char *arg, const char *key, char *sarg0) ;
extern int getarg_ii(char *arg, int *iarg0, int *iarg1) ;
extern int getarg_id(char *arg, int *iarg0, double *darg1) ;
extern int getarg_dd(char *arg, double *darg0, double *darg1) ;
extern int getarg_ss(char *arg, char *sarg0, char *sarg1, int sz0, int sz1) ;

/******************************************************************************

  Ensure a list can hold one more object, allocating memory as needed
  in chunks of no less than chunk*entry_sz.

  */
extern rc_t list_chkmem(void **list, int *nmax, int n, int chunk,
			size_t entry_sz) ;

/******************************************************************************

  Find max/min in a list of integers.

  */
extern void list_maxmin(int *max, int *min, const int *list, int n) ;

/******************************************************************************

  Sorting routines.  We sort on the first list, keep the second consistent.

  */
extern void sort_i_asc(int n, int *i0) ;
extern void sort_ii_desc(int n, int *i0, int *i1) ;
extern void sort_ii_asc(int n, int *i0, int *i1) ;
extern void sort_dd_desc(int n, double *d0, double *d1) ;
extern void sort_di_desc(int n, double *d0, int *i1) ;
extern void sort_ix_desc(int n, int *i0, void **x1) ;
extern void sort_dx_desc(int n, double *d0, void **x1) ;

/******************************************************************************

 Return Gaussian random deviate with zero mean, unit variance.

 */
extern double random_gauss(void) ;

/******************************************************************************

  Filename manipulation routines.

  */
extern char *fn_unique(const char *fn) ;
extern char *fn_seq(const char *fn, int inum) ;
extern char *fn_resuffix(const char *fn, const char *new_suffix) ;
extern char *fn_related(const char *fn, const char *base, 
			const char *suffix, const char *deflt) ;

/******************************************************************************

  Change working directories, creating a new directory if necessary.
  Returning where we came from if we were successful.

  */
extern char *cd_make(const char *dir) ;

/******************************************************************************

  Verbosity stack: 

  push_verb pushes the current verbosity onto the stack, and sets 
            current verbosity to new_verb.
  pop_verb  sets current verbosity to whatever was last pushed onto 
            the stack, or does nothing if the stack is empty.
  */
extern void push_verb(verb_t new_verb) ;
extern void pop_verb(void) ;

/******************************************************************************

  Basic statistics on integer.

  */
extern void stat_init(stat_t *s) ;
extern void stat_update(stat_t *s, int v) ;

#endif
