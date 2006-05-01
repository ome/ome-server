bin_PROGRAMS = test-concurrent-write
test_concurrent_write_SOURCES = test-concurrent-write.c ../File.c ../Pixels.c ../OMEIS_Error.c ../digest.c \
				../repository.c ../sha1DB.c \
				../File.h ../Pixels.h ../OMEIS_Error.h ../digest.h \
				../repository.h ../sha1DB.h
AM_CPPFLAGS = -DOMEIS_ROOT=\"$(OMEIS_ROOT)\" -I../zoom/include @LIBXML2_CFLAGS@
LDADD = @LIBXML2_LIBS@ ../zoom/lib/libzoom.a ../zoom/lib/libpic.a
