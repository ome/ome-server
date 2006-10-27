#  Tomasz Macura

MEX       = mex
MEX_FILE  = colour_deconvolution
MEX_EXT   = c # or cpp
MEX_FLAGS = -O -inline

all: $(MEX_FILE).$(MEX_EXT)
	$(MEX) $(MEX_FLAGS) $(LIB) $(MEX_FILE).$(MEX_EXT) 

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