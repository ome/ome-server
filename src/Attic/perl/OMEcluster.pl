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



print_form ();
execute () if ($OME->cgi->param('Execute'));

print $OME->cgi->end_html;




sub print_form {

#
# The user specifies wether a distance cutoff or a sigma cutoff is to be used
# Page layout is two radio buttons and two text fields.  Not really necessary to put them in
# a table.
#

my $cmd;
my $result;
my $conn = $OME->conn;
my $cgi = $OME->cgi;
my @cutoffSelect;


	push (@cutoffSelect, $cgi->radio_group(-name=>'cutoff',
			-values=>['Distance','Sigmas'],-default=>'Sigmas',-nolabels=>1));
	$cutoffSelect[0] = $cutoffSelect[0]."Absolute distance of ".
		$cgi->textfield(-name=>'distCutoff',-size=>3)."um<BR>";
	$cutoffSelect[1] = $cutoffSelect[1].$cgi->textfield(-name=>'sigmaCutoff',-size=>3,-default=>2.0).
		"Sigmas over mean pair-wise distance.";


	print $OME->cgi->header (-cookie=>[$OME->connInfoCookie,$OME->SIDcookie],-type=>'text/html');
	print $OME->cgi->start_html(-title=>'Run spawnSpots');

	print $OME->cgi->h2("Select a distance cut-off method for clustering:");
	print $OME->cgi->startform;
	print "@cutoffSelect";
		
	print "<CENTER>", $OME->cgi->submit(-name=>'Execute',-value=>'Run cluster'), "</CENTER>";
	print $OME->cgi->endform;
}




sub execute {
my $distCutoff=undef;
my $sigmaCutoff=undef;

	if ($OME->cgi->param('cutoff') eq 'Sigmas')
	{
		$sigmaCutoff = $OME->cgi->param('sigmaCutoff');
	}
	elsif ($OME->cgi->param('cutoff') eq 'Distance')
	{
		$distCutoff = $OME->cgi->param('distCutoff');
	}

	Do_Analysis( distCutoff => $distCutoff, sigmaCutoff => $sigmaCutoff);

	$OME->Finish();
}



sub Do_Analysis {
	
	my @datasets = $OME->GetSelectedDatasets();
	my $dataset;
	my %params = @_;
	my $analysisID;
	my $programName = "findSpindles";
	my $features;
	my %attributes = (
		'CLUSTER_F__CLUSTER_ID' => 'cluster_ID'
		);

	$OME->StartAnalysis();
	foreach $dataset (@datasets)
	{
		$distCutoff = $params{distCutoff};
		$sigmaCutoff = $params{sigmaCutoff};
		$distCutoff = "NULL" unless defined $distCutoff;
		$sigmaCutoff = "NULL" unless defined $sigmaCutoff;
		$analysisID = $OME->RegisterAnalysis(
			datasetID    => $dataset,
			programName  => $programName,
			DIST_CUTOFF  => $distCutoff,
			SIGMA_CUTOFF => $sigmaCutoff);

		$distCutoff = $params{distCutoff};
		$sigmaCutoff = $params{sigmaCutoff};

		$features = Cluster_Dataset($dataset);
		
		$OME->Add_Feature_Attributes ($analysisID, $features, \%attributes);
		
		$OME->PurgeDataset($dataset);
#print "Purged dataset \n";
		$OME->FinishAnalysis();
#print "Finished analysis\n";
	}

}




sub Cluster_Dataset {
	my $datasetID = shift;
	my $params = shift;
	my $features = $OME->GetFeatures (DatasetID=>$datasetID,
			location__x           => undef,
			location__y           => undef,
			location__z           => undef,
			timepoint__timepoint  => undef,
			cluster_ID            => undef,
			nearestFeature        => undef,
			nearestDistance       => undef
			);
	my %timepoints;
	my $timepoint;
	my $featureID;
	my $feature;
	my @featureList;
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

# Cluster the features in each timepoint
	foreach $timepoint (keys %timepoints)
	{
#	print "timepoint $timepoint\n";
		($dist_min,$dist_max,$dist_mean,$dist_sigma) = Set_Nearest_Neighbors ($timepoints{$timepoint});
		$distCutoff = $dist_mean + ($sigmaCutoff * $dist_sigma) unless defined $distCutoff;
		Cluster_Features($timepoints{$timepoint});
	}
	
#	print "features is a reference to ".ref($features)."\n";
#	foreach $feature (@$features) {print $feature->ID."\n";}
	return $features;

}



sub Cluster_Features {
	my $features = shift;
	my $feature;
	my %clusters;
	my $nearestDistance;
	my $clusterID;

	foreach $feature (@$features)
	{
		if (! defined $feature->cluster_ID )
		{
			$feature->cluster_ID ($OME->GetOID('CLUSTER_ID_SEQ'));
		}

#print "Top level: Clustering feature ".$feature->ID."\n";
		Cluster_Feature ($feature, $features);
		
		push (@{$clusters{$feature->cluster_ID}}, $feature);
# 		print $feature->ID.":(".$feature->location__x.",".$feature->location__y.",".$feature->location__z.")";
#		print "\n";
	}

# Print the clusters
#	print "Clusters :\n";
#	foreach $clusterID (keys %clusters)
#	{
#		print "Cluster $clusterID: ";
#		foreach $feature ( @{$clusters{$clusterID}} )
#			{
#			print "  ".$feature->ID;
#			}
#		print "\n";
#	}

# Try to merge the stragglers
	foreach $clusterID (keys %clusters)
	{

# If a cluster has one feature, merge it with the nearest cluster
		if ($#{$clusters{$clusterID}} eq 0)
		{
			($feature,$nearestDistance) = Get_Nearest_Feature ($clusters{$clusterID}[0],$features);
			if ( $nearestDistance < $distCutoff) 
			{
#print "merging cluster $clusterID\n";
				$clusters{$clusterID}[0]->cluster_ID ($feature->cluster_ID);
				push (@{$clusters{$feature->cluster_ID}}, $clusters{$clusterID}[0]);
				delete $clusters{$clusterID};
			}
		}
	}


}

# Find the nearest feature.
# If the nearest feature is not part of a cluster, then make it part of our feature's cluster, and recurse.
# if the nearest feature is already part of a cluster, then return;
sub Cluster_Feature {
	my $ourFeature = shift;
	my $features = shift;
	

#print "Recursive clustering of feature ".$ourFeature->ID."\n";
	my ($nearestFeature,$nearestDistance) = Get_Nearest_Feature ($ourFeature, $features);
	if ( defined ($nearestFeature->cluster_ID) ) { return; }
	if ( $nearestDistance >= $distCutoff ) {return; }
	$nearestFeature->cluster_ID ($ourFeature->cluster_ID);
	Cluster_Feature ($nearestFeature, $features);
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
		$ourFeature->nearestFeature($nearestFeature);
		$ourFeature->nearestDistance($nearestDistance);
		
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
	my ($x1,$x2,$y1,$y2,$z1,$z2);

	$distance = sqrt
		(
			( ($feature2->location__x - $feature1->location__x)**2 ) +
			( ($feature2->location__y - $feature1->location__y)**2 ) +
			( ($feature2->location__z - $feature1->location__z)**2 )
		);
	
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


sub Set_Nearest_Neighbors {
	my $dist_min=undef;
	my $dist_max=undef;
	my $dist_sum=0;
	my $dist_sum2=0;
	my $dist_count=0;
	my $dist_mean=0;
	my $dist_sigma=undef;
	my $dist=undef;
	my $features = shift;
	my ($feature,$nearest);

	foreach $feature (@$features)
	{
		($nearest,$dist) = Get_Nearest_Feature ($feature,$features);
	 	$dist_min = $dist unless defined $dist_min;
	 	$dist_max = $dist unless defined $dist_max;
		$dist_min = $dist if $dist < $dist_min;
		$dist_max = $dist if $dist > $dist_max;
	 	$dist_sum += $dist;
		$dist_sum2 += ($dist**2);
		$dist_count++;
	}
	
	$dist_sigma = abs ( sqrt ( ($dist_sum2 - ($dist_sum**2) / $dist_count) / ($dist_count - 1.0) ) );
	$dist_mean = $dist_sum / $dist_count;
	return ($dist_min,$dist_max,$dist_mean,$dist_sigma);
}




