# OME/Remote/Facades/ModuleExecutionFacade.pm

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


package OME::Remote::Facades::ModuleExecutionFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Remote::DTO::GenericAssembler;
use OME::Session;
use OME::ModuleExecution;
use OME::Tasks::ModuleExecutionManager;

=head1 NAME

OME::Remote::Facades::ModuleExecutionFacade - implementation of remote
facade methods pertaining to module executions

=cut

use constant DEFAULT_MEX_SPEC =>
  {
   '.' => ['id','dependence','dataset','image','module'],
   'dataset' => ['id','name'],
   'image' => ['id','name'],
   'module' => ['id','name'],
  };

sub createMEX {
    my ($proto,$module_id,$dependence,$target_id,
        $iterator_tag,$new_feature_tag,$spec) = @_;

    $spec = DEFAULT_MEX_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $module = $factory->loadObject('OME::Module',$module_id);
    die "Module $module_id doesn't exist" unless defined $module;

    my $target_class;
    my $target;
    if ($dependence eq 'G') {
        # No target
    } elsif ($dependence eq 'D') {
        $target_class = "OME::Dataset";
        $target = $factory->loadObject($target_class,$target_id);
        die "Dataset $target_id doesn't exist" unless defined $target;
    } elsif ($dependence eq 'I') {
        $target_class = "OME::Image";
        $target = $factory->loadObject($target_class,$target_id);
        die "Image $target_id doesn't exist" unless defined $target;
    } else {
        die "Invalid dependence $dependence";
    }

    my $mex = OME::Tasks::ModuleExecutionManager->
      createMEX($module,$dependence,$target,$iterator_tag,$new_feature_tag);
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($mex,$spec);

    return $dto;
}

use constant DEFAULT_ACTUAL_INPUT_SPEC =>
  {
   '.' => ['id','module_execution','formal_input','input_module_execution'],
   'module_execution' => ['id'],
   'formal_input' => ['id'],
   'input_module_execution' => ['id'],
  };

sub addActualInput {
    my ($proto,$output_mex_id,$input_mex_id,$formal_input_id,$spec) = @_;

    $spec = DEFAULT_ACTUAL_INPUT_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $output_mex = $factory->
      loadObject('OME::ModuleExecution',$output_mex_id);
    die "MEX $output_mex_id doesn't exist"
      unless defined $output_mex;

    my $input_mex = $factory->
      loadObject('OME::ModuleExecution',$input_mex_id);
    die "MEX $input_mex_id doesn't exist"
      unless defined $input_mex;

    my $formal_input = $factory->
      loadObject('OME::ModuleExecution',$formal_input_id);
    die "Formal input $formal_input_id doesn't exist"
      unless defined $formal_input;

    my $actual_inupt = OME::Tasks::ModuleExecutionManager->
      addActualInput($output_mex,$input_mex,$formal_input);
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($actual_input,$spec);

    return $dto;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
