package OME::Dataset;

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
	id          => ['DATASETS','DATASET_ID',
			{sequence => 'DATASET_SEQ'}],
	name        => ['DATASETS','NAME'],
	description => ['DATASETS','DESCRIPTION'],
	locked      => ['DATASETS','LOCKED'],
	images      => ['DATASET_IMAGE_MAP','IMAGE_ID',
			{map       => 'DATASET_ID',
			 reference => 'OME::Image'}]
    };

    return $self;
}

1;

