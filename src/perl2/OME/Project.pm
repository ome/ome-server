package OME::Project;

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
	id          => ['PROJECTS','PROJECT_ID',{sequence => 'PROJECT_SEQ'}],
	name        => ['PROJECTS','NAME'],
	owner       => ['PROJECTS','OWNER_ID',{reference => 'OME::Experimenter'}],
	description => ['PROJECTS','DESCRIPTION'],
	datasets    => ['PROJECT_DATASET_MAP','DATASET_ID',{map       => 'PROJECT_ID',
							    reference => 'OME::Dataset'}],
    };

    return $self;
}

1;

