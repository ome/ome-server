CC     = gcc
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`

# Don't put this cruft in if we don't need it
ifdef $(OSTYPE)
	ifeq (,$(findstring(darwin,$(OSTYPE))))
	FINK_INCLUDE = -I/sw/include/
	FINK_LIB = -L/sw/lib/ 
	endif
endif

# The CPP (C-Pre-Processor) in Apple's GCC 1175 is broken, upgrade to the
# August 2003 GCC for -pedantic
CFLAGS = -O3 -g -W -Wall -Wshadow -Wmissing-prototypes -Wstrict-prototypes -Wchar-subscripts -Wformat -Wformat=2 -Wmissing-format-attribute -Wmissing-noreturn -Wundef -std=c99
LIBS   = -lm -lssl -lcrypto -lz -lbz2 $(XML2_LIBS) $(FINK_INCLUDE) $(FINK_LIB)
OBJS   = digest.o method.o xmlBinaryResolution.o ../base64.c ../b64z_lib.c

ifndef OME_ROOT
OME_ROOT=/OME
endif

ifdef OME_ROOT
DEFINES=-DOMEIS_ROOT=\"$(OME_ROOT)/OMEIS\"
else
DEFINES=-DOMEIS_ROOT=\"/OME/OMEIS\"
endif

# BSD / OS-X 64-bit portability and large file support (>4GB)
DEFINES += -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE

all: omeis

omeis: omeis.c omeis.h $(OBJS)
	$(CC) $(CFLAGS) $(LIBS) $(XML2_CFLAGS) $(DEFINES) -o omeis omeis.c $(OBJS)

digest.o: digest.c digest.h
	$(CC) $(CFLAGS) -c digest.c

method.o: method.c method.h
	$(CC) $(CFLAGS) -c method.c

#../base64.o: ../base64.c ../base64.h
#	$(CC) $(CFLAGS) -c ../base64.c -o ../base64.o

#../b64z_lib.o: ../b64z_lib.c ../b64z_lib.h
#	$(CC) $(CFLAGS) -c ../b64z_lib.c -o ../b64z_lib.o

xmlBinaryResolution.o: xmlBinaryResolution.c
	$(CC) $(CFLAGS) -c xmlBinaryResolution.c $(FINK_INCLUDE) $(XML2_CFLAGS) 

clean:
	/bin/rm -f *.o *~ core omeis

install:
	install -c omeis $(OME_ROOT)/bin/omeis
