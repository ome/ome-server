#  Tomasz Macura

MEX       = mex
MEX_FILE  = mb_texture
MEX_EXT   = c # or cpp
MEX_FLAGS = -O -inline

INC       = CVIPtexture.h mapkit.h mapkit_generic.h
LIB       = CVIPtexture.c mapkit.c mapkit_generic.c

CC        = gcc
CC_FILE   = mb_texture_cl
CC_EXT    = c
CC_FLAGS  = -O -inline -I../../../../C/omeis-http/ -L../../../../C/omeis-http

all: mex

# compile the mex file
mex: $(INC) $(LIB) $(MEX_FILE).$(MEX_EXT)
	$(MEX) $(MEX_FLAGS) $(MEX_FILE).$(MEX_EXT) $(LIB)

# compile the standalone program
cl: $(INC) $(LIB) $(CC_FILE).$(CC_EXT)
	$(CC) $(CC_FLAGS) -o $(CC_FILE) $(CC_FILE).$(CC_EXT) $(LIB) -lcurl -lhttpOMEIS
	
# Utilities for cleaning up your directory.  
# 'make clean' removes emacs backup files
# 'make cleaner' also removes all object files
# 'make cleanest' also removes the executable

clean:
	- rm -f *# *~ 
cleaner: clean
	- rm -f *.o
cleanest: cleaner
	- rm $(MEX_FILE).mex* $(CC_FILE)