package OME::Instrument;

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
	id          => ['INSTRUMENTS','INSTRUMENT_ID','SEQUENCE','INSTRUMENT_SEQ'],
	name        => ['INSTRUMENTS','NAME'],
	description => ['INSTRUMENTS','DESCRIPTION']
    };

    return $self;
}

1;
