# OME/Dataset.pm

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


package OME::Dataset;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    project_id => 'project',
    owner_id   => 'owner',
    group_id   => 'group'
    });

__PACKAGE__->table('datasets');
__PACKAGE__->sequence('dataset_seq');
__PACKAGE__->columns(Primary => qw(dataset_id));
__PACKAGE__->columns(Essential => qw(name description locked));
#__PACKAGE__->has_many('images',OME::Image => qw(dataset_id));
__PACKAGE__->hasa(OME::Project => qw(project_id));
__PACKAGE__->hasa(OME::Experimenter => qw(owner_id));
__PACKAGE__->hasa(OME::Group => qw(group_id));


1;

