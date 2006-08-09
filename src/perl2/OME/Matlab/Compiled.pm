# Superclass

package OME::Matlab::Compiled;

use strict;
use warnings;
use Carp;

use base qw(Class::Data::Inheritable);

our $CACHE_DIRECTORY;

BEGIN {
	use OME::Install::Environment;
	my $environment = initialize OME::Install::Environment;
	if ($environment and $environment->base_dir()) {
		$CACHE_DIRECTORY = $environment->base_dir().'/Inline';
	} else {
#		$CACHE_DIRECTORY = '/var/tmp/Inline';
		croak "OME::Matlab::Compiled was loaded without an OME installation environment!";
	}
	if (not -d $CACHE_DIRECTORY) {
		mkpath $CACHE_DIRECTORY
			or croak "Could not create cache directory for OME::Matlab::Compiled";
	}
}

use Inline ( Config => DIRECTORY => $CACHE_DIRECTORY );

use Inline (
	C       => 'DATA',
	INC		  => '-I/Applications/MATLAB72/extern/include',
);

Inline->init;

__PACKAGE__->mk_classdata('__matlabIsInitialized');
__PACKAGE__->__matlabIsInitialized(undef);

sub new {
	my $proto = shift;
	my $packageName = ref( $proto ) || $proto;
	
	# Initialize matlab as needed. Only do this once per perl interpreter
	unless( __PACKAGE__->__matlabIsInitialized() ) {
		__PACKAGE__->_initializeMatlab();
		__PACKAGE__->__matlabIsInitialized( 1 );
	}
	
	my $compData = $packageName->getComponentData();
	my $self = $packageName->_new($compData);
	return $self;
}

sub getComponentData {
	die "Cannot call getComponentData: This is an abstract method\n";
}


1;

__DATA__

__C__

#include "mclmcr.h"

static int mclDefaultPrintHandler(const char *s)
{

    return fwrite(s, sizeof(char), strlen(s), stdout);

}

static int mclDefaultErrorHandler(const char *s)
{

    int written = 0, len = 0;
    len = strlen(s);
    written = fwrite(s, sizeof(char), len, stderr);
    if (len > 0 && s[ len-1 ] != '\n')
        written += fwrite("\n", sizeof(char), 1, stderr);
    return written;

}

void _initializeMatlab(char* class)
{
	/* set flags */
	char *pStrings[]={ "-nojvm" };
	
	/* initialize matlab */
    if( !mclInitializeApplication(pStrings, 1) )
		croak("Could not initialize matlab");

}

SV *_new(char* class, SV* whichInstance)
{
	SV *obj_ref, *obj;
	HMCRINSTANCE _mcr_inst = NULL;
	mclOutputHandlerFcn error_handler = mclDefaultErrorHandler;
	mclOutputHandlerFcn print_handler = mclDefaultPrintHandler;
	
	mclComponentData *compData = (mclComponentData *)( SvIV(SvRV(whichInstance)) );
	
    if (!mclInitializeComponentInstance(&_mcr_inst,
		compData,
		true, NoObjectType, LibTarget,
		error_handler,
		print_handler))
	croak("Could not initialize matlab component instance");

	
	/* bless it into the class */
	obj_ref = newSV(0);
	sv_setref_pv(obj_ref, class, (void*) _mcr_inst);
	SvREADONLY_on(obj_ref);

	return (obj_ref);

}

void callMatlab (SV *obj, char* function, int nargout, int nargin, ...)
{
	HMCRINSTANCE _mcr_inst = (HMCRINSTANCE)( SvIV(SvRV(obj)) );
	Inline_Stack_Vars;
    mxArray** prhs = (mxArray**) mxCalloc( nargin, sizeof( mxArray* ) );
    mxArray** plhs = (mxArray**) mxCalloc( nargout, sizeof( mxArray* ) );
    int i;
    SV *response;
    char* class = "OME::Matlab::Array";
    
    for (i = 0; i < nargin; i++) {
		prhs[i] = (mxArray *)(SvIV( SvRV(Inline_Stack_Item(i+4)) ));
	}
    
	mclFeval(_mcr_inst, function, nargout, plhs, nargin, prhs);
		
	/* Free some memory */
	mxFree( prhs );
	
	/* Reset the stack so we can return stuff  */
	Inline_Stack_Reset;
	for (i = 0; i < nargout; i++) {
		response = newSV(0);
		sv_setref_pv(response, class, plhs[i] );
		Inline_Stack_Push( response );
	}
	Inline_Stack_Done;
	Inline_Stack_Return(nargout);
}

void DESTROY(SV* obj) {

	HMCRINSTANCE _mcr_inst = (HMCRINSTANCE)( SvIV(SvRV(obj)) );
	if (_mcr_inst != NULL) {
		mclTerminateInstance(&_mcr_inst);
	}
	
	mclTerminateApplication();
}