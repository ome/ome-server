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


$programName = "Neurite";
$executable = '/usr/local/bin/matlab -nosplash -nodisplay -nojvm';




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

	my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
	my %waveNumbers;
	my $waveNumber = 0;
	foreach (@$wavelengths) {
		$waveNumbers {$waveNumber} = $_;
		$waveNumber++;
	}

	$row  = $cgi->td ({-align=>'RIGHT'},"Neurite wavelength: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->popup_menu(-name=>'Neurites', -values=>\%waveNumbers, -default=>1));
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Nuclei wavelength: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->popup_menu(-name=>'Nuclei', -values=>\%waveNumbers, -default=>0));
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Size of template disk: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->textfield (-name=>'TemplateDisk', -size=>6, -default=>'6') );
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Peak Threshold: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->textfield (-name=>'PeakThresh', -size=>6, -default=>'0.2') );
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Radius of peak dilation: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->textfield (-name=>'DialRadius', -size=>6, -default=>'4') );
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Radius for closing operation : ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->textfield (-name=>'CloseDisk', -size=>6, -default=>'2') );
	push (@tableRows,$row);

	$row  = $cgi->td ({-align=>'RIGHT'},"Size of Wiener filter: ");
	$row .= $cgi->td ({-align=>'LEFT'},$cgi->textfield (-name=>'WienerFilt', -size=>6, -default=>'2') );
	push (@tableRows,$row);




	print $OME->cgi->startform;
	print "<CENTER>";
	print $cgi->table({-border=>0,-cellspacing=>0,-cellpadding=>0},
		$cgi->Tr(\@tableRows)
		);
	print "<BR><BR>";

	print $OME->cgi->submit(-name=>'Execute',-value=>"Run $programName");
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
	'ratio'        => ['neurite','ratio'],
	);
my %datasets;
my $numDatasets = 0;
my $datasetArray;
my $key;
my $ratio;
my $retVal;
my $cgi = $OME->cgi;
my ($datasetID,$neuriteID,$nucleiID,$neuriteTiff,$nucleiTiff);
my $nueriteWave = $cgi->param('Neurites');
my $nucleiWave = $cgi->param('Nuclei');
my $tempDisk = $cgi->param('TemplateDisk');
my $peakThresh = $cgi->param ('PeakThresh');
my $dialRadius = $cgi->param('DialRadius');
my $closeDisk = $cgi->param ('CloseDisk');
my $wienerFilter = $cgi->param ('WienerFilt');

my $tempFileNameIn =  $OME->GetTempName ('Neurite','in')  or die "Couldn't get a name for a temporary file $!\n";
my $tempFileNameErr = $OME->GetTempName ('Neurite','err') or die "Couldn't get a name for a temporary file $!\n";


# Neurite Usage - matlab:
# neurite ('a','b',c,d,e,f)
#a = neurite image
#b = nuclei image
#c = diameter of disk for template matching of nuclei image
#d = threshold for picking peaks from the cross correlation between the
#   template and nuclei image
#e = radius for dilation of picked peaks to increase size (used to
#    exclude neurite density near nuclei)
#f = size of disk for closing operation after canny edge detection of
#    neurite image
#g = size of wiener filter before canny edge detection of neurite image
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
			$datasetArray = $image->GetWavelengthDatasets();
		# Only put in the key if *both* necessary wavelengths exist.
			if (defined $datasetArray->[$nueriteWave] and defined $datasetArray->[$nucleiWave]) {
				$datasets{$key} = $datasetArray;
				$numDatasets++;
			}
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

# Open the matlab input file
	open (MATLABIN,"> $tempFileNameIn");
# Write a cwd directive to go to the matlab code
	print MATLABIN "cd /OME/matlab\n";
#
# Run through our hash of RasterIDs
	while ( ($key,$datasetArray) = each %datasets) {

		$neuriteTiff = $datasetArray->[$nueriteWave]->Path.$datasetArray->[$nueriteWave]->Name;
		$nucleiTiff  = $datasetArray->[$nucleiWave]->Path.$datasetArray->[$nucleiWave]->Name;
		
		print MATLABIN "neurite ('$neuriteTiff','$nucleiTiff',$tempDisk,$peakThresh,$dialRadius,$closeDisk,$wienerFilter)\n";
	}
	print MATLABIN "exit\n";
	close (MATLABIN);


my $line;
my @results;
my $resultCount=0;

#
# Execute the matlab by opening a pipe to its output
	my $cmd = "$executable < $tempFileNameIn 2> $tempFileNameErr |";
	open (MATLABOUT, $cmd) or die "Couldn't execute '$cmd':$!\n";


# Go through the matlab output as it comes in.
	while (<MATLABOUT>) {
		chomp;
		if ($_ eq 'ratio =') {
			$resultCount++;
			($key,$datasetArray) = each %datasets;
			next;
		}
		$ratio = $_;
	# Trim leading and trailing whitespace.
		$ratio =~ s/^\s+//;
		$ratio =~ s/\s+$//;
	# Numeric results ONLY.  Set undef if not like a C float.
		$ratio = undef unless ($ratio =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
		if (defined $ratio and $ratio) {
			$datasetID = $datasetArray->[0]->ID;
			$neuriteID = $datasetArray->[$nueriteWave]->ID;
			$nucleiID = $datasetArray->[$nucleiWave]->ID;
	# The following statements put our results into the OME DB.
			$analysisID = $OME->RegisterAnalysis(
				datasetID     => $datasetID,
				programName   => $programName,
				NEURITE_ID    => $neuriteID,
				NUCLEI_ID     => $nucleiID,
				TEMPLATE_DISK => $tempDisk,
				PEAK_THRESH   => $peakThresh,
				DIAL_RADIUS   => $dialRadius,
				CLOSE_DISK    => $closeDisk,
				WIENER_FILT   => $wienerFilter
				);
			my $features = [{ratio => $ratio}];
			$OME->WriteFeatures ($analysisID, $features, \%attributes);
			$OME->PurgeDataset($datasetID);
			$OME->FinishAnalysis();
		}
	}
	
	die "Number of results ($resultCount) does not match number of datasets ($numDatasets):".`cat $tempFileNameErr` unless $resultCount eq $numDatasets;
	unlink ($tempFileNameErr);
	unlink ($tempFileNameIn);


}
