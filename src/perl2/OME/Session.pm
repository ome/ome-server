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

    my $sql = "
      select experimenter_id, password
        from experimenters
       where ome_name = ?";
    my ($experimenterID,$dbpass) = $manager->DBH()->selectrow_array($sql,
								    {},
								    $username);
    return undef unless defined $dbpass;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    my $self = {
	manager  => $manager,
	username => $username,
	userID   => $experimenterID,
	user     => undef
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

sub User {
    my $self = shift;
    if (!defined $self->{user}) {
	$self->{user} = $self->{factory}->loadObject("OME::Experimenter",$self->{userID});
    }
    return $self->{user};
}


1;

