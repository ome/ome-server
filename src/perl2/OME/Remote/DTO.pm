# OME/Remote/DTO.pm

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


package OME::Remote::DTO;
use OME;
our $VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);
our @EXPORT = qw(__makeHash __updateHash);
our @EXPORT_OK = @EXPORT;

use OME::Session;

=head1 NAME

OME::Remote::DTO - superclass for all DTO assembler classes

=head1 DESCRIPTION

This class contains some useful helper methods for quickly creating
the DTO assembler classes in OME::Remote::DTO::*.  All of the methods
described below are automatically imported upon using this package.

=cut

=head2 __makeHash

	my $dto = __makeHash($object,$class,$columns);

Creates a DTO hash out of a DBObject.  If the C<$class> parameter is
defined, this method ensures that C<$object> is an instance of
C<$class>.  The C<$columns> parameter should be an array reference of
the columns to copy from the object into the new DTO hash.  Each entry
can have one of the following forms:

=over

=item C<$column_name>

An entry is added to the DTO hash with C<$column_name> for the key and
C<$object->$column_name()> for the value.

=item C<[$dto_name,$object_name]>

An entry is added to the DTO hash with C<$dto_name> for the key and
C<$object-E<gt>$object_name()> for the value.  (This is exactly the
same as the simple scalar case, except that separate names can be
provided for the object accessor and DTO hash key.)

=back

This is the inverse of C<__updateHash>.

=cut

sub __makeHash ($$$) {
    my ($object,$class,$columns) = @_;

    if (defined $class) {
        die "makeDTO expects a $class object"
          unless UNIVERSAL::isa($object,$class);
    }

    my $dto = {};
    foreach my $column (@$columns) {
        if (ref($column) eq 'ARRAY') {
            my ($dto_name,$object_name) = @$column;
            $dto->{$dto_name} = $object->$object_name();
        } else {
            $dto->{$column} = $object->$column();
        }
    }

    return $dto;
}

=head2 __updateHash

	__updateHash($dto,$class,$columns,[$store]);

Updates a DBObject based on the contents of a DTO hash.  This method
will load in an instance of the C<$class> DBObject subclass which has
a primary key of C<$dto-E<gt>{id}>.  The contents of the hash are then
passed into the mutator methods of this object.  The C<$columns>
arrayref can have the exact same format as in the C<__makeHash>
function.  If the C<$store> parameter is true or unspecified, this
method will also call C<storeObject> on the DBObject before returning.

This is the inverse of C<__makeHash>.

=cut

sub __updateHash ($$$;$) {
    my ($dto,$class,$columns,$store) = @_;
    my $factory = OME::Session->instance()->Factory();
    $store = 1 unless defined $store;

    my $object = $factory->loadObject($class,$dto->{id});
    for my $column (@$columns) {
        if (ref($column) eq 'ARRAY') {
            my ($dto_name,$object_name) = @$column;
            $object->$object_name($dto->{$dto_name});
        } else {
            $object->$column($dto->{$column});
        }
    }

    $object->storeObject() if $store;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
