# OME/Module/FormalInput.pm

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


package OME::Module::FormalInput;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('formal_inputs');
__PACKAGE__->setSequence('formal_input_seq');
__PACKAGE__->addPrimaryKey('formal_input_id');
__PACKAGE__->addColumn(module_id => 'module_id');
__PACKAGE__->addColumn(module => 'module_id','OME::Module',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'modules',
                       });
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->addColumn(optional => 'optional',
                       {
                        SQLType => 'boolean',
                        Default => 'false',
                       });
__PACKAGE__->addColumn(list => 'list',
                       {
                        SQLType => 'boolean',
                        Default => 'true',
                       });
__PACKAGE__->addColumn(semantic_type_id => 'semantic_type_id');
__PACKAGE__->addColumn(semantic_type => 'semantic_type_id',
                       'OME::SemanticType',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'semantic_types',
                       });
__PACKAGE__->addColumn(lookup_table_id => 'lookup_table_id');
__PACKAGE__->addColumn(lookup_table => 'lookup_table_id',
                       'OME::LookupTable',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'lookup_tables',
                       });
__PACKAGE__->addColumn(user_defined => 'user_defined',
                       {
                        SQLType => 'boolean',
                        Default => 'false',
                       });

__PACKAGE__->hasMany('actual_inputs','OME::ModuleExecution::ActualInput' =>
                     'formal_input');


1;
