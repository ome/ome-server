# OME/Analysis/PerlHandler.pm

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


package OME::Analysis::PerlHandler;

use strict;
our $VERSION = '1.0';

use base qw(OME::Analysis::Handler);

use fields qw(_instance);

sub new {
    my ($proto,$location,$factory,$program) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$factory,$program);
    eval "require $location";
    $self->{_instance} = $location->new($factory);

    bless $self,$class;
    return $self;
}


sub startDataset {
    my ($self,$dataset) = @_;
    return $self->{_instance}->startDataset($dataset);
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
    return $self->{_instance}->datasetInputs($inputHash);
}


sub precalculateDataset {
    my ($self) = @_;
    return $self->{_instance}->precalculateDataset();
}


sub startImage {
    my ($self,$image) = @_;
    return $self->{_instance}->startImage($image);
}


sub imageInputs {
    my ($self,$inputHash) = @_;
    return $self->{_instance}->imageInputs($inputHash);
}


sub precalculateImage {
    my ($self) = @_;
    return $self->{_instance}->precalculateImage();
}


sub startFeature {
    my ($self,$feature) = @_;
    return $self->{_instance}->startFeature($feature);
}


sub featureInputs {
    my ($self,$inputHash) = @_;
    return $self->{_instance}->featureInputs($inputHash);
}


sub calculateFeature {
    my ($self) = @_;
    return $self->{_instance}->calculateFeature();
}


sub collectFeatureOutputs {
    my ($self) = @_;
    return $self->{_instance}->collectFeatureOutputs();
}


sub finishFeature {
    my ($self) = @_;
    return $self->{_instance}->finishFeature();
}


sub postcalculateImage {
    my ($self) = @_;
    return $self->{_instance}->postcalculateImage();
}


sub collectImageOutputs {
    my ($self) = @_;
    return $self->{_instance}->collectImageOutputs();
}


sub finishImage {
    my ($self) = @_;
    return $self->{_instance}->finishImage();
}


sub postcalculateDataset {
    my ($self) = @_;
    return $self->{_instance}->postcalculateDataset();
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return $self->{_instance}->collectDatasetOutputs();
}


sub finishDataset {
    my ($self) = @_;
    return $self->{_instance}->finishDataset();
}


1;
