CFLAGS = -g -O3 -I. -I../include $(DEFINES) $(FINK_INCLUDE)

PIC_OBJ = window.o pic.o pic_all.o pic_file.o swap.o \
          tiff.o jpeg.o png.o omeis.o

ZOOM_OBJ = zoom.o scanline.o filt.o

OMEIS_DEPS =  ../../composite.h ../../Pixels.h ../../File.h ../../digest.h ../../repository.h ../../sha1DB.h

all: libpic.a libzoom.a

libpic.a: $(PIC_OBJ)
	ar rcu libpic.a $(PIC_OBJ)
	ranlib libpic.a

libzoom.a: $(ZOOM_OBJ)
	ar rcu libzoom.a $(ZOOM_OBJ)
	ranlib libzoom.a

clean:
	-rm -f libpic.a libzoom.a *.o *.lint

GHOST:

# LIBPIC Dependencies
pic.o: ../include/pic.h ../include/pixel.h
window.o: ../include/window.h
pic_all.o: ../include/pic.h
pic_file.o: ../include/pic.h
tiff.o: ../include/pixel.h
jpeg.o: ../include/pixel.h
png.o: ../include/pixel.h
omeis.o: ../include/pixel.h $(OMEIS_DEPS)

# LIBZOOM Depenendencies
zoom.o: ../include/zoom.h ../include/scanline.h ../include/filt.h
scanline.o: ../include/scanline.h
filt.o: ../include/filt.h
