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
	description => ['DATATYPES','DESCRIPTION']
    };

    return $self;
}
