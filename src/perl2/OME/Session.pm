# OME::Session

package OME::Session;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use OME::Factory;
use OME::SessionManager;

use base qw(Ima::DBI Class::Accessor);

use fields qw(Manager Username UserID User Factory);
__PACKAGE__->mk_ro_accessors(qw(Manager Username UserID User Factory));
__PACKAGE__->set_db('Main',
                  OME::SessionManager->DataSource(),
                  OME::SessionManager->DBUser(),
                  OME::SessionManager->DBPassword());

__PACKAGE__->set_sql('find_user',<<"SQL",'Main');
      select experimenter_id, password
        from experimenters
       where ome_name = ?
SQL



# createWithPassword
# ------------------

sub createWithPassword {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($manager,$username,$password) = @_;

    my $self = $class->SUPER::new();

    my $sth = $self->sql_find_user();
    return undef unless $sth->execute($username);

    my $results = $sth->fetch();
    my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    $self->{Manager} = $manager;
    $self->{Username} = $username;
    $self->{UserID} = $experimenterID;
    $self->{User} = undef;
    $self->{Factory} = OME::Factory->new($self);

    return $self;
}


# Accessors
# ---------

sub DBH { my $self = shift; return $self->db_Main(); }

sub User {
    my $self = shift;
    my $value = $self->{User};
    
    if (!defined $value) {
        $value = $self->Factory()->loadObject("OME::Experimenter",$self->UserID());
        $self->{User} = $value;
    }
    
    return $value;
}


1;

