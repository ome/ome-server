# OME/LSID.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


=head1 NAME

OME::LSID;

=head1 SYNOPSIS

To come.	
	
=head1 DESCRIPTION

To come.

=head1 METHODS

=head2 name

accessor/mutator for name

=head2 created

accessor/mutator for creation timestamp

=head2 inserted

accessor/mutator for timestamp of image import

=head2 description

accessor/mutator for description

=cut

package OME::LSID;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

# currently unused, could be useful in the future.
my %_namespace_object_codes = (
	Project => "OME::Project",
	Dataset => "OME::Dataset",
	Image   => "OME::Image",
	Feature => "OME::Feature",
 	Module  => "OME::Module",
	ModuleExecution => "OME::ModuleExecution",
);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('lsid_object_map');
__PACKAGE__->addColumn(lsid => 'lsid',
                       {
                        SQLType => 'varchar(256)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(namespace => 'namespace',
                       {
                        SQLType => 'varchar(256)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(object_id => 'object_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                       });

# Our current caching implements breaks when there is not a single
# primary key column for the table.  As this is the case for this
# table, turn off caching (just for this class).

__PACKAGE__->Caching(0);

sub parseLSID {
	my ($self) = @_;
	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$self->lsid());
	return { 
		authority   => $authority,
		namespace   => $namespace,
		local_id    => $localID,
		db_instance => $dbInstance
	};
}

1;
