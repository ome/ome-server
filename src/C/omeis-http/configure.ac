AC_INIT(httpOMEIS.c)
AM_INIT_AUTOMAKE(httpOMEIS,0.1)
AM_CONFIG_HEADER(config.h)
AC_PROG_CC
AC_PROG_RANLIB

dnl Check for -lcurl
AC_CHECK_LIB(curl, curl_global_init)
AC_CHECK_HEADER(curl/curl.h,LIBCURL='yes',AC_MSG_ERROR([
*** OMEIS-http requires libcurl; (Required cURL headers not found) ***]))

dnl specify the MATLAB install path
AC_ARG_WITH(matlab-path,
			AC_HELP_STRING([--with-matlab-path],
						   [specify path to MATLAB install]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(path to MATLAB install ... $withval)
		MATLAB_PATH=$withval
	fi
])

dnl specify the MATLAB licensed user
AC_ARG_WITH(matlab-user,
			AC_HELP_STRING([--with-matlab-user],
						   [specify system user who is licensed to run MATLAB]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(specified MATLAB user... $withval)
		MATLAB_USER=$withval
	fi
])

dnl specify the MATLAB install path
AC_ARG_WITH(matlab-flags,
			AC_HELP_STRING([--with-matlab-flags],
						   [specify flags with which MATLAB should be run]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(MATLAB flags ... $withval)
		MATLAB_FLAGS=$withval
	fi
])


dnl Figure out whether to use matlab bindings or not.
AC_ARG_WITH(matlab,
			AC_HELP_STRING([--with-matlab],
						   [compile an additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings [defaults to no]]),
[
	if test "$withval" != no ; then
		AC_MSG_NOTICE(Compiling additional omeis-http library (libhttpOMEIS-MATLAB) with MATLAB bindings... $withval)
		MATLAB="-DMATLAB"
		MATLAB_INCLUDE=`../../../src/perl2/OME/Matlab/MatlabInfo.pl -matlab-path=$MATLAB_PATH -matlab-user=$MATLAB_USER -matlab-flags="$MATLAB_FLAGS" -I`
		AC_MSG_NOTICE(MATLAB include is ... $MATLAB_INCLUDE)
		MATLAB_LIBRARY="libhttpOMEISMATLAB.a"
	fi
], [
	AC_MSG_NOTICE(Compiling additional omeis-http library with MATLAB bindings NO)
	MATLAB_INCLUDE=""
])

AC_SUBST(MATLAB_INCLUDE)
AC_SUBST(MATLAB_LIBRARY)
AC_OUTPUT(Makefile)