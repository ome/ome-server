# OME/module/Category.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Module::Category;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('module_categories');
__PACKAGE__->setSequence('module_category_seq');
__PACKAGE__->addPrimaryKey('category_id');
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(parent_category_id => 'parent_category_id');
__PACKAGE__->addColumn(parent_category => 'parent_category_id',
                       'OME::Module::Category',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'module_categories',
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->hasMany('children','OME::Module::Category' =>
                     'parent_category');
__PACKAGE__->hasMany('modules','OME::Module' => 'category');


1;
