AC_INIT(libimfit,0.1)
AM_INIT_AUTOMAKE(libimfit,0.1)
AM_CONFIG_HEADER(config.h)
AC_PROG_CC
AC_PROG_CXX
AC_PROG_RANLIB

dnl ------------------------------------------------------------
dnl check for FFTW3
dnl add the corresponding options to LIBS and CXXFLAGS
dnl ------------------------------------------------------------

AC_CHECK_LIB(fftw3,fftw_execute,[AC_DEFINE(HAVE_FFTW3,1,"Turn on FFTW3 support.")],
	[AC_MSG_ERROR([FFTW3 library not found])]
)
AC_CHECK_HEADER(fftw3.h, [],
        AC_MSG_ERROR([the <fftw3.h> header file from FFTW3 could not be found.]))

AC_OUTPUT(Makefile)
