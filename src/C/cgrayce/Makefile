#---------------------------------------------------------------------------
#
#   ome-1.5
#
#   Copyright (c) 2001 Christopher J. Grayce
#
#   Permission to use, copy, modify, distribute and sell this software
#   including C source code and header files for any purpose is hereby 
#   granted provided the above copyright notice and this permission 
#   notice appear in all copies of the software.
#
#   THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
#   EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
#   WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
#
#-------------------------- generic macros ---------------------------------

BUILDIR = .

BINDIR = $(BUILDIR)
INCDIR = $(BUILDIR)
LIBDIR = $(BUILDIR)

CFLAGS = -O2 -Wall -finline-functions -ffast-math -funroll-loops
#CFLAGS = -g -Wall

CC = gcc

.c.o:
	$(CC) -c $(CFLAGS) -I$(INCDIR) $<

STDLIBS = -lm

#------------------ specific targets -----------------------

NAME     = ome-1.5
LIBNAME  = ome
LIB      = lib$(LIBNAME).a
HEADERS  = img_file.h gras.h hist.h datafile.h fit_nonlinear.h obj.h \
           util.h pixl.h voronoy.h fit_linear.h mosaic.h geo.h
CSRC     = img_file_tiff.c gras.c hist.c datafile.c fit_nonlinear.c \
           obj.c util.c voronoy.c pixl.c fit_linear.c mosaic.c geo.c \
           ome_info.c ome_make.c ome_copy.c ome_hist.c ome_obj.c \
           ome_cccp.c ome_tmcp.c
OBJS     = img_file_tiff.o gras.o hist.o datafile.o fit_nonlinear.o \
           obj.o geo.o pixl.o util.o voronoy.o fit_linear.o mosaic.o
HELPERS  = ome_info ome_make ome_copy ome_hist ome_obj
XTRALIBS = -lome -ltiff
LDFLAGS  = -L$(LIBDIR) $(XTRALIBS) $(STDLIBS) 
TARNAME  = $(NAME).tar.gz
TARFILE  = README Makefile $(CSRC) $(HEADERS) $(IHEADERS)

all: $(LIB) helpers ome_cccp ome_tmcp

$(LIB): $(OBJS) $(HEADERS)
	ar cr $@ $(OBJS)
	ranlib $@

helpers: $(LIB) $(HELPERS)

ome_info: $(LIB) ome_info.o
	$(CC) -o $(BINDIR)/$@ ome_info.o $(LDFLAGS)

ome_make: $(LIB) ome_make.o
	$(CC) -o $(BINDIR)/$@ ome_make.o $(LDFLAGS)

ome_copy: $(LIB) ome_copy.o
	$(CC) -o $(BINDIR)/$@ ome_copy.o $(LDFLAGS)

ome_hist: $(LIB) ome_hist.o
	$(CC) -o $(BINDIR)/$@ ome_hist.o $(LDFLAGS)

ome_obj: $(LIB) ome_obj.o
	$(CC) -o $(BINDIR)/$@ ome_obj.o $(LDFLAGS)

ome_cccp:  $(LIB) ome_cccp.o
	$(CC) -o $(BINDIR)/$@ ome_cccp.o $(LDFLAGS)

ome_tmcp:  $(LIB) ome_tmcp.o
	$(CC) -o $(BINDIR)/$@ ome_tmcp.o $(LDFLAGS)


# ------------------------- generic targets --------------------------------

clean:
	/bin/rm -f *.o
	/bin/rm -f *~
	/bin/rm -f core ome_cccp ome_tmcp $(HELPERS) $(LIB) $(TARNAME)

distclean: clean

tarfile:
	mkdir $(NAME)
	/bin/cp $(TARFILE) $(NAME)
	tar -cvf $(NAME).tar $(NAME)
	gzip -f $(NAME).tar
	/bin/rm -R $(NAME)

install:
	install -d /OME/bin
	install -c ome_cccp /OME/bin/ome_cccp
	install -c ome_tmcp /OME/bin/ome_tmcp

