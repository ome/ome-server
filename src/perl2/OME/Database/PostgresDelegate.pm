# OME/Database/PostgresDelegate.pm

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


package OME::Database::PostgresDelegate;

use strict;
our $VERSION = 2.000_000;

use DBI;
use OME::Database::Delegate;
use base qw(OME::Database::Delegate);

use UNIVERSAL::require;

=head1 NAME

OME::Database::PostgresDelegate - a PostgreSQL implementation of OME::Database::Delegate

=head1 SYNOPSIS

	my $delegate = OME::Database::Delegate->getDefaultDelegate();
	my $dbh = $delegate->connectToDatabase($datasource,
	                                       $username,
	                                       $password);
	my $id = $delegate->getNextSequenceValue($dbh,$sequence);
	$delegate->addClassToDatabase($dbh,$className);

=head1 DESCRIPTION

This class is a PostgreSQL-specific implementation of
OME::Database::Delegate.  It uses the inherited implementations of
getInstance and connectToDatabase.  It overrides getNextSequenceValue
and addClassToDatabase.

All of the methods in this class are described in the
L<OME::Database::Delegate|OME::Database::Delegate> page.

=cut

use constant FIND_DATABASE_SQL => <<SQL;
  SELECT oid
    FROM pg_database
   WHERE lower(datname) = lower(?)
SQL

sub createDatabase {
    my ($self,$platform) = @_;

    print "Creating PostgreSQL database...\n";

    my $dbh;

    $dbh = DBI->connect("dbi:Pg:dbname=template1")
      or die $dbh->errstr();

    my $find_database = $dbh->prepare(FIND_DATABASE_SQL);
    my ($db_oid) = $dbh->selectrow_array($find_database,{},'ome');

    # This will be NULL if the database does not exist
    if (defined $db_oid) {
        $dbh->disconnect();
        return 1;
    }

    $dbh->do('CREATE DATABASE ome')
      or die $dbh->errstr();
    $dbh->disconnect();

    print "\t\033[1m[Done.]\033[0m\n";

    # Debian does this by default using Debconf, everything else needs it.
    # Atleast as far as I know. (Chris)
    if ($platform ne "DEBIAN") {
        print "Adding PL-PGSQL language...\n";
        my $CMD_OUT = `createlang plpgsql ome 2>&1`;
        die $CMD_OUT if $? != 0;
        print "\t\033[1m[Done.]\033[0m\n";
    }

    print "Fixing OID/INTEGER compatability bug...\n";
    $dbh = DBI->connect("dbi:Pg:dbname=ome")
      or die $dbh->errstr();
    my $sql = <<SQL;
CREATE FUNCTION OID(INT8) RETURNS OID AS '
declare
  i8 alias for \$1;
begin
  return int4(i8);
end;'
LANGUAGE 'plpgsql';
SQL
    $dbh->do($sql) or die ($dbh->errstr);
    $dbh->disconnect();
    print "\t\033[1m[Done.]\033[0m\n";

    return 0;
}

# The SQL statement to retrieve a sequence value from the DB.

use constant SEQUENCE_SQL => <<SQL;
  SELECT NEXTVAL(?)
SQL

sub getNextSequenceValue {
    my ($self,$dbh,$sequence) = @_;
    die "getNextSequenceValue: Wrong number of parameters"
      unless defined $dbh && defined $sequence;

    my $sth = $dbh->prepare(SEQUENCE_SQL);
    $sth->execute($sequence);
    my $row = $sth->fetch() or
      die "Could not read from sequence $sequence";

    return $row->[0];
}


# add

# $sth->execute($table_name)
use constant FIND_RELATION_SQL => <<SQL;
  SELECT oid, relkind
    FROM pg_class
   WHERE lower(relname) = lower(?)
SQL

# $sth->execute($table_oid,$column_number)
use constant FIND_COLUMN_BY_NUMBER_SQL => <<SQL;
  SELECT lower(attname)
    FROM pg_attribute
   WHERE attrelid = ?
     AND attnum = ?
SQL

# $sth->execute($table_oid,$column_name)
use constant FIND_COLUMN_BY_NAME_SQL => <<SQL;
  SELECT attnum
    FROM pg_attribute
   WHERE attrelid = ?
     AND lower(attname) = lower(?)
SQL

# $sth->execute($table_oid)
use constant FIND_PRIMARY_KEY_SQL => <<SQL;
  SELECT indkey
    FROM pg_index
   WHERE indrelid = ?
     AND indisprimary
SQL

sub __collectSQLOptions ($$) {
    my ($columns,$aliases) = @_;
    my ($sql_type,$default,$not_null,$unique,$references);

    foreach my $alias (@$aliases) {
        my $sql_options = $columns->{$alias}->[3];
        next unless defined $sql_options;

        if (defined $sql_options->{SQLType}) {
            die "SQL types mismatch"
              if defined $sql_type &&
                $sql_options->{SQLType} ne $sql_type;
            $sql_type = $sql_options->{SQLType};
        }

        if (defined $sql_options->{DefaultValue}) {
            die "Default values mismatch"
              if defined $default &&
                $sql_options->{DefaultValue} ne $default;
            $default = $sql_options->{DefaultValue};
        }

        if (defined $sql_options->{NotNull}) {
            die "NOT NULLs mismatch"
              if defined $not_null &&
                $sql_options->{NotNull} ne $not_null;
            $not_null = $sql_options->{NotNull};
        }

        if (defined $sql_options->{Unique}) {
            die "UNIQUEs mismatch"
              if defined $unique &&
                $sql_options->{Unique} ne $unique;
            $unique = $sql_options->{Unique};
        }

        if (defined $sql_options->{ForeignKey}) {
            die "Foreign keys mismatch"
              if defined $references &&
                $sql_options->{ForeignKey} ne $references;
            $references = $sql_options->{ForeignKey};
        }
    }

    return ($sql_type,$default,$not_null,$unique,$references);
}

sub addClassToDatabase {
    my ($self,$dbh,$class) = @_;

    die "addClassToDatabase: Wrong number of parameters"
      unless defined $dbh && defined $class;

    die "addClassToDatabase: Malformed class name $class"
      unless $class =~ /^\w+(\:\:\w+)*$/;

    die "addClassToDatabase: $class is not a subclass of OME::DBObject"
      unless UNIVERSAL::isa($class,"OME::DBObject");

    # Haha!  I've finally figured out how to get rid of the annoying
    # Postgres notices.  I DON'T CARE IF YOU'RE CREATING TRIGGERS FOR
    # MY FOREIGN KEYS!

    open my $olderr, ">&STDERR";
    open STDERR, ">/dev/null";

    # Do all of our database stuff inside of an eval.  That way, if
    # anything goes wrong, we can clean up after ourselves before we
    # actually die.

    eval {
        my $columns   = $class->__columns();
        my $locations = $class->__locations();
        my $primaries = $class->__primaryKeys();
        my $sequence  = $class->__sequence();

        # Prepare all of the SQL statements we might need
        my $find_relation = $dbh->prepare(FIND_RELATION_SQL);
        my $find_column_by_number = $dbh->prepare(FIND_COLUMN_BY_NUMBER_SQL);
        my $find_column_by_name = $dbh->prepare(FIND_COLUMN_BY_NAME_SQL);
        my $find_primary_key = $dbh->prepare(FIND_PRIMARY_KEY_SQL);

        # Create the primary key sequence if needed
        if (defined $sequence) {
            #print "\n$sequence\n------------------\n";

            my ($reloid,$relkind) =
              $dbh->selectrow_array($find_relation,{},$sequence);
            die "Database contains object named $sequence which is not a sequence!"
              if defined $relkind && $relkind ne 'S';

            if (defined $relkind) {
                #print "Exists!\n";
            } else {
                #print "New sequence!\n";
                my $sql = "CREATE SEQUENCE $sequence";
                $dbh->do($sql)
                  or die "Could not create sequence $sequence";
            }
        }

        # Ensure that each table exists
      TABLE:
        foreach my $table (keys %{$class->__tables()}) {
            #print "\n$table\n------------------\n";

            my ($reloid,$relkind) =
              $dbh->selectrow_array($find_relation,{},$table);
            die "Database contains object named $table which is not a table!"
              if defined $relkind && $relkind ne 'r';

            if (defined $relkind) {
                # The table already exists, issue ALTER TABLE statements
                #print "Exists!\n";

                # Check the primary key
                if (defined $primaries->{$table}) {
                    # This is the name of the column that the DBObject
                    # says should be primary
                    my $dbo_primary_column = $primaries->{$table};

                    # Find out if there is already a primary key defined
                    # for this table.  Here's the kicker: The primary key
                    # might very well be multi-column.  PostgreSQL will
                    # store this as an integer array, which seems to show
                    # up in Perl as a string of integers separated by
                    # spaces.
                    my ($pk_nums) =
                      $dbh->selectrow_array($find_primary_key,{},$reloid);
                    my @pk_nums = split(' ',$pk_nums);

                    # DBObjects can also declare single-column primary
                    # keys.  So, if the primary key, according to the
                    # database, is multi-column, then we know right away
                    # that is conflicts with what the DBObject is asking
                    # for.
                    die "Table $table has a multi-column primary key!"
                      if (scalar(@pk_nums) > 1);

                    if (scalar(@pk_nums) == 1) {
                        # If there is a single-column primary key in the
                        # database, verify that it's the same column that
                        # the DBObject wants to be the primary key.
                        my ($pk_name) =
                          $dbh->selectrow_array($find_column_by_number,{},
                                                $reloid,$pk_nums[0]);

                        die "Table $table already has a primary key ($pk_name)!"
                          if ($pk_name ne $dbo_primary_column);

                        #print "Primary key exists!\n";
                    } else {
                        # At this point, there is no primary key defined
                        # in the database.  First, we must check whether
                        # the primary key column exists.  If so, we issue
                        # an ALTER TABLE statement to make it the primary
                        # key.  If not, we issue a different ALTER TABLE
                        # statement to add the column.

                        my ($pk_num) =
                          $dbh->selectrow_array($find_column_by_name,{},
                                                $reloid,$dbo_primary_column);

                        my $sql;
                        my @bind_vals;
                        if (defined $pk_num) {
                            $sql =
                              "ALTER TABLE $table ADD CONSTRAINT PRIMARY KEY(".
                                "$dbo_primary_column)";
                        } else {
                            $sql =
                              "ALTER TABLE $table ADD COLUMN ".
                                "$dbo_primary_column INTEGER";
                            if (defined $sequence) {
                                $sql .= " DEFAULT NEXTVAL(?)";
                                push @bind_vals, $sequence;
                            }
                            $sql .= " PRIMARY KEY";
                        }

                        #print "$sql\n(",join(',',@bind_vals),")\n";
                        $dbh->do($sql,{},@bind_vals)
                          or die "Could not add primary key to existing table!";
                    }
                }

                # Now, check each of the columns defined by DBObject aliases.

                my $table_hash = $locations->{$table};
              COLUMN:
                foreach my $column (keys %$table_hash) {
                    my $aliases = $table_hash->{$column};
                    my ($sql_type,$default,$not_null,$unique,$references) =
                      __collectSQLOptions($columns,$aliases);

                    next COLUMN
                      unless defined $sql_type;

                    # See if the column exists already
                    my ($col_num) =
                      $dbh->selectrow_array($find_column_by_name,{},
                                            $reloid,$column);

                    if (defined $col_num) {
                        #print "$column exists!\n";

                        # FIXME: We should try to verify the type and
                        # other SQL options.
                    } else {
                        #print "New column ($column)!\n";

                        my $sql = "ALTER TABLE $table ADD COLUMN $column $sql_type";
                        my @bind_vals;

                        if (defined $default) {
                            $sql .= " DEFAULT ?";
                            push @bind_vals, $default;
                        }

                        $sql .= " NOT NULL" if $not_null;
                        $sql .= " UNIQUE" if $unique;
                        $sql .=
                          " REFERENCES $references DEFERRABLE INITIALLY DEFERRED"
                            if defined $references;

                        #print "$sql\n(",join(',',@bind_vals),")\n";
                        $dbh->do($sql,{},@bind_vals)
                          or die "Could not add column $column to $table!";
                    }
                }
            } else {
                # The table does not exists, issue one big CREATE TABLE statement.
                #print "New table!\n";
                my @column_sqls;
                my @bind_vals;

                # First, add the primary key for this table (if any).
                if (defined $primaries->{$table}) {
                    my $key_sql = $primaries->{$table}." INTEGER";
                    if (defined $sequence) {
                        $key_sql .= " DEFAULT NEXTVAL(?)";
                        push @bind_vals, $sequence;
                    }
                    $key_sql .= " PRIMARY KEY";
                    push @column_sqls, $key_sql;
                }

                # Now, add all of the columns defined by DBObject aliases.

                my $table_hash = $locations->{$table};
                foreach my $column (keys %$table_hash) {
                    #print "  $column\n";
                    my $aliases = $table_hash->{$column};
                    my ($sql_type,$default,$not_null,$unique,$references) =
                      __collectSQLOptions($columns,$aliases);

                    die "$column does not have an SQL type!"
                      unless defined $sql_type;

                    my $column_sql = "$column $sql_type";

                    if (defined $default) {
                        $column_sql .= " DEFAULT ?";
                        push @bind_vals, $default;
                    }

                    $column_sql .= " NOT NULL" if $not_null;
                    $column_sql .= " UNIQUE" if $unique;
                    $column_sql .=
                      " REFERENCES $references DEFERRABLE INITIALLY DEFERRED"
                        if defined $references;

                    push @column_sqls, $column_sql;
                }

                # Join all of the column definitions together into a
                # CREATE TABLE statement, and execute it.

                my $create_sql = "CREATE TABLE $table (".
                  join(", ",@column_sqls).")";

                #print "$create_sql\n(",join(", ",@bind_vals),")\n";
                $dbh->do($create_sql) or die "Could not create table $table";
            }
        }
    };

    # Save any error message so that the close/open below doesn't
    # clobber it.
    my $err = $@;

    # Restore standard error
    close STDERR;
    open STDERR, ">&", $olderr;

    # Rethrow any error that might have occurred
    die $err if $@;
}


1;
