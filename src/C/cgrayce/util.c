/************************************************************************

  General definitions and utilities.

  */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include "util.h"

/* handy for writing error messages */
char msgbuf[100] ;

/* verbosity stack */
#define NVSTAK 10
static verb_t verb_stak[NVSTAK] ;
static int vstak_n = 0 ;

/******************************************************************************

  Failure returning integer.

  */
rc_t punt(const char *file, int line, const char *id, const char *msg) {

  if (msg && (verbosity != MSG_NONE)) 
    printf("* %s [%s:%d]: %s\n",id,file,line,msg) ;
  return(FATAL) ;
}

/******************************************************************************

  Failure returning null pointer.

  */
void *ppunt(const char *file, int line, const char *id, const char *msg) {

  if (msg && (verbosity != MSG_NONE))
    printf("* %s [%s:%d]: %s\n",id,__FILE__,line,msg) ;
  return(0) ;
}

/******************************************************************************

  Memory allocation failure returning integer.

  */
rc_t memfail(const char *file, int line, const char *id) {

  return(punt(file,line,id,"can\'t allocate memory")) ;
}

/******************************************************************************

  Memory allocation failure returning null pointer.

  */
void *pmemfail(const char *file, int line, const char *id) {

  return(ppunt(file,line,id,"can\'t allocate memory")) ;
}

/******************************************************************************

  Subroutine failure returning integer.

  */
rc_t subfail(const char *file, int line, const char *id) {

  return(punt(file,line,id,"subroutine failure")) ;
}

/******************************************************************************

  Failure returning integer and freeing temporary buffers.

  */
rc_t cleanup(rc_t rc, const char *file, int line, const char *id, 
	     const char *msg, void ***bufs, int nbuf) {

  int i ;

  if (nbuf && bufs) for(i=0;i<nbuf;i++) {
    free(*(bufs[i])) ;
    *(bufs[i]) = 0 ;
  } ;
  if (msg && (verbosity != MSG_NONE))
    printf("* %s [%s:%d]: %s\n",id,file,line,msg) ;
  return(rc) ;
}

/******************************************************************************

  Bad argument complaint.

  */
rc_t badarg(const char *arg) {

  const char *fmt = "Bad argument: \"%s\"\n" ;
    
  if (verbosity != MSG_NONE) printf(fmt,arg) ;
  return(FATAL) ;
}

/******************************************************************************

  Try to get an argument of the form: int
  Return 0 on failure, 1 on success.

  => only set *iarg0 if argument successfully obtained.

*/
int getarg_i(char *arg, int *iarg0) {
  
  int i0 ;
  char *eptr ;

  i0 = strtol(arg,&eptr,10) ;
  if (*eptr != '\0') return(0) ;
  *iarg0 = i0 ;
  return(1) ;
}

/******************************************************************************

  Try to get an argument of the form: <key>=<string>
  Return 0 on failure, 1 on success.

  => only set *sarg0 if argument successfully obtained.

*/
int getarg_s(char *arg, const char *key, char *sarg0) {
  
  char *eq ;

  if (!(eq = strchr(arg,'='))) return(0) ;
  if (strncmp(arg,key,strlen(key))) return(0) ;
  if (!strlen(eq+1)) return(0) ;
  strcpy(sarg0,eq+1) ;
  return(1) ;
}

/******************************************************************************

  Try to get a pair of arguments of the form: int,int
  Return 0 on failure, 1 on success.

  => only set *iarg0,*iarg1 if both are successfully obtained.

*/
int getarg_ii(char *arg, int *iarg0, int *iarg1) {

  int i0,i1 ;
  char *eptr ;

  i0 = strtol(arg,&eptr,10) ;
  if (*eptr != ',') return(0) ;
  i1 = strtol(eptr+1,&eptr,10) ;
  if (*eptr != '\0') return(0) ;
  *iarg0 = i0 ; *iarg1 = i1 ;
  return(1) ;
}

/******************************************************************************

  Try to get a pair of arguments of the form: int,double
  Return 0 on failure, 1 on success.

  => only set *iarg0,*darg1 if both are successfully obtained.

*/
int getarg_id(char *arg, int *iarg0, double *darg1) {

  int i0 ;
  double d1 ;
  char *eptr ;

  i0 = strtol(arg,&eptr,10) ;
  if (*eptr != ',') return(0) ;
  d1 = strtod(eptr+1,&eptr) ;
  if (*eptr != '\0') return(0) ;
  *iarg0 = i0 ; *darg1 = d1 ;
  return(1) ;
}

/******************************************************************************

  Try to get a pair of arguments of the form: double,double
  Return 0 on failure, 1 on success.

  => only set *darg0,*darg1 if both are successfully obtained.

*/
int getarg_dd(char *arg, double *darg0, double *darg1) {

  double d0,d1 ;
  char *eptr ;

  d0 = strtod(arg,&eptr) ;
  if (*eptr != ',') return(0) ;
  d1 = strtod(eptr+1,&eptr) ;
  if (*eptr != '\0') return(0) ;
  *darg0 = d0 ; *darg1 = d1 ;
  return(1) ;
}

/******************************************************************************

  Try to get a pair of arguments of the form: string,string
  Return 0 on failure, 1 on success.

  => only set *sarg0,*sarg1 if both are successfully obtained.

*/
int getarg_ss(char *arg, char *sarg0, char *sarg1, int sz0, int sz1) {

  char *comma ;

  if (!(comma = strchr(arg,','))) return(0) ;
  *comma++ = '\0' ;
  if (!strlen(arg) || (strlen(arg) > sz0) || 
      !strlen(comma) || (strlen(comma) > sz1)) return(0) ;
  strcpy(sarg0,arg) ; 
  strcpy(sarg1,comma) ;
  return(1) ;
}

/******************************************************************************

  Ensure a list can hold one more object, allocating memory as needed
  in chunks of no less than chunk*entry_sz.

  */
rc_t list_chkmem(void **list, int *nmax, int n, int chunk, 
		 size_t entry_sz) {

  size_t want ;

  if (n+1 < *nmax) return(OK) ;
  want = ((*nmax += chunk)) * entry_sz ;
  if (!(*list = realloc(*list,want))) return(FATAL) ;
  return(OK) ;
} ;

/******************************************************************************

  Find max/min in a list of integers.

  */
void list_maxmin(int *max, int *min, const int *list, int n) {

  int mx,mn,i ;

  mx = INT_MIN ; mn = INT_MAX ;
  for(i=0;i<n;i++) { mx = MAX(list[i],mx) ; mn = MIN(list[i],mn) ; } ;
  *max = mx ; *min = mn ;
}

/******************************************************************************

  Shell sort i0 into ascending order.

  */
void sort_i_asc(int n, int *i0) {

  int i,j,inc ;
  int k0 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      k0 = i0[i] ;
      for(j = i; (j >= inc) && (i0[j-inc] > k0) ; j -= inc) { 
	i0[j] = i0[j-inc] ;
      } ;
      i0[j] = k0 ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort i0 into ascending order, keeping i1 consistent.

  */
void sort_ii_asc(int n, int *i0, int *i1) {

  int i,j,inc ;
  int k0,k1 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      k0 = i0[i] ; k1 = i1[i] ;
      for(j = i; (j >= inc) && (i0[j-inc] > k0) ; j -= inc) { 
	i0[j] = i0[j-inc] ; i1[j] = i1[j-inc] ;
      } ;
      i0[j] = k0 ; i1[j] = k1 ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort i0 into descending order, keeping i1 consistent.

  */
void sort_ii_desc(int n, int *i0, int *i1) {

  int i,j,inc ;
  int k0,k1 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      k0 = i0[i] ; k1 = i1[i] ;
      for(j = i; (j >= inc) && (i0[j-inc] < k0) ; j -= inc) { 
	i0[j] = i0[j-inc] ; i1[j] = i1[j-inc] ;
      } ;
      i0[j] = k0 ; i1[j] = k1 ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort d0 into descending order, keeping d1 consistent.

  */
void sort_dd_desc(int n, double *d0, double *d1) {

  int i,j,inc;
  double v0,v1 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      v0 = d0[i] ; v1 = d1[i] ;
      for(j = i; (j >= inc) && (d0[j-inc] < v0) ; j -= inc) { 
	d0[j] = d0[j-inc] ; d1[j] = d1[j-inc] ;
      } ;
      d0[j] = v0 ; d1[j] = v1 ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort d0 into descending order, keeping i1 consistent.

  */
void sort_di_desc(int n, double *d0, int *i1) {

  int i,j,inc;
  int k ;
  double v0 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      v0 = d0[i] ; k = i1[i] ;
      for(j = i; (j >= inc) && (d0[j-inc] < v0) ; j -= inc) { 
	d0[j] = d0[j-inc] ; i1[j] = i1[j-inc] ;
      } ;
      d0[j] = v0 ; i1[j] = k ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort i0 into descending order, keeping pointer list x1 consistent.

  */
void sort_ix_desc(int n, int *i0, void **x1) {

  int i,j,inc ;
  void *xv ;
  int k0 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      k0 = i0[i] ; xv = x1[i] ;
      for(j = i; (j >= inc) && (i0[j-inc] < k0) ; j -= inc) { 
	i0[j] = i0[j-inc] ; x1[j] = x1[j-inc] ;
      } ;
      i0[j] = k0 ; x1[j] = xv ;
    } ;
  } ;
}

/******************************************************************************

  Shell sort d0 into descending order, keeping pointer list x1 consistent.

  */
void sort_dx_desc(int n, double *d0, void **x1) {

  int i,j,inc ;
  void *xv ;
  double v0 ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      v0 = d0[i] ; xv = x1[i] ;
      for(j = i; (j >= inc) && (d0[j-inc] < v0) ; j -= inc) { 
	d0[j] = d0[j-inc] ; x1[j] = x1[j-inc] ;
      } ;
      d0[j] = v0 ; x1[j] = xv ;
    } ;
  } ;
}

/******************************************************************************

 Return Gaussian deviate with zero mean, unit variance.

 */
double random_gauss() {

  double x1,x2 ;
  static double spare = 0.0 ;
  static int have_spare = 0 ;

  if (have_spare) {
    have_spare = 0 ; return(spare) ;
  } ;
  x1 = DRAND ; x2 = DRAND ;
  spare = sqrt(-2.0*log(x1)) * cos(2.0*M_PI*x2) ;
  have_spare = 1 ;
  return(sqrt(-2.0*log(x1)) * sin(2.0*M_PI*x2)) ;
}

/******************************************************************************

  Return a unique filename (one that does not already exist in this
  directory) starting from fn, by adding numbers before any suffix of
  fn if necessary.

  */
char *fn_unique(const char *fn) {

  static char *buf = 0 ;
  static int bufsz = 0 ;
  struct stat sb ;
  char *root, *suffix ;
  int n ;

  n = strlen(fn) + 3 ;
  if ((n > bufsz) && !(buf = (char *)realloc(buf,(bufsz=n)))) return(0) ;
  strcpy(buf,fn) ;
  if (stat(buf,&sb)) return(buf) ;  
  if (!(root = (char *)malloc(bufsz))) return(buf) ;
  strcpy(root,fn) ;
  if ((suffix = rindex(root,'.'))) *suffix++ = '\0' ;
  for(n=1;n<1000;n++) {
    sprintf(buf,(suffix ? "%s_%d.%s" : "%s_%d"),root,n,suffix) ;
    if (stat(buf,&sb)) break ;
  } ;
  free(root) ;
  return(buf) ;
}

/******************************************************************************

  Return the next filename not already in this directory
  by adding numbers starting with inum before any suffix of fn.

  */
char *fn_seq(const char *fn, int inum) {

  static char *buf = 0 ;
  static int bufsz = 0 ;
  struct stat sb ;
  char *root, *suffix ;
  int n ;

  n = strlen(fn) + 3 ;
  if ((n > bufsz) && !(buf = (char *)realloc(buf,(bufsz=n)))) return(0) ;
  strcpy(buf,fn) ;
  if (!(root = (char *)malloc(bufsz))) return(0) ;
  strcpy(root,fn) ;
  if ((suffix = rindex(root,'.'))) *suffix++ = '\0' ;
  for(n=inum;n<10000;n++) {
    sprintf(buf,(suffix ? "%s_%d.%s" : "%s_%d"),root,n,suffix) ;
    if (stat(buf,&sb)) break ;
  } ;
  free(root) ;
  return(buf) ;
}

/******************************************************************************

  Return a new filename formed from fn by replacing any suffix 
  with new_suffix.

  */
char *fn_resuffix(const char *fn, const char *new_suffix) {

  static char *buf = 0 ;
  static int bufsz = 0 ;
  char *suffix ;
  int n ;

  n = strlen(fn) + strlen(new_suffix) ;
  if ((n > bufsz) && !(buf = (char *)realloc(buf,(bufsz=n)))) return(0) ;
  strcpy(buf,fn) ;
  if ((suffix = rindex(buf,'.'))) *suffix = '\0' ;
  strcat(buf,new_suffix) ;
  return(buf) ;
}

/******************************************************************************

  Return a filename optionally based upon a modification of another.

  In particular:

  if fn is given => use that.
  otherwise, if base is given => resuffix with suffix and use that.
  otherwise => use a unique modification of deflt.

  */
char *fn_related(const char *fn, const char *base, 
		 const char *suffix, const char *deflt) {
  
  if (fn && strlen(fn)) return((char *)fn) ;
  if (base && strlen(base)) return(fn_resuffix(base,suffix)) ;
  return(fn_unique(deflt)) ;
}

/******************************************************************************

  Change working directories, creating a new directory if necessary.
  Returning where we came from if we were successful.

  */
char *cd_make(const char *dir) {

  static char old_dir[256] ;
  const char *me = "cd_make" ;

  if (!getcwd(old_dir,sizeof(old_dir)))
    return(ppunt(__FILE__,__LINE__,me,"can\'t get current directory.")) ;
  if (chdir(dir)) {
    switch (errno) {
    case ENOENT :
      if (mkdir(dir,0777)) {
	if (verbosity < MSG_NONE) {
	  sprintf(msgbuf,"%s [%s:%d]",me,__FILE__,__LINE__) ; 
	  perror(msgbuf) ;
	} ;
	return(ppunt(__FILE__,__LINE__,me,"can\'t create new directory.")) ;
      } ;
      if (!chdir(dir)) break ;
    default:
      if (verbosity < MSG_NONE) { 
	sprintf(msgbuf,"%s [%s:%d]",me,__FILE__,__LINE__) ; 
	perror(msgbuf) ;
      } ;
      return(ppunt(__FILE__,__LINE__,me,"can\'t change directory.")) ;
    } ;
  } ;
  return(old_dir) ;
}

/******************************************************************************

  Verbosity stack.

  push_verb pushes the current verbosity onto the stack, and sets 
            current verbosity to new_verb.
  pop_verb  sets current verbosity to whatever was last pushed onto 
            the stack, or does nothing if the stack is empty.

  */
void push_verb(verb_t new_verb) {

  int i ;

  for(i=0;i<NVSTAK-1;i++) verb_stak[i+1] = verb_stak[i] ;
  if (vstak_n < NVSTAK) vstak_n += 1 ;  
  verb_stak[0] = verbosity ;
  verbosity = new_verb ;
}

void pop_verb() {

  int i ;

  if (!vstak_n) return ;
  verbosity = verb_stak[0] ;
  for(i=0;i<NVSTAK-1;i++) verb_stak[i] = verb_stak[i+1] ;
  vstak_n -= 1 ;
}

/******************************************************************************

  Statistics routines.

  */
void stat_init(stat_t *s) {

  s->n = 0 ; 
  s->max = INT_MIN ;
  s->min = INT_MAX ;
  s->tot = 0.0 ;
  s->av = 0.0 ;
  s->tot2 = 0.0 ;
  s->var = 0.0 ;
}
void stat_update(stat_t *s, int v) {

  s->n += 1 ; 
  s->max = MAX(s->max,v) ;
  s->min = MIN(s->min,v) ;
  s->tot += (double)v ;
  s->av = s->tot/(double)(s->n) ;
  s->tot2 += SQ((double)v) ;
  s->var = s->tot2/(double)(s->n) - SQ(s->av) ;
}
