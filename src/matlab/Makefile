# Written By Tom Macura <tmacura@nih.gov>

TARGETS = haralick zernike

all: $(TARGETS)

haralick:
	make -C OME/Statistics/haralick/

zernike:
	make -C OME/Statistics/zernike/
	
clean:
	make -C OME/Statistics/haralick/ cleanest
	make -C OME/Statistics/zernike/ cleanest