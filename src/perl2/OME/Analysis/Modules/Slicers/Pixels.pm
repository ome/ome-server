# OME/Analysis/Modules/Slicers/Pixels.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Slicers::Pixels;

use strict;
use OME 2.002_000;
our $VERSION = 1.000;

=head1 NAME

OME::Analysis::Modules::Slicers::Pixels

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

    my @pixelses = $self->getCurrentInputAttributes("Pixels");

  PIXELS:
    foreach my $pixels (@pixelses) {
        my $new_slice = $self->
          newAttributes('Pixels slices',
                        {
                         Pixels => $pixels,
                         StartX => 0,
                         EndX   => $pixels->SizeX() - 1,
                         StartY => 0,
                         EndY   => $pixels->SizeY() - 1,
                         StartZ => 0,
                         EndZ   => $pixels->SizeZ() - 1,
                         StartC => 0,
                         EndC   => $pixels->SizeC() - 1,
                         StartT => 0,
                         EndT   => $pixels->SizeT() - 1,
                        });
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
