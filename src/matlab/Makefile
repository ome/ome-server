# Written By Tom Macura <tmacura@nih.gov>

TARGETS = omeis_http HaralickTextures Znl colour_deconvolution

all: $(TARGETS)

omeis_http:
	make -C OMEIS/
	
HaralickTextures:
	make -C OME/Statistics/HaralickTextures/
	
Znl:
	make -C OME/Statistics/Znl/
	
colour_deconvolution:
	make -C OME/Filters/colour_deconvolution
	
clean: cleanest

cleanest:
	make -C OMEIS/ cleanest
	make -C OME/Statistics/HaralickTextures/ cleanest
	make -C OME/Statistics/ZernikePolynomials/ cleanest
	make -C OME/Filters/colour_deconvolution cleanest