# TrackSpots.pm:  Object wrapper for trackSpots analysis
# Author:  Douglas Creager <dcreager@alum.mit.edu>
# Copyright 2002 Douglas Creager.
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

package OMEAnalysis::TrackSpots;
use strict;
use vars qw($VERSION @ISA);
$VERSION = 2.000_000;

use OMEpl;
use OMEhtml;
use OMEhtml::Form;
use OMEhtml::Section;
use OMEhtml::Control;
use OMEhtml::Control::TextField;
use OMEAnalysis;

@ISA = ("OMEAnalysis");

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new();

    my $var;
    my @newvars = ['params'];
    foreach $var (@newvars) { $self->{$var} = undef; }

    $self->{programName} = "trackSpots2";

    $self->{htmlVars} = ['iWeight'];

    $self->{columnKey} = {
	'trajectory_ID' => ['DELTA','TRAJECTORY_ID'],
	'movedTo'       => ['DELTA','MOVED_TO'],
	'deltaX'        => ['DELTA','DELTA_X'],
	'deltaY'        => ['DELTA','DELTA_Y'],
	'deltaZ'        => ['DELTA','DELTA_Z'],
	'distance'      => ['DELTA','DISTANCE'] 
	};

    $self->{columnKeyRE} = {};

    bless($self,$class);
    return $self;
}

sub StartAnalysis {
    my $self   = shift;
    my $params = shift;
    my $OME    = $self->{OME};
    my $dbh    = $OME->DBIhandle();
    my $CGI    = $OME->cgi();

    $self->SUPER::StartAnalysis($params);
    $self->{params} = $params;
}

sub Execute {
    my $self    = shift;
    my $dataset = shift;
    my $OME     = $self->{OME};

    # don't call inherited execute

    my $datasetID  = $dataset->ID;
    my $analysisID = $OME->RegisterAnalysis(datasetID     => $dataset,
					    programName   => $self->{programName},
					    INTENS_WEIGHT => $self->{params}{iWeight});

    my $features = $self->Track_Features($dataset);
    $OME->WriteFeatures ($analysisID, $features, $self->{columnKey});
    $OME->PurgeDataset($dataset);
    $OME->FinishAnalysis();
}

sub Track_Features {
    my $self = shift;
    my $OME = $self->{OME};
    my $datasetID = shift;
    my $iWeight = $self->{params}{iWeight};
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
    $self->Convert_Coordinates ($features);

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
	    $self->Get_Nearest_Feature ($feature,$timepoints[$i+1],$iWeight);
	}
    }
    
    
    #	print "features is a reference to ".ref($features)."\n";
    #	foreach $feature (@$features) {print $feature->ID."\n";}
    return $features;

}


sub Get_Nearest_Feature {
    my $self = shift;
    my $OME = $self->{OME};
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
	    $distance = $self->Get_Feature_Distance ($ourFeature,$feature,$iWeight);
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
    my $self = shift;
    my $OME = $self->{OME};
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
    my $self = shift;
    my $OME = $self->{OME};
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

sub OutputHTMLForm {
    my $self = shift;
    my $OME  = $self->{OME};
    my $CGI  = $OME->cgi();

    my ($form, $section, $control);
    my $space = "&nbsp;&nbsp;";

    $form = new OMEhtml::Form("TrackSpots parameters");

    #$section = new OMEhtml::Section("Intensity weight");
    $section = new OMEhtml::Section("");
    $form->add($section);

    $control = new OMEhtml::Control::TextField("iWeight",{-size => 4});
    $control->prefix("Intensity weight$space");
    $section->add($control);

    $form->outputHTML($OME,"Run TrackSpots");
}
