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
use OME::DBConnection;

use base qw(Ima::DBI Class::Accessor Class::Data::Inheritable);

use fields qw(Debug _cache);
__PACKAGE__->mk_accessors(qw(Debug));
__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
                  { RaiseError => 1 });



# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();
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

sub loadAttribute {
    my ($self, $attribute_type_name, $id) = @_;

    my $type = $self->findObject("OME::AttributeType",
                                 name => $attribute_type_name);
    die "Cannot find attribute type $attribute_type_name"
        unless defined $type;
    my $pkg = $type->requireAttributeTypePackage();

    return $pkg->load($id);
}


# findObject
# ----------

sub findObject {
    my ($self, $class, @criteria) = @_;
    my $objects = $self->findObjects($class,@criteria);
    return $objects? $objects->next(): undef;
}


# findObjects
# -----------

sub findObjects {
    my ($self, $class, @criteria) = @_;

    return undef unless (scalar(@criteria) > 0) && ((scalar(@criteria) % 2) == 0);

    eval "require $class";
    return $class->search(@criteria);
}


# newObject
# ---------

sub newObject {
    my ($self, $class, $data) = @_;

    eval "require $class";
    my $object = $class->create($data) or return undef;
    return $object;
}

sub newAttribute {
    my ($self, $attribute_type_name, $target, $rows) = @_;

    my $type = $self->findObject("OME::AttributeType",
                                 name => $attribute_type_name);
    die "Cannot find attribute type $attribute_type_name"
        unless defined $type;
    my $pkg = $type->requireAttributeTypePackage();

    return $pkg->new($target, $rows);
}

1;
