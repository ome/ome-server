# OME::Factory

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


package OME::Factory;
use OME;
our $VERSION = $OME::VERSION;

=head1 NAME

OME::Factory - database access class

=head1 SYNOPSIS

	use OME::Factory;
	my $factory = $session->Factory();

	my $project = $factory->loadObject("OME::Project",1);
	my $dataset = $factory->newObject("OME::Dataset",
	                                  {
	                                   name  => "New dataset",
	                                   owner => $user
	                                  });
	my @images = $factory->findObjects("OME::Image",
	                                   name => "Image 4");

=head1 DESCRIPTION

The OME::Factory class provides a single interface through which the
rest of OME interacts with the database.  The objects returned by this factory
are (in most cases) instances of some descendant of L<OME::DBObject|OME::DBObject>.

All of the methods which can take in DBObjects as parameters will work
properly whether passed in an actual DBObject or an integer database
ID.  This includes search criteria in the findObject and findObjects
methods, and the data hash used to create new objects in newObject and
newAttribute.

OME implements some extensions to Class::DBI.  Please see the
L<OME::DBObject|OME::DBObject> module for more details.

=head1 OBJECTS VS. ATTRIBUTES

Several of the OME::Factory methods make a distinction between
"objects" and "attributes".  In this convention, an "object" is
defined by an OME::DBObject subclass included in the OME source tree.
All of the core OME database tables (PROJECTS, DATASETS, IMAGES, etc.)
are "objects", and have predefined OME::DBObject subclasses
(OME::Project, OME::Dataset, OME::Image, etc.).  Methods such as
newObject and loadObject operate on these core tables, and identify
the specific OME::DBObject subclass by name.

Attribute tables, however, cannot have predefined OME::DBObject
subclasses, since the semantic types available in OME can vary from
time to time.  However, OME stores enough information about each
semantic type to construct OME::DBObject subclasses at runtime.  (The
real situation is slightly more complex than this because of the
distinction between data tables and semantic types.  See the
L<OME::DataTable|OME::DataTable> and
L<OME::SemanticType|OME::SemanticType> modules for more details.)
Methods such as newAttribute and loadAttribute operate on these
user-defined semantic types, and identify the specific OME::DBObject
subclass by the semantic type.

=head1 OBTAINING A FACTORY

To retrieve an OME::Factory to use for accessing the database, the
user must log in to OME.  This is done via the
L<OME::SessionManager|OME::SessionManager> class.  Logging in via
OME::SessionManager yields an L<OME::Session|OME::Session> object.
Each OME::Session object has an associated OME::Factory, which can be
retrieved with the Factory method.  The full process is summarized
below:

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $factory = $session->Factory();


=head1 Database Handles and Transactions

Factory maintains its own database handle (DBH) to ensure that all DBObjects it generates
are from the same transaction.  Factory also allows the caller to get their own separate
DBH to issue SQL queries on (newDBH method).  These DBHs are cached by Factory and must be
returned to it when the caller is finished with the DBH (releaseDBH method).  A transaction
is initiated in this DBH, and the caller is responsible for committing the transaction themselves.
The transaction for this DBH is separate from the transaction the Factory itself is in.
In other words, DB writes made via the Factory or the DBObjects it produces will not be visible in this
transaction until the commitTransaction method is called on Factory or its associated Session.
The transaction will be terminated (rolled back) when releaseDBH is called.  The Factory's own
transaction can be committed or rolled back by calling commitTransaction or rollbackTransaction.
This is normally done by calling these methods on L<OME::Session|OME::Session>.


=head1 METHODS

=head2 obtainDBH

	my $dbh = $factory->obtainDBH();

This method returns the DBI database handle associated with this
OME::Factory.  You can use it to run arbitrary SQL commands within the Factory's own transaction.
To get a new DBH (and a separate transaction), call newDBH().

=head2 newDBH

	my $dbh = $factory->newDBH();

This method returns a new DBI database handle I<not> associated with this
OME::Factory.  You can use it to run arbitrary SQL commands outside of Factory's transaction.
The Factory maintains a cache of DBHs that it made.  This call must be balanced with a releaseDBH call.

=head2 releaseDBH

	$factory->releaseDBH($dbh);

This method releases the DBH and puts it baqck in Factory's DBH cache.  Before putting it
back in the cache, a $dbh->rollback() call will be made to ensure that there are no DBHs
with hanging transaction in the cache.  If the handle was used to modify the DB, it is
the caller's responsibility to call $dbh->commit().


=head2 newObject

	my $object = $factory->newObject($className,$dataHash);

Creates a new object with initial values specified by $dataHash.  The
keys of $dataHash should be columns in the corresponding database
table.  (By convention, foreign key fields should be referred to
without any "_id" suffix if they are being specified by reference;
with the suffix if they are being specified by ID number.)  The values
of $dataHash should be the initial values for the respective columns.
The $dataHash should not contain a value for the primary key if the
underlying table has a corresponding sequence; Class::DBI will fill in
the primary key.  Note that this method creates a row in the database
corresponding to the new object, so any columns defined to be NOT NULL
I<must> be specified in $dataHash, or DBI will throw an error.

=head2 maybeNewObject

	my $object = $factory->maybeNewObject($className,$dataHash);

This works exactly like newObject, except that if an object in the
database already exists with the given contents, it will be returned,
and no new object will be created.  This is extremely useful for
adding items to a many-to-many map.  For instance,

	# Add $image to $dataset
	my $map = $factory->
	    maybeNewObject("OME::Image::DatasetMap",
	                   {
	                    dataset => $dataset,
	                    image   => $image
	                   });

=head2 newAttribute

	my $attribute = $factory->
	    newAttribute($semanticType,$target,$module_execution,$dataHash);

Creates a new attribute object.  Note that this is not technically a
DBObject subclass, since attributes can (conceivably) live in multiple
data tables.  Each attribute is associated with one DBObject per data
table is resides in.  (For more information on this, see
L<OME::SemanticType|OME::SemanticType>.

The target of the attribute (dataset, image, or feature) should not be
specified in $dataHash.  Rather, is should be passed in the $target
parameter.  The appropriate key will be added to the $dataHash
depending on the granularity of the semantic type.  Similarly, the
module execution that this attribute should be associated with should
be passed in the $module_execution parameter, not the $dataHash.

Since semantic type packages are created dynamically, semantic types
are not referred to by class name, like objects are.  The
$semanticType parameter should be either an instance of
OME::SemanticType (which I<is> an OME::DBObject, and can be obtained
via any of the *Object methods), or the name of an semantic type.
Note that:

	my $attribute = $factory->
	    newAttribute("Stack mean",$image,$hash);

is exactly equivalent to:

	my $type = $factory->
	    findObject("OME::SemanticType",
	               name => "Stack mean");
	my $attribute = $factory->
	    newAttribute($type,$image,$hash);

=head2 newAttributes

	my $attributes = $factory->
	    newAttributes($target,$module_execution,
	                  $semanticType1,$dataHash1,
	                  $semanticType2,$dataHash2,
	                  $semanticType3,$dataHash3,
	                  ...);

Creates several new attribute objects.  This method differs from
C<newAttribute> in that it creates several attributes which are
expected to live in a single set of data rows (one data row per data
table).  This method returns an array reference of the attribute
objects that were created.

The target of the attribute (dataset, image, or feature) should not be
specified in the $dataHashes.  Rather, is should be passed in the
$target parameter.  The appropriate key will be added to the
$dataHashes depending on the granularity of the semantic type.
Similarly, the module execution that this attribute should be
associated with should be passed in the $module_execution parameter,
not the $dataHashes.

All of the semantic types given as input must have the same
granularity.  Further, since the attributes will be stored in a single
set of data rows, any semantic elements which map to the same data
column must have the same value in all of the data hashes.  If any of
these conditions aren't met, an error is thrown and no new attributes
are created.

As in the case of C<newAttribute>, each semantic type can be specified
by name or as an instance of L<OME::SemanticType>.  If any types are
specified by name, and a semantic type of that name does not exist, an
error will be thrown and no new attributes will be created.

=head2 loadObject

	my $object = $factory->loadObject($className,$id);

Returns a DBObject instance corresponding to the row in $className's
table with $id for its primary key.  Returns B<undef> if there is no
row with that primary key.

=head2 loadAttribute

	my $attribute = $factory->loadAttribute($semanticType,$id);

Loads in the attribute with the specified primary key.  As in the case
of newAttribute, $semanticType can be either an semantic type name
or an instance of OME::SemanticType.  Since all of the data rows that
make up an attribute are required to have the same primary key value,
this method works by calling loadObject on all of the data table
classes that make up the given semantic type, and then creating a new
semantic type instance with those data rows.

=head2 objectExists

	my $boolean = $factory->objectExists($className,%criteria);

Returns true if there is at least one row in $className's database
table which matches the given search criteria.

=head2 findObject

	my $object = $factory->findObject($className,%criteria);

Returns the object in $className's table which matches the search
criteria.  Returns B<undef> if no object matches.  If more than one
object matches, one of them will be returned; it is undefined which
one it will be.

=head2 findObjects

	my $iterator = $factory->findObjects($className,%criteria);
	while (my $object = $iterator->next()) {
	    # Do something with the objects one at a time
	}

	my @objects = $factory->findObjects($className,%criteria);
	# Do something with the objects all at once

In list context, returns all of the objects in $className's table
matching the search criteria.  In scalar context, returns an iterator
whose next() method will return those objects one at a time.  This
iterator is provided by the Class::DBI module.

=head2 objectExistsLike

	my $object = $factory->objectExistsLike($className,%criteria);

Works exactly like the objectExists method, but uses the SQL LIKE
operator for comparison, rather than the = operator.

=head2 findObjectLike

	my $object = $factory->findObjectLike($className,%criteria);

Works exactly like the findObject method, but uses the SQL LIKE
operator for comparison, rather than the = operator.

=head2 findObjectsLike

	my $iterator = $factory->findObjectsLike($className,%criteria);
	while (my $object = $iterator->next()) {
	    # Do something with the objects one at a time
	}

	my @objects = $factory->findObjectsLike($className,%criteria);
	# Do something with the objects all at once

Works exactly like the findObjects method, but uses the SQL LIKE
operator for comparison, rather than the = operator.

=head2 findAttributes

	my $iterator = $factory->findAttributes($semanticType,$target);
	while (my $attribute = $iterator->next()) {
	    # Do something with the attributes one at a time
	}

	my @attributes = $factory->findAttributes($semanticType,$target);
	# Do something with the attributes all at once

Finds the attributes of a given type referring to a given target.  As
in the case of newAttribute, $semanticType can be either an semantic
type name or an instance of OME::SemanticType.  The target must be an
OME::Dataset, OME::Image, or OME::Feature object, depending on the
granularity of the type.  Note that arbitrary search criteria is not
currently supported in this method.  If you need this functionality,
email Doug (dcreager@mit.edu).

=head1 SEARCH CRITERIA

The objectExists, findObject, findObjects, findObjectLike, and
findObjectsLike methods all take in search criteria as their last
parameters.  These criteria are used to build the WHERE clause of the
SQL statement used to retrieve the objects in question.  You can think
of these criteria as similar to the data hash used to create objects:
The keys should be column names (without the "_id" suffix for foreign
keys), the values should be the search criteria values.  When calling
the methods, these criteria can be passed in directly in the parameter
list, or as a hash reference.  For instance:

	my @programs = $factory->
	    findObjects("OME::Modules",
	                module_type => "OME::ModuleExecution::CLIHandler",
	                category    => "Statistics");

Also note that these methods are not intended to support arbitrarily
complex SQL; that's what SQL is for.  As such, all of the criteria
will be ANDed together in the WHERE clause.

A couple of special syntaxes are supported for the value in a search
clause:

	dataset.name => 'Foo'

inserts a JOIN clause into the query.  This allows you to follow
foreign-key links in the objects in your search criteria.  Currently,
it is only possible to follow has-one foreign keys.

	__order => ['id','name']

tells the Factory to order the results of the query.  The contents of
the array ref should be the columns to order by.  Like search
criteria, these columns can involve foreign key joins.

	id => ['>',3]

tells the Factory to use a different SQL operator in this clause.
This clause, for instance, would return all objects with a primary key
ID greater than 3.

	id => ['in',[1,2,3]]

The C<in> operator is another special case -- SQL expects a list in
this case, so the value for the query clause should be an array
reference of values.  This clause would return objects with a primary
key of 1, 2, or 3.

Note that these shortcuts mean that the findObjectsLike method is
technically superfluous -- the exact same functionality can be
achieved with findObjects.  For instance,

	$factory->findObjectsLike("OME::Module",
	                          {
	                           module_type => 'OME::%',
	                           name        => '% (Matlab)'
	                          });

is exactly equivalent to

	$factory->findObjects("OME::Module",
	                      {
	                       module_type => ['like','OME::%'],
	                       name        => ['like','% (Matlab)']
	                      });

The *Like methods are provided as a convenience.

=cut

use strict;
use OME::DBConnection;
use OME::Database::Delegate;
use DBI;
use Carp qw(cluck croak);

use UNIVERSAL::require;

use fields qw(__handlesAvailable __allHandles);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $delegate = OME::Database::Delegate->getDefaultDelegate()
			or croak "Could not get default DB delegate";

    my $dbh = $delegate->
      connectToDatabase(OME::DBConnection->DataSource(),
                        OME::DBConnection->DBUser(),
                        OME::DBConnection->DBPassword());
    die "Cannot create database handle"
      unless defined $dbh;

    my $self = {__ourDBH           => $dbh,
                __handlesAvailable => {},
                __allHandles       => {},
               };

    return bless $self, $class;
}

sub DESTROY {
	my $self = shift;
    $self->closeFactory();
}

sub closeFactory {
    my $self = shift;
    $self->__disconnectAll();
}

sub Session { return OME::Session->instance() }

sub __checkClass {
    my $class = shift;
    croak "Malformed class name $class"
      unless $class =~ /^\w+(\:\:\w+)*$/;
}

sub obtainDBH {
    my ($self) = @_;
    return $self->{__ourDBH};
}

sub newDBH {
    my ($self) = @_;

    my @handles = values %{$self->{__handlesAvailable}};
    my $dbh;
    $dbh = shift @handles if scalar @handles;
    
    if ($dbh) {
    	delete $self->{__handlesAvailable}->{"$dbh"};
    } else {
		my $delegate = OME::Database::Delegate->getDefaultDelegate()
			or croak "Could not get default DB delegate";
		$dbh = $delegate->
		  connectToDatabase(OME::DBConnection->DataSource(),
							OME::DBConnection->DBUser(),
							OME::DBConnection->DBPassword());
		die "Cannot create database handle"
		  unless defined $dbh;
		$self->{__allHandles}->{"$dbh"} = $dbh;
    }

    return $dbh;
}

sub releaseDBH {
    my ($self,$dbh) = @_;

    croak "Cannot release a null DBH!" unless $dbh;
    if ($dbh == $self->{__ourDBH}) {
        cluck "Releasing the Factory's DBH is deprecated.  Nothing happens...";
        return;
    }
    
    croak "Attempt to release a DBH which is not in the Factory's DBH pool"
    	unless exists $self->{__allHandles}->{"$dbh"};
    
    croak "Attempt to release a DBH which is already released"
    	if exists $self->{__handlesAvailable}->{"$dbh"};
    	
    $dbh->rollback() or croak $dbh->errstr;
    $self->{__handlesAvailable}->{"$dbh"} = $dbh;

    #carp "--- Releasing handle: ".
    #  scalar(@{$self->{__handlesAvailable}})."/".
    #  scalar(@{$self->{__allHandles}});

    return;
}

sub __disconnectAll {
    my ($self) = @_;
    #carp "--- $$ Disconnecting handles\n";
    defined $_ && $_->disconnect() foreach values %{$self->{__allHandles}};
    $self->{__allHandles} = {};
    $self->{__handlesAvailable} = {};
    
	if (defined $self->{__ourDBH}) {
    	$self->{__ourDBH}->disconnect() or die $self->{__ourDBH}->errstr;
	}

    $self->{__ourDBH} = undef;

}

sub commitTransaction {
    my ($self) = @_;
    $self->{__ourDBH}->commit() or die $self->{__ourDBH}->errstr;;
}

sub rollbackTransaction {
    my ($self) = @_;
    $self->{__ourDBH}->rollback() or die $self->{__ourDBH}->errstr;;
}

sub loadObject {
    my ($self, $class, $id, $columns_wanted) = @_;

    return undef unless defined $class && defined $id;

    __checkClass($class);
    $class->require();

    my $object;
    eval {
        $object = $class->__newByID($self->{__ourDBH},
                                    $id,
                                    $columns_wanted);
    };

    die $@ if $@;

    return $object;

}

sub loadAttribute {
    my ($self, $semantic_type, $id, $columns_wanted) = @_;

    return undef unless defined $semantic_type && defined $id;

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
      unless defined $type;

    my $pkg = $type->requireAttributeTypePackage();

    my $attribute;
    eval {
        $attribute = $pkg->__newByID($self->{__ourDBH},
                                     $id,
                                     $columns_wanted);
    };

    die $@ if $@;

    return $attribute;
}

sub objectExists {
    my ($self, $class, @criteria) = @_;
    return defined $self->findObject($class,@criteria);
}

sub findObject {
    my ($self, $class, @criteria) = @_;
    my $objects = $self->findObjects($class,@criteria);
    return $objects? $objects->next(): undef;
}

sub findObjects {
    my ($self, $class, @criteria) = @_;

    # If the caller is not looking for a value, don't do anything.
    return undef unless defined wantarray;

    my $columns_wanted;

    # An array ref at the beginning of the criteria counts as
    # $columns_wanted.
    $columns_wanted = shift(@criteria)
      if (ref($criteria[0]) eq 'ARRAY');

    my $criteria;

    # Let's accept a hash ref for the criteria, too.
    if (ref($criteria[0]) eq 'HASH') {
        $criteria = $criteria[0];
    } else {
        # Return undef if the criteria are not well-formed.
        return undef
          unless (scalar(@criteria) >= 0) && ((scalar(@criteria) % 2) == 0);
        $criteria = {@criteria};
    }

    __checkClass($class);
    $class->require();

    my ($sql,$ids_available,$values) =
      $class->__makeSelectSQL($columns_wanted,$criteria);
    my $sth = $self->{__ourDBH}->prepare($sql);

    if (wantarray) {
        # __makeSelectSQL should have created the where clause in
        # keys-order, which will be the same order that values returns.
        my @result;
        eval {
            $sth->execute(@$values);

            push @result, $_
              while $_ = $class->__newInstance($sth,
                                               $ids_available,$columns_wanted);
        };
        die $@ if $@;
        return @result;
    } else {
        # looking for a scalar
        my $iterator = OME::Factory::Iterator->
          new($class,$sth,
              $values,$ids_available,$columns_wanted);
        return $iterator;
    }
}

sub countObjects {
    my ($self, $class, @criteria) = @_;

    my $criteria;

    # Let's accept a hash ref for the criteria, too.
    if (ref($criteria[0]) eq 'HASH') {
        $criteria = $criteria[0];
    } else {
        # Return undef if the criteria are not well-formed.
        return undef
          unless (scalar(@criteria) >= 0) && ((scalar(@criteria) % 2) == 0);
        $criteria = {@criteria};
    }

    __checkClass($class);
    $class->require();

    my ($sql,$ids_available,$values) =
      $class->__makeSelectSQL('COUNT',$criteria);
    my $sth = $self->{__ourDBH}->prepare($sql);

    # __makeSelectSQL should have created the where clause in
    # keys-order, which will be the same order that values returns.
    my $result = 0;
    eval {
        $sth->execute(@$values);
        $result = $sth->fetch()->[0];
    };
    die $@ if $@;

    return $result;
}

sub objectExistsLike {
    my ($self, $class, @criteria) = @_;
    return defined $self->findObjectLike($class,@criteria);
}

sub findObjectLike {
    my ($self, $class, @criteria) = @_;
    my $objects = $self->findObjectsLike($class,@criteria);
    return $objects? $objects->next(): undef;
}

sub findObjectsLike {
    my ($self, $class, @criteria) = @_;

    # If the caller is not looking for a value, don't do anything.
    return undef unless defined wantarray;

    my $columns_wanted;

    # An array ref at the beginning of the criteria counts as
    # $columns_wanted.
    $columns_wanted = shift(@criteria)
      if (ref($criteria[0]) eq 'ARRAY');

    my $criteria;

    # Let's accept a hash ref for the criteria, too.
    if (ref($criteria[0]) eq 'HASH') {
        $criteria = $criteria[0];
    } else {
        # Return undef if the criteria are not well-formed.
        return undef
          unless (scalar(@criteria) >= 0) && ((scalar(@criteria) % 2) == 0);
        $criteria = {@criteria};
    }

    foreach my $key (keys %$criteria) {
        # Only add an explicit LIKE operator if the caller didn't
        # specify one on their own.
        $criteria->{$key} = ['LIKE',$criteria->{$key}]
          if (ref($criteria->{$key}) ne 'ARRAY');
    }

    if (defined $columns_wanted) {
        return $self->findObjects($class,$columns_wanted,$criteria);
    } else {
        return $self->findObjects($class,$criteria);
    }
}

sub newObject {
    my ($self, $class, $data) = @_;

    __checkClass($class);
    $class->require();

    my $object;
    eval {
        $object = $class->__createNewInstance($self->{__ourDBH},$data);
    };
    die $@ if $@;
    return $@? undef: $object;
}

sub maybeNewObject {
    my ($self, $class, $data) = @_;

    my $object = $self->findObject($class,$data);
    return $object if defined $object;

    $object = $self->newObject($class,$data);
    return $object;
}

sub findAttributes {
    my ($self,$semantic_type,@criteria) = @_;

    return undef unless defined $semantic_type;

    if (scalar(@criteria) == 1 && (ref($criteria[0]) ne 'HASH')) {
        # Old prototype - only a target is passed in
        if (defined $criteria[0]) {
            @criteria = ( target => $criteria[0] );
        } else {
            @criteria = ();
        }
    }

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
      unless defined $type;

    my $pkg = $type->requireAttributeTypePackage();

    return $self->findObjects($pkg,@criteria);
}

sub countAttributes {
    my ($self,$semantic_type,@criteria) = @_;

    return undef unless defined $semantic_type;

    if (scalar(@criteria) == 1 && (ref($criteria[0]) ne 'HASH')) {
        # Old prototype - only a target is passed in
        if (defined $criteria[0]) {
            @criteria = ( target => $criteria[0] );
        } else {
            @criteria = ();
        }
    }

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
      unless defined $type;

    my $pkg = $type->requireAttributeTypePackage();

    return $self->countObjects($pkg,@criteria);
}

sub findAttribute {
    my ($self, $semantic_type, @criteria) = @_;
    my $objects = $self->findAttributes($semantic_type,@criteria);
    return $objects? $objects->next(): undef;
}

sub newAttribute {
    my ($self, $semantic_type, $target, $module_execution, $data) = @_;

    return undef unless defined $semantic_type && defined $data;

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
      unless defined $type;

    my $pkg = $type->requireAttributeTypePackage();

    $data->{target} = $target if defined $target;
    $data->{module_execution} = $module_execution;

    return $self->newObject($pkg,$data);
}

package OME::Factory::Iterator;
use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;

use fields qw(__sth __values
              __class __ids __columns __open __executed);

sub new {
    #carp "*** Iterator new";
    my $proto = shift;
    my $pclass = ref($proto) || $proto;

    my ($class,$sth,$values,$ids,$columns) = @_;
    my $self = {
                __class    => $class,
                __sth      => $sth,
                __values   => $values,
                __ids      => $ids,
                __columns  => $columns,
                __open     => 1,
                __executed => 0,
               };

    return bless $self, $pclass;
}

sub DESTROY {
    #carp "*** Iterator DESTROY";
    my $self = shift;
    $self->__close();
}

sub __execute {
    my $self = shift;
    $self->{__sth}->execute(@{$self->{__values}});
    $self->{__executed} = 1;
}

sub __close {
    my $self = shift;

    #carp "*** Iterator close";

    if ($self->{__open}) {
        $self->{__open} = 0;
    }
}

sub first {
    my $self = shift;

    die "Cannot retrieve objects from a closed iterator"
      unless $self->{__open};

    $self->__execute();
    return $self->next();
}

sub next {
    my $self = shift;

    die "Cannot retrieve objects from a closed iterator"
      unless $self->{__open};

    $self->__execute() unless $self->{__executed};

    return $self->{__class}->
      __newInstance($self->{__sth},
                    $self->{__ids},
                    $self->{__columns});
}

sub finish {
    my $self = shift;

    die "Cannot retrieve objects from a closed iterator"
      unless $self->{__open};

    if ($self->{__executed}) {
        $self->{__sth}->finish();
        $self->{__executed} = 0;
    }

    return;
}

sub close {
    my $self = shift;

    die "Cannot retrieve objects from a closed iterator"
      unless $self->{__open};

    $self->finish();
    $self->__close();

    return;
}

package OME::Factory::LinkIterator;
use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;

use fields qw(__iterator __method __params);

sub new {
    my $proto = shift;
    my $pclass = ref($proto) || $proto;

    my $iterator = shift;
    my $method = shift;
    my @params = @_;

    my $self = {
                __iterator => $iterator,
                __method   => $method,
                __params   => \@params,
               };

    return bless $self, $pclass;
}

sub first {
    my $self = shift;
    my $result = $self->{__iterator}->first();
    return undef unless defined $result;

    my $method = $self->{__method};
    my $params = $self->{__params};
    return $result->$method(@$params);
}

sub next {
    my $self = shift;
    my $result = $self->{__iterator}->next();
    return undef unless defined $result;

    my $method = $self->{__method};
    my $params = $self->{__params};
    return $result->$method(@$params);
}

sub finish {
    my $self = shift;
    $self->{__iterator}->finish();
}

sub close {
    my $self = shift;
    $self->{__iterator}->close();
}

1;
