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

use strict;
use OMEpl;
use Pg;
use vars qw ($OME);



$OME = new OMEpl;

$OME->StartAnalysis();



print_form ();
execute () if ($OME->cgi->param('Execute'));

print $OME->cgi->end_html;



END
{
	$OME = undef;
}



sub print_form {

#
# The user supplies minimum distance between points,point size,optional threshold,
# two points (x1,y1 and x2,y2) for a bounding box, the total number of points
# to look for, and wether or not to look in adjacent Z sections.
#
my @tableRows;
my @tableColumns;
my $cmd;
my $result;
my $conn = $OME->conn;
my ($maxX,$maxY);

	$tableColumns[0]=$OME->cgi->th("# of spots");
	$tableColumns[1]=$OME->cgi->textfield(-name=>'nSpots',-size=>2,-default=>3);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0]=$OME->cgi->th("Min. distance");
	$tableColumns[1]=$OME->cgi->textfield(-name=>'minDist',-size=>2,-default=>4);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0]=$OME->cgi->th("Size");
	$tableColumns[1]=$OME->cgi->textfield(-name=>'size',-size=>2,-default=>4);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0]=$OME->cgi->th("Threshold");
	$tableColumns[1]=$OME->cgi->textfield(-name=>'threshold',-size=>2,-default=>0);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$cmd = "SELECT min(size_x),min(size_y) FROM attributes_dataset_xyzwt WHERE dataset_id=ome_sessions_datasets.dataset_id ".
		"AND ome_sessions_datasets.SESSION_ID=".$OME->SID;
	$result = $conn->exec($cmd);
	die $conn->errorMessage unless $result->resultStatus eq PGRES_TUPLES_OK;
	if ($result->ntuples == 1)
	{
		$maxX = $result->getvalue (0,0) - 5;
		$maxY = $result->getvalue (0,1) - 5;
	}
	$tableColumns[0]=$OME->cgi->th("Search limits");
	$tableColumns[1]="From (x,y)".$OME->cgi->textfield(-name=>'X1',-size=>3,-default=>5).
			",".$OME->cgi->textfield(-name=>'Y1',-size=>3,-default=>5).
			"To (x,y)".$OME->cgi->textfield(-name=>'X2',-size=>3,-default=>$maxX).
			",".$OME->cgi->textfield(-name=>'Y2',-size=>3,-default=>$maxY);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0]=$OME->cgi->th("Use adjacent Z sections?");
	$tableColumns[1]=$OME->cgi->radio_group(-name=>'adjZ',
			-values=>['Yes','No'],-default=>'Yes',-nolabels=>0);
	@tableColumns = $OME->cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);


	print $OME->CGIheader (-type=>'text/html');
	print $OME->cgi->start_html(-title=>'Run spawnSpots');

#	print "Number of datasets selected :".$OME->NumSelectedDatasets()."\nIDs:";
#	print join (" ",$OME->GetSelectedDatasets)."\n";

	print $OME->cgi->h2("Enter parameters for spawnSpots");
	print $OME->cgi->startform;
	print $OME->cgi->table({-border=>1,-cellspacing=>2,-cellpadding=>2},
		$OME->cgi->Tr(\@tableRows)
		);
	print "<CENTER>", $OME->cgi->submit(-name=>'Execute',-value=>'Run spawnSpots'), "</CENTER>";
	print $OME->cgi->endform;
}




sub execute {
my @datasetPaths;
my @datasetNames;
my @datasetIDs;
my $datasetID;
my $datasetPath;
my $programPath;
my $programName="spawnSpots";
my $tStart;
my $tStop;
my @parameters;
my $cmd;
my $conn = $OME->conn;
my $result;
my $k;
my $programStatus;
my $shortStatus;

# Get the path to the program

	$cmd = "SELECT path,program_name FROM programs WHERE program_name='".$programName."'";
	$result = $conn->exec($cmd);
	die "error executing '$cmd':\n".$conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
	$programPath = join ("",$result->fetchrow);
	die "Program $programPath does not exist.\n" unless (-e $programPath);
	die "User '".getpwuid ($<)."' does not have permission to execute $programPath\n" unless (-x $programPath);

# Get a list of selected dataset paths.
	$cmd = "SELECT dataset_id,path,name FROM datasets WHERE datasets.dataset_id=ome_sessions_datasets.dataset_id ".
		"AND ome_sessions_datasets.SESSION_ID=".$OME->SID;
	$result = $conn->exec($cmd);
	die "error executing '$cmd':\n".$conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
	for ($k = 0; $k < $result->ntuples; $k++)
	{
		$datasetIDs[$k] = $result->getvalue($k,0);
		$datasetPaths[$k] = $result->getvalue($k,1).$result->getvalue($k,2);
		$datasetNames[$k] = $result->getvalue($k,2);
	}

# make up a parameter string based on user entries.
# The order of required parameters (other than dataset name) is:
# arg[2] = minDist
# arg[3] = size
# arg[4] = threshold
# arg[5] = X1
# arg[6] = Y1
# arg[7] = X2
# arg[8] = Y2
# arg[9] = nSpots
# arg[10] = adjZ (0=false, any other number is true, anything else is false)
# arg[11] = database connection string - passed to PQconnectdb as defined in libpq.h.

	push (@parameters,sprintf ("%d",$OME->cgi->param('minDist')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('size')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('threshold')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('X1')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('Y1')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('X2')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('Y2')) );
	push (@parameters,sprintf ("%d",$OME->cgi->param('nSpots')) );
	if ($OME->cgi->param('adjZ') eq 'Yes')
	{
		push (@parameters,"true" );
	}
	else
	{
		push (@parameters,"false" );
	}

# add the connection string as a parameter.
	push (@parameters,"'".$OME->connInfo."'");

# Loop through the selected datasets
	$k=0;
	foreach $datasetPath (@datasetPaths)
	{
		$cmd = $programPath." ".$datasetPath." ".join (" ",@parameters).
			" 2> /tmp/system.stderr 1> /tmp/system.stdout";

		$programStatus = system ($cmd);
		$shortStatus = sprintf "%hd",$programStatus;
		$shortStatus = $shortStatus/256;
		$programStatus = $programStatus/256;
		if ($shortStatus < 1)
		{
			print "<H2>Errors durring execution:</H2>";
			print "<PRE>",`cat /tmp/system.stderr`,"</PRE>";
		}
		else
		{
			$cmd = "SELECT count(*) FROM features WHERE analysis_id=$programStatus";
			$result = $conn->exec($cmd);
			die $conn->errorMessage unless $result->resultStatus eq PGRES_TUPLES_OK;
			print "<H4>$datasetNames[$k]: ".$result->fetchrow." features found.</H4>";
		}
	$k++;
	}	

}

