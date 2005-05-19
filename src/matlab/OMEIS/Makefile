#  Tomasz Macura

MEX       = mex
MEX_FLAGS = -O -inline -I../../C/omeis-http/ -L../../C/omeis-http  -lcurl -lhttpOMEIS

targets: newPixels.mex* pixelsInfo.mex* finishPixels.mex* getPixels.mex* setPixels.mex*

newPixels.mex*: newPixels.c 
	$(MEX) $(MEX_FLAGS) newPixels.c
	
pixelsInfo.mex*: pixelsInfo.c
	$(MEX) $(MEX_FLAGS) pixelsInfo.c
	
finishPixels.mex*: finishPixels.c
	$(MEX) $(MEX_FLAGS) finishPixels.c
	
getPixels.mex*: getPixels.c
	$(MEX) $(MEX_FLAGS) getPixels.c

setPixels.mex*: setPixels.c
	$(MEX) $(MEX_FLAGS) setPixels.c
	
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
	- rm *.mex*