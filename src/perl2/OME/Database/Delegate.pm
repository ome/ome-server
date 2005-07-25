# OME/Database/Delegate.pm

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
# Modifications by:
#  Ilya Goldberg <igg@nih.gov>
#    * Added support for listeners and notifiers for IPC
#    * Added functionality to specify DB connection parameters
#      in the installation environment (OME::Install::Environment)
#
#-------------------------------------------------------------------------------


package OME::Database::Delegate;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use DBI;
use UNIVERSAL::require;
use Carp;

use OME::Install::Environment;

=head1 NAME

OME::Database::Delegate - database-platform-specific routines

=head1 SYNOPSIS

	my $delegate = OME::Database::Delegate->getDefaultDelegate();
	my $dbh = $delegate->connectToDatabase();
	my $id = $delegate->getNextSequenceValue($dbh,$sequence);
	$delegate->addClassToDatabase($dbh,$className);

=head1 DESCRIPTION

Several of the database operations that OME::DBObject and OME::Factory
perform have different implementations depending on the database
server used.  The OME::Database::Delegate class provides a public
interface for each of these operations.  OME currently ships with a
single implementation of this interface -- OME::Database::PostgresDelegate.  In
theory, ports of OME to another database (can anyone say Oracle?)
would only require a new OME::Database::Delegate class to be written.
This has not been tested as of yet.

=head1 OBTAINING A DELEGATE

The default delegate is set in the installation environment
(OME::Install::Environment).  This class returns a hash with the DB_conf()
method.  The hash consists of the following keys:

 Delegate - The delegate class (e.g. OME::Database::PostgresDelegate)
 User     - The username to use to connect to the database
 Password - The password for the specified user
           The password will be stored as plain text in /etc/ome-install.store
           Using the password option is not recommended at this time.
           User and Password are passed on to DBI->connect, even if undef
 Host     - The hostname the database is runing on
           Calling the getDSN() method will properly specify the host
           in the connection string used by DBI.  The hostname specification
           will be left out if Host is undef.
 Port     - The port number to use for the connection
           The getDSN() method will add the port to DBI's connection string
           if its not undef, and leave it out of the string if undef.
 Name     - The dabase name.  This is also encoded in the DBI connection string
               Unlike Host, Port, User and Password, the DB Name cannot be undef.

=head2 getDefaultDelegate

	my $delegate = OME::Database::Delegate->getDefaultDelegate();

Determines the name of the appropriate implementation of
OME::Database::Delegate.  The default delegate is set by
OME::Install::Environment->initialize()->DB_conf()->{Delegate}
The getInstance() method of this class is called, and its result returned, which
will be the appropriate subclass of OME::Database::Delegate

=cut

sub getDefaultDelegate {
    # Get the database configuration
    my $dbConf = OME::Install::Environment->initialize()->DB_conf();
    croak "Could not get DB configuration enevironment\n".
        "Maybe the installation environment did not load?" unless $dbConf;
    $dbConf->{Delegate}->require();
    return $dbConf->{Delegate}->getInstance();
}

=head1 INTERFACE METHODS

The following methods are defined by the OME::Database::Delegate
interface.  Most of them are abstract and must be overridden in any
subclasses.

=head2 getInstance

	my $delegate = OME::Database::Delegate->getInstance();

Returns an instance of the database delegate.  In most cases, the
Database::Delegate subclass will be a singleton class.  The default
implementation of getInstance provides this behavior, so subclasses
will only need to override this if any instance state needs to be
initialized, or if the class cannot work as a singleton class.

This method should only be called directly if the default delegate is
somehow inadequate or incorrect.  Rather, the getDefaultDelegate
method should be used.

=cut

# Make this truly private
my $new = sub {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    return bless $self, $class;
};

my $singleton;

sub getInstance {
    # Create a new instance iff we don't have one yet.
    $singleton = &$new(@_) unless defined $singleton;
    return $singleton;
}

=head2 errorStr

	my $error = $delegate->errorStr ();

Reports the error generated by a DB operation.  This method is only used where
a DBI handle is not passed in from the caller.

=cut

sub errorStr {
	my $self = shift;
	$self->{__ERROR}  = shift @_ if (scalar @_);
	return $self->{__ERROR};
}

=head2 createDatabase

	my $already_exists = $delegate->createDatabase ($superuser,$password);

Creates the OME database.  This does not create any tables or other
database objects; it just ensures that the appropriate database
exists.  If the database could not be created successfully, it should die with 
an appropriate error message.  Successful creation (or if the DB already exists)
should return a true value.

The superuser and password parameters can be used to make a bootstrap connection
using a user and password other than the ones in OME::Install::Environment.

=cut

sub createDatabase {
    die "OME::Database::Delegate->createDatabase is abstract";
}

=head2 createUser

	$delegate->createUser ($username,$isSuperuser,$superuser,$password);

Creates a user in the OME database.  The $username parameter is required.
The $isSuperuser boolean is set true if $username should be created with superuser
privileges.

Just like createDatabase(), the optional $superuser,$password parameters are
used to override the User and Password settings in the
OME::Install::Environment->initialize()->DB_conf() hash.
The password parameter is the superuser's password - not the user we are creating.

This method returns false (0) on failure and true (1) on success.  The return
value should be checked, because that is the only indication of failure.
This method does not die in user creation fails.

=cut

sub createUser {
    die "OME::Database::Delegate->createUser is abstract";
}

=head2 connectToDatabase

	my $dbh = $delegate->connectToDatabase ($flags);

Connects to the database with the given connection information.  In
most cases, the default implementation of this method, which just
calls DBI->connect, is sufficient.  If a database server requires
extra setup of the database handle, this method can be overridden to
provide it.

The $flags is a hash reference that will be passed on to DBI->connect.
In addition to the stnadard options provided by DBI, the following
additional keys are supported (they will be deleted from the hash before this
method returns):

 DataSource - The connection string to pass to DBI
 DBUser     - A DB user to connect as
 DBPassword - The password for the DB user
 * The above three keys will be deleted from the $flags hash reference.
 * Default values for these settings come from the
  OME::Install::Environment->initialize()->DB_conf() hash.

Regardless of the DBI or driver defaults, the following settings will be placed
in $flags unless they are already present in the hash (over-rideable defaults).

 AutoCommit      => 0
 RaiseError      => 1
 InactiveDestroy => 1

=cut

sub connectToDatabase {
    my ($self,$flags) = @_;
    my $dbConf = OME::Install::Environment->initialize()->DB_conf();
    croak "Could not get DB configuration enevironment\n".
        "Maybe the installation environment did not load?" unless $dbConf;
    $flags->{AutoCommit}      = 0 unless exists $flags->{AutoCommit};
    $flags->{RaiseError}      = 1 unless exists $flags->{RaiseError};
    $flags->{InactiveDestroy} = 1 unless exists $flags->{InactiveDestroy};


    my ($datasource,$user,$password);
    $datasource = $flags->{DataSource} ?
        $flags->{DataSource} : $self->getDSN ($dbConf);
    $user = $flags->{DBUser} ?
        $flags->{DBUser} : $dbConf->{User};
    $password = $flags->{DBPassword} ?
        $flags->{DBPassword} : $dbConf->{Pass};

    delete $flags->{DataSource};
    delete $flags->{DBUser};
    delete $flags->{DBPassword};

    my $dbh = DBI->connect($datasource,$user,$password,$flags);
    return $dbh;
}

=head2 getDSN

    my $dbh = DBI->connect($self->getDSN ($dbConf));

Get a DBI connection string (Data Source Name or DSN) in a DB-specific way.
The DSN for a local postgres connection looks like this: 'dbi:Pg:dbname=ome'.
The DSN format is DB-specific, though the components of it aren't.
Therefore getting the actual DSN must be implemented in each delegate by
translating the DB configuration hash, which consists of the
following keys:

 Host     =>
 Port     =>
 Name     =>

These keys are also provided, though in most cases they are passed seperately
to DBI->connect();

 User     =>
 Password =>

The $dbConf parameter is optional.  If its missing, it should be retreived from
the installation environment by using:
  OME::Install::Environment->initialize()->DB_conf()

=cut

sub getDSN {
    die "OME::Database::Delegate->getDSN is abstract";
}

=head2 getRemoteDSN

    my $dbh = DBI->connect($self->getRemoteDSN ());

Get a DBI connection string (Data Source Name or DSN) in a DB-specific way
for a remote database connection.  This DSN should allow a remote client to
connect to the DSN.  Essentially this method ensures that a host specification
is in the DSN, and the host specification is not localhost or 127.0.0.1.

=cut

sub getRemoteDSN {
    die "OME::Database::Delegate->getRemoteDSN is abstract";
}

=head2 tableExists

	die "Table $table doesn't exist" unless $delegate->tableExists($dbh,$table);

Determines if the specified table name exists in the DB.  Not case-sensitive.
Returns undef if table not found, 1 if it exists.

=cut

sub tableExists {
    die "OME::Database::Delegate->tableExists is abstract";
}



=head2 dropColumn

    $delegate->dropColumn ($dbh,$table,$column);

Drop the specified column from the specified table.  Some databases implement
ALTER TABLE DROP COLUMN while others don't.  If the DB doesn't support this
call in SQL, then an alternative would be to remove all constraints, defaults
and triggers for that column, rename it (to dropped_column for instance) and
set all of its values to NULL.

=cut

sub dropColumn {
    die "OME::Database::Delegate->dropColumn is abstract";
}

# after these methods are implemented and used, the boolean hack in
# DBObject->addcolumn should be taken out

=head2 datatypeNeedsTranslation

	if( $delegate->datatypeNeedsTranslation($SQLType) ) {
		# do something
	}

Determine if translation method calls are needed.

Used by EITHER DBObject's addColumn method to cache results in column
definition OR methods that call delegate translation methods.

=cut

=head2 translateDatatypesToDB

	$datum = $delegate->translateDatatypesToDB($SQLType, $datum);

This method converts data types from perl to the database. Boolean
values of 0 or 1 in perl will be translated to 't' or 'f' for database
writes. Timestamps may also need conversions.

Used in DBObject __make*SQL methods

=cut

=head2 translateDatatypesFromDB

	$datum = $delegate->translateDatatypesFromDB( $SQLType, $datum );

Inverse of translateDatatypesToDB.

Used in DBObject __fillInstance method

=cut

=head2 translateQueryClause

	my ($join_clause,\@values) = $delegate->
	    translateQueryClause($SQLType,$location,$operator,\@data);

Formats a query properly for a SELECT statement.  Usually this just
involves concatenating the location, operator, and a question mark.
However, in the case of array values, it is necessary to turn =
operators into IN operators.  Also, the = operator does not usually
work on floats, and must be turned into an appropriate comparison
against an epsilon value.

Anyway, given the location, operator, and data array, this method
should generate a single SQL expression ($join_clause) which tests the
location against the data array with the operator.  If the data array
and operator are not compatible (e.g., multiple values with =), an
error should be thrown.  The join clause should involve bind variables
as much as possible, and the values to be substituted for the bind
variables should be returned as the @values array.  Most of the time,
it will be identical to the @data array.

=cut

=head2 getNextSequenceValue

	my $id = $delegate->getNextSequenceValue($dbh,$sequence);

Returns the next value in the $sequence sequence in the database.  The
method should use the $dbh handle to access the database.

=cut

sub getNextSequenceValue {
    die "OME::Database::Delegate->getNextSequenceValue is abstract";
}



=head2 addNotNullConstraints

	$delegate->addNotNullConstraints($dbh,$class);

This method is responsible for adding any not-null constraints.
The implementation must not add duplicate constraints if they already exist
in the database.

=cut

sub addNotNullConstraints {
    die "OME::Database::Delegate->addNotNullConstraints is abstract";
}




=head2 addForeignKeyConstraints

	$delegate->addForeignKeyConstraints($dbh,$class);

This method is responsible for defining the foreign key constraints for the
the references used in the given class.  The $class parameter may be a class name
or a reference.
The implementation should add FK constraints regardless of the existence
of the ForeignKey option in the class columns' SQL options - it should add FK
constraints for any foreign class referenced by the class's columns.
The implementation is also responsible for not adding duplicate FK constraints,
because this method may be called multiple times on a given class within the same
DB instance.

=cut

sub addForeignKeyConstraints {
    die "OME::Database::Delegate->addForeignKeyConstraints is abstract";
}


=head2 addClassToDatabase

	$delegate->addClassToDatabase($dbh,$className);

This method is responsible for ensuring that the database is setup
properly to store the given DBObject class.  Usually, this just
involves issuing the appropriate CREATE TABLE, ALTER TABLE, and CREATE
SEQUENCE statements.  The method should use the $dbh handle to access
the database.

=cut

sub addClassToDatabase {
    die "OME::Database::Delegate->addClassToDatabase is abstract";
}




=head2 registerListener

	$delegate->registerListener($dbh,$condition);

This method registers a listener for a named condition (a string).
Note that this doesn't involve a callback - for not the implementation
should include a blocking call until the condition occurs.

=cut

sub registerListener {
    die "OME::Database::Delegate->registerListener is abstract";
}


=head2 waitNotifies

	$delegate->waitNotifies($dbh,$timeout);

This method should block until $timeout (in fractional seconds) or forever if undef.
The method returns a reference to an array containing all of the events that occured
or undef if nothing hapened.  Event listeners are registered with registerListener and
un-registered with unregisterListener.  Event names are arbitrary strings.

There is no guarantee that all notifications will be picked up by this method.  It should
return from a block if any registered event happened on any handle.  It is up to the caller
to determine what actually happened (and in what sequence if that's important) by using
tables in the DB.

=cut

sub waitNotifies {
    die "OME::Database::Delegate->waitNotifies is abstract";
}


=head2 unregisterListener

	$delegate->unregisterListener($dbh,$condition);

Un-does a call to registerListener.  The $dbh should no loger respond
to the specified condition.

=cut

sub unregisterListener {
    die "OME::Database::Delegate->unregisterListener is abstract";
}


=head2 notifyListeners

	$delegate->notifyListeners($dbh,$condition);

Sends an asynchronous notification to all listeners of the specified condition.

Note that the whole point of the four methods above is to allow inter-process
communication between processes connected to a common database - by any means.
Implementation must take into account that any data base handle can send a notification
to any other database handle connected to the same DB.

=cut

sub notifyListeners {
    die "OME::Database::Delegate->notifyListeners is abstract";
}



1;
