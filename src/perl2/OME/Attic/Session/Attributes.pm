
package OME::Session::Attributes;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

use fields qw(_attributes);
__PACKAGE__->AccessorNames({
    project_id     => 'project'
});

__PACKAGE__->table('ome_sessions');
__PACKAGE__->sequence('session_seq');
__PACKAGE__->columns(Primary => qw(session_id));
__PACKAGE__->columns(Essential => qw(session_key module_execution));
__PACKAGE__->columns(Others => qw(host image_view feature_view display_settings last_access started experimenter_id project_id));
#__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));
__PACKAGE__->hasa('OME::Project' => qw(project_id));

1;


