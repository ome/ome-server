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
	    getAttributesForMEX($mex,[$semantic_type]);

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

use OME::Session;

=head1 METHODS

NOTE: Several of these methods create new database objects.  None of
them commit any database transactions.

=head2 createMEX

	my $mex = OME::Tasks::ModuleExecutionManager->
	    createMEX($module,$dependence,$target);

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

=cut

sub createMEX {
    my $class = shift;
    my ($module,$dependence,$target) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $dataset = ($dependence eq 'D')? $target: undef;
    my $image = ($dependence eq 'I')? $target: undef;

    my $mex = $factory->
      newObject("OME::ModuleExecution",
                {
                 module     => $module,
                 dependence => $dependence,
                 dataset    => $dataset,
                 image      => $image,
                 timestamp  => 'now',
                 status     => 'UNFINISHED',
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
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $input_module = $input_mex->module();

    my $input;
    if (UNIVERSAL::isa($input_name,"OME::Module::FormalInput")) {
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
                  module_execution => $input_mex,
                  formal_input     => $input,
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

=head2 getAttributesForMEX

	my @attributes = OME::Tasks::ModuleExecutionManager->
	    getAttributesForMEX($mex,$semantic_type,[\%extra_criteria]);

Returns the attributes of a given semantic type which were created by
a given module execution.  The final parameter, if specified, should
be a hashref of extra criteria for the search.  They will be passed
directly into the factory.

=cut

sub getAttributesForMEX {
    my $class = shift;
    my ($mex,$semantic_type,$criteria) = @_;
    $criteria->{module_execution} = $mex;

    return OME::Session->instance()->Factory()->
      findAttributes($semantic_type,$criteria);
}

=head2 getInputTag

	my $tag = OME::Tasks::ModuleExecutionManager->getInputTag($mex);

Returns the input tag of an existing module execution.  This input tag
is not well-defined until all of the actual inputs for the module
execution have been recorded.  Calling code should not make any
assumptions about the output of this method, except that it will be a
string, and that two module executions with the same input tag are
eligible candidates for attribute reuse.

=cut

sub getInputTag {
    my $class = shift;
    my $factory = OME::Session->instance()->Factory();

    my ($mex) = @_;
    my $mexID = $mex->id();

    my ($input_tag);

    # Save the dependence and target of the MEX

    if ($mex->dependence() eq 'G') {
        $input_tag = "G ";
    } elsif ($mex->dependence() eq 'D') {
        $input_tag = "D ".$mex->dataset()->id()." ";
    } else {
        $input_tag = "I ".$mex->image()->id()." ";
    }

    my @formal_inputs;

    foreach my $granularity ('G','D','I','F') {
        $input_tag .= lc($granularity)." ";
        @formal_inputs = $factory->
          findObjects("OME::Module::FormalInput",
                      {
                       module                      => $mex->module(),
                       'semantic_type.granularity' => $granularity,
                       __order                     => 'id',
                      });

        foreach my $formal_input (@formal_inputs) {
            my $formal_inputID = $formal_input->id();
            $input_tag .= $formal_inputID."(";

            my $actual_input = $factory->
              findObject("OME::ModuleExecution::ActualInput",
                         {
                          module_execution => $mex,
                          formal_input     => $formal_input,
                         });
            my $input_mex = $actual_input->input_module_execution();

            my $semantic_type = $formal_input->semantic_type();
            my @attributes = $class->
              getAttributesForMEX($input_mex,$semantic_type,
                                  {
                                   __order => 'id',
                                  });

            $input_tag .= $_->id()." " foreach @attributes;
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
