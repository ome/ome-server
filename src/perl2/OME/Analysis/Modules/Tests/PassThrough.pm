# OME/Analysis/Modules/Tests/PassThrough.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Tests::PassThrough;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Analysis::Handler;
use OME::Tasks::ModuleExecutionManager;

use base qw(OME::Analysis::Handler);

# Clones a single input into a single output.

sub execute {
    my ($self,$dependence,$target) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $mex = $self->getModuleExecution();
    my $module = $mex->module();
    my $formal_input = $factory->
      findObject('OME::Module::FormalInput',
                 {
                  module => $module,
                  name   => 'Pixels',
                 });
    my $actual_input = $factory->
      findObject('OME::ModuleExecution::ActualInput',
                 {
                  module_execution => $mex,
                  formal_input     => $formal_input,
                 });
    my $input_mex = $actual_input->input_module_execution();
    my $input_attrs = OME::Tasks::ModuleExecutionManager->
      getAttributesForMEX($input_mex,$formal_input->semantic_type())
      or die "Couldn't get inputs!";

    my $formal_output = $factory->findObject(
    	'OME::Module::FormalOutput',
		{ module => $module }
	) or die "no output for this module ".$module->name();

	my $data_hash = $input_attrs->[0]->getDataHash();
	$data_hash->{ target } = $input_attrs->[0]->target();
	$self->newAttributes( $formal_output, $data_hash );

}

1;
