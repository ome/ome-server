bin_PROGRAMS = omeis update_v1 update_v2 purge
omeis_SOURCES = File.c Pixels.c auth.c cgi.c composite.c digest.c method.c \
				omeis.c repository.c sha1DB.c xmlBinaryResolution.c \
				xmlBinaryInsertion.c xmlIsOME.c base64.c b64z_lib.c \
				File.h Pixels.h auth.h cgi.h composite.h digest.h method.h \
				omeis.h repository.h sha1DB.h xmlBinaryResolution.h \
				xmlBinaryInsertion.h xmlIsOME.h base64.h b64z_lib.h update.c 
update_v1_SOURCES = File.c Pixels.c auth.c cgi.c digest.c repository.c sha1DB.c \
				 update.c File.h Pixels.h auth.h cgi.h digest.h repository.h \
				 sha1DB.h update_v1.c
update_v2_SOURCES = File.c Pixels.c auth.c cgi.c digest.c repository.c sha1DB.c \
				 update.c File.h Pixels.h auth.h cgi.h digest.h repository.h \
				 sha1DB.h update_v2.c				 				 
purge_SOURCES = File.c Pixels.c auth.c cgi.c digest.c repository.c sha1DB.c \
				purge.c File.h Pixels.h auth.h cgi.h digest.h repository.h \
				sha1DB.h update.c
AM_CPPFLAGS = -DOMEIS_ROOT=\"$(OMEIS_ROOT)\" -Izoom/include @LIBXML2_CFLAGS@
SUBDIRS = zoom
LDADD = @LIBXML2_LIBS@ zoom/lib/libzoom.a zoom/lib/libpic.a
