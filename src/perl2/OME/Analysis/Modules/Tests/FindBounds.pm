# OME/Analysis/Modules/Tests/FindBounds.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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


package OME::Analysis::Modules::Tests::FindBounds;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);


sub createBounds {
    my ($self,$x1,$y1,$w,$h) = @_;
    my $xw = $w/2;
    my $yh = $h/2;

    # As a hack until per module configs are available, we'll use the
    # location as the tag for the new features.  --- Aha!  No longer!
    # Modules can now specify the new feature tags.

    my ($feature,$output_bounds);
    my $location = $self->getModule()->location();

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

sub startImage {
    my ($self,$image) = @_;
    $self->SUPER::startImage($image);

    print STDERR "FindBounds->startImage\n";

    if (!$self->isIteratingFeatures()) {
        my $image = $self->getCurrentImage();
        my $pixels = $image->DefaultPixels();

        $self->createBounds(0,0,$pixels->SizeX(),$pixels->SizeY());
    }
}

sub startFeature {
    my ($self,$feature) = @_;
    $self->SUPER::startFeature($feature);

    print STDERR "FindBounds->startFeature\n";

    my $input_bounds = $self->getCurrentInputAttributes('Input bounds')->[0];
    $self->createBounds($input_bounds->X(),$input_bounds->Y(),
                        $input_bounds->Width(),$input_bounds->Height());

}

1;
