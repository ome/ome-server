# OME/Analysis/FindBounds.pm

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

package OME::Analysis::FindBounds;

use OME::Analysis::Handler;

use strict;
our $VERSION = '1.0';

use base qw(OME::Analysis::Handler);


sub createBounds {
    my ($self,$x1,$y1,$w,$h) = @_;
    my $xw = $w/2;
    my $yh = $h/2;

    # As a hack until per module configs are available, we'll
    # use the location as the tag for the new features.

    my ($feature,$output_bounds);
    my $location = $self->{_location};

    $feature = $self->newFeature($location,lc($location)." 1");
    $output_bounds = $self->
      newAttribute("Output bounds",
                   {
                    x          => $x1,
                    y          => $y1,
                    width      => $xw,
                    height     => $yh,
                    feature_id => $feature->id()
                   });

    $feature = $self->newFeature($location,lc($location)." 2");
    $output_bounds = $self->
      newAttribute("Output bounds",
                   {
                    x          => $x1+$xw,
                    y          => $y1,
                    width      => $xw,
                    height     => $yh,
                    feature_id => $feature->id()
                   });

    $feature = $self->newFeature($location,lc($location)." 3");
    $output_bounds = $self->
      newAttribute("Output bounds",
                   {
                    x          => $x1,
                    y          => $y1+$yh,
                    width      => $xw,
                    height     => $yh,
                    feature_id => $feature->id()
                   });

    $feature = $self->newFeature($location,lc($location)." 4");
    $output_bounds = $self->
      newAttribute("Output bounds",
                   {
                    x          => $x1+$xw,
                    y          => $y1+$yh,
                    width      => $xw,
                    height     => $yh,
                    feature_id => $feature->id()
                   });
}


sub calculateFeature {
    my ($self) = @_;

    if (defined $self->{_node}->iterator_tag()) {
        my $input_bounds = $self->getFeatureInputs('Input bounds')->[0];
        $self->createBounds($input_bounds->x(),$input_bounds->y(),
                            $input_bounds->width(),$input_bounds->height());
    } else {
        my $image = $self->getCurrentImage();
        my $dims = $image->Dimensions();

        $self->createBounds(0,0,$dims->size_x(),$dims->size_y());
    }

}
