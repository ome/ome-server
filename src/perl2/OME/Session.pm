# OME::Session

package OME::Session;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';
use OME::Factory;


# createWithPassword
# ------------------

sub createWithPassword {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($manager,$username,$password) = @_;

    my $sql = "select password from experimenters where ome_name = ?";
    my $dbpass = $manager->DBH()->selectrow_array($sql,{},$username);
    if (crypt($password,$dbpass) ne $dbpass) {
	return undef;
    }

    my $self = {
	manager  => $manager,
	username => $username
    };
    bless $self,$class;
    
    $self->{factory} = OME::Factory->new($self);
    return $self;
}


# Accessors
# ---------

sub Manager { my $self = shift; return $self->{manager}; }
sub Username { my $self = shift; return $self->{username}; }
sub Factory { my $self = shift; return $self->{factory}; }
sub DBH { my $self = shift; return $self->{manager}->DBH(); }


1;

