# OME/Analysis/Modules/Slicers/Planes.pm

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
PixelsPlaneSlice. The PixelsPlaneSlice points to the 
FrequencySpace's magnitude plane.

=cut

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    bless $self, $class;
    return $self;
}

sub startImage {
    my ($self,$image) = @_;
    $self->SUPER::startImage($image);

    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $mex     = $self->getModuleExecution();

    my @fses  = $self->getCurrentInputAttributes("Frequency Space");
    
    foreach my $fs (@fses) {
    	my $slice = $fs->Parent();
    	
    	# PixelsSlice points to the zeroth Channel
		my $parent = $factory->
		  newParentAttribute('PixelsSlice',$slice->image(),$mex,
					   {
						Parent => $slice->Parent(),
						StartX => $slice->StartX(),
						EndX   => $slice->EndX(),
						StartY => $slice->StartY(),
						EndY   => $slice->EndY(),
						StartZ => 0,
						EndZ   => 0,
						StartC => 0,
						EndC   => 0,
						StartT => 0,
						EndT   => 0,
					   });
					   
		# Convert the PixelsSlice into a planes slice;
		my $new_slice = $self->newAttributes('Pixels Plane Slice',
											{
											 Parent => $parent,
											});
	}
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
