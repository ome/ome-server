# OME/DBObject.pm
# This module is the superclass of any Perl object stored in the
# database.

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


package OME::DBObject;

use strict;
use OME;
our $VERSION = $OME::VERSION;

=head1 NAME

OME::DBObject - OME's Object/Relational mapping class

=head1 DESCRIPTION

The DBObject class provides an object/relationship mapping layer.  It
provides object-oriented access into a set of tables in a database.
It is used by declaring DBObject subclasses to represent logically
similar objects.  Usually this corresponds to the notion of rows
within a database table, but it is possible for a single DBObject
subclass to span multiple tables.  (In this case, each table must
contain a primary key column, which is used to link rows in the
separate tables.)

For more information on the use of the DBObject class, please see the
B<I<(as-yet-unwritten)>> OME Database Introduction.

=cut

use Carp;
use Class::Data::Inheritable;
use UNIVERSAL::require;
use OME::Database::Delegate;

use base qw(Class::Data::Inheritable);
use fields qw(__id __fields __changedFields);

# The columns known about each class.
# __columns()->{$alias} = [$table,$column,$optional_fkey_class,$sql_options]
__PACKAGE__->mk_classdata('__columns');

# The locations known about each class.
# __locations()->{$table}->{$column} = \@aliases
__PACKAGE__->mk_classdata('__locations');

# The "default" (usually "only") table
__PACKAGE__->mk_classdata('__defaultTable');

# The tables this class is stored in.  (This is a hash whose values
# are undef, to simulate a set.)
__PACKAGE__->mk_classdata('__tables');

# The primary key columns (at most one per table)
# __primaryKeys()->{$table} = $column
__PACKAGE__->mk_classdata('__primaryKeys');

# Columns which can be used to delete
# __primaryKeys()->{$table} = [$column,...]
__PACKAGE__->mk_classdata('__deleteKeys');

# A list of the has-many accessors which have been defined, stored as a
# hash-set (contents in keys, "undef" in values)
__PACKAGE__->mk_classdata('__hasManys');

# The sequence used to get new primary key ID's
__PACKAGE__->mk_classdata('__sequence');

# Whether this class has been defined
__PACKAGE__->mk_classdata('__classDefined');

# Whether this class is cached
__PACKAGE__->mk_classdata('Caching');

# Interim fix added by IGG to avoid errors in things that try to use the cache.
__PACKAGE__->mk_classdata('__cache'); 
__PACKAGE__->__cache({}); 

# List of classes that have requested separate caches
our @__nonGlobalCaches;

__PACKAGE__->Caching(1);
__PACKAGE__->__classDefined(0);

our $SHOW_SQL = 0;
our $EPSILON = 1e-6;

my %realTypes = (
                 'float'            => 1,
                 'double'           => 1,
                 'real'             => 1,
                 'double precision' => 1,
                );


=head1 METHODS - Caching

The DBObject class provides an object cache, whose main purpose is to
prevent a single row in the database from being represented by more
than one DBObject instance in memory at a single time.  The following
methods are available for controlling this cache.

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
from the database, will I<not> cause those objects to be removed from
the global cache.  It I<will>, however, orphan them, as the caching
mechanism will no longer look in the global cache for this class.

=cut

sub useSeparateCache {
    my ($class) = @_;
    # Create a separate cache for this class.
    # (Class::Data::Inheritable does most of the work.)
    $class->__cache({});
    my $class_name = ref( $class ) || $class;
    OME::DBObject->__addNonGlobalCache( $class_name );
}

sub __addNonGlobalCache {
	shift;
	push @__nonGlobalCaches, shift;
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
    %$cache = ();
}


=head2 clearAllCaches

	$class->clearAllCaches();

Causes all DBObject caches for to be emptied, including classes that
are using separare caches.

=cut


sub clearAllCaches {
	my $self = shift;
	$self->clearCache();
	$_->clearCache() foreach @__nonGlobalCaches;
	
}

sub isRealType {
    my ($class,$type) = @_;
    return 0 unless defined $type;
    return $realTypes{$type} || 0;
}

=head1 METHODS - Defining DBObject subclasses

Each DBObject subclass should use the methods in this section to
declare its logical columns and the database tables that contain them.

=head2 newClass

	package MyNewClass;
	use base qw(OME::DBObject);

	__PACKAGE__->newClass();

This should be the first method called for any new DBObject subclass.
It ensures that the variables used to maintain the class's metadata
are initialized to the appropriate values.

=cut

sub newClass {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    $class->__classDefined(1);
    $class->__columns({});
    $class->__locations({});
    $class->__defaultTable(undef);
    $class->__tables({});
    $class->__primaryKeys({});
    $class->__deleteKeys({});
    $class->__hasManys({});
    $class->__sequence(undef);

    return;
}

=head2 setDefaultTable

	__PACKAGE__->setDefaultTable($table_name);

Sets the default table for this DBObject subclass.  After this method
has been called, later method calls which refer to database locations
can use the "COLUMN" form rather than the "TABLE.COLUMN" form; the
default table will be implied.  Note that this implication takes place
when the database locations are I<defined>, not when they're I<used>,
so it is safe to use this method more than once.

=cut

sub setDefaultTable {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $table = shift;
    die "setDefaultTable called with no parameters"
      unless defined $table;

    $table = lc($table);

    $class->__defaultTable($table);

    # Maintain a list of all the tables this class is stored in.
    $class->__tables()->{$table} = undef;

    return;
}

=head2 setSequence

	__PACKAGE__->setSequence($sequence_name);

Subclasses which have primary keys should call this method to specify
which database sequence is used to provide values for the primary key.
New values are obtained by passing the $sequence_name parameter into
the OME::Database::Delegate->getNextSequenceValue method.

=cut

sub setSequence {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $sequence = shift;
    die "setSequence called with no parameters"
      unless defined $sequence;

    $class->__sequence($sequence);
    return;
}

=head2 addPrimaryKey

	__PACKAGE__->addPrimaryKey($location);

Declares a primary key column for this subclass.  Subclasses which
span multiple database tables should define a primary key column for
each one.

The $location parameter should be in one of two forms: "TABLE.COLUMN"
or "COLUMN".  The second form can only be used if the setDefaultTable
method has been called previously.

=cut

sub addPrimaryKey {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($location) = @_;

    # Verify that the location is valid.
    my ($table,$column) = $class->__verifyLocation($location);

    #print "Adding primary key $table.$column to $class\n";

    # Add an entry to __primaryKeys
    $class->__primaryKeys()->{$table} = $column;

    # Maintain a list of all the tables this class is stored in.
    $class->__tables()->{$table} = undef;

    # Make an extra, deprecated accessor for the primary key, as long as
    # there isn't already an alias of this name
    if (!defined $class->__columns()->{$column}) {
        my $accessor = sub {
            return shift->id();
        };

        no strict 'refs';
        *{"$class\::$column"} = $accessor;
    }

    return;
}

=head2 addDeleteKey

	__PACKAGE__->addDeleteKey($location);

Declares a delete key column for this subclass.  A delete key is
basically a big huge hack, which allows DBObject classes which don't
have primary keys to be deleted.  Currently the only cases of this are
the many-to-many mapping classes between projects, datasets, and
images.  They should be used with extreme prejudice, and will
hopefully be replaced with something more robust in the near future.

The $location parameter should be in one of two forms: "TABLE.COLUMN"
or "COLUMN".  The second form can only be used if the setDefaultTable
method has been called previously.

=cut

sub addDeleteKey {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($location) = @_;

    # Verify that the location is valid.
    my ($table,$column) = $class->__verifyLocation($location);

    #print "Adding delete key $table.$column to $class\n";

    # Add an entry to __deleteKeys
    $class->__deleteKeys()->{$table}->{$column} = undef;

    # Maintain a list of all the tables this class is stored in.
    $class->__tables()->{$table} = undef;

    return;
}

=head2 addColumn

	__PACKAGE__->addColumn($aliases,$location);
	__PACKAGE__->addColumn($aliases,$location,$fkey);
	__PACKAGE__->addColumn($aliases,$location,\%sql_options);
	__PACKAGE__->addColumn($aliases,$location,$fkey,\%sql_options);

Adds a new logical data column to this subclass.  It also creates new
accessor/mutator methods for this subclass for reading and writing
values for this column.  These new accessors are instance methods
which accept a single optional parameter.  If called with a parameter,
that instance's value for this column is set to the specified value.
If called without a parameter, that instance's value is returned.

The $aliases parameter specifies the name(s) that this column to be
referred to as by other code.  This includes the keys to data hashes
(for new* and find* methods) and the names of the accessors which are
created.  The parameter can either be a single alias (as a scalar), or
an array reference of aliases.  These aliases should be valid Perl
method identifiers.  Most often, at least one alias will be the same
as the name of the underlying database column.

The $location parameter specifies where in the database this column is
stored.  It should be in one of two forms: "TABLE.COLUMN" or "COLUMN".
The second form can only be used if the setDefaultTable method has
been called previously.

If specified, the $fkey parameter (which must be a scalar) should
specify the name of another DBObject subclass (the "foreign-key
class").  This declares that this data column is a foreign-key column,
and implies that it will contain an integer value.  This integer value
is interpreted as the primary key ID of an instance of the specified
foreign-key class.  The accessors which are created will automatically
load in the appropriate foreign-key instance from the database, and
return it, instead of the stored integer.  The mutator version of
these methods will accept either an integer primary key ID, or an
instance of the foreign-key class (and no other class).

The $fkey parameter can also be used to store attributes, if the $fkey
parameter is of the form "@SemanticTypeName".  In this case, the
inflation-deflation described above will be performed by the factory's
C<loadAttribute> method, rather than the C<loadObject> method.

If specified, the \%sql_options parameter (which must be a hash
reference) specifies options which are used by the database delegate
to create this column in the database.  It specifies, among other
things, the underlying SQL data type of the column.  Currently, the
following keys are supported:

=over

=item SQLType

The SQL type of the data column.  Any standard SQL type is valid.
Non-standard, database-specific types should be avoided.

=item Default

Provides a default value for this column.  It can be any value which
can be substituted into a '?' slot in a standard DBI statement.  This
corresponds to the DEFAULT clause of the CREATE TABLE statement.

=item NotNull

Should be a Boolean value (0 or 1), defaults to 0.  Specifies whether
this column has a NOT NULL constraint.

=item Unique

Should be a Boolean value (0 or 1), defaults to 0.  Specifies whether
this column has a UNIQUE constraint.

=item ForeignKey

Should be a table name.  This adds a foreign-key referential integrity
restriction to the underlying database table.  Most database products
enforce this restriction, and do not allow values that do not
correspond to existing rows in the foreign-key table.  Note that this
SQL option and the DBObject-specific foreign-key behavior specified by
the $fkey parameter are not related: Specifying one does not
automatically specify the other, and the $fkey behavior does I<not>
require this SQL option in order to work.

=item Check

Adds a CHECK constraint to the underlying column.  This value for this
key should be a standard SQL expression, which is substituted directly
into the CREATE TABLE statement.

=back

Different logical columns (each specified by a single call to
addColumn) can live in the same database location (specified by the
$location parameter).  (This is useful in case you want to provide an
accessor for retrieving a foreign-key ID in addition to one for
retrieving a foreign-key object.)  In this case, exactly one of the
logical columns should provide the \%sql_options parameter.  If none
of them do, the database location will never be created, and the
database operations will most likely generate "column missing" errors.
If more than one does, the database delegate will try to create a
table with two identically-named columns, which is a database error.

=cut

sub __isClassName ($) {
    my $class_name = shift;
    return $class_name =~ /^\w+(\:\:\w+)*$/;
}

sub __isSTReference ($) {
    my $ref = shift;
    return $ref =~ /^\@\w+$/;
}

sub addColumn {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # First two params are always the alias(es) and DB location.
    my $aliases = shift;
    my $location = shift;

    # If the next parameter is a scalar, it's the fkey class.
    my $foreign_key_class = shift if (!ref($_[0]));

    # Any hash ref at the end is the SQL option hash.
    my $sql_options = shift if (ref($_[0]) eq 'HASH');

    # $aliases can be specified either as an array ref, or as a single
    # scalar.  If it's a scalar, wrap it in an array ref to make the
    # later code simpler.
    $aliases = [$aliases] if !ref $aliases;

    # Verify that the location is valid.
    my ($table,$column) = $class->__verifyLocation($location);

    # Verify that the foreign key class, if specified, is valid.
    if (defined $foreign_key_class) {
        die "Malformed class name $foreign_key_class"
          unless __isClassName($foreign_key_class)
              || __isSTReference($foreign_key_class);
    }

    #print "Adding $table.$column to $class\n";

    foreach my $alias (@$aliases) {
        die "Already a column named $alias"
          if defined $class->getColumnType($alias);

        # Create an entry in __columns
        $class->__columns()->{$alias} = [$table,$column,
                                         $foreign_key_class,
                                         $sql_options];

        # Create an accessor/mutator
        my $accessor;

        if (defined $foreign_key_class) {
            if (__isClassName($foreign_key_class)) {
                $accessor = sub {
                    my $self = shift;
                    die "This instance did not load in $alias"
                      unless exists $self->{__fields}->{$table}->{$column};
                    if (@_) {
                        $self->{__changedFields}->{$table}->{$column}++;
                        my $datum = shift;
                        $datum = $datum->id() if ref($datum);
                        return $self->{__fields}->{$table}->{$column} = $datum;
                    } else {
                        my $datum = $self->{__fields}->{$table}->{$column};
                        return $datum if ref($datum);
                        # This should load the object from the cache if
                        # it's already been retrieved from the DB.
                        return $self->Session()->Factory()->
                          loadObject($foreign_key_class,$datum);
                    }
                };
            } else {
                # Remove the leading @
                my $st_name = substr($foreign_key_class,1);

                $accessor = sub {
                    my $self = shift;
                    die "This instance did not load in $alias"
                      unless exists $self->{__fields}->{$table}->{$column};
                    if (@_) {
                        $self->{__changedFields}->{$table}->{$column}++;
                        my $datum = shift;
                        if (ref($datum)) {
                            $datum->verifyType($st_name);
                            $datum = $datum->id();
                        }
                        return $self->{__fields}->{$table}->{$column} = $datum;
                    } else {
                        my $datum = $self->{__fields}->{$table}->{$column};
                        return $datum if ref($datum);
                        # This should load the object from the cache if
                        # it's already been retrieved from the DB.
                        return $self->Session()->Factory()->
                          loadAttribute($st_name,$datum);
                    }
                };
            }
        } else {
            # It seems that sometimes the Postgres driver will return 1
            # or 0 for a boolean column, sometimes 't' or 'f'.  This is
            # unacceptable, so we define the accessor method to always
            # return 1 or 0.

            if (defined $sql_options->{SQLType} &&
                $sql_options->{SQLType} eq 'boolean') {
                $accessor = sub {
                    my $self = shift;
                    die "This instance did not load in $alias"
                      unless exists $self->{__fields}->{$table}->{$column};
                    my $value;
                    if (@_) {
                        $self->{__changedFields}->{$table}->{$column}++;
                        my $datum = shift;

                        die "Illegal Boolean column value '$datum'"
                          unless $datum =~ /^f(alse)?$|^t(rue)?$|^[01]$/i;

                        $datum = 'true' if $datum eq  '1';
                        $datum = 'false' if $datum eq '0';
                        $value = $self->{__fields}->{$table}->{$column} = $datum;
                    } else {
                        $value = $self->{__fields}->{$table}->{$column};
                    }

                    return 1 if ($value =~ /^t(rue)?$/i);
                    return 0 if ($value =~ /^f(alse)?$/i);
                    return $value;
                };
            } else {
                $accessor = sub {
                    my $self = shift;
                    die "This instance did not load in $alias"
                      unless exists $self->{__fields}->{$table}->{$column};
                    if (@_) {
                        $self->{__changedFields}->{$table}->{$column}++;
                        my $datum = shift;
                        $datum = $datum->id() if ref($datum);
                        return $self->{__fields}->{$table}->{$column} = $datum;
                    } else {
                        return $self->{__fields}->{$table}->{$column};
                    }
                };
            }
        }

        no strict 'refs';
        *{"$class\::$alias"} = $accessor;
    }

    # Maintain a list of all of the aliases that a stored in a
    # database column.
    push @{$class->__locations()->{$table}->{$column}}, @$aliases;

    # Maintain a list of all the tables this class is stored in.
    $class->__tables()->{$table} = undef;

    return;
}

=head2 getColumn

	my $column_def = $class->getColumn($alias);

Returns the definition of the logical column with the specified alias.
This is mostly for internal purposes, and is used to generate the
appropriate SQL statements for the various database operations.
However, it can also be useful for reflection purposes.  The result is
an array reference of the following form:

	[$table_name,$column_name,$fkey_class,$sql_options]

These correspond to the $location (split into table and column),
$fkey, and \%sql_options parameters to the addColumn method.  If the
$fkey or \%sql_options parameters weren't specified, their entries in
the arrayref will be undef.  If the $location was specified in
"COLUMN" format, the $table_name entry will be the default table at
the time the addColumn method was called.

=cut

sub getColumn {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $alias = shift;

    return $class->__columns()->{$alias};
}

=head2 getColumnType

	my $column_type = $class->getColumnType($alias);

Returns the type of the logical column with the specified alias.  If
the column exists, the type will be one of three values -- "normal",
"has-one", or "has-many".  If the column does not exist, the method
returns undef.

=cut

sub getColumnType {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $alias = shift;

    if ($alias eq 'id') {
        return "normal";
    } elsif (defined $class->__columns()->{$alias}) {
        return defined $class->__columns()->{$alias}->[2]?
          "has-one":
          "normal";
    } elsif (exists $class->__hasManys()->{$alias}) {
        return "has-many";
    } else {
        return undef;
    }
}

=head2 hasMany

	__PACKAGE__->hasMany($aliases,$fkey_class,$fkey_alias);

Defines a has-many relationship for this subclass.  This is the
inverse of the addColumn method with an $fkey parameter specified.
This implies the the $fkey_class DBObject subclass has a logical
column with an alias of $fkey_alias.  It further implies that that
logical column was declared to be a foreign key which points to this
class.

This method will then create an accessor method which returns all of
the instances of $fkey_class whose $fkey_alias column points to the
given instance of this class.  If the accessor is called in list
context, an array of those objects is returned; if called in scalar
context, an iterator is returned (see the L<OME::Factory|OME::Factory>
class for a description of iterators).  The $aliases parameter is
specified just as in the addColumn method; it allows you to provide
multiple names for the accessor which is created.

Note that hasMany columns cannot be present in data hashes, either for
creation or searching.

=cut

sub hasMany {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($aliases, $foreign_key_class, $foreign_key_alias) = @_;

    # $aliases can be specified either as an array ref, or as a single
    # scalar.  If it's a scalar, wrap it in an array ref to make the
    # later code simpler.
    $aliases = [$aliases] if !ref $aliases;

    # Verify that the foreign key class is specified and valid.
    if (defined $foreign_key_class) {
        die "Malformed class name $foreign_key_class"
          unless $foreign_key_class =~ /^\w+(\:\:\w+)*$/;
    } else {
        die "hasMany called without a foreign key class";
    }

    #print "Adding has-many from $foreign_key_alias in $foreign_key_class to $class\n";

    my $has_manys = $class->__hasManys();

    foreach my $alias (@$aliases) {
        die "Already an alias named $alias"
          if defined $class->getColumnType($alias);

        # Create an accessor/mutator
        my $accessor = sub {
            my $self = shift;
            my $factory = $self->Session()->Factory();
            return $factory->findObjects($foreign_key_class,
                                         $foreign_key_alias => $self->{__id});
        };

        my $counter = sub {
            my $self = shift;
            my $factory = $self->Session()->Factory();
            return $factory->countObjects($foreign_key_class,
                                          $foreign_key_alias => $self->{__id});
        };

        $has_manys->{$alias} = undef;

        no strict 'refs';
        *{"$class\::$alias"} = $accessor;
        *{"$class\::count_$alias"} = $counter;
    }
}

=head2 manyToMany

	__PACKAGE__->manyToMany($aliases,$map_class,$map_alias,$map_linker);

Defines a many-to-many relationship for this subclass.  This is
basically the same thing as a has-many relationship (defined by the
C<hasMany> method), with an additional linking table.  The linking
table still must be defined as its own DBObject subclass, but once
that is done, this method can be used to provide accessors which
transparently use the mapping table.

For instance, projects and datasets have a many-to-many relationship,
involving the C<OME::Project>, C<OME::Dataset>, and
C<OME::Project::DatasetMap> classes.  In C<OME::Project>,

	__PACKAGE__->manyToMany('datasets',
	                        'OME::Project::DatasetMap',
	                        'project','dataset');

causes a C<datasets> accessor to be created (first parameter), which
loads in all of the C<OME::Project::DatasetMap> instances (second
parameter) pointing to the current project (via its C<project> alias,
third parameter).  Instead of returning those
C<OME::Project::DatasetMap> instances, though, the C<dataset> accessor
(fourth parameter) is called on each, and the results of those
accessor calls are returned.

As with all other list-retrieval accessors, if the many-to-many
accessor is called in scalar context, an iterator is returned instead
of a list.

Note that manyToMany columns cannot be present in data hashes, either
for creation or searching.

=cut

sub manyToMany {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($aliases, $map_class, $map_alias, $map_linker_alias) = @_;

    # $aliases can be specified either as an array ref, or as a single
    # scalar.  If it's a scalar, wrap it in an array ref to make the
    # later code simpler.
    $aliases = [$aliases] if !ref $aliases;

    # Verify that the foreign key class is specified and valid.
    if (defined $map_class) {
        die "Malformed class name $map_class"
          unless $map_class =~ /^\w+(\:\:\w+)*$/;
    } else {
        die "manyToMany called without a mapping class";
    }

    my $has_manys = $class->__hasManys();

    foreach my $alias (@$aliases) {
        die "Already an alias named $alias"
          if defined $class->getColumnType($alias);

        # Create an accessor/mutator
        my $accessor = sub {
            return unless defined wantarray;

            my $self = shift;
            my $factory = $self->Session()->Factory();

            if (wantarray) {
                my @links = $factory->
                  findObjects($map_class,
                              $map_alias => $self->{__id});

                foreach my $link (@links) {
                    $link = $link->$map_linker_alias();
                }

                return @links;
            } else {
                my $links = $factory->
                  findObjects($map_class,
                              $map_alias => $self->{__id});

                my $iterator = OME::Factory::LinkIterator->
                  new($links,$map_linker_alias);

                return $iterator;
            }
        };

        my $counter = sub {
            my $self = shift;
            my $factory = $self->Session()->Factory();
            return $factory->countObjects($map_class,
                                          $map_alias => $self->{__id});
        };

        $has_manys->{$alias} = undef;

        no strict 'refs';
        *{"$class\::$alias"} = $accessor;
        *{"$class\::count_$alias"} = $counter;
    }
}

=head1 METHODS - Standard instance methods

The following instance methods are defined in DBObject and are
available to all DBObject subclasses (in addition to the various
accessors automatically created by the class definition methods).

=head2 id

	my $id = $instance->id();

Returns the primary key value for instances whose subclasses have them
defined.

=cut

sub Session { return OME::Session->instance() }
sub id { return shift->{__id}; }
sub ID { return shift->{__id}; }

=head2 storeObject

	$instance->storeObject();

The mutator methods created by the addColumn method only change the
values which are in memory.  They are not automatically flushed to the
database.  (This is mainly to allow you to modify several columns
while only sending a single UPDATE statement to the database.)  This
method flushes any outstanding changes to the database.

This method does B<absolutely no transaction control whatsoever>.  You
must manage that yourself with the transaction control methods in
L<OME::Session|OME::Session>.  Note that Postgres, at least, does not
automatically commit a transaction at the end of a program, so any
uncommitted changes will not make it into the database.

=cut

sub storeObject {
    my $self = shift;

    if (%{$self->{__changedFields}}) {
        my $session = $self->Session();
        my $factory = $session->Factory();
		$factory or confess ("Failure to retrieve factory.");
        my $dbh = $factory->obtainDBH();
        eval {
            $self->__writeToDatabase($dbh);
        };
        die $@ if $@;
    }

    return;
}

=head2 deleteObject

	$instance->deleteObject();

Deletes this object from the database.  Be very careful before calling
this!  No referential integrity constraints are enforced; if the
database engine does not want you to delete this object, you will get
an error.

This method does B<absolutely no transaction control whatsoever>.  You
must manage that yourself with the transaction control methods in
L<OME::Session|OME::Session>.  Note that Postgres, at least, does not
automatically commit a transaction at the end of a program, so any
uncommitted changes will not make it into the database.

=cut

sub deleteObject {
    my $self = shift;

    my $session = $self->Session();
    my $factory = $session->Factory();
    $factory or confess ("Failure to retrieve factory.");
    my $dbh = $factory->obtainDBH();
    eval {
        $self->__deleteFromDatabase($dbh);
    };
    die $@ if $@;

    return;
}

=head2 getDataHash

	my $data_hash = $instance->getDataHash([$aliases]);

Returns the values of this instance as a hash.  The keys of the hash
are the aliases of each logical column, the values of the hash are the
values of the logical columns.  If the $aliases parameter is specified
and is an array reference, only those aliases in that arrayref will
appear in the data hash.  Otherwise, all of the subclass's aliases
will appear.  The integer primary key, if present in the subclass,
will always appear with a key of C<id>.

=cut

# Backwards-compatibility name
sub populate { shift->getDataHash(@_) }

sub getDataHash {
    my ($self,$aliases) = @_;

    unless (defined $aliases && ref($aliases) eq 'ARRAY') {
        my $columns = $self->__columns();
        my @aliases = keys %$columns;
        $aliases = \@aliases;
    }

    my %result;
    $result{$_} = $self->$_() foreach @$aliases;

    my $id = $self->id();
    $result{id} = $id if defined $id;

    return \%result;
}

=head2 getDataHashes

	my $data_hashes = MyNewClass->getDataHashes([$aliases],$list);

This is just a convenience method which calls getDataHash($aliases) on
each element of the list array reference.  Its result is an array
reference of hash references, one data hash per input DBObject
instance.

=cut

# Backwards-compatibility name
sub populate_list { shift->getDataHashes(@_) }

sub getDataHashes {
    my ($proto,$param1,$param2) = @_;

    my ($aliases,$list);
    if (defined $param2) {
        $aliases = $param1;
        $list = $param2;
    } else {
        $aliases = undef;
        $list = $param1;
    }

    my @result;
    push @result, $_->populate($aliases) foreach @$list;
    return \@result;
}

=head2 refresh

	$instance->refresh();

Refreshes this DBObject instance from the database.  If any columns
have been modified without calling storeObject, those changes will be
overwritten.  (In that sense, this method can be viewed as a "revert"
method in addition to a "refresh" method.)

=cut

sub refresh {
    my ($self) = @_;
    my $id = $self->{__id};
    my $factory = $self->Session()->Factory();

    my $columns_wanted = [keys %{$self->__columns()}];

    my ($sql,$id_available,$values) = $self->
      __makeSelectSQL($columns_wanted,{id => $id});

    my $dbh = $factory->obtainDBH();
    eval {
        my $sth = $dbh->prepare($sql) or die "Could not prepare";
        $sth->execute(@$values) or die "Could not execute";
        my $sth_vals = $sth->fetch() or die "Could not fetch";
        my $i = 0;
        $i++ if $id_available;
        $self->__fillInstance($i,$columns_wanted,$sth_vals);
    };
    confess $@ if $@;
}

=head1 METHODS - The guts

For the brave and/or foolhardy, the following methods are used
internally to implement the database I/O functionality.  They should
almost never be called from outside the OME::DBObject and
L<OME::Factory|OME::Factory> classes.  And by "almost never", I mean
"never ever".

=head2 __getCachedObject

	my $instance = $class->__getCachedObject($id);

If an object with the specified primary key ID is in the specified
class's object cache, it is returned.  Otherwise, undef is returned.

=cut

sub __getCachedObject {
    my ($proto,$id) = @_;
    my $class = ref($proto) || $proto;

    # Don't look for a cached object if caching is not enabled for
    # this object's class.
    unless ($class->Caching()) {
        #print STDERR "Not caching $class\n";
        return undef;
    }

    #print STDERR "### Looking in cache $class $id -- ";
    my $cache = $class->__cache()->{$class};
    #print STDERR defined $cache->{$id}? "FOUND\n": "NOT FOUND\n";
    return $cache->{$id};
}

=head2 __storeCachedObject

	$instance->__storeCachedObject();

Stores $instance in its class's object cache.

=cut

sub __storeCachedObject {
    my ($self) = @_;
    my $class = ref($self);

    # Don't store the object in the cache if caching is not enabled for
    # this object's class.
    return unless $class->Caching();

    my $id = $self->id();

    if (defined $id) {
        $class->__cache()->{$class}->{$id} = $self;
        #print STDERR "### Storing in cache $class $id\n";
    }

    return;
}

=head2 __activateSTColumn

	__activateSTColumn($type_name);

In order to access or search based on a column which is an attribute
reference, the semantic type that it points to must be loaded in.
This method does that.  This method assumes that the OME::SemanticType
class has already been loaded and defined, and that there is a valid
activate session object.

=cut

sub __activateSTColumn ($) {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $alias = shift;
    my $def = $class->getColumn($alias);

    return
      unless defined $def->[2]
          && __isSTReference($def->[2]);

    # Strip off the leading @
    my $st_name = substr($def->[2],1);

    OME::SemanticType->require();
    my $factory = OME::Session->instance()->Factory();
    my $st = $factory->findObject('OME::SemanticType',name => $st_name);

    die "Semantic type $st_name not found"
      unless defined $st;

    $st->requireAttributeTypePackage();
}

=head2 __verifyLocation

	my ($table,$column) = $class->__verifyLocation($location);

This method is used by the addPrimaryKey and addColumn methods to
parse the $location parameter.  It ensures that the location is in one
of the two valid forms ("COLUMN" or "TABLE.COLUMN").  If it's in the
"COLUMN" form, it ensures that a default table has been specified.
The (possibly default) table and column values are then returned,
after being converted to lowercase.

=cut

sub __verifyLocation {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Verify that location refers to a valid DB location.
    # (Alphanumeric, at most one period).

    my $location = shift;
    my ($table, $column);

    if ($location =~ /^\w+$/) {
        # Only a column was specified
        $table = $class->__defaultTable();
        die "No default table has been specified for $class"
          unless defined $table;
        $column = $location;
    } elsif ($location =~ /^(\w+)\.(\w+)$/) {
        # Both table and column were specified
        $table = $1;
        $column = $2;
    } else {
        die "Malformed database location: $location";
    }

    return (lc($table),lc($column));
}

=head2 __addJoins

	my ($first_table,$first_key) = $class->
	    __addJoins($columns_needed,$tables_used,$where_clauses);

For subclasses which span multiple tables, this method is responsible
for adding the appropriate WHERE clauses to an SQL statement to join
those tables.

The three parameters are references to the internal variables of the
SQL-generation methods.  The $columns_needed parameter is an array
reference containing the column clauses of the statement (the part
between C<SELECT> and C<FROM>).  A primary key column clause is
appended to this array if necessary.  The $table_used parameter is a
hash reference, with the keys being the names of the tables that are
needed for the SQL statement.  (There's no need to join tables which
don't appear in the statement.)  All of these tables should be defined
by this DBObject subclass.  This has is not modified.  The
$where_clauses parameter is an array reference containing the WHERE
clauses of the statement.  The necessary joins will be appended to
this list.

The return value is the first table and primary key that was found
while iterating through the $tables_used hash.  For subclasses with
primary keys, then, "${first_table}.${first_key}" is guaranteed to be
the database location of a primary key which appears in the SQL
statement.

=cut

sub __addJoins {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($columns_needed,$tables_used,$join_clauses) = @_;
    my $keys = $class->__primaryKeys();
    my ($first_table, $first_key);

    foreach my $table (keys %$tables_used) {
        my $key = $keys->{$table};
        next unless defined $key;

        if (defined $first_table) {
            push @$join_clauses, "$table.$key = $first_key";
        } else {
            $first_table = $table;
            $first_key = "$table.$key";
            unshift @$columns_needed, "$first_key as id";
        }
    }

    return ($first_table,$first_key);
}

=head2 __addForeignJoin

	my $result_key = $class->
	    __addForeignJoin($fk_number,$aliases,
	                     $foreign_tables,$foreign_aliases,$join_clauses);

Used by the __getQueryLocation method to add a foreign-key join clause
to an SQL statement.  The $aliases parameter should be an array
reference, and should contain the result of splitting a foreign-key
alias on periods.  A foreign-key alias allows you to follow an
arbitrary number of foreign-key fields in a search clause.  All but
the last alias in the array I<must> be a foreign-key alias.  (The last
one I<can> be, but does not have to be.)  Further, each foreign-key
alias must belong to the class pointed to by the previous foreign-key
in the list.  (The examples provided in the "Search criteria" section
of the L<OME::Factory|OME::Factory> documentation should make things
clearer.)

The $fk_number parameter should be a reference to an integer counter;
it is used as a nonce to guarantee the uniqueness of any table
re-names added to the FROM clause of the statement.  The
$foreign_tables parameter should be an array reference of the FROM
clauses of the statement.  Any new foreign-key tables needed to
satisfy the foreign-key clause are added to this list.  The
$join_clauses parameter is an array reference of the WHERE clauses of
the statement.  The joins needed to add the foreign-key tables are
added to this list.

The $foreign_aliases parameter is a hash reference.  It will contain
the statement-specific names of each foreign-key alias in the search
query, taking into account any table-renaming needed to ensure the
uniqueness of the table names in the statement.

After this method returns, $foreign_aliases->{$result_key} will be a
two-element array reference.  Joining these two elements with a period
gives a statement location for the requested foreign-key alias.  This
statement location is suitable for using in a column, WHERE, ORDER BY,
or GROUP BY clause.

=cut

sub __addForeignJoin {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($foreign_key_number,$aliases,
        $foreign_tables,$foreign_aliases,$join_clauses) = @_;

    if (scalar(@$aliases) < 1) {
        confess "Cannot create foreign key joins if there aren't any dereferences";
    } elsif (scalar(@$aliases) == 1) {
        # Base case - no dereferences
        my $alias = $aliases->[0];

        if (!exists $foreign_aliases->{$alias}) {
            my $columns = $class->__columns();
            my $column = $columns->{$alias};
            $foreign_aliases->{$alias} = $column;

            # If this is an ST column, load in the ST's package
            $class->__activateSTColumn($alias);
        }
        return $alias;
    } else {
        my $target_alias = pop(@$aliases);
        my $local_alias = $class->
          __addForeignJoin($foreign_key_number,$aliases,
                           $foreign_tables,$foreign_aliases,
                           $join_clauses);
        my $full_alias = "${local_alias}.${target_alias}";

        if (!exists $foreign_aliases->{$full_alias}) {
            my $column = $foreign_aliases->{$local_alias};
            #print STDERR "$column ",join(',',@$column),"\n";

            confess "$local_alias is not a reference -- cannot add a foreign key table"
              unless defined $column->[2];
            my $local_table_alias = $column->[0];
            my $local_column_name = $column->[1];
            my $fkey_class = $column->[2];

            my $target_columns = $fkey_class->__columns();
            my $target_column = $target_columns->{$target_alias};
            my $target_table_name = $target_column->[0];
            my $target_column_name = $target_column->[1];
            my $target_pkeys = $fkey_class->__primaryKeys();
            confess "Cannot create foreign join -- $fkey_class has no primary key"
              unless exists $target_pkeys->{$target_table_name};
            my $target_pkey = $target_pkeys->{$target_table_name};
            my $number = $$foreign_key_number++;
            my $target_table_alias = "fkey${number}_${target_table_name}";

            push @$foreign_tables, "$target_table_name $target_table_alias";
            #print STDERR "$target_table_name $target_table_alias $target_column_name\n";

            # Make a copy of the old column entry, so that we can
            # replace the table name with its SQL alias.
            my $new_column = [@$target_column];
            $new_column->[0] = $target_table_alias;
            $foreign_aliases->{$full_alias} = $new_column;

            # If this is an ST column, activate it
            $fkey_class->__activateSTColumn($target_alias);

            push @$join_clauses,
              "${target_table_alias}.${target_pkey} = ".
              "${local_table_alias}.${local_column_name}";
        }

        return $full_alias;
    }

}

=head2 __getQueryLocation

	my $location = $class->
	    __getQueryLocation($fkey_number,$foreign_tables,$foreign_aliases,
	                       $where_clauses,$tables_used,$column_alias);

This method performs the meat of the SQL-generation methods.  It is
responsible for taking an arbitrary alias expression for this class
($column_alias) and turning it into a simple, statement-specific
"TABLE.COLUMN" expression.  This alias might possibly follow an
arbitrary number of foreign-key relationships, as described in the
"Search criteria" section of L<OME::Factory|OME::Factory>.  The table
portion of the returned location might not correspond to an actual
database table name; table re-naming is used in the statement to
ensure that if a single database table appears in the statement more
than once, each copy has a distinct name.  The location which is
returned is suitable for using in a column, WHERE, ORDER BY, or GROUP
BY clause.

All of the other parameters (besides $column_alias) are part of the
internal state of the SQL-generation methods.  The $fkey_number is a
reference to an integer counter, which is a nonce used by the
__addForeignKeyJoins method.  The tables which appear in the statement
appear in the $foreign_tables arrayref and the $tables_used hashref.
(The first is for foreign-key tables, the second for tables for this
subclass's data.)  The $where_clauses parameter is an arrayref of the
WHERE clauses for this statement.  It is augmented as necessary to
include the joins necessary for the tables in the statement.  The
$foreign_aliases parameter is a hashref which is used by the
__addForeignJoins method to ensure that each foreign alias is only
added to the statement once.  (It's safest to assume that it's
opaque...)

=cut

sub __getQueryLocation {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($foreign_key_number,
        $foreign_tables,$foreign_aliases,$join_clauses,
        $tables_used,$column_alias) = @_;

    my $location;
    if ($column_alias eq 'id') {
        $location = "id";
    } elsif ($column_alias =~ /\./) {
        # If there's a period, then we'll need to do some
        # foreign joins.

        my @aliases = split(/\./,$column_alias);
        my $foreign_alias = $class->
          __addForeignJoin($foreign_key_number,\@aliases,
                           $foreign_tables,$foreign_aliases,
                           $join_clauses);
        my $foreign_column = $foreign_aliases->{$foreign_alias};

        $location = $foreign_column->[0].".".$foreign_column->[1];
    } else {
        my $column = $class->__columns()->{$column_alias};
        confess "Column $column_alias does not exist"
          unless defined $column;
        $location = $column->[0].".".$column->[1];
        $tables_used->{$column->[0]} = undef;
    }

    return $location;
}

=head2 __makeSelectSQL

	my ($sql,$id_available,$values) = $class->
	    __makeSelectSQL($columns_wanted,$criteria);

Creates an SQL statement suitable for retrieving instances of this
subclass which match the specified search criteria.  (Search criteria
are described in the L<OME::Factory|OME::Factory> documentation.)  If
defined, the $columns_wanted parameter should be an array references
of aliases for this subclass; the SQL statement will only contain
enough column clauses to populate those logical columns.  If it is not
specified, everything will be filled in.

The $sql result will be the text of the SQL statement.  The
$id_available result will be a Boolean indicating whether the SQL
statement returns a primary key.  If so, it will be in an SQL column
named C<id>.  The $values result will be an array reference of the
values for the SQL statement.  These should be used as the bind values
for the DBI call; this array is guaranteed to be in the same order as
any ?-placeholders which appear in the SQL statement.

=cut

sub __makeSelectSQL {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($columns_wanted,$criteria) = @_;

    # These three variables will correspond to the four sections of
    # the SELECT statement: the list of columns, the list of tables,
    # the WHERE clause, and the ORDER BY clause.
    my @columns_needed;
    my %tables_used;
    my @foreign_tables;
    my %foreign_aliases;
    my @join_clauses;
    my @values;
    my @order_by;

    my $columns = $class->__columns();
    my $count_only = 0;

    # Add each requested column to the @columns_needed array.  The
    # contents of this array are valid DB locations, so we build this
    # as necessary from the contents of the __columns array.  This
    # loop also populates the %tables_used hash.

    if ((!defined $columns_wanted) || (ref($columns_wanted) eq 'ARRAY')) {
        # If the wanted columns aren't specified, get them all.
        if ((!defined $columns_wanted) || (scalar(@$columns_wanted) <= 0)) {
            $columns_wanted = [keys %{$class->__columns()}];
        }

        foreach my $column_alias (@$columns_wanted) {
            my $column = $columns->{$column_alias};
            confess "Column $column_alias does not exist"
              unless defined $column;

            push @columns_needed, $column->[0].".".$column->[1];

            # We are just using the keys of this hash, so the value is
            # unimportant.
            $tables_used{$column->[0]} = undef;
        }
    } elsif ($columns_wanted eq 'COUNT') {
        $count_only = 1;
        %tables_used = (%{$class->__tables()});
    }

    # Set to one if any of the criteria refers to the primary key,
    # whose column name isn't known until we've figured out which
    # tables we have to include.
    my $id_criteria = 0;

    # Same, but for ORDER BY
    my $id_order = 0;

    # A counter used to construct unique table aliases for any foreign
    # tables we join with.  (We can't just use the foreign table name,
    # because each table might occur in the query more than once.)
    my $foreign_key_number = 0;

    # Any LIMIT or OFFSET clause found in the criteria
    my ($limit,$offset);

    # Look through the criteria, if there are any.  Add the criteria
    # entries to the WHERE clause list, and also make sure that the
    # tables used by each criterion are in the %tables_used hash.
    if (defined $criteria) {

        # Pull out and parse the ORDER BY clause, if one exists
        my $order_by = $criteria->{__order};
        delete $criteria->{__order};
        $order_by ||= [];
        $order_by = [$order_by] unless ref($order_by);

        foreach my $column_alias (@$order_by) {
            my $location = $class->
              __getQueryLocation(\$foreign_key_number,
                                 \@foreign_tables,\%foreign_aliases,
                                 \@join_clauses,\%tables_used,
                                 $column_alias);
            $id_order = 1 if $location eq 'id';
            push @order_by, $location;
        }

        # Parse any LIMIT or OFFSET clause

        if (exists $criteria->{__limit}) {
            $limit = $criteria->{__limit};
            delete $criteria->{__limit};
            die "Invalid LIMIT clause $limit -- must be an integer"
              unless $limit =~ /^\d+$/;
        }

        if (exists $criteria->{__offset}) {
            $offset = $criteria->{__offset};
            delete $criteria->{__offset};
            die "Invalid OFFSET clause $offset -- must be an integer"
              unless $offset =~ /^\d+$/;
        }

        # Parse the remaining criteria

        foreach my $column_alias (keys %$criteria) {
            my $location = $class->
              __getQueryLocation(\$foreign_key_number,
                                 \@foreign_tables,\%foreign_aliases,
                                 \@join_clauses,\%tables_used,
                                 $column_alias);

            my $criterion = $criteria->{$column_alias};
            my ($operation,$value);

            my $question = '?';

            # If the value is an object, assume that it has an id
            # method, and use that in the SQL query.

            my @new_values;

            if (ref($criterion) eq 'ARRAY') {
                $value = $criterion->[1];
                if (ref($value) eq 'ARRAY') {
                    my @questions;
                    foreach my $arrayval (@$value) {
                        if (defined $arrayval) {
                            push @questions, '?';
                            $arrayval = $arrayval->id()
                              if UNIVERSAL::isa($arrayval,"OME::DBObject");
                            push @new_values, $arrayval;
                        }
                    }
                    $question = '('.join(',',@questions).')';
                } else {
                    $value = $value->id()
                      if UNIVERSAL::isa($value,"OME::DBObject");
                    push @new_values, $value;
                }
                $operation = defined $value? $criterion->[0]: "is";
            } else {
                $value = $criterion;
                $value = $value->id()
                  if UNIVERSAL::isa($value,"OME::DBObject");
                push @new_values, $value;
                $operation = defined $value? "=": "is";
            }

            my $sql_type = exists $columns->{$column_alias}?
              $columns->{$column_alias}->[3]->{SQLType}:
              "";

            if ($location eq 'id') {
                push @join_clauses, [$operation, $question];
                $id_criteria = 1;
            } elsif ($sql_type eq 'boolean') {
                # If the column is Boolean, 1/0 won't work.
                foreach my $value (@new_values) {
                    die "Illegal Boolean column value '$value'"
                      unless $value =~ /^f(alse)?$|^t(rue)?$|^[01]$/i;

                    $value = 'true' if $value eq '1';
                    $value = 'false' if $value eq '0';
                }
                push @join_clauses, "$location $operation $question";
            } elsif ($class->isRealType($sql_type) && $operation eq '=') {
                # If the column is a float, = won't work.
                push @join_clauses, "abs($location - $question) < ?";
                push @new_values, $EPSILON;
            } else {
                push @join_clauses, "$location $operation $question";
            }

            push @values, @new_values;
        }
    }

    # Add appropriate JOIN clauses to the array of WHERE clauses if
    # more than one table was found in the list of requested columns.

    my ($first_table,$first_key) =
      $class->__addJoins(\@columns_needed,\%tables_used,\@join_clauses);

    # Go through and replace all of the criteria applying to the
    # primary key ID with the actual primary key field in the SQL
    # statement
    if ($id_criteria) {
        die "Cannot search for an ID; none is in the SQL statement!"
          unless defined $first_key;
        map { $_ = "$first_key ".$_->[0]." ".$_->[1] if ref($_); } @join_clauses;
    }

    if ($id_order) {
        die "Cannot order by an ID; none is in the SQL statement!"
          unless defined $first_key;
        map { $_ = $first_key if $_ eq 'id' } @order_by;
    }

    my $sql;

    if ($count_only) {
        $sql = "select count(*) from ".
          join(", ",
               keys(%tables_used),
               @foreign_tables
              );
    } else {
        $sql = "select ". join(", ",@columns_needed). " from ".
          join(", ",
               keys(%tables_used),
               @foreign_tables
              );
    }

    $sql .= " where ". join(" and ",@join_clauses)
      if scalar(@join_clauses) > 0;

    # The ORDER BY, LIMIT, and OFFSET clauses are not added if we're
    # only retrieving a count.

    if (!$count_only) {
        $sql .= " order by ". join(", ",@order_by)
          if scalar(@order_by) > 0;

        if (defined $limit) {
            die "Illegal limit value $limit"
              unless $limit =~ /^\d+$/;
            $sql .= " limit $limit";
        }

        if (defined $offset) {
            die "Illegal offset value $offset"
              unless $offset =~ /^\d+$/;
            $sql .= " offset $offset";
        }
    }

    print STDERR "\n$sql\n" if $SHOW_SQL;
    print STDERR join(',',@values),"\n" if $SHOW_SQL;

    return ($sql,defined $first_key,\@values);
}

=head2 __makeInsertSQLs

	my ($sqls,$new_key) = $class->__makeInsertSQLs($dbh,$data_hash);

Creates a series of SQL INSERT statements suitable for creating a new
instance of this DBObject subclass.  The values for the new instance
must be specified by the $data_hash.  Any database columns not
specified by this hash will be filled with NULLs, or with any default
values specified by the Default SQL option of the addColumn method.

One INSERT statement will be returned for each database table which
contains this DBObject subclass.  If the subclass defines a primary
key, a new value will be retrieved from the subclass's sequence, and
returned in the $new_key result.  (It will also be included in the
INSERT statements.)

The $sqls result has the form

	[ [$sql,$values], ... ]

Where each $sql entry is the text of an INSERT statement, and the
$values entry is an arrayref of bind values for that statement.  Both
can be passed directly into the appropriate DBI method for execution.

=cut

sub __makeInsertSQLs {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($dbh,$data_hash) = @_;

    my @fields = keys %$data_hash;

    my %tables_used;
    my %columns_needed;
    my %values_needed;
    my %new_values;

    my $sequence = $class->__sequence();
    my $columns = $class->__columns();
    my $keys = $class->__primaryKeys();

    my $key_val;

    foreach my $alias (@fields) {
        my $datum = $data_hash->{$alias};
        $datum = $datum->id() if ref($datum);

        #print "   $alias\n";

        if ($alias eq '__id') {
            #print "     ID! $datum\n";
            $key_val = $datum;
            next;
        }

        my $column_def = $columns->{$alias};
        confess "Column $alias does not exist"
          unless defined $column_def;
        my ($table, $column, $foreign_key_class, $sql_options) = @$column_def;

        if (defined $sql_options &&
            $sql_options->{SQLType} eq 'boolean' and 
            defined $datum ) {

            # This is a Boolean column, so we need to make sure that
            # the value is 'true' or 'false', not 1 or 0.

            # FIXME: Eventually, this should move into the
            # DatabaseDelegate, since this Boolean translation is
            # Postgres-specific.

            die "Illegal Boolean column value '$datum'"
              unless $datum =~ /^f(alse)?$|^t(rue)?$|^0$|^1$/i;

            $datum = 'false' if $datum eq '0';
            $datum = 'true' if $datum eq '1';
        }

        $tables_used{$table} = undef;
        push @{$columns_needed{$table}}, $column;
        push @{$values_needed{$table}}, "?";
        push @{$new_values{$table}}, $datum;
    }

    my $delegate = OME::Database::Delegate->getDefaultDelegate();
    $key_val =
      $delegate->getNextSequenceValue($dbh,$sequence)
      if (!defined $key_val) && (defined $sequence);

    my @sqls;
    foreach my $table (keys %tables_used) {
        #print "Table $table '$key_val'\n";
        my $columns = $columns_needed{$table};
        my $column_holders = $values_needed{$table};
        my $values = $new_values{$table};
        my $key = $keys->{$table};

        die "Cannot insert into $table if we don't know the primary key!"
          if defined $key && !defined $key_val;

        if (defined $key) {
            unshift @$columns, $key;
            unshift @$column_holders, "?";
            unshift @$values, $key_val;
        }

        my $sql = "insert into $table (". join(", ",@$columns).
          ") values (". join(", ",@$column_holders). ")";
        push @sqls, [$sql,$values];
    }

    print STDERR "\n",join("\n",map {$_->[0]} @sqls),"\n" if $SHOW_SQL;
    return (\@sqls, $key_val);
}

=head2 __makeUpdateSQLs

	my $sqls = $instance->__makeUpdateSQLs();

Creates a series of UPDATE SQL statements suitable for saving the
modified state of the specified DBObject instance to the database.  It
will only modify the logical columns which have changed since the
instance was last loaded from or saved to the database.  The $sqls
result has the same format as the $sqls result of the __makeInsertSQLs
method.

=cut

sub __makeUpdateSQLs {
    my $self = shift;

    my @changed_tables = keys %{$self->{__changedFields}};
    my %tables_used;
    my %columns_needed;
    my %new_values;

    my $columns = $self->__columns();
    my $keys = $self->__primaryKeys();

    foreach my $table (@changed_tables) {
        my @changed_columns = keys %{$self->{__changedFields}->{$table}};

        foreach my $column (@changed_columns) {
            $tables_used{$table} = undef;
            push @{$columns_needed{$table}}, "$column = ?";
            push @{$new_values{$table}}, $self->{__fields}->{$table}->{$column};
        }
    }

    my @sqls;
    foreach my $table (keys %tables_used) {
        my $columns = $columns_needed{$table};
        my $values = $new_values{$table};
        my $key = $keys->{$table};
        die "Cannot update $table if we don't know the primary key!"
          unless defined $key;

        push @$values, $self->{__id};

        my $sql = "update $table set ". join(", ",@$columns).
          " where $table.$key = ?";
        push @sqls, [$sql,$values];
    }

    return \@sqls;
}

=head2 __makeDeleteSQLs

	my $sqls = $instance->__makeDeleteSQLs();

Creates a series of DELETE SQL statements suitable for deleting the
specified DBObject instance from the database.  The $sqls result has
the same format as the $sqls result of the __makeInsertSQLs method.

=cut

sub __makeDeleteSQLs {
    my $self = shift;

    my $tables = $self->__tables();
    my $keys = $self->__primaryKeys();
    my $deletes = $self->__deleteKeys();

    my @sqls;
    foreach my $table (keys %$tables) {
        my $key = $keys->{$table};
        my $delete = $deletes->{$table};

        if (defined $key) {
            my $sql = "delete from $table where $table.$key = ?";
            my $values = [$self->{__id}];
            push @sqls, [$sql,$values];
        } elsif (defined $delete) {
            my @deletes = keys %$delete;
            my $sql = "delete from $table where ";
            my @wheres = map { "${table}.$_ = ?" } @deletes;
            $sql .= join (" and ",@wheres);
            my @values = map { $self->$_() } @deletes;
            push @sqls, [$sql,\@values];
        } else {
            die "Cannot delete $table if we don't know the primary key!"
              unless defined $key;
        }
    }

    return \@sqls;
}

=head2 __createNewInstance

	my $instance = $class->__createNewInstance($dbh,$data_hash);

Used by the OME::Factory->newObject and ->newAttribute methods to
create a DBObject instance corresponding to a new entry in the
database.  The $dbh parameter should be an active connection to the
database.  The $data_hash parameter should contain the values for the
new DBObject instance.

Note that this method is not truly atomic in the case of subclasses
which span tables since we cannot rely on hierarchical transactions in
the underlying database.  (In other words, we cannot necessarily start
a "subtransaction" without clobbering a transaction which is occuring
outside of this method.)  Therefore, if one of the INSERT statements
fails, this method cannot roll back the INSERT statements which had
succeeded to that point.

=cut

sub __createNewInstance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($dbh,$data_hash) = @_;
    my ($sqls,$key_val) = $class->__makeInsertSQLs($dbh,$data_hash);

    # FIXME: How do we want to handle atomicity?  Currently, if any of
    # the INSERT statements fail, an undef object is returned, but
    # none of the statements which succeeded are rolled back.  (This
    # would require a hierarchical transaction system; we cannot start
    # our own sub-transaction to handle this case, since it might
    # clobber a transaction which was started outside of this method.)
    foreach my $sql_entry (@$sqls) {
        my ($sql,$values) = @$sql_entry;
        #print "$sql\n  (",join(',',@$values),")\n";;
        my $sth = $dbh->prepare($sql);
        $sth->execute(@$values) or return undef;
    }

    # Make a copy of the fields
    my %fields;

    my $columns = $class->__columns();

    foreach my $alias (keys %$columns) {
        my $entry = $columns->{$alias};
        my $table = $entry->[0];
        my $column = $entry->[1];
        $fields{$table}->{$column} = undef;
    }

    foreach my $alias (keys %$data_hash) {
        my $entry = $columns->{$alias};
        my $table = $entry->[0];
        my $column = $entry->[1];
        $fields{$table}->{$column} = $data_hash->{$alias};
        #print "$table $column = $alias\n";
    }

    my $self = {
                __fields  => \%fields,
                __id      => $key_val,
                __changedFields => {},
               };

    return bless $self,$class;
}

=head2 __writeToDatabase

	$instance->__writeToDatabase($dbh);

Saves the modified state of this instance to the database.  It will
only save the logical columns which have changed since the instance
was last loaded from or saved to the database.

Note that this method is not truly atomic in the case of subclasses
which span tables since we cannot rely on hierarchical transactions in
the underlying database.  (In other words, we cannot necessarily start
a "subtransaction" without clobbering a transaction which is occuring
outside of this method.)  Therefore, if one of the UPDATE statements
fails, this method cannot roll back the UPDATE statements which had
succeeded to that point.

=cut

sub __writeToDatabase {
    my ($self,$dbh) = @_;

    my $sqls = $self->__makeUpdateSQLs();

    # FIXME: Just like in __createNewInstance, we don't handle
    # atomicity very well.
    my $i = 1;
    foreach my $sql_entry (@$sqls) {
        my ($sql,$values) = @$sql_entry;
        my $sth = $dbh->prepare($sql);
        $sth->execute(@$values) or die "Cannot write object to database!";
    }

    $self->{__changedFields} = {};

    return;
}

=head2 __writeToDatabase

	$instance->__writeToDatabase($dbh);

Deletes this instance from the database.  No referential integrity
constraints are checked; if the database doesn't want you to delete
this object, you'll get an error.

Note that this method is not truly atomic in the case of subclasses
which span tables since we cannot rely on hierarchical transactions in
the underlying database.  (In other words, we cannot necessarily start
a "subtransaction" without clobbering a transaction which is occuring
outside of this method.)  Therefore, if one of the DELETE statements
fails, this method cannot roll back the DELETE statements which had
succeeded to that point.

=cut

sub __deleteFromDatabase {
    my ($self,$dbh) = @_;

    my $sqls = $self->__makeDeleteSQLs();

    # FIXME: Just like in __createNewInstance, we don't handle
    # atomicity very well.
    my $i = 1;
    foreach my $sql_entry (@$sqls) {
        my ($sql,$values) = @$sql_entry;
        my $sth = $dbh->prepare($sql);
        $sth->execute(@$values) or die "Cannot delete object from database!";
    }

    # Once deleted from the database the entire contents of the object
    # in memory have been "modified".

    $self->{__changedFields} = {};
    foreach my $alias (keys %{$self->__columns()}) {
        $self->{__changedFields}->{$alias} = undef;
    }

    return;
}

=head2 __fillInstance

	$instance->__fillInstance($id_available,$columns_wanted,$sth_vals);

Fills in a new DBObject instance with the values fetched from a DBI
statement handle.  The $id_available parameter should indicate whether
a primary key ID was retrieved by the statement.  The $columns_wanted
should be an array of logical column aliases, in the order that they
appear in the statement.  The $sth_vals parameter should be the array
reference returned by the fetch() method of the statement handle.

=cut

sub __fillInstance {
    my ($self,$i,$columns_wanted,$sth_vals) = @_;

    # Place the values returned from the database into the __fields
    # instance variable.  This will set the entries for a NULL field
    # to be undef.  This means that when the accessor tries to
    # retrieve a value, exists will return true, while defined will
    # return false.
    my $columns = $self->__columns();
    foreach my $alias (@$columns_wanted) {
        my $entry = $columns->{$alias};
        my $table = $entry->[0];
        my $column = $entry->[1];
        $self->{__fields}->{$table}->{$column} = $sth_vals->[$i++];
    }

    $self->{__changedFields} = {};
}

=head2 __newInstance

	my $instance = $class->__newInstance($sth,$id_available,
	                                     [$columns_wanted]);

Creates a new DBObject instance corresponding to a row retrieved by a
DBI statement handle.  This statement will most likely have been
generated by the __makeSelectSQL method.  The $sth parameter should be
an open statement handle.  The $id_available parameter should indicate
whether the first column is a primary key.  If specified, the
$columns_wanted parameter should be an arrayref of logical column
aliases, and should be in the same order as the columns returned by
the statement.  If not specified, all of the columns defined by the
class will be used.

This method will retrieve one row of information from the statement
handle and create a DBObject instance to hold that data.  If the
statement does not have any more rows left to return, this method will
return undef.

=cut

sub __newInstance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($sth,$id_available,$columns_wanted) = @_;
    my $sth_vals;

    # We need to advance the statement cursor even if the object is
    # already in the object cache.
    return undef unless $sth_vals = $sth->fetch();

    my $i = 0;

    my $id;
    if ($id_available) {
        $id = $sth_vals->[$i++];
        # Try to load this object from the cache, if we can.
        my $cached_object = $class->__getCachedObject($id);
        return $cached_object if defined $cached_object;
    }

    my $columns_specified = 1;
    if ((!defined $columns_wanted) || (scalar(@$columns_wanted) <= 0)) {
        $columns_wanted = [keys %{$class->__columns()}];
        $columns_specified = 0;
    }

    # Create a hash to store the fields that we're loading in.
    my %fields;

    my $self = {
                __fields  => \%fields,
                __id      => $id,
                __changedFields => {},
               };

    bless $self, $class;

    $self->__fillInstance($i,$columns_wanted,$sth_vals);

    # Don't store this object in the cache if there were specific
    # columns requested.
    $self->__storeCachedObject()
      unless $columns_specified;

    return $self;
}

=head2 __newByID

	my $instance = $class->__newByID($dbh,$id,$columns_wanted);

Returns a new DBObject instance to represent an entry in the database
with the given primary key ID.  Obviously, this DBObject subclass must
define a primary key for this method to be useful.  (If it doesn't, an
error will be thrown.)  The $dbh parameter should be an active
database handle.  The $id parameter should be the primary key ID to
load.  If specified, the $columns_wanted parameter should be an
arrayref of logical column aliases, and should be in the same order as
the columns returned by the statement.  If not specified, all of the
columns defined by the class will be used.

=cut

sub __newByID {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($dbh,$id,$columns_wanted) = @_;

    # Try to load the object from the cache first.
    my $cached_object = $class->__getCachedObject($id);
    return $cached_object if defined $cached_object;

    my ($sql,$id_available,$values) = $class->
      __makeSelectSQL($columns_wanted,{id => $id});

    die "ID not available"
      unless $id_available;

    #print "\n$sql\n";
    #print join(',',@$columns_wanted),"\n";

    my $sth = $dbh->prepare($sql);
    eval {
        $sth->execute(@$values);
    };
    confess $@ if $@;

    return $class->__newInstance($sth,$id_available,$columns_wanted);
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


