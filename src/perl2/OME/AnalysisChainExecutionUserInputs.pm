# OME/AnalysisChainExecutionUserInputs.pm

##-------------------------------------------------------------------------------
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
# Written by:    Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------


package OME::AnalysisChainExecutionUserInputs;

=head1 NAME

OME::AnalysisChainExecutionUserInputs - records the user-inputs specified for
for an execution of an module_execution chain

=head1 DESCRIPTION

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_chain_executions_user_inputs');
__PACKAGE__->setSequence('analysis_chain_execution_user_inputs_seq');
__PACKAGE__->addPrimaryKey('analysis_chain_execution_user_input_id');
__PACKAGE__->addColumn(analysis_chain_execution_id => 'analysis_chain_execution_id');
__PACKAGE__->addColumn(analysis_chain_execution => 'analysis_chain_execution_id',
                       'OME::AnalysisChainExecution',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_executions',
                       });
__PACKAGE__->addColumn(formal_input_id => 'formal_input_id');
__PACKAGE__->addColumn(formal_input => 'formal_input_id',
                       'OME::Module::FormalInput',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'formal_inputs',
                       });
                       
__PACKAGE__->addColumn(module_execution_id => 'module_execution_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'module_executions',
                       });
1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Open Microscopy Environment, MIT

=cut

