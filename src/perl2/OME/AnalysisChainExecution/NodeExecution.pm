# OME/AnalysisChainExecution/NodeExecution.pm

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
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


=head1 NAME

OME::AnalysisChainExecution::NodeExecution - execution of one node in an
analysis chain

=head1 DESCRIPTION

The C<AnalysisChainExecution> class represents an execution of an OME
analysis chain against a dataset of images.  The
C<AnalysisChainExecution::NodeExecution> class represents an execution of
each node in the chain.  Each actual execution of the chain is
represented by exactly one C<AnalysisChainExecution>, and each execution of
a node is represented by exactly one
C<AnalysisChainExecution::NodeExecution>, even if the results of a module
execution are reused.

=cut

package OME::AnalysisChainExecution::NodeExecution;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_node_executions');
__PACKAGE__->setSequence('analysis_node_execution_seq');
__PACKAGE__->addPrimaryKey('analysis_node_execution_id');
__PACKAGE__->addColumn(analysis_chain_execution_id =>
                       'analysis_chain_execution_id');
__PACKAGE__->addColumn(analysis_chain_execution => 'analysis_chain_execution_id',
                       'OME::AnalysisChainExecution',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_executions',
                       });
__PACKAGE__->addColumn(analysis_chain_node_id => 'analysis_chain_node_id');
__PACKAGE__->addColumn(analysis_chain_node => 'analysis_chain_node_id',
                       'OME::AnalysisChain::Node',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_nodes',
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

=head1 METHODS (C<AnalysisChainExecution::NodeExecution>)

The following methods are available to
C<AnalysisChainExecution::NodeExecution> in addition to those defined by
L<OME::DBObject>.

=head2 analysis_chain_execution

	my $analysis_chain_execution = $node_execution->analysis_chain_execution();
	$node_execution->analysis_chain_execution($analysis_chain_execution);

Returns or sets the chain execution that this node execution belongs
to.

=head2 analysis_chain_node

	my $analysis_chain_node = $node_execution->analysis_chain_node();
	$node_execution->analysis_chain_node($analysis_chain_node);

Returns or sets the analysis chain node that was executed.

=head2 module_execution

	my $module_execution = $node_execution->module_execution();
	$node_execution->module_execution($module_execution);

Returns or sets the module execution that satisfied this node
execution.

=cut


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

