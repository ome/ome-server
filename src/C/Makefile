TARGETS = DumpDV SetDVwave findSpotsOME BinarizeGlobal \
		SoftWorxSlice DumpSoftWorxHeader DumpSoftWorxExHeader \
		OME_Image_XY_stats OME_Image_XY_sums OME_Image_XYZ_fastStats \
		DumpSoftWorxStats DumpTIFFheader DumpTIFFstats OME_Image_XYZ_stats \
		maxIntensity cgrayce2
FINK_INCLUDE = -I/sw/include/
INCS    = -I/usr/local/include $(FINK_INCLUDE)
COMPRESSION_LIBS = -lz -lbz2
MATH_LIBS = -lm
LIBPATHS = -L/usr/local/lib -L/sw/lib
LIBS = $(MATH_LIBS) $(LIBPATHS)
DEFINES = -DDEBUG
COMPILER_FLAGS = -g -Wall -Winline -Wpointer-arith -Wstrict-prototypes -Wshadow -O3

CFLAGS = $(DEFINES) $(LIBPATHS) $(COMPILER_FLAGS)
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`
CC = gcc

ifndef OME_ROOT
OME_ROOT=/OME
endif

export OME_ROOT


all: $(TARGETS)

BSUtils.o: BSUtils.c
	$(CC) $(CFLAGS) -c BSUtils.c

readTiffData.o: readTiffData.c readTIFF.h
	$(CC) $(CFLAGS) -c readTiffData.c

findSpotsOME : findSpotsOME.c readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o
	$(CC) $(CFLAGS) findSpotsOME.c readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o -o findSpotsOME ${MATH_LIBS} -ltiff

BinarizeGlobal: BinarizeGlobal.c readTIFF.h readTiffData.o BSUtils.o
	$(CC) $(CFLAGS) readTiffData.o BSUtils.o BinarizeGlobal.c -o BinarizeGlobal ${MATH_LIBS} -ltiff

SoftWorxSlice: SoftWorxSlice.c BSUtils.o
	$(CC) $(CFLAGS) BSUtils.o SoftWorxSlice.c -o SoftWorxSlice ${MATH_LIBS}

DumpSoftWorxHeader: DumpSoftWorxHeader.c BSUtils.o
	$(CC) $(CFLAGS) BSUtils.o DumpSoftWorxHeader.c -o DumpSoftWorxHeader

DumpSoftWorxExHeader: DumpSoftWorxExHeader.c BSUtils.o
	$(CC) $(CFLAGS) DumpSoftWorxExHeader.c BSUtils.o -o DumpSoftWorxExHeader ${MATH_LIBS}

DumpSoftWorxStats: DumpSoftWorxStats.c BSUtils.o
	$(CC) $(CFLAGS) BSUtils.o DumpSoftWorxStats.c -o DumpSoftWorxStats ${MATH_LIBS}

DumpTIFFheader: DumpTIFFheader.c
	$(CC) $(CFLAGS) DumpTIFFheader.c -o DumpTIFFheader ${MATH_LIBS} -ltiff

DumpTIFFstats: DumpTIFFstats.c readTiffData.o
	$(CC) $(CFLAGS) DumpTIFFstats.c readTiffData.o -o DumpTIFFstats ${MATH_LIBS} -ltiff

OME_Image_XYZ_stats: OME_Image_XYZ_stats.c
	$(CC) $(CFLAGS) OME_Image_XYZ_stats.c -o OME_Image_XYZ_stats ${MATH_LIBS}

OME_Image_XYZ_fastStats: OME_Image_XYZ_fastStats.c
	$(CC) $(CFLAGS) OME_Image_XYZ_fastStats.c -o OME_Image_XYZ_fastStats ${MATH_LIBS}

OME_Image_XY_stats: OME_Image_XY_stats.c
	$(CC) $(CFLAGS) OME_Image_XY_stats.c -o OME_Image_XY_stats ${MATH_LIBS}

OME_Image_XY_sums: OME_Image_XY_sums.c
	$(CC) $(CFLAGS) OME_Image_XY_sums.c -o OME_Image_XY_sums ${MATH_LIBS}

DumpDV: DumpDV.c BSUtils.o
	$(CC) $(CFLAGS) DumpDV.c BSUtils.o -o DumpDV

SetDVwave: SetDVwave.c BSUtils.o
	$(CC) $(CFLAGS) SetDVwave.c BSUtils.o -o SetDVwave

cgrayce2:
	$(MAKE) -C cgrayce

maxIntensity: maxIntensity.c ../perl2/OME/Image/Pix/libpix.c ../perl2/OME/Image/Pix/libpix.h
	$(CC) $(CFLAGS) $(LIBPATHS) -o maxIntensity maxIntensity.c ../perl2/OME/Image/Pix/libpix.c -ltiff -lm

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
	install -c SoftWorxSlice $(OME_ROOT)/bin/SoftWorxSlice
	install -c DumpSoftWorxHeader $(OME_ROOT)/bin/DumpSoftWorxHeader
	install -c DumpSoftWorxExHeader $(OME_ROOT)/bin/DumpSoftWorxExHeader
	install -c DumpSoftWorxStats $(OME_ROOT)/bin/DumpSoftWorxStats
	install -c maxIntensity $(OME_ROOT)/bin/maxIntensity
	install -d /usr/local/bin
	install -c DumpDV /usr/local/bin/DumpDV
	install -c SetDVwave /usr/local/bin/SetDVwave
	$(MAKE) -C cgrayce install
