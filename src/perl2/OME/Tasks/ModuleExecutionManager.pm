# OME/Tasks/ModuleExecutionManager.pm

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


package OME::Tasks::ModuleExecutionManager;

=head1 NAME

OME::Tasks::ModuleExecutionManager - Workflow methods for handling
module executions

=head1 SYNOPSIS

	my $mex = OME::Tasks::ModuleExecutionManager->
	    createMEX($module,$dependence,$target);
	my $actual_input = OME::Tasks::ModuleExecutionManager->
	    addActualInput($output_mex,$input_mex,$formal_input);
	my @attributes = OME::Tasks::ModuleExecutionManager->
	    getAttributesForMEX($mex,$semantic_type);

=head1 DESCRIPTION

This class contains methods for handling module executions.  Each time
an analysis module is executed (whether or not this is performed by
the analysis engine), a module execution is created.  Module
executions form the glue of the data dependency tree.  Each attribute
records which module execution created it, and module executions
record how the formal inputs of the module were satisfied with actual
values.

Module executions have a property called "dependence", which is
similar in meaning to an attribute's granularity.  With few
exceptions, the granularity of an attribute is the same as the
dependence of the module execution which created it.

An image-dependent module execution implies that the results of that
module are independent of the dataset which was being analyzed.  If
the same module is executed again, with the same parameters, against
the same image, an image-dependent module is guaranteed to produce the
same results, I<even if the image is being analyzed as part of a
completely different dataset>.

A dataset-dependent module execution does not make this guarantee.  It
implies that the results of the module, even if they are image
attributes, somehow depend on the entire dataset.  Therefore, if the
module is executed again, with the same parameters, against the same
image, but in a different dataset, the module might generate different
results.

Module executions can be completely represented by an "input tag".
This input tag encapsulates the entire state of the module execution
into a single string.  It is used by the analysis engine to determine
attribute reuse.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;

use OME::Session;
use OME::Module;
use OME::ModuleExecution;
use OME::ModuleExecution::VirtualMEXMap;
use OME::SemanticType;
use OME::AnalysisChainExecution;

=head1 METHODS

NOTE: Several of these methods create new database objects.  None of
them commit any database transactions.

=head2 createMEX

	my $mex = OME::Tasks::ModuleExecutionManager->
	    createMEX($module,$dependence,$target,
	              $iterator_tag,$new_feature_tag);

Creates a new module execution of the given module.  It is marked as
having the given dependence and target.  The $dependence parameter
should be either 'G', 'D', or 'I'.  Some basic sanity checking is
performed.  If $dependence is 'G', $target should be undefined.  (It
will be ignored.)  If $dependence is 'D', $target should be an
instance of OME::Dataset.  If $dependence is 'I', $target should be an
instance of OME::Image.  If this is not the case, an error is thrown.

This method does I<not> check whether the specified dependence is
valid for the specified module.  For one thing, this is not entirely
defined until all of the actual inputs are specified.  For another,
it's often unnecessary, and slows down this method.  To perform this
check, call the B<***asYetUnwritten***> method.

If the $iterator_tag or $new_feature_tag parameters are given, then
they provide values for the MEX fields of the same name.  If either is
undefined, that value is copied from the default_iterator or
new_feature_tag column, respectively, of the module.

=cut

sub createMEX {
    my $class = shift;
    my ($module,$dependence,$target,$iterator_tag,$new_feature_tag) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    Carp::cluck "Undefined module" unless defined $module;

    my $dataset = ($dependence eq 'D')? $target: undef;
    my $image = ($dependence eq 'I')? $target: undef;

    # If either the iterator tag or new feature tag isn't specified,
    # get its value from the module.

    $iterator_tag ||= $module->default_iterator();
    $new_feature_tag ||= $module->new_feature_tag();

    my $mex = $factory->
      newObject("OME::ModuleExecution",
                {
                 module          => $module,
                 dependence      => $dependence,
                 dataset         => $dataset,
                 image           => $image,
                 iterator_tag    => $iterator_tag,
                 new_feature_tag => $new_feature_tag,
                 timestamp       => 'now',
                 status          => 'UNFINISHED',
                 experimenter    => $session->UserState()->experimenter(),
                });

    return $mex;
}

=head2 addActualInput

	my $actual_input = OME::Tasks::ModuleExecutionManager->
	    addActualInput($output_mex,$input_mex,$formal_input);

Adds an actual input to a module execution.  Actual inputs are
specified as links between module executions.  This method specifies
that the outputs of the $output_mex module execution should be used to
provide input to the $formal_input of the $input_mex module execution.
Note that a formal output of the $output_mex is not specified; all of
the attributes of the appropriate type created by that module
execution are used as input.

=cut

sub addActualInput {
    my $class = shift;
    my ($output_mex,$input_mex,$input_name) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $input_module = $input_mex->module();

    my $input;
    if (UNIVERSAL::isa($input_name,"OME::Module::FormalInput")) {
        die "Specified formal input does not belong to input MEX's module"
          unless $input_name->module()->id() == $input_module->id();
        $input = $input_name;
        $input_name = $input->name();
    } else {
        $input = $factory->
          findObject("OME::Module::FormalInput",
                     {
                      module => $input_module,
                      name   => $input_name,
                     });
        die "Module ".$input_module->name()." does not have an input called $input_name"
          unless defined $input;
    }

    my $actual_input = $factory->
      findObject("OME::ModuleExecution::ActualInput",
                 {
                  module_execution       => $input_mex,
                  formal_input           => $input,
                  input_module_execution => $output_mex,
                 });
    die "MEX ".$input_mex->id()." (".$input_module->name().") already has an actual input for input $input_name"
      if defined $actual_input;

    $actual_input = $factory->
      newObject("OME::ModuleExecution::ActualInput",
                {
                 module_execution       => $input_mex,
                 formal_input           => $input,
                 input_module_execution => $output_mex,
                });

    return $actual_input;
}

=head2 createVirtualMEX

=cut

sub createVirtualMEX {
    my ($self,$attributes) = @_;
    my $factory = OME::Session->instance()->Factory();

    my %used_mexes;
    my %types;
    my %attributes_by_type;
    my ($dependence,$target,$module,$iterator_tag,$new_feature_tag);

    foreach my $attribute (@$attributes) {
        my $mex = $attribute->module_execution();
        $used_mexes{$mex->id()} = $mex;

        my $st = $attribute->semantic_type();
        $types{$st->id()} = $st;
        push @{$attributes_by_type{$st->id()}}, $attribute;

        my $mex_dependence = $mex->dependence();
        die "Cannot create a virtual MEX -- dependence mismatch"
          if (defined $dependence) && ($dependence ne $mex_dependence);
        $dependence = $mex_dependence;

        if ($dependence ne 'G') {
            my $mex_target =
              ($dependence eq 'D')? $mex->dataset(): $mex->image();
            die "Cannot create a virtual MEX -- target mismatch"
              if (defined $target) && (defined $mex_target)
                && ($target->id() != $mex_target->id());
            $target = $mex_target;
        }

        my $mex_module = $mex->module();
        die "Cannot create a virtual MEX -- module mismatch"
          if (defined $module) && (defined $mex_module)
          && ($module->id() != $mex_module->id());
        $module = $mex_module;

        my $mex_iterator_tag = $mex->iterator_tag();
        die "Cannot create a virtual MEX -- iterator tag mismatch"
          if (defined $iterator_tag)
          && ($iterator_tag ne $mex_iterator_tag);
        $iterator_tag = $mex_iterator_tag;

        my $mex_new_feature_tag = $mex->new_feature_tag();
        die "Cannot create a virtual MEX -- new feature tag mismatch"
          if (defined $new_feature_tag)
          && ($new_feature_tag ne $mex_new_feature_tag);
        $new_feature_tag = $mex_new_feature_tag;
    }

    # At this point, the %used_mexes hash should be populated with all
    # of the MEX's used to create the input attributes.  If there's
    # more than one such MEX, then we definitely need to create a
    # virtual MEX.  If there's only one, then we only need to create a
    # virtual MEX if the $attributes list contains a subset of the
    # attributes created by this MEX.

    if (scalar(keys %used_mexes) == 1) {
        # For now, we'll assume that this mex is okay
        my ($id, $mex) = each %used_mexes;
        my $good = 1;

        # Check each type, and see if the attributes of that type which
        # we received is the same list as the attributes of that type
        # created by the MEX.  If so, we're still good.  If not, then
        # we cannot use this MEX, and need to create a virtual MEX.

      TYPE:
        foreach my $st_id (keys %types) {
            my $st = $types{$st_id};
            my $st_attributes = $attributes_by_type{$st_id};

            my $count = $factory->
              countAttributes($st,{ module_execution => $mex });

            if ($count != scalar(@$st_attributes)) {
                $good = 0;
                last TYPE;
            }
        }

        return $mex if $good;
    }

    # Otherwise, we need to create the virtual MEX.
    my $mex = $self->createMEX($module,$dependence,$target,
                               $iterator_tag,$new_feature_tag);

    foreach my $attribute (@$attributes) {
        my $map = $factory->
          maybeNewObject('OME::ModuleExecution::VirtualMEXMap',
                         {
                          module_execution => $mex,
                          attribute        => $attribute,
                         });
    }

    $mex->virtual_mex(1);
    $mex->status('FINISHED');
    $mex->storeObject();

    # Create any necessary SemanticTypeOutputs

    my $untyped = $factory->
          findObject('OME::Module::FormalOutput',
                     {
                      module        => $module,
                      semantic_type => undef,
                     });

    foreach my $st_id (keys %types) {
        my $st = $types{$st_id};
        my $formal_output = $factory->
          findObject('OME::Module::FormalOutput',
                     {
                      module => $module,
                      semantic_type => $st,
                     });

        # If there's a formal output for this type, that's awesome.
        next if defined $formal_output;

        # Otherwise, this type needs an untyped output entry.  We'd
        # damn well better have an untyped output for this module.
        die "No untyped formal output for this module!"
          unless defined $untyped;

        $factory->
          maybeNewObject('OME::ModuleExecution::SemanticTypeOutput',
                         {
                          module_execution => $mex,
                          semantic_type    => $st,
                         });
    }

    return $mex;
}

=head2 createNEX

	my $nex = OME::Tasks::ModuleExecutionManager->
	    createNEX($mex,$chain_execution,$node);

Creates a new node execution.  Node executions record which module
execution was used to satisfy a node during the execution of an
analysis chain.  The chain execution and node can be undefined, which
signifies that this is a "universal execution".  Universal executions
are basically a hack to make the import modules work correctly -- if a
universal execution exists for a module, it will B<I<always>> be used
to satisfy that module.

=cut

sub createNEX {
    my $class = shift;
    my ($mex,$chex,$node) = @_;
    my $factory = OME::Session->instance()->Factory();

    die "Chain execution and node must either both be specified or neither"
      if (defined $chex && !defined $node)
      || (defined $node && !defined $chex);

    my $nex = $factory->
      newObject("OME::AnalysisChainExecution::NodeExecution",
                {
                 module_execution         => $mex,
                 analysis_chain_execution => $chex,
                 analysis_chain_node      => $node,
                });
}

=head2 getAttributesForMEX

	my $attributes = OME::Tasks::ModuleExecutionManager->
	    getAttributesForMEX($mex,$semantic_type,[\%extra_criteria]);

Returns an array reference of the attributes of a given semantic type
which were created by a given module execution.  The final parameter,
if specified, should be a hashref of extra criteria for the search.
They will be passed directly into the factory.

=cut

sub getAttributesForMEX {
    my $class = shift;
    my ($mexes,$semantic_type,$criteria) = @_;
    my $factory = OME::Session->instance()->Factory();

    $mexes = (ref($mexes) eq 'ARRAY')? $mexes: [$mexes];

    my @regular_mexes;
    my @virtual_mexes;

    foreach my $mex (@$mexes) {
        if ($mex->virtual_mex()) {
            push @virtual_mexes, $mex;
        } else {
            push @regular_mexes, $mex;
        }
    }

    my @attributes;

    if (scalar(@regular_mexes) > 0) {
        $criteria->{module_execution} = ['in',\@regular_mexes];

        push @attributes, $factory->
          findAttributes($semantic_type,$criteria);
    }

    if (scalar(@virtual_mexes) > 0) {
        my @maps = $factory->
          findObjects('OME::ModuleExecution::VirtualMEXMap',
                      { module_execution => ['in',\@virtual_mexes] });
        print STDERR "\n\n**** maps ",scalar(@maps),"\n";
        my @attr_ids = map { $_->attribute_id() } @maps;
        print STDERR "**** attr ",scalar(@attr_ids),"\n";

        $criteria->{id} = ['in',\@attr_ids];

        push @attributes, $factory->
          findAttributes($semantic_type,$criteria);
    }

    return \@attributes;
}

=head2 getMEXesForAttribute

	my $mexes = OME::Tasks::ModuleExecutionManager->
	    getMEXesForAttribute($attribute);

Returns an array reference of the module executions which could have
created the given attribute.  Any of these module executions could
have been used for an actual input which contains the given attribute.
This is mostly used for creating data history entries given a past
attribute.

=cut

sub getMEXesForAttribute {
    my $class = shift;
    my ($attribute) = @_;
    my $factory = OME::Session->instance()->Factory();

    my @mexes;

    # The trivial case is the MEX which initially created the
    # attribute.  This MEX is always part of the result.

    push @mexes, $attribute->module_execution();

    # The other results are any virtual MEX's which have this
    # attribute listed as an output.  This is actually pretty is to
    # query for.

    my @virtual_mex_maps = $factory->
      findObjects('OME::ModuleExecution::VirtualMEXMap',
                  { attribute => $attribute });

    foreach my $map (@virtual_mex_maps) {
        push @mexes, $map->module_execution();
    }

    return \@mexes;
}

=head2 getInputTag

	my $tag = OME::Tasks::ModuleExecutionManager->getInputTag($mex);
	my $tag = OME::Tasks::ModuleExecutionManager->
	    getInputTag($module,$dependence,$target,
	                $iterator_tag,$new_feature_tag,
	                \%actual_inputs);

The first form returns the input tag of an existing module execution.
This input tag is not well-defined until all of the actual inputs for
the module execution have been recorded.

The second form returns the input tag of a module execution that does
not exist in the database yet.  All of the data necessary to create a
module execution (the module and actual inputs) must be presented to
this routine instead of the MEX itself.  The %actual_inputs parameter
is a hash with formal input ID's as keys and MEX's as values.  (Each
value can be either a single MEX object, or an array reference of MEX
objects.)

Calling code should not make any assumptions about the output of this
method, except that it will be a string, and that two module
executions with the same input tag are eligible candidates for
attribute reuse.

=cut

sub getInputTag {
    my $class = shift;
    my $factory = OME::Session->instance()->Factory();

    my $param = shift;

    # This hairiness is to deal with the two ways of calling this
    # method.  We store the contents of the "MEX" in local variables.
    # With the first set of calling conventions, these variables are
    # populated directly from the MEX object.  In the second, they're
    # populated from the parameter list.  The actual inputs are
    # stored as a subroutine ref, which returns a list of input MEX
    # objects for a formal input.

    my ($module,$dependence,$target,$get_input_mexes);
    my ($iterator_tag,$new_feature_tag);

    if (UNIVERSAL::isa($param,'OME::ModuleExecution')) {
        # First method signature -
        # getInputTag($mex)

        my $mex = $param;

        # See if we've already calculated the input tag
        my $input_tag = $mex->input_tag();
        return $input_tag if defined $input_tag;

        $module = $mex->module();
        $dependence = $mex->dependence();
        if ($dependence eq 'G') {
            $target = undef;
        } elsif ($dependence eq 'D') {
            $target = $mex->dataset();
        } elsif ($dependence eq 'I') {
            $target = $mex->image();
        }
        $iterator_tag = $mex->iterator_tag();
        $new_feature_tag = $mex->new_feature_tag();

        $get_input_mexes = sub {
            my $formal_input = shift;

            # Retrieve the actual input(s) for this formal input

            my @actual_inputs = $factory->
              findObjects("OME::ModuleExecution::ActualInput",
                          {
                           module_execution => $mex,
                           formal_input     => $formal_input,
                          });

            # If there wasn't one, we're done with this input

            unless (scalar(@actual_inputs) > 0) {
                $input_tag .= "none) ";
                next FORMAL_INPUT;
            }

            # Retrieve the MEX(es) that satisfied this formal input
            my @input_mexes;
            push @input_mexes, $_->input_module_execution()
              foreach @actual_inputs;

            return \@input_mexes;
        };
    } elsif (UNIVERSAL::isa($param,'OME::Module')) {
        # Second method signature:
        # getInputTag($module,$dependence,$target,\%actual_inputs)

        $module = $param;
        $dependence = shift;
        $target = shift;
        $iterator_tag = shift || $module->default_iterator();
        $new_feature_tag = shift || $module->new_feature_tag();
        my $actual_inputs = shift;

        $get_input_mexes = sub {
            my $formal_input = shift;
            my $id = ref($formal_input)? $formal_input->id(): $formal_input;
            my $val = $actual_inputs->{$id};

            # This closure should return an array ref regardless of
            # what's actually in the hash.
            return ref($val) eq 'ARRAY'? $val: [$val];
        };
    }

    my $input_tag;

    # Save the dependence and target of the MEX

    if ($dependence eq 'G') {
        $input_tag = "G ";
    } elsif ($dependence eq 'D') {
        $input_tag = "D ".$target->id()." ";
    } else {
        $input_tag = "I ".$target->id()." ";
    }

    $iterator_tag ||= "";
    $new_feature_tag ||= "";

    $input_tag .= "{".$iterator_tag."} {".$new_feature_tag."} ";

    my @formal_inputs;

    # Add the formal inputs to the tag grouped by granularity

    foreach my $granularity ('G','D','I','F') {
        $input_tag .= lc($granularity)." ";

        # Retrieve all of the formal inputs for this module of the
        # current granularity.  Make sure that they're ordered!

        @formal_inputs = $factory->
          findObjects("OME::Module::FormalInput",
                      {
                       module                      => $module,
                       'semantic_type.granularity' => $granularity,
                       __order                     => 'id',
                      });

      FORMAL_INPUT:
        foreach my $formal_input (@formal_inputs) {
            my $formal_inputID = $formal_input->id();
            $input_tag .= $formal_inputID."(";

            my $input_mexes = $get_input_mexes->($formal_input);

            # Get the attributes that satisfied this formal input

            my $semantic_type = $formal_input->semantic_type();
            my $attributes = $class->
              getAttributesForMEX($input_mexes,$semantic_type,
                                  {
                                   __order => 'id',
                                  });

            # Create an ID list from these attributes.  Collapse
            # consecutive sequential ID's into to prevent the string
            # from growing overly large.

            my $first = shift(@$attributes);
            if ($first) {
                my $prev_id_top = $first->id();
                my $prev_id_bot = $first->id();

                while (my $attr = shift(@$attributes)) {
                    my $id = $attr->id();
                    if ($id == $prev_id_bot+1) {
                        $prev_id_bot = $id;
                    } else {
                        # Don't add anything to the tag until we've got
                        # a break in the attribute ID's.

                        $input_tag .= ($prev_id_top == $prev_id_bot)?
                          "$prev_id_top ": "$prev_id_top-$prev_id_bot ";

                        $prev_id_top = $prev_id_bot = $id;
                    }
                }

                $input_tag .= ($prev_id_top == $prev_id_bot)?
                  "$prev_id_top ": "$prev_id_top-$prev_id_bot ";
            }

            $input_tag .= ") ";
        }
    }

    return $input_tag;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
