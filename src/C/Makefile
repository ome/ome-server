OBJECTS = OME_DV.o rel2abs.o BSUtils.o
TARGETS = DumpDV SetDVwave findSpotsOME BinarizeGlobal \
		SoftWorxSlice DumpSoftWorxHeader DumpSoftWorxExHeader \
		OME_Image_XY_stats OME_Image_XY_sums OME_Image_XYZ_fastStats \
		DumpSoftWorxStats DumpTIFFheader DumpTIFFstats OME_Image_XYZ_stats OME_JPEG \
		maxIntensity cgrayce2
DB_INCLUDES = -I/usr/include/pgsql -I/usr/local/include/pgsql
FINK_INCLUDE = -I/sw/include/
INCS    = -I/usr/local/include $(FINK_INCLUDE) $(DB_INCLUDES)
DB_LIBS = -lpq
COMPRESSION_LIBS = -lz -lbz2
IMAGE_LIBS = -ltiff
MATH_LIBS = -lm
LIBPATHS = -L. -L/usr/local/lib -L/sw/lib
BIN_DATA_LIBS = $(IMAGE_LIBS) $(COMPRESSION_LIBS) $(LIBPATHS) $(INCS)
LIBS = $(DB_LIBS) $(MATH_LIBS) $(LIBPATHS) -lOME 
DEFINES = -DDEBUG
COMPILER_FLAGS = -g -Wall -Wpointer-arith -Wstrict-prototypes -O3
OME_LIB = libOME.a

CFLAGS = $(DEFINES) $(LIBPATHS) $(DB_INCLUDES) $(COMPILER_FLAGS)
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`
CC = gcc

ifndef OME_ROOT
OME_ROOT=/OME
endif

export OME_ROOT


all: $(TARGETS)

findSpotsOME : findSpotsOME.o readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o
	$(CC) $(CFLAGS) findSpotsOME.o readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o -o findSpotsOME ${MATH_LIBS} -ltiff

#makemesh: makemesh.o iolib/argarray.o iolib/failio.o iolib/repository.o
#	$(CC) $(DEFINES) $+ -o $@

BinarizeGlobal : BinarizeGlobal.o readTiffData.o BSUtils.o
	$(CC) $(CFLAGS) BinarizeGlobal.o readTiffData.o BSUtils.o -o BinarizeGlobal ${MATH_LIBS} -ltiff

SoftWorxSlice : SoftWorxSlice.o BSUtils.o
	$(CC) $(CFLAGS) SoftWorxSlice.o BSUtils.o -o SoftWorxSlice ${MATH_LIBS}

DumpSoftWorxHeader : DumpSoftWorxHeader.o BSUtils.o
	$(CC) $(CFLAGS) DumpSoftWorxHeader.o BSUtils.o -o DumpSoftWorxHeader ${MATH_LIBS}

DumpSoftWorxExHeader : DumpSoftWorxExHeader.o BSUtils.o
	$(CC) $(CFLAGS) DumpSoftWorxExHeader.o BSUtils.o -o DumpSoftWorxExHeader ${MATH_LIBS}

DumpSoftWorxStats : DumpSoftWorxStats.o BSUtils.o
	$(CC) $(CFLAGS) DumpSoftWorxStats.o BSUtils.o -o DumpSoftWorxStats ${MATH_LIBS}

DumpTIFFheader : DumpTIFFheader.o
	$(CC) $(CFLAGS) DumpTIFFheader.o -o DumpTIFFheader ${MATH_LIBS} -ltiff

DumpTIFFstats : DumpTIFFstats.o readTiffData.o
	$(CC) $(CFLAGS) DumpTIFFstats.o readTiffData.o -o DumpTIFFstats ${MATH_LIBS} -ltiff

OME_Image_XYZ_stats : OME_Image_XYZ_stats.o
	$(CC) $(CFLAGS) OME_Image_XYZ_stats.o -o OME_Image_XYZ_stats ${MATH_LIBS}

OME_Image_XYZ_fastStats : OME_Image_XYZ_fastStats.o
	$(CC) $(CFLAGS) OME_Image_XYZ_fastStats.o -o OME_Image_XYZ_fastStats ${MATH_LIBS}

OME_Image_XY_stats : OME_Image_XY_stats.o
	$(CC) $(CFLAGS) OME_Image_XY_stats.o -o OME_Image_XY_stats ${MATH_LIBS}

OME_Image_XY_sums : OME_Image_XY_sums.o
	$(CC) $(CFLAGS) OME_Image_XY_sums.o -o OME_Image_XY_sums ${MATH_LIBS}

#DumpTIFF : DumpTIFF.o
#	$(CC) $(DEFINES) DumpTIFF.o -o DumpTIFF ${MATH_LIBS} -ltiff

spawnSpots : $(OBJECTS) spawnSpots.o
	$(CC) $(CFLAGS) -o spawnSpots spawnSpots.o $(LIBS)

DumpDV: DumpDV.o  BSUtils.o
	$(CC) $(CFLAGS) -o DumpDV DumpDV.o BSUtils.o

SetDVwave: SetDVwave.o  BSUtils.o
	$(CC) $(CFLAGS) -o SetDVwave SetDVwave.o BSUtils.o

OME_JPEG: OME_JPEG.c
	$(CC) $(CFLAGS) $(FINK_INCLUDE) -o OME_JPEG OME_JPEG.c -ljpeg

$(OME_LIB): $(OBJECTS)
	ar cr $@ $(OBJECTS)
	ranlib $@

cgrayce2:
	$(MAKE) -C cgrayce

maxIntensity: maxIntensity.c ../perl2/OME/Image/Pix/libpix.c ../perl2/OME/Image/Pix/libpix.h
	$(CC) $(CFLAGS) $(LIBPATHS) -o maxIntensity maxIntensity.c ../perl2/OME/Image/Pix/libpix.c -ltiff -lm

OME_DV.o : OMEdb.h
trackSpotsOMEwrpr.o : OMEdb.h

.PHONY : clean
clean :
	rm -f *.o
	rm -f $(TARGETS)
	rm -f iolib/*.o
	$(MAKE) -C cgrayce clean

install:
	install -d $(OME_ROOT)
	install -d $(OME_ROOT)/bin
	install -d $(OME_ROOT)/bin/findSpots
	install -c findSpotsOME $(OME_ROOT)/bin/findSpots/findSpotsOME
	install -c findSpotsOME $(OME_ROOT)/bin/findSpots/findSpots
	install -d $(OME_ROOT)/bin/BinarizeGlobal
	install -c BinarizeGlobal $(OME_ROOT)/bin/BinarizeGlobal/BinarizeGlobal
	install -c DumpTIFFheader $(OME_ROOT)/bin/DumpTIFFheader
	install -c DumpTIFFstats $(OME_ROOT)/bin/DumpTIFFstats
	install -c OME_Image_XYZ_stats $(OME_ROOT)/bin/OME_Image_XYZ_stats
	install -c OME_Image_XYZ_fastStats $(OME_ROOT)/bin/OME_Image_XYZ_fastStats
	install -c OME_Image_XY_stats $(OME_ROOT)/bin/OME_Image_XY_stats
	install -c OME_Image_XY_sums $(OME_ROOT)/bin/OME_Image_XY_sums
	install -c OME_JPEG $(OME_ROOT)/bin/OME_JPEG
	install -c SoftWorxSlice $(OME_ROOT)/bin/SoftWorxSlice
	install -c DumpSoftWorxHeader $(OME_ROOT)/bin/DumpSoftWorxHeader
	install -c DumpSoftWorxExHeader $(OME_ROOT)/bin/DumpSoftWorxExHeader
	install -c DumpSoftWorxStats $(OME_ROOT)/bin/DumpSoftWorxStats
	install -c maxIntensity $(OME_ROOT)/bin/maxIntensity
	install -d /usr/local/bin
	install -c DumpDV /usr/local/bin/DumpDV
	install -c SetDVwave /usr/local/bin/SetDVwave
	$(MAKE) -C cgrayce install
