OBJECTS = OMEdb.o OME_DV.o rel2abs.o BSUtils.o
TARGETS = OMEimportDVfile DumpDV SetDVwave findSpotsOME BinarizeGlobal SoftWorxSlice DumpSoftWorxHeader DumpSoftWorxStats
DB_INCLUDES = -I/usr/include/pgsql
DB_LIBS = -lpq
MATH_LIBS = -lm
LIBS = $(DB_LIBS) $(MATH_LIBS) -L. -lOME
DEFINES = -DDEBUG
COMPILER_FLAGS = -fstrict-prototypes -Wall -O2

OME_LIB = libOME.so

CFLAGS = $(DEFINES) $(DB_INCLUDES) $(COMPILER_FLAGS)
CC = gcc

all: $(OME_LIB)

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

findSpotsOME : findSpotsOME.o readTiffData.o BSUtils.o
		gcc $(DEFINES) findSpotsOME.o readTiffData.o BSUtils.o -o findSpotsOME -lm -ltiff

BinarizeGlobal : BinarizeGlobal.o readTiffData.o BSUtils.o
		gcc $(DEFINES) BinarizeGlobal.o readTiffData.o BSUtils.o -o BinarizeGlobal -lm -ltiff

SoftWorxSlice : SoftWorxSlice.o BSUtils.o
		gcc $(DEFINES) SoftWorxSlice.o BSUtils.o -o SoftWorxSlice -lm

DumpSoftWorxHeader : DumpSoftWorxHeader.o BSUtils.o
		gcc $(DEFINES) DumpSoftWorxHeader.o BSUtils.o -o DumpSoftWorxHeader -lm

DumpSoftWorxStats : DumpSoftWorxStats.o BSUtils.o
		gcc $(DEFINES) DumpSoftWorxStats.o BSUtils.o -o DumpSoftWorxStats -lm

spawnSpots : $(OBJECTS) spawnSpots.o
		gcc -o spawnSpots spawnSpots.o $(LIBS)

testFoo : $(OBJECTS) testFoo.o
		gcc  -o testFoo testFoo.o $(LIBS)

DumpDV: DumpDV.o  BSUtils.o
		gcc  -o DumpDV DumpDV.o  BSUtils.o

SetDVwave: SetDVwave.o  BSUtils.o
		gcc  -o SetDVwave SetDVwave.o  BSUtils.o

$(OME_LIB): $(OBJECTS)
	ld -shared -warn-once -o $@ $(OBJECTS) 
	
OMEdb.o : OMEdb.h
OME_DV.o : OMEdb.h
trackSpotsOMEwrpr.o : OMEdb.h
OMEimportDVfile.o : OMEdb.h



.PHONY : clean
clean :
		-rm $(OBJECTS)
		rm -f trackSpotsOMEwrpr ../bin/trackSpots/trackSpotsOMEwrpr
		rm -f ../bin/trackSpots/trackspotsOMEcolumns
		rm -f trackSpotsDB ../bin/trackSpots/trackSpotsDB
		rm -f ../bin/trackSpots/trackSpots
		rm -f findSpotsOMEwrpr ../bin/findSpots/findSpotsOMEwrpr
		rm -f ../bin/findSpots/findspotsOMEcolumns
		rm -f findSpotsDB ../bin/findSpots/findSpotsDB
		rm -f findSpotsOME ../bin/findSpots/findSpotsOME
		rm -f ../bin/findSpots/findSpots
		rm -f BinarizeGlobal ../bin/BinarizeGlobal/BinarizeGlobal
		rm -f spawnSpots ../bin/spawnSpots/spawnSpots
		rm -f /usr/sbin/OMEimportDV
		rm -f OMEimportDVfile /usr/bin/OMEimportDVfile
		rm -f /usr/bin/DumpDV
		rm -f /usr/bin/SetDVwave

install:
		cp -f trackSpotsOMEwrpr ../bin/trackSpots/
		cp -f trackspotsOMEcolumns ../bin/trackSpots/
		cp -f trackSpotsDB ../bin/trackSpots/
		ln -fs trackSpotsOMEwrpr ../bin/trackSpots/trackSpots
		cp -f findSpotsOMEwrpr ../bin/findSpots/
		cp -f findspotsOMEcolumns ../bin/findSpots/
		cp -f findSpotsDB ../bin/findSpots/
		cp -f findSpotsOME ../bin/findSpots/findSpotsOME
		ln -fs findSpotsOME ../bin/findSpots/findSpots
		cp -f BinarizeGlobal ../bin/BinarizeGlobal/BinarizeGlobal
		cp -f spawnSpots ../bin/spawnSpots/
		cp -f OMEimportDV /usr/sbin/
		cp -f OMEimportDVfile /usr/bin/
		cp -f DumpDV /usr/bin/DumpDV
		cp -f SetDVwave /usr/bin/SetDVwave

all: $(TARGETS)
