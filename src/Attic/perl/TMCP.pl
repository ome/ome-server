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

use vars qw ($OME $programName $executable);
$OME = new OMEpl;

$programName = "TMCP";
$executable = $OME->binPath().'ome_tmcp';





if ($OME->gotBrowser) {
	print_form ();
	Do_Analysis () if ($OME->cgi->param('Execute'));
	print $OME->cgi->end_html;
} else {
	Do_Analysis();
}

# Only if we make it here, do we commit our work to the database.
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


#	$row = "Distance cutoff (in pixels): ".$cgi->textfield(-name=>'Cutoff',
#								-size=>4,
#								-maxlength=>4);
#	push (@tableRows,$cgi->td($row));
#
#	$row = $cgi->checkbox(-name => 'Flag',
#		       -label => 'Set distances above cutoff to cutoff value');
#	push (@tableRows,$cgi->td($row));


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


sub Do_Analysis {
$OME->StartAnalysis();
	
my $images = $OME->GetSelectedDatasetObjects();
my $image;
my $analysisID;
my $features;
my %attributes = (
	'TMCP'        => ['TMCP','TMCP']
	);
my %datasets;
my $numDatasets = 0;
my $datasetArray;
my $key;
my $TMCP;
my $retVal;
my $cgi = $OME->cgi;
my ($refWave,$trackWave,$cutoff,$flag);
my ($datasetID,$refWaveID,$trackWaveID,$tiff0,$tiff1,$threshold);
my ($binName,$binPath);
my $tempFileNameErr = $OME->GetTempName ('TMCP','err') or die "Couldn't get a name for a temporary file $!\n";

# In OME, wave numbers are zero-referenced, while users usualy prefer one-referenced
	$refWave = $cgi->param ('RefWave') - 1;
	$trackWave = $cgi->param ('TrackWave') - 1;
#	$cutoff = $cgi->param ('Cutoff');
#	if (defined $cutoff and $cutoff) {
#		if ($cgi->param ('Flag') eq 'on') {
#			$flag = 'keep';
#		} else {
#			$flag = 'drop';
#		}
#	} else {
#		undef $cutoff;
#	}

	
#Usage: ./ome_tmcp [options] test_imagefile ref_imagefile
#Options:
#   -t <threshold_value> Set threshold value in test image (default=0)
#   -v <n>               Set verbosity to n (1=all,2=fatal,3=none,0=debug)
#Return TMCP correlation.
#
#
# The dataset selection may contain TIFF files that are part of the same raster -
# i.e. two or more TIFF files that are different wavelengths of the same image.
# We reduce our list of selected datasets to a list of rasters.
# The two or more selected TIFF files in the same raster will have different IDs, but the same RasterID.
# We construct a hash with the keys being the RasterIDs, and the values being an ordered array
# of dataset objects making up the raster (as returned by the GetWavelengthDatasets method).
# The array of objects returned by the GetWavelengthDatasets method is ordered by wave number (the Wave field).
	foreach $image (@$images)
	{
		$key = $image->{RasterID};
		if (not exists $datasets{$key}) {
			$datasets{$key} = $image->GetWavelengthDatasets();
			$numDatasets++;
		}
	}

#
# The number of datasets selected doesn't reflect the number of analyses we're going to perform,
# so update the session info so that the right number is displayed in the status.
# Update session info
	my $session = $OME->Session;
	my $analysis = $session->{Analyses}->{$$};
	$analysis->{NumSelectedDatasets} = $numDatasets;
	$OME->Session($session);

#
# Run through our hash of RasterIDs
	while ( ($key,$datasetArray) = each %datasets) {
	# Skip this round if we don't have a second wave
		next unless defined $datasetArray->[1];
	# Get the latest binary image for this dataset
	# This gets the latest binary image for the reference dataset.
		($binName,$binPath) = $OME->DBIhandle->selectrow_array (
			'SELECT name,path FROM binary_image WHERE dataset_id_in = '.$datasetArray->[$refWave]->ID.' ORDER BY analysis_id DESC LIMIT 1');
		$tiff1 = $binPath.$binName;
	# Get the threshold for the tracked image (test image).
	# This gets the latest threshold for the test image.
		$threshold = $OME->DBIhandle->selectrow_array (
			'SELECT threshold FROM threshold,analyses WHERE threshold.analysis_id=analyses.analysis_id '.
			' AND analyses.status = \'ACTIVE\' AND analyses.dataset_id = '.$datasetArray->[$trackWave]->ID.' ORDER BY analysis_id DESC LIMIT 1');
# This is the traditional way of getting computed 'Features'.
# We did a direct query because it seems a little faster, though by how much wasn't determined recently.
# We should probably eventually go back to doing things this way because its more general + robust.
# The first hash describes what kind of objects we want in the result,
# and the second hash describes where to get the desired fields.
#		$features1 = $OME->GetFeatures ({
#				DatasetID     => $datasetArray->[$refWave]->ID,
#				BinName       => undef,
#				BinPath       => undef,
#				},{
#					BinName      => ['BINARY_IMAGE', 'NAME'],
#					BinPath      => ['BINARY_IMAGE', 'PATH'],
#				});
#		$features2 = $OME->GetFeatures ({
#				DatasetID     => $datasetArray->[$trackWave]->ID,
#				Threshold     => undef
#				},{
#					Threshold    => ['THRESHOLD', 'THRESHOLD']
#				});
#
#		$tiff0 = $features1->[0]->{BinPath}.$features1->[0]->{BinName};
#		$threshold = $features2->[0]->{Threshold};

		$threshold = 0 unless defined $threshold;
		my $tiff0 = $datasetArray->[$trackWave]->{Path}.$datasetArray->[$trackWave]->{Name};

	# Execute the TMCP program, capturing its output in $TMCP, and sending stderr to $tempFileNameErr
		$TMCP = $retVal = `$executable -t $threshold -v 2 $tiff0 $tiff1 2> $tempFileNameErr`;
	# Trim leading and trailing whitespace, set $TMCP to undef if not like a C float.
		$TMCP =~ s/^\s+//;$TMCP =~ s/\s+$//;$TMCP = undef unless ($TMCP =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
		if (defined $TMCP and $TMCP) {
			$datasetID = $datasetArray->[0]->ID;
			$refWaveID = $datasetArray->[$refWave]->ID;
			$trackWaveID = $datasetArray->[$trackWave]->ID;
			$analysisID = $OME->RegisterAnalysis(
				datasetID     => $datasetID,
				programName   => $programName,
				REF_WAVE => $refWaveID,
				TRACK_WAVE => $trackWaveID
#				CUTOFF => $cutoff,
#				FLAG => $flag
			);
			$features = [{TMCP => $TMCP}];
		
#		print STDERR "TMCP:  Calling Add_Feature_Attributes.\n";
			$OME->WriteFeatures ($analysisID, $features, \%attributes);
			$OME->PurgeDataset($datasetID);
			$OME->FinishAnalysis();
		}
	# Report the error.  Getting a bogus TMCP is fatal!
		else {
			die "$programName returned '$retVal' - was expecting a number.\n$programName ERROR:\n".`cat $tempFileNameErr`."\n";
		}
	}
	
	

	unlink ($tempFileNameErr);


}
