#  Tomasz Macura

MEX       = mex
MEX_FILE  = Znl
INC       = complex.h
LIB       = complex.c
MEX_EXT   = c # or cpp
MEX_FLAGS = -O -lm

all: $(INC) $(LIB) $(MEX_FILE).$(MEX_EXT)
	$(MEX) $(MEX_FLAGS) $(MEX_FILE).$(MEX_EXT) $(LIB)

# Utilities for cleaning up your directory.  
# 'make clean' removes emacs backup files
# 'make cleaner' also removes all object files
# 'make cleanest' also removes core, the executable, and
#      the ii_files directory created by the SGI compiler
clean:
	- rm -f *# *~ 
cleaner: clean
	- rm -f *.o
cleanest: cleaner
	- rm $(MEX_FILE).mex*
