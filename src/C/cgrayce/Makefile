#---------------------------------------------------------------------------
#
#
#   Copyright (c) 2001 Christopher J. Grayce
#
#     OME is free software; you can redistribute it and/or modify          
#     it under the terms of the GNU General Public License as published by 
#     the Free Software Foundation; either version 2 of the License, or    
#     (at your option) any later version.                                  
#
#     OME is distributed in the hope that it will be useful,               
#     but WITHOUT ANY WARRANTY; without even the implied warranty of       
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        
#     GNU General Public License for more details.                         
#
#     You should have received a copy of the GNU General Public License    
#     along with OME; if not, write to the Free Software Foundation, Inc.  
#        59 Temple Place, Suite 330, Boston, MA  02111-1307  USA           
#                                                                          
#
#
#-------------------------- generic macros ---------------------------------

BUILDIR = .

BINDIR = $(BUILDIR)
INCDIR = $(BUILDIR)
LIBDIR = $(BUILDIR)

CFLAGS = -g -O2 -Wall -finline-functions -ffast-math -funroll-loops

CC = gcc

.c.o:
	$(CC) -c $(CFLAGS) -I$(INCDIR) $<

STDLIBS = -lm

#------------------ specific targets -----------------------

NAME     = ome-1.1-IR4
LIBNAME  = ome
LIB      = lib$(LIBNAME).a
HEADERS  = img_file.h gras.h hist.h datafile.h fit_nonlinear.h obj.h \
           util.h pixl.h voronoy.h fit_linear.h mosaic.h geo.h
CSRC     = calc_separation.c gras.c datafile.c fit_linear.c \
	   fit_nonlinear.c geo.c hist.c img_file_tiff.c mosaic.c\
           obj.c ome_cccp.c ome_copy.c ome_hist.c ome_info.c \
           ome_make.c ome_obj.c ome_tmcp.c pixl.c util.c voronoy.c
OBJS     = img_file_tiff.o gras.o hist.o datafile.o fit_nonlinear.o \
	   calc_separation.o \
           obj.o geo.o pixl.o util.o voronoy.o fit_linear.o mosaic.o
HELPERS  = ome_info ome_make ome_copy ome_hist ome_obj
XTRALIBS = -lome -ltiff
LDFLAGS  = -L$(LIBDIR) $(XTRALIBS) $(STDLIBS) 
TARNAME  = $(NAME).tar.gz
TARFILE  = README Makefile $(CSRC) $(HEADERS) $(IHEADERS)

all: $(LIB) helpers ome_cccp ome_tmcp

$(LIB): $(OBJS) $(HEADERS)
	ar csr $@ $(OBJS)

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

install:
	install -c ome_cccp /OME/bin/ome_cccp
	install -c ome_tmcp /OME/bin/ome_tmcp


tarfile:
	mkdir $(NAME)
	/bin/cp $(TARFILE) $(NAME)
	tar -cvf $(NAME).tar $(NAME)
	gzip -f $(NAME).tar
	/bin/rm -R $(NAME)
