package OME::LookupTable;

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
	id          => ['LOOKUP_TABLES','LOOKUP_TABLE_ID',
			{sequence => 'LOOKUP_TABLE_SEQ'}],
	name        => ['LOOKUP_TABLES','NAME'],
	description => ['LOOKUP_TABLES','DESCRIPTION'],
	entries     => ['LOOKUP_TABLE_ENTRIES','LOOKUP_TABLE_ENTRY_ID',
			{map       => 'LOOKUP_TABLE_ID',
			 reference => 'OME::LookupTable::Entry',
			 order     => 'LABEL'}]
    };

    return $self;
}


package OME::LookupTable::Entry;

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
	id    => ['LOOKUP_TABLE_ENTRIES','LOOKUP_TABLE_ENTRY_ID',
		  {sequence => 'LOOKUP_TABLE_ENTRY_SEQ'}],
	table => ['LOOKUP_TABLE_ENTRIES','LOOKUP_TABLE_ID',
		  {reference => 'OME::LookupTable'}],
	value => ['LOOKUP_TABLE_ENTRIES','VALUE'],
	label => ['LOOKUP_TABLE_ENTRIES','LABEL']
    };

    return $self;
}


1;

