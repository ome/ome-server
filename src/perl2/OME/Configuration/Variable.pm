# OME/Configuration/Variable.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------
=head1 NAME

OME::Configuration::Variable - A DB instance of an OME Configuration variable

=head1 DESCRIPTION

This class is used by L<C<OME::Configuration>|OME::Configuration> to store individual configuration variables,
and should not be used by itself.  This class inherits from OME::DBObject, and doesn't really do anyting interesting with it.
The DB table used by this class is CONFIGURATION.  Columns are VAR_ID (primary key), CONFIGURATION_ID (always set to 1)
NAME (the name of the variable) and VALUE (the value of the variable).  VAR_ID uses the sequence CONFIG_VAR_ID_SEQ.

=head1 METHODS

=head2 var_id

The primary key for the CONFIGURATION table and the object ID for this class.

=head2 configuration_id

The configuration ID.  This should always be 1.

=head2 name

The name of the configuration variable.

=head2 value

The value of the configuration variable.

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>, Open Microscopy Environment

=cut


package OME::Configuration::Variable;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setSequence('config_var_id_seq');
__PACKAGE__->setDefaultTable('configuration');
__PACKAGE__->addPrimaryKey('var_id');
__PACKAGE__->addColumn(configuration_id => 'configuration_id',{SQLType => 'integer'});
__PACKAGE__->addColumn(name => 'name',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(value => 'value',{SQLType => 'varchar(256)'});
__PACKAGE__->Caching(1);

1;

