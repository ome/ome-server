CC=gcc
CFLAGS=-g -Winline -Wall -Wpointer-arith -Wstrict-prototypes -O3 -std=c99 -pedantic
OBJS=
LIBS=-lm

all: omeis

omeis: omeis.c
	$(CC) $(CFLAGS) $(LIBS) -o omeis omeis.c

clean:
	rm -f omeis
