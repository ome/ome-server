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

use fields qw(_location _factory
              _program _formal_inputs _formal_outputs _actual_outputs
              _current_dataset _current_image _current_feature
              _dataset_inputs _image_inputs _feature_inputs
              _dataset_outputs _image_outputs _feature_outputs);

sub new {
    my ($proto,$location,$factory,$program) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{_location} = $location;
    $self->{_factory} = $factory;
    $self->{_program} = $program;

    my $inputs = {};
    foreach my $formal_input ($program->inputs()) {
        $inputs->{$formal_input->name()} = $formal_input;
    }
    $self->{_formal_inputs} = $inputs;

    my $outputs = {};
    foreach my $formal_input ($program->outputs()) {
        $outputs->{$formal_input->name()} = $formal_input;
    }
    $self->{_formal_outputs} = $outputs;

    bless $self, $class;
    return $self;
}

sub getCurrentDataset {
    my ($self) = @_;
    return $self->{_current_dataset};
}

sub getCurrentImage {
    my ($self) = @_;
    return $self->{_current_image};
}

sub getCurrentFeature {
    my ($self) = @_;
    return $self->{_current_feature};
}

sub getFormalInput {
    my ($self,$input_name) = @_;
    return $self->{_formal_inputs}->{$input_name};
}

sub getFormalOutput {
    my ($self,$output_name) = @_;
    return $self->{_formal_outputs}->{$output_name};
}

sub getDatasetInputs {
    my ($self,$input_name) = @_;
    return $self->{_dataset_inputs}->{$input_name};
}

sub getImageInputs {
    my ($self,$input_name) = @_;
    return $self->{_image_inputs}->{$input_name};
}

sub getFeatureInputs {
    my ($self,$input_name) = @_;
    return $self->{_feature_inputs}->{$input_name};
}

sub newFeature {
    my ($self,$tag) = @_;

    my $data = {
        image => $self->{_current_image},
        tag   => $tag
        };

    my $feature = $self->{_factory}->newObject("OME::Feature",$data);
}

sub newAttribute {
    my ($self,$output_name,$data) = @_;
    my $formal_output = $self->{_formal_outputs}->{$output_name};
    my $datatype = $formal_output->datatype();
    my $table_name = $datatype->table_name();
    my $granularity = $datatype->attribute_type();

    my $featureID;
    
    $data->{actual_output_id} = $self->{_actual_outputs}->{$output_name};
    if ($granularity eq 'D') {
        $data->{dataset_id} = $self->{_current_dataset};
    } elsif ($granularity eq 'I') {
        $data->{image_id} = $self->{_current_image};
    } elsif ($granularity eq 'F') {
        $featureID = $data->{feature_id};
        #$data->{feature_id} = $self->{_current_feature};
    }
    
    my $attribute = $self->{_factory}->newAttribute($table_name,$data);

    if ($granularity eq 'D') {
        push @{$self->{_dataset_outputs}->{$output_name}}, $attribute;
    } elsif ($granularity eq 'I') {
        push @{$self->{_image_outputs}->{$output_name}}, $attribute;
    } elsif ($granularity eq 'F') {
        push @{$self->{_feature_outputs}->{$output_name}->{$featureID}}, $attribute;
    }

    return $attribute;
}


sub startAnalysis {
    my ($self,$actual_outputs) = @_;
    $self->{_actual_outputs} = $actual_outputs;
}

sub startDataset {
    my ($self,$dataset) = @_;
    $self->{_current_dataset} = $dataset;
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
    $self->{_dataset_inputs} = $inputHash;
}


sub precalculateDataset() {
    my ($self) = @_;
}


sub startImage {
    my ($self,$image) = @_;
    $self->{_current_image} = $image;
}


sub imageInputs {
    my ($self,$inputHash) = @_;
    $self->{_image_inputs} = $inputHash;
}

sub precalculateImage() {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
    $self->{_current_feature} = $feature;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
    $self->{_feature_inputs} = $inputHash;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    return $self->{_feature_outputs};
}


sub finishFeature {
    my ($self) = @_;
    $self->{_current_feature} = undef;
    $self->{_feature_inputs} = undef;
    $self->{_feature_outputs} = undef;
}


sub postcalculateImage() {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    return $self->{_image_outputs};
}


sub finishImage {
    my ($self) = @_;
    $self->{_current_image} = undef;
    $self->{_image_inputs} = undef;
    $self->{_image_outputs} = undef;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return $self->{_dataset_outputs};
}


sub finishDataset {
    my ($self) = @_;
    $self->{_current_dataset} = undef;
    $self->{_dataset_inputs} = undef;
    $self->{_dataset_outputs} = undef;
}


1;
