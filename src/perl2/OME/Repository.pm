package OME::Repository;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->table('repositories');
__PACKAGE__->sequence('repository_seq');
__PACKAGE__->columns(Primary => qw(repository_id));
__PACKAGE__->columns(Essential => qw(path));


1;
