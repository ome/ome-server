package OME::DataType;

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

    $self->{_fields} = {
	id          => ['DATATYPES','DATATYPE_ID',
			{sequence => 'DATATYPE_SEQ'}],
	tableName   => ['DATATYPES','TABLE_NAME'],
	description => ['DATATYPES','DESCRIPTION'],
        columns     => ['DATATYPE_COLUMNS','DATATYPE_COLUMN_ID',
                        {map       => 'DATATYPE_ID',
                         reference => 'OME::DataType::Column'}]
    };

    return $self;
}


package OME::DataType::Column;

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

    $self->{_fields} = {
        id            => ['DATATYPE_COLUMNS','DATATYPE_COLUMN_ID',
                          {sequence => 'DATATYPE_COLUMN_SEQ'}],
        dataType      => ['DATATYPE_COLUMNS','DATATYPE_ID',
                          {reference => 'OME::DataType'}],
        columnName    => ['DATATYPE_COLUMNS','COLUMN_NAME'],
        referenceName => ['DATATYPE_COLUMNS','REFERENCE_NAME']
    };

    return $self;
}


