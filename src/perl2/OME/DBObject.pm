# This module is the superclass of any Perl object stored in the
# database.

package OME::DBObject;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $factory = shift;
    
    my $self = {};

    $self->{_factory} = $factory;
    $self->{_fields} = undef;
    $self->{_fieldValues} = {};
    $self->{_dirty} = 0;
    bless $self,$class;
}


# Accessors
# ---------

sub ID {
    my $self = shift;
    return $self->{_fieldValues}->{id} = shift if @_;
    return $self->{_fieldValues}->{id};
}

sub DBH { my $self = shift; return $self->{_factory}->DBH(); }


# Field accessor
# --------------

sub Field {
    my $self = shift;
    my $field = shift;
    my $fieldDef = $self->{_fields}->{$field};
    my $options = $fieldDef->[2];

    if (exists $options->{reference}) {
	# This is a foreign key field, so we should return an object
	# of an appropriate type (rather than the foreign key ID).
	# This field is still stored in the field value hash as the
	# foreign key number, preventing reference fields from being
	# a special case in the database access methods.

	my $refClass = $options->{reference};
	my $oldValue = $self->{_fieldValues}->{$field};
	my $oldObject = [];

	if (ref($oldValue) eq 'ARRAY') {
	    # We want this to silently work on an array of values,
	    # which will turn up in the case of maps.
	    foreach my $value (@$oldValue) {
		push @$oldObject, $self->{_factory}->loadObject($refClass,$value);
	    }
	
	    if (@_) {
		my $newObject = shift;
		die "Non-array sent to Field method" unless (ref($newObject) eq 'ARRAY');
		my $newValue = [];
		foreach my $object (@$newObject) {
		    push @$newValue, $object->Field("id");
		}
		$self->{_fieldValues}->{$field} = $newValue;
	    }
	    return $oldObject;
	} else {
	    $oldObject = $self->{_factory}->loadObject($refClass,$oldValue);
	    if (@_) {
		# We expect an object of the appropriate type as input.
		# Place it's ID into the foreign key field here.
		my $value = shift;
		die "Incorrect class sent to Field method: $refClass" unless ($value->isa($refClass));
		$self->{_fieldValues}->{$field} = $value->Field("id");
	    }
	    return $oldObject;
	}
    }
    
    if (@_) {
	$self->{_dirty} = 1;
	return $self->{_fieldValues}->{$field} = shift;
    } else {
	return $self->{_fieldValues}->{$field};
    }
}


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

    if (!defined $fields || !exists $fields->{id} || (!exists $fields->{id}->[2]->{sequence})) {
	return 0;
    }

    my $idSequence = $fields->{id}->[2]->{sequence};

    my ($dbh,$sth,$sql,$rs);
    $dbh = $self->DBH();
    $sql = "select nextval(?)";
    $rs = $dbh->selectrow_array($sql,{},$idSequence);
    if (defined $rs) {
	$self->{_fieldValues}->{id} = $rs;
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
    my $values = $self->{_fieldValues};

    if (!defined $fields || !exists $fields->{id}) {
	return 0;
    }

    my %tables;
    my $idFieldName = $fields->{id}->[1];

    foreach my $fieldName (keys %$fields) {
	if ($fieldName ne 'id') {
	    my $fieldDef = $fields->{$fieldName};
	    my ($tableName, $columnName, $options) = @$fieldDef;

	    push @{$tables{$tableName}->[0]}, $columnName;
	    push @{$tables{$tableName}->[1]}, $values->{$fieldName};
	    push @{$tables{$tableName}->[2]}, '?';
	    push @{$tables{$tableName}->[3]}, $options;
	}
    }

    my ($dbh,$sth,$sql,$rs);
    $dbh = $self->DBH();
    # The DBH should be set to manual transaction control
    # within the SessionManager constructor.
    # $dbh->{AutoCommit} = 0;
    
    foreach my $tableName (keys %tables) {
	my $columnNames = $tables{$tableName}->[0];
	my $columnValues = $tables{$tableName}->[1];
	my $columnQuestions = $tables{$tableName}->[2];
	my $options = $tables{$tableName}->[3];
	my ($mapName, $mapValues);
	my (@updates, @values, @names, @questions);
	my $mapped = 0;

	my $i = 0;
	my $matchField = $idFieldName;
	foreach my $name (@$columnNames) {
	    if (exists $options->[$i]->{map}) {
		$mapName = $name;
		$mapValues = $columnValues->[$i];
		$matchField = $options->[$i]->{map};
		$mapped = 1;
	    } elsif (exists $options->[$i]->{link}) {
		$matchField = $options->[$i]->{link};
	    } else {
		push @updates, "$name = ?";
		push @values, @$columnValues[$i];
		push @names, @$columnNames[$i];
		push @questions, @$columnQuestions[$i];
	    }
	    $i++;
	}

	if ($mapped) {
	    $sql = "delete from $tableName where $matchField = $self->{_fieldValues}->{id}";
	    $sth = $dbh->prepare($sql);
	    if (!$sth->execute()) {
		$dbh->rollback;
		return 0;
	    }
	    push @names, $mapName, $matchField;
	    push @questions, "?", "?";
	    $sql = "insert into $tableName (" .
		join(',',@names) . ") values (" . join(',',@questions) . ")";
	    $sth = $dbh->prepare($sql);
	    foreach my $value (@$mapValues) {
		my @v = @values;
		push @v, $value;
		push @v, $self->{_fieldValues}->{id};
		if (!$sth->execute(@v)) {
		    $dbh->rollback;
		    return 0;
		}
	    }
	} else {
	    $sql = "update $tableName set " . join(',',@updates) . " where $matchField = $self->{_fieldValues}->{id}";
	    $sth = $dbh->prepare($sql);
	    if ($sth->execute(@values) == 0) {
		# row didn't exist already, let's insert it
		$sql = "insert into $tableName (" .
		    join(',',@names) . ") values (" . join(',',@questions) . ")";
		$sth = $dbh->prepare($sql);
		if (!$sth->execute(@values)) {
		    $dbh->rollback;
		    return 0;
		}
	    }
	}
    }

    $dbh->commit;
    $self->{_dirty} = 0;
    return 1;
}


# readObject
# ----------
# Populates the fields of the object from the database.

sub readObject {
    my $self = shift;
    my $fields = $self->{_fields};

    my $class = ref $self;

    if (!defined $fields || !exists $fields->{id}) {
	return 0;
    }

    my %tables;
    my $idFieldName = $fields->{id}->[1];

    foreach my $fieldName (keys %$fields) {
	if ($fieldName ne 'id') {
	    my $fieldDef = $fields->{$fieldName};
	    my ($tableName, $columnName, $options) = @$fieldDef;

	    push @{$tables{$tableName}->[0]}, $columnName;
	    push @{$tables{$tableName}->[1]}, $fieldName;
	    push @{$tables{$tableName}->[2]}, (exists $options->{map});
	    $tables{$tableName}->[3] = $options->{order} if exists $options->{order};
	}
    }

    # We store the results into a temporary hash, so that if any one
    # select fails, the object is left in its original state.
    my %tempData;
    foreach my $tableName (keys %tables) {
	my $columnNames = $tables{$tableName}->[0];
	my $fieldNames = $tables{$tableName}->[1];
	my $mappedList = $tables{$tableName}->[2];
	my $orderBy = $tables{$tableName}->[3];
	my ($dbh,$sth,$sql,$rs);

	$sql = "select " . join(',',@$columnNames) . " from $tableName ".
	    "where $idFieldName = $self->{_fieldValues}->{id}";
	$sql .= " order by $orderBy" if defined $orderBy;
	#print STDERR "$sql\n";
	$dbh = $self->DBH();
	$sth = $dbh->prepare($sql);
	if ($sth->execute()) {
	    while ($rs = $sth->fetchrow_arrayref()) {
		foreach my $i (0..$#$columnNames) {
		    my $name = $fieldNames->[$i];
		    my $value = $rs->[$i];
		    my $mapped = $mappedList->[$i];
		    if ($mapped) {
			push @{$tempData{$name}}, $value;
		    } else {
			$tempData{$name} = $value;
		    }
		}
	    }
	} else {
	    return 0;
	}
    }
    foreach my $key (keys %tempData) {
	$self->{_fieldValues}->{$key} = $tempData{$key};
    }
    $self->{_dirty} = 0;
    return 1;
}

1;
