/****************************************************************************/
/*                                                                          */
/*                                                                          */
/*     datafile.c                                                           */
/*                                                                          */
/*   Author:  Christopher Grayce                                            */
/*   Copyright 2001 Christopher Grayce                                      */
/*   This file is part of OME.                                              */
/*                                                                          */
/*  Text data file routines.                                                */
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

/*
  Routines to ensure a text data file when it is opened has a
  comment header automatically written of the form:

# program = foo.c of Aug 31 2001 04:44 PDT
# date = Fri Aug 31 04:44 PDT 2001
# user@host = me@mycomputer.org
# foo = 1
# bar = 2.00000
# baz = output from test program
<data>

  Usage syntax:

  int foo ;
  double bar ;
  char *baz[] = "output from test program" ;
  FILE *fp ;

  datafile_init(__FILE__,__DATE__,__TIME__) ;
  datafile_register("foo","%d",DATAFILE_TYPE_INT,&foo) ;
  datafile_register("bar","%f",DATAFILE_TYPE_DOUBLE,&bar) ;
  datafile_register("baz","%s",DATAFILE_TYPE_STRING,&baz) ;

  if ((fp = datafile_open("foo.dat",0)) {
     fprintf(fp,..<data>...

  Note that the leading comments above are added automatically.

*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "datafile.h"

/* return codes */
#define OK      (0)
#define FATAL  (-1)

#define CHUNK_N    10
#define CHUNK_DATA 1000

#define MAX(a,b) ((a) > (b) ? (a) : (b))

static char msgbuf[1000] ;

/******************************************************************************

  Memory allocation failure returning integer

  */
static int memfail(int line, const char *id) {

  printf("* %s [%s:%d]: %s\n",id,__FILE__,line,"couldn\'t allocate memory") ;
  return(FATAL) ;
}

/******************************************************************************

  Initialize.  

  => file, date, and time are intended to receive the compiler 
     constants __FILE__,__DATE__ and  __TIME__, to show the source code
     file of the calling program and its date of compilation.  
     prog is intended to receive the name of the calling program.

  */
int datafile_init(datafile_reg_t *dfr,
		  const char *prog, const char *file,
		  const char *date, const char *time) {

  int want ;
  const char *me = "datafile_init" ;

  want = strlen(file) + 4 + strlen(date) + 1 + strlen(time) + 1 ;
  if (!(dfr->prog = (char *)malloc((strlen(prog) + 1) * sizeof(char))) ||
      !(dfr->file = (char *)malloc(want * sizeof(char))))
    return(memfail(__LINE__,me)) ;
  strcpy(dfr->prog,prog) ; 
  strcpy(dfr->file,file) ; 
  strcat(dfr->file," of ") ; 
  strcat(dfr->file,date) ;
  strcat(dfr->file," ") ; 
  strcat(dfr->file,time) ;

  dfr->n = 0 ;
  dfr->nmax = 0 ;
  dfr->next_nam = 0 ;
  dfr->next_fmt = 0 ;
  dfr->nam = 0 ;
  dfr->fmt = 0 ;
  dfr->adr = 0 ;
  dfr->type = 0 ;
  dfr->data_nam = 0 ;
  dfr->data_fmt = 0 ;
  dfr->sz_nam = 0 ;
  dfr->sz_fmt = 0 ;

  return(OK) ;
}

/******************************************************************************

  Free allocated memory.  datafile_init must be called before this
  structure can be used again.

  */
void datafile_free(datafile_reg_t *dfr) {

  free(dfr->nam) ;
  free(dfr->fmt) ;
  free(dfr->adr) ;
  free(dfr->type) ;
  free(dfr->prog) ;
  free(dfr->file) ;
  free(dfr->data_nam) ;
  free(dfr->data_fmt) ;
}

/******************************************************************************

  Register a variable to be printed in the datafile comment header.

  => variable's value will be read when datafile is opened, 
     not when variable is registered.

  */
int datafile_register(datafile_reg_t *dfr, 
		      const char *nam, const char *fmt, 
		      datafile_type_t type, void *adr) {

  size_t sz,newsz ;
  int n,want ;
  const char *me = "datafile_register" ;

  n = dfr->n ;
  if (n + 1 >= dfr->nmax) {
    want = dfr->nmax + CHUNK_N ;
    if (!(dfr->nam = 
	  (int *)realloc(dfr->nam,want*sizeof(int))) ||
	!(dfr->fmt = 
	  (int *)realloc(dfr->fmt,want*sizeof(int))) ||
	!(dfr->adr = 
	  (void **)realloc(dfr->adr,want*sizeof(void *))) ||
	!(dfr->type = (datafile_type_t *)
	  realloc(dfr->type,want*sizeof(datafile_type_t))) )
      return(memfail(__LINE__,me)) ;
    dfr->nmax = want ;
  } ;

  dfr->nam[n] = dfr->next_nam ;
  sz = dfr->next_nam * sizeof(char) ;
  newsz = sz + (strlen(nam) + 1) * sizeof(char) ;
  if (newsz >= dfr->sz_nam) {
    sz = MAX(newsz,dfr->next_nam + CHUNK_DATA) ;
    if (!(dfr->data_nam = (char *)realloc(dfr->data_nam,sz)))
      return(memfail(__LINE__,me)) ;
    dfr->sz_nam = sz ;
  } ;
  strcpy(dfr->data_nam + dfr->nam[n], nam) ;
  dfr->next_nam += (strlen(nam) + 1) ;

  dfr->fmt[n] = dfr->next_fmt ;
  sz = dfr->next_fmt * sizeof(char) ;
  newsz = sz + (strlen(fmt) + 1) * sizeof(char) ;
  if (newsz >= dfr->sz_fmt) {
    sz = MAX(newsz,dfr->next_fmt + CHUNK_DATA) ;
    if (!(dfr->data_fmt = (char *)realloc(dfr->data_fmt,sz)))
      return(memfail(__LINE__,me)) ;
    dfr->sz_fmt = sz ;
  } ;
  strcpy(dfr->data_fmt + dfr->fmt[n], fmt) ;
  dfr->next_fmt += (strlen(fmt) + 1) ;

  dfr->adr[n] = adr ;

  dfr->type[n] = type ;

  dfr->n += 1 ;

  return(OK) ;
}

/******************************************************************************

  Add program info.

  */
static void add_prog(FILE *fp, const datafile_reg_t *dfr) {

  fprintf(fp,"# program = %s\n",dfr->prog) ;
  fprintf(fp,"# source = %s\n",dfr->file) ;
}

/******************************************************************************

  Add current time.

  */
static void add_time(FILE *fp) {

  time_t now ;
  struct tm *t ;
  const char *fmt = "%a %b %d %T %Z %Y" ;

  if (time(&now) && (t = localtime(&now)) && 
      strftime(msgbuf,sizeof(msgbuf),fmt,t))
    fprintf(fp,"# date = %s\n",msgbuf) ;
}

/******************************************************************************

  Add current user/hostname.

  */
static void add_user(FILE *fp) {

  const char *who ;
  const char *nobody = "(unknown)" ;

  if (!(who = getlogin())) who = nobody ;
  strncpy(msgbuf,who,sizeof(msgbuf)) ;
  strcat(msgbuf,"@") ;
  if (!gethostname(msgbuf+strlen(msgbuf),sizeof(msgbuf)-strlen(msgbuf)))
    fprintf(fp,"# user@host = %s\n",msgbuf) ;
}

/******************************************************************************

  Add i'th registry entry.

  */
static void add_entry(FILE *fp, const datafile_reg_t *dfr, int i) {

  char *nam,*fmt ;
  datafile_type_t type ;
  void *adr ;

  nam = dfr->data_nam + dfr->nam[i] ;
  fmt = dfr->data_fmt + dfr->fmt[i] ;
  adr = dfr->adr[i] ;
  type = dfr->type[i] ;

  sprintf(msgbuf,"# %%s = ") ;
  strncat(msgbuf,fmt,sizeof(msgbuf)) ;
  strncat(msgbuf,"\n",sizeof(msgbuf)) ;
  switch (type) {
  case DATAFILE_TYPE_INT :
    fprintf(fp,msgbuf,nam,*(int *)adr) ;
    break ;
  case DATAFILE_TYPE_DOUBLE :
    fprintf(fp,msgbuf,nam,*(double *)adr) ;
    break ;
  default :
  case DATAFILE_TYPE_STRING :
    fprintf(fp,msgbuf,nam,(char *)adr) ;
    break ;
  } ;
}

/******************************************************************************

  Add all entries.

  */
static void add_header(FILE *fp, const datafile_reg_t *dfr) {

  int i ;

  add_prog(fp,dfr) ;
  add_time(fp) ;
  add_user(fp) ;
  for(i=0;i<dfr->n;i++) add_entry(fp,dfr,i) ;
}

/******************************************************************************

  Create a unique filename, by adding numbers before any suffix
  if necessary.

  */
static char *fn_unique(const char *fn) {

  struct stat sb ;  char *suffix = 0 ;  int n = 0 ;
  char fnroot[200] ;
  static char newfn[255] ;

  if (stat(fn,&sb)) return((char *)fn) ;
  strncpy(fnroot,fn,sizeof(fnroot)) ;
  if ((suffix = rindex(fnroot,'.'))) *suffix++ = '\0' ;
  do {
    sprintf(newfn,(suffix ? "%s_%d.%s" : "%s_%d"),fnroot,++n,suffix) ;
  } while (!stat(newfn,&sb)) ;
  return(newfn) ;
}

/******************************************************************************

  Open a file for text data output, printing comment header.

  => if fn_ask is not zero, contents will be used to pick a unique
     filename (one which does not exist in this directory) by adding
     numbers if necessary before any suffix.  In this case fn will be
     replaced with whatever unique filename results.

  */
FILE *datafile_open(char *fn, const char *fn_ask, const datafile_reg_t *dfr) {

  FILE *fp ;

  if (fn_ask) strcpy(fn,fn_unique(fn_ask)) ;
  if (!(fp = fopen(fn,"w"))) {
    printf("* can\'t open \"%s\"\n",fn) ; return(0) ;
  } ;
  add_header(fp,dfr) ;
  return(fp) ;
}




