# $Header$

DEST = ..
L = $(DEST)/lib
COPTS = -g $(FLOATOPT)
IPATH = -I. -I$(DEST)/include
CFLAGS = $(IPATH) $(COPTS) $(DEFINES) $(FINK_INCLUDE)

SRC = window.c pic.c pic_all.c pic_file.c swap.c \
	tiff.c jpeg.c png.c omeis.c\

OBJ = window.o pic.o pic_all.o pic_file.o swap.o \
	tiff.o jpeg.o png.o omeis.o\

OMEIS_DEPS =  ../../composite.h ../../Pixels.h ../../File.h ../../digest.h ../../repository.h ../../sha1DB.h
HDR = pixel.h window.h pic.h

.SUFFIXES: .o .s .i .c

.c.i:
	$(CC) $(CFLAGS) -P $*.c
	cat -s <$*.i >temp
	mv temp $*.i

all: libpic.a

libpic.a: $(OBJ)
	ar rcu libpic.a $(OBJ)
	ranlib libpic.a

install: libpic.a
	mv libpic.a $L
	ranlib $(L)/libpic.a
#	cp -p $(HDR) $(DEST)/include
	cp $(HDR) $(DEST)/include

libpic.lint: GHOST
	lint $(IPATH) $(SRC) >libpic.lint

clean:
	-rm -f libpic.a *.o *.lint

GHOST:

pic.o: pic.h pixel.h
window.o: window.h
pic_all.o: pic.h
pic_file.o: pic.h

tiff.o: pixel.h
jpeg.o: pixel.h
png.o: pixel.h
omeis.o: pixel.h $(OMEIS_DEPS)

