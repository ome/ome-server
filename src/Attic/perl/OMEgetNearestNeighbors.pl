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

use Pg;
use OMEpl;
use strict;

use vars qw ($OME $distCutoff $sigmaCutoff);

END
{
	$OME = undef;
}

$OME = new OMEpl;

$OME->StartAnalysis();



if ($OME->inWebServer)
{
	print_form ();
	Do_Analysis () if ($OME->cgi->param('Execute'));
	print $OME->cgi->end_html;
}
else
{
	Do_Analysis ();
}





sub print_form {

		
	print $OME->cgi->header (-cookie=>[$OME->connInfoCookie,$OME->SIDcookie],-type=>'text/html');
	print $OME->cgi->start_html(-title=>'Get Nearest Neighbors');
	print $OME->cgi->startform;
	print "<CENTER>", $OME->cgi->submit(-name=>'Execute',-value=>'Get nearest neighbors'), "</CENTER>";
	print $OME->cgi->endform;
}




sub Do_Analysis {
	
	my @datasets = $OME->GetSelectedDatasets();
	my $dataset;
	my $analysisID;
	my $programName = "getNearestNeighbors";
	my $features;
	my $feature;
	my %attributes = (
		'NEAREST_NEIGHBOR__DELTA_X' => 'delta_X',
		'NEAREST_NEIGHBOR__DELTA_Y' => 'delta_Y',
		'NEAREST_NEIGHBOR__DELTA_Z' => 'delta_Z',
		'NEAREST_NEIGHBOR__FEATURE_ID' => 'nearestFeature',
		'NEAREST_NEIGHBOR__DISTANCE' => 'nearestDistance'
		);

	$OME->StartAnalysis();
	foreach $dataset (@datasets)
	{
	print "Working on dataset $dataset ...";
		$analysisID = $OME->RegisterAnalysis(
			datasetID    => $dataset,
			programName  => $programName);

		$features = Process_Dataset($dataset);
#		foreach $feature (@$features)
#		{
#			print "ID              : ",$feature->ID,"\n";
#			print "delta_X         : ",$feature->delta_X,"\n";
#			print "delta_Y         : ",$feature->delta_Y,"\n";
#			print "delta_Z         : ",$feature->delta_Z,"\n";
#			print "nearestFeature  : ",$feature->nearestFeature,"\n";
#			print "nearestDistance : ",$feature->nearestDistance,"\n";
#		}
		
		$OME->Add_Feature_Attributes ($analysisID, $features, \%attributes);
		
		$OME->PurgeDataset($dataset);
		$OME->FinishAnalysis();
	print "... Done <BR>\n";
	}

}




sub Process_Dataset {
	my $datasetID = shift;
	my $params = shift;
	my $features = $OME->GetFeatures (DatasetID=>$datasetID,
			location__x           => undef,
			location__y           => undef,
			location__z           => undef,
			timepoint__timepoint  => undef,
			delta_X               => undef,
			delta_Y               => undef,
			delta_Z               => undef,
			nearestFeature        => undef,
			nearestDistance       => undef
			);
	my %timepoints;
	my $timepoint;
	my $featureID;
	my $feature;
	my $featuresT;
	my ($dist_min,$dist_max,$dist_mean,$dist_sigma);


# Convert coordinates to real coordinates
	Convert_Coordinates ($features);

# Sort the features by timepoint
	foreach $feature (@$features)
	{
		$timepoint = $feature->timepoint__timepoint;
		$featureID = $feature->ID;
		push (@{$timepoints{$timepoint}},$feature);
	}

# get nearest neighbors in each timepoint
	foreach $timepoint (keys %timepoints)
	{
		$featuresT = $timepoints{$timepoint};
		foreach $feature (@$featuresT)
		{
			Get_Nearest_Feature ($feature,$featuresT);
		}
	}
	
	return $features;

}







sub Get_Nearest_Feature {
	my $ourFeature = shift;
	my $features = shift;
	my $nearestFeature = undef;
	my $nearestDistance=undef;
	my $distance=$nearestDistance;
	my $feature;
	
	if (! defined ($ourFeature->nearestFeature))
	{
		foreach $feature (@$features)
		{
			if ($ourFeature ne $feature)
			{
				$distance = Get_Feature_Distance ($ourFeature,$feature);
				if (not defined $nearestDistance or $distance < $nearestDistance)
				{
					$nearestDistance = $distance;
					$nearestFeature = $feature;
				}
#print $ourFeature->ID."->".$feature->ID." = $distance (nearest = $nearestDistance)\n";
			}
		}
		$ourFeature->nearestFeature($nearestFeature->ID);
		$ourFeature->nearestDistance($nearestDistance);
		$ourFeature->delta_X ($nearestFeature->location__x - $ourFeature->location__x);
		$ourFeature->delta_Y ($nearestFeature->location__y - $ourFeature->location__y);
		$ourFeature->delta_Z ($nearestFeature->location__z - $ourFeature->location__z);

#print $ourFeature->ID."->".$nearestFeature->ID." = ",$ourFeature->nearestDistance,"\n";
		
	}
	else
	{
		$nearestFeature = $ourFeature->nearestFeature;
		$nearestDistance = $ourFeature->nearestDistance;
	}
	
	return $nearestFeature,$nearestDistance;
}



sub Get_Feature_Distance {
	my $feature1 = shift;
	my $feature2 = shift;
	my $distance;
	my ($deltaX,$deltaY,$deltaZ);

	$deltaX = $feature2->location__x - $feature1->location__x;
	$deltaY = $feature2->location__y - $feature1->location__y;
	$deltaZ = $feature2->location__z - $feature1->location__z;
	$distance = sqrt ( ($deltaX**2) + ($deltaY**2) + ($deltaZ**2) );
	
	return ($distance);
}




sub Convert_Coordinates {

	my $features = shift;
	my $feature;
	my ($size_x,$size_y,$size_z);
	my ($cmd,$result,$conn);
	$conn = $OME->conn;
	my $datasetID = @{$features}[0]->DatasetID;
	my %pixelSize = $OME->GetPixelSizes ($datasetID);

	foreach $feature (@$features)
	{
		$feature->location__x ($feature->location__x*$pixelSize{X});
		$feature->location__y ($feature->location__y*$pixelSize{Y});
		$feature->location__z ($feature->location__z*$pixelSize{Z});
	}
}


