# OME/Image/DatasetMap.pm

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

package OME::Image::DatasetMap;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('image_dataset_map');
__PACKAGE__->addColumn(image_id => 'image_id');
__PACKAGE__->addColumn(image => 'image_id','OME::Image',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'images',
                       });
__PACKAGE__->addDeleteKey('image_id');
__PACKAGE__->addColumn(dataset_id => 'dataset_id');
__PACKAGE__->addColumn(dataset => 'dataset_id','OME::Dataset',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'datasets',
                       });
__PACKAGE__->addDeleteKey('dataset_id');

# Our current caching implements breaks when there is not a single
# primary key column for the table.  As this is the case for this
# table, turn off caching (just for this class).

__PACKAGE__->Caching(0);



1;

