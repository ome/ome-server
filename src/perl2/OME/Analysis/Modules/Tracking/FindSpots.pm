# OME/Analysis/FindSpotsHandler.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Analysis::FindSpotsHandler;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;
use OME::Analysis::Handler;

use base qw(OME::Analysis::Handler);

use fields qw(_options _inputHandle _outputHandle _errorHandle
	      _inputFile _outputFile _errorFile _cmdLine);

sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$module,$node);

    $self->{_options} = "-db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v -sa -per -ff";

    bless $self,$class;
    return $self;
}

sub precalculateImage {
    my ($self) = @_;

    my $image = $self->getCurrentImage();
    my $pixels = $self->getImageInputs("Pixels")->[0];
    my $path = $image->getFullPath( $pixels );
    my $location = $self->{_location};
    my $options = $self->{_options};

    my $params = $self->getGlobalInputs("Parameters")->[0];
    my $paramopts = " ";

    my $channel = $params->Channel();
    if (defined $channel) {
        if ($channel >= 0 && $channel < $pixels->SizeC()) {
            my $v = sprintf("%d",$channel);
            $paramopts .= "$v ";
        } else {
            die "Illegal channel input: $channel";
        }
    } else {
        $paramopts .= "0 ";
    }

    my $threshtype = $params->ThresholdType();
    my $threshvalue = $params->ThresholdValue();
    if ($threshtype eq 'Absolute') {
        my $v = sprintf("%d",$threshvalue);
        $paramopts .= "$v ";
    } elsif ($threshtype eq 'RelativeToMean') {
        my $v = sprintf("%.2f",$threshvalue);
        $paramopts .= "mean${v}s ";
    } elsif ($threshtype eq 'RelativeToGeometricMean') {
        my $v = sprintf("%.2f",$threshvalue);
        $paramopts .= "gmean${v}s ";
    } elsif ($threshtype eq 'MaximumEntropy') {
        $paramopts .= "me ";
    } elsif ($threshtype eq 'Kittler') {
        $paramopts .= "kittler ";
    } elsif ($threshtype eq 'MomentPreservation') {
        $paramopts .= "moment ";
    } elsif ($threshtype eq 'Otsu') {
        $paramopts .= "otsu ";
    } elsif (!defined $threshtype) {
        $paramopts .= "gmean4.5s ";
    } else {
        die "Illegal threshold type: $threshtype";
    }

    my $minVol = $params->MinimumSpotVolume();
    if (defined $minVol) {
        my $v = sprintf("%d",$minVol);
        $paramopts .= "$v ";
    } else {
        $paramopts .= "10 ";
    }

    my $timeStart = $params->TimeStart();
    my $timeStop = $params->TimeStop();

    if (defined $timeStart || defined $timeStop) {
        my $timeopt = "-time ";

        if (defined $timeStart) {
            if ($timeStart >= 0 && $timeStart < $pixels->SizeT()) {
                my $v = sprintf("%d",$timeStart);
                $timeopt .= "$v";
            } else {
                die "Illegal start time: $timeStart";
            }
        }

        $timeopt .= "-";

        if (defined $timeStop) {
            if ($timeStop >= 0 && $timeStop < $pixels->SizeT()) {
                my $v = sprintf("%d",$timeStop);
                $timeopt .= "$v";
            } else {
                die "Illegal stop time: $timeStop";
            }
        }

        $paramopts .= "$timeopt ";
    }

    my $cmdLine = "$location $path $paramopts $options";

    my ($input, $output, $error, $pid);
    my $session = $self->Session();
    my $inputFile  = $session->getTemporaryFilename("findSpots","stdin");
    my $outputFile = $session->getTemporaryFilename("findSpots","stdout");
    my $errorFile  = $session->getTemporaryFilename("findSpots","stderr");

    $input = new IO::File;
    $output = new IO::File;
    $error = new IO::File;
    open $input, "> $inputFile";

    print STDERR "      $cmdLine\n";

    $self->{_inputHandle} = $input;
    $self->{_outputHandle} = $output;
    $self->{_errorHandle} = $error;
    $self->{_inputFile} = $inputFile;
    $self->{_outputFile} = $outputFile;
    $self->{_errorFile} = $errorFile;
    $self->{_currentImage} = $image;
    $self->{_cmdLine} = $cmdLine;

    my $dimString = "Dims=".$pixels->SizeX().",".$pixels->SizeY().
	",".$pixels->SizeZ().",".$pixels->SizeC().",".$pixels->SizeT();

    print $input "$dimString\nWaveStats=\n";

    my $mean_list = $self->getImageInputs('Stack means');
    my $geomean_list = $self->getImageInputs('Stack geomeans');
    my $sigma_list = $self->getImageInputs('Stack sigmas');
    my $min_list = $self->getImageInputs('Stack minima');
    my $max_list = $self->getImageInputs('Stack maxima');

    die "Bad input lists"
        if (scalar(@$mean_list) != scalar(@$geomean_list))
            || (scalar(@$mean_list) != scalar(@$sigma_list))
            || (scalar(@$mean_list) != scalar(@$min_list))
            || (scalar(@$mean_list) != scalar(@$max_list));


    my %wave_stats;

    $wave_stats{$_->TheT()}->{$_->TheC()}->{Mean} = $_->Mean()
        foreach @$mean_list;
    $wave_stats{$_->TheT()}->{$_->TheC()}->{Geomean} = $_->GeometricMean()
        foreach @$geomean_list;
    $wave_stats{$_->TheT()}->{$_->TheC()}->{Sigma} = $_->Sigma()
        foreach @$sigma_list;
    $wave_stats{$_->TheT()}->{$_->TheC()}->{Min} = $_->Minimum()
        foreach @$min_list;
    $wave_stats{$_->TheT()}->{$_->TheC()}->{Max} = $_->Maximum()
        foreach @$max_list;

    foreach my $time (sort {$a <=> $b} (keys %wave_stats)) {
        my $stats = $wave_stats{$time};
        foreach my $wave (sort {$a <=> $b} (keys %$stats)) {
            my @stats = ($wave,
                         $wave,
                         $time,
                         $wave_stats{$time}->{$wave}->{Min},
                         $wave_stats{$time}->{$wave}->{Max},
                         $wave_stats{$time}->{$wave}->{Mean},
                         $wave_stats{$time}->{$wave}->{Geomean},
                         $wave_stats{$time}->{$wave}->{Sigma});
            my $wave_stat = join(',',@stats);
            #print STDERR "        $wave_stat\n";
            print $input "$wave_stat\n";
        }
    }

    close $input;

    my $cmdLine = $self->{_cmdLine};
    system("$cmdLine < ".$self->{_inputFile}.
	   " > ".$self->{_outputFile}.
	   " 2> ".$self->{_errorFile});

    open $self->{_outputHandle}, "< ".$self->{_outputFile};
    open $self->{_errorHandle}, "< ".$self->{_errorFile};

    $self->{_features} = [];
}


sub calculateFeature {
    my ($self) = @_;

    my $output = $self->{_outputHandle};

    my $headers = <$output>;
    chomp $headers;
    my @headers;
    foreach my $header (split("\t",$headers)) {
	$header =~ s/^\s+//;
	$header =~ s/\s+$//;
	push @headers, $header;
    }

    my $image = $self->getCurrentImage();

    my $wavelength_rex = qr/^([cimg])\[([ 0-9]+)\]([XYZ])?$/;

    my $spotCount = 1;
    while (my $line = <$output>) {
	chomp $line;
	my @data;
	foreach my $datum (split("\t",$line)) {
	    $datum =~ s/^\s+//;
	    $datum =~ s/\s+$//;
	    push @data, $datum;
	}

	my $feature = $self->newFeature('Spot '+$spotCount++);
	my $featureID = $feature->id();
        print STDERR "ns$featureID ";

        #my $timepointData = {feature_id => $featureID};
        #my $thresholdData = {feature_id => $featureID};
        #my $locationData  = {feature_id => $featureID};
        #my $extentData    = {feature_id => $featureID};
        my $timepointData = {};
        my $thresholdData = {};
        my $locationData  = {};
        my $extentData    = {};
	my %signalData;

	my $i = 0;
	foreach my $datum (@data) {
	    my $header = $headers[$i++];
	    $datum = undef if ($datum eq 'inf');
	    if ($header eq "t") {
		$timepointData->{TheT} = $datum;
	    } elsif ($header eq "Thresh.") {
		$thresholdData->{Threshold} = $datum;
	    } elsif ($header eq "mean X") {
		$locationData->{TheX} = $datum;
	    } elsif ($header eq "mean Y") {
		$locationData->{TheY} = $datum;
	    } elsif ($header eq "mean Z") {
		$locationData->{TheZ} = $datum;
	    } elsif ($header eq "volume") {
		$extentData->{Volume} = $datum;
	    } elsif ($header eq "Surf. Area") {
		$extentData->{SurfaceArea} = $datum;
	    } elsif ($header eq "perimiter") {
		$extentData->{Perimeter} = $datum;
	    } elsif ($header eq "Form Factor") {
		$extentData->{FormFactor_} = $datum;
	    } elsif ($header =~ /$wavelength_rex/) {
		my $c1 = $1;
		my $wavelength = $2;
		my $c2 = $3;

		my $signalData;
		if (!exists $signalData{$wavelength}) {
		    $signalData = {
			TheC => $wavelength
			};
                    $signalData{$wavelength} = $signalData;
		} else {
		    $signalData = $signalData{$wavelength};
		}

		if (($c1 eq "c") && ($c2 eq "X")) {
		    $signalData->{CentroidX} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Y")) {
		    $signalData->{CentroidY} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Z")) {
		    $signalData->{CentroidZ} = $datum;
		} elsif ($c1 eq "i") {
		    $signalData->{Integral} = $datum;
		} elsif ($c1 eq "m") {
		    $signalData->{Mean} = $datum;
		} elsif ($c1 eq "g") {
		    $signalData->{GeometricMean} = $datum;
		}
	    } else {
		#print STDERR "?";
	    }
        }  # foreach datum

        $self->newAttributes('Timepoint',$timepointData,
                             'Threshold',$thresholdData,
                             'Location',$locationData,
                             'Extent',$extentData);

        foreach my $signalData (values %signalData) {
            $self->newAttributes('Signals',$signalData);
        }
    }

    close $self->{_outputHandle};
    close $self->{_errorHandle};
}




1;
