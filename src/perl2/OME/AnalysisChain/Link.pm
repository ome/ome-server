# OME/AnalysisChain/Link.pm

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

=head1 NAME

OME::AnalysisChain::Link - a link connecting two nodes in the chain

=cut

package OME::AnalysisChain::Link;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_chain_links');
__PACKAGE__->setSequence('analysis_chain_links_seq');
__PACKAGE__->addPrimaryKey('analysis_chain_link_id');
__PACKAGE__->addColumn(analysis_chain_id => 'analysis_chain_id');
__PACKAGE__->addColumn(analysis_chain => 'analysis_chain_id',
                       'OME::AnalysisChain',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chains',
                       });
__PACKAGE__->addColumn(from_node_id => 'from_node');
__PACKAGE__->addColumn(from_node => 'from_node',
                       'OME::AnalysisChain::Node',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_nodes',
                       });
__PACKAGE__->addColumn(from_output_id => 'from_output');
__PACKAGE__->addColumn(from_output => 'from_output',
                       'OME::Module::FormalOutput',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'formal_outputs',
                       });
__PACKAGE__->addColumn(to_node_id => 'to_node');
__PACKAGE__->addColumn(to_node => 'to_node',
                       'OME::AnalysisChain::Node',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_nodes',
                       });
__PACKAGE__->addColumn(to_input_id => 'to_input');
__PACKAGE__->addColumn(to_input => 'to_input',
                       'OME::Module::FormalInput',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'formal_inputs',
                       });

=head1 METHODS (C<AnalysisView::Link>)

The following methods are available to C<AnalysisView::Link> in
addition to those defined by L<OME::DBObject>.

=head2 analysis_chain

	my $analysis_chain = $link->analysis_chain();
	$link->analysis_chain($analysis_chain);

Returns the module_execution chain that this link belongs to.

=head2 from_node

	my $from_node = $link->from_node();
	$link->from_node($from_node);

Returns the node that this link receives data from.

=head2 from_output

	my $from_output = $link->from_output();
	$link->from_output($from_output);

Returns the formal output that this link receives data from.

=head2 to_node

	my $to_node = $link->to_node();
	$link->to_node($to_node);

Returns the node that this link sends data to.

=head2 to_input

	my $to_input = $link->to_input();
	$link->to_input($to_input);

Returns the formal input that this link sends data to.

=cut

1;


__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

