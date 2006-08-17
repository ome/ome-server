# OME/Analysis/Modules/Tracking/FindSpots.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institue of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:	 Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Tracking::FindSpots;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;
use Log::Agent;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

use fields qw(_options _outputHandle _errorHandle
			  _outputFile _errorFile _cmdLine);
use OME::Tasks::ImageManager;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	$self->{_options} = "-tt -th -c -i -m -g -ms -gs -mc -v -sa -per -ff -box -sd";


	bless $self,$class;
	return $self;
}

sub startImage {
	my ($self,$imageIN) = @_;
	$self->SUPER::startImage($imageIN);

	my $image		= $self->getCurrentImage();
	my $pixels_attr = $self->getCurrentInputAttributes("Pixels")->[0];
	my $path		= $pixels_attr->Repository()->ImageServerURL().' '.$pixels_attr->ImageServerID;
	my $location	= $self->getModule()->location();
	my $options		= $self->{_options};

	my $params = $self->getCurrentInputAttributes("Parameters")->[0];
	my $paramopts = " ";

	# The channel is a label.  We have to convert it to a channel index
	my $channelLabels= OME::Tasks::ImageManager->getImageWavelengths($image);
	my %channelIndexes = map{ $_->{Label} => $_->{WaveNum} } @$channelLabels ;

	my $channel = $channelIndexes{$params->Channel()};
	if (defined $channel) {
		if ($channel >= 0 && $channel < $pixels_attr->SizeC()) {
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
			if ($timeStart >= 0 && $timeStart < $pixels_attr->SizeT()) {
				my $v = sprintf("%d",$timeStart);
				$timeopt .= "$v";
			} else {
				die "Illegal start time: $timeStart";
			}
		}

		$timeopt .= "-";

		if (defined $timeStop) {
			if ($timeStop >= 0 && $timeStop < $pixels_attr->SizeT()) {
				my $v = sprintf("%d",$timeStop);
				$timeopt .= "$v";
			} else {
				die "Illegal stop time: $timeStop";
			}
		}

		$paramopts .= "$timeopt ";
	}
	
	if (defined $params->FadeSpotsTheT() and $params->FadeSpotsTheT() < $pixels_attr->SizeT()) {
		$paramopts .= "-fadeSpots ".$params->FadeSpotsTheT()." ";
	}
	
	if (defined $params->DarkSpots() and $params->DarkSpots()) {
		$paramopts .= "-darkSpots ";
	}

	my $cmdLine = "$location $path $paramopts $options";

	my ($output, $error, $pid);
	my $session = $self->Session();
	my $outputFile = $session->getTemporaryFilename("findSpots","stdout");
	my $errorFile  = $session->getTemporaryFilename("findSpots","stderr");

	$output = new IO::File;
	$error = new IO::File;
	print STDERR "		$cmdLine\n";

	$self->{_outputHandle} = $output;
	$self->{_errorHandle} = $error;
	$self->{_outputFile} = $outputFile;
	$self->{_errorFile} = $errorFile;
	$self->{_currentImage} = $image;
	$self->{_cmdLine} = $cmdLine;


	#$cmdLine = $self->{_cmdLine};
	system("$cmdLine > ".$self->{_outputFile}.
	   " 2> ".$self->{_errorFile});

	open $self->{_outputHandle}, "< ".$self->{_outputFile};
	open $self->{_errorHandle}, "< ".$self->{_errorFile};

	$self->{_features} = [];

}


sub finishImage {
	my ($self) = @_;
	
	my $output = $self->{_outputHandle};
	my $image = $self->getCurrentImage();
	my $channel_rex = qr/^(c|i|m|g|ms|gs)\[(\s*[0-9]+)\]([XYZ])?$/;
	my $channel;

	my %Timepoint_key;
	my %Threshold_key;
	my %Location_key;
	my %Extent_key;
	my %Signals_key;
	
	my @headers;
	my $col_num=0;

	my $headers = <$output>;
	chomp $headers;
	foreach my $header (split("\t",$headers)) {
		$header =~ s/^\s+//;
		$header =~ s/\s+$//;
		push @headers, $header;

		if ($header eq "t") {
			$Timepoint_key{TheT} = $col_num;
		} elsif ($header eq "Thresh.") {
			$Threshold_key{Threshold} = $col_num;
		} elsif ($header eq "mean X") {
			$Location_key{TheX} = $col_num;
		} elsif ($header eq "mean Y") {
			$Location_key{TheY} = $col_num;
		} elsif ($header eq "mean Z") {
			$Location_key{TheZ} = $col_num;
		
		} elsif ($header eq "volume") {
			$Extent_key{Volume} = $col_num;
		} elsif ($header eq "min X") {
			$Extent_key{MinX} = $col_num;
		} elsif ($header eq "min Y") {
			$Extent_key{MinY} = $col_num;
		} elsif ($header eq "min Z") {
			$Extent_key{MinZ} = $col_num;
		} elsif ($header eq "max X") {
			$Extent_key{MaxX} = $col_num;
		} elsif ($header eq "max Y") {
			$Extent_key{MaxY} = $col_num;
		} elsif ($header eq "max Z") {
			$Extent_key{MaxZ} = $col_num;
		} elsif ($header eq "sigma X") {
			$Extent_key{SigmaX} = $col_num;
		} elsif ($header eq "sigma Y") {
			$Extent_key{SigmaY} = $col_num;
		} elsif ($header eq "sigma Z") {
			$Extent_key{SigmaZ} = $col_num;
		} elsif ($header eq "Surf. Area") {
			$Extent_key{SurfaceArea} = $col_num
		} elsif ($header eq "perimiter") {
			$Extent_key{Perimeter} = $col_num;
		} elsif ($header eq "Form Factor") {
			$Extent_key{FormFactor} = $col_num;
		
		} elsif ($header =~ /$channel_rex/) {
			my $c1 = $1;
			my $channel = $2;
			my $c2 = $3;
			
			if (($c1 eq "c") && ($c2 eq "X")) {
				$Signals_key{$channel}{CentroidX} = $col_num;
			} elsif (($c1 eq "c") && ($c2 eq "Y")) {
				$Signals_key{$channel}{CentroidY} = $col_num;
			} elsif (($c1 eq "c") && ($c2 eq "Z")) {
				$Signals_key{$channel}{CentroidZ} = $col_num;
			} elsif ($c1 eq "i") {
				$Signals_key{$channel}{Integral} = $col_num;
			} elsif ($c1 eq "m") {
				$Signals_key{$channel}{Mean} = $col_num;
			} elsif ($c1 eq "g") {
				$Signals_key{$channel}{GeometricMean} = $col_num;
			} elsif ($c1 eq "ms") {
				$Signals_key{$channel}{Sigma} = $col_num;
			} elsif ($c1 eq "gs") {
				$Signals_key{$channel}{GeometricSigma} = $col_num;
			}
		}

		$col_num++;
	}


	my $spotCount = 0;


	while (my $line = <$output>) {
	# Oddly, the AE handler keeps track of attributes by hash ref, so we have to
	# declare a new hash fpr each attribute.
		my %Timepoint_data;
		my %Threshold_data;
		my %Location_data;
		my %Extent_data;
		my %Signals_data;

		chomp $line;
		my @data;
		$col_num = 0;
		foreach my $datum (split("\t",$line)) {
			$datum =~ s/^\s+//;
			$datum =~ s/\s+$//;
			$datum = undef if ($datum =~ /inf/i || $datum =~ /nan/i);
			push (@data,$datum);
		}
		

		$spotCount++;
		my $feature = $self->newFeature("Spot $spotCount",$image);
		my $featureID = $feature->id();
		my $featureName = $feature->name();
		logdbg "debug", "Spot $spotCount: Feature ID $featureID ";

		$Timepoint_data{TheT} = $data[$Timepoint_key{TheT}];
		$Timepoint_data{feature_id} = $featureID;

		$Threshold_data{Threshold} = $data[$Threshold_key{Threshold}];
		$Threshold_data{feature_id} = $featureID;

		$Location_data{TheX} = $data[$Location_key{TheX}];
		$Location_data{TheY} = $data[$Location_key{TheY}];
		$Location_data{TheZ} = $data[$Location_key{TheZ}];
		$Location_data{feature_id} = $featureID;
		
		$Extent_data{Volume} = $data[$Extent_key{Volume}];
		$Extent_data{MinX} = $data[$Extent_key{MinX}];
		$Extent_data{MinY} = $data[$Extent_key{MinY}];
		$Extent_data{MinZ} = $data[$Extent_key{MinZ}];
		$Extent_data{MaxX} = $data[$Extent_key{MaxX}];
		$Extent_data{MaxY} = $data[$Extent_key{MaxY}];
		$Extent_data{MaxZ} = $data[$Extent_key{MaxZ}];
		$Extent_data{SigmaX} = $data[$Extent_key{SigmaX}];
		$Extent_data{SigmaY} = $data[$Extent_key{SigmaY}];
		$Extent_data{SigmaZ} = $data[$Extent_key{SigmaZ}];
		$Extent_data{SurfaceArea} = $data[$Extent_key{SurfaceArea}];
		$Extent_data{Perimeter} = $data[$Extent_key{Perimeter}];
		$Extent_data{FormFactor} = $data[$Extent_key{FormFactor}];
		$Extent_data{feature_id} = $featureID;
		
		foreach $channel (keys (%Signals_key) ) {
			$Signals_data{$channel} = {} unless exists $Signals_data{$channel};
			$Signals_data{$channel}->{TheC} = $channel;
			$Signals_data{$channel}->{CentroidX} = $data[$Signals_key{$channel}{CentroidX}];
			$Signals_data{$channel}->{CentroidY} = $data[$Signals_key{$channel}{CentroidY}];
			$Signals_data{$channel}->{CentroidZ} = $data[$Signals_key{$channel}{CentroidZ}];
			$Signals_data{$channel}->{Integral} = $data[$Signals_key{$channel}{Integral}];
			$Signals_data{$channel}->{Mean} = $data[$Signals_key{$channel}{Mean}];
			$Signals_data{$channel}->{GeometricMean} = $data[$Signals_key{$channel}{GeometricMean}];
			$Signals_data{$channel}->{Sigma} = $data[$Signals_key{$channel}{Sigma}];
			$Signals_data{$channel}->{GeometricSigma} = $data[$Signals_key{$channel}{GeometricSigma}];
			$Signals_data{$channel}->{feature_id} = $featureID;
		}

		$self->newAttributes('Timepoint',\%Timepoint_data,
			'Threshold',\%Threshold_data,
			'Location',\%Location_data,
			'Extent',\%Extent_data
		);

		foreach my $signal (values %Signals_data) {
			$self->newAttributes('Signals',$signal);
		}
	} # foreach row

	close $self->{_outputHandle};
	close $self->{_errorHandle};

	my $session = OME::Session->instance();
	$session->finishTemporaryFile($self->{_outputFile});
	$session->finishTemporaryFile($self->{_errorFile});

	$self->SUPER::finishImage();
}




1;
