#!/usr/bin/perl -w

use OMEpl;
use OMEAnalysis;
use OMEAnalysis::TrackSpots;
use strict;

my $analysis = new OMEAnalysis::TrackSpots;
my $OME = $analysis->{OME};

$analysis->OutputHTMLForm();

if ($OME->cgi->param('Execute')) {
    $analysis->ExecuteCGI();
}

$OME->Finish();
