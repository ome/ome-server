CC     = gcc
CFLAGS = -g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99
LIBS   = -lm -lssl
OBJS   = digest.o
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

clean:
	/bin/rm -f *.o *~ core omeis

install:
	install -c omeis $(OME_ROOT)/bin/omeis
