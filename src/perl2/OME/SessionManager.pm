# OME::SessionManager

package OME::SessionManager;
use strict;
use vars qw($VERSION);
use OME::Session;
$VERSION = '1.00';


my $datasource = "dbi:Pg:dbname=ome";
my $dbuser     = "postgres";
my $dbpass     = "lemondave0";

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{dbh} = DBI->connect($datasource,$dbuser,$dbpass);
    $self->{datasource} = $datasource;
    $self->{dbuser} = $dbuser;
    $self->{dbpass} = $dbpass;
    bless $self, $class;
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

sub DBH { my $self = shift; return $self->{dbh}; }


# failedAuthentication()
# ----------------------

sub failedAuthentication() {
}

1;
