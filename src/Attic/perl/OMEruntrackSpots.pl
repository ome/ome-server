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

use CGI qw (:html3);
use CGI::Carp qw(fatalsToBrowser);
use Pg;
#use strict;

END
{
$query = undef;
$conn = undef;
}



my $maxTuples=20;
$query = new CGI;
my $OMEloginURL = "http://".$query->server_name()."/perl/OMElogin.pl";
my $OMEselectDatasetsURL = "http://".$query->server_name()."/perl/OMEselectDatasets.pl";
my $cookieLifetime = "30m";
#
my $connInfo = $query->cookie ('connInfo');
my $conn = Pg::connectdb($connInfo);
my $OME_SID = $query->cookie ('OME_sessionID');
my $SIDcookie;
my $RefererCookie;
my $connInfoCookie;


my $k;


if ($conn->status != PGRES_CONNECTION_OK || (!$OME_SID) )
{
   $RefererCookie = $query->cookie (-name=>'referer',-value=>$query->self_url);
   print $query->redirect (-cookie=>$RefererCookie,-location=>$OMEloginURL);
   exit;
}



my $cmd;
my $result;
my $nTuples;
my $full_url;

$full_url      = $query->url();
# Update the default analysis pane.
$cmd = "UPDATE ome_sessions SET analysis = '$full_url' WHERE session_id = $OME_SID";
$result = $conn->exec($cmd);
die $conn->errorMessage unless PGRES_COMMAND_OK eq $result->resultStatus;




$cmd = "SELECT dataset_id FROM ome_sessions_datasets WHERE session_id=".$OME_SID;
$result = $conn->exec($cmd);
die $conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;

if ($result->ntuples < 1)
{
   $RefererCookie = $query->cookie (-name=>'referer',-value=>$query->self_url);
   print $query->redirect (-cookie=>$RefererCookie,-location=>$OMEselectDatasetsURL);
   exit;
}
$connInfoCookie = $query->cookie (-name=>'connInfo',-value=>$connInfo,-expires=>$cookieLifetime);
$SIDcookie = $query->cookie (-name=>'OME_sessionID',-value=>$OME_SID,-expires=>$cookieLifetime);
$RefererCookie = $query->cookie (-name=>'referer',-value=>'');

#
# The user supplies the TIME_START, TIME_STOP (begining to end, or number to end or begining to number)
# The WAVELEGTH.  This is a popup containing the wavelegths in the dataset(s),
# The THRESHOLD.  This is either a number or relative to the mean or to the geometric mean.
# Minimum spot volume - a number
# Intensity weight - default 0.
#

my @timeStartSelect;
$timeStartSelect[0]=$query->th('Time');
$timeStartSelect[1]=$query->th('From:');
push (@timeStartSelect,$query->radio_group(-name=>'startTime',
		-values=>['Begining','timePoint'],-default=>'Begining',-nolabels=>1));
$timeStartSelect[2] = $timeStartSelect[2]."Begining";
$timeStartSelect[3] = $timeStartSelect[3]."Timepoint".$query->textfield(-name=>'Start',-size=>4);
@timeStartSelect = $query->td (\@timeStartSelect);

my @timeStopSelect;
$timeStopSelect[0]=$query->td(' ');
$timeStopSelect[1]=$query->th('To:');
push (@timeStopSelect,$query->radio_group(-name=>'stopTime',
		-values=>['End','timePoint'],-default=>'End',-nolabels=>1));
$timeStopSelect[2] = $timeStopSelect[2]."End";
$timeStopSelect[3] = $timeStopSelect[3]."Timepoint".$query->textfield(-name=>'Stop',-size=>4);
@timeStopSelect = $query->td (\@timeStopSelect);


$cmd = "SELECT DISTINCT wavelength FROM stats_xyz WHERE stats_xyz.dataset_id=ome_sessions_datasets.dataset_id AND ".
	"ome_sessions_datasets.session_id =".$OME_SID;
$result = $conn->exec($cmd);
die $conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
my @wavelengths;
for ($k = 0; $k < $result->ntuples; $k++)
{
	$wavelengths[$k]= $result->fetchrow;
}
my @selectWavelegths;
$selectWavelegths[0] = $query->th ('Wavelength');
$selectWavelegths[1] = $query->td (' ');
$selectWavelegths[2] = $query->popup_menu(-name=>'wavelengths',
                            -values=>\@wavelengths)."nm";
$selectWavelegths[3] = $query->td (' ');
@selectWavelegths = $query->td (\@selectWavelegths);

my @selectThreshold;
$selectThreshold[0] = $query->th ('Threshold');
$selectThreshold[1] = $query->td (' ');
push (@selectThreshold, $query->radio_group(-name=>'threshold',
		-values=>['Absolute','Relative'],-default=>'Relative',-nolabels=>1));
$selectThreshold[2] = $selectThreshold[2]."Absolute :".$query->textfield(-name=>'Absolute',-size=>4);
$selectThreshold[3] = $selectThreshold[3]."Relative to:".$query->popup_menu(-name=>'means',
			-values=>['Mean','Geometric Mean'],default=>'Geometric Mean').
			"+/-".$query->textfield(-name=>'nSigmas',-size=>4).
			" standard deviations.</blockquote>";
@selectThreshold = $query->td (\@selectThreshold);


my @selectMinPix;
$selectMinPix[0] = $query->th ('Min. volume');
$selectMinPix[1] = $query->td (' ');
$selectMinPix[2] = $query->textfield(-name=>'minPix',-size=>4,default=>'4')."pixels.";
$selectMinPix[3] = $query->td (' ');
@selectMinPix = $query->td (\@selectMinPix);


my @selectIntnsWght;
$selectIntnsWght[0] = $query->th ('Intensity Weight');
$selectIntnsWght[1] = $query->td (' ');
$selectIntnsWght[2] =  $query->textfield(-name=>'intnsWght',-size=>4,default=>'0');
$selectIntnsWght[3] = $query->td (' ');
@selectIntnsWght = $query->td (\@selectIntnsWght);


	print $query->header (-cookie=>[$connInfoCookie,$SIDcookie],-type=>'text/html');
	print $query->start_html(-title=>'Run trackSpots');
	print $query->h2("Enter parameters for trackSpots");
	print $query->startform;
	print $query->table({-border=>1,-cellspacing=>0,-cellpadding=>0},
		$query->Tr(\@timeStartSelect),
		$query->Tr(\@timeStopSelect),
		$query->Tr(\@selectThreshold),
		$query->Tr(\@selectWavelegths),
		$query->Tr(\@selectMinPix),
		$query->Tr(\@selectIntnsWght)
		);


	print "<CENTER>", $query->submit(-name=>'Execute',-value=>'Run trackSpots'), "</CENTER>",
	$query->endform;
if ($query->param('Execute'))
{
my @datasetPaths;
my @datasetNames;
my @datasetIDs;
my $datasetID;
my $datasetPath;
my $programPath;
my $programName="trackSpots";
my $tStart;
my $tStop;
my @parameters;
my $cmd;
# Get the path to the program

	$cmd = "SELECT path,program_name FROM programs WHERE program_name='".$programName."'";
	$result = $conn->exec($cmd);
	die $conn->errorMessage unless $result->resultStatus eq PGRES_TUPLES_OK;
	$programPath = join ("",$result->fetchrow);
	die "Program $programPath does not exist.\n" unless (-e $programPath);
	die "User '".getpwuid ($<)."' does not have permission to execute $programPath\n" unless (-x $programPath);

# Get a list of selected dataset paths.
	$cmd = "SELECT dataset_id,path,name FROM datasets WHERE datasets.dataset_id=ome_sessions_datasets.dataset_id ".
		"AND ome_sessions_datasets.session_id=".$OME_SID;
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
	push (@parameters,$query->param('wavelengths'));

	if ($query->param('threshold') eq 'Absolute')
	{
		push (@parameters,sprintf ("%d",$query->param('Absolute')) );
	}
	else
	{
	my $nSigmas = sprintf ("%.2f",$query->param('nSigmas'));
		if ($query->param('means') eq 'Mean')
		{
			push (@parameters,"mean".$nSigmas."s");
		}
		else
		{
			push (@parameters,"gmean".$nSigmas."s");
		}
	}

	push (@parameters,sprintf ("%d",$query->param('minPix')));
	if ($query->param('startTime') eq 'Begining')
	{
		$tStart=0;
	}
	else
	{
		$tStart = sprintf ("%d",$query->param('Start'));
	}
	if ($query->param('stopTime') eq 'End')
	{
		$tStop=0;
	}
	else
	{
		$tStop = sprintf ("%d",$query->param('Stop'));
	}
	
	if ($tStart || $tStop)
	{
		push (@parameters,"-time".$tStart."-".$tStop);
	}

	if ($query->param('intnsWght'))
	{
		push (@parameters,"-iwght".sprintf ("%.3f",$query->param('intnsWght')));
	}

# add the connection string as a parameter.
	push (@parameters,"-OMEdbConn='".$connInfo."'");
# Loop through the selected datasets
	$k=0;
	foreach $datasetPath (@datasetPaths)
	{
# Get the last analysis that had identical parameters.
#		$datasetID = $datasetIDs[$k};
#		$cmd = "SELECT analysis_id FROM input_trackspots WHERE ".
#				"time_start=$parameters[0] AND ".
#				"time_stop=$parameters[0] AND ".
#				"wavelength=$parameters[0] AND ".
#				"threshold='$parameters[0]' AND ".
#				"min_spot_vol=$parameters[0] AND ".
#				"intens_weight=$parameters[0] AND ".
#				"analysis_id=analyses.analysis_id AND analyses.dataset_id=$datasetID ".
#				"order by analyses.timestamp desc limit 1";
		$cmd = $programPath." ".$datasetPath." ".join (" ",@parameters).
			" 2> /tmp/system.stderr 1> /tmp/system.stdout";
#		print $cmd,"<br>";
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

	print $query->end_html;


