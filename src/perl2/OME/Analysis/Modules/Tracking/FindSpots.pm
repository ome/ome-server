# OME/Analysis/Modules/Tracking/FindSpots.pm

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


package OME::Analysis::Modules::Tracking::FindSpots;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

use fields qw(_options _outputHandle _errorHandle
              _outputFile _errorFile _cmdLine);
use OME::Tasks::ImageManager;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    $self->{_options} = "-db -tt -th -c -i -m -g -ms -gs -mc -v -sa -per -ff";


    bless $self,$class;
    return $self;
}

sub startImage {
    my ($self,$imageIN) = @_;
    $self->SUPER::startImage($imageIN);

    my $image       = $self->getCurrentImage();
    my $pixels_attr = $self->getCurrentInputAttributes("Pixels")->[0];
    my $path        = $pixels_attr->Repository()->ImageServerURL().' '.$pixels_attr->ImageServerID;
    my $location    = $self->getModule()->location();
    my $options     = $self->{_options};

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

    my $cmdLine = "$location $path $paramopts $options";

    my ($output, $error, $pid);
    my $session = $self->Session();
    my $outputFile = $session->getTemporaryFilename("findSpots","stdout");
    my $errorFile  = $session->getTemporaryFilename("findSpots","stderr");

    $output = new IO::File;
    $error = new IO::File;
    print STDERR "      $cmdLine\n";

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

    my $headers = <$output>;
    chomp $headers;
    my @headers;
    foreach my $header (split("\t",$headers)) {
	     $header =~ s/^\s+//;
	     $header =~ s/\s+$//;
	     push @headers, $header;
    }

    my $image = $self->getCurrentImage();
    my $wavelength_rex = qr/^(c|i|m|g|ms|gs)\[(\s*[0-9]+)\]([XYZ])?$/;

    my $spotCount = 1;

    while (my $line = <$output>) {
	     	chomp $line;
	     	my @data;
	     	foreach my $datum (split("\t",$line)) {
	          $datum =~ s/^\s+//;
	          $datum =~ s/\s+$//;
	          push @data, $datum;
	     	}

	    	my $feature = $self->newFeature('Spot '.$spotCount++);
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

	        $datum = undef if ($datum eq 'inf' || $datum eq 'nan');
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
              	   $extentData->{SurfaceArea} =$datum
	        } elsif ($header eq "perimiter") {
			   if ($datum >10000){
              	      $extentData->{Perimeter} =0;#$datum;
			   }else{
				$extentData->{Perimeter} =$datum;
			   }
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
		         } elsif ($c1 eq "ms") {
		           $signalData->{Sigma} = $datum;
		         } elsif ($c1 eq "gs") {
		           $signalData->{GeometricSigma} = $datum;
		        }
        } else {
		      #print STDERR "?";
	      }
      }  # foreach datum

      $self->newAttributes('Timepoint',$timepointData,
                             'Threshold',$thresholdData,
                             'Location',$locationData,
                             'Extent',$extentData);

      foreach my $signal (values %signalData) {
            $self->newAttributes('Signals',$signal);
      }
    } #while

    close $self->{_outputHandle};
    close $self->{_errorHandle};

    my $session = OME::Session->instance();
    $session->finishTemporaryFile($self->{_outputFile});
    $session->finishTemporaryFile($self->{_errorFile});

    $self->SUPER::finishImage();
}




1;
