OBJECTS = OMEdb.o OME_DV.o rel2abs.o BSUtils.o
TARGETS = DumpDV SetDVwave findSpotsOME BinarizeGlobal \
		SoftWorxSlice DumpSoftWorxHeader DumpSoftWorxExHeader \
		OME_Image_XY_stats \
		DumpSoftWorxStats DumpTIFFheader DumpTIFFstats OME_Image_XYZ_stats OME_JPEG makemesh \
		cgrayce2
DB_INCLUDES = -I/usr/include/pgsql
DB_LIBS = -lpq
MATH_LIBS = -lm
LIBS = $(DB_LIBS) $(MATH_LIBS) -L. -lOME
DEFINES = -DDEBUG
COMPILER_FLAGS = -Wall -g
MAKEFILES = cgrayce
OME_LIB = libOME.a

CFLAGS = $(DEFINES) $(DB_INCLUDES) $(COMPILER_FLAGS)
CC = gcc

all: $(TARGETS)

zernike : dataset.h dataset.c dataset.o zernike.c zernike.h BSUtils.o zernike.o
	gcc -o zernike zernike.o dataset.o BSUtils.o readTiffData.o $(MATH_LIBS) -ltiff
zernike2 : dataset.h dataset.c dataset.o zernike2.c zernike.h BSUtils.o zernike2.o
	gcc -o zernike2 zernike2.o dataset.o BSUtils.o readTiffData.o $(MATH_LIBS) -ltiff

trackSpotsOMEwrpr : $(OBJECTS) trackSpotsOMEwrpr.o
	gcc -o trackSpotsOMEwrpr trackSpotsOMEwrpr.o $(LIBS)

findSpotsOMEwrpr : $(OBJECTS) findSpotsOMEwrpr.o
	gcc -o findSpotsOMEwrpr findSpotsOMEwrpr.o $(LIBS)

OMEimportDVfile : $(OBJECTS) OMEimportDVfile.o
	gcc -o OMEimportDVfile OMEimportDVfile.o $(LIBS)

trackSpotsDB :  BSUtils.o trackSpotsDB.o
	gcc  -o trackSpotsDB trackSpotsDB.o $(LIBS)

findSpotsDB : findSpotsDB.o
	gcc $(DEFINES) findSpotsDB.o -o findSpotsDB -lm 

findSpotsOME : findSpotsOME.o readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o
	gcc $(DEFINES) findSpotsOME.o readTiffData.o BSUtils.o iolib/argarray.o iolib/failio.o -o findSpotsOME -lm -ltiff

makemesh: makemesh.o iolib/argarray.o iolib/failio.o iolib/repository.o
	gcc $(DEFINES) $+ -o $@

BinarizeGlobal : BinarizeGlobal.o readTiffData.o BSUtils.o
	gcc $(DEFINES) BinarizeGlobal.o readTiffData.o BSUtils.o -o BinarizeGlobal -lm -ltiff

SoftWorxSlice : SoftWorxSlice.o BSUtils.o
	gcc $(DEFINES) SoftWorxSlice.o BSUtils.o -o SoftWorxSlice -lm

DumpSoftWorxHeader : DumpSoftWorxHeader.o BSUtils.o
	gcc $(DEFINES) DumpSoftWorxHeader.o BSUtils.o -o DumpSoftWorxHeader -lm

DumpSoftWorxExHeader : DumpSoftWorxExHeader.o BSUtils.o
	gcc $(DEFINES) DumpSoftWorxExHeader.o BSUtils.o -o DumpSoftWorxExHeader -lm

DumpSoftWorxStats : DumpSoftWorxStats.o BSUtils.o
	gcc $(DEFINES) DumpSoftWorxStats.o BSUtils.o -o DumpSoftWorxStats -lm

DumpTIFFheader : DumpTIFFheader.o
	gcc $(DEFINES) DumpTIFFheader.o -o DumpTIFFheader -lm -ltiff

DumpTIFFstats : DumpTIFFstats.o readTiffData.o
	gcc $(DEFINES) DumpTIFFstats.o readTiffData.o -o DumpTIFFstats -lm -ltiff

OME_Image_XYZ_stats : OME_Image_XYZ_stats.o
	gcc $(DEFINES) OME_Image_XYZ_stats.o -o OME_Image_XYZ_stats -lm

OME_Image_XY_stats : OME_Image_XY_stats.o
	gcc $(DEFINES) OME_Image_XY_stats.o -o OME_Image_XY_stats -lm

#DumpTIFF : DumpTIFF.o
#	gcc $(DEFINES) DumpTIFF.o -o DumpTIFF -lm -ltiff

spawnSpots : $(OBJECTS) spawnSpots.o
	gcc -o spawnSpots spawnSpots.o $(LIBS)

testFoo : $(OBJECTS) testFoo.o
	gcc  -o testFoo testFoo.o $(LIBS)

DumpDV: DumpDV.o  BSUtils.o
	gcc  -o DumpDV DumpDV.o  BSUtils.o

SetDVwave: SetDVwave.o  BSUtils.o
	gcc  -o SetDVwave SetDVwave.o  BSUtils.o

OME_JPEG: OME_JPEG.c
	gcc -o OME_JPEG -O3 OME_JPEG.c -ljpeg

$(OME_LIB): $(OBJECTS)
	ar cr $@ $(OBJECTS)
	ranlib $@

cgrayce2:
	$(MAKE) -C cgrayce

OMEdb.o : OMEdb.h
OME_DV.o : OMEdb.h
trackSpotsOMEwrpr.o : OMEdb.h
OMEimportDVfile.o : OMEdb.h



.PHONY : clean
clean :
	rm -f *.o
	rm -f $(TARGETS)	
	$(MAKE) -C cgrayce clean

install:
	install -d /OME
	install -d /OME/bin
	install -d /OME/bin/findSpots
	install -c findSpotsOME /OME/bin/findSpots/findSpotsOME
	install -c findSpotsOME /OME/bin/findSpots/findSpots
	install -d /OME/bin/BinarizeGlobal
	install -c BinarizeGlobal /OME/bin/BinarizeGlobal/BinarizeGlobal
	install -c DumpTIFFheader /OME/bin/DumpTIFFheader
	install -c DumpTIFFstats /OME/bin/DumpTIFFstats
	install -c OME_Image_XYZ_stats /OME/bin/OME_Image_XYZ_stats
	install -c OME_Image_XY_stats /OME/bin/OME_Image_XY_stats
	install -c SoftWorxSlice /OME/bin/SoftWorxSlice
	install -c DumpSoftWorxHeader /OME/bin/DumpSoftWorxHeader
	install -c DumpSoftWorxExHeader /OME/bin/DumpSoftWorxExHeader
	install -c DumpSoftWorxStats /OME/bin/DumpSoftWorxStats
	install -d /usr/local/bin
	install -c DumpDV /usr/local/bin/DumpDV
	install -c SetDVwave /usr/local/bin/SetDVwave
	$(MAKE) -C cgrayce install

