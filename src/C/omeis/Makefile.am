bin_PROGRAMS = omeis
omeis_SOURCES = File.c Pixels.c auth.c cgi.c composite.c digest.c method.c omeis.c repository.c sha1DB.c xmlBinaryResolution.c
SUBDIRS = zoom
INCLUDES = @LIBXML2_CFLAGS@ -Izoom/include
LDADD = @LIBXML2_LIBS@ ../b64z_lib.o ../base64.o zoom/lib/libzoom.a zoom/lib/libpic.a
