# OME/Analysis/Modules/PPM/FourierTransform.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Analysis::Modules::PPM::FourierTransform;

use strict;
use OME 2.002_000;
our $VERSION = 1.000;

=head1 NAME

OME::Analysis::Modules::PPM::FourierTransform

=head1 SYNOPSIS

Typecaster module for the Fourier Transform

=head1 OVERVIEW

This module allows a FrequencySpace attribute to be used as a 
DerivedPixels. The DerivedPixels points to the 
FrequencySpace's magnitude plane.

=cut

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    bless $self, $class;
    return $self;
}

sub startFeature {
    my ($self,$feature) = @_;
    $self->SUPER::startFeature($feature);

    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $mex     = $self->getModuleExecution();

	my $start_time = [gettimeofday()];
    my @fses  = $self->getCurrentInputAttributes("Frequency Space");
	$mex->read_time(tv_interval($start_time));

	$start_time = [gettimeofday()];
    foreach my $fs (@fses) {
    	my $pixels = $fs->Parent();
    	
    	# DerivedPixels point to the zeroth Channel
		$self->newAttributes('Pixels',
					   {
						Parent => $pixels,
						StartX => 0,
						EndX   => $pixels->SizeX()-1,
						StartY => 0,
						EndY   => $pixels->SizeY()-1,
						StartZ => 0,
						EndZ   => 0,
						StartC => 0,
						EndC   => 0,
						StartT => 0,
						EndT   => 0,
					   });
	}
	$mex->write_time(tv_interval($start_time));
	$mex->storeObject();
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
