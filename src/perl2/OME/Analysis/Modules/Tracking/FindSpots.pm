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
	      _inputFile _outputFile _errorFile _features _cmdLine);

sub new {
    my ($proto,$location,$factory,$program) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$factory,$program);

    $self->{_options} = "0 gmean4.5s 10 -db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v -sa -per -ff";

    bless $self,$class;
    return $self;
}

sub startImage {
    my ($self,$image) = @_;

    my $path = $image->getFullPath();
    my $location = $self->{_location};
    my $options = $self->{_options};
    my $cmdLine = "$location $path $options";

    my ($input, $output, $error, $pid);
    my $session = $self->{_factory}->Session();
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
}


sub imageInputs {
    my ($self,$inputHash) = @_;

    my $input = $self->{_inputHandle};

    my $image = $self->{_currentImage};
    my $dims = $image->Dimensions();
    my $dimString = "Dims=".$dims->size_x().",".$dims->size_y().
	",".$dims->size_z().",".$dims->num_waves().",".$dims->num_times();

    print $input "$dimString\nWaveStats=\n";

    my $attribute_list = $inputHash->{Wavelength};
    my %wave_stats;
    foreach my $attribute (@$attribute_list) {
	my @stats = ($attribute->wavenumber(),
		     $attribute->wavenumber(),
		     $attribute->timepoint(),
		     $attribute->min(),
		     $attribute->max(),
		     $attribute->mean(),
		     $attribute->geomean(),
		     $attribute->sigma());
	my $wave_stat = join(',',@stats);
        $wave_stats{$attribute->timepoint()}->{$attribute->wavenumber()} = $wave_stat;
	#print STDERR "        $wave_stat\n";
	#print $input "$wave_stat\n";
    }

    foreach my $time (sort {$a <=> $b} (keys %wave_stats)) {
        my $stats = $wave_stats{$time};
        foreach my $wave (sort {$a <=> $b} (keys %$stats)) {
            my $wave_stat = $stats->{$wave};
            print STDERR "        $wave_stat\n";
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


sub precalculateImage {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    my $factory = $self->{_factory};

    my %feature_outputs;
    my $output = $self->{_outputHandle};

    my $headers = <$output>;
    chomp $headers;
    my @headers;
    foreach my $header (split("\t",$headers)) {
	$header =~ s/^\s+//;
	$header =~ s/\s+$//;
	push @headers, $header;
    }

    my $image = $self->{_currentImage};

    my $wavelength_rex = qr/^([cimg])\[([ 0-9]+)\]([XYZ])?$/;

    my $spotCount = 0;
    print STDERR "      ";
    while (my $line = <$output>) {
	chomp $line;
	my @data;
	foreach my $datum (split("\t",$line)) {
	    $datum =~ s/^\s+//;
	    $datum =~ s/\s+$//;
	    push @data, $datum;
	}

	my $feature = $factory->newAttribute('FEATURES',{
	    image_id => $image->id(),
	    name     => "Spot".$spotCount++
	    });
	my $featureID = $feature->id();
        my $timepointData = {feature_id => $featureID};
        my $thresholdData = {feature_id => $featureID};
        my $locationData  = {feature_id => $featureID};
        my $extentData    = {feature_id => $featureID};
	my %signalData;

	my $i = 0;
	foreach my $datum (@data) {
	    my $header = $headers[$i++];
	    #print STDERR ".";
	    $datum = undef if ($datum eq 'inf');
	    if ($header eq "t") {
		$timepointData->{timepoint} = $datum;
	    } elsif ($header eq "Thresh.") {
		$thresholdData->{threshold} = $datum;
	    } elsif ($header eq "mean X") {
		$locationData->{x} = $datum;
	    } elsif ($header eq "mean Y") {
		$locationData->{y} = $datum;
	    } elsif ($header eq "mean Z") {
		$locationData->{z} = $datum;
	    } elsif ($header eq "volume") {
		$extentData->{volume} = $datum;
	    } elsif ($header eq "Surf. Area") {
		$extentData->{surface_area} = $datum;
	    } elsif ($header eq "perimiter") {
		$extentData->{perimiter} = $datum;
	    } elsif ($header eq "Form Factor") {
		$extentData->{form_factor} = $datum;
	    } elsif ($header =~ /$wavelength_rex/) {
		my $c1 = $1;
		my $wavelength = $2;
		my $c2 = $3;
		#print STDERR " '$c1' '$wavelength' '$c2'";

		my $signalData;
		if (!exists $signalData{$wavelength}) {
		    $signalData = {
			feature_id => $featureID,
			wavelength => $wavelength
			};
                    $signalData{$wavelength} = $signalData;
		} else {
		    $signalData = $signalData{$wavelength};
		}

		if (($c1 eq "c") && ($c2 eq "X")) {
		    $signalData->{centroid_x} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Y")) {
		    $signalData->{centroid_y} = $datum;
		} elsif (($c1 eq "c") && ($c2 eq "Z")) {
		    $signalData->{centroid_z} = $datum;
		} elsif ($c1 eq "i") {
		    $signalData->{integral} = $datum;
		} elsif ($c1 eq "m") {
		    $signalData->{mean} = $datum;
		} elsif ($c1 eq "g") {
		    $signalData->{geomean} = $datum;
		}
	    } else {
		#print STDERR "?";
	    }
        }  # foreach datum

	my $timepoint = $factory->newAttribute('TIMEPOINT',$timepointData);
	my $threshold = $factory->newAttribute('THRESHOLD',$thresholdData);
	my $location = $factory->newAttribute('LOCATION',$locationData);
	my $extent = $factory->newAttribute('EXTENT',$extentData);

        my @signals;
        foreach my $signalData (values %signalData) {
            push @signals, $factory->newAttribute('SIGNAL',$signalData);
        }

        # Save the image attribute for later
        push @{$self->{_features}}, $feature;
        
        # Return the feature attributes
	$feature_outputs{'Timepoint'}->{$featureID} = $timepoint;
	$feature_outputs{'Threshold'}->{$featureID} = $threshold;
	$feature_outputs{'X'}->{$featureID} = $location;
	$feature_outputs{'Y'}->{$featureID} = $location;
	$feature_outputs{'Z'}->{$featureID} = $location;
	$feature_outputs{'Volume'}->{$featureID} = $extent;
	$feature_outputs{'Perimeter'}->{$featureID} = $extent;
	$feature_outputs{'Surface area'}->{$featureID} = $extent;
	$feature_outputs{'Form factor'}->{$featureID} = $extent;
	$feature_outputs{'Wavelength'}->{$featureID} = [@signals];
	$feature_outputs{'Integral'}->{$featureID} = [@signals];
	$feature_outputs{'Centroid X'}->{$featureID} = [@signals];
	$feature_outputs{'Centroid Y'}->{$featureID} = [@signals];
	$feature_outputs{'Centroid Z'}->{$featureID} = [@signals];
	$feature_outputs{'Mean'}->{$featureID} = [@signals];
	$feature_outputs{'Geometric Mean'}->{$featureID} = [@signals];

	print STDERR "*$spotCount";
    }
    print STDERR "\n";
    print STDERR "*** ".$feature_outputs{'Timepoint'}."\n";
    #print STDERR "*** ".join(',',@{$feature_outputs{'Timepoint'}})."\n";

    close $self->{_outputHandle};
    close $self->{_errorHandle};

    return \%feature_outputs;
}


sub finishFeature {
    my ($self) = @_;
}


sub postcalculateImage {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    my $image = $self->{_currentImage};
    my $factory = $self->{_factory};
    my $features = $self->{_features};

    return {
	Spots => $features
	};
}


sub finishImage {
    my ($self) = @_;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return {};
}


sub finishDataset {
    my ($self) = @_;
}


1;
