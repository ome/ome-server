# OME/Database/PostgresDelegate.pm

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


package OME::Database::PostgresDelegate;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use DBI;
use OME::Database::Delegate;
use base qw(OME::Database::Delegate);

use UNIVERSAL::require;
use IO::Select;
use Sys::Hostname;


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
	my ($self,$superuser,$password) = @_;

	my $dsn = $self->getDSN();
	$dsn =~ s/dbname=([^\s;:]+)/dbname=template1/;
	my $dbName = $1;
	die "The name of the ome database was not specified!" unless $dbName;

	print "Creating PostgreSQL database $dbName...";

	my $dbh = $self->connectToDatabase( {
		DataSource => $dsn,
		DBUser	   => $superuser,
		DBPassword => $password,
		AutoCommit => 1,
		InactiveDestroy => 1,
	} );
	unless ($dbh) {
    	$self->errorStr($DBI::errstr);
		die "Could not connect to the database";
	}
	
	my $find_database = $dbh->prepare(FIND_DATABASE_SQL);
	my ($db_oid) = $dbh->selectrow_array($find_database,{},$dbName);

	# This will be NULL if the database does not exist
	if (defined $db_oid) {
		$dbh->disconnect();
		return 1;
	}

	$dbh->do(qq{CREATE DATABASE "$dbName"}) or die $dbh->errstr();
	print "\t\033[1m[Done.]\033[0m\n";
	$dbh->disconnect();

	print "Fixing OID/INTEGER compatability bug...";
	$dbh = $self->connectToDatabase({AutoCommit => 1}) or die $dbh->errstr();

	my $sth = $dbh->prepare("SELECT oid FROM pg_language WHERE lanname = 'plpgsql'");
	($db_oid) = $dbh->selectrow_array($sth);
	unless ($db_oid) {
		$sth = $dbh->prepare("SELECT oid FROM pg_proc
			WHERE proname = 'plpgsql_call_handler'
			AND prorettype = 0 AND pronargs = 0"
		);
		my ($func_oid) = $dbh->selectrow_array($sth);
		$dbh->do (q[CREATE FUNCTION "plpgsql_call_handler" ()
			RETURNS OPAQUE AS '$libdir/plpgsql' LANGUAGE C]
		) unless $func_oid;
		$dbh->do (q[CREATE TRUSTED LANGUAGE "plpgsql" HANDLER "plpgsql_call_handler"])
			or die $dbh->errstr();
	}

	my $sql = <<SQL;
CREATE FUNCTION OID(INT8) RETURNS OID AS '
declare
  i8 alias for \$1;
begin
  return int4(i8);
end;'
LANGUAGE 'plpgsql';
SQL
	$dbh->{RaiseError} = 0;
	$dbh->do ($sql);
	if ($dbh->errstr()) {
		die ($dbh->errstr) unless $dbh->errstr() =~ /already exists/;
	}
	$dbh->disconnect();
	print "\t\033[1m[Done.]\033[0m\n";

	return 1;
}


use constant FIND_USER_SQL => <<SQL;
  SELECT usename,usecreatedb,usesuper
    FROM pg_shadow
   WHERE usename = ?
SQL


# Create a postgres superuser SQL: CREATE USER foo CREATEUSER CREATEDB
sub createUser {
    my ($self,$username,$isSuperuser,$superuser,$password) = @_;
    my $retval;
    my $success;

    my $dsn = $self->getDSN();
    $dsn =~ s/dbname=([^\s;:]+)/dbname=template1/;
    my $dbName = $1;
    die "The name of the ome database was not specified!" unless $dbName;

    my $dbh = $self->connectToDatabase( {
        DataSource => $dsn,
        DBUser     => $superuser,
        DBPassword => $password,
        AutoCommit => 1,
		InactiveDestroy => 1,
        RaiseError => 0,
        PrintError => 0
    } );
    unless ($dbh) {
    	$self->errorStr($DBI::errstr);
		return 0;
    }

    my $find_user = $dbh->prepare(FIND_USER_SQL);
    my ($db_name,$db_create,$db_super) = $dbh->selectrow_array($find_user,{},$username);
    
    if ($db_name) {
            unless ( ($db_create and $db_super and $isSuperuser) or
                (not $db_create and not $db_super and not $isSuperuser)
            ) {
                $dbh->disconnect();
                die "Modifying user priviledges is not supported - sorry.";
            }
    } else {
        my $sql = "CREATE USER $username";
        $sql .= ' CREATEUSER CREATEDB' if ($isSuperuser);
        $dbh->do($sql);
		$self->errorStr($dbh->errstr());
    }
    ($db_name,$db_create,$db_super) = $dbh->selectrow_array($find_user,{},$username);
    $dbh->disconnect();
    return 1 if $db_name eq $username;
    return 0;
}



sub getDSN {
    my ($self,$dbConf) = @_;
    $dbConf = OME::Install::Environment->initialize()->DB_conf()
        unless $dbConf and exists $dbConf->{Name} and $dbConf->{Name};
    die "Could not get DB configuration enevironment\n".
        "Maybe the installation environment did not load?" unless $dbConf;
# the dbConf consists of the following
#    User     =>
#    Password =>
#    Host     =>
#    Port     =>
#    Name     =>

    my $host_str = $dbConf->{Host} ? ';host='.$dbConf->{Host} : '';
    my $port_str = $dbConf->{Port} ? ';port='.$dbConf->{Port} : '';
    return 'dbi:Pg:dbname='.$dbConf->{Name}.$host_str.$port_str;
}

sub getRemoteDSN {
    my ($self) = @_;
	my $dsn = $self->getDSN();
	$dsn .= ';host='.hostname()
			unless $dsn =~ /;host=\S+/
			and not $dsn =~ /;host=localhost/
			and not $dsn =~ /;host=127.0.0.1/;
	return ($dsn);
}

use constant GET_VERSION_SQL => <<SQL;
  SELECT version();
SQL

# $sth->execute($table_name)
use constant FIND_RELATION_SQL => <<SQL;
  SELECT oid, relkind
    FROM pg_class
   WHERE lower(relname) = lower(?)
SQL
# add

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

# $dbh->selectcol_arrayref($sth,$table_oid)
use constant FIND_TABLE_INDEX_NAMES_SQL => <<SQL;
  SELECT pg_get_indexdef(indexrelid)
    FROM pg_index
   WHERE indrelid = ?
SQL

sub dropColumn {
	my ($self,$dbh,$table,$column) = @_;
	die "dropColumn: Wrong number of parameters"
		unless $dbh and $table and $column;
	$table = lc ($table);
	$column = lc ($column);

	# Get the table oid		
	my ($reloid)  = $dbh->selectrow_array(FIND_RELATION_SQL,{},$table);
	return unless $reloid;

	# Get the column oid		
	my ($coloid)  = $dbh->selectrow_array(FIND_COLUMN_BY_NAME_SQL,{},$reloid,$column);
	return unless $coloid;

	# Get the DB version
	my $sth = $dbh->prepare('SELECT version()');
	my ($db_version) = $dbh->selectrow_array($sth);
	$db_version = $1 if $db_version =~ /PostgreSQL\s+([\d.]+)/;

	# Postgres > 7.3 implements drop column in SQL
	if ($db_version ge '7.3') {
		$dbh->do("ALTER TABLE $table DROP COLUMN $column") or die $dbh->errstr();

	# In Postgres < 7.3 we have to do stuff manually.
	} else {
		# remove triggers
		my ($trigger)  = $dbh->selectrow_array(
			"SELECT tgname FROM pg_trigger WHERE tgrelid=$reloid and tgargs like '%$column%'"
		) or die $dbh->errstr();
		$dbh->do("DROP TRIGGER \"$trigger\" ON $table") if $trigger;

		# Determine a new name for the dropped column (dropped_column##)
		my $sth = $dbh->prepare ("SELECT * from $table LIMIT 1");
		$sth->execute();
		my %cols;
		$cols{$_} = 1 foreach (@{$sth->{NAME_lc}});
		my $new_col_name = 'dropped_column';
		if (exists $cols{$new_col_name}) {
			my $i=1;
			$i++ while exists $cols{$new_col_name.'_'.$i};
			$new_col_name = $new_col_name.'_'.$i;
		}

		# remove not null constraint
		$dbh->do(<<SQL)  or die $dbh->errstr();
			UPDATE pg_attribute SET attnotnull = FALSE WHERE attname = '$column'
			AND attrelid = ( SELECT oid FROM pg_class WHERE relname = '$table' )
SQL

		# remove default
		$dbh->do("ALTER TABLE $table ALTER COLUMN $column DROP DEFAULT")
			or die $dbh->errstr();

		# remove indexes
		my $indexes = $dbh->selectcol_arrayref (FIND_TABLE_INDEX_NAMES_SQL,{},$reloid);
		foreach my $index (@$indexes) {
			if ($index =~ /INDEX\s+(\S+)\s+ON\s+(\S+)[^(]+\(([^)]+)/i) {
				my ($idx_name,$idx_table,$idx_col) = ($1,$2,$3);
				if ( lc($idx_table) eq lc($table) and lc($idx_col) eq lc ($column) ) {
					$dbh->do("DROP INDEX $idx_name")
						or die $dbh->errstr();
				}
			}
		}

		# set the column to NULL
		$dbh->do("UPDATE $table SET $column=null") or die $dbh->errstr();

		# rename the column
		$dbh->do("ALTER TABLE $table RENAME COLUMN $column TO $new_col_name")
			or die $dbh->errstr();
	}
	
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



# $sth->execute($table_oid)
use constant FIND_PRIMARY_KEY_SQL => <<SQL;
  SELECT indkey
    FROM pg_index
   WHERE indrelid = ?
     AND indisprimary
SQL

sub __collectSQLOptions ($$) {
    my ($columns,$aliases) = @_;
    my ($sql_type,$default,$not_null,$unique,$references,$indexed);

    foreach my $alias (@$aliases) {
        my $sql_options = $columns->{$alias}->[3];
        next unless defined $sql_options;

        if (defined $sql_options->{SQLType}) {
            die "SQL types mismatch"
              if defined $sql_type &&
                $sql_options->{SQLType} ne $sql_type;
            $sql_type = $sql_options->{SQLType};
        }

        if (defined $sql_options->{Default}) {
            die "Default values mismatch"
              if defined $default &&
                $sql_options->{Default} ne $default;
            $default = $sql_options->{Default};
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

        if (defined $sql_options->{Indexed}) {
            die "INDEXes mismatch"
              if defined $indexed &&
                $sql_options->{Indexed} ne $indexed;
            $indexed = $sql_options->{Indexed};
        }
    }

    return ($sql_type,$default,$not_null,$unique,$references,$indexed);
}

sub __createSequence {
    my ($self,$dbh,$sequence) = @_;
    my $find_relation = $dbh->prepare_cached(FIND_RELATION_SQL);

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

    return;
}

my $index_sequence_created = 0;
use constant INDEX_SEQUENCE_NAME => 'OME__INDEX_SEQ';

our $CREATE_INDICES = 1;

sub __createIndex {
    my ($self,$dbh,$table,$column) = @_;

    return unless $CREATE_INDICES;

    die "Invalid table name"
      unless $table =~ /^\w+$/;
    die "Invalid column name"
      unless $column =~ /^\w+$/;

    if (!$index_sequence_created) {
        $self->__createSequence($dbh,INDEX_SEQUENCE_NAME());
        $index_sequence_created = 1;
    }

    my $find_relation = $dbh->prepare_cached(FIND_RELATION_SQL);
    my $find_index_names = $dbh->prepare_cached(FIND_TABLE_INDEX_NAMES_SQL);
    
    my ($reloid)  = $dbh->selectrow_array($find_relation,{},$table);

    # Get all indexes for this table/column.
    my $hasindex = 0;
    my $indexes = $dbh->selectcol_arrayref ($find_index_names,{},$reloid);
    my ($ome_idx,$sys_idx);
    my %extra_indexes;
    foreach my $index (@$indexes) {
        if ($index =~ /INDEX\s+(\S+)\s+ON\s+(\S+)[^(]+\(([^)]+)/i) {
            my ($idx_name,$idx_table,$idx_col) = ($1,$2,$3);
            if ( lc($idx_table) eq lc($table) and lc($idx_col) eq lc ($column) ) {
                if ($idx_name =~ /^OME__INDEX_\d+$/i) {
                    # We're going to drop all but one ome index for this column
                    $extra_indexes {$idx_name} = $idx_name if $ome_idx or $sys_idx;
                    $ome_idx = $idx_name unless $ome_idx;
                } else {
                    # This is a system index for this column (not one we made explicitly)
                    # We're going to keep all of these, but if we have at least one, we're
                    # dropping the ome index
                    $sys_idx = $idx_name;
                    $extra_indexes {$ome_idx} = $ome_idx;
                }
            }
        }
    }
    
    if (not ($ome_idx or $sys_idx)) {    
        my $index_name;
        my $index_good = 0;

        until ($index_good) {
            my $index_number = $self->
              getNextSequenceValue($dbh,INDEX_SEQUENCE_NAME());
            $index_name = "OME__INDEX_".$index_number;
    
            my ($reloid,$relkind) =
              $dbh->selectrow_array($find_relation,{},$index_name);
    
            $index_good = !defined $relkind;
        }
    
        my $sql = "CREATE INDEX $index_name ON $table ($column)";
        $dbh->do($sql)
          or die "Could not create index of ${table}.${column}";
    } else {
        foreach my $idx_name (keys %extra_indexes) {
            my $sql = "DROP INDEX $idx_name";
            $dbh->do($sql)
              or die "Could not drop index $idx_name of ${table}.${column}";
        }
    }
}

sub addClassToDatabase {
    my ($self,$dbh,$class) = @_;

    die "addClassToDatabase: Wrong number of parameters"
      unless defined $dbh && defined $class;

    die "addClassToDatabase: Malformed class name $class"
      unless $class =~ /^\w+(\:\:\w+)*$/;

    die "addClassToDatabase: $class is not a subclass of OME::DBObject"
      unless UNIVERSAL::isa($class,"OME::DBObject");

    my $columns   = $class->__columns();
    my $locations = $class->__locations();
    my $primaries = $class->__primaryKeys();
    my $sequence  = $class->__sequence();

    # Prepare all of the SQL statements we might need
    my $find_relation = $dbh->prepare_cached(FIND_RELATION_SQL);
    my $find_column_by_number = $dbh->prepare_cached(FIND_COLUMN_BY_NUMBER_SQL);
    my $find_column_by_name = $dbh->prepare_cached(FIND_COLUMN_BY_NAME_SQL);
    my $find_primary_key = $dbh->prepare_cached(FIND_PRIMARY_KEY_SQL);

    # Create the primary key sequence if needed
    if (defined $sequence) {
        $self->__createSequence($dbh,$sequence);
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
                    #
                    # IGG 12/10/03:  Refactored this a wee bit to work with 7.2
                    # No column, so add it.
                    if (not defined $pk_num) {
                        $sql =
                          "ALTER TABLE $table ADD COLUMN ".
                            "$dbo_primary_column INTEGER";
                        $dbh->do($sql)
                          or die "Could not add primary key column to existing table!";
                    }

                    # Give the column a NOT NULL constraint.  No harm, no foul if its already there
                    $sql = "UPDATE pg_attribute SET attnotnull = TRUE WHERE attname = '$dbo_primary_column' ".
                        "AND attrelid = ( SELECT oid FROM pg_class WHERE relname = '$table')";
                    $dbh->do($sql)
                      or die "Could not add NOT NULL constraint to column $dbo_primary_column in table $table!";

                    # Add the primary key constraint
                    $sql = "ALTER TABLE $table ADD PRIMARY KEY ($dbo_primary_column)";
                    $dbh->do($sql)
                      or die "Could not add primary key to existing table!";
 
                    # Add the sequence if there is one.
                    if (defined $sequence) {
                        my @bind_vals;
                    	$sql = "ALTER TABLE $table ALTER $dbo_primary_column SET DEFAULT NEXTVAL(?)"; 
                        push @bind_vals, $sequence;
						$dbh->do($sql,{},@bind_vals)
						  or die "Could not add default for column $dbo_primary_column in table $table!";
                    }
                }
            }

            # Now, check each of the columns defined by DBObject aliases.

            my $table_hash = $locations->{$table};
          COLUMN:
            foreach my $column (keys %$table_hash) {
                my $aliases = $table_hash->{$column};
                my ($sql_type,$default,$not_null,$unique,$references,$indexed) =
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
                    # IGG 12/10/03:  Refactored this a wee bit to work with 7.2

                    my $sql = "ALTER TABLE $table ADD COLUMN $column $sql_type";
                    $sql .=
                      " REFERENCES $references DEFERRABLE INITIALLY DEFERRED"
                        if defined $references;
                    $dbh->do($sql)
                      or die "Could not add column $column to $table!";


                    if (defined $default) {
                        my @bind_vals;
                    	$sql = "ALTER TABLE $table ALTER $column SET DEFAULT ?"; 
                        push @bind_vals, $default;
						$dbh->do($sql,{},@bind_vals)
						  or die "Could not add default for column $column in table $table!";
                    }
                    
                    if ($not_null) {
                        $sql = "UPDATE pg_attribute SET attnotnull = TRUE WHERE attname = '$column' ".
                            "AND attrelid = ( SELECT oid FROM pg_class WHERE relname = '$table')";
						$dbh->do($sql)
						  or die "Could not add NOT NULL constraint to column $column in table $table!";
                    }

                    if ($unique) {
                     	$sql = "ALTER TABLE $table ADD CONSTRAINT $table"."_$column"."_key UNIQUE ($column)"; 
						$dbh->do($sql)
						  or die "Could not add UNIQUE constraint to column $column in table $table!";
                   }

                    #print STDERR "$sql\n(",join(',',@bind_vals),")\n";
                }

                if ($indexed) {
                    $self->__createIndex($dbh,$table,$column);
                }
            }
        } else {
            # The table does not exists, issue one big CREATE TABLE statement.
            #print "New table!\n";
            my @column_sqls;
            my @bind_vals;
            my @indices;

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
                my ($sql_type,$default,$not_null,$unique,$references,$indexed) =
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
                push @indices, $column
                  if $indexed;
            }

            # Join all of the column definitions together into a
            # CREATE TABLE statement, and execute it.

            my $create_sql = "CREATE TABLE $table (".
              join(", ",@column_sqls).")";

            #print "$create_sql\n(",join(", ",@bind_vals),")\n";
            $dbh->do($create_sql,{},@bind_vals)
              or die "Could not create table $table";

            foreach my $column (@indices) {
                $self->__createIndex($dbh,$table,$column);
            }
        }
    }
}


sub registerListener {
my ($self,$dbh,$condition) = @_;

	$dbh->do (qq/LISTEN "$condition"/);
}

sub waitNotifies {
my ($self,$dbh,$timeout) = @_;
my @notices;

	my $fd = $dbh->func ('getfd') or
		die "Unable to get PostgreSQL back-end FD";
	my $sel = IO::Select->new ($fd);
	# Block until something happens
	if (defined $timeout) {
		$sel->can_read ($timeout);
	} else {
		$sel->can_read ();
	}
	my $notify = 1;
	while ($notify) {
		$notify = $dbh->func ('pg_notifies');
		push (@notices,$notify->[0]) if $notify;
	}
	return undef unless scalar @notices;
	return \@notices;
}


sub unregisterListener {
my ($self,$dbh,$condition) = @_;
	$dbh->do (qq/UNLISTEN "$condition"/);
}

sub notifyListeners {
my ($self,$dbh,$condition) = @_;
	$dbh->do (qq/NOTIFY "$condition"/);
}

1;
