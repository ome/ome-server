# OME/DBObject.pm
# This module is the superclass of any Perl object stored in the
# database.

# Copyright (C) 2002 Open Microscopy Environment, MIT
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


package OME::DBObject;

=head1 NAME

OME::DBObject - OME-specific extensions to Class::DBI

=head1 SYNOPSIS

	# Enables caching for all OME database classes
	OME::DBObject->Caching(1);

	# Enables caching for all but one class
	OME::DBObject->Caching(1);
	OME::Program->Caching(0);

	# Enables caching for all classes, but stores
	# OME::Program's separately
	OME::DBObject->Caching(1);
	OME::Program->useSeparateCache();
	     # ... load some objects ...
	OME::Program->clearCache();
	# At this point, cached OME::Programs are discarded,
	# allowing them to be reread from the database.  All
	# other cached objects remain.

=head1 DESCRIPTION

The OME system currently uses the L<Class::DBI|Class::DBI> module for
most of its database interaction.  All OME database instance classes
are declared to be subclasses of this class.  This class inherits most
of its behavior from Class::DBI, as such, its manual page should be
consulted for base behavior.

The most prominent extension to Class::DBI provided by OME::DBObject
is that of object caching.  During benchmark tests, it was noted that
the Class::DBI framework often loaded instances of database classes
for often than was necessary.  While this is the desired behavior when
the objects in the database are changing often, if they are largely
immutable than this adds an unnecessary strain to the database server,
and slows down the scripts.  Caching the objects as they are loaded
from the database can get around this problem.

The caching implemented by OME::DBObject is not an all-or-nothing
solution, however.  Caching can be enabled on a class-by-class basis,
or turned on for all classes.  Separate caches can be maintained for
each class, or all cached objects can be stored in one central cache.
Combinations of these are also supported.

The default mode of operation is for caching to be disabled, and for
all cached objects to be stored in a single cache.

=cut

use strict;
our $VERSION = '1.0';

use Log::Agent;
use Ima::DBI;
use Class::Data::Inheritable;
use Class::Accessor;
use OME::SessionManager;
use OME::DBConnection;

use base qw(Class::DBI Class::Accessor Class::Data::Inheritable);

__PACKAGE__->mk_classdata('AccessorNames');
__PACKAGE__->mk_classdata('Session');
__PACKAGE__->mk_classdata('Caching');
__PACKAGE__->mk_classdata('__cache');
__PACKAGE__->AccessorNames({});
__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
                  { RaiseError => 1 });

# Default to no caching, and a single cache for all objects.

__PACKAGE__->Caching(0);
__PACKAGE__->__cache({});


=head1 METHODS

=head2 useSeparateCache

	$class->useSeparateCache();

Forces instances of $class to be stored in a separate cache.  This is
not particularly useful without also using the clearCache method.
Calling this method directly on OME::DBObject is also not useful,
since it just redeclares the global object cache.  This is a
irreversible operation over the lifetime of one Perl instance.

NOTE: Calling this method (either on OME::DBObject or a subclass)
after objects have already been stored in the appropriate cache will
cause that cache to be cleared.  Calling this method on a subclass for
the first time, after objects of that class have already been loaded
from the database, will E<not> cause those objects to be removed from
the global cache.  It E<will>, however, orphan them, as the caching
mechanism will no longer look in the global cache for this class.

=cut

sub useSeparateCache {
    my ($class) = @_;
    # Create a separate cache for this class.
    # (Class::Data::Inheritable does most of the work.)
    $class->__cache({});
}

=head2 clearCache

	$class->clearCache();

Causes the cache for $class to be emptied.  The objects will be
eligible for garbage collection, assuming there are no other
references to them in other code.  Subsequent objects of this class
will be reloaded from the databases.  If this method is called on
OME::DBObject, or on a subclass which has not had useSeparateClass
called on it, then the global cache will be emptied.

=cut

sub clearCache {
    my ($class) = @_;
    my $cache = $class->__cache();
    %$class = ();
}


# These next two methods check the cache first for the appropriate
# object, if caching is enabled.  If caching is disabled, or the
# object is not in the cache, these methods delegate to the behavior
# inherited from Class::DBI.

sub retrieve {
    my ($class,$id) = @_;

    if ($class->Caching()) {
        # Check the cache

        my $cache = $class->__cache();
        if (exists $cache->{$class}->{$id}) {
            # Found it

            logdbg "debug", "Retrieving from cache $class.$id";
            return $cache->{$class}->{$id};
        }

        # Object not found, so delegate
        logdbg "debug", "Loading object $class.$id";
        my $object = $class->SUPER::retrieve($id);

        # Storing the object here turns out to be unnecessary, as
        # retrieve calls construct, which will fill in the cache on
        # its own.

        # $cache->{$class}->{$id} = $object;

        return $object;
    } else {
        # Caching off, so delegate
        return $class->SUPER::retrieve($id);
    }
}

sub construct {
    my ($proto,$data) = @_;
    my $class = ref $proto || $proto;

    if ($proto->Caching()) {
        my $cache = $proto->__cache();
        my $primary = $class->primary_column();
        my $id = $data->{$primary};

        # Check the cache
        if (exists $cache->{$class}->{$id}) {
            # Found it

            logdbg "debug", "Retrieving from cache $class.$id\n";
            return $cache->{$class}->{$id};
        }

        # Object not found, so delegate
        logdbg "debug", "Creating object $class.$id\n";
        my $object = $proto->SUPER::construct($data);

        # Store the object in the cache
        $cache->{$class}->{$id} = $object;
        return $object;
    } else {
        # Caching disabled, so delegate
        return $proto->SUPER::construct($data);
    }
}


# I put these next two routines in to aid in debugging.  Setting the
# OME_CLASS_DBI_DEBUG environment variable to 1 will cause a debug
# message to be displayed whenver this method is called.  Be
# forewarned, it gets called a _lot_.  --DC

sub columns {
    my ($class) = shift;

    if (exists $ENV{OME_CLASS_DBI_DEBUG} &&
        $ENV{OME_CLASS_DBI_DEBUG} eq '1') {
        logtrc "debug", "${class}->columns being called (".join(',',@_).")";
    }

    $class->SUPER::columns(@_);
}

sub _set_columns {
    my ($class) = shift;

    if (exists $ENV{OME_CLASS_DBI_DEBUG} &&
        $ENV{OME_CLASS_DBI_DEBUG} eq '1') {
        logtrc "debug", "${class}->_set_columns being called (".join(',',@_).")";
    }

    $class->SUPER::_set_columns(@_);
}

sub delete {
    logcarp "Class::DBI::delete disabled";
    return;
}


# Accessors
# ---------

sub ID {
    my $self = shift;
    return $self->id(@_);
}

sub accessor_name {
    my ($class, $column) = @_;
    my $names = $class->AccessorNames();
    return $names->{$column} if (exists $names->{$column});
    return $column;
}
sub DBH { my $self = shift; return $self->db_Main(); }


# Field accessor
# --------------

sub Field {
    my $self = shift;
    my $field = shift;

    return $self->$field(@_);
}


=head2 writeObject

	$dbObject->writeObject();

This instance methods writes any unsaved changes to the database, and
then commits the database transaction.

=cut


sub writeObject {
    my $self = shift;
    $self->commit();
    $self->dbi_commit();
    return;
}

=head2 dissociateObject

	$dbObject->disassociateObject('objectField');

This instance method disassociates an associated object (from a 'has a' relationship).  
The parameter passed is the field name that is used to acess the associated object.

=cut


sub dissociateObject {
    my $self = shift;
    my $field = shift;
    my $object = $self->$field();
    my $objType = ref ($object);
    return unless defined $objType and $objType;
    my $primary = $objType->primary_column();
    return unless defined $primary and $primary;

	my $nullObject = $objType->construct({$primary => undef});
	return unless defined $nullObject and $nullObject;

	$self->$field ($nullObject);
}


=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<Class::DBI|Class::DBI>, L<OME::Factory|OME::Factory>

=cut

1;
