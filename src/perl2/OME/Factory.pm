# OME::Factory

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


package OME::Factory;
our $VERSION = '1.00';

use strict;
use Ima::DBI;
use Class::Accessor;
use OME::SessionManager;

use base qw(Ima::DBI Class::Accessor);

use fields qw(Session Debug _cache);
__PACKAGE__->mk_ro_accessors(qw(Session));
__PACKAGE__->mk_accessors(qw(Debug));
__PACKAGE__->set_db('Main',
                  OME::SessionManager->DataSource(),
                  OME::SessionManager->DBUser(),
                  OME::SessionManager->DBPassword(), 
                  { RaiseError => 1 });



# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $session = shift;

    my $self = $class->SUPER::new();
    $self->{Session} = $session;
    $self->{_cache} = {};
    $self->{Debug} = 1;

    return $self;
}


# Accessors
# ---------

sub DBH { my $self = shift; return $self->db_Main(); }


# loadObject
# ----------

sub loadObject {
    my ($self, $class, $id) = @_;

    return undef unless defined $id;

    my $classCache = $self->{_cache}->{$class};
    if (exists $classCache->{$id}) {
	print STDERR "loading cache $class $id\n" if $self->{debug};
	return $classCache->{$id};
    } else {
	print STDERR "loading  new  $class $id\n" if $self->{debug};
    }

    eval "require $class";
    my $object = $class->retrieve($id) or return undef;

    $self->{_cache}->{$class}->{$id} = $object;
    return $object;
}


# findObjects
# -----------

sub findObjects {
    my ($self, $class, $key, $value) = @_;

    return undef unless (defined $key) && (defined $value);

    eval "require $class";
    return $class->search($key,$value);
}


# newObject
# ---------

sub newObject {
    my ($self, $class, $data) = @_;

    eval "require $class";
    my $object = $class->create($data) or return undef;
    return $object;
}

1;
