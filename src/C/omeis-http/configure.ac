AC_INIT(httpOMEIS.c)
AM_INIT_AUTOMAKE(httpOMEIS,0.1)
AM_CONFIG_HEADER(config.h)
AC_PROG_CC
AC_PROG_RANLIB

dnl Check for -lcurl
AC_CHECK_LIB(curl, curl_global_init)
AC_CHECK_HEADER(curl/curl.h,LIBCURL='yes',AC_MSG_ERROR([
*** OMEIS-http requires libcurl; (Required cURL headers not found) ***]))

dnl Figure out whether MATLAB user is specified
AC_ARG_WITH(MATLAB-user,
			AC_HELP_STRING([--with-MATLAB-user],
						   [specify system user who is licensed to run MATLAB]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(specified MATLAB user... $withval)
		MATLAB_USER=$withval
	fi
])

dnl Figure out whether to use matlab bindings or not.
AC_ARG_WITH(MATLAB,
			AC_HELP_STRING([--with-MATLAB],
						   [compile an additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings [defaults to no]]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(Compiling additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings... $withval)
		MATLAB="-DMATLAB"
		MATLAB_INCLUDE=`../../../src/perl2/OME/Matlab/MatlabInfo.pl $MATLAB_USER -I`
		MATLAB_LIBRARY="libhttpOMEISMATLAB.a"
	fi
], [
	AC_MSG_NOTICE(Compiling additional omeis-http library with MATLAB bindings NO)
	MATLAB_INCLUDE=""
])

AC_SUBST(MATLAB_INCLUDE)
AC_SUBST(MATLAB_LIBRARY)
AC_OUTPUT(Makefile)