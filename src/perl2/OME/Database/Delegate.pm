# OME/Database/Delegate.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Database::Delegate;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use DBI;
use UNIVERSAL::require;

=head1 NAME

OME::Database::Delegate - database-platform-specific routines

=head1 SYNOPSIS

	my $delegate = OME::Database::Delegate->getDefaultDelegate();
	my $dbh = $delegate->connectToDatabase($datasource,
	                                       $username,
	                                       $password);
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

The current way to obtain an implementation of OME::Database::Delegate
assumes that the Postgres delegate is the only one in the system.  Of
course, this will have to change once we have more implementations.
Unfortunately, we can't retrieve this configuration parameter from the
database, since the delegate is responsible for connecting to the
database.

=head2 getDefaultDelegate

	my $delegate = OME::Database::Delegate->getDefaultDelegate();

Determines the name of the appropriate implementation of
Database::Delegate.  For now, this is hard-coded to
"OME::Database::PostgresDelegate".  In the future, it will come from a
configuration setting.  The getInstance() method of this class is
called, and its result returned.

=cut

sub getDefaultDelegate {
    # I didn't want to put this at the top of the file as a
    # full-fledged "use" statement, since we really shouldn't need to
    # have Database::Delegate require Database::PostgresDelegate.
    OME::Database::PostgresDelegate->require();
    return OME::Database::PostgresDelegate->getInstance();
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

=head2 createDatabase

	my $already_exists = $delegate->createDatabase($platform);

Creates the OME database.  This does not create any tables or other
database objects; it just ensures that the appropriate database
exists.  If the database already exists, this method should return a
true value.  If the database did not exists, and was created
successfully, it should return false.  If the database could not be
created successfully, it should die with an appropriate error message.

=cut

sub createDatabase {
    die "OME::Database::Delegate->createDatabase is abstract";
}

=head2 connectToDatabase

	my $dbh = $delegate->connectToDatabase($datasource,
	                                       $username,
	                                       $password);

Connects to the database with the given connection information.  In
most cases, the default implementation of this method, which just
calls DBI->connect, is sufficient.  If a database server requires
extra setup of the database handle, this method can be overridden to
provide it.

=cut

sub connectToDatabase {
    my ($self,$datasource,$username,$password) = @_;
    my $dbh = DBI->connect(OME::DBConnection->DataSource(),
                           OME::DBConnection->DBUser(),
                           OME::DBConnection->DBPassword(),
                           { RaiseError => 1, AutoCommit => 0 });
    return $dbh;
}

=head2 getNextSequenceValue

	my $id = $delegate->getNextSequenceValue($dbh,$sequence);

Returns the next value in the $sequence sequence in the database.  The
method should use the $dbh handle to access the database.

=cut

sub getNextSequenceValue {
    die "OME::Database::Delegate->getNextSequenceValue is abstract";
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


1;
