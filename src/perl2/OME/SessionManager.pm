# OME::SessionManager

package OME::SessionManager;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use Class::Data::Inheritable;
use OME::Session;

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
                  OME::SessionManager->DBPassword());

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
