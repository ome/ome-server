#!/usr/bin/perl -w

use OMEpl;
use OMEAnalysis;
use OMEAnalysis::FindSpots;
use strict;

my $analysis = new OMEAnalysis::FindSpots;
my $OME = $analysis->{OME};

$analysis->OutputHTMLForm();

if ($OME->cgi->param('Execute')) {
    $analysis->ExecuteCGI();
}

$OME->Finish();
