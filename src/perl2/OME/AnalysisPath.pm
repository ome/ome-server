# OME/AnalysisPath.pm

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


package OME::AnalysisPath;

=head1 NAME

OME::AnalysisPath - a data path within an analysis chain

OME::AnalysisPath::Map - the individual entries in a data path

=head1 DESCRIPTION

The C<AnalysisPath> class represents a single, linear data path
through an analysis chain.  Each chain has one I<data path> for each
linear path from a root node to a leaf node.  (A root node contains no
inputs; a leaf node contains no outputs.  Since analysis chains are
acyclic, there must be at least one of each in any chain.)

The C<AnalysisPath::Map> class represents each element in a data path.
It corresponds to one of the nodes in the analysis chain.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_paths');
__PACKAGE__->setSequence('analysis_path_seq');
__PACKAGE__->addPrimaryKey('path_id');
__PACKAGE__->addColumn(analysis_chain_id => 'analysis_chain_id');
__PACKAGE__->addColumn(analysis_chain => 'analysis_chain_id',
                       'OME::AnalysisChain',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'analysis_chains',
                       });
__PACKAGE__->addColumn(path_length => 'path_length',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                       });
__PACKAGE__->hasMany('path_nodes', 'OME::AnalysisPath::Map' => 'path');

=head1 METHODS (C<AnalysisPath>)

The following methods are available to C<AnalysisPath> in addition to
those defined by L<OME::DBObject>.

=head2 path_length

	my $path_length = $execution->path_length();
	$execution->path_length($path_length);

Returns or sets the length of the path.  This should correspond to the
number of items returned by C<path_nodes>.

=head2 analysis_chain

	my $analysis_chain = $execution->analysis_chain();
	$execution->analysis_chain($analysis_chain);

Returns or sets the analysis chain that this data path belongs to.

=head2 path_nodes

	my @nodes = $execution->path_nodes();
	my $node_iterator = $execution->path_nodes();

Returns or iterates, depending on context, a list of the path entries
in this data path.

=cut


package OME::AnalysisPath::Map;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('analysis_path_map');
__PACKAGE__->addColumn(path_id => 'path_id');
__PACKAGE__->addColumn(path => 'path_id',
                       'OME::AnalysisPath',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_paths',
                       });
__PACKAGE__->addColumn(path_order => 'path_order',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(analysis_chain_node_id => 'analysis_chain_node_id');
__PACKAGE__->addColumn(analysis_chain_node => 'analysis_chain_node_id',
                       'OME::AnalysisChain::Node',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'analysis_chain_nodes',
                       });

=head1 METHODS (C<AnalysisPath::Map>)

The following methods are available to C<AnalysisPath::Map> in
addition to those defined by L<OME::DBObject>.

=head2 path

	my $path = $execution->path();
	$execution->path($path);

Returns or sets the data path that this entry belongs to.

=head2 analysis_chain_node

	my $analysis_chain_node = $execution->analysis_chain_node();
	$execution->analysis_chain_node($analysis_chain_node);

Returns ot sets the analysis chain node that this entry corresponds
to.

=head2 path_order

	my $path_order = $execution->path_order();
	$execution->path_order($path_order);

Returns or sets the position along the data path (indexed from 1) of
this entry.

=cut

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

