# FindSpots.pm:  Object wrapper for findSpots analysis
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

package OMEAnalysis::FindSpots;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.20';

use OMEpl;
use OMEAnalysis;

@ISA = ("OMEAnalysis");

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new();

    my $var;
    my @newvars = ['programPath', 'tStart', 'tStop',
		   'threshold', 'wavelength', 'minSpotVol',
		   'parameters', 'outputOptions'];
    foreach $var (@newvars) {
	$self->{$var} = undef;
    }

    $self->{programName} = "findSpots";

    $self->{htmlVars} = ['wavelengths','threshold','nSigmas','Absolute',
			 'means','autoThresh','minPix',
			 'startTime','stopTime','Start','Stop'];

    $self->{outputOptions} = " -db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v -sa -per -ff";

    $self->{columnKey} = {
	't'           => ['TIMEPOINT', 'TIMEPOINT'],
	'Thresh.'     => ['THRESHOLD', 'THRESHOLD'],
	'mean X'      => ['LOCATION',  'X'],
	'mean Y'      => ['LOCATION',  'Y'],
	'mean Z'      => ['LOCATION',  'Z'],
	'volume'      => ['EXTENT',    'VOLUME'],
	'perimiter'   => ['EXTENT',    'PERIMITER'],
	'Surf. Area'  => ['EXTENT',    'SURFACE_AREA'],
	'Form Factor' => ['EXTENT',    'FORM_FACTOR']
	};

    $self->{columnKeyRE} = {
	'i\[([0-9]+)\]'  => ['SIGNAL', 'INTEGRAL',       'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]X' => ['SIGNAL', 'CENTROID_X',     'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]Y' => ['SIGNAL', 'CENTROID_Y',     'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]Z' => ['SIGNAL', 'CENTROID_Z',     'ONE2MANY', 'WAVELENGTH'],
	'm\[([0-9]+)\]'  => ['SIGNAL', 'MEAN',           'ONE2MANY', 'WAVELENGTH'],
	'ms\[([0-9]+)\]' => ['SIGNAL', 'SD_OVER_MEAN',   'ONE2MANY', 'WAVELENGTH'],
	'g\[([0-9]+)\]'  => ['SIGNAL', 'GEOMEAN',        'ONE2MANY', 'WAVELENGTH'],
	'gs\[([0-9]+)\]' => ['SIGNAL', 'SD_OVER_GEOMEAN','ONE2MANY', 'WAVELENGTH']
	};


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

    my ($cmd,$pp);

    # Get the path to the program
    $cmd = "SELECT path,program_name FROM programs WHERE program_name='".$self->{programName}."'";
    $pp = join ("",$dbh->selectrow_array($cmd));
    die "Program $pp does not exist.\n" unless (-e $pp);
    die "User '".getpwuid ($<)."' does not have permission to execute $pp\n" unless (-x $pp);
    $self->{programPath} = $pp;
    
    # Set the wavelength
    $self->{wavelength} = sprintf ("%d",$CGI->param('wavelengths'));

    # make up a parameter string based on user entries.
    # The order of required parameters (other than dataset name) is:
    # <wavelength> <threshold> <min. spot vol.> [<-time#n-#n>] [<-iwght#n>]
    
    # Set the threshold
    if ($params->{'threshold'} eq 'Absolute')
    {
	$self->{threshold} = sprintf ("%d",$params->{'Absolute'});
    }
    elsif ($params->{'threshold'} eq 'Relative')
    {
	my $nSigmas = sprintf ("%.2f",$params->{'nSigmas'});
	if ($params->{'means'} eq 'Mean')
	{
	    $self->{threshold} = "mean".$nSigmas."s";
	}
	else
	{
	    $self->{threshold} = "gmean".$nSigmas."s";
	}
    }
    else
    {
	my %thresholdMap = (
			    'Moment-Preservation' => 'MOMENT',
			    'Otsu\'s moment preservation' => 'OTSU',
			    'Maximum Entropy' => 'ME',
			    'Kittler\'s minimum error' => 'KITTLER'
			    );
	$self->{threshold} = $thresholdMap{$params->{'autoThresh'}};
    }

    # Set the times
    $self->{minSpotVol} = sprintf ("%d",$params->{'minPix'});
    if ($params->{'startTime'} eq 'Beginning')
    {
	$self->{tStart}=0;
    }
    else
    {
	$self->{tStart} = sprintf ("%d",$params->{'Start'});
    }
    if ($params->{'stopTime'} eq 'End')
    {
	$self->{tStop}=0;
    }
    else
    {
	$self->{tStop} = sprintf ("%d",$params->{'Stop'});
    }

    push (@{$self->{parameters}},$self->{wavelength});
    push (@{$self->{parameters}},$self->{threshold});
    push (@{$self->{parameters}},$self->{minSpotVol});
    if ($self->{tStart} || $self->{tStop})
    {
	push (@{$self->{parameters}},"-time".$self->{tStart}."-".$self->{tStop});
    }

    # Put the output options at the end of the parameter list.
    push (@{$self->{parameters}},$self->{outputOptions});

    # format the parameters to go into the database.
    # We need to quote the string parameter
    $self->{threshold} = "'$self->{threshold}'";

    # We need to set tStart and tStop to 'NULL' if they are undef.
    $self->{tStart} = 'NULL' unless defined $self->{tStart};
    $self->{tStop} = 'NULL' unless defined $self->{tStop};

}

sub Execute {
    my $self    = shift;
    my $dataset = shift;
    my $OME     = $self->{OME};

    # don't call inherited execute

    my $datasetID   = $dataset->ID;
    my $datasetPath = $dataset->Path.$dataset->Name;
    my $datasetName = $dataset->Name;

    # Get temporary file names for stdout and stderr.
    my $fNameStdout = $OME->GetTempName ($self->{programName}.'-'.$datasetID,"stdout")
	or die "Couldn't open a temporary file.\n";
    my $fNameStderr = $OME->GetTempName ($self->{programName}.'-'.$datasetID,"stderr")
	or die "Couldn't open a temporary file.\n";
    # Generate the command for executing the program, and execute it.
    my $cmd = $self->{programPath}." ".$datasetPath." ".join (" ",@{$self->{parameters}}).
	" 2> $fNameStderr 1> $fNameStdout";
    my $programStatus = system ($cmd);
    my $shortStatus = sprintf "%hd",$programStatus;
    $shortStatus = $shortStatus/256;

    my ($analysisID, $nFeatures);
    
    if ($shortStatus < 0)
    {
	# Dump the error file if there were errors.
	print "<H2>Errors durring execution:</H2>";
	print "<PRE>",`cat $fNameStderr`,"</PRE>";
    } else {
	# Process the program's output if there were no errors.

	# Get a new analysis ID by passing the user parameters to the RegisterAnalysis method.
	$analysisID = $OME->RegisterAnalysis(datasetID    => $datasetID,
					     programName  => $self->{programName},
					     TIME_START   => $self->{tStart},
					     TIME_STOP    => $self->{tStop},
					     WAVELENGTH   => $self->{wavelength},
					     THRESHOLD    => $self->{threshold},
					     MIN_SPOT_VOL => $self->{minSpotVol});
	
	# This wrapper reads the output, generates features, and writes them into the DB.
	$nFeatures = $self->ProcessOutput($analysisID,$fNameStdout);
	# my $td = timediff($t1, $t0);
	
	print "<H4>Analysis ID $analysisID on file '$datasetName':  ".$nFeatures." features found.</H4>";
	
	# Tell OME that we're done.  OME will commit the transaction we started
	# in the RegisterAnalysis method,	
	# Set the view for the dataset, etc.
	$OME->FinishAnalysis();

	# Purge similar analyses from the DB (similar = same program, same user, same dataset).
	$OME->PurgeDataset($datasetID);

    }
    
    unlink ($fNameStdout);
    unlink ($fNameStderr);
}


sub FinishAnalysis {
    my $self = shift;
    my $OME  = $self->{OME};

    $self->SUPER::FinishAnalysis();
}

sub OutputHTMLForm {
    my $self = shift;
    my $OME  = $self->{OME};
    my $CGI  = $OME->cgi();
    my @tableRows;
    my @tableColumns;
    my @radioGrp;


    # The user supplies the TIME_START, TIME_STOP (begining to end, or
    # number to end or begining to number) The WAVELEGTH.  This is a
    # popup containing the wavelegths in the dataset(s), The
    # THRESHOLD.  This is either a number or relative to the mean or
    # to the geometric mean.  Minimum spot volume - a number Intensity
    # weight - default 0.

    $tableColumns[0]=$CGI->th('Time');
    $tableColumns[1]='<b>From:</b>';
    @radioGrp = $CGI->radio_group(-name     => 'startTime',
				  -values   => ['Beginning','timePoint'],
				  -default  => 'Beginning',
				  -nolabels => 1);
    $tableColumns[2] = $radioGrp[0]."Beginning";
    $tableColumns[3] = $radioGrp[1]."Timepoint".$CGI->textfield(-name=>'Start',-size=>4);
    @tableColumns = $CGI->td (\@tableColumns);
    push (@tableRows,@tableColumns);
    @tableColumns = ();

    $tableColumns[0]=$CGI->td(' ');
    $tableColumns[1]='<b>To:</b>';
    @radioGrp = $CGI->radio_group(-name=>'stopTime',
				  -values=>['End','timePoint'],-default=>'End',-nolabels=>1);
    $tableColumns[2] = $radioGrp[0]."End";
    $tableColumns[3] = $radioGrp[1]."Timepoint".$CGI->textfield(-name=>'Stop',-size=>4);
    @tableColumns = $CGI->td (\@tableColumns);
    push (@tableRows,@tableColumns);
    @tableColumns = ();



# Collect the wavelengths available for the selected datasets
    my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
    $tableColumns[0] = $CGI->th ('Wavelength');
    $tableColumns[1] = $CGI->popup_menu(-name=>'wavelengths',
					-values=>$wavelengths);
    $tableColumns[2] = $CGI->td (' ');
    @tableColumns = $CGI->td (\@tableColumns);
    push (@tableRows,@tableColumns);
    @tableColumns = ();

    $tableColumns[0] = $CGI->th ('Threshold');
    @radioGrp = $CGI->radio_group(-name=>'threshold',
				  -values=>['Absolute','Relative','Automatic'],
				  -default=>'Relative',
				  -nolabels=>1);
    $tableColumns[1] = $radioGrp[0]."Absolute :<BR>".$CGI->textfield(-name=>'Absolute',-size=>4);
    $tableColumns[2] = $radioGrp[1]."Relative to:".$CGI->popup_menu(-name=>'means',
								    -values=>['Mean','Geometric Mean'],
								    default=>'Geometric Mean').
									"<BR>+/-".$CGI->textfield(-name=>'nSigmas',-size=>4).
									" standard deviations.</blockquote>";
    $tableColumns[3] = $radioGrp[2]."Automatic:<BR>".$CGI->popup_menu(-name=>'autoThresh',
								      -values=>['Maximum Entropy','Kittler\'s minimum error','Moment-Preservation','Otsu\'s moment preservation'],
								      default=>'Maximum Entropy');
    @tableColumns = $CGI->td (\@tableColumns);
    push (@tableRows,@tableColumns);
    @tableColumns = ();


    $tableColumns[0] = $CGI->th ('Min. volume');
    $tableColumns[1] = $CGI->textfield(-name=>'minPix',-size=>4,default=>'4')."pixels.";
    @tableColumns = $CGI->td (\@tableColumns);
    push (@tableRows,@tableColumns);
    @tableColumns = ();



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



