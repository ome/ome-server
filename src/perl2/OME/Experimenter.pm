package OME::Experimenter;

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
	id        => ['EXPERIMENTERS','EXPERIMENTER_ID','SEQUENCE','EXPERIMENTER_SEQ'],
	omeName   => ['EXPERIMENTERS','OME_NAME'],
	firstName => ['EXPERIMENTERS','FIRSTNAME'],
	lastName  => ['EXPERIMENTERS','LASTNAME'],
	email     => ['EXPERIMENTERS','EMAIL']
    };

    return $self;
}

1;
