package OME::Project;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    owner_id => 'owner',
    group_id => 'group'
    });

__PACKAGE__->table('projects');
__PACKAGE__->sequence('project_seq');
__PACKAGE__->columns(Primary => qw(project_id));
__PACKAGE__->columns(Essential => qw(name description));
__PACKAGE__->has_many('datasets',OME::Dataset => qw(project_id));
__PACKAGE__->hasa(OME::Experimenter => qw(owner_id));
__PACKAGE__->hasa(OME::Group => qw(group_id));


1;

