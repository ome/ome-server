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
use strict;
use OME;
our $VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);
our @EXPORT = qw(__makeHash __updateHash);
our @EXPORT_OK = @EXPORT;
use Carp;
use Carp qw(cluck);

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
    my ($object,$class,$request_list) = @_;

	# Sanity Checks
    return undef unless defined $object;
    if (defined $class) {
        die "makeDTO expects a $class object"
          unless UNIVERSAL::isa($object,$class);
    }

    # Massage the incoming requests
    my %requests;
    foreach my $request (@$request_list) {
        if (ref($request) eq 'ARRAY') {
            my ($dto_name,$method_name) = @$request;
            $requests{$method_name} = $dto_name;
        } else {
            $requests{$request} = $request;
        }
    }

	# expand ":all:" into everything that should be transferred.
	if( exists $requests{":all:"} ) {
	    delete $requests{ ":all:" };
		my @method_request_list = (
			$object->getColumns(),
			keys %{$object->getHasMany()},
			map( '#'.$_, keys %{$object->getHasMany()} ), # counts of those
			keys %{$object->getManyToMany()},
			map( '#'.$_, keys %{$object->getManyToMany()} ), # counts of those
			$object->getPseudoColumns()
		);
		# only include inferred relations for STs
	    if( UNIVERSAL::isa($object,'OME::SemanticType::Superclass') ) {
			push @method_request_list, (
				keys %{$object->getInferredHasMany()},
				map( '#'.$_, keys %{$object->getInferredHasMany()} )
			)
		}
	    # add these method requests to columns. skip those that have already 
	    # been requested that may have an alias. That shouldn't happen unless
	    # someone writes sloppy requests, but it mimics the behavior of the
	    # last implementation.
    	foreach my $method ( @method_request_list ) {
	    	$requests{ $method } = $method
	    		unless exists $requests{ $method };
	    }
	}

	# force inference of relationships. This allows requests of inferred
	# methods to be granted.
	$object->getInferredHasMany();

	# Actually make the hash
    my $dto = {};
	foreach my $method_request ( keys %requests ) {
		my $dto_name = $requests{ $method_request };
		# request for a list count
		if( $method_request =~ /^#(.*)$/ ) {
			my $method = $1;
			die "Cannot find a relationship by the name of $method to count in $object" 
				unless( defined $object->getColumnType($method) );
			$method = "count_".$method;
			$dto->{ $dto_name } = $object->$method();
		# die unless the method is defined
		} elsif( not defined $object->getColumnType($method_request) ) {
			confess "Cannot find a column or relation by the name of $method_request in $object";
		# request returns a list of objects
		} elsif( $object->getColumnType($method_request) =~ /(has-many|many-to-many)/o ) {
			my @results = $object->$method_request();
			$dto->{ $dto_name } = \@results;
		# request returns a scalar or a single object
		} else {
			$dto->{ $dto_name } = $object->$method_request();
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

