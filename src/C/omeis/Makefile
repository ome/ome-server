CC     = gcc
CFLAGS = -g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99
LIBS   =-lm

all: omeis

omeis: omeis.c omeis.h
	$(CC) $(CFLAGS) $(LIBS) -o omeis omeis.c

clean:
	/bin/rm -f *.o *~ core omeis

install:
	install -c omeis /OME/bin/omeis
