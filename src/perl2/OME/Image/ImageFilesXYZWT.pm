# OME/Image/ImageFilesXYZWT.pm

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

package OME::Image::ImageFilesXYZWT;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('image_files_xyzwt');
__PACKAGE__->addColumn(image_id => 'image_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'images',
                       });
__PACKAGE__->addColumn(['file_sha1','sha1'] => 'file_sha1',{SQLType => 'char(40)'});
__PACKAGE__->addColumn(bigendian => 'bigendian',{SQLType => 'boolean'});
__PACKAGE__->addColumn(path => 'path',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(host => 'host',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(url => 'url',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(x_start => 'x_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(x_stop  => 'x_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn('y_start' => 'y_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn('y_stop'  => 'y_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(z_start => 'z_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(z_stop  => 'z_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(w_start => 'w_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(w_stop  => 'w_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(t_start => 't_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(t_stop  => 't_stop', {SQLType => 'smallint'});



1;

