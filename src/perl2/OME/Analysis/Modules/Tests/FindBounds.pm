# OME/module_execution/FindBounds.pm

# Copyright (C) 2002 Open Microscopy Environment
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


package OME::Analysis::FindBounds;

use OME::Analysis::Handler;

use strict;
our $VERSION = 2.000_000;

use base qw(OME::Analysis::Handler);


sub createBounds {
    my ($self,$x1,$y1,$w,$h) = @_;
    my $xw = $w/2;
    my $yh = $h/2;

    # As a hack until per module configs are available, we'll use the
    # location as the tag for the new features.  --- Aha!  No longer!
    # Modules can now specify the new feature tags.

    my ($feature,$output_bounds);
    my $location = $self->{_location};

    $feature = $self->newFeature(lc($location)." 1");
    $output_bounds = $self->
        newAttributes("Output bounds",
                      {
                       X          => $x1,
                       Y          => $y1,
                       Width      => $xw,
                       Height     => $yh,
                      });

    $feature = $self->newFeature(lc($location)." 2");
    $output_bounds = $self->
        newAttributes("Output bounds",
                      {
                       X          => $x1+$xw,
                       Y          => $y1,
                       Width      => $xw,
                       Height     => $yh
                      });

    $feature = $self->newFeature(lc($location)." 3");
    $output_bounds = $self->
        newAttributes("Output bounds",
                      {
                       X          => $x1,
                       Y          => $y1+$yh,
                       Width      => $xw,
                       Height     => $yh
                      });

    $feature = $self->newFeature(lc($location)." 4");
    $output_bounds = $self->
        newAttributes("Output bounds",
                      {
                       X          => $x1+$xw,
                       Y          => $y1+$yh,
                       Width      => $xw,
                       Height     => $yh
                      });
}


sub calculateFeature {
    my ($self) = @_;

    if (defined $self->{_node}->iterator_tag()) {
        my $input_bounds = $self->getFeatureInputs('Input bounds')->[0];
        $self->createBounds($input_bounds->X(),$input_bounds->Y(),
                            $input_bounds->Width(),$input_bounds->Height());
    } else {
        my $image = $self->getCurrentImage();
        my $pixels = $image->DefaultPixels();

        $self->createBounds(0,0,$pixels->SizeX(),$pixels->SizeY());
    }

}
