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

OME::Analysis::Handler - the superclass of all module_execution handlers

=head1 SYNOPSIS

	use OME::Analysis::Handler;
	my $handler = OME::Analysis::Handler->new($location,$session,
	                                          $module,$node);

=head1 DESCRIPTION

The module_execution handlers are the chief mechanism supporting language
independence in the modules of the module_execution system.  The handlers
serve to decouple the details of interfacing with a given language
from the analysis engine, and to decouple the common functionality of
interacting with the database away from the modules.

The Handler class follows the same interface that the analysis engine
expects of its modules; in this way, the handlers can be seen as
delegate classes, deferring to the module itself to perform
the actual calculations.

=cut

use strict;
our $VERSION = 2.000_000;

use Log::Agent;
use OME::DataTable;
use OME::SemanticType;
use Benchmark qw(timediff timesum timestr);

use fields qw(_location _session _node _output_types _untyped_output
              _module _formal_inputs _formal_outputs _module_execution
              _inputs_by_granularity
              _current_dataset _current_image _current_feature
              _global_inputs _dataset_inputs _image_inputs _feature_inputs
              _global_outputs _dataset_outputs _image_outputs _feature_outputs
              _global_outputs_allowed
              _last_new_feature);

=head1 METHODS

=head2 new

	my $handler = OME::Analysis::Handler->
	    new($location,$session,$module,$node);

Creates a new instance of the module_execution handler.  Subclass constructors
I<must> call this as part of their construction code.  The helper
methods used to create new attributes for the module results will
not work without the variables assigned by this method.

=cut

sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{_location} = $location;
    $self->{_session} = $session;
    $self->{_module} = $module;
    $self->{_node} = $node;

    # Hash the formal inputs by name and by granularity, so they can
    # be accessed quickly.  At the same time, determine whether or not
    # this module can create global outputs.  (It can as long as all of
    # its input are of global granularity.)

    my $globalOutputsAllowed = 1;

    my $inputs = {};
    my $granularity_inputs = {};

    foreach my $formal_input ($module->inputs()) {
        $inputs->{$formal_input->name()} = $formal_input;
        my $granularity = $formal_input->semantic_type()->granularity();
        push @{$granularity_inputs->{$granularity}}, $formal_input;
        if ($granularity ne 'G') {
            $globalOutputsAllowed = 0;
        }
    }
    $self->{_formal_inputs} = $inputs;
    $self->{_global_outputs_allowed} = $globalOutputsAllowed;
    $self->{_inputs_by_granularity} = $granularity_inputs;

    # Hash the formal outputs by name, and by attribute type.  If there
    # is an untyped formal output, save it.

    my %outputs;
    my %types;
    my $untyped_output;
    my $granularity_outputs = {};

    foreach my $formal_output ($module->outputs()) {
        $outputs{$formal_output->name()} = $formal_output;
        my $semantic_type = $formal_output->semantic_type();
        if (!defined $semantic_type) {
            die "Cannot have two untyped outputs!"
              if defined $untyped_output;
            $untyped_output = $formal_output;
        } else {
            die "Cannot have two outputs of the same type!"
              if exists $types{$semantic_type->id()};
            $types{$semantic_type->id()} = $formal_output;
            my $granularity = $semantic_type->granularity();
            push @{$granularity_outputs->{$granularity}}, $formal_output;
        }
    }
    $self->{_formal_outputs} = \%outputs;
    $self->{_output_types} = \%types;
    $self->{_untyped_output} = $untyped_output;
    $self->{_outputs_by_granularity} = $granularity_outputs;

    bless $self, $class;
    return $self;
}

sub __debug {
    #logdbg "info", @_;
    #print STDERR @_,"\n";
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

sub getGlobalInputs {
    my ($self,$input_name) = @_;
    if (exists $self->{_global_inputs}->{$input_name}) {
        return $self->{_global_inputs}->{$input_name}
    } else {
        die "$input_name does not exist, or it is not a global input";
    }
}

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
    my ($self,$name,$parent) = @_;

    # Find the tag for the new feature.  If this tag is undefined,
    # then the module declares that it won't create features, causing
    # this method call to be illegal.

    my $new_feature_tag = $self->{_node}->new_feature_tag();
    die "This module says it won't create features!"
      unless (defined $new_feature_tag && $new_feature_tag ne "");

    # Find the feature that will be the new feature's parent.  If the
    # module is iterating over features, then the new feature will be
    # a child of the currently analyzed feature.  Otherwise, the new
    # feature will not have a parent.

    my $parent_feature = undef;

    # Four possibilities:
    #   [Child:TAG]   - create a new feature of tag TAG, as a
    #                   child of the current feature
    #   [Sibling:TAG] - create a new feature of tag TAG, as a
    #                   sibling of the current feature
    #   [Root:TAG]    - create a new feature of tag TAG, as a
    #                   child of the image
    #   TAG           - shorthand for [Child:TAG]

    my $tag;
    if ($new_feature_tag =~ /^\[Child\:([^:\[\]]+)\]$/) {
        $tag = $1;
        $parent_feature = $self->{_current_feature};
    } elsif ($new_feature_tag =~ /^\[Sibling\:([^:\[\]]+)\]$/) {
        $tag = $1;
        my $current = $self->{_current_feature};
        die "Cannot create a feature which is a sibling of the image"
          unless defined $current;
        $parent_feature = $current->parent_feature();
    } elsif ($new_feature_tag =~ /^\[Root\:([^:\[\]]+)\]$/) {
        $tag = $1;
        $parent_feature = undef;
    } elsif ($new_feature_tag =~ /^([^:\[\]]+)$/) {
        $tag = $1;
        $parent_feature = $self->{_current_feature};
    } else {
        die "Invalid feature tag";
    }

    # Create the feature object

    my $data =
      {
       image          => $self->{_current_image},
       tag            => $tag,
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
	    newAttributes($self,[$semantic_type,$data]...);

	# or

	my $attribute = $handler->
	    newAttributes($self,[$formal_output_name,$data]...);

Creates a set of new attributes as outputs of the current module.  The
formal output or attribute type and attribute data is specified for
each attribute to be created.  The data is specified by a hash mapping
attribute column names to values.  The target of the attribute is
determined automatically.  In the case of dataset and image outputs,
the new attribute is automatically targeted to the currently analyzed
dataset and image.  In the case of feature outputs, there are three
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
    my ($self,@attribute_info) = @_;

    # These hashes are keyed by table name.
    my %data_tables;
    my %data;
    my %targets;
    my %granularities;
    my %feature_tags;

    # These hashes are keyed by attribute type ID.
    my %attribute_tables;

    # Merge the attribute data hashes into hashes for each data table.
    # Also, mark which data tables belong to each attribute.

    my $t0 = new Benchmark;

    my @new_attribute_info;
    my %granularityColumns = 
      (
       'G' => undef,
       'D' => 'dataset_id',
       'I' => 'image_id',
       'F' => 'feature_id'
      );

    my $output_types = $self->{_output_types};
    my $i;
    my $length = scalar(@attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        my $key = $attribute_info[$i];
        my $data_hash = $attribute_info[$i+1];
        my ($semantic_type,$formal_output,$formal_output_name);

        if (!ref($key)) {
            # This is a string, treat it as a formal input name.
            $formal_output_name = $key;
            $formal_output = $self->{_formal_outputs}->{$formal_output_name};
            $semantic_type = $formal_output->semantic_type();
        } elsif (UNIVERSAL::isa($key,"OME::SemanticType")) {
            # This is an attribute type
            $semantic_type = $key;

            $formal_output =
              (exists $output_types->{$semantic_type->id()})?
                $output_types->{$semantic_type->id()}:
                  $self->{_untyped_output};

            die "Cannot find a formal output for semantic type ".
              $semantic_type->name()
                unless defined $formal_output;

            $formal_output_name = $formal_output->name();
        } else {
            # We don't know how to handle this
            die "Illegal argument; must be formal input name or attribute type";
        }

        __debug("  $formal_output_name");
        my $granularity = $semantic_type->granularity();

        if ($granularity eq 'G') {
            die "This module is not allowed to create global attributes"
              unless $self->{_global_outputs_allowed};
        } elsif ($granularity eq 'D') {
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

        push @new_attribute_info, $semantic_type, $data_hash;
    }

    my $t1 = new Benchmark;

    OME::SemanticType->__addOneTime('_sortTime',timediff($t1,$t0));

    my $attributes = OME::SemanticType->newAttributes($self->Session(),
                                                       $self->{_module_execution},
                                                       @new_attribute_info);

    $self->__saveAttributes($attributes);
    return $attributes;
}

=head2 newAttributesWithTargets

	my $attribute = $handler->
	    newAttributesWithTargets($self,[$semantic_type,$data]...);

	# or

	my $attribute = $handler->
	    newAttributesWithTargets($self,[$formal_output_name,$data]...);

Creates a set of new attributes as outputs of the current module.  The
formal output or attribute type and attribute data is specified for
each attribute to be created.  The data is specified by a hash mapping
attribute column names to values.  The target of the attributes must
be specified in the data hashes.

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

sub newAttributesWithTargets {
    my ($self,@attribute_info) = @_;

    # These hashes are keyed by table name.
    my %data_tables;
    my %data;
    my %targets;
    my %granularities;
    my %feature_tags;

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

    my $output_types = $self->{_output_types};
    my $i;
    my $length = scalar(@attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        my $key = $attribute_info[$i];
        my $data_hash = $attribute_info[$i+1];
        my ($semantic_type,$formal_output,$formal_output_name);

        if (!ref($key)) {
            # This is a string, treat it as a formal input name.
            $formal_output_name = $key;
            $formal_output = $self->{_formal_outputs}->{$formal_output_name};
            $semantic_type = $formal_output->semantic_type();
        } elsif (UNIVERSAL::isa($key,"OME::SemanticType")) {
            # This is an attribute type
            $semantic_type = $key;

            $formal_output =
              (exists $output_types->{$semantic_type->id()})?
                $output_types->{$semantic_type->id()}:
                $self->{_untyped_output};

            die "Cannot find a formal output for semantic type ".
              $semantic_type->name()
                unless defined $formal_output;

            $formal_output_name = $formal_output->name();
        } else {
            # We don't know how to handle this
            die "Illegal argument; must be formal input name or attribute type";
        }

        __debug("  $formal_output_name");
        my $granularity = $semantic_type->granularity();

        if ($granularity eq 'G') {
            die "This module is not allowed to create global attributes"
              unless $self->{_global_outputs_allowed};
        } elsif ($granularity eq 'D') {
            die "Need a dataset for this attribute"
              unless defined $data_hash->{target};
            $data_hash->{dataset_id} = $data_hash->{target};
            delete $data_hash->{target};
        } elsif ($granularity eq 'I') {
            die "Need an image for this attribute"
              unless defined $data_hash->{target};
            $data_hash->{image_id} = $data_hash->{target};
            delete $data_hash->{target};
        } elsif ($granularity eq 'F') {
            die "Need a feature for this attribute"
              unless defined $data_hash->{target};
            $data_hash->{feature_id} = $data_hash->{target};
            delete $data_hash->{target};
        }

        push @new_attribute_info, $semantic_type, $data_hash;
    }

    my $attributes = OME::SemanticType->newAttributes($self->Session(),
                                                       $self->{_module_execution},
                                                       @new_attribute_info);

    $self->__saveAttributes($attributes);
    return $attributes;
}

# A helper method used to save any attributes created by the analysis module.

sub __saveAttributes {
    my ($self,$attributes) = @_;
    my $formal_outputs = $self->{_output_types};

    foreach my $attribute (@$attributes) {
        my $semantic_type = $attribute->_attribute_type();
        my $formal_output = $formal_outputs->{$semantic_type->id()};
        if (!defined $formal_output) {
            # There is no typed formal output for this attribute type,
            # so we must use the untyped formal output.  If there is no
            # untyped formal output, this is an error.  This error
            # should have been caught by now, so this is would be a
            # double-secret-bad error.
            $formal_output = $self->{_untyped_output};
            die "Can't find formal output in __saveAttributes"
              unless defined $formal_output;
        }
        my $foID = $formal_output->id();
        my $foName = $formal_output->name();
        my $granularity = $semantic_type->granularity();

        # Save this new attribute as an actual output of the
        # appropriate formal output.  The
        # collect[Dataset/Image/Feature]Outputs method will return
        # these lists, so subclasses using this method will
        # automatically fulfill that part of the contract.

        #print STDERR "--- $formal_output_name $granularity\n";

        my $target = $attribute->_getTarget();

        if ($granularity eq 'G') {
            $self->{_global_outputs}->{$foName}++;
        } elsif ($granularity eq 'D') {
            $self->{_dataset_outputs}->{$foName}->{$target->id()}++;
        } elsif ($granularity eq 'I') {
            $self->{_image_outputs}->{$foName}->{$target->id()}++;
        } elsif ($granularity eq 'F') {
            $self->{_feature_outputs}->{$foName}->{$target->id()}++;
        }
    }
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

sub startAnalysis {
    my ($self,$module_execution) = @_;
    $self->{_module_execution} = $module_execution;
    OME::SemanticType->__resetTiming();
}

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

sub finishAnalysis {
    my ($self) = @_;
    $self->{_dataset_outputs} = undef;
    $self->{_global_outputs} = undef;

    my $module_execution = $self->{_module_execution};
    return unless defined $module_execution;
    $module_execution->attribute_sort_time(OME::SemanticType->__getSeconds('_sortTime'));
    $module_execution->attribute_db_time(OME::SemanticType->__getSeconds('_dbTime'));
    $module_execution->attribute_create_time(OME::SemanticType->__getSeconds('_createTime'));
    $module_execution->storeObject();
}


=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Tasks::AnalysisEngine|OME::Tasks::AnalysisEngine>

=cut

1;
