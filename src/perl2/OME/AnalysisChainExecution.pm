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
    experimenter_id => 'experimenter'
    });

__PACKAGE__->table('analysis_executions');
__PACKAGE__->sequence('analysis_execution_seq');
__PACKAGE__->columns(Primary => qw(analysis_execution_id));
__PACKAGE__->columns(Essential => qw(analysis_view_id dataset_id
				     experimenter_id timestamp));
__PACKAGE__->hasa('OME::AnalysisView' => qw(analysis_view_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));
__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));


1;
