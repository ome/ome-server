CC     = gcc
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`
FINK_INCLUDE = -I/sw/include/
FINK_LIB = -L/sw/lib/ 
# ugh! pedantic has too many complaints: 'omeis.c:37:3: warning: style of line directive is a GCC extension'
#CFLAGS = -g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99 -pedantic
CFLAGS = -g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99 $(XML2_CFLAGS)
LIBS   = -lm -lssl -lcrypto -lz -lbz2 $(XML2_LIBS) $(FINK_INCLUDE) $(FINK_LIB)
OBJS   = digest.o method.o extractBinDataIS.o ../base64.o ../b64z_lib.o
ifndef OME_ROOT
OME_ROOT=/OME
endif

ifdef OME_ROOT
DEFINES=-DOMEIS_ROOT=\"$(OME_ROOT)/OMEIS\"
else
DEFINES=-DOMEIS_ROOT=\"/OME/OMEIS\"
endif


all: omeis

omeis: omeis.c omeis.h $(OBJS)
	$(CC) $(CFLAGS) $(LIBS) $(DEFINES) -o omeis omeis.c $(OBJS)

digest.o: digest.c digest.h
	$(CC) $(CFLAGS) -c digest.c

method.o: method.c method.h
	$(CC) $(CFLAGS) -c method.c

../base64.o: ../base64.c ../base64.h
	$(CC) $(CFLAGS) -c ../base64.c -o ../base64.o

../b64z_lib.o: ../b64z_lib.c ../b64z_lib.h
	$(CC) $(CFLAGS) -c ../b64z_lib.c -o ../b64z_lib.o

extractBinDataIS.o: extractBinDataIS.c
	$(CC) $(CFLAGS) -c extractBinDataIS.c $(FINK_INCLUDE)

clean:
	/bin/rm -f *.o *~ core omeis

install:
	install -c omeis $(OME_ROOT)/bin/omeis
