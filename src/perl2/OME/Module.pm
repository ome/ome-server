# OME/Module.pm

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

=head1 NAME

OME::Module - a reuseable computational block for analysis

=head1 SYNOPSIS

	 later

=head1 DESCRIPTION

later

=cut


package OME::Module;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

use OME::Module::FormalOutput;
use OME::Module::FormalInput;

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('modules');
__PACKAGE__->setSequence('module_seq');
__PACKAGE__->addPrimaryKey('module_id');
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->addColumn(location => 'location',
                       {
                        SQLType => 'varchar(128)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(module_type => 'module_type',
                       {
                        SQLType => 'varchar(128)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(category_id => 'category');
__PACKAGE__->addColumn(category => 'category',
                       'OME::Module::Category',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'module_categories',
                       });
__PACKAGE__->addColumn(default_iterator => 'default_iterator',
                       {
                        SQLType => 'varchar(128)',
                       });
__PACKAGE__->addColumn(new_feature_tag => 'new_feature_tag',
                       {
                        SQLType => 'varchar(128)',
                       });
__PACKAGE__->addColumn(execution_instructions => 'execution_instructions',
                       {
                        SQLType => 'text',
                       });
__PACKAGE__->hasMany('inputs','OME::Module::FormalInput' => 'module');
__PACKAGE__->hasMany('outputs','OME::Module::FormalOutput' => 'module');
__PACKAGE__->hasMany('analyses','OME::ModuleExecution' => 'module');


=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut



1;

