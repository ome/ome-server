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

=head1 NAME

OME::Analysis::Handler - the superclass of all analysis handlers

=head1 SYNOPSIS

	use OME::Analysis::Handler;
	my $handler = OME::Analysis::Handler->new($location,$session,
	                                          $program,$node);

=head1 DESCRIPTION

The analysis handlers are the chief mechanism supporting language
independence in the modules of the analysis system.  The handlers
serve to decouple the details of interfacing with a given language
from the analysis engine, and to decouple the common functionality of
interacting with the database away from the analysis modules.

The Handler class follows the same interface that the analysis engine
expects of its modules; in this way, the handlers can be seen as
delegate classes, deferring to the analysis module itself to perform
the actual calculations.

=cut

use strict;
our $VERSION = '1.0';

use fields qw(_location _session _node
              _program _formal_inputs _formal_outputs _actual_outputs
              _current_dataset _current_image _current_feature
              _dataset_inputs _image_inputs _feature_inputs
              _dataset_outputs _image_outputs _feature_outputs
              _last_new_feature);

=head1 METHODS

=head2 new

	my $handler = OME::Analysis::Handler->
	    new($location,$session,$program,$node);

Creates a new instance of the analysis handler.  Subclass constructors
I<must> call this as part of their construction code.  The helper
methods used to create new attributes for the analysis results will
not work without the variables assigned by this method.

=cut

sub new {
    my ($proto,$location,$session,$program,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{_location} = $location;
    $self->{_session} = $session;
    $self->{_program} = $program;
    $self->{_node} = $node;

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

=head2 Session and Factory

	my $session = $handler->Session();
	my $factory = $handler->Factory();

Returns the OME database session associated with the handler, and the
factory associated with that session, respectively.  These are used
internally to control access to the OME database.

=cut

sub Session {
    my ($self) = @_;
    return $self->{_session};
}

sub Factory {
    my ($self) = @_;
    return $self->{_session}->Factory();
}

=head2 getCurrentDataset, getCurrentImage, and getCurrentFeature

	my $dataset = $handler->getCurrentDataset();
	my $image = $handler->getCurrentImage();
	my $feature = $handler->getCurrentFeature();

These methods can be used by Handler subclasses during the execution
of the analysis module.  They return the dataset, image, and feature
that is currently being analyzed by the module.  As the module
progresses through th e methods defined by the Module interface, the
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

=head2 getFormalInput and getFormalOutput

	my $input = $handler->getFormalInput($input_name);
	my $output = $handler->getFormalOutput($output_name);

These methods can be used to access the formal inputs and outputs of
the module being executed.  They are referred to by name.

=cut

sub getFormalInput {
    my ($self,$input_name) = @_;
    return $self->{_formal_inputs}->{$input_name};
}

sub getFormalOutput {
    my ($self,$output_name) = @_;
    return $self->{_formal_outputs}->{$output_name};
}

=head2 getDatasetInputs, getImageInputs, and getFeatureInputs

	my $input_array = $handler->getDatasetInputs($input_name);
	my $input_array = $handler->getImageInputs($input_name);
	my $input_array = $handler->getFeatureInputs($input_name);

Returns the attributes passed in as actual inputs for the specified
formal input.  The method call used must match the granularity of the
formal input specified, otherwise an error is raised.  The actual
inputs are returned as a list of Attribute objects of the attribute
type corresponding to the formal input.  The values of each attribute
can be accessed (but not changed) via methods of the same name as the
column in question.

=cut

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

=head2 newFeature

	my $feature = $handler->newFeature($name);

Creates a new feature for use as an actual output of this module.  The
name of the feature is specified as input.  The tag of the feature is
determined by the analysis chain to which this module belongs.  New
feature attributes are associated with this feature via the
newAttribute method.

=cut

sub newFeature {
    my ($self,$name) = @_;

    my $new_feature_tag = $self->{_node}->new_feature_tag();
    die "This module says it won't create features!"
      unless (defined $new_feature_tag);

    my $parent_feature = undef;

    if (defined $self->{_node}->iterator_tag()) {
        # This should be undefined if the iterator tag is
        # undefined, but for now, I'll be sure.
        $parent_feature = $self->{_current_feature};
    }

    my $data =
      {
       image          => $self->{_current_image},
       tag            => $new_feature_tag,
       name           => $name,
       parent_feature => $parent_feature
      };

    my $feature = $self->Factory()->newObject("OME::Feature",$data);
    $self->{_last_new_feature} = $feature;
    return $feature;
}

=head2 newAttributes

	my $attribute = $handler->
	    newAttributes($self,[$output_name,$data]...);

Creates a set of new attributes as outputs of the current module.  The
formal output and attribute data is specified for each attribute to be
created.  The data is specified by a hash mapping attribute column
names to values.  The target of the attribute is determined
automatically.  In the case of dataset and image outputs, the new
attribute is automatically targeted to the currently analyzed dataset
and image.  In the case of feature outputs, there are three
possibilities.  The new attribute can be targeted to the current
feature, the current feature's parent, or a new feature created by the
module.  The feature actually used is determined by the analysis chain
that the module appears in.

Any attributes created via this method will automatically be returned
to the analysis engine when the collectFeatureOutputs,
collectImageOutputs, and collectDatasetOutputs methods are called.
Subclasses need not reimplement this functionality.

If more than one attribute is specified in the call to newAttributes,
then the attributes in question will be stored in a single row in each
of the data tables.  If two attributes refer to the same column in a
data table, then the values in each attribute must be the same.  If
not, an error is raised and no attributes are created.

=cut

sub newAttribute {
    my ($self,%attribute_info) = @_;

    my %data;
    my %granularities;
    my %targets;

    foreach my $formal_output_name (keys %attribute_info) {
        my $formal_output = $self->{_formal_outputs}->{$output_name};
        my $attribute_type = $formal_output->attribute_type();
        my @attribute_columns = $attribute_type->attribute_columns();
        my $granularity = $attribute_type->attribute_type();
        my $data_hash = $attribute_info{$formal_output_name};

        foreach my $column (@attribute_columns) {
            my $data_column = $column->data_column();
            my $column_name = $data_column->column_name();
            my $data_table = $data_column->data_table();
            my $table_name = $data_table->table_name();
            my $data_granularity = $data_table->granularity();
            my $attribute_name = $column->name();

            die "Attribute granularity and data table granularity don't match!"
                if ($granularity ne $data_granularity);

            #$data->{actual_output_id} = $self->{_actual_outputs}->{$output_name};
            if ($granularity eq 'D') {
                $targets{$table_name} = $self->{_current_dataset};
                $data{$table_name}->{dataset_id} = $self->{_current_dataset};
            } elsif ($granularity eq 'I') {
                $targets{$table_name} = $self->{_current_image};
                $data{$table_name}->{image_id} = $self->{_current_image};
            } elsif ($granularity eq 'F') {
                my $feature_tag = $formal_output->feature_tag();
                die "Cannot create an untagged feature!"
                    unless (defined $feature_tag);

                my $feature;

                if ($feature_tag eq '[Iterator]') {
                    $feature = $self->{_current_feature};
                } elsif ($feature_tag eq '[Feature]') {
                    $feature = $self->{_last_new_feature};
                } elsif ($feature_tag eq '[Parent]') {
                    my $last_new = $self->{_last_new_feature};
                    $feature = $last_new->parent_feature() if (defined $last_new);
                } else {
                    die "Invalid feature tag for new feature attribute: $feature_tag\n";
                }

                die "Desired feature ($feature_tag) does not exist"
                    unless defined $feature;

                if (exists $granularities{$table_name}) {
                    my $previous_feature = $targets{$table_name};
                    die "Attribute feature targets clash"
                        if ($previous_feature->id() ne $feature->id());
                }

                $targets{$table_name} = $feature;
                $data{$table_name}->{feature_id} = $feature;
            }

            %granularities{$table_name} = granularity;

            my $new_data = $data_hash->{$attribute_name};

            if (exists $data{$table_name}->{$column_name}) {
                my $old_data = $data{$table_name}->{$column_name};
                die "Attribute values clash"
                    if ($new_data ne $old_data);
            }

            $data{$table_name}->{$column_name} = $new_data;
        }
    }

    my @attributes;

    foreach my $table_name (keys %data) {
        my $attribute = $self->Factory()->
            newAttribute($table_name,$data{$table_name});

        if ($granularities{$table_name} eq 'D') {
            push @{$self->{_dataset_outputs}->{$output_name}}, $attribute;
        } elsif ($granularities{$table_name} eq 'I') {
            push @{$self->{_image_outputs}->{$output_name}}, $attribute;
        } elsif ($granularities{$table_name} eq 'F') {
            push @{$self->{_feature_outputs}->{$output_name}}, $attribute;
        }

        push @attributes, $attribute;
    }

    return \@attributes;
}


=head2 Module interface methods

	$handler->startAnalysis($actual_outputs);
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

These are the methods defined by the Module interface.  Handler
subclasses should override the precalculateDataset, precalculateImage,
calculateFeature, postcalculateImage, and postcalculateDataset methods
to delegate to the module in question.  The other methods maintain the
internal state of the Handler superclass, and should not be
overridden.  Subclasses can use the accessors and methods described
above to access the current state of the module and to create outputs
as it progresses through these interface methods.

=cut

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
