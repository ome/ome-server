# OME::Image
# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
# Created from OMEpl (v1.20) package split.
#
# OMEpl credits
# -----------------------------------------------------------------------------
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
# -----------------------------------------------------------------------------
# 
#

package OME::Image;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';


sub GetSelectedDatasetIDs
{
    my $self = shift;
    my $row;
    my $sth;
    my @selectedDatasets;
    my $selectedDatasetsRef=undef;

    $sth = $self->{dbHandle}->prepare ("SELECT dataset_id FROM ome_sessions_datasets WHERE SESSION_ID=?");
    $sth->execute( $self->{sessionID} );
    $sth->bind_columns(\$row);
    while ( $sth->fetch ) {
	push (@selectedDatasets,$row);
    }
    undef $sth;
    undef $row;

    $selectedDatasetsRef = \@selectedDatasets if ($selectedDatasets[0]);

    $self->{SelectedDatasets} = $selectedDatasetsRef;
    return $selectedDatasetsRef;
}

#
# GetSelectedDatasets
# FIXME:  This method should return objects.  GetSelectedDatasetIDs should return IDs
sub GetSelectedDatasets
{
    my $self = shift;

    return $self->GetSelectedDatasetIDs();
}


sub GetSelectedDatasetObjects
{
    my $self = shift;

    return $self->GetDatasetObjects ($self->GetSelectedDatasetIDs());
}



sub GetSelectedDatasetsWavelengths
{
    #	select distinct wave from attributes_iccb_tiff where dataset_id = ome_sessions_datasets.dataset_id
    my $self = shift;
    my $row;
    my $sth;
    my @wavelengths;

    #$sth = $self->{dbHandle}->prepare (
    #	"SELECT DISTINCT attributes_iccb_tiff.wave ".
    #		"FROM attributes_iccb_tiff,ome_sessions_datasets ".
    #		"WHERE attributes_iccb_tiff.dataset_id = ome_sessions_datasets.dataset_id ".
    #		"AND ome_sessions_datasets.SESSION_ID=".$self->{sessionID});
    #$sth->execute();
    #$sth->bind_columns(\$row);
    #while ( $sth->fetch ) {
    #	push (@wavelengths,$row);
    ##}


    $sth = $self->{dbHandle}->prepare (
				       "SELECT DISTINCT dataset_wavelengths.em_wavelength ".
				       "FROM dataset_wavelengths,ome_sessions_datasets ".
				       "WHERE dataset_wavelengths.dataset_id = ome_sessions_datasets.dataset_id ".
				       "AND ome_sessions_datasets.SESSION_ID=".$self->{sessionID});
    $sth->execute();
    $sth->bind_columns(\$row);
    while ( $sth->fetch ) {
	push (@wavelengths,$row);
    }

    undef $sth;

    return \@wavelengths;
}


sub GetDatasetObjects
{
    my $self = shift;
    my $selectedDatasetIDs = shift;
    my @datasets;
    my $datasetID;

    die "Attempt to call GetDatasetObjects without the required reference to an array of dataset IDs.\n"
	unless defined $selectedDatasetIDs;
    foreach $datasetID (@$selectedDatasetIDs) {
	push (@datasets,$self->NewDataset (ID => $datasetID));
    }

    return \@datasets;

}


sub SelectDatasets
{
    my $self = shift;
    if ($self->gotBrowser())
    {
	$self->SetReferer();
	$self->Redirect (-location=>$self->{OMEselectDatasetsURL});
    }
}


sub SetSelectedDatasets()
{
    my $self = shift;
    my $datasets = shift;
    my $datasetID;
    my $SID = $self->{sessionID};
    return unless defined $datasets and $datasets and scalar @$datasets > 0;
    # Delete the previously selected datasets
    $self->{dbHandle}->do ("DELETE FROM ome_sessions_datasets WHERE session_id = $SID");
    $self->{SelectedDatasets} = undef;

    my $sliceStart = 0;
    my $maxDSidx = scalar (@$datasets)-1;
    my $sliceStop = $maxDSidx;
    if ($sliceStop > $SQLLISTLIMIT) {$sliceStop = $SQLLISTLIMIT - 1;}
    while ($sliceStop <= $maxDSidx) {
	my @datasetSlice = @$datasets[$sliceStart .. $sliceStop];
	# Only copy unique datasets that exist in the datasets table.
	$self->DBIhandle->do(
			     "INSERT INTO ome_sessions_datasets (session_id,dataset_id) ".
			     "SELECT DISTINCT $SID,datasets.dataset_id WHERE datasets.dataset_id IN (".join (',',@datasetSlice).')');
	$sliceStart = $sliceStop + 1;
	$sliceStop += $SQLLISTLIMIT;
	$sliceStop = $maxDSidx if ($sliceStop > $maxDSidx);
	$sliceStop = $maxDSidx + 1 if ($sliceStart > $maxDSidx);
	push (@{$self->{SelectedDatasets}},@datasetSlice);
    }

    #	$self->Commit();
    $self->SetSessionProjectID();
    $self->RefreshSessionInfo();

    return $self->{SelectedDatasets};
}


sub PurgeDataset ()
{
    my $self = shift;
    my $datasetID = shift;
    my ($analysisID,$programID);
    my $analysisIDs;
    my @programIDs;
    my %latestAnalyses;
    my %allAnalyses;
    my $sth;

    return unless defined $datasetID;

    # Get the programIDs that were used to analyze this dataset.  Make a hash of lists where the keys are the programIDs
    # and the list items are the corresponding analysisIDs.
    $sth = $self->{dbHandle}->prepare ("SELECT analysis_id, program_id FROM analyses WHERE dataset_id = ? AND experimenter_id = ? AND ".
				       "(status <> 'EXPIRED' OR status = NULL)");
    $sth->execute( $datasetID,$self->{ExperimenterID} );
    while ( ($analysisID,$programID) = $sth->fetchrow_array)
    {
	push (@{$allAnalyses{$programID}},$analysisID);
    }

    # For each programID, get the latest analysisID, and put it in the latestAnalyses hash.
    while ( ($programID,$analysisIDs) = each (%allAnalyses) )
    {
	$latestAnalyses{$programID} = undef;
	foreach $analysisID (@$analysisIDs)
	{
	    $latestAnalyses{$programID} = $analysisID unless defined ($latestAnalyses{$programID});
	    if ($analysisID > $latestAnalyses{$programID})
	    {
		$latestAnalyses{$programID} = $analysisID;
	    }
	}
    }

    # Now we go through every analysis done on this dataset and check if it matches our latestAnalyses hash.
    # For each analysis, we also check if any of its dependants are in the latestAnalyses hash.

LOOP:
    # For each programID, get the latest analysisID, and put it in the latestAnalyses hash.
    while ( ($programID,$analysisIDs) = each (%allAnalyses) )
    {
	foreach $analysisID (@$analysisIDs)
	{
	    if ($analysisID != $latestAnalyses{$programID})
	    {
		my $dependents = $self->GetDependentsOf ($analysisID);
		my $dependent;
		foreach $dependent (@$dependents)
		{
		    if ($dependent = $latestAnalyses{$programID}) { next LOOP; }
		}
		$self->ExpireAnalysis ($analysisID);
	    }
	}
    }

}


1;
