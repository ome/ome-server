# OME::Factory
# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
#

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
                  OME::SessionManager->DBPassword());



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


# findObject
# ----------

sub findObject {
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
