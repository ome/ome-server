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

sub experimenter {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->attribute_type()->name() eq "Experimenter";
        return $self->experimenter_id($attribute->id());
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


1;
