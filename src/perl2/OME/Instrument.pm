package OME::Instrument;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->table('instruments');
__PACKAGE__->sequence('instrument_seq');
__PACKAGE__->columns(Primary => qw(instrument_id));
__PACKAGE__->columns(Essential => qw(name description));


1;
