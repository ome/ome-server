# OME/AnalysisPath.pm

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


package OME::AnalysisPath;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('analysis_paths');
__PACKAGE__->sequence('analysis_path_seq');
__PACKAGE__->columns(Primary => qw(path_id));
__PACKAGE__->columns(Essential => qw(path_length));

__PACKAGE__->has_many('path_nodes', 'OME::AnalysisPath::Map' => qw(path_id));


package OME::AnalysisPath::Map;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_view_node_id => 'analysis_view_node',
    path_id               => 'path'
    });

__PACKAGE__->table('analysis_path_map');
__PACKAGE__->columns(Essential => qw(path_id path_order
				     analysis_view_node_id));
__PACKAGE__->hasa('OME::AnalysisPath' => qw(path_id));
__PACKAGE__->hasa('OME::AnalysisView::Node' => qw(analysis_view_node_id));

1;
