bin_PROGRAMS = omeis update purge
omeis_SOURCES = File.c Pixels.c auth.c cgi.c composite.c digest.c method.c omeis.c repository.c sha1DB.c xmlBinaryResolution.c xmlIsOME.c
update_SOURCES = File.c Pixels.c auth.c cgi.c digest.c repository.c sha1DB.c update.c
purge_SOURCES = File.c Pixels.c auth.c cgi.c digest.c repository.c sha1DB.c purge.c
AM_CPPFLAGS = -DOMEIS_ROOT=\"$(OMEIS_ROOT)\" -Izoom/include @LIBXML2_CFLAGS@
SUBDIRS = zoom
LDADD = @LIBXML2_LIBS@ ../b64z_lib.o ../base64.o zoom/lib/libzoom.a zoom/lib/libpic.a
