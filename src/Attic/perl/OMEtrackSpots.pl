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

use vars qw ($OME);


$OME = new OMEpl;

$OME->StartAnalysis();



print_form ();
execute () if ($OME->cgi->param('Execute'));

print $OME->cgi->end_html;
$OME->Finish();
undef $OME;


sub print_form {

#
# The user specifies wether a distance cutoff or a sigma cutoff is to be used
# Page layout is two radio buttons and two text fields.  Not really necessary to put them in
# a table.
#

my $cgi = $OME->cgi;
my @cutoffSelect;

	print $OME->CGIheader();
	print $OME->cgi->h2("Enter intensity weight for tracking spots:");
	print $OME->cgi->startform;
	print "Intensity weight:",$cgi->textfield(-name=>'iWeight',-size=>5);
		
	print "<CENTER>", $OME->cgi->submit(-name=>'Execute',-value=>'Run trackSpots'), "</CENTER>";
	print $OME->cgi->endform;
}




sub execute {

	Do_Analysis( sprintf ("%f",$OME->cgi->param('iWeight')) );

	$OME->Finish();
}



sub Do_Analysis {
	
my $datasets = $OME->GetSelectedDatasets();
my $dataset;
my $iWeight = shift;
my $analysisID;
my $programName = "trackSpots2";
my $features;
my %attributes = (
	'trajectory_ID' => ['DELTA','TRAJECTORY_ID'],
	'movedTo'       => ['DELTA','MOVED_TO'],
	'deltaX'        => ['DELTA','DELTA_X'],
	'deltaY'        => ['DELTA','DELTA_Y'],
	'deltaZ'        => ['DELTA','DELTA_Z'],
	'distance'      => ['DELTA','DISTANCE'] 
	);

	print STDERR "OMEtrackspots:  Calling StartAnalysis.\n";

	$OME->StartAnalysis();
	foreach $dataset (@$datasets)
	{
	print STDERR "OMEtrackspots:  Calling RegisterAnalysis for DatasetID=$dataset.\n";
		$analysisID = $OME->RegisterAnalysis(
			datasetID    => $dataset,
			programName  => $programName,
			INTENS_WEIGHT  => $iWeight);

	print STDERR "OMEtrackspots:  Calling Track_Features.\n";
		$features = Track_Features($dataset,$iWeight);
		
	print STDERR "OMEtrackspots:  Calling Add_Feature_Attributes.\n";
		$OME->WriteFeatures ($analysisID, $features, \%attributes);
		
		$OME->PurgeDataset($dataset);
#print "Purged dataset \n";
		$OME->FinishAnalysis();
#print "Finished analysis\n";
	}

}




sub Track_Features {
my $datasetID = shift;
my $iWeight = shift;
my %attributes = (
	X => ['LOCATION', 'X'],
	Y => ['LOCATION', 'Y'],
	Z => ['LOCATION', 'Z'],
	t => ['TIMEPOINT','TIMEPOINT']
	);
my $features = $OME->GetFeatures ({
		DatasetID     => $datasetID,
		X             => undef,
		Y             => undef,
		Z             => undef,
		t             => undef,
		xPix          => undef,
		yPix          => undef,
		zPix          => undef,
		trajectory_ID => undef,
		movedTo       => undef,
		deltaX        => undef,
		deltaY        => undef,
		deltaZ        => undef,
		distance      => undef
		},\%attributes);
my %timepointHash;
my @timepoints;
my $timepoint;
my $featureID;
my $feature;
my $movedTo;
my @featureList;
my $i;

# Sort the features by timepoint, and copy the pixel coordinates to a different datamember b/c
# X, Y, Z will be reset when we convert to real coordinates.
	foreach $feature (@$features)
	{
		$feature->xPix($feature->X);
		$feature->yPix($feature->Y);
		$feature->zPix($feature->Z);
		$timepoint = $feature->t;
		$featureID = $feature->ID;
		push (@{$timepointHash{$timepoint}},$feature);
	}

# Convert coordinates to real coordinates
	Convert_Coordinates ($features);

# Sort the timepoint hash
	foreach $timepoint (sort {$a <=> $b} keys %timepointHash)
	{
		push (@timepoints,$timepointHash{$timepoint});
	}

# For each feature in each timepoint, find the nearest neighbor in the next timepoint.
	for ($i=0; $i < (@timepoints-1); $i++)
	{
#	print "timepoint $timepoint\n";
		foreach $feature (@{$timepoints[$i]})
		{
	# If the feature does not have a defined trajectory ID, then assign one.
			if (not defined $feature->trajectory_ID)
			{
				$feature->trajectory_ID ($OME->GetOID('TRAJECTORY_ID_SEQ'));
			}
			Get_Nearest_Feature ($feature,$timepoints[$i+1],$iWeight);
		}
	}
	
	
#	print "features is a reference to ".ref($features)."\n";
#	foreach $feature (@$features) {print $feature->ID."\n";}
	return $features;

}


sub Get_Nearest_Feature {
	my $ourFeature = shift;
	my $features = shift;
	my $iWeight = shift;
	my $nearestFeature = undef;
	my $nearestDistance=undef;
	my $distance=$nearestDistance;
	my $feature;
	
		foreach $feature (@$features)
		{
			if ($ourFeature ne $feature)
			{
				$distance = Get_Feature_Distance ($ourFeature,$feature,$iWeight);
				if (not defined $nearestDistance or $distance < $nearestDistance)
				{
					$nearestDistance = $distance;
					$nearestFeature = $feature;
				}
	#print $ourFeature->ID."->".$feature->ID." = $distance (nearest = $nearestDistance)\n";
			}
		}

		$ourFeature->deltaX($nearestFeature->xPix - $ourFeature->xPix);
		$ourFeature->deltaY($nearestFeature->yPix - $ourFeature->yPix);
		$ourFeature->deltaZ($nearestFeature->zPix - $ourFeature->zPix);
		$ourFeature->distance($nearestDistance);
		$ourFeature->movedTo($nearestFeature->ID);
		$nearestFeature->trajectory_ID($ourFeature->trajectory_ID);
		
}

sub Get_Feature_Distance {
	my $feature1 = shift;
	my $feature2 = shift;
	my $iWeight = shift;
	my $distance;
	my ($x1,$x2,$y1,$y2,$z1,$z2);

	$distance = sqrt
		(
			( ($feature2->X - $feature1->X)**2 ) +
			( ($feature2->Y - $feature1->Y)**2 ) +
			( ($feature2->Z - $feature1->Z)**2 )
		);
	
	return ($distance);
}




sub Convert_Coordinates {

	my $features = shift;
	my $feature;
	my ($size_x,$size_y,$size_z);
	my $datasetID = $features->[0]->DatasetID;
	my %pixelSize = $OME->GetPixelSizes ($datasetID);

	foreach $feature (@$features)
	{
		$feature->X ($feature->X*$pixelSize{X});
		$feature->Y ($feature->Y*$pixelSize{Y});
		$feature->Z ($feature->Z*$pixelSize{Z});
	}
#	print "pixelSize X: ",$pixelSize{X},"pixelSize Y: ",$pixelSize{Y},"pixelSize Z: ",$pixelSize{Z};
}
