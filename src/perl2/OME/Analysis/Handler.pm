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

use Log::Agent;
use OME::DataTable;
use OME::AttributeType;
use Benchmark qw(timediff timesum timestr);

use fields qw(_location _session _node
              _program _formal_inputs _formal_outputs _analysis
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

sub __debug {
    #logdbg "info", @_;
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
    if (exists $self->{_formal_inputs}->{$input_name}) {
        return $self->{_formal_inputs}->{$input_name};
    } else {
        die "$input_name is not a formal input"
    }
}

sub getFormalOutput {
    my ($self,$output_name) = @_;
    if (exists $self->{_formal_outputs}->{$output_name}) {
        return $self->{_formal_outputs}->{$output_name};
    } else {
        die "$output_name is not a formal output"
    }
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
    if (exists $self->{_dataset_inputs}->{$input_name}) {
        return $self->{_dataset_inputs}->{$input_name}
    } else {
        die "$input_name does not exist, or it is not a dataset input";
    }
}

sub getImageInputs {
    my ($self,$input_name) = @_;
    if (exists $self->{_image_inputs}->{$input_name}) {
        return $self->{_image_inputs}->{$input_name};
    } else {
        die "$input_name does not exist, or it is not an image input";
    }
}

sub getFeatureInputs {
    my ($self,$input_name) = @_;
    if (exists $self->{_feature_inputs}->{$input_name}) {
        return $self->{_feature_inputs}->{$input_name};
    } else {
        die "$input_name does not exist, or it is not an feature input";
    }
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

    # Find the tag for the new feature.  If this tag is undefined,
    # then the module declares that it won't create features, causing
    # this method call to be illegal.

    my $new_feature_tag = $self->{_node}->new_feature_tag();
    die "This module says it won't create features!"
      unless (defined $new_feature_tag);

    # Find the feature that will be the new feature's parent.  If the
    # module is iterating over features, then the new feature will be
    # a child of the currently analyzed feature.  Otherwise, the new
    # feature will not have a parent.

    my $parent_feature = undef;

    if (defined $self->{_node}->iterator_tag()) {
        # _current_feature should be undefined if the iterator tag is
        # undefined, since we won't be looping through features.  That
        # would make the if test above unnecessary, but for now, I'll
        # be overly cautious.

        $parent_feature = $self->{_current_feature};
    }

    # Create the feature object

    my $data =
      {
       image          => $self->{_current_image},
       tag            => $new_feature_tag,
       name           => $name,
       parent_feature => $parent_feature
      };
    my $feature = $self->Factory()->newObject("OME::Feature",$data);

    # Save the feature object so that new feature attributes can be
    # keyed to it.

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

sub newAttributes {
    my ($self,%attribute_info) = @_;

    my $t0 = new Benchmark;

    # These hashes are keyed by table name.
    my %data_tables;
    my %data;
    my %targets;
    my %granularities;
    my %feature_tags;
    my %formal_outputs;

    # These hashes are keyed by attribute type ID.
    my %attribute_tables;

    # Merge the attribute data hashes into hashes for each data table.
    # Also, mark which data tables belong to each attribute.

    my @new_attribute_info;
    my %granularityColumns = 
      (
       'G' => undef,
       'D' => 'dataset_id',
       'I' => 'image_id',
       'F' => 'feature_id'
      );

    foreach my $formal_output_name (keys %attribute_info) {
        my $formal_output = $self->{_formal_outputs}->{$formal_output_name};
        my $attribute_type = $formal_output->attribute_type();
        my $granularity = $attribute_type->granularity();
        my $data_hash = $attribute_info{$formal_output_name};

        $formal_outputs{$attribute_type->id()} = $formal_output;

        __debug("  $formal_output_name");

        if ($granularity eq 'D') {
            $data_hash->{dataset_id} = $self->{_current_dataset};
        } elsif ($granularity eq 'I') {
            $data_hash->{image_id} = $self->{_current_image};
        } elsif ($granularity eq 'F') {
            my $feature_tag = $formal_output->feature_tag();
            die "Cannot create an untagged feature attribute!"
              unless (defined $feature_tag);

            # The special tags are used to specify which feature a
            # new attribute belongs to.  All of the possibilites
            # have been stored in local fields, so we just have to
            # pick out the right one.

            my $target;

            if ($feature_tag eq '[Iterator]') {
                $target = $self->{_current_feature};
            } elsif ($feature_tag eq '[Feature]') {
                $target = $self->{_last_new_feature};
            } elsif ($feature_tag eq '[Parent]') {
                my $last_new = $self->{_last_new_feature};
                $target = $last_new->parent_feature() if (defined $last_new);
            } else {
                die "Invalid feature tag for new feature attribute: $feature_tag";
            }

            # Every feature attribute must refer to a some feature.

            die "Desired feature ($feature_tag) does not exist"
                unless defined $target;

            $data_hash->{feature_id} = $target;
        }

        push @new_attribute_info, $attribute_type, $data_hash;
    }

    my $attributes = OME::AttributeType->newAttributes($self->{_analysis},
                                                       @new_attribute_info);

    foreach my $attribute (@$attributes) {
        my $attribute_type = $attribute->_attribute_type();
        my $formal_output = $formal_outputs{$attribute_type->id()};
        my $formal_output_name = $formal_output->name();
        my $granularity = $attribute_type->granularity();

        # Save this new attribute as an actual output of the
        # appropriate formal output.  The
        # collect[Dataset/Image/Feature]Outputs method will return
        # these lists, so subclasses using this method will
        # automatically fulfill that part of the contract.

        if ($granularity eq 'G') {
            die "Global attributes not allowed in analysis modules!";
        } elsif ($granularity eq 'D') {
            push @{$self->{_dataset_outputs}->{$formal_output_name}}, $attribute;
        } elsif ($granularity eq 'I') {
            push @{$self->{_image_outputs}->{$formal_output_name}}, $attribute;
        } elsif ($granularity eq 'F') {
            push @{$self->{_feature_outputs}->{$formal_output_name}}, $attribute;
        }
    }

    my $t1 = new Benchmark;
    my $td = timediff($t1,$t0);

    if (exists $self->{_timing}) {
        $self->{_timing} = timesum($self->{_timing},$td);
    } else {
        $self->{_timing} = $td;
    }

    return $attributes;
}


=head2 Module interface methods

	$handler->startAnalysis($analysis);
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
    my ($self,$analysis) = @_;
    $self->{_analysis} = $analysis;
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

    #print STDERR "newAttributes:\n".timestr($self->{_timing})."\n"
    #    if exists $self->{_timing};
}


=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Tasks::AnalysisEngine|OME::Tasks::AnalysisEngine>

=cut

1;
