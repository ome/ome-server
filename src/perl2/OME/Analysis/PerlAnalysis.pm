# OME/Analysis/PerlAnalysis.pm

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


package OME::Analysis::PerlAnalysis;

use strict;
our $VERSION = '1.0';


use fields qw(_factory
	      _currentDataset _currentImage _currentFeature
	      _datasetInputs  _imageInputs  _featureInputs
	      _datasetOutputs  _imageOutputs  _featureOutputs);

sub new {
    my ($proto,$factory) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{_factory} = $factory;

    $self->{_currentDataset} = undef;
    $self->{_datasetInputs} = undef;
    $self->{_datasetOutputs} = undef;

    $self->{_currentImage} = undef;
    $self->{_imageInputs} = undef;
    $self->{_imageOutputs} = undef;

    $self->{_currentFeature} = undef;
    $self->{_featureInputs} = undef;
    $self->{_featureOutputs} = undef;

    bless $self,$class;
    return $self;
}


sub startDataset {
    my ($self,$dataset) = @_;
    $self->{_currentDataset} = $dataset;
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
    $self->{_datasetInputs} = $inputHash;
}


sub precalculateDataset {
    my ($self) = @_;
}


sub startImage {
    my ($self,$image) = @_;
    $self->{_currentImage} = $image;
}


sub imageInputs {
    my ($self,$inputHash) = @_;
    $self->{_imageInputs} = $inputHash;
}


sub precalculateImage {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
    $self->{_currentFeature} = $feature;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
    $self->{_featureInputs} = $inputHash;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    return $self->{_featureOutputs};
}


sub finishFeature {
    my ($self) = @_;
    $self->{_currentFeature} = undef;
    $self->{_featureInputs} = undef;
    $self->{_featureOutputs} = undef;
}


sub postcalculateImage {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    return $self->{_imageOutputs};
}


sub finishImage {
    my ($self) = @_;
    $self->{_currentImage} = undef;
    $self->{_imageInputs} = undef;
    $self->{_imageOutputs} = undef;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return $self->{_datasetOutputs};
}


sub finishDataset {
    my ($self) = @_;
    $self->{_currentDataset} = undef;
    $self->{_datasetInputs} = undef;
    $self->{_datasetOutputs} = undef;
}


1;
