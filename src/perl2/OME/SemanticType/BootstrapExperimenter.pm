# OME/SemanticType/BootstrapExperimenter.pm

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


# The Experimenter, Group, and Repository semantic types must have
# their tables created before they are really instantiated as semantic
# types.  (Some of the core tables have foreign keys into this table.)

package OME::SemanticType::BootstrapExperimenter;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('experimenters');
__PACKAGE__->setSequence('attribute_seq');
__PACKAGE__->addPrimaryKey('attribute_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        #ForeignKey => 'module_executions',
                       });
__PACKAGE__->addColumn(FirstName => 'firstname',{SQLType => 'varchar(30)'});
__PACKAGE__->addColumn(LastName => 'lastname',{SQLType => 'varchar(30)'});
__PACKAGE__->addColumn(Email => 'email',{SQLType => 'varchar(50)'});
__PACKAGE__->addColumn(OMEName => 'ome_name',
                       {
                        SQLType => 'varchar(30)',
                        Unique  => 1,
                       });
__PACKAGE__->addColumn(Password => 'password',{SQLType => 'varchar(64)'});
__PACKAGE__->addColumn(Group => 'group_id',
                       'OME::SemanticType::BootstrapGroup',
                       {
                        SQLType => 'integer',
                       });
__PACKAGE__->addColumn(DataDirectory => 'data_dir',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(Institution => 'institution',{SQLType => 'varchar(256)'});


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

