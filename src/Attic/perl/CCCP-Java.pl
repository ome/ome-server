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

$programName = "CCCP";
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
my ($row,@tableRows);

	print $OME->CGIheader();
	my $progDescr = $OME->DBIhandle->selectrow_array("SELECT description FROM programs WHERE program_name='$programName'");
	print $OME->cgi->h3("$programName: $progDescr");

	$row = $cgi->checkbox(-name => 'UseBin',
		       -label => 'Use binary image as mask',
		       -checked=>'checked');
	push (@tableRows,$cgi->td($row));

	my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
	$row = "Mask wavelength: ".$cgi->popup_menu(-name=>'BinWave',
                            	-values=>$wavelengths, -default=>scalar @$wavelengths);
	push (@tableRows,$cgi->td($row));



	print $OME->cgi->startform;
	print "<CENTER>";
	print $cgi->table({-border=>0,-cellspacing=>0,-cellpadding=>0},
		$cgi->Tr(\@tableRows)
		);
	print "<BR><BR>";

	print $OME->cgi->submit(-name=>'Execute',-value=>'Run CCCP');
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
	'correlation'        => ['CCCP','CORRELATION'],
	'corelation_masked'  => ['CCCP','CORRELATION_MASKED'],
	'spearman'           => ['CCCP','SPEARMAN'],
	'spearman_masked'    => ['CCCP','SPEARMAN_MASKED']
	);
my %datasets;
my $dataset;
my $datasetArray;
my $key;
my $CCCP;
my $cgi = $OME->cgi;
my $binWave;

	if ($cgi->param ('UseBin') eq 'on') {
		$binWave = $cgi->param ('BinWave') - 1;
	} else {
		undef $binWave;
	}
	

	
# The current incarnation of CCCP.java expects to get a file path as an argument.  This file
# is supposed to have a set of two or three tab-separated file paths per line.
# We will ask OME for a temporary filename, open it, and write the paths to the image sets in there, 
# then pass the path to the temporary file to CCCP.java, wait for the results, and erase the temporary
# file.
	my $tempFileName = $OME->GetTempName ('CCCP','in') or die "Couldn't get a name for a temporary file $!\n";
	my $tempFileNameErr = $OME->GetTempName ('CCCP','err') or die "Couldn't get a name for a temporary file $!\n";
	open (CCCP_IN,"> $tempFileName") or die "Could not open temporary file '$tempFileName' for writing $!\n";

	foreach $image (@$images)
	{
#	print STDERR "CCCP:  Dataset=$image->{Name}.\n";
		$key = $image->{BaseName}.$image->{ChemPlate}.
			$image->{Well}.$image->{Sample};
		if (not exists $datasets{$key}) {
#	print STDERR "CCCP:  Dataset Group $key - raster ID = ".$image->{RasterID}."\n";
			$datasets{$key} = $image->GetWavelengthDatasets;
		}
	}


	my $numDatasets=0;
	my @orderedDatasets;
	while ( ($key,$datasetArray) = each %datasets) {
#	print STDERR "CCCP:  Dataset Group $key\n";
		if (defined $datasetArray->[1]) {
			my $tiff0 = $datasetArray->[0]->{Path}.$datasetArray->[0]->{Name};
			my $tiff1 = $datasetArray->[1]->{Path}.$datasetArray->[1]->{Name};
			my $tiff2 = '';
			if (defined $binWave) {
				my ($binName,$binPath) = $OME->DBIhandle->selectrow_array (
					'SELECT name,path FROM binary_image WHERE dataset_id_in = '.$datasetArray->[$binWave]->ID);
				$tiff2 = $binPath.$binName;
#				my $features = $OME->GetFeatures ({
#					DatasetID     => $datasetArray->[$binWave]->ID,
#					BinName       => undef,
#					BinPath       => undef,
#					},{
#						BinName      => ['BINARY_IMAGE', 'NAME'],
#						BinPath      => ['BINARY_IMAGE', 'PATH'],
#					});
#
#				$tiff2 = $features->[0]->{BinPath}.$features->[0]->{BinName};
			}
			print CCCP_IN $tiff0,"\t",$tiff1,"\t",$tiff2,"\n";
			$numDatasets++;
			push (@orderedDatasets,$datasetArray);
		} else {
			$datasets{$key} = undef;
		}
	}
	close CCCP_IN;

	my $command = "$java -cp $javaClassPath $programName $tempFileName 2> $tempFileNameErr |";
	open (STDOUT_PIPE,$command);	
#	print STDERR "CCCP:  Calling Command\n$command\n";

	my @CCCPs;
	my $numCCCPs = 0;
	while (<STDOUT_PIPE>) {
		chomp;
	print STDERR "CCCP:  CCCP[$numCCCPs]:$_\n";
		$CCCP = Math::BigFloat->new($_);
		push (@CCCPs,"$CCCP");
		$numCCCPs++;
	}
	close STDOUT_PIPE;

	die "Number of CCCPs ($numCCCPs) returned by CCCP is not the same as number of datasets entered ($numDatasets)!\n"
		unless $numCCCPs = $numDatasets;


	my $datasetNum=0;
	foreach (@CCCPs) {
		$CCCP = $_;
		if (defined $CCCP and $CCCP) {
			my $datasetID = $orderedDatasets[$datasetNum]->[0]->{ID};
			my $wave1ID = $datasetID;
			my $wave2ID = $orderedDatasets[$datasetNum]->[1]->{ID};
			my $wave3ID = undef;
			if (defined $binWave and defined $orderedDatasets[$datasetNum]->[$binWave]) {
				$wave3ID = $orderedDatasets[$datasetNum]->[$binWave]->{ID};
			}
print STDERR "CCCP: Calling RegisterAnalysis for DatasetID=$orderedDatasets[$datasetNum]->[0]->{ID}.\n";
			$analysisID = $OME->RegisterAnalysis(
				datasetID     => $datasetID,
				programName   => $programName,
				NUM_WAVES     => scalar @{$orderedDatasets[$datasetNum]},
				DATASET_ID_W1 => $wave1ID,
				DATASET_ID_W2 => $wave2ID,
				DATASET_ID_W3 => $wave3ID
				);
			my $features = [{correlation => $CCCP}];
		
#		print STDERR "CCCP:  Calling Add_Feature_Attributes.\n";
			$OME->WriteFeatures ($analysisID, $features, \%attributes);
			$OME->PurgeDataset($datasetID);
			$OME->FinishAnalysis();
		}
		$datasetNum++;
	}
	
	

	unlink ($tempFileName);
	unlink ($tempFileNameErr);


}




