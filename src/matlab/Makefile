# Written By Tom Macura <tmacura@nih.gov>

TARGETS = omeis_http haralick zernike colour_deconvolution

all: $(TARGETS)

omeis_http:
	make -C OMEIS/
	
haralick:
	make -C OME/Statistics/haralick/
	
zernike:
	make -C OME/Statistics/zernike/
	
colour_deconvolution:
	make -C OME/Filters/colour_deconvolution
	
clean: cleanest

cleanest:
	make -C OMEIS/ cleanest
	make -C OME/Statistics/haralick/ cleanest
	make -C OME/Statistics/zernike/ cleanest
	make -C OME/Filters/colour_deconvolution cleanest