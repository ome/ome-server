# OME/Analysis/Handler.pm

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


package OME::Analysis::Handler;

use strict;
our $VERSION = '1.0';

use fields qw(_location _factory _program);

sub new {
    my ($proto,$location,$factory,$program) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{_location} = $location;
    $self->{_factory} = $factory;
    $self->{_program} = $program;

    bless $self, $class;
    return $self;
}


sub startDataset {
    my ($self,$dataset) = @_;
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
}


sub precalculateDataset() {
    my ($self) = @_;
}


sub startImage {
    my ($self,$image) = @_;
}


sub imageInputs {
    my ($self,$inputHash) = @_;
}

sub precalculateImage() {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    return {};
}


sub finishFeature {
    my ($self) = @_;
}


sub postcalculateImage() {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    return {};
}


sub finishImage {
    my ($self) = @_;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return {};
}


sub finishDataset {
    my ($self) = @_;
}


1;
