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

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;

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

sub addActualInput {
    my $class = shift;
    my ($output_mex,$input_mex,$input_name) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $input_module = $input_mex->module();

    my $input = $factory->
      findObject("OME::Module::FormalInput",
                 {
                  module => $input_module,
                  name   => $input_name,
                 });
    die "Module ".$input_module->name()." does not have an input called $input_name"
      unless defined $input;

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

1;
