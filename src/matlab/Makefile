# Written By Tom Macura <tmacura@nih.gov>

TARGETS = omeis_http haralick zernike

all: $(TARGETS)

omeis_http:
	make -C OMEIS/
	
haralick:
	make -C OME/Statistics/haralick/

zernike:
	make -C OME/Statistics/zernike/
		
clean:
	make -C OME/Statistics/haralick/ cleanest
	make -C OME/Statistics/zernike/ cleanest