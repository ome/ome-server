# OME/AnalysisChain.pm

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

OME::AnalysisChain::Node - a node in the module_execution chain

=cut

package OME::AnalysisChain::Node;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_chain_nodes');
__PACKAGE__->setSequence('analysis_chain_nodes_seq');
__PACKAGE__->addPrimaryKey('analysis_chain_node_id');
__PACKAGE__->addColumn(analysis_chain_id => 'analysis_chain_id');
__PACKAGE__->addColumn(analysis_chain => 'analysis_chain_id',
                       'OME::AnalysisChain',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chains',
                       });
__PACKAGE__->addColumn(module_id => 'module_id');
__PACKAGE__->addColumn(module => 'module_id',
                       'OME::Module',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'modules',
                       });
__PACKAGE__->addColumn(iterator_tag => 'iterator_tag',
                       {SQLType => 'varchar(128)'});
__PACKAGE__->addColumn(new_feature_tag => 'new_feature_tag',
                       {SQLType => 'varchar(128)'});
__PACKAGE__->hasMany('input_links',
                     'OME::AnalysisChain::Link' => 'to_node');
__PACKAGE__->hasMany('output_links',
                     'OME::AnalysisChain::Link' => 'from_node');

=head1 METHODS (C<AnalysisView::Node>)

The following methods are available to C<AnalysisView::Node> in
addition to those defined by L<OME::DBObject>.

=head2 analysis_chain

	my $analysis_chain = $node->analysis_chain();
	$node->analysis_chain($analysis_chain);

Returns or sets the module_execution chain that this node belongs to.

=head2 module

	my $module = $node->module();
	$node->module($module);

Returns or sets the module_execution module that this node represents.

=head2 iterator_tag

	my $iterator_tag = $node->iterator_tag();
	$node->iterator_tag($iterator_tag);

Returns or sets the iterator tag for this node.

=head2 new_feature_tag

	my $new_feature_tag = $node->new_feature_tag();
	$node->new_feature_tag($new_feature_tag);

Returns or sets the tag that any new features created by this module
will have.

=head2 input_links

	my @input_links = $node->input_links();
	my $input_link_iterator = $node->input_links();

Returns or iterates, depending on context, the links that provide
input to this node.

=head2 output_links

	my @output_links = $node->output_links();
	my $output_link_iterator = $node->output_links();

Returns or iterates, depending on context, the links that this node
provides output for.

=cut

1;


__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

