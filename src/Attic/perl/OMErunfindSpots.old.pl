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

use vars qw ($OME $programName);

$programName="findSpots";

$OME = new OMEpl;

$OME->StartAnalysis();



print_form ();
Execute () if ($OME->cgi->param('Execute'));

print $OME->cgi->end_html;

$OME = undef;




sub print_form()
{
my $conn = $OME->conn();
my $CGI = $OME->cgi();
my ($cmd,$result);
my $nTuples;
my $full_url;
my @tableRows;
my @tableColumns;
my $k;





#
# The user supplies the TIME_START, TIME_STOP (begining to end, or number to end or begining to number)
# The WAVELEGTH.  This is a popup containing the wavelegths in the dataset(s),
# The THRESHOLD.  This is either a number or relative to the mean or to the geometric mean.
# Minimum spot volume - a number
# Intensity weight - default 0.
#
	$tableColumns[0]=$CGI->th('Time');
	$tableColumns[1]=$CGI->th('From:');
	push (@tableColumns,$CGI->radio_group(-name=>'startTime',
			-values=>['Begining','timePoint'],-default=>'Begining',-nolabels=>1));
	$tableColumns[2] = $tableColumns[2]."Begining";
	$tableColumns[3] = $tableColumns[3]."Timepoint".$CGI->textfield(-name=>'Start',-size=>4);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0]=$CGI->td(' ');
	$tableColumns[1]=$CGI->th('To:');
	push (@tableColumns,$CGI->radio_group(-name=>'stopTime',
			-values=>['End','timePoint'],-default=>'End',-nolabels=>1));
	$tableColumns[2] = $tableColumns[2]."End";
	$tableColumns[3] = $tableColumns[3]."Timepoint".$CGI->textfield(-name=>'Stop',-size=>4);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);


	$cmd = "SELECT DISTINCT wavelength FROM stats_xyz WHERE stats_xyz.dataset_id=ome_sessions_datasets.dataset_id AND ".
		"ome_sessions_datasets.session_id =".$OME->SID;
	$result = $conn->exec($cmd);
	die $conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
	my @wavelengths;
	for ($k = 0; $k < $result->ntuples; $k++)
	{
		$wavelengths[$k]= $result->fetchrow;
	}
	$tableColumns[0] = $CGI->th ('Wavelength');
	$tableColumns[1] = $CGI->td (' ');
	$tableColumns[2] = $CGI->popup_menu(-name=>'wavelengths',
                            	-values=>\@wavelengths)."nm";
	$tableColumns[3] = $CGI->td (' ');
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);

	$tableColumns[0] = $CGI->th ('Threshold');
	$tableColumns[1] = $CGI->td (' ');
	push (@tableColumns, $CGI->radio_group(-name=>'threshold',
			-values=>['Absolute','Relative'],-default=>'Relative',-nolabels=>1));
	$tableColumns[2] = $tableColumns[2]."Absolute :".$CGI->textfield(-name=>'Absolute',-size=>4);
	$tableColumns[3] = $tableColumns[3]."Relative to:".$CGI->popup_menu(-name=>'means',
				-values=>['Mean','Geometric Mean'],default=>'Geometric Mean').
				"+/-".$CGI->textfield(-name=>'nSigmas',-size=>4).
				" standard deviations.</blockquote>";
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);


	$tableColumns[0] = $CGI->th ('Min. volume');
	$tableColumns[1] = $CGI->td (' ');
	$tableColumns[2] = $CGI->textfield(-name=>'minPix',-size=>4,default=>'4')."pixels.";
	$tableColumns[3] = $CGI->td (' ');
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);



	print $OME->CGIheader (-type=>'text/html');
	print $CGI->start_html(-title=>'Run findSpots');
	print $CGI->h2("Enter parameters for findSpots");
	print $CGI->startform;

	print $CGI->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
		$CGI->Tr(\@tableRows)
		);
		
	print "<CENTER>", $CGI->submit(-name=>'Execute',-value=>'Run findSpots'), "</CENTER>";
	print $CGI->endform;
}



sub Execute ()
{
my $CGI = $OME->cgi();
my ($cmd,$result);
my $conn = $OME->conn();
my @datasetPaths;
my @datasetNames;
my @datasetIDs;
my $datasetID;
my $datasetPath;
my $programPath;
my $tStart;
my $tStop;
my @parameters;
my $outputOptions = "";
my $k;
my ($programStatus,$shortStatus);

# Get the path to the program
	$cmd = "SELECT path,program_name FROM programs WHERE program_name='".$programName."'";
	$result = $conn->exec($cmd);
	die $conn->errorMessage unless $result->resultStatus eq PGRES_TUPLES_OK;
	$programPath = join ("",$result->fetchrow);
	die "Program $programPath does not exist.\n" unless (-e $programPath);
	die "User '".getpwuid ($<)."' does not have permission to execute $programPath\n" unless (-x $programPath);

# Get a list of selected dataset paths.
	$cmd = "SELECT dataset_id,path,name FROM datasets WHERE datasets.dataset_id=ome_sessions_datasets.dataset_id ".
		"AND ome_sessions_datasets.session_id=".$OME->SID;
	$result = $conn->exec($cmd);
	die $conn->errorMessage unless $result->resultStatus eq PGRES_TUPLES_OK;
	for ($k = 0; $k < $result->ntuples; $k++)
	{
		$datasetIDs[$k] = $result->getvalue($k,0);
		$datasetPaths[$k] = $result->getvalue($k,1).$result->getvalue($k,2);
		$datasetNames[$k] = $result->getvalue($k,2);
	}

# make up a parameter string based on user entries.
# The order of required parameters (other than dataset name) is:
# <wavelength> <threshold> <min. spot vol.> [<-time#n-#n>] [<-iwght#n>]


# Wavelength is safe as a single number because it is not user editable.
# All user-editable text fields get sent through sprintf before being put into @parameters.
	push (@parameters,$CGI->param('wavelengths'));

	if ($CGI->param('threshold') eq 'Absolute')
	{
		push (@parameters,sprintf ("%d",$CGI->param('Absolute')) );
	}
	else
	{
	my $nSigmas = sprintf ("%.2f",$CGI->param('nSigmas'));
		if ($CGI->param('means') eq 'Mean')
		{
			push (@parameters,"mean".$nSigmas."s");
		}
		else
		{
			push (@parameters,"gmean".$nSigmas."s");
		}
	}

	push (@parameters,sprintf ("%d",$CGI->param('minPix')));
	if ($CGI->param('startTime') eq 'Begining')
	{
		$tStart=0;
	}
	else
	{
		$tStart = sprintf ("%d",$CGI->param('Start'));
	}
	if ($CGI->param('stopTime') eq 'End')
	{
		$tStop=0;
	}
	else
	{
		$tStop = sprintf ("%d",$CGI->param('Stop'));
	}

	if ($tStart || $tStop)
	{
		push (@parameters,"-time".$tStart."-".$tStop);
	}

# add the connection string as a parameter.
	push (@parameters,"-OMEdbConn='".$OME->connInfo."'");
# Loop through the selected datasets
	$k=0;
	foreach $datasetPath (@datasetPaths)
	{
		$cmd = $programPath." ".$datasetPath." ".join (" ",@parameters).
			" 2> /tmp/$programName.stderr 1> /tmp/$programName.stdout";

		$programStatus = system ($cmd);
		$shortStatus = sprintf "%hd",$programStatus;
		print "short Status: $shortStatus, ";
		$shortStatus = $shortStatus/256;
		print "/256: $shortStatus, staright up: $programStatus, ";
		$programStatus = $programStatus/256;
		print "/256: $programStatus<br>";
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

