# OME/Analysis/Handlers/DefaultLoopHandler.pm

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

package OME::Analysis::Handlers::DefaultLoopHandler;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Analysis::Handler;
use OME::Analysis::Engine::FeatureHierarchy;

use base qw(OME::Analysis::Handler);

use fields qw(_current_dataset _current_image _current_feature
              _last_new_feature);

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

sub getLastNewFeature {
    my ($self) = @_;
    return $self->{_last_new_feature};
}

sub getCurrentActualInputs {
    my ($self,$which) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $input = UNIVERSAL::isa($which,'OME::Module::FormalInput')?
      $which:
      $self->getFormalInput($which);
    my $type = $input->semantic_type();
    my $granularity = $type->granularity();

    my $criteria = {
                    module_execution => $self->getModuleExecution(),
                    formal_input     => $input,
                   };

    # If the granularity is dataset, image, or feature, limit the list
    # of actual inputs to those whose input module executions point to
    # the current dataset, image, or image. (not a typo)

    if ($granularity eq 'D') {
        $criteria->{'input_module_execution.dataset'} =
          $self->getCurrentDataset();
    } elsif ($granularity eq 'I') {
        $criteria->{'input_module_execution.image'} =
          $self->getCurrentImage();
    } elsif ($granularity eq 'F') {
        $criteria->{'input_module_execution.image'} =
          $self->getCurrentImage();
    }

    my @actual_inputs = $factory->
      findObjects('OME::ModuleExecution::ActualInput',$criteria);

    return \@actual_inputs;
}

sub getCurrentInputAttributes {
    my ($self,$which,$criteria) = @_;

    my $input = UNIVERSAL::isa($which,'OME::Module::FormalInput')?
      $which:
      $self->getFormalInput($which);
    my $type = $input->semantic_type();
    my $granularity = $type->granularity();

    my $actual_inputs = $self->getActualInputs($input);
    my @input_mexes = map { $_->input_module_execution() } @$actual_inputs;

    # Extend the search criteria to limit to the current image or
    # feature, if the granularity is appropriate.  If there is no
    # current feature, and we're searching for feature attributes, limit
    # to the current image.  We don't need to restrict the criteria for
    # dataset attributes, since we should never be executing against
    # more than one dataset.

    if ($granularity eq 'I') {
        $criteria->{image} = $self->getCurrentImage();
    } elsif ($granularity eq 'F') {
        my $feature = $self->getCurrentFeature();
        if (defined $feature) {
            $criteria->{feature} = $feature;
        } else {
            $criteria->{'feature.image'} = $self->getCurrentImage();
        }
    }

    return $self->getInputAttributes($input,$criteria);
}

sub newFeature {
    my ($self,$name) = @_;

    my $image = $self->getCurrentImage();
    die "Cannot create a feature -- there is no current image"
      unless defined $image;

    # Find the tag for the new feature.  If this tag is undefined,
    # then the module declares that it won't create features, causing
    # this method call to be illegal.

    my $new_feature_tag = $self->getModuleExecution()->new_feature_tag();
    die "This module says it won't create features!"
      unless (defined $new_feature_tag && $new_feature_tag ne "");
    die "Invalid feature tag"
      if ($new_feature_tag =~ /[{}]/);

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
        $parent_feature = $self->getCurrentFeature();
    } elsif ($new_feature_tag =~ /^\[Sibling\:([^:\[\]]+)\]$/) {
        $tag = $1;
        my $current = $self->getCurrentFeature();
        die "Cannot create a feature which is a sibling of the image"
          unless defined $current;
        $parent_feature = $current->parent_feature();
    } elsif ($new_feature_tag =~ /^\[Root\:([^:\[\]]+)\]$/) {
        $tag = $1;
        $parent_feature = undef;
    } elsif ($new_feature_tag =~ /^([^{}:\[\]]+)$/) {
        $tag = $1;
        $parent_feature = $self->getCurrentFeature();
    } else {
        die "Invalid feature tag";
    }

    my $feature = OME::Session->instance()->Factory()->
      newObject("OME::Feature",
                {
                 image          => $image,
                 tag            => $tag,
                 name           => $name,
                 parent_feature => $parent_feature
                });
    $self->{_last_new_feature} = $feature;

    return $feature;
}

sub __modifyAttributeInfo {
    my ($self,$attribute_info) = @_;

    $attribute_info = $self->SUPER::__modifyAttributeInfo($attribute_info);

    # Find any attribute hashes which need targets, but do not have
    # them.  Add the current target (dataset, image, or feature, as
    # appropriate) to the attribute hash.

  ATTRIBUTE:
    foreach my $info (@$attribute_info) {
        my ($formal_output, $semantic_type, $data_hash) = @$info;
        my $granularity = $semantic_type->granularity();

        if ($granularity eq 'D') {
            next ATTRIBUTE
              if defined $data_hash->{target};

            $info->[2]->{target} = $self->getCurrentDataset();
        } elsif ($granularity eq 'I') {
            next ATTRIBUTE
              if defined $data_hash->{target};

            $info->[2]->{target} = $self->getCurrentImage();
        } elsif ($granularity eq 'F') {
            next ATTRIBUTE
              if defined $data_hash->{target};

            my $feature_tag = $formal_output->feature_tag();
            die "Cannot create an untagged feature attribute!"
              unless (defined $feature_tag);

            # The special tags are used to specify which feature a
            # new attribute belongs to.  All of the possibilites
            # have been stored in local fields, so we just have to
            # pick out the right one.

            my $target;

            if ($feature_tag eq '[Iterator]') {
                $target = $self->getCurrentFeature();
            } elsif ($feature_tag eq '[Feature]') {
                $target = $self->getLastNewFeature();
            } elsif ($feature_tag eq '[Parent]') {
                my $last_new = $self->getLastNewFeature();
                $target = $last_new->parent_feature() if (defined $last_new);
            } else {
                die "Invalid feature tag for new feature attribute: $feature_tag";
            }

            # Every feature attribute must refer to a some feature.

            die "Desired feature ($feature_tag) does not exist"
                unless defined $target;

            $info->[2]->{target} = $target;
        }
    }

    return $attribute_info;
}


# Checks a hash of inputs to make sure that they match the cardinality
# constraints specified by the appropriate formal input.

sub __checkInputParameters {
    my ($self, $granularity) = @_;
    my $factory = OME::Session->instance()->Factory();

    my @inputs = $factory->
      findObjects('OME::Module::FormalInput',
                  {
                   module                      => $self->getModule(),
                   'semantic_type.granularity' => $granularity,
                  });

    foreach my $input (@inputs) {
        my $formal_input_name = $input->name();
        my $semantic_type = $input->semantic_type();

        my $optional = $input->optional();
        my $list = $input->list();

        # Don't bother checking if there are no constraints.
        next if ($optional && $list);

        # Only try to pull two attributes out of the iterator, since
        # that's enough to check the cardinality constraints.

        my $values = $self->getCurrentInputAttributes($input);
        my $cardinality = scalar(@$values);

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

	$handler->executeGlobal();
	$handler->startDataset($dataset);
	$handler->startImage($image);
	$handler->startFeature($feature);
	$handler->finishFeature();
	$handler->finishImage();
	$handler->finishDataset();

These are the methods defined by the Module interface.  Handler
subclasses should override the executeGlobal, startDataset, startImage,
startFeature, finishFeature, finishImage, finishDataset methods to
delegate to the module in question.  The other methods maintain the
internal state of the Handler superclass, and should not be overridden. 
Subclasses can use the accessors and methods described above to access
the current state of the module and to create outputs as it progresses
through these interface methods.

=cut

sub executeGlobal {
    my ($self) = @_;
}

sub startDataset {
    my ($self,$dataset) = @_;
    $self->{_current_dataset} = $dataset;
}


sub startImage {
    my ($self,$image) = @_;
    $self->{_current_image} = $image;
}


sub startFeature {
    my ($self,$feature) = @_;
    $self->{_current_feature} = $feature;
}


sub finishFeature {
    my ($self) = @_;
    $self->{_current_feature} = undef;
}


sub finishImage {
    my ($self) = @_;
    $self->{_current_image} = undef;
}


sub finishDataset {
    my ($self) = @_;
    $self->{_current_dataset} = undef;
}


sub __imageLoop {
    my ($self,$image) = @_;
    my $session = OME::Session->instance();
    my $mex = $self->getModuleExecution();

    $self->startImage($image);

    if (defined $mex->iterator_tag()) {
        my $hierarchy = OME::Analysis::Engine::FeatureHierarchy->
          new($mex,$image);
        my $iterator_features = $hierarchy->
          findIteratorFeatures($mex->iterator_tag());

        foreach my $feature (@$iterator_features) {
            $self->startFeature($feature);
            $self->finishFeature();
        }
    }

    $self->finishImage();

}


sub execute {
    my ($self,$dependence,$target) = @_;

    my $module_execution = $self->getModuleExecution();
    my $module = $self->getModule();

    if ($dependence eq 'G') {
        $self->executeGlobal();
    } elsif ($dependence eq 'D') {
        $self->startDataset($target);

        # We can't use the ->images() method, b/c we want to iterate
        # through the images, and only keep one in memory at a time.

        my $image_links = $target->image_links();
        while (my $image_link = $image_links->next()) {
            my $image = $image_link->image();
            $self->__imageLoop($image);
        }

        $self->finishDataset();
    } elsif ($dependence eq 'I') {
        # This module is image-dependent, so the dataset which the
        # image belongs to cannot be important, and there cannot be
        # any dataset inputs.  Therefore, we don't call the
        # startDataset or datasetInput methods.

        $self->__imageLoop($target);
    }
}

1;
