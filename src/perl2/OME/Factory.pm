# OME::Factory

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


package OME::Factory;
our $VERSION = 2.000_000;

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
rest of OME interacts with the database.  Most of the OME::Factory
methods delegate to Class::DBI, which OME uses to implement object
persistence.  However, I<no code other than OME::Factory should make
calls to Class::DBI methods>!  If you know which Class::DBI method you
want to call, please see the L<Class::DBI EQUIVALENTS|/"Class::DBI
EQUIVALENTS"> section for the OME::Factory method to use instead.

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
All of the core OME database tables (EXPERIMENTERS, PROJECTS,
DATASETS, IMAGES, etc.) are "objects", and have predefined
OME::DBObject subclasses (OME::Project, OME::Dataset, OME::Image, etc.).
Methods such as newObject and loadObject operate on these core tables, 
and identify the specific OME::DBObject subclass by name.

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

=head1 METHODS

=head2 DBH

	my $dbh = $factory->DBH();

This method returns the DBI database handle associated with this
OME::Factory.  You can use it to run arbitrary SQL commands.  Note
that this is not the preferred method for executing arbitrary SQL.
The OME code uses the Ima::DBI module, which provides a much more
centralized and consistent way to incorporate SQL into Perl.

=over

B<TODO>: Add a real description of the Ima::DBI idiom for arbitrary
SQL.  For now, just look at how it's done in
OME::Tasks::AnalysisEngine.

=back

=head2 newObject

	my $object = $factory->newObject($className,$dataHash);

Creates a new object with initial values specified by $dataHash.  The
keys of $dataHash should be columns in the corresponding database
table.  (By convention, foreign key fields should be referred to
without any "_id" suffix.)  The values of $dataHash should be the
initial values for the respective columns.  The $dataHash should not
contain a value for the primary key if the underlying table has a
corresponding sequence; Class::DBI will fill in the primary key.  Note
that this method creates a row in the database corresponding to the
new object, so any columns defined to be NOT NULL I<must> be specified
in $dataHash, or DBI will throw an error.

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
table with $id for its primary key.  Returns B<undef> if there is now
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

Finds the attribute of a given type referring to a given target.  As
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
the methods, these criteria should be passed in directly in the
parameter list, not as a hash reference.  For instance:

	my @programs = $factory->
	    findObjects("OME::Modules",
	                module_type => "OME::ModuleExecution::CLIHandler",
	                category    => "Statistics");

Also note that these methods are not intended to support arbitrarily
complex SQL; that's what SQL is for.  As such, all of the criteria
will be ANDed together in the WHERE clause.

=head1 Class::DBI EQUIVALENTS

This section describes the OME::Factory analogues to the most common
Class::DBI methods.

=head2 create

	# Through Class::DBI
	my $module = OME::Module->create($data_hash);

	# Through OME::Factory
	my $module = $factory->newObject("OME::Module",$data_hash);

=head2 find_or_create

	# Through Class::DBI
	my $module = OME::Module->find_or_create($data_hash);

	# Through OME::Factory
	my $module = $factory->
	    maybeNewObject("OME::Module",$data_hash);

=head2 retrieve

	# Through Class::DBI
	my $module = OME::Module->retrieve($id);

	# Through OME::Factory
	my $module = $factory->loadObject("OME::Module",$id);

=head2 search

	# Through Class::DBI
	my @programs = OME::Module->
	    search(name        => $name,
	           module_type => $module_type);
	my $programIterator = OME::Module->
	    search(name        => $name,
	           module_type => $module_type);

	# Through OME::Factory
	my $oneProgram = $factory->
	    findObject("OME::Module",
	               name        => $name,
	               module_type => $module_type);
	my @manyPrograms = $factory->
	    findObjects("OME::Module",
	                name        => $name,
	                module_type => $module_type);
	my $programIterator = $factory->
	    findObjects("OME::Module",
	                name        => $name,
	                module_type => $module_type);

=head2 search_like

	# Through Class::DBI
	my @programs = OME::Module->
	    search_like(name        => $name,
	                module_type => $module_type);
	my $programIterator = OME::Module->
	    search_like(name        => $name,
	                module_type => $module_type);

	# Through OME::Factory
	my $oneProgram = $factory->
	    findObjectLike("OME::Module",
	                   name        => $name,
	                   module_type => $module_type);
	my @manyPrograms = $factory->
	    findObjectsLike("OME::Module",
	                    name        => $name,
	                    module_type => $module_type);
	my $programIterator = $factory->
	    findObjectsLike("OME::Module",
	                    name        => $name,
	                    module_type => $module_type);

=cut


use strict;
use Ima::DBI;
use Class::Accessor;
use OME::SessionManager;
use OME::DBConnection;
use Log::Agent;

use base qw(Ima::DBI Class::Accessor Class::Data::Inheritable);

use fields qw(Debug _cache _session);
__PACKAGE__->mk_accessors(qw(Debug));
__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
                  { RaiseError => 1 });



# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session) = @_;

    my $self = $class->SUPER::new();
    $self->{_cache} = {};
    $self->{_session} = $session;
    $self->{Debug} = 1;

    return $self;
}


# Accessors
# ---------

sub DBH { my $self = shift; return $self->db_Main(); }
sub Session { my $self = shift; return $self->{_session}; }

sub __checkClass {
    my $class = shift;
    logcroak "Malformed class name $class"
      unless $class =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;
}

# loadObject
# ----------

sub loadObject {
    my ($self, $class, $id) = @_;

    return undef unless defined $id;

    #my $classCache = $self->{_cache}->{$class};
    #if (exists $classCache->{$id}) {
    #    logdbg "debug", "loading cache $class $id" if $self->{debug};
    #    return $classCache->{$id};
    #} else {
    #    logdbg "debug", "loading  new  $class $id" if $self->{debug};
    #}

    __checkClass($class);
    eval "require $class";
    my $object = $class->retrieve($id) or return undef;
    $object->Session($self->Session());

    #$self->{_cache}->{$class}->{$id} = $object;
    return $object;
}

sub loadAttribute {
    my ($self, $semantic_type, $id) = @_;

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
        unless defined $type;

    return $type->loadAttribute($id);
}


# objectExists
# ------------

sub objectExists {
    my ($self, $class, @criteria) = @_;
    return defined $self->findObject($class,@criteria);
}


# findObject
# ----------

sub findObject {
    my ($self, $class, @criteria) = @_;
    my $objects = $self->findObjects($class,@criteria);
    return $objects? $objects->next(): undef;
}


# findObjects
# -----------

sub findObjects {
    my ($self, $class, @criteria) = @_;

    # If the caller is not looking for a value, don't do anything.
    return undef unless defined wantarray;

    # Return undef if the criteria are not well-formed.
    return undef unless (scalar(@criteria) >= 0) && ((scalar(@criteria) % 2) == 0);

    my $session = $self->Session();

    __checkClass($class);
    eval "require $class";
    if (wantarray) {
        # looking for a list
        my @result = (scalar(@criteria) == 0)?
          $class->retrieve_all():
          $class->search(@criteria);
        $_->Session($session) foreach @result;
        return @result;
    } else {
        # looking for a scalar
        my $iterator = (scalar(@criteria) == 0)?
          $class->retrieve_all():
          $class->search(@criteria);
        return OME::Factory::Iterator->new($iterator,$session);
    }
}


# objectExists
# ------------

sub objectExistsLike {
    my ($self, $class, @criteria) = @_;
    return defined $self->findObjectLike($class,@criteria);
}


# findObject
# ----------

sub findObjectLike {
    my ($self, $class, @criteria) = @_;
    my $objects = $self->findObjectsLike($class,@criteria);
    return $objects? $objects->next(): undef;
}


# findObjects
# -----------

sub findObjectsLike {
    my ($self, $class, @criteria) = @_;

    # If the caller is not looking for a value, don't do anything.
    return undef unless defined wantarray;

    # Return undef if the criteria are not well-formed.
    return undef unless (scalar(@criteria) > 0) && ((scalar(@criteria) % 2) == 0);

    my $session = $self->Session();

    __checkClass($class);
    eval "require $class";
    if (wantarray) {
        # looking for a list
        my @result = $class->search_like(@criteria);
        $_->Session($session) foreach @result;
        return @result;
    } else {
        # looking for a scalar
        my $iterator = $class->search_like(@criteria);
        return OME::Factory::Iterator->new($iterator,$session);
    }
}


# newObject
# ---------

sub newObject {
    my ($self, $class, $data) = @_;

    __checkClass($class);
    eval "require $class";
    my $object = $class->create($data);
    $object->Session($self->Session());
    return $object;
}

sub maybeNewObject {
    my ($self, $class, $data) = @_;

    __checkClass($class);
    eval "require $class";
    my $object = $class->find_or_create($data);
    $object->Session($self->Session());
    return $object;
}

sub newAttribute {
    my ($self, $semantic_type, $target, $module_execution, $data_hash) = @_;

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
        unless defined $type;

    #print STDERR "$semantic_type -> Session = ",$type->Session(),"\n";

    my $granularity = $type->granularity();
    if ($granularity eq 'D') {
        $data_hash->{dataset_id} = $target;
    } elsif ($granularity eq 'I') {
        $data_hash->{image_id} = $target;
    } elsif ($granularity eq 'F') {
        $data_hash->{feature_id} = $target;
    }

    my $result = OME::SemanticType->newAttributes($self->Session(),
                                                   $module_execution,
                                                   $type => $data_hash);


    # We're only creating one attribute, so it doesn't need to be
    # wrapped in an array.
    return undef if (!defined $result);
    return $result->[0];
}

sub newAttributes {
    my ($self, $target, $module_execution, @attribute_info) = @_;

    my @real_info;

    my $i;
    my $length = scalar(@attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        my $semantic_type = $attribute_info[$i];
        my $data_hash = $attribute_info[$i+1];

        my $type =
          ref($semantic_type) eq "OME::SemanticType"?
            $semantic_type:
            $self->findObject("OME::SemanticType",
                              name => $semantic_type);
        die "Cannot find attribute type $semantic_type"
          unless defined $type;

        #print STDERR "$semantic_type -> Session = ",$type->Session(),"\n";

        my $granularity = $type->granularity();
        if ($granularity eq 'D') {
            $data_hash->{dataset_id} = $target;
        } elsif ($granularity eq 'I') {
            $data_hash->{image_id} = $target;
        } elsif ($granularity eq 'F') {
            $data_hash->{feature_id} = $target;
        }

        push @real_info, $type, $data_hash;
    }

    my $result = OME::SemanticType->newAttributes($self->Session(),
                                                  $module_execution,
                                                  @real_info);


    return $result;
}

sub findAttributes {
    my ($self, $semantic_type, $target) = @_;

    my $type =
      ref($semantic_type) eq "OME::SemanticType"?
        $semantic_type:
        $self->findObject("OME::SemanticType",
                          name => $semantic_type);
    die "Cannot find attribute type $semantic_type"
        unless defined $type;

    return $type->findAttributes($target);
}

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::DBObject|OME::DBObject>,
L<OME::SemanticType|OME::SemanticType>

=cut


package OME::Factory::Iterator;

our $VERSION = 2.000_000;

use Class::DBI::Iterator;

use fields qw(_iterator _session);

# The OME::Factory::Iterator class is a replacement for Class::DBI's
# iterator.  It's constructor takes in a Class::DBI::Iterator and an
# OME::Session.  The first and next methods delegate to the
# Class::DBI::Iterator, must make sure that any object returned has
# its Session set properly.

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($iterator,$session) = @_;
    my $self = {
                _iterator => $iterator,
                _session  => $session,
               };

    return bless $self, $class;
}

sub __fix {
    my ($self,$object) = @_;
    $object->Session($self->{_session})
      if defined $object;
    return $object;
}

sub first {
    my ($self) = @_;
    return $self->__fix($self->{_iterator}->first());
}

sub next {
    my ($self) = @_;
    return $self->__fix($self->{_iterator}->next());
}

1;
