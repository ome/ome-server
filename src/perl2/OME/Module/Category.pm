# OME/module/Category.pm

# Copyright (C) 2002-2003 Open Microscopy Environment
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


package OME::Module::Category;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->
  AccessorNames({
                 parent_category_id => 'parent_category'
                });


__PACKAGE__->table('module_categories');
__PACKAGE__->sequence('module_category_seq');
__PACKAGE__->columns(Primary => qw(category_id));
__PACKAGE__->columns(Essential => qw(name description parent_category_id));
__PACKAGE__->hasa('OME::Module::Category' => qw(parent_category_id));
__PACKAGE__->has_many('children','OME::Module::Category' =>
                      qw(parent_category_id),
                      {sort => 'name'});
__PACKAGE__->has_many('modules','OME::Module' =>
                      qw(category),
                      {sort => 'name'});


1;
