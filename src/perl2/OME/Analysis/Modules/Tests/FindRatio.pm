# OME/module_execution/FindRatio.pm

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


package OME::Analysis::FindRatio;

use OME::Analysis::DefaultLoopHandler;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Analysis::DefaultLoopHandler);


sub calculateFeature {
    my ($self) = @_;

    my $numerator_features = $self->getFeatureInputs('Golgi bounds');
    my $denominator_features = $self->getFeatureInputs('Mito bounds');

    my $numerator = scalar(@$numerator_features);
    my $denominator = scalar(@$denominator_features);

    no integer;
    my $ratio = ($denominator == 0)? 0: $numerator/$denominator;
    use integer;

    my $ratio_attribute = $self->
      newAttributes("Golgi-mito ratio",
                    {
                     Ratio => $ratio
                    });
}

1;
