#!/usr/bin/perl -w

use OMEpl;
use OMEAnalysis;
use CGI;
use strict;

my $CGI = new CGI;
my $analysisClass = $CGI->url_param("analysis");

if ($analysisClass) {
    my $analysisMethod = "${analysisClass}::new";
    my $analysis;
    
    {
	no strict 'refs';
	eval "require $analysisClass";
	$analysis = &$analysisMethod($analysisClass);
    }
    
    my $OME = $analysis->{OME};
    
    $analysis->OutputHTMLForm();
    
    if ($OME->cgi->param('Execute')) {
	$analysis->ExecuteCGI();
    }
    
    $OME->Finish();
}
