AC_INIT(httpOMEIS.c)
AM_INIT_AUTOMAKE(httpOMEIS,0.1)
AM_CONFIG_HEADER(config.h)
AC_PROG_CC
AC_PROG_RANLIB

dnl Check for -lcurl
AC_CHECK_LIB(curl, curl_global_init)
AC_CHECK_HEADER(curl/curl.h,LIBCURL='yes',AC_MSG_ERROR([
*** OMEIS-http requires libcurl; (Required cURL headers not found) ***]))

dnl Figure out whether to use matlab bindings or not.
AC_ARG_WITH(matlab,
			AC_HELP_STRING([--with-matlab],
						   [compile an additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings [defaults to no]]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(Compiling additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings... $withval)
		AC_MSG_NOTICE(MATLAB include is ... $MATLAB_INCLUDE)
		MATLAB_LIBRARY="libhttpOMEISMATLAB.a"
	fi
], [
	AC_MSG_NOTICE(Compiling additional omeis-http library with MATLAB bindings NO)
	MATLAB_INCLUDE=""
])

dnl specify the MATLAB header include path
AC_ARG_WITH(matlab-include,
			AC_HELP_STRING([--with-matlab-include],
						   [specify path to Mathworks provided MATLAB header files]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(path to Mathworks provided MATLAB header files ... $withval)
		MATLAB_INCLUDE=$withval
	fi
])

AC_SUBST(MATLAB_INCLUDE)
AC_SUBST(MATLAB_LIBRARY)
AC_OUTPUT(Makefile)