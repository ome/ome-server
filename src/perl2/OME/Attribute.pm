package OME::Attribute;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use OME::DBObject;


# Attributes are handled differently than other database-persistent
# objects.  The attribute's data table is dependent on the type of the
# particular attribute, so a dynamically-defined subclass of DBObject
# is used to access the database-persistent portion of the attribute.
# In order for this to work, the data type of the attribute must be
# known in advance.


# new(datatype)
# -------------
# There are two ways to generate Attribute objects, similar to the two
# ways to generate DBObjects:
#   1) loading an existing attribute from the database (requires a
#      datatype and integer ID)
#   2) creating a new attribute (requires just the datatype)
# I have defined Attribute to following the same method-calling
# conventions as DBObject.  Creating a new Attribute does not load an
# existing object or create a new one; rather, calls to ID/loadObject
# or createObject are necessary to fully instantiate an Attribute.

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # the datatype of this attribute is given as input
    my $datatype = shift;

    # construct the list of fields for the memento object
    # TODO: add support to DBObject for the "others" field
    my $table = $datatype->Field("tableName");
    my $mementoFields = {
	id     => [$table,'ATTRIBUTE_ID',
		   {sequence => 'ATTRIBUTE_SEQ'}]
	#others => [$table,'*']
    };

    # create the memento object
    # NOTE:  this does not load anything from the database
    my $memento = OME::Attribute::Memento->new($mementoFields);

    my $self = {
	datatype => $datatype,
	memento  => $memento
    };
}


# ID([value])
# -----------
# Gets/sets the value of the attribute's (ie, the memento's) ID.

sub ID {
    my $self = shift;
    if (@_) {
	return $self->{memento}->ID(shift);
    } else {
	return $self->{memento}->ID();
    }
}


# Field([value])
# --------------
# Gets/sets the value of one of the attribute's (ie, the memento's)
# fields.

sub Field {
    my $self = shift;
    my $field = shift;
    if (@_) {
	return $self->{memento}->Field($field,shift);
    } else {
	return $self->{memento}->Field($field);
    }
}


# DataType()
# ----------

sub DataType() { my $self = shift; return $self->{datatype}; }


# loadObject()
# ------------

sub loadObject {
    my $self = shift;
    $self->{memento}->readObject();
}


# createObject()
# --------------

sub createObject {
    my $self = shift;
    $self->{memento}->createObject();
}


# writeObject()
# --------------

sub writeObject {
    my $self = shift;
    $self->{memento}->writeObject();
}


# createObject()
# --------------

sub createObject {
    my $self = shift;
    $self->{memento}->createObject();
}


package OME::Attribute::Memento;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    my $fields = shift;

    $self->{_fields} = $fields;

    return $self;
}
