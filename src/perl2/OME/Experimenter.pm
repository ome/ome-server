package OME::Experimenter;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('experimenters');
__PACKAGE__->sequence('experimenter_seq');
__PACKAGE__->columns(Primary => qw(experimenter_id));
__PACKAGE__->columns(Essential => qw(ome_name firstname lastname email));


1;
