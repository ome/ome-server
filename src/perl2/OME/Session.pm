# OME::Session

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Session;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use OME::Factory;
require OME::SessionManager;

use base qw(Ima::DBI Class::Accessor);

use fields qw(Manager Username UserID User Factory);
__PACKAGE__->mk_ro_accessors(qw(Manager Username UserID User Factory));
__PACKAGE__->set_db('Main',
                  OME::SessionManager->DataSource(),
                  OME::SessionManager->DBUser(),
                  OME::SessionManager->DBPassword(), 
                  { RaiseError => 1 });

__PACKAGE__->set_sql('find_user',<<"SQL",'Main');
      select experimenter_id, password
        from experimenters
       where ome_name = ?
SQL



# createWithPassword
# ------------------

sub createWithPassword {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($manager,$username,$password) = @_;

    my $self = $class->SUPER::new();

    my $sth = $self->sql_find_user();
    return undef unless $sth->execute($username);

    my $results = $sth->fetch();
    my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    $self->{Manager} = $manager;
    $self->{Username} = $username;
    $self->{UserID} = $experimenterID;
    $self->{User} = undef;
    $self->{Factory} = OME::Factory->new($self);

    return $self;
}


# Accessors
# ---------

# this is a stub. It needs to be hooked up to db
# it should return the dataset id of this session
sub Dataset {
	return 1;
}

# this is a stub. It needs to be hooked up to db
# it should return the project_id of this session
sub Project {
	return 1;
}

sub DBH { my $self = shift; return $self->db_Main(); }

sub User {
    my $self = shift;
    my $value = $self->{User};
    
    if (!defined $value) {
        $value = $self->Factory()->loadObject("OME::Experimenter",$self->UserID());
        $self->{User} = $value;
    }
    
    return $value;
}

# take this out. it's contents should be moved to OME::Session in the style of OME::Image
#package OME::Session::OME_Sessions;

#use strict;
#our $VERSION = '1.0';

#use OME::DBObject;
#use base qw(OME::DBObject);

#__PACKAGE__->AccessorNames({
#    session_key => 'key',
#    experimenter_id     => 'experimenter'
#    });

#__PACKAGE__->table('ome_sessions');
#__PACKAGE__->columns(Primary => qw(session_id));
#__PACKAGE__->columns(Essential => qw(session_key experimenter_id host project_id
#				     dataset_id image_view feature_view analysis display_settings 
#				     last_access started));




1;

