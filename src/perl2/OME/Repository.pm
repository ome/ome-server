package OME::Repository;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id   => ['REPOSITORIES','REPOSITORY_ID','SEQUENCE','REPOSITORY_SEQ'],
	path => ['REPOSITORIES','PATH']
    };

    return $self;
}

1;
