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


package OME::Analysis::Handler;

=head1 NAME

OME::Analysis::Handler - the superclass of all analysis handlers

=head1 SYNOPSIS

	use OME::Analysis::Handler;
	my $handler = OME::Analysis::Handler->new($mex);

=head1 OVERVIEW

Analysis handlers serve several purposed in the OME analysis engine.
First, they provide a means of factoring common functionality out of
several analysis modules.  This is used chiefly for the language
independence of the analysis engine -- which are written in the same
external language will usually share an analysis handler.

Second, analysis handlers define the "glue" code between the analysis
engine and the analysis modules.  In the case of an external module,
it is the handler which is responsible for loading and executing the
external module.  The handler also defines how data is passed between
the OME database and the external module.

=head1 ANALYSIS HANDLER INTERFACE

Analysis handlers are simply Perl classes written to the interface
defined by this class.  Since Perl is not a strongly-typed language,
analysis handler classes are not required to be direct subclasses of
C<OME::Analysis::Handler>.  However, this class provides several
helper methods which make it unlikely that it is ever worth the effort
of writing an analysis handler from scratch.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
use OME::Session;
use OME::DataTable;
use OME::SemanticType;
use OME::Tasks::ModuleExecutionManager;

use Carp;

use fields qw(_module_execution
              _global_outputs_allowed);

=head1 METHODS

=head2 new

	my $handler = OME::Analysis::Handler->new($mex);

Creates a new instance of the analysis handler.  Subclass constructors
I<must> call this as part of their construction code.  The helper
methods used to create new attributes for the module results will
not work without the variables assigned by this method.

=cut

sub new {
    my ($proto,$module_execution) = @_;
    my $class = ref($proto) || $proto;

    my $module = $module_execution->module();

    my $self = {};
    $self->{_module_execution} = $module_execution;

    my $factory = OME::Session->instance()->Factory();

    # Determine whether or not this module can create global outputs.
    # (It can as long as all of its inputs are of global granularity.)

    $self->{_global_outputs_allowed} = !$factory->
      objectExists('OME::Module::FormalInput',
                   {
                    module                      => $module,
                    'semantic_type.granularity' => ['<>','G'],
                   });

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

sub Session { return OME::Session->instance(); }
sub Factory { return OME::Session->instance()->Factory(); }

sub getModuleExecution { return shift->{_module_execution}; }
sub getDependence { return shift->{_module_execution}->dependence(); }

sub isIteratingFeatures {
    my $tag = shift->{_module_execution}->iterator_tag();
    return defined $tag && $tag ne "";
}

sub getModule { return shift->{_module_execution}->module(); }

=head2 getFormalInput and getFormalOutput

	my $input = $handler->getFormalInput($input_name);
	my $output = $handler->getFormalOutput($output_name);

These methods can be used to access the formal inputs and outputs of
the module being executed.  They are referred to by name.

=cut

sub getFormalInput {
    my ($self,$input_name) = @_;

    Carp::cluck "***** getFormalInput($input_name)"
      unless defined $input_name;

    my $factory = OME::Session->instance()->Factory();
    return $factory->
      findObject('OME::Module::FormalInput',
                 {
                  module => $self->getModule(),
                  name   => $input_name,
                 });
}

sub getFormalOutput {
    my ($self,$which) = @_;
    my $factory = OME::Session->instance()->Factory();
    my $criteria = {
                    module => $self->getModule(),
                   };

    $criteria->{semantic_type} = $which
      if (UNIVERSAL::isa($which,'OME::SemanticType'));

    $criteria->{name} = $which
      if !ref($which);

    return $factory->
      findObject('OME::Module::FormalOutput',$criteria);
}

sub getUntypedFormalOutput {
    my ($self) = @_;
    my $factory = OME::Session->instance()->Factory();
    return $factory->
      findObject('OME::Module::FormalOutput',
                 {
                  module        => $self->getModule(),
                  semantic_type => undef,
                 });
}

sub getFormalInputsByGranularity {
    my ($self,$granularity) = @_;
    my $factory = OME::Session->instance()->Factory();
    return $factory->
      findObjects('OME::Module::FormalInput',
                  {
                   module                      => $self->getModule(),
                   'semantic_type.granularity' => $granularity,
                  });
}

sub getActualInputs {
    my ($self,$which) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $input = UNIVERSAL::isa($which,'OME::Module::FormalInput')?
      $which:
      $self->getFormalInput($which);

    my @actual_inputs = $factory->
      findObjects('OME::ModuleExecution::ActualInput',
                  {
                   module_execution => $self->getModuleExecution(),
                   formal_input     => $input,
                  });

    return \@actual_inputs;
}

=head2 getInputAttributes

	my $input_array = $handler->getInputAttributes($which,$criteria);

Returns the attributes passed in as actual inputs for the specified
formal input.  The method call used must match the granularity of the
formal input specified, otherwise an error is raised.  The actual
inputs are returned as a list of Attribute objects of the attribute
type corresponding to the formal input.  The values of each attribute
can be accessed (but not changed) via methods of the same name as the
column in question.

=cut

sub getInputAttributes {
    my ($self,$which,$criteria) = @_;
    return unless defined wantarray;

    my $input = UNIVERSAL::isa($which,'OME::Module::FormalInput')?
      $which:
      $self->getFormalInput($which);

    my $actual_inputs = $self->getActualInputs($input);
    my @input_mexes = map { $_->input_module_execution() } @$actual_inputs;

    my $inputs = OME::Tasks::ModuleExecutionManager->
      getAttributesForMEX(\@input_mexes,$input->semantic_type(),$criteria);

    if (wantarray) {
        return @$inputs;
    } else {
        return $inputs;
    }
}

sub newFeature {
    my ($self,$name,$image,$parent_feature) = @_;

    # Find the tag for the new feature.  If this tag is undefined,
    # then the module declares that it won't create features, causing
    # this method call to be illegal.

    my $new_feature_tag = $self->getModuleExecution()->new_feature_tag();
    die "This module says it won't create features!"
      unless (defined $new_feature_tag && $new_feature_tag ne "");
    die "Invalid feature tag"
      unless ($new_feature_tag =~ /^[^{}:\[\]]+$/);

    my $feature = OME::Session->instance()->Factory()->
      newObject("OME::Feature",
                {
                 image          => $image,
                 tag            => $new_feature_tag,
                 name           => $name,
                 parent_feature => $parent_feature
                });

    return $feature;
}

=head2 newAttributes

	my $attribute = $handler->
	    newAttributes([$semantic_type,$data]...);

	# or

	my $attribute = $handler->
	    newAttributes([$formal_output_name,$data]...);

	# or

	my $attribute = $handler->
	    newAttributes([$formal_output,$data]...);

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

sub __expandAttributeInfo {
    my ($self,$attribute_info) = @_;

    my @new_attribute_info;

    my $i;
    my $length = scalar(@$attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        my $key = $attribute_info->[$i];
        my $data_hash = $attribute_info->[$i+1];
        my ($semantic_type,$formal_output,$formal_output_name);

        if (!ref($key)) {
            # This is a string, treat it as a formal input name.
            $formal_output_name = $key;
            $formal_output = $self->getFormalOutput($formal_output_name);
            $semantic_type = $formal_output->semantic_type();
        } elsif (UNIVERSAL::isa($key,"OME::SemanticType")) {
            # This is a semantic type
            $semantic_type = $key;
            $formal_output =
              $self->getFormalOutput($semantic_type) ||
              $self->getUntypedFormalOutput();

            die "Cannot find a formal output for semantic type ".
              $semantic_type->name()
              unless defined $formal_output;

            $formal_output_name = $formal_output->name();
        } elsif (UNIVERSAL::isa($key,"OME::Module::FormalOutput")) {
            # This is a formal output object
            $formal_output = $key;
            $formal_output_name = $formal_output->name();
            $semantic_type = $formal_output->semantic_type();
            die "$formal_output_name is untyped -- you must specify the semantic type explicitly"
              unless defined $semantic_type;
        } else {
            # We don't know how to handle this
            die "Illegal argument; must be formal input name or attribute type";
        }

        #print "  $formal_output_name\n";
        my $granularity = $semantic_type->granularity();

        if ($granularity eq 'G') {
            die "This module is not allowed to create global attributes"
              unless $self->{_global_outputs_allowed};
        }

        push @new_attribute_info, [$formal_output, $semantic_type, $data_hash];
    }

    return \@new_attribute_info;
}

sub __modifyAttributeInfo {
    my ($self,$attribute_info) = @_;

    # Make sure that any target specified in the hash is specified in
    # the "target" column, not "dataset", or "dataset_id", or anything
    # like that.

  ATTRIBUTE:
    foreach my $info (@$attribute_info) {
        my ($formal_output, $semantic_type, $data_hash) = @$info;
        my $granularity = $semantic_type->granularity();

        if ($granularity eq 'D') {
            if (defined $data_hash->{target}) {
                # Nothing special
            } elsif (defined $data_hash->{dataset}) {
                $info->[2]->{target} = $data_hash->{dataset};
            } elsif (defined $data_hash->{dataset_id}) {
                $info->[2]->{target} = $data_hash->{dataset_id};
            }

            delete $info->[2]->{dataset};
            delete $info->[2]->{dataset_id};
        } elsif ($granularity eq 'I') {
            if (defined $data_hash->{target}) {
                # Nothing special
            } elsif (defined $data_hash->{image}) {
                $info->[2]->{target} = $data_hash->{image};
            } elsif (defined $data_hash->{image_id}) {
                $info->[2]->{target} = $data_hash->{image_id};
            }

            delete $info->[2]->{image};
            delete $info->[2]->{image_id};
        } elsif ($granularity eq 'F') {
            if (defined $data_hash->{target}) {
                # Nothing special
            } elsif (defined $data_hash->{feature}) {
                $info->[2]->{target} = $data_hash->{feature};
            } elsif (defined $data_hash->{feature_id}) {
                $info->[2]->{target} = $data_hash->{feature_id};
            }

            delete $info->[2]->{feature};
            delete $info->[2]->{feature_id};
        }
    }

    return $attribute_info;
}

sub __normalizeAttributeInfo {
    my ($self,$attribute_info) = @_;

    my @new_attribute_info = map { $_->[1], $_->[2] } @$attribute_info;
    return \@new_attribute_info;
}

sub __newAttributesWorker {
    my ($self,$normalized_attribute_info) = @_;

    my $attributes = OME::SemanticType->
      newAttributes($self->Session(),
                    $self->{_module_execution},
                    @$normalized_attribute_info);

    return $attributes;
}

sub newAttributes {
    my $self = shift;
    my $expanded = $self->__expandAttributeInfo(\@_);
    my $modified = $self->__modifyAttributeInfo($expanded);
    my $normalized = $self->__normalizeAttributeInfo($modified);
    return $self->__newAttributesWorker($normalized);
}


sub startAnalysis {
    my ($self) = @_;
}

sub execute {
    my ($self,$dependence,$target) = @_;
    die "OME::Analysis::Handler->execute is abstract";
}

sub finishAnalysis {
    my ($self) = @_;
}

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Analysis::AnalysisEngine|OME::Analysis::AnalysisEngine>

=cut

1;
