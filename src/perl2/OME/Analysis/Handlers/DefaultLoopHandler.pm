# OME/Analysis/Handler.pm

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

package OME::Analysis::DefaultLoopHandler;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Analysis::Handler;
use OME::Analysis::FeatureHierarchy;

use base qw(OME::Analysis::Handler);

use fields qw(_current_dataset _current_image _current_feature
              _global_inputs _dataset_inputs _image_inputs _feature_inputs
              _global_outputs _dataset_outputs _image_outputs _feature_outputs);

=head2 getCurrentDataset, getCurrentImage, and getCurrentFeature

	my $dataset = $handler->getCurrentDataset();
	my $image = $handler->getCurrentImage();
	my $feature = $handler->getCurrentFeature();

These methods can be used by Handler subclasses during the execution
of the analysis module.  They return the dataset, image, and feature
that is currently being analyzed by the module.  As the module
progresses through the methods defined by the Module interface, the
values these methods return are automatically updated.

=cut

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


# Checks a hash of inputs to make sure that they match the cardinality
# constraints specified by the appropriate formal input.

sub __checkInputParameters {
    my ($self, $params, $granularity) = @_;

    foreach my $param (@{$self->{_inputs_by_granularity}->{$granularity}}) {
        my $formal_input_name = $param->name();
        my $semantic_type = $param->semantic_type();

        my $optional = $param->optional();
        my $list = $param->list();

        # Don't bother checking if there are no constraints.
        next if ($optional && $list);

        my $values = $params->{$formal_input_name};
        my $cardinality = (defined $values)? scalar(@$values): 0;

        die "$formal_input_name is not optional"
          if (($cardinality == 0) && (!$optional));

        die "$formal_input_name cannot be a list"
          if (($cardinality > 1) && (!$list));
    }
}

# Checks a hash of outputs to make sure that they match the cardinality
# constraints specified by the appropriate formal output.  Note that the
# output attributes are not actually saved, just a count of them.

sub __checkOutputParameters {
    my ($self, $params, $granularity) = @_;

    foreach my $param (@{$self->{_outputs_by_granularity}->{$granularity}}) {
        my $formal_output_name = $param->name();
        my $semantic_type = $param->semantic_type();

        # We don't check untyped outputs.  They can be anything.
        next if
          (!defined $semantic_type);

        my $optional = $param->optional();
        my $list = $param->list();

        # Don't bother checking if there are no constraints.
        next if ($optional && $list);

        my $values = $params->{$formal_output_name};

        if ($granularity eq 'G') {
            # For global outputs, the $params input is a hash a la:
            # $params->{$formal_output_name} => $cardinality

            my $cardinality = $values || 0;

            #print STDERR "      $formal_output_name ($cardinality)\n";

            die "$formal_output_name is not optional"
              if (($cardinality == 0) && (!$optional));

            die "$formal_output_name cannot be a list"
              if (($cardinality > 1) && (!$list));
        } else {
            # For all other outputs, the $params input is a hash a la:
            # $params->{$formal_output_name}->{$target_id} => $cardinality

            foreach my $target_id (keys %$values) {
                my $cardinality = $values->{$target_id} || 0;

                #print STDERR "      $formal_output_name $granularity$target_id ($cardinality)\n";

                die "$formal_output_name is not optional"
                  if (($cardinality == 0) && (!$optional));

                die "$formal_output_name cannot be a list"
                  if (($cardinality > 1) && (!$list));
            }
        }

    }
}

=head2 Module interface methods

	$handler->startAnalysis($module_execution);
	$handler->globalInputs($global_input_hash);
	$handler->precalculateGlobal();
	$handler->startDataset($dataset);
	$handler->datasetInputs($dataset_input_hash);
	$handler->precalculateDataset();
	$handler->startImage($image);
	$handler->imageInputs($image_input_hash);
	$handler->precalculateImage();
	$handler->startFeature($feature);
	$handler->featureInputs($feature_input_hash);
	$handler->calculateFeature();
	my $feature_output_hash = $handler->collectFeatureOutputs();
	$handler->finishFeature();
	$handler->postcalculateImage();
	my $image_output_hash = $handler->collectImageOutputs();
	$handler->finishImage();
	$handler->postcalculateDataset();
	my $dataset_output_hash = $handler->collectDatasetOutputs();
	$handler->finishDataset();
	$handler->postcalculateGlobal();
	my $global_output_hash = $handler->collectGlobalOutputs();
	$handler->finishAnalysis();

These are the methods defined by the Module interface.  Handler
subclasses should override the precalculateGlobal,
precalculateDataset, precalculateImage, calculateFeature,
postcalculateImage, postcalculateDataset, and postcalculateGlobal
methods to delegate to the module in question.  The other methods
maintain the internal state of the Handler superclass, and should not
be overridden.  Subclasses can use the accessors and methods described
above to access the current state of the module and to create outputs
as it progresses through these interface methods.

=cut

sub globalInputs {
    my ($self,$inputHash) = @_;
    $self->__checkInputParameters($inputHash,'G');
    $self->{_global_inputs} = $inputHash;
}

sub precalculateGlobal {
    my ($self) = @_;
}

sub startDataset {
    my ($self,$dataset) = @_;
    $self->{_current_dataset} = $dataset;
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
    $self->__checkInputParameters($inputHash,'D');
    $self->{_dataset_inputs} = $inputHash;
}


sub precalculateDataset {
    my ($self) = @_;
}


sub startImage {
    my ($self,$image) = @_;
    $self->{_current_image} = $image;
}


sub imageInputs {
    my ($self,$inputHash) = @_;
    $self->__checkInputParameters($inputHash,'I');
    $self->{_image_inputs} = $inputHash;
}

sub precalculateImage {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
    $self->{_current_feature} = $feature;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
    $self->__checkInputParameters($inputHash,'F');
    $self->{_feature_inputs} = $inputHash;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    my $hash = $self->{_feature_outputs};
    $self->__checkOutputParameters($hash,'F');
    return 1;
}


sub finishFeature {
    my ($self) = @_;
    $self->{_current_feature} = undef;
    $self->{_feature_inputs} = undef;
}


sub postcalculateImage {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    my $hash = $self->{_image_outputs};
    $self->__checkOutputParameters($hash,'I');
    return 1;
}


sub finishImage {
    my ($self) = @_;
    $self->{_current_image} = undef;
    $self->{_image_inputs} = undef;
    $self->{_feature_outputs} = undef;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    my $hash = $self->{_dataset_outputs};
    $self->__checkOutputParameters($hash,'D');
    return 1;
}


sub finishDataset {
    my ($self) = @_;
    $self->{_current_dataset} = undef;
    $self->{_dataset_inputs} = undef;
    $self->{_image_outputs} = undef;

    #print STDERR "newAttributes:\n".timestr($self->{_timing})."\n"
    #    if exists $self->{_timing};
}


sub postcalculateGlobal {
    my ($self) = @_;
}

sub collectGlobalOutputs {
    my ($self) = @_;
    my $hash = $self->{_global_outputs};
    $self->__checkOutputParameters($hash,'G');
    return 1;
}

sub __getInputs {
    my ($self,$input,$input_execution,$target,$target_name) = @_;
    $target_name ||= "target";
    my $factory = $self->{_session}->Factory();

    my $semantic_type = $input->semantic_type();
    my $criteria = { module_execution => $input_execution };

    if (defined $target) {
        $criteria->{$target_name} =
          (ref($target) eq 'ARRAY')?
          ['in',$target]: $target;
    }

    my @inputs = $factory->findAttributes($semantic_type,$criteria);
    return \@inputs;
}

sub __feedGlobalInputs {
    my ($self,$inputs) = @_;

    my $curr_global_inputs  = $self->{_inputs_by_granularity}->{G};

    my %global_hash;
    foreach my $input (@$curr_global_inputs) {
        my $input_execution = $inputs->{$input->id()};
        $global_hash{$input->name()} = $self->
          __getInputs($input,$input_execution,undef);
    }

    $self->globalInputs(\%global_hash);
}

sub __feedDatasetInputs {
    my ($self,$inputs) = @_;

    my $curr_dataset_inputs = $self->{_inputs_by_granularity}->{D};

    my %dataset_hash;
    foreach my $input (@$curr_dataset_inputs) {
        my $input_execution = $inputs->{$input->id()};
        $dataset_hash{$input->name()} = $self->
          __getInputs($input,$input_execution,undef);
    }

    $self->datasetInputs(\%dataset_hash);
}

sub __feedImageInputs {
    my ($self,$inputs,$image) = @_;

    my $curr_image_inputs = $self->{_inputs_by_granularity}->{I};

    my %image_hash;
    foreach my $input (@$curr_image_inputs) {
        my $input_execution = $inputs->{$input->id()};
        $image_hash{$input->name()} = $self->
          __getInputs($input,$input_execution,$image);
    }

    $self->imageInputs(\%image_hash);
}

sub __feedFeatureInputs {
    my ($self,$inputs,$target) = @_;

    my $curr_feature_inputs = $self->{_inputs_by_granularity}->{F};
    my $target_name =
      UNIVERSAL::isa($target,"OME::Image")?
        "target.image": "target";

    my %feature_hash;
    foreach my $input (@$curr_feature_inputs) {
        my $input_execution = $inputs->{$input->id()};
        $feature_hash{$input->name()} = $self->
          __getInputs($input,$input_execution,$target,$target_name);
    }

    $self->featureInputs(\%feature_hash);
}

sub __imageLoop {
    my ($self,$image,$inputs) = @_;
    my $node = $self->{_node};
    my $chain_execution = $self->{_chain_execution};
    my $session = $self->{_session};

    $self->startImage($image);
    $self->__feedImageInputs($inputs,$image);
    $self->precalculateImage();

    if (defined $node->iterator_tag()) {
        my $hierarchy = OME::Analysis::FeatureHierarchy->
          new($session,$chain_execution,$node,$image);
        my $iterator_features = $hierarchy->
          findIteratorFeatures($node->iterator_tag());

        foreach my $feature (@$iterator_features) {
            $self->startFeature(undef);
            $self->__feedFeatureInputs($inputs,$feature);
            $self->calculateFeature();
            $self->finishFeature();
        }
    } else {
        $self->startFeature(undef);
        $self->__feedFeatureInputs($inputs,$image);
        $self->calculateFeature();
        $self->finishFeature();
    }

    $self->postcalculateImage();
    $self->finishImage();

}


sub execute {
    my ($self,$dependence,$target,$inputs) = @_;
    my $module_execution = $self->{_module_execution};
    my $module = $self->{_module};
    my $node = $self->{_node};
    my $dataset = $self->{_dataset};
    my $chain_execution = $self->{_chain_execution};

    my $factory = $self->{_session}->Factory();

    my $curr_global_inputs  = $self->{_inputs_by_granularity}->{G};
    my $curr_dataset_inputs = $self->{_inputs_by_granularity}->{D};
    my $curr_image_inputs   = $self->{_inputs_by_granularity}->{I};
    my $curr_feature_inputs = $self->{_inputs_by_granularity}->{F};

    $self->__feedGlobalInputs($inputs);
    $self->precalculateGlobal();

    if ($dependence eq 'G') {
        $self->postcalculateGlobal();
        $self->collectGlobalOutputs();

    } elsif ($dependence eq 'D') {
        $self->startDataset($dataset);
        $self->__feedDatasetInputs($inputs);
        $self->precalculateDataset();

        my $image_links = $dataset->image_links();
        while (my $image_link = $image_links->next()) {
            my $image = $image_link->image();
            $self->__imageLoop($image,$inputs);
        }

        $self->postcalculateDataset();
        $self->collectDatasetOutputs();

        $self->postcalculateGlobal();
        $self->collectGlobalOutputs();

    } elsif ($dependence eq 'I') {
        # This module is image-dependent, so the dataset which the
        # image belongs to cannot be important, and there cannot be
        # any dataset inputs.  Therefore, we don't call the
        # startDataset or datasetInput methods.
        $self->precalculateDataset();

        foreach my $image_id (@$target) {
            my $image = $factory->loadObject("OME::Image",$image_id);
            $self->__imageLoop($image,$inputs);
        }

        $self->postcalculateDataset();
        $self->collectDatasetOutputs();

        $self->postcalculateGlobal();
        $self->collectGlobalOutputs();
    }
}

1;
