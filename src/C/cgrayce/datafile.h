/***********************************************************************


  Datafile.h

  Copyright (C) 2001 Christopher J. Grayce

  Text data files.
  Routines to ensure a text data file when it is opened has a 
  comment header automatically written of the form:

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


# program = a.out
# source = foo.c of Aug 31 2001 04:44 PDT
# date = Fri Aug 31 04:44 PDT 2001
# user@host = me@mycomputer.org
# foo = 1
# bar = 2.00000
# baz = output from test program
<data>

  Usage syntax:
  -------------

  datafile_reg_t dfr ;
  int foo ;
  double bar ;
  char *baz[] = "output from test program" ;
  FILE *fp ;

  datafile_init(&dfr,argv[0],__FILE__,__DATE__,__TIME__) ;
  datafile_register(&dfr,"foo","%d",DATAFILE_TYPE_INT,&foo) ;
  datafile_register(&dfr,"bar","%f",DATAFILE_TYPE_DOUBLE,&bar) ;
  datafile_register(&dfr,"baz","%s",DATAFILE_TYPE_STRING,&baz) ;

  if ((fp = datafile_open("foo.dat",0,&dfr)) {
     fprintf(fp,..<data>...

  datafile_free(&dfr) ;

  */
#ifndef _DATAFILE_
#define _DATAFILE_

/* types of data */
typedef enum { 
  DATAFILE_TYPE_INT, 
  DATAFILE_TYPE_DOUBLE, 
  DATAFILE_TYPE_STRING
} datafile_type_t ;

/* a header registry */
typedef struct {
  int n ;
  int nmax ;
  int next_nam ;
  int next_fmt ;
  int *nam ;
  int *fmt ;
  void **adr ;
  datafile_type_t *type ;
  char *prog ;
  char *file ;
  char *data_nam ;
  char *data_fmt ;
  size_t sz_nam ;
  size_t sz_fmt ;
} datafile_reg_t ;

/******************************************************************************

  Initialize.  

  => file, date, and time are intended to receive the compiler 
     constants __FILE__,__DATE__ and  __TIME__, to show the source code
     file of the calling program and its date of compilation.  
     prog is intended to receive the name of the calling program.

  */
int datafile_init(datafile_reg_t *dfr,
		  const char *prog, const char *file,
		  const char *date, const char *time) ;

/******************************************************************************

  Free allocated memory.  datafile_init must be called before this
  structure can be used again.

  */
void datafile_free(datafile_reg_t *dfr) ;

/******************************************************************************

  Register a variable to be printed in the datafile comment header.

  => variable's value will be read when datafile is opened, 
     NOT when variable is registered.

  */
int datafile_register(datafile_reg_t *dfr,
		      const char *name, const char *fmt, 
		      datafile_type_t type, void *adr) ;

/******************************************************************************

  Open a file for text data output, printing comment header.

  => if fn_ask is not zero, contents will be used to pick a unique
     filename (one which does not exist in this directory) by adding
     numbers if necessary before any suffix.  In this case fn will be
     replaced with whatever unique filename results.

  */
FILE *datafile_open(char *fn, const char *fn_ask, const datafile_reg_t *dfr) ;

#endif
