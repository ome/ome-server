CC     = gcc
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`

# Don't put this cruft in if we don't need it
ifdef OSTYPE
	ifeq (,$(findstring(darwin,$(OSTYPE))))
	FINK_INCLUDE = -I/sw/include/
	FINK_LIB = -L/sw/lib/ 
	endif
endif

IM_CFLAGS = -Izoom/include
IM_LIBS = -Lzoom/lib/ -lzoom -lpic -ltiff -ljpeg -lpng

# The CPP (C-Pre-Processor) in Apple's GCC 1175 is broken, upgrade to the
# August 2003 GCC for -pedantic
CFLAGS = -O3 -g -W -Wall -Wshadow -Wmissing-prototypes -Wstrict-prototypes -Wchar-subscripts -Wformat -Wformat=2 -Wundef
LIBS   = -lm -lssl -lcrypto -lz -lbz2 -ldb $(XML2_LIBS) $(FINK_LIB) $(IM_LIBS)
INCS   = $(FINK_INCLUDE) 
OBJS   = digest.o method.o composite.o cgi.o repository.o Pixels.o File.o sha1DB.o \
		xmlBinaryResolution.o ../base64.o ../b64z_lib.o

ifndef OME_ROOT
OME_ROOT=/OME
endif

ifdef OMEIS_ROOT
DEFINES=-DOMEIS_ROOT=\"$(OMEIS_ROOT)\"
else
DEFINES=-DOMEIS_ROOT=\"$(OME_ROOT)/OMEIS\"
endif

# BSD / OS-X 64-bit portability and large file support (>4GB)
DEFINES += -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE

ifndef NO_TIFF_LZW
DEFINES += -DUSE_TIFF_LZW
endif

ifndef OMEIS_JPEG_QUALITY
OMEIS_JPEG_QUALITY=80
endif
DEFINES += -DOMEIS_JPEG_QUALITY=$(OMEIS_JPEG_QUALITY)


CFLAGS += $(DEFINES)

all: make_zoom omeis

make_zoom:
	$(MAKE) DEFINES='$(DEFINES)' -C zoom install

omeis: omeis.o zoom/lib/libzoom.a zoom/lib/libpic.a $(OBJS)
	$(CC) $(OBJS) $(LIBS) -o omeis omeis.o

omeis.o: omeis.c omeis.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) $(XML2_CFLAGS) $(INCS) -c omeis.c

digest.o: digest.c digest.h
	$(CC) $(CFLAGS) -c digest.c

method.o: method.c method.h
	$(CC) $(CFLAGS) -c method.c

composite.o: composite.c composite.h omeis.h Pixels.h File.h digest.h repository.h sha1DB.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c composite.c

cgi.o: cgi.c cgi.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c cgi.c

repository.o: repository.c repository.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c repository.c

Pixels.o: Pixels.c Pixels.h File.h digest.h repository.h sha1DB.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c Pixels.c

File.o: File.c File.h digest.h repository.h sha1DB.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c File.c

sha1DB.o: sha1DB.c sha1DB.h repository.h digest.h
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c sha1DB.c

xmlBinaryResolution.o: xmlBinaryResolution.c xmlBinaryResolution.h Pixels.h digest.h ../base64.h ../b64z_lib.h
	$(CC) $(CFLAGS) -c xmlBinaryResolution.c $(INCS) $(XML2_CFLAGS)

zoom/lib/libzoom.a: make_zoom
zoom/lib/libpic.a: make_zoom

clean:
	/bin/rm -f *.o *~ core omeis
	$(MAKE) -C zoom clean

install:
	install -c omeis $(OME_ROOT)/bin/omeis
