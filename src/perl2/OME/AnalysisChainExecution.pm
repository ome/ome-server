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


package OME::AnalysisExecution;

=head1 NAME

OME::AnalysisExecution - execution of an analysis chain

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
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_view_id => 'analysis_view',
    dataset_id => 'dataset',
#    experimenter_id => 'experimenter'
    });

__PACKAGE__->table('analysis_executions');
__PACKAGE__->sequence('analysis_execution_seq');
__PACKAGE__->columns(Primary => qw(analysis_execution_id));
__PACKAGE__->columns(Essential => qw(analysis_view_id dataset_id
				     experimenter_id timestamp));
__PACKAGE__->hasa('OME::AnalysisView' => qw(analysis_view_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));
#__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));
__PACKAGE__->has_many('node_executions',
                      'OME::AnalysisExecution::NodeExecution' =>
                      qw(analysis_execution_id));

=head1 METHODS (C<AnalysisExecution>)

The following methods are available to C<AnalysisExecution> in
addition to those defined by L<OME::DBObject>.

=head2 analysis_view

	my $analysis_view = $execution->analysis_view();
	$execution->analysis_view($analysis_view);

Returns or sets the analysis chain which was executed.

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
C<AnalysisExecution::NodeExecutions> associated with this analysis.

=cut

sub experimenter {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->attribute_type()->name() eq "Experimenter";
        $self->experimenter_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->experimenter_id());
    }
}


package OME::AnalysisExecution::NodeExecution;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_execution_id => 'analysis_execution',
    analysis_view_node_id => 'analysis_view_node',
    analysis_id           => 'analysis'
    });

__PACKAGE__->table('analysis_node_executions');
__PACKAGE__->sequence('analysis_node_execution_seq');
__PACKAGE__->columns(Primary => qw(analysis_node_execution_id));
__PACKAGE__->columns(Essential => qw(analysis_execution_id
                                     analysis_view_node_id
                                     analysis_id));
__PACKAGE__->hasa('OME::AnalysisExecution' => qw(analysis_execution_id));
__PACKAGE__->hasa('OME::AnalysisView::Node' => qw(analysis_view_node_id));
__PACKAGE__->hasa('OME::Analysis' => qw(analysis_id));

=head1 METHODS (C<AnalysisExecution::NodeExecution>)

The following methods are available to
C<AnalysisExecution::NodeExecution> in addition to those defined by
L<OME::DBObject>.

=head2 analysis_execution

	my $analysis_execution = $node_execution->analysis_execution();
	$node_execution->analysis_execution($analysis_execution);

Returns or sets the analysis execution that this node execution
belongs to.

=head2 analysis_view_node

	my $analysis_view_node = $node_execution->analysis_view_node();
	$node_execution->analysis_view_node($analysis_view_node);

Returns or sets the analysis chain node that was executed.

=head2 analysis

	my $analysis = $node_execution->analysis();
	$node_execution->analysis($analysis);

Returns or sets the module execution that satisfied this node
execution.

=cut


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

