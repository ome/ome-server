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

use vars qw ($OME $programName $java $javaClassPath);

$programName = "TMCP";
$java = "/usr/java/jdk1.3/bin/java";
$javaClassPath = "/OME/java/classes";

$OME = new OMEpl;

$OME->StartAnalysis();



if ($OME->gotBrowser) {
	print_form ();
	Do_Analysis () if ($OME->cgi->param('Execute'));
	print $OME->cgi->end_html;
} else {
	Do_Analysis();
}

$OME->Finish();
undef $OME;

#####################################

sub print_form {
my $cgi = $OME->cgi;
my @cutoffSelect;
my ($row,@tableRows);

	print $OME->CGIheader();
	my $progDescr = $OME->DBIhandle->selectrow_array("SELECT description FROM programs WHERE program_name='$programName'");
	print $cgi->h3("$programName: $progDescr");

	my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
	$row = "Reference Wavelength (binary image): ".$cgi->popup_menu(-name=>'RefWave',
                            	-values=>$wavelengths, -default=>'1');
	push (@tableRows,$cgi->td($row));


	$row = "Tracked Wavelength (raw image - thresholded): ".$cgi->popup_menu(-name=>'TrackWave',
                            	-values=>$wavelengths, -default=>'2');
	push (@tableRows,$cgi->td($row));


	$row = "Distance cutoff (in pixels): ".$cgi->textfield(-name=>'Cutoff',
								-size=>4,
								-maxlength=>4);
	push (@tableRows,$cgi->td($row));

	$row = $cgi->checkbox(-name => 'Flag',
		       -label => 'Set distances above cutoff to cutoff value');
	push (@tableRows,$cgi->td($row));


	print $cgi->startform;

	print "<CENTER>";
	print $cgi->table({-border=>0,-cellspacing=>0,-cellpadding=>0},
		$cgi->Tr(\@tableRows)
		);
	print "<BR><BR>";
	print $cgi->submit(-name=>'Execute',-value=>"Run $programName");
	print "</CENTER>";
	print $OME->cgi->endform;
}


use Math::BigFloat;

sub Do_Analysis {
	
my $images = $OME->GetSelectedDatasetObjects();
my $image;
my $iWeight = shift;
my $analysisID;
my $features;
my %attributes = (
	'TMCP'        => ['TMCP','TMCP']
	);
my %datasets;
my $dataset;
my $datasetArray;
my $key;
my $TMCP;
my ($refWave,$trackWave,$cutoff,$flag);
my $cgi = $OME->cgi;

	$refWave = $cgi->param ('RefWave') - 1;
	$trackWave = $cgi->param ('TrackWave') - 1;
	$cutoff = $cgi->param ('Cutoff');
	if (defined $cutoff and $cutoff) {
		if ($cgi->param ('Flag') eq 'on') {
			$flag = 'keep';
		} else {
			$flag = 'drop';
		}
	} else {
		undef $cutoff;
	}

	
# The current incarnation of TMCP.java expects to get a file path as an argument.  This file
# is supposed to have a set of two or three tab-separated file paths per line.
# We will ask OME for a temporary filename, open it, and write the paths to the image sets in there, 
# then pass the path to the temporary file to TMCP.java, wait for the results, and erase the temporary
# file.
	my $tempFileName = $OME->GetTempName ('TMCP','in') or die "Couldn't get a name for a temporary file $!\n";
	my $tempFileNameErr = $OME->GetTempName ('TMCP','err') or die "Couldn't get a name for a temporary file $!\n";
	open (TMCP_IN,"> $tempFileName") or die "Could not open temporary file '$tempFileName' for writing $!\n";

	foreach $image (@$images)
	{
#	print STDERR "TMCP:  Dataset=$image->{Name}.\n";
		$key = $image->{BaseName}.$image->{ChemPlate}.
			$image->{Well}.$image->{Sample};
		if (not exists $datasets{$key}) {
#	print STDERR "TMCP:  Dataset Group $key - raster ID = ".$image->{RasterID}."\n";
			$datasets{$key} = $image->GetWavelengthDatasets;
		}
	}


	my $numDatasets=0;
	my @orderedDatasets;

	while ( ($key,$datasetArray) = each %datasets) {
#	print STDERR "TMCP:  Dataset Group $key\n";
		if (defined $datasetArray->[1]) {
			my ($binName,$binPath) = $OME->DBIhandle->selectrow_array (
				'SELECT name,path FROM binary_image WHERE dataset_id_in = '.$datasetArray->[$refWave]->ID);
			my $tiff0 = $binPath.$binName;
			my $weight = $OME->DBIhandle->selectrow_array (
				'SELECT threshold FROM threshold,analyses WHERE threshold.analysis_id=analyses.analysis_id '.
				' AND analyses.status = \'ACTIVE\' AND analyses.dataset_id = '.$datasetArray->[$trackWave]->ID);
#			my $features1 = $OME->GetFeatures ({
#					DatasetID     => $datasetArray->[$refWave]->ID,
#					BinName       => undef,
#					BinPath       => undef,
#					},{
#						BinName      => ['BINARY_IMAGE', 'NAME'],
#						BinPath      => ['BINARY_IMAGE', 'PATH'],
#					});
#			my $features2 = $OME->GetFeatures ({
#					DatasetID     => $datasetArray->[$trackWave]->ID,
#					Threshold     => undef
#					},{
#						Threshold    => ['THRESHOLD', 'THRESHOLD']
#					});
#
#			my $tiff0 = $features1->[0]->{BinPath}.$features1->[0]->{BinName};
#			my $weight = $features2->[0]->{Threshold};
			my $tiff1 = $datasetArray->[$trackWave]->{Path}.$datasetArray->[$trackWave]->{Name};
			
			$weight = 0 unless defined $weight;

			print TMCP_IN $tiff0,"\t",$tiff1,"\t",$weight,"\n";
			$numDatasets++;
			push (@orderedDatasets,$datasetArray);
		} else {
			$datasets{$key} = undef;
		}
	}
	close TMCP_IN;

	my $command;
	if (defined $cutoff) {
		$command = "$java -cp $javaClassPath $programName $tempFileName $cutoff $flag 2> $tempFileNameErr |";
	} else {
		$command = "$java -cp $javaClassPath $programName $tempFileName 2> $tempFileNameErr |";
	}
	open (STDOUT_PIPE,$command);	
	print STDERR "TMCP:  Calling Command\n$command\n";

	my @TMCPs;
	my $numTMCPs = 0;
	while (<STDOUT_PIPE>) {
		chomp;
		my @words = split (/\s+/);
		my $TMCP_in = $words[$#words];
		if (uc ($TMCP_in) eq 'NAN') {
			push (@TMCPs,undef);
			$numTMCPs++;
		} else {
			$TMCP = Math::BigFloat->new($TMCP_in);
		print STDERR "TMCP:  $_\nTMCP[$numTMCPs]:$TMCP\n";
			if (defined $TMCP and $TMCP) {
				push (@TMCPs,"$TMCP");
				$numTMCPs++;
			}
		}
	}
	close STDOUT_PIPE;

	die "Number of TMCPs ($numTMCPs) returned by TMCP is not the same as number of datasets entered ($numDatasets)!\n"
		unless $numTMCPs = $numDatasets;


	my $datasetNum=0;
	foreach (@TMCPs) {
		$TMCP = $_;
#		if (defined $TMCP and $TMCP) {
			my $datasetID = $orderedDatasets[$datasetNum]->[0]->{ID};
			my $refWaveID = $orderedDatasets[$datasetNum]->[$refWave]->{ID};
			my $trackWaveID = $orderedDatasets[$datasetNum]->[$trackWave]->{ID};
print STDERR "TMCP: Calling RegisterAnalysis for DatasetID=$datasetID.\n";
			$analysisID = $OME->RegisterAnalysis(
				datasetID     => $datasetID,
				programName   => $programName,
				REF_WAVE => $refWaveID,
				TRACK_WAVE => $trackWaveID,
				CUTOFF => $cutoff,
				FLAG => $flag
				);
			my $features = [{TMCP => $TMCP}];
		
#		print STDERR "TMCP:  Calling Add_Feature_Attributes.\n";
			$OME->WriteFeatures ($analysisID, $features, \%attributes);
			$OME->PurgeDataset($datasetID);
			$OME->FinishAnalysis();
#		}
		$datasetNum++;
	}
	
	

	unlink ($tempFileName);
	unlink ($tempFileNameErr);


}




