# OME::SessionManager

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


package OME::SessionManager;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use Class::Data::Inheritable;

use base qw(Ima::DBI Class::Accessor Class::Data::Inheritable);

__PACKAGE__->mk_classdata('DataSource');
__PACKAGE__->mk_classdata('DBUser');
__PACKAGE__->mk_classdata('DBPassword');

__PACKAGE__->DataSource("dbi:Pg:dbname=ome");
__PACKAGE__->DBUser(undef);
__PACKAGE__->DBPassword(undef);

__PACKAGE__->set_db('Main',
                  OME::SessionManager->DataSource(),
                  OME::SessionManager->DBUser(),
                  OME::SessionManager->DBPassword(), 
                  { RaiseError => 1 });

require OME::Session;

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();
    
    return $self;
}

# createSession
# -------------

sub createSession {
    my $self = shift;
    my ($username,$password) = @_;

    my $session;
    $session = OME::Session->createWithPassword($self,$username,$password);

    return $session;
}


# Accessors
# ---------

sub DBH { my $self = shift; return $self->db_Main(); }


# failedAuthentication()
# ----------------------

sub failedAuthentication() {
}

1;
