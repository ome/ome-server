package OME::Group;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('groups');
__PACKAGE__->sequence('group_seq');
__PACKAGE__->columns(Primary => qw(group_id));
__PACKAGE__->columns(Essential => qw(name));
__PACKAGE__->hasa(OME::Experimenter => qw(leader));
__PACKAGE__->hasa(OME::Experimenter => qw(contact));


1;
