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


$programName = "CCCP";
$executable = $OME->binPath().'ome_cccp';




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



#####################################


sub Do_Analysis {
$OME->StartAnalysis();

my $images = $OME->GetSelectedDatasetObjects();
my $image;
my $analysisID;
my $features;
my %attributes = (
	'correlation'        => ['CCCP','CORRELATION'],
	'corelation_masked'  => ['CCCP','CORRELATION_MASKED'],
	'spearman'           => ['CCCP','SPEARMAN'],
	'spearman_masked'    => ['CCCP','SPEARMAN_MASKED']
	);
my %datasets;
my $numDatasets = 0;
my $datasetArray;
my $key;
my $CCCP;
my $retVal;
my $cgi = $OME->cgi;
my $binWave;
my ($datasetID,$wave1ID,$wave2ID,$wave3ID,$tiff0,$tiff1,$tiff2);
my ($binName,$binPath);
my $tempFileNameErr = $OME->GetTempName ('CCCP','err') or die "Couldn't get a name for a temporary file $!\n";

# Set binWave to the wave number of the user-specified binary wave.
# In OME, wave numbers are zero-referenced, while users usualy prefer one-referenced
	if ($cgi->param ('UseBin') eq 'on') {
		$binWave = $cgi->param ('BinWave') - 1;
	} else {
		undef $binWave;
	}
	

# CCCP Usage:
#Usage: ./ome_cccp [options] imagefile1 imagefile2 [maskfile]
#Options:
#   -t <threshold_value>	Set threshold value used with maskfile
#   -i                  	Invert sense of threshold
#   -v <n>              	Set verbosity n (0=debug,1=all,2=fatal,3=none)
#Returns integrated correlation between pixel values in two images.
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

		$tiff0 = $datasetArray->[0]->Path.$datasetArray->[0]->Name;
		$tiff1 = $datasetArray->[1]->Path.$datasetArray->[1]->Name;
		$tiff2 = '';
		if (defined $binWave) {
		# Get the latest binary image for this dataset
			($binName,$binPath) = $OME->DBIhandle->selectrow_array (
				'SELECT name,path FROM binary_image WHERE dataset_id_in = '.$datasetArray->[$binWave]->ID.' ORDER BY analysis_id DESC LIMIT 1');
			$tiff2 = $binPath.$binName;
		}
	
	# Execute the CCCP program, capturing its output in $CCCP, and sending stderr to $tempFileNameErr
		$CCCP = $retVal = `$executable -v 2 $tiff0 $tiff1 $tiff2 2> $tempFileNameErr`;
	# Trim leading and trailing whitespace, set $CCCP to undef if not like a C float.
		$CCCP =~ s/^\s+//;$CCCP =~ s/\s+$//;$CCCP = undef unless ($CCCP =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
		if (defined $CCCP and $CCCP) {
			$datasetID = $datasetArray->[0]->ID;
			$wave1ID = $datasetID;
			$wave2ID = $datasetArray->[1]->ID;
			$wave3ID = undef;
			if (defined $binWave and defined $datasetArray->[$binWave]) {
				$wave3ID = $datasetArray->[$binWave]->ID;
			}
print STDERR "CCCP: Calling RegisterAnalysis for DatasetID=$datasetID\n";
	# The following statements put our results into the OME DB.
			$analysisID = $OME->RegisterAnalysis(
				datasetID     => $datasetID,
				programName   => $programName,
				NUM_WAVES     => $datasetArray->[0]->NumWaves,
				DATASET_ID_W1 => $wave1ID,
				DATASET_ID_W2 => $wave2ID,
				DATASET_ID_W3 => $wave3ID
				);
			my $features = [{correlation => $CCCP}];
			$OME->WriteFeatures ($analysisID, $features, \%attributes);
			$OME->PurgeDataset($datasetID);
			$OME->FinishAnalysis();
		}
	# Report the error.  Getting a bogus CCCP is fatal!
		else {
			die "$programName returned '$retVal' - was expecting a number.\n$programName ERROR:\n".`cat $tempFileNameErr`."\n";
		}
	}
	
	

	unlink ($tempFileNameErr);


}
