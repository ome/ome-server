dnl Process this file with autoconf to produce a configure script.

dnl Our Autoconf prerequisite, needed for AC_SYS_LARGEFILE
AC_PREREQ(2.50)

dnl Init Autoconf
AC_INIT([omeis], [0.2], [ome-devel@lists.openmicroscopy.org.uk])

dnl Yes, AM_CONFIG_HEADER is correct for our purposes. Things will still work
dnl fine but the M4 may not get built correctly if Automake is earlier than
dnl version 1.6.0. Let me know if you have any weirdness.
dnl -- Chris Allan <callan@blackcat.ca>
AM_CONFIG_HEADER(config.h)

dnl Automake time
AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)

dnl Make sure we have the canonical host variables kicking around
AC_CANONICAL_HOST

dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_RANLIB

dnl Set our default prefix to /OME
AC_PREFIX_DEFAULT(/OME)

dnl Define our OMEIS_ROOT / OME_ROOT as per configure settings or defaults
AC_ARG_WITH(omeis-root,
			AC_HELP_STRING([--with-omeis-root],
						   [root directory path of OMEIS files after installation [defaults to PREFIX/OMEIS]]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(using OMEIS root... $withval)
		OMEIS_ROOT=$withval
	fi
], [
	if test "$prefix" = "NONE"; then
		prefix="$ac_default_prefix";
	fi
		AC_MSG_NOTICE(using OMEIS root... $prefix/OMEIS)
		OMEIS_ROOT=$prefix/OMEIS;
])

# Make OMEIS_ROOT available to all our makefiles
AC_SUBST(OMEIS_ROOT)

dnl Allow variable JPEG qualities
AC_ARG_WITH(jpeg-quality,
			AC_HELP_STRING([--with-jpeg-quality],
						   [specifies the quality used when OMEIS is making JPEG's [default to 80]]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(using OMEIS JPEG quality... $withval)
		AC_DEFINE(OMEIS_JPEG_QUALITY, [$withval], [Defines the quality used when OMEIS makes JPEGs])
	fi
], [
 	AC_MSG_NOTICE(using OMEIS JPEG quality [default]... 80)
	AC_DEFINE(OMEIS_JPEG_QUALITY, [80])
])

dnl Do it early just in case any weird checks require it...
dnl ----------------------------------------------------------
dnl Ripped gloriously from GAIM (http://gaim.sourceforge.net/)
dnl -- gaim/configure.ac --
dnl Thanks to robflynn and Chipx86
dnl ----------------------------------------------------------
case "$host_os" in
	darwin*)
		AC_MSG_CHECKING([for fink])
		if test -d "/sw"; then
			AC_MSG_RESULT([found, adding /sw to search paths])
			CPPFLAGS="$CPPFLAGS -I/sw/include"
			LDFLAGS="$LDFLAGS -L/sw/lib"
		else
			AC_MSG_RESULT([not found])
		fi
	;;
	*)
	;;
esac


dnl Because our Apple friends are idiots and don't want to include things that
dnl are part of a *proper* install like pkg-config, we do this. It probably
dnl needs an M4 macro, etc. to be made more robust.
LIBXML2_CFLAGS=`xml2-config --cflags`
LIBXML2_LIBS=`xml2-config --libs`

dnl Export our libxml2 stuff
AC_SUBST(LIBXML2_CFLAGS)
AC_SUBST(LIBXML2_LIBS)
	
dnl Because of our lovely Apple friends, this isn't really portable but works
dnl great! :)
dnl PKG_CHECK_MODULES(LIBXML2, libxml-2.0)

dnl Enable 64-bit off_t on *NON* 64-bit platforms. If you're paranoid, use
dnl t/offtest.c to make sure it's working.
AC_SYS_LARGEFILE

dnl Check for -lbz2
AC_CHECK_LIB(bz2, BZ2_bzDecompress)
AC_CHECK_HEADER(bzlib.h,LIBBZ2='yes',AC_MSG_ERROR([
*** OMEIS requires libbz2; (Required BZ2 headers not found) ***]))

dnl Check for -lpng
AC_CHECK_LIB(png, png_init_io)
AC_CHECK_HEADER(png.h,LIBPNG='yes',AC_MSG_ERROR([
*** OMEIS requires libpng; (Required PNG headers not found) ***]))

dnl Check for -ljpeg
AC_CHECK_LIB(jpeg, jpeg_start_compress)
AC_CHECK_HEADER(jpeglib.h,LIBJPEG='yes',AC_MSG_ERROR([
*** OMEIS requires libjpeg; (Required JPEG headers not found) ***]))

dnl Check for -ltiff
AC_CHECK_LIB(tiff, TIFFReadScanline)
AC_CHECK_HEADER(tiffio.h,LIBTIFF='yes',AC_MSG_ERROR([
*** OMEIS requires libtiff; (Required TIFF headers not found) ***]))

dnl Check for SSL using our M4 func
CHECK_SSL

dnl Check for zlib using our M4 func
CHECK_ZLIB

dnl Check for Berkeley DB using our M4 func
CHECK_BDB_COMPAT

dnl Check for LZW encoder in libtiff
CHECK_TIFF_LZW

dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS(fcntl.h limits.h sys/time.h unistd.h)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_OFF_T
AC_TYPE_SIZE_T

dnl Checks for library functions.
AC_FUNC_MMAP
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(mkdir socket strdup strerror strstr)

AC_OUTPUT([Makefile zoom/Makefile zoom/lib/Makefile jpegls/Makefile jpegls/lib/Makefile])
