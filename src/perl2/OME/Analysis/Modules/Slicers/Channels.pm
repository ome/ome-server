# OME/Analysis/Modules/Slicers/Channels.pm

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


package OME::Analysis::Modules::Slicers::Channels;

use strict;
use OME 2.002_000;
our $VERSION = 1.000;

=head1 NAME

OME::Analysis::Modules::Slicers::Channels

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

    my @slices  = $self->getCurrentInputAttributes("Slices");
    my @indices = $self->getCurrentInputAttributes("Channel indices");

  SLICE:
    foreach my $slice (@slices) {
        my $c0 = $slice->StartC();
        my $c1 = $slice->EndC();

        if (scalar(@indices) > 0) {
            # The user specified which channels they want

          INDEX:
            foreach my $index (@indices) {
                my $c = $index->TheC();

                # Make sure that this input slice contains this channel
                # index before we create a new slice for it.

                next INDEX if ($c < $c0 || $c > $c1);

                my $parent = $factory->
                  newParentAttribute('PixelsSlice',$image,$mex,
                               {
                                Parent => $slice->Parent(),
                                StartX => $slice->StartX(),
                                EndX   => $slice->EndX(),
                                StartY => $slice->StartY(),
                                EndY   => $slice->EndY(),
                                StartZ => $slice->StartZ(),
                                EndZ   => $slice->EndZ(),
                                StartC => $c,
                                EndC   => $c,
                                StartT => $slice->StartT(),
                                EndT   => $slice->EndT(),
                               });

                my $new_slice = $self->
                  newAttributes('Channel slices',
                                {
                                 Parent => $parent,
                                });
            }
        } else {
            # The user did not specify any slices, so loop through the
            # channels in the current slice, creating a new slice for
            # each.

            for (my $c = $c0; $c <= $c1; $c++) {
                my $parent = $factory->
                  newParentAttribute('PixelsSlice',$image,$mex,
                               {
                                Parent => $slice->Parent(),
                                StartX => $slice->StartX(),
                                EndX   => $slice->EndX(),
                                StartY => $slice->StartY(),
                                EndY   => $slice->EndY(),
                                StartZ => $slice->StartZ(),
                                EndZ   => $slice->EndZ(),
                                StartC => $c,
                                EndC   => $c,
                                StartT => $slice->StartT(),
                                EndT   => $slice->EndT(),
                               });

                my $new_slice = $self->
                  newAttributes('Channel slices',
                                {
                                 Parent => $parent,
                                });
            }
        }
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
