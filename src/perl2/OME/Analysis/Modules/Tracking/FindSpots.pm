# OME/Analysis/FindSpotsHandler.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Analysis::FindSpotsHandler;

use strict;
our $VERSION = '1.0';

use IO::File;
use OME::Analysis::CLIHandler;

use base qw(OME::Analysis::CLIHandler);

use fields qw(_options _inputHandle _outputHandle _errorHandle
	      _inputFile _outputFile _errorFile _cmdLine);

sub new {
    my ($proto,$location,$session,$program,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$program,$node);

    $self->{_options} = "0 gmean4.5s 10 -db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v -sa -per -ff";

    bless $self,$class;
    return $self;
}

sub precalculateImage {
    my ($self) = @_;

    my $image = $self->getCurrentImage();
    my $path = $image->getFullPath();
    my $location = $self->{_location};
    my $options = $self->{_options};
    my $cmdLine = "$location $path $options";

    my ($input, $output, $error, $pid);
    my $session = $self->Session();
    my $inputFile  = $session->getTemporaryFilename("findSpots","stdin");
    my $outputFile = $session->getTemporaryFilename("findSpots","stdout");
    my $errorFile  = $session->getTemporaryFilename("findSpots","stderr");

    $input = new IO::File;
    $output = new IO::File;
    $error = new IO::File;
    open $input, "> $inputFile";

    print STDERR "      $location $path $options\n";

    $self->{_inputHandle} = $input;
    $self->{_outputHandle} = $output;
    $self->{_errorHandle} = $error;
    $self->{_inputFile} = $inputFile;
    $self->{_outputFile} = $outputFile;
    $self->{_errorFile} = $errorFile;
    $self->{_currentImage} = $image;
    $self->{_cmdLine} = $cmdLine;

    my $dims = $image->Dimensions();
    my $dimString = "Dims=".$dims->size_x().",".$dims->size_y().
	",".$dims->size_z().",".$dims->num_waves().",".$dims->num_times();

    print $input "$dimString\nWaveStats=\n";

    my $mean_list = $self->getImageInputs('Stack mean');
    my $geomean_list = $self->getImageInputs('Stack geomean');
    my $sigma_list = $self->getImageInputs('Stack sigma');
    my $min_list = $self->getImageInputs('Stack minimum');
    my $max_list = $self->getImageInputs('Stack maximum');

    die "Bad input lists"
        if (scalar(@$mean_list) != scalar(@$geomean_list))
            || (scalar(@$mean_list) != scalar(@$sigma_list))
            || (scalar(@$mean_list) != scalar(@$min_list))
            || (scalar(@$mean_list) != scalar(@$max_list));


    my %wave_stats;

    $wave_stats{$_->TIMEPOINT()}->{$_->WAVENUMBER()}->{Mean} = $_->MEAN()
        foreach @$mean_list;
    $wave_stats{$_->TIMEPOINT()}->{$_->WAVENUMBER()}->{Geomean} = $_->GEOMEAN()
        foreach @$geomean_list;
    $wave_stats{$_->TIMEPOINT()}->{$_->WAVENUMBER()}->{Sigma} = $_->SIGMA()
        foreach @$sigma_list;
    $wave_stats{$_->TIMEPOINT()}->{$_->WAVENUMBER()}->{Min} = $_->MINIMUM()
        foreach @$min_list;
    $wave_stats{$_->TIMEPOINT()}->{$_->WAVENUMBER()}->{Max} = $_->MAXIMUM()
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
		$timepointData->{TIMEPOINT} = $datum;
	    } elsif ($header eq "Thresh.") {
		$thresholdData->{THRESHOLD} = $datum;
	    } elsif ($header eq "mean X") {
		$locationData->{X} = $datum;
	    } elsif ($header eq "mean Y") {
		$locationData->{Y} = $datum;
	    } elsif ($header eq "mean Z") {
		$locationData->{Z} = $datum;
	    } elsif ($header eq "volume") {
		$extentData->{VOLUME} = $datum;
	    } elsif ($header eq "Surf. Area") {
		$extentData->{SURFACE_AREA} = $datum;
	    } elsif ($header eq "perimiter") {
		$extentData->{PERIMETER} = $datum;
	    } elsif ($header eq "Form Factor") {
		$extentData->{FORM_FACTOR} = $datum;
	    } elsif ($header =~ /$wavelength_rex/) {
		my $c1 = $1;
		my $wavelength = $2;
		my $c2 = $3;

		my $signalData;
		if (!exists $signalData{$wavelength}) {
		    $signalData = {
			WAVELENGTH => $wavelength
			};
                    $signalData{$wavelength} = $signalData;
		} else {
		    $signalData = $signalData{$wavelength};
		}

		if (($c1 eq "c") && ($c2 eq "X")) {
		    $signalData->{CENTROID_X} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Y")) {
		    $signalData->{CENTROID_Y} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Z")) {
		    $signalData->{CENTROID_Z} = $datum;
		} elsif ($c1 eq "i") {
		    $signalData->{INTEGRAL} = $datum;
		} elsif ($c1 eq "m") {
		    $signalData->{MEAN} = $datum;
		} elsif ($c1 eq "g") {
		    $signalData->{GEOMEAN} = $datum;
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
