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
IM_LIBS = -ltiff -ljpeg -lpng -Lzoom/lib/ -lpic -lzoom

# The CPP (C-Pre-Processor) in Apple's GCC 1175 is broken, upgrade to the
# August 2003 GCC for -pedantic
CFLAGS = -O3 -g -W -Wall -Wshadow -Wmissing-prototypes -Wstrict-prototypes -Wchar-subscripts -Wformat -Wformat=2 -Wmissing-noreturn -Wundef -std=c99
LIBS   = -lm -lssl -lcrypto -lz -lbz2 $(XML2_LIBS) $(FINK_LIB) $(IM_LIBS)
INCS   = $(FINK_INCLUDE) 
OBJS   = digest.o method.o composite.o xmlBinaryResolution.o ../base64.c ../b64z_lib.c

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

all: omeis make_zoom

make_zoom:
	$(MAKE) -C zoom install

omeis: omeis.c omeis.h $(OBJS)
	$(CC) $(CFLAGS) $(IM_CFLAGS) $(LIBS) $(INCS) $(XML2_CFLAGS) $(DEFINES) -o omeis omeis.c $(OBJS)

digest.o: digest.c digest.h
	$(CC) $(CFLAGS) -c digest.c

method.o: method.c method.h
	$(CC) $(CFLAGS) -c method.c

composite.o: composite.c composite.h
	$(MAKE) -C zoom install
	$(CC) $(CFLAGS) $(IM_CFLAGS) -c composite.c

xmlBinaryResolution.o: xmlBinaryResolution.c
	$(CC) $(CFLAGS) -c xmlBinaryResolution.c $(INCS) $(XML2_CFLAGS)

clean:
	/bin/rm -f *.o *~ core omeis
	$(MAKE) -C zoom clean

install:
	install -c omeis $(OME_ROOT)/bin/omeis
