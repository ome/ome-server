#!/usr/bin/perl -w
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#


use OMEpl;
use strict;

use vars qw ($OME @threshNames @threshTypes);
@threshNames = (
	'Maximum Entropy',
	'Kittler\'s minimum error',
	'Moment-Preservation',
	'Otsu\'s moment preservation',
	'Absolute',
	'Relative to Mean',
	'Relative to Geometric Mean'
	);
@threshTypes = (
	'ME',
	'KITTLER',
	'MOMENT',
	'OTSU',
	'ABS',
	'MEAN',
	'GEO'
);

$OME = new OMEpl;

$OME->StartAnalysis();



if ($OME->gotBrowser) {
	print $OME->CGIheader(-title=>'Global thresholding');
	print_form ();
	if ($OME->cgi->param('Execute')) {
		Execute ();
		print '<H2> Finished </H2>';
	}
	print $OME->cgi->end_html;
} else {
	Do_Analysis();
}

$OME->Finish();
undef $OME;

#####################################

sub print_form {
my $cgi = $OME->cgi;
my @buttons;
my @cutoffSelect;
my $buttNum=0;
my @tableRows;
my $row;

	@buttons = $cgi->radio_group (-name  =>'Method',
							 -values    => \@threshTypes,
							 -nolabels    => 'true'
							 );


	print "<CENTER>";
	print $cgi->h2("Global Thresholding and Binary Images");
	print $cgi->startform;
	foreach (@buttons) {
		my $buttonType = $threshTypes[$buttNum];
		$row = $buttons[$buttNum];
		$row .= $threshNames[$buttNum];
		if ($buttonType eq 'ABS') {
			$row .= 'Value = ';
			$row .= $cgi->textfield(-name=>$buttonType.'_Arg',
	                    -default=>'2048',
	                    -size=>4,
	                    -maxlength=>4);
		} elsif ($buttonType eq 'MEAN' or $buttonType eq 'GEO') {
			$row .= ' +/- ';
			$row .= $cgi->textfield(-name=>$buttonType.'_Arg',
	                    -default=>'5.0',
	                    -size=>4,
	                    -maxlength=>4);
	        $row .= 'Sigma';
		}
		push (@tableRows,$cgi->td($row));
		$buttNum++;
	}
	
# Collect the wavelengths available for the selected datasets
	my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
	$row = "Wavelength: ".$cgi->popup_menu(-name=>'wavelengths',
                            	-values=>$wavelengths);
	push (@tableRows,$cgi->td($row));



	$row = '<CENTER>';
	$row .= $cgi->checkbox(-name => 'makeBinary',
			   -checked => 'checked',
		       -value => '1',
		       -label => 'Create binary images');
	$row .= '</CENTER>';
	push (@tableRows,$cgi->td($row));

	print $cgi->table({-border=>0,-cellspacing=>0,-cellpadding=>0},
		$cgi->Tr(\@tableRows)
		);
	print "<BR><BR>\n";
	print $cgi->submit(-name=>'Execute',-value=>'Execute');
	print "</CENTER>";
	print $cgi->endform;
}



sub Execute {
my $cgi = $OME->cgi;
my $method = $cgi->param('Method');
my $wavelength = $cgi->param('wavelengths');
my $argument = undef;
my $makeBinary = 0;


	if ($method eq 'ABS' or $method eq 'MEAN' or $method eq 'GEO') {
		$argument = $cgi->param($method.'_Arg')
	}

	$makeBinary = 1 if $cgi->param('makeBinary') eq '1';
	Do_Analysis ($wavelength,$method,$argument,$makeBinary);
}


sub Do_Analysis {
my ($wavelength,$method,$argument,$makeBinary) = @_;
my $images = $OME->GetSelectedDatasetObjects();
my $image;
my $iWeight = shift;
my $analysisID;
my $programName = "BinarizeGlobal";
my $programPath = "/OME/bin/BinarizeGlobal/";
my $features;
my %attributes = (
	'Type'         => ['BINARY_IMAGE','DATASET_TYPE'],
	'DatasetIDin'  => ['BINARY_IMAGE','DATASET_ID_IN'],
	'BinaryName'   => ['BINARY_IMAGE','NAME'],
	'BinaryPath'   => ['BINARY_IMAGE','PATH'],
	'Threshold'    => ['THRESHOLD',   'THRESHOLD']
	);

my $cmdBase = $programPath.$programName;
my $errFile = $OME->GetTempName ('BinGlob','err') or die "Couldn't get a name for a temporary file $!\n";


	foreach $image (@$images)
	{
		next if exists $image->{Wave} and $image->Wave ne $wavelength;
		my $cmd = $cmdBase." '".$image->Path.$image->Name."' -type=$method";
		my $makeBinaryBool = 'false';
		my ($tempFilePath,$tempFileName);
		my $datasetID = $image->ID;
		my ($fileBaseName,$extension);
		if ($makeBinary) {
		# GetNewDatasetName will add a 3-digit number between the base name and the extension to make the
		# dataset name unique.  If wantarray is true, then return the name and the path seperately.
		# If false, return the full path.
		# The base name will be the name of the dataset with "-BIN" before the extension.
			if ($image->Name =~ /(.*)\.(.*)/) {$fileBaseName = $1; $extension = $2;}
			($tempFilePath,$tempFileName) = $OME->GetNewDatasetName ($fileBaseName."-BIN.".$extension);
			die "Couldn't get a name for a temporary file $!\n"
				unless defined $tempFilePath and $tempFilePath and defined $tempFileName and $tempFileName;
			$cmd .= " -out='$tempFilePath$tempFileName'";
			$makeBinaryBool = 'true';
		}
		if (defined $argument and $argument) {
			$cmd .= " -value=$argument";
		}

		$cmd .= " -wave=$wavelength";

		my $thresh = sprintf ("%g",`$cmd 2> $errFile`);
#print STDERR "$programName:  Executing $cmd\n";
		my $error = `cat $errFile`;
		unlink ($errFile);
		die "Error executing $cmd:\n$error\n" unless defined $thresh and $thresh;
		my $analysisID = $OME->RegisterAnalysis(
			datasetID     => $datasetID,
			programName   => $programName,
			METHOD        => $method,
			ARGUMENT      => $argument,
			MAKE_BINARY   => $makeBinaryBool,
			WAVELENGTH    => $wavelength
			);
		my $features = [{
			Type         => $image->Type,
			DatasetIDin  => $datasetID,
			BinaryName   => $tempFileName,
			BinaryPath   => $tempFilePath,
			Threshold    => $thresh
			}];
	
#		print STDERR "$programName:  Calling Add_Feature_Attributes.  Threshold: $thresh, File: $tempFileName\n";
		$OME->WriteFeatures ($analysisID, $features, \%attributes);
		$OME->PurgeDataset($datasetID);
		$OME->FinishAnalysis();
		
	}

}




