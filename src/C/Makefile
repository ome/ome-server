OBJECTS = OMEdb.o OME_DV.o rel2abs.o BSUtils.o
TARGETS = DumpDV SetDVwave findSpotsOME BinarizeGlobal \
		SoftWorxSlice DumpSoftWorxHeader DumpSoftWorxExHeader \
		OME_Image_XY_stats OME_Image_XY_sums OME_Image_XYZ_fastStats \
		DumpSoftWorxStats DumpTIFFheader DumpTIFFstats OME_Image_XYZ_stats OME_JPEG \
		cgrayce2 extractBinData insertBinData
DB_INCLUDES = -I/usr/include/pgsql
DB_LIBS = -lpq
MATH_LIBS = -lm
LIBS = $(DB_LIBS) $(MATH_LIBS) -L. -lOME
DEFINES = -DDEBUG
COMPILER_FLAGS = -g -Wall -Wpointer-arith -Wstrict-prototypes -O3
MAKEFILES = cgrayce
OME_LIB = libOME.a

CFLAGS = $(DEFINES) $(DB_INCLUDES) $(COMPILER_FLAGS)
XML2_CFLAGS = `xml2-config --cflags`
XML2_LIBS = `xml2-config --libs`
CC = gcc

all: $(TARGETS)

zernike : dataset.h dataset.c dataset.o zernike.c zernike.h BSUtils.o zernike.o
	$(CC) $(CFLAGS) -o zernike zernike.o dataset.o BSUtils.o readTiffData.o $(MATH_LIBS) -ltiff
zernike2 : dataset.h dataset.c dataset.o zernike2.c zernike.h BSUtils.o zernike2.o
	$(CC) $(CFLAGS) -o zernike2 zernike2.o dataset.o BSUtils.o readTiffData.o $(MATH_LIBS) -ltiff

trackSpotsOMEwrpr : $(OBJECTS) trackSpotsOMEwrpr.o
	$(CC) $(CFLAGS) -o trackSpotsOMEwrpr trackSpotsOMEwrpr.o $(LIBS)

findSpotsOMEwrpr : $(OBJECTS) findSpotsOMEwrpr.o
	$(CC) $(CFLAGS) -o findSpotsOMEwrpr findSpotsOMEwrpr.o $(LIBS)

OMEimportDVfile : $(OBJECTS) OMEimportDVfile.o
	$(CC) $(CFLAGS) -o OMEimportDVfile OMEimportDVfile.o $(LIBS)

trackSpotsDB :  BSUtils.o trackSpotsDB.o
	$(CC) $(CFLAGS) -o trackSpotsDB trackSpotsDB.o $(LIBS)

findSpotsDB : findSpotsDB.o
	$(CC) $(CFLAGS) findSpotsDB.o -o findSpotsDB ${MATH_LIBS} 

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

testFoo : $(OBJECTS) testFoo.o
	$(CC) $(CFLAGS) -o testFoo testFoo.o $(LIBS)

DumpDV: DumpDV.o  BSUtils.o
	$(CC) $(CFLAGS) -o DumpDV DumpDV.o BSUtils.o

SetDVwave: SetDVwave.o  BSUtils.o
	$(CC) $(CFLAGS) -o SetDVwave SetDVwave.o BSUtils.o

OME_JPEG: OME_JPEG.c
	$(CC) $(CFLAGS) -o OME_JPEG OME_JPEG.c -ljpeg

$(OME_LIB): $(OBJECTS)
	ar cr $@ $(OBJECTS)
	ranlib $@

cgrayce2:
	$(MAKE) -C cgrayce

# extractBinData and insertBinData added by Josiah 6/6/3
# I think they could be cleaned up, but I don't know how and don't have time now.
# If anyone sees this, feel free to clean them up and erase this message.
extractBinData: extractBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c b64z_lib.c base64.h ../perl2/OME/Image/Pix/libpix.h b64z_lib.h
	$(CC) $(CFLAGS) $(XML2_CFLAGS) $(XML2_LIBS) -I/sw/include/ -L/sw/lib/ -lz -lbz2 -ltiff extractBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c b64z_lib.c -o extractBinData

insertBinData: insertBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c b64z_lib.c base64.h ../perl2/OME/Image/Pix/libpix.h b64z_lib.h
	$(CC) $(CFLAGS) $(XML2_CFLAGS) $(XML2_LIBS) -I/sw/include/ -L/sw/lib/ -lbz2 -lz -ltiff insertBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c b64z_lib.c -o insertBinData

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
	install -c OME_Image_XYZ_fastStats /OME/bin/OME_Image_XYZ_fastStats
	install -c OME_Image_XY_stats /OME/bin/OME_Image_XY_stats
	install -c OME_Image_XY_sums /OME/bin/OME_Image_XY_sums
	install -c OME_JPEG /OME/bin/OME_JPEG
	install -c SoftWorxSlice /OME/bin/SoftWorxSlice
	install -c DumpSoftWorxHeader /OME/bin/DumpSoftWorxHeader
	install -c DumpSoftWorxExHeader /OME/bin/DumpSoftWorxExHeader
	install -c DumpSoftWorxStats /OME/bin/DumpSoftWorxStats
	install -c extractBinData /OME/bin/extractBinData
	install -c insertBinData /OME/bin/insertBinData
	install -d /usr/local/bin
	install -c DumpDV /usr/local/bin/DumpDV
	install -c SetDVwave /usr/local/bin/SetDVwave
	$(MAKE) -C cgrayce install

