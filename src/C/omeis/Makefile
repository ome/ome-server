CC     = gcc
CFLAGS = -g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99
LIBS   =-lm
ifdef OME_ROOT
DEFINES=-DOMEIS_ROOT=\"$(OME_ROOT)/OMEIS\"
else
DEFINES=-DOMEIS_ROOT=\"/OME/OMEIS\"
endif


all: omeis

omeis: omeis.c omeis.h
	$(CC) $(CFLAGS) $(LIBS) $(DEFINES) -o omeis omeis.c

clean:
	/bin/rm -f *.o *~ core omeis

install:
	install -c omeis /OME/bin/omeis
