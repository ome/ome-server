dnl @synopsis CHECK_SSL
dnl
dnl This macro will check various standard spots for OpenSSL including
dnl a user-supplied directory. The user uses '--with-ssl' or
dnl '--with-ssl=/path/to/ssl' as arguments to configure.
dnl
dnl If OpenSSL is found the include directory gets added to CFLAGS and
dnl CXXFLAGS as well as '-DHAVE_SSL', '-lssl' & '-lcrypto' get added
dnl to LIBS, and the libraries location gets added to LDFLAGS. Finally
dnl 'HAVE_SSL' gets set to 'yes' for use in your Makefile.in I use it
dnl like so (valid for gmake):
dnl
dnl     HAVE_SSL = @HAVE_SSL@
dnl     ifeq ($(HAVE_SSL),yes)
dnl         SRCS+= @srcdir@/my_file_that_needs_ssl.c
dnl     endif
dnl
dnl For bsd 'bmake' use:
dnl
dnl     .if ${HAVE_SSL} == "yes"
dnl         SRCS+= @srcdir@/my_file_that_needs_ssl.c
dnl     .endif
dnl
dnl @version $Id$
dnl @author Mark Ethan Trostler <trostler@juniper.net>
dnl
AC_DEFUN([CHECK_SSL],
[AC_MSG_CHECKING(if ssl is wanted)
AC_ARG_ENABLE(ssl,
AC_HELP_STRING([--disable-ssl],[disable ssl]),
[
    AC_MSG_RESULT(no)
],
[   AC_MSG_RESULT(yes)
    for dir in $withval /usr/local/ssl /usr/lib/ssl /usr/ssl /usr/pkg /usr/local /usr; do
        ssldir="$dir"
        if test -f "$dir/include/openssl/ssl.h"; then
            found_ssl="yes";
            CFLAGS="$CFLAGS -I$ssldir/include/openssl -DHAVE_SSL";
            CXXFLAGS="$CXXFLAGS -I$ssldir/include/openssl -DHAVE_SSL";
            break;
        fi
        if test -f "$dir/include/ssl.h"; then
            found_ssl="yes";
            CFLAGS="$CFLAGS -I$ssldir/include/ -DHAVE_SSL";
            CXXFLAGS="$CXXFLAGS -I$ssldir/include/ -DHAVE_SSL";
            break
        fi
    done
    if test x_$found_ssl != x_yes; then
        AC_MSG_ERROR(Cannot find ssl libraries)
    else
        printf "OpenSSL found in $ssldir\n";
        LIBS="$LIBS -lssl -lcrypto";
        LDFLAGS="$LDFLAGS -L$ssldir/lib";
        HAVE_SSL=yes
    fi
    AC_SUBST(HAVE_SSL)
])
])

dnl
dnl @synopsis CHECK_ZLIB()
dnl
dnl This macro searches for an installed zlib library. If nothing
dnl was specified when calling configure, it searches first in /usr/local
dnl and then in /usr. If the --with-zlib=DIR is specified, it will try
dnl to find it in DIR/include/zlib.h and DIR/lib/libz.a. If --without-zlib
dnl is specified, the library is not searched at all.
dnl
dnl If either the header file (zlib.h) or the library (libz) is not
dnl found, the configuration exits on error, asking for a valid
dnl zlib installation directory or --without-zlib.
dnl
dnl The macro defines the symbol HAVE_LIBZ if the library is found. You should
dnl use autoheader to include a definition for this symbol in a config.h
dnl file. Sample usage in a C/C++ source is as follows:
dnl
dnl   #ifdef HAVE_LIBZ
dnl   #include <zlib.h>
dnl   #endif /* HAVE_LIBZ */
dnl
dnl @version $Id$
dnl @author Loic Dachary <loic@senga.org>
dnl

AC_DEFUN([CHECK_ZLIB],
#
# Handle user hints
#
[AC_MSG_CHECKING(if zlib is wanted)
AC_ARG_WITH(zlib,
[  --with-zlib=DIR root directory path of zlib installation [defaults to
                    /usr/local or /usr if not found in /usr/local]
  --without-zlib to disable zlib usage completely],
[if test "$withval" != no ; then
  AC_MSG_RESULT(yes)
  ZLIB_HOME="$withval"
else
  AC_MSG_RESULT(no)
fi], [
AC_MSG_RESULT(yes)
ZLIB_HOME=/usr/local
if test ! -f "${ZLIB_HOME}/include/zlib.h"
then
        ZLIB_HOME=/usr
fi
])

#
# Locate zlib, if wanted
#
if test -n "${ZLIB_HOME}"
then
        ZLIB_OLD_LDFLAGS=$LDFLAGS
        ZLIB_OLD_CPPFLAGS=$LDFLAGS
        LDFLAGS="$LDFLAGS -L${ZLIB_HOME}/lib"
        CPPFLAGS="$CPPFLAGS -I${ZLIB_HOME}/include"
        AC_LANG_SAVE
        AC_LANG_C
        AC_CHECK_LIB(z, inflateEnd, [zlib_cv_libz=yes], [zlib_cv_libz=no])
        AC_CHECK_HEADER(zlib.h, [zlib_cv_zlib_h=yes], [zlib_cv_zlib_h=no])
        AC_LANG_RESTORE
        if test "$zlib_cv_libz" = "yes" -a "$zlib_cv_zlib_h" = "yes"
        then
                #
                # If both library and header were found, use them
                #
                AC_CHECK_LIB(z, inflateEnd)
                AC_MSG_CHECKING(zlib in ${ZLIB_HOME})
                AC_MSG_RESULT(ok)
        else
                #
                # If either header or library was not found, revert and bomb
                #
                AC_MSG_CHECKING(zlib in ${ZLIB_HOME})
                LDFLAGS="$ZLIB_OLD_LDFLAGS"
                CPPFLAGS="$ZLIB_OLD_CPPFLAGS"
                AC_MSG_RESULT(failed)
                AC_MSG_ERROR(either specify a valid zlib installation with --with-zlib=DIR or disable zlib usage with --without-zlib)
        fi
fi

])

dnl 
dnl @synopsis CHECK_BDB_COMPAT()
dnl
dnl This macro searches known Berkeley DB paths for a either a compatability
dnl or native (statically linked into libc) version of Berkeley DB. OMEIS
dnl requires this evil and horrible library in order to provide reverse
dnl lookups for SHA1 digests.
dnl
dnl It manages defines and includes for both scenarios.
dnl
dnl When the Berkeley DB is in compatability mode:
dnl #ifdef BDB_COMPAT
dnl
dnl When the Berkeley DB is native:
dnl #ifdef BDB_NATIVE
dnl
dnl @version 0.1
dnl @author Chris Allan <callan@blackcat.ca>
dnl
AC_DEFUN([CHECK_BDB_COMPAT],
[AC_MSG_CHECKING(for compat version of Berkeley DB)
	dnl Look first for db_185.h
    for dir in /usr/include \
               /usr/include/db4 \
			   /usr/include/db3 \
			   /usr/include/db2 \
			   /usr/local/include \
			   /usr/local/include/db4 \
			   /usr/local/include/db3 \
			   /usr/local/include/db2
	do
        bdbdir="$dir"
        if test -f "$dir/db_185.h"
		then
			dnl Okay... we found one
            found_bdb="yes"
			CFLAGS="$CFLAGS -I$bdbdir"
			LDFLAGS="$LDFLAGS -ldb"
			dnl Make our config.h define "DBD_COMPAT"
			AC_DEFINE([BDB_COMPAT], [1], [Define to 1 when we have a later version of BDB running in compatability mode])
			AC_MSG_RESULT($dir/db_185.h)
            break;
        fi
    done

	dnl Okay, now look for a specific DB1 version of db.h
	if test x_$found_bdb != x_yes
	then
		for dir in /usr/include/db1 \
		           /usr/local/include/db1
		do
			bdbdir="$dir"
			if test -f "$dir/db.h"
			then
				dnl Okay... we found one
				found_bdb="yes"
				CFLAGS="$CFLAGS -I$bdbdir"
				LDFLAGS="$LDFLAGS -ldb"
				dnl Make our config.h define "BDB_NATIVE" to get the db.h
				dnl include.
				AC_DEFINE([BDB_NATIVE], [1], [Define to 1 when we have a native (BSD) version of BDB])
				AC_MSG_RESULT($dir/db.h)
				break;
			fi
		done
	fi

	if test x_$found_bdb != x_yes
	then
		dnl Okay, we didn't find a compat version, check db.h
		for dir in /usr/include \
		           /usr/local/include
		do
	       	 bdbdir="$dir"
	        if test -f "$dir/db.h"
			then
				dnl Okay... we found one
            	found_bdb="yes"
				CFLAGS="$CFLAGS -I$bdbdir"
				dnl Make our config.h define "DBD_NATIVE"
				AC_DEFINE([BDB_NATIVE])
				AC_MSG_RESULT($dir/db.h)
            	break;
        	fi
    	done
	fi

	if test x_$found_bdb != x_yes
	then
		AC_MSG_RESULT(not found)
        AC_MSG_ERROR([*** OMEIS requires a compat version of Berkeley DB; (Required headers not found) ***])
    fi

	dnl Make sure the library actually links and works
	AC_MSG_CHECKING(for Berkeley DB usability)
	AC_TRY_LINK([
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>
#ifdef BDB_COMPAT
#include <db_185.h>
#else
#include <db.h>
#endif
], [
DB *myDB;
myDB = dbopen ("/tmp/foo",O_CREAT|O_RDWR, 0600, DB_BTREE, NULL);
], [valid_bdb="yes"], [valid_bdb="no"])
	if test x_$valid_bdb != x_yes
	then
		AC_MSG_RESULT(no)
   		AC_MSG_ERROR([*** OMEIS requires a compat version of Berkeley DB; (Required library not found) ***])
	else
		AC_MSG_RESULT(yes)
	fi

])

dnl
dnl @synopsis CHECK_TIFF_LZW ()
dnl
dnl This macro checks for the existence of libtiff LZW encoding. Decoding is
dnl supported by default so we're not overly worried about that.
dnl
dnl Thanks to Jan Prikryl <prikryl@cg.tuwien.ac.at> who wrote an original but
dnl antiquated macro in 2000. This is based on his work.
dnl
dnl When libtiff's LZW encoding is enabled:
dnl #ifdef HAVE_TIFF_LZW
dnl
dnl When libtiff's LZW encoding is disabled:
dnl #ifndef HAVE_TIFF_LZW
dnl
dnl @version 0.1
dnl @author Chris Allan <callan@blackcat.ca>
dnl
AC_DEFUN(CHECK_TIFF_LZW, [
	AC_MSG_CHECKING([for LZW encoder in -ltiff])
	AC_TRY_RUN([
#include <tiffio.h>
int main(void)
{
	TIFF *tif = TIFFOpen("conftest.tif", "w");

	TIFFSetField(tif, TIFFTAG_IMAGELENGTH, 1);
	TIFFSetField(tif, TIFFTAG_IMAGEWIDTH, 1);
	TIFFSetField(tif, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFInitLZW(tif, COMPRESSION_LZW);
	
	if (TIFFWriteScanline(tif, "a", 0, 0) < 0)
		return -1;

	return 0;
}
], [ lzwenc=yes ], [ lzwenc=no ])
 
	AC_MSG_RESULT([$lzwenc])
	if test x_$lzwenc = x_yes
	then
		AC_DEFINE(HAVE_TIFF_LZW, [1], [Define 1 when we want OMEIS to use LZW compression with TIFFs])
	fi
])
