# OME/AnalysisExecution.pm

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


package OME::AnalysisChainExecution;

=head1 NAME

OME::AnalysisExecution - execution of an module_execution chain

OME::AnalysisExecution::NodeExecution - execution of one node in an
analysis chain

=head1 DESCRIPTION

The C<AnalysisExecution> class represents an execution of an OME
analysis chain against a dataset of images.  The
C<AnalysisExecution::NodeExecution> class represents an execution of
each node in the chain.  Each actual execution of the chain is
represented by exactly one C<AnalysisExecution>, and each execution of
a node is represented by exactly one
C<AnalysisExecution::NodeExecution>, even if the results of a module
execution are reused.

=cut

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_chain_id => 'analysis_chain',
    dataset_id => 'dataset',
    });

__PACKAGE__->table('analysis_chain_executions');
__PACKAGE__->sequence('analysis_chain_execution_seq');
__PACKAGE__->columns(Primary => qw(analysis_chain_execution_id));
__PACKAGE__->columns(Essential => qw(analysis_chain_id dataset_id
				     experimenter_id timestamp));
__PACKAGE__->hasa('OME::AnalysisChain' => qw(analysis_chain_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));
__PACKAGE__->has_many('node_executions',
                      'OME::AnalysisExecution::NodeExecution' =>
                      qw(analysis_chain_execution_id));

=head1 METHODS (C<AnalysisExecution>)

The following methods are available to C<AnalysisExecution> in
addition to those defined by L<OME::DBObject>.

=head2 analysis_chain

	my $analysis_chain = $execution->analysis_chain();
	$execution->analysis_chain($analysis_chain);

Returns or sets the module_execution chain which was executed.

=head2 dataset

	my $dataset = $execution->dataset();
	$execution->dataset($dataset);

Returns or sets the dataset that the chain was executed against.

=head2 experimenter

	my $experimenter = $execution->experimenter();
	$execution->experimenter($experimenter);

Returns or sets the experimenter who performed the execution of the
chain.

=head2 timestamp

	my $timestamp = $execution->timestamp();
	$execution->timestamp($timestamp);

Returns or sets when the execution occurred.

=head2 node_executions

	my @nodes = $execution->node_executions();
	my $node_iterator = $execution->node_executions();

Returns or iterates, depending on context, a list of all of the
C<AnalysisExecution::NodeExecutions> associated with this module_execution.

=cut

sub experimenter {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->semantic_type()->name() eq "Experimenter";
        $self->experimenter_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->experimenter_id());
    }
}


package OME::AnalysisChainExecution::NodeExecution;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_chain_execution_id => 'analysis_chain_execution',
    analysis_chain_node_id => 'analysis_chain_node',
    module_execution_id           => 'module_execution'
    });

__PACKAGE__->table('analysis_node_executions');
__PACKAGE__->sequence('analysis_node_execution_seq');
__PACKAGE__->columns(Primary => qw(analysis_node_execution_id));
__PACKAGE__->columns(Essential => qw(analysis_chain_execution_id
                                     analysis_chain_node_id
                                     module_execution_id));
__PACKAGE__->hasa('OME::AnalysisChainExecution' => qw(analysis_chain_execution_id));
__PACKAGE__->hasa('OME::AnalysisChain::Node' => qw(analysis_chain_node_id));
__PACKAGE__->hasa('OME::ModuleExecution' => qw(module_execution_id));

=head1 METHODS (C<AnalysisExecution::NodeExecution>)

The following methods are available to
C<AnalysisExecution::NodeExecution> in addition to those defined by
L<OME::DBObject>.

=head2 analysis_chain_execution

	my $analysis_chain_execution = $node_execution->analysis_chain_execution();
	$node_execution->analysis_chain_execution($analysis_chain_execution);

Returns or sets the module_execution execution that this node execution
belongs to.

=head2 analysis_chain_node

	my $analysis_chain_node = $node_execution->analysis_chain_node();
	$node_execution->analysis_chain_node($analysis_chain_node);

Returns or sets the module_execution chain node that was executed.

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

