# This module is the superclass of any Perl object stored in the
# database.

package OME::DBObject;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $factory = shift;
    
    my $self = {};

    $self->{_factory} = $factory;
    $self->{_fields} = undef;
    bless $self,$class;
}


# Accessors
# ---------

sub ID { my $self = shift; return $self->{id} = shift if @_; return $self->{id}; }
sub DBH { my $self = shift; return $self->{_factory}->DBH(); }


# createObject
# ------------
# This method generates a new ID for this object.  It does not place
# any data into the database, in case there are field constraints
# which would be violated without real data.  After filling in the
# object's fields with data, writeObject can be called to commit the
# object to the database.

sub createObject {
    my $self = shift;
    my $fields = $self->{_fields};

    if (!defined $fields || !exists $fields->{id}) {
	return 0;
    }

    my $idSequence = $fields->{id}->[2];

    my ($dbh,$sth,$sql,$rs);
    $dbh = $self->DBH();
    $sql = "select nextval(?)";
    $rs = $dbh->selectrow_array($sql,{},$idSequence);
    if (defined $rs) {
	$self->{id} = $rs;
	return 1;
    } else {
	return 0;
    }
}

# writeObject
# -----------
# This method assumes the object contains a complete set of valid
# data, including a primary key ID.  If this is a new object,
# createObject should be called first to retrieve a valid, unique key
# for this object.

sub writeObject {
    my $self = shift;
    my $fields = $self->{_fields};

    if (!defined $fields || !exists $fields->{id}) {
	return 0;
    }

    my %tables;
    my $idFieldName = $fields->{id}->[1];

    foreach my $fieldName (keys %$fields) {
	if ($fieldName ne 'id') {
	    my $fieldDef = $fields->{$fieldName};
	    my ($tableName, $columnName) = @$fieldDef;

	    push @{$tables{$tableName}->[0]}, $columnName;
	    push @{$tables{$tableName}->[1]}, $self->{$fieldName};
	    push @{$tables{$tableName}->[2]}, '?';
	}
    }

    foreach my $tableName (keys %tables) {
	my $columnNames = $tables{$tableName}->[0];
	my $columnValues = $tables{$tableName}->[1];
	my $questions = $tables{$tableName}->[2];

	my @updates;
	foreach my $name (@$columnNames) {
	    push @updates, "$name = ?";
	}

	my ($dbh,$sth,$sql,$rs);
	
	$sql = "update $tableName set " . join(',',@updates) . " where $idFieldName = $self->{id}";
	$dbh = $self->DBH();
	$sth = $dbh->prepare($sql);
	if ($sth->execute(@$columnValues) == 0) {
	    # row didn't exist already, let's insert it
	    $sql = "insert into $tableName (" .
		join(',',@$columnNames) . ") values (" . join(',',@$questions) . ")";
	    $sth = $dbh->prepare($sql);
	    return $sth->execute(@$columnValues);
	}
	return 1;
    }
}


# readObject
# ----------
# Populates the fields of the object from the database.

sub readObject {
    my $self = shift;
    my $fields = $self->{_fields};

    if (!defined $fields || !exists $fields->{id}) {
	return 0;
    }

    my %tables;
    my $idFieldName = $fields->{id}->[1];

    foreach my $fieldName (keys %$fields) {
	if ($fieldName ne 'id') {
	    my $fieldDef = $fields->{$fieldName};
	    my ($tableName, $columnName) = @$fieldDef;

	    push @{$tables{$tableName}->[0]}, $columnName;
	    push @{$tables{$tableName}->[1]}, $fieldName;
	}
    }

    # We store the results into a temporary hash, so that if any one
    # select fails, the object is left in its original state.
    my %tempData;
    foreach my $tableName (keys %tables) {
	my $columnNames = $tables{$tableName}->[0];
	my $fieldNames = $tables{$tableName}->[1];
	my ($dbh,$sth,$sql,$rs);

	$sql = "select " . join(',',@$columnNames) . " from $tableName where $idFieldName = $self->{id}";
	#print STDERR "$sql\n";
	$dbh = $self->DBH();
	$sth = $dbh->prepare($sql);
	if ($sth->execute()) {
	    $rs = $sth->fetchrow_arrayref();
	    foreach my $i (0..$#$columnNames) {
		my $name = $fieldNames->[$i];
		my $value = $rs->[$i];
		$tempData{$name} = $value;
	    }
	} else {
	    return 0;
	}
    }
    foreach my $key (keys %tempData) {
	$self->{$key} = $tempData{$key};
    }
    return 1;
}

1;
