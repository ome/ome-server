
# OME/AnalysisView.pm

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


package OME::AnalysisView;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('analysis_views');
__PACKAGE__->sequence('analysis_view_seq');
__PACKAGE__->columns(Primary => qw(analysis_view_id));
__PACKAGE__->columns(Essential => qw(owner name locked));
#__PACKAGE__->hasa('OME::Experimenter' => qw(owner));
__PACKAGE__->has_many('nodes',
                      'OME::AnalysisView::Node' => qw(analysis_view_id));
__PACKAGE__->has_many('links',
                      'OME::AnalysisView::Link' => qw(analysis_view_id));
__PACKAGE__->has_many('paths',
                      'OME::AnalysisPath' => qw(analysis_view_id));

sub owner {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->attribute_type()->name() eq "Experimenter";
        $self->_owner_accessor($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->_owner_accessor());
    }
}



package OME::AnalysisView::Node;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_view_id => 'analysis_view',
    program_id       => 'program'
    });

__PACKAGE__->table('analysis_view_nodes');
__PACKAGE__->sequence('analysis_view_nodes_seq');
__PACKAGE__->columns(Primary => qw(analysis_view_node_id));
__PACKAGE__->columns(Essential => qw(analysis_view_id program_id
                                     iterator_tag new_feature_tag));
__PACKAGE__->hasa('OME::AnalysisView' => qw(analysis_view_id));
__PACKAGE__->hasa('OME::Program' => qw(program_id));
__PACKAGE__->has_many('input_links',
                      'OME::AnalysisView::Link' => qw(to_node));
__PACKAGE__->has_many('output_links',
                      'OME::AnalysisView::Link' => qw(from_node));



package OME::AnalysisView::Link;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_view_id => 'analysis_view'
    });

__PACKAGE__->table('analysis_view_links');
__PACKAGE__->sequence('analysis_view_links_seq');
__PACKAGE__->columns(Primary => qw(analysis_view_link_id));
__PACKAGE__->columns(Essential => qw(analysis_view_id
                                     from_node from_output
                                     to_node to_input));
__PACKAGE__->hasa('OME::AnalysisView' => qw(analysis_view_id));
__PACKAGE__->hasa('OME::AnalysisView::Node' => qw(from_node));
__PACKAGE__->hasa('OME::Program::FormalOutput' => qw(from_output));
__PACKAGE__->hasa('OME::AnalysisView::Node' => qw(to_node));
__PACKAGE__->hasa('OME::Program::FormalInput' => qw(to_input));


1;
