# $Header$

DEST = ..
L = $(DEST)/lib
BIN = $(DEST)/bin
COPTS = -g
IPATH = -I$(DEST)/include
CFLAGS = $(IPATH) $(COPTS)
OBJ = zoom.o scanline.o filt.o
SRC = zoom.c scanline.c filt.c
EXTRALIB = -ljpeg -lpng -lz -ltiff
HDR = filt.h zoom.h

all: libzoom.a

libzoom.a: $(OBJ)
	ar rcu libzoom.a $(OBJ)
	ranlib libzoom.a

zoom.lint: GHOST
	lint $(IPATH) $(SRC) >zoom.lint

install: zoom.o libzoom.a
	cp $(HDR) $(DEST)/include
	mv libzoom.a $(L)
	ranlib $(L)/libzoom.a

GHOST:

zoom.o: zoom.h scanline.h filt.h
scanline.o: scanline.h
filt.o: filt.h

clean:
	-rm -f zoom *.o *.lint
