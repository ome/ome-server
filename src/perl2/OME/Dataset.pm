package OME::Dataset;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    project_id => 'project',
    owner_id   => 'owner',
    group_id   => 'group'
    });

__PACKAGE__->table('datasets');
__PACKAGE__->sequence('dataset_seq');
__PACKAGE__->columns(Primary => qw(dataset_id));
__PACKAGE__->columns(Essential => qw(name description locked));
__PACKAGE__->has_many('images',OME::Image => qw(dataset_id));
__PACKAGE__->hasa(OME::Project => qw(project_id));
__PACKAGE__->hasa(OME::Experimenter => qw(owner_id));
__PACKAGE__->hasa(OME::Group => qw(group_id));


1;

