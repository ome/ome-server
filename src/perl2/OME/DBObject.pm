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

use strict;
our $VERSION = 2.000_000;

use Carp;
use Class::Data::Inheritable;
use UNIVERSAL::require;
use OME::Database::Delegate;

use base qw(Class::Data::Inheritable);
use fields qw(__session __id __fields __changeFields);

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

# The sequence used to get new primary key ID's
__PACKAGE__->mk_classdata('__sequence');

# Whether this class has been defined
__PACKAGE__->mk_classdata('__classDefined');

# Whether this class is cached
__PACKAGE__->mk_classdata('Caching');

__PACKAGE__->Caching(0);
__PACKAGE__->__classDefined(0);


sub newClass {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    $class->__classDefined(1);
    $class->__columns({});
    $class->__locations({});
    $class->__defaultTable(undef);
    $class->__tables({});
    $class->__primaryKeys({});
    $class->__sequence(undef);

    return;
}

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

sub setSequence {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $sequence = shift;
    die "setSequence called with no parameters"
      unless defined $sequence;

    $class->__sequence($sequence);
    return;
}

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

    return;
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
          unless $foreign_key_class =~ /^\w+(\:\:\w+)*$/;
    }

    #print "Adding $table.$column to $class\n";

    foreach my $alias (@$aliases) {
        # Create an entry in __columns
        $class->__columns()->{$alias} = [$table,$column,
                                         $foreign_key_class,
                                         $sql_options];

        # Create an accessor/mutator
        my $accessor;

        if (defined $foreign_key_class) {
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
                    return $self->{__session}->Factory()->
                      loadObject($foreign_key_class,$datum);
                }
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

sub getColumn {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $alias = shift;

    return $class->__columns()->{$alias};
}

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

    foreach my $alias (@$aliases) {
        # Create an accessor/mutator
        my $accessor = sub {
            my $self = shift;
            my $factory = $self->{__session}->Factory();
            return $factory->findObjects($foreign_key_class,
                                         $foreign_key_alias => $self->{__id});
        };

        no strict 'refs';
        *{"$class\::$alias"} = $accessor;
    }
}

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

sub __makeSelectSQL {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($columns_wanted,$criteria) = @_;

    if ((!defined $columns_wanted) || (scalar(@$columns_wanted) <= 0)) {
        $columns_wanted = [keys %{$class->__columns()}];
    }

    # These three variables will correspond to the three sections of
    # the SELECT statement: the list of columns, the list of tables,
    # and the WHERE clause.
    my @columns_needed;
    my %tables_used;
    my @join_clauses;

    my $columns = $class->__columns();

    # Add each requested column to the @columns_needed array.  The
    # contents of this array are valid DB locations, so we build this
    # as necessary from the contents of the __columns array.  This
    # loop also populates the %tables_used hash.
    foreach my $column_alias (@$columns_wanted) {
        my $column = $columns->{$column_alias};
        confess "Column $column_alias does not exist"
          unless defined $column;

        push @columns_needed, $column->[0].".".$column->[1];

        # We are just using the keys of this hash, so the value is
        # unimportant.
        $tables_used{$column->[0]} = undef;
    }

    my $id_criteria = 0;

    # Look through the criteria, if there are any.  Add the criteria
    # entries to the WHERE clause list, and also make sure that the
    # tables used by each criterion are in the %tables_used hash.
    if (defined $criteria) {
        foreach my $column_alias (keys %$criteria) {
            my $location;

            # A key of "id" in the criteria hash is a special case -
            # it will always refer to the primary key field.
            if ($column_alias eq 'id') {
                $location = "id";
            } else {
                my $column = $columns->{$column_alias};
                confess "Column $column_alias does not exist"
                  unless defined $column;
                $location = $column->[0].".".$column->[1];
                $tables_used{$column->[0]} = undef;
            }

            my $criterion = $criteria->{$column_alias};
            my ($operation,$value);

            if (ref($criterion) eq 'ARRAY') {
                $value = $criterion->[1];
                $operation = defined $value? $criterion->[0]: "is";
            } else {
                $value = $criterion;
                $operation = defined $value? "=": "is";
            }

            # If the value is an object, assume that it has an id
            # method, and use that in the SQL query.
            $value = $value->id() if ref($value);

            if ($location eq 'id') {
                push @join_clauses, [$operation];
                $id_criteria = 1;
            } else {
                push @join_clauses, "$location $operation ?";
            }
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
        map { $_ = "$first_key ".$_->[0]." ?" if ref($_); } @join_clauses;
    }

    my $sql = "select ". join(", ",@columns_needed). " from ".
      join(", ",keys(%tables_used));

    $sql .= " where ". join(" and ",@join_clauses)
      if scalar(@join_clauses) > 0;

    return ($sql,defined $first_key);
}

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

        die "Cannot update $table if we don't know the primary key!"
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

    return (\@sqls, $key_val);
}

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

sub __createNewInstance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session,$dbh,$data_hash) = @_;
    my ($sqls,$key_val) = $class->__makeInsertSQLs($dbh,$data_hash);

    # FIXME: How do we want to handle atomicity?  Currently, if any of
    # the INSERT statements fail, an undef object is returned, but
    # none of the statements which succeeded are rolled back.  (This
    # would require a hierarchical transaction system.)
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
                __session => $session,,
                __fields  => \%fields,
                __id      => $key_val,
                __changedFields => {},
               };

    return bless $self,$class;
}

sub __writeToDatabase {
    my ($self,$dbh) = @_;

    my $sqls = $self->__makeUpdateSQLs();

    # FIXME: Just like in __createNewInstance, we don't handle
    # atomicity very well.
    foreach my $sql_entry (@$sqls) {
        my ($sql,$values) = @$sql_entry;
        my $sth = $dbh->prepare($sql);
        $sth->execute(@$values) or die "Cannot write object to database!";
    }

    $self->{__changedFields} = {};

    return;
}

sub __newInstance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session,$sth,$id_available,$columns_wanted) = @_;
    my $sth_vals;

    return undef unless $sth_vals = $sth->fetch();

    if ((!defined $columns_wanted) || (scalar(@$columns_wanted) <= 0)) {
        $columns_wanted = [keys %{$class->__columns()}];
    }

    # Try to preallocate the field hash as closely as possible.
    my %fields;
    #keys %fields = scalar(@$sth_vals);

    my $i = 0;

    my $id;
    if ($id_available) {
        $id = $sth_vals->[$i++];
    }

    my $self = {
                __session => $session,
                __fields  => \%fields,
                __id      => $id,
                __changedFields => {},
               };

    # Place the values returned from the database into the __fields
    # instance variable.  This will set the entries for a NULL field
    # to be undef.  This means that when the accessor tries to
    # retrieve a value, exists will return true, while defined will
    # return false.
    my $columns = $class->__columns();
    foreach my $alias (@$columns_wanted) {
        my $entry = $columns->{$alias};
        my $table = $entry->[0];
        my $column = $entry->[1];
        $fields{$table}->{$column} = $sth_vals->[$i++];
    }

    return bless $self, $class;
}

sub __newByID {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session,$dbh,$id,$columns_wanted) = @_;

    $columns_wanted = [keys %{$class->__columns()}]
      unless defined $columns_wanted && scalar(@$columns_wanted) > 0;
    my ($sql,$id_available) = $class->__makeSelectSQL($columns_wanted,
                                                      {id => $id});

    die "ID not available"
      unless $id_available;

    #print "\n$sql\n";

    my $sth = $dbh->prepare($sql);
    eval {
        $sth->execute($id);
    };
    confess $@ if $@;

    return $class->__newInstance($session,$sth,$id_available,$columns_wanted);
}

sub Session { return shift->{__session}; }
sub id { return shift->{__id}; }
sub ID { return shift->{__id}; }

sub storeObject {
    my $self = shift;

    if (%{$self->{__changedFields}}) {
        my $session = $self->{__session};
        my $factory = $session->Factory();
        my $dbh = $factory->obtainDBH();
        eval {
            $self->__writeToDatabase($dbh);
        };
        $factory->releaseDBH($dbh);
        die $@ if $@;
    }

    return;
}

sub writeObject {
    carp "**** writeObject is deprecated!";
    my $self = shift;
    $self->storeObject();
    $self->{__session}->commitTransaction();
}


1;
