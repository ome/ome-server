# OME::Analysis
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

package OME::Analysis;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';


sub StartAnalysis
{
    my $self = shift;
    my $full_url;

    if ($self->inWebServer()) {$full_url = $self->{cgi}->url(-relative=>1);}
    else {$full_url = $ENV{'PWD'}."/".$0;}

    $self->{dbHandle}->do ("UPDATE ome_sessions SET analysis = ? WHERE SESSION_ID = ?",undef,
			   $full_url, $self->{sessionID});
    $self->{SelectedDatasets} = undef;
    #	if (not defined $self->GetSelectedDatasetIDs()) {
    #		$self->SelectDatasets;
    #	}
    #	
    #	$self->GetSelectedDatasetIDs();
    #	die "Attempt to start an analysis without selecting datasets." unless defined $self->{SelectedDatasets};

    $self->Commit();

    $self->TrackProgress();

    #	my %Analysis_Data = (
    #		AnalysisID => undef,
    #		ProgramID => undef,
    #		InputTableName => undef,
    #		ExperimenterID => undef,
    #		DatasetID => undef,
    #		Status => undef
    #		);

}





sub TrackProgress
{
    my $self = shift;
    my $numItems = shift;

    my $session = $self->Session;
    my %analysis;
    $analysis{ProgramPID} = $$;
    $analysis{ProgramStarted} = time;
    $analysis{ProgramName} = $0;
    $analysis{ProgramID} = undef;
    $analysis{Status} = 'Executing';
    $analysis{Message} = '';
    $analysis{Error} = '';
    if (defined $numItems) {
	$analysis{NumSelectedDatasets} = $numItems;
    } else {
	$analysis{NumSelectedDatasets} = $self->NumSelectedDatasets();
    }
    $analysis{NumDatasetsCompleted} = 0;
    $analysis{CurrentAnalysisID} = undef;
    $analysis{CurrentDatasetID} = undef;	
    $analysis{LastCompletedDatasetID} = undef;
    $analysis{LastCompletedDatasetTime} = undef;
    $analysis{AverageTimePerDataset} = undef;
    $analysis{TimeFinished} = undef;
    $session->{Analyses}->{$$} = {%analysis};
    $self->Session ($session);
}



sub IncrementProgress
{
    my $self = shift;

    my $session = $self->Session;
    return unless exists $session->{Analyses};
    return unless exists $session->{Analyses}->{$$};
    my $analysis = $session->{Analyses}->{$$};
    $analysis->{CurrentAnalysisID} = undef;
    $analysis->{LastCompletedDatasetID} = $analysis->{CurrentDatasetID};
    $analysis->{LastCompletedDatasetTime} = time;
    $analysis->{NumDatasetsCompleted}++;
    $analysis->{AverageTimePerDataset} = ($analysis->{LastCompletedDatasetTime} - $analysis->{ProgramStarted}) / $analysis->{NumDatasetsCompleted};

    $analysis->{CurrentDatasetID} = undef;
    if ($analysis->{NumDatasetsCompleted} ge $analysis->{NumSelectedDatasets}) {
	$self->StopProgress();
    }
    $self->Session($session);
}


sub UpdateProgress
{
    my $self = shift;
    my %params = @_;
    my ($key,$value);

    my $session = $self->Session;
    return unless exists $session->{Analyses};
    return unless exists $session->{Analyses}->{$$};
    my $analysis = $session->{Analyses}->{$$};
    while ( ($key,$value) = each %params ) {
	if ($key eq 'Error' and defined $analysis->{Error} and $analysis->{Error}) {
	    $analysis->{$key} .= "\n------------\n$value";
	} else {
	    $analysis->{$key} = $value;
	}
    }
    $self->Session($session);
}


sub StopProgress
{
    my $self = shift;
    my $session = $self->Session;
    return unless exists $session->{Analyses};
    return unless exists $session->{Analyses}->{$$};
    my $analysis = $session->{Analyses}->{$$};

    $analysis->{Status} = 'Finished' if defined $analysis->{Status} and $analysis->{Status} eq 'Executing' ;
    $analysis->{TimeFinished} = time;
    $self->Session($session);
}


sub RegisterAnalysis
{ 
    my $self = shift;
    my %params = @_;
    my $sth;

    #	die "You must call StartAnalysis prior to RegisterAnalysis" unless @SelectedDatasets;

    die "You must register an analysis using a programName or programID." unless
	( $params{'programName'} or $params{'programID'} );

    die "You must supply a datasetID to register an analysis." unless
	$params{'datasetID'};

    # Get the programID if all we have is a programName
    my $programID;
    if ($params{'programName'})
    {
	$sth = $self->{dbHandle}->prepare ("SELECT program_id FROM programs WHERE program_name=?");
	$sth->execute( $params{'programName'} );
	$programID = $sth->fetchrow_array;	
	die "Program '".$params{'programName'}."' is not registered with OME\n" unless defined $programID;
    }
    else {
	$programID = $params{'programID'};
    }

    # Get the analysisID and the datasetID
    my $analysisID = $self->GetOID ('ANALYSIS_SEQ');
    my $datasetID = $params{'datasetID'};

    # Make an entry in the Analyses table.
    $sth = $self->{dbHandle}->do (
				  "INSERT INTO analyses (analysis_ID,experimenter_ID,dataset_ID,program_ID,status) VALUES (?,?,?,?,?)",undef,
				  $analysisID,$self->{ExperimenterID},$datasetID,$programID,'EXECUTING'
				  );

    # Get the name of the input table for this program
    my $inputTableName;
    $sth = $self->{dbHandle}->prepare ("SELECT input_table FROM programs WHERE program_id=?");
    $sth->execute( $programID );
    $inputTableName = $sth->fetchrow_array;
    die "Program ID: $programID not properly registered with OME (INPUT_TABLE not found).\n" unless defined $inputTableName;

    # Delete the datasetID, programID, and programName keys from the params hash
    delete $params{'datasetID'};
    delete $params{'programID'};
    delete $params{'programName'};

    # Add the ANALYSIS_ID key to the params hash.
    $params{'ANALYSIS_ID'} = $analysisID;

    # Now the params hash has all the keys and values to stuff it directly into the program's
    # input table.  This funny business here is to make as many '?' as there are keys in the hash.
    # We go the '?' route so that DBI can do the proper quoting of strings.
    my @questions;
    while ( each %params) {
	push (@questions,"?");
    }

    $sth = $self->{dbHandle}->do (
				  "INSERT INTO $inputTableName (".join (",",keys %params).") VALUES (".join (",",@questions).")",undef,
				  values %params
				  );


    # Return the analysisID
    $self->{CurrentAnalysisID} = $analysisID;

    # Update session info
    $self->UpdateProgress(
			  CurrentAnalysisID => $analysisID,
			  CurrentDatasetID => $datasetID,
			  ProgramID => $programID
			  );	

    return $analysisID;
}


sub WriteFeatures ()
{
    my $self = shift;
    my ($analysisID,$features,$featureDBmap) = @_;
    my ($dataMember,$memberTypeData);
    my ($table,$row,$column);
    my (%tableNames,$tableHash);
    my $feature;
    my $sth;
    my $cmd;

    # Die several different ways
    die "First required parameter (analysis ID) undefined in call to WriteFeatures\n"
	unless defined $analysisID;
    die "Second required parameter (reference to array of features) undefined in call to WriteFeatures\n"
	unless defined $features;
    die "Third required parameter (reference to hash mapping datamembers to DB) undefined in call to WriteFeatures\n"
	unless defined $featureDBmap;
    die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got a scalar.\n"
	unless ref($features);
    die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got ".ref($features)."\n"
	unless ref($features) eq "ARRAY";
    die "The third argument to Add_Feature_Attributes must be a HASH reference. Got a scalar.\n"
	unless ref($featureDBmap);
    die "The second argument to Add_Feature_Attributes must be an HASH reference. Got ".ref($featureDBmap)."\n"
	unless ref($featureDBmap) eq "HASH";

    # Create a flat features table.
    # Do a select from the tables+columns in the $featureDBmap into an empty temporary table - the select should not return any tuples.
    # General case:  $featureDBmap = {DataMember  => ['TABLE','COLUMN', 'TYPE OPTIONS'... ], ...};
    # one to many:  $featureDBmap = {DataMember  => ['TABLE','COLUMN', 'ONE2MANY', 'DISCRIMINATOR COLUMN','DISCRIMINATOR VALUE' ], ...};
    #
    # M
    my @selectExpression = ('FEATURES.FEATURE_ID AS FEATURE_ID','FEATURES.ANALYSIS_ID AS ANALYSIS_ID');
    my @flatColumnNames =  ('FEATURE_ID','ANALYSIS_ID');
    my @questions =        ('?',$analysisID);
    my @featureFields =        ('ID');
    my ($flatColumnName,$selectColumn);
    my ($discColumn,$discValue,%discHash);

    delete $featureDBmap->{ID};
    delete $featureDBmap->{AnalysisID};
    while ( ($dataMember,$memberTypeData) = each (%$featureDBmap) )
    {
	$table = $memberTypeData->[0];
	$column = $memberTypeData->[1];
	if (uc ($table) ne 'FEATURES')
	{
	    #
	    # $tableNames = {TABLE1 => {'flatColumns' => ["Column1","Column2"],
	    #                          'dataMemebers' => [dataMember1,dataMember2],
	    #                          'tableColumns' => [column1,column2],
	    #                          'subTables'    => {$discValue => {'flatColumns' => ["Column1","Column2"],
	    #                                                            'dataMemebers' => [dataMember1,dataMember2],
	    #                                                            'tableColumns' => [column1,column2]
	    #                                                           }
	    #                                         }
	    #                          }
	    #               }
	    if (not exists $tableNames{$table}) {
		$tableNames{$table} = {
		    flatColumns  => ['FEATURE_ID','ANALYSIS_ID'],
		    dataMemebers => ['ID','AnalysisID'],
		    tableColumns => ['ATTRIBUTE_OF','ANALYSIS_ID'],
		};
	    }

	    $tableHash = $tableNames{$table};
	    if (defined $memberTypeData->[2] and $memberTypeData->[2] eq 'ONE2MANY')
	    {
		$discColumn = $memberTypeData->[3];
		$discValue = $memberTypeData->[4];
		if (not exists $tableHash->{subTables}) {$tableHash->{subTables} = {}};

		if (not exists $tableHash->{subTables}->{$discValue}) {
		    $flatColumnName = qq/"$discColumn$discValue"/;
		    $tableHash->{subTables}->{$discValue} = {
			flatColumns  => ['FEATURE_ID','ANALYSIS_ID',$flatColumnName],
			dataMemebers => ['ID','AnalysisID',undef],
			tableColumns => ['ATTRIBUTE_OF','ANALYSIS_ID',$discColumn]
			};

		    push (@flatColumnNames,$flatColumnName);
		    push (@selectExpression,qq/$table.$discColumn AS $flatColumnName/);
		    push (@questions,qq/'$discValue'/);
		}
		$tableHash = $tableHash->{subTables}->{$discValue};
	    }

	    $selectColumn = qq/$table.$column/;
	    $flatColumnName = qq/"$dataMember"/;
	    push (@flatColumnNames,$flatColumnName);
	    push (@selectExpression,qq/$selectColumn AS $flatColumnName/);
	    push (@questions,'?');
	    push (@featureFields,$dataMember);
	    push (@{$tableHash->{flatColumns}},$flatColumnName);
	    push (@{$tableHash->{dataMemebers}},$dataMember);
	    push (@{$tableHash->{tableColumns}},$column);
	}
    }

    # Some notes on a DbMap Object implementation:
    # Method : feature->DBmap->SelectExpressions() - a list with members of the form 'table.column AS flatColumnName'
    # Method : feature->DBmap->TableNames() - a list of UNIQUE table names - i.e. keys from a hash.
    # Method : feature->DBmap->FlatColumnNames() - a list of UNIQUE column names for a flat table.
    #          This and the two lists below share the same column order.
    # Method : feature->DBmap->FlatColumnValuesPre() - a list - either a value or ?.
    #          Values should be in single quotes.  ? are unquoted (nekid).
    #          The two lists above are exactly the same size.  Values specified in this list will be plugged into columns specified above.
    # Method : feature->DBmap->FlatColumnValues(ID) - a list - values corresponding ? in FlatColumnValuesPre().
    #          This list's size is the number of '?' members in the list above.
    #
    # Fields:
    #  One field for every datamember in the Feature object that maps to the database.
    #  
    my @values;
    my $subTableHash;
    $cmd = "SELECT ".join (',',@selectExpression).
	q/ INTO TEMPORARY TABLE foobar WHERE /.
	    join ('.attribute_of=0 AND ',keys %tableNames).
		q/.attribute_of=0 AND features.feature_id = 0/;
    $self->{dbHandle}->do ($cmd);

    $sth = $self->{dbHandle}->prepare("INSERT INTO foobar (".
				      join (',',@flatColumnNames).") VALUES (".join (',',@questions).")");
    foreach $feature (@$features)
    {
	# Make sure that each feature has an ID.
	if (!defined $feature->{ID} ) { $feature->{ID} = $self->GetOID('FEATURE_SEQ'); }

	$feature->{AnalysisID} = $analysisID;
	@values = ();
	foreach $dataMember (@featureFields) {
	    push (@values,$feature->{$dataMember});
	}
	$sth->execute(@values);
    }

    $self->{dbHandle}->do ("INSERT INTO features (feature_id,analysis_id) SELECT feature_id,analysis_id FROM foobar");

    while ( ($table,$tableHash) = each (%tableNames) )
    {
	if (exists $tableHash->{subTables}) {
	    foreach $subTableHash (values %{$tableHash->{subTables}}) {
		$self->{dbHandle}->do (
				       "INSERT INTO $table (".join (',',@{$subTableHash->{tableColumns}}).
				       ") SELECT ".join (',',@{$subTableHash->{flatColumns}})." FROM foobar"
				       );
	    }
	}

	else {
	    $self->{dbHandle}->do (
				   "INSERT INTO $table (".join (',',@{$tableHash->{tableColumns}}).
				   ") SELECT ".join (',',@{$tableHash->{flatColumns}})." FROM foobar"
				   );
	}

    }

    $self->{dbHandle}->do ("DROP TABLE foobar");


}



#
# This method cleans up after an analysis is finished.  Currently what happens is that
# all previous analyses by the current user on the given dataset with the same program are deleted.
# This is done by calling the method PurgeAnalysis.
# FIXME:  The status of PurgeDataset is somewhat in flux, so PurgeDataset should be called manually after an analysis.
sub FinishAnalysis
{
    my $self = shift;

    $self->{dbHandle}->do ("UPDATE analyses SET status='ACTIVE' WHERE analysis_id=".$self->{CurrentAnalysisID});
    #	$self->Commit();
    #	$self->SetDatasetView();

    # Update session info
    $self->IncrementProgress();

    $self->{CurrentAnalysisID} = undef;
}


sub GetLatestAnalysisID
{
    my $self = shift;
    my %params = @_;
    my $analysisID;

    die "Parameter DatasetID must be supplied to GetLatestAnalysisID" unless exists $params{DatasetID} and $params{DatasetID}; 
    if (exists $params{ProgramID} and $params{ProgramID}) {
	$analysisID = $self->DBIhandle->selectrow_array (
							 "SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND program_ID=?",undef,$params{DatasetID},$params{ProgramID});
    }

    elsif (exists $params{ProgramName} and $params{ProgramName}) {
	$analysisID = $self->DBIhandle->selectrow_array (
							 "SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND ".
							 "program_ID=programs.program_ID AND programs.program_name = ?",undef,$params{DatasetID},$params{ProgramName});
    }

    else {
	die "Parameter ProgramName or ProgramID must be supplied to GetLatestAnalysisID";
    }
    return $analysisID;
}

# GetAnalysisIDs
# Returns an array of analysis IDs performed on the given DatasetID by the given ProgramName or ProgramID - latest analysis first.
sub GetAnalysisIDs
{    
    my $self = shift;
    my %params = @_;
    my $sth;
    my $row;
    my @analysisIDs;

    die "Parameter DatasetID must be supplied to GetAnalysisIDs" unless exists $params{DatasetID} and $params{DatasetID}; 
    if (exists $params{ProgramID} and $params{ProgramID}) {
	$sth = $self->DBIhandle->prepare (
					  "SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND program_ID=?".
					  " ORDER BY analysis_ID DESC");
	$sth->execute($params{DatasetID},$params{ProgramID});
	$sth->bind_columns(\$row);
	while ( $sth->fetch ) {
	    push (@analysisIDs,$row);
	}
	undef $sth;
    }

    elsif (exists $params{ProgramName} and $params{ProgramName}) {
	$sth = $self->DBIhandle->prepare (
					  "SELECT analysis_id FROM analyses WHERE dataset_id = ? AND program_ID=programs.program_ID AND programs.program_name = ?".
					  " ORDER BY analysis_ID DESC");
	$sth->execute($params{DatasetID},$params{ProgramName} );
	$sth->bind_columns(\$row);
	while ( $sth->fetch ) {
	    push (@analysisIDs,$row);
	}
	undef $sth;
    }

    else {
	die "Parameter ProgramName or ProgramID must be supplied to GetAnalysisIDs";
    }

    return \@analysisIDs;
}


sub GetDependentsOf ()
{
	my $self = shift;
	my $analysisID = shift;
	my $tuple;
	my @dependents;
	my $sth;
	my $cmd;

	return unless defined $analysisID;
	
# All we want is to select an analysis ID that is greater than the one we're checking, was produced by a different 
# program than the one we're checking, and has features in common with the one we're checking.
# There are two alternative queries here, one of which is commented out.
# Here is an alternative query which requires determining the programID:
	$sth = $self->{dbHandle}->prepare ("SELECT program_id FROM analyses WHERE analysis_id = ?");
	$sth->execute( $analysisID );
	my $programID =  $sth->fetchrow_array;

	$cmd = "SELECT analysis_id FROM analyses a1 WHERE a1.analysis_id > $analysisID AND a1.program_id <> $programID ".
		"AND EXISTS (SELECT f1.feature_id FROM features f1 WHERE f1.analysis_id = a1.analysis_id AND feature_id IN ".
		"(SELECT feature_id FROM features WHERE analysis_id = $analysisID))";
# This is the other alternative, which seems to be potentially slower:
#	$cmd = "SELECT DISTINCT f1.analysis_id FROM features f1, features f2 , analyses a1, analyses a2 WHERE ".
#		"f2.analysis_id = $analysisID AND f2.feature_id = f1.feature_id AND f1.analysis_id > $analysisID ".
#		"AND f1.analysis_id = a1.analysis_id AND a2.analysis_id = f2.analysis_id AND a1.program_id <> a2.program_id";
	$sth = $self->{dbHandle}->prepare ($cmd);
	$sth->execute( );
	while ( $tuple = $sth->fetchrow_array ) { push (@dependents,$tuple); }

#print "AnalysisID: $analysisID, Dependents=(";
#my $dep;
#foreach $dep (@dependents) { print $dep,","; }
#print ")\n";
#
	return \@dependents;
	
}


# Delete all attributes of the analysis, and mark the analysis expired.
sub ExpireAnalysis
{
    my $self = shift;
    my $analysisID = shift;
    my $tuple;
    my @featureTables;
    my $tableName;
    my $sth;

    return unless defined $analysisID;

    # Get the table names of the attributes computed by this analysis.
    $sth = $self->{dbHandle}->prepare ("SELECT table_name FROM attribute_list WHERE list_id = programs.attribute_list_id AND ".
				       "programs.program_id = analyses.program_id AND analyses.analysis_id = ?");
    $sth->execute( $analysisID );
    while ( $tuple = $sth->fetchrow_array ) {push (@featureTables,$tuple) ; }

    # Push the features table into the list of tables as well.
    push (@featureTables,'features');

    # Go through all the attribute tables and delete attributes with matching analysisIDs.
    foreach $tableName (@featureTables)
    {
	$self->{dbHandle}->do ("DELETE FROM $tableName WHERE analysis_id=$analysisID");
    }

    # Mark the analysis EXPIRED in the analyses table.
    $self->{dbHandle}->do ("UPDATE analyses SET status='EXPIRED' WHERE analysis_id=$analysisID");
    $self->UnlinkExpiredFiles();
}





1;
