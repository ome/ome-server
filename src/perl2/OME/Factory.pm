# OME::Factory
# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
#

package OME::Factory;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';


# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $session = shift;

    my $self = {
	session => $session,
	cache   => {}
	};

    bless $self, $class;
}


# Accessors
# ---------

sub Session { my $self = shift; return $self->{session}; }
sub DBH { my $self = shift; return $self->{session}->DBH(); }


# loadObject
# ----------

sub loadObject {
    my ($self, $class, $id) = @_;

    my $classCache = $self->{cache}->{$class};

    return $classCache->{$id} if (exists $classCache->{$id});

    eval "require $class";
    my $object = $class->new($self);
    $object->ID($id);

    if ($object->readObject()) {
	$classCache->{$id} = $object;
	return $object;
    }
    return undef;
}


# newObject
# ---------

sub newObject {
    my ($self, $class) = @_;

    eval "require $class";
    my $object = $class->new($self);
    return $object if $object->createObject();
    return undef;
}

1;
