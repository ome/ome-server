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

    return undef unless defined $id;

    my $classCache = $self->{cache}->{$class};
    if (exists $classCache->{$id}) {
	print STDERR "loading cache $class $id\n";
	return $classCache->{$id};
    } else {
	print STDERR "loading  new  $class $id\n";
    }

    eval "require $class";
    my $object = $class->new($self);
    $object->ID($id);

    if ($object->readObject()) {
	$self->{cache}->{$class}->{$id} = $object;
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
