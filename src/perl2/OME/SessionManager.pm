# OME::SessionManager

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


package OME::SessionManager;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use Class::Data::Inheritable;
use Apache::Session::File;

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
                  OME::SessionManager->DBPassword(), 
                  { RaiseError => 1 });
__PACKAGE__->set_sql('find_user',<<"SQL",'Main');
      select experimenter_id, password
        from experimenters
       where ome_name = ?
SQL


#use OME::Session;

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
    my ($username,$password,$key);
    ($username,$password) = @_ if scalar (@_) == 2;
    ($key) = @_ if scalar (@_) == 1;

    my $session;
    
    if (defined $username and defined $password) { 
        $session = $self->createWithPassword($username,$password);
    } elsif (defined $key) {
        $session = $self->createWithKey($key);
    }

    $self->storeApacheSession($session);
    return $session;
}


# createWithPassword
# ------------------

sub createWithPassword {
    my $self = shift;
    my ($username, $password) = @_;
print STDERR "createWithPassword: username=".$username."\n";
    my $session = $self->getOMESession ($username, $password);
    return undef unless $session;
    $session->{ApacheSession} = $self->newApacheSession ($username, $password);
    $session->{SessionKey} = $session->{ApacheSession}->{SessionKey};
print STDERR "createWithPassword: {SessionKey}=".$session->{SessionKey}."\n";
print STDERR "createWithPassword: SessionKey()=".$session->SessionKey()."\n";
print STDERR "createWithPassword: session{username}=".$session->{ApacheSession}->{username}."\n";
    return $session;
}


# createWithKey
# ------------------

sub createWithKey {
    my $self = shift;
    my $key = shift;

    my $apacheSession = $self->getApacheSession($key);
print STDERR "createWithKey: username=".$apacheSession->{username}."\n";
print STDERR "createWithKey: key=".$apacheSession->{SessionKey}."\n";
    my ($username, $password) = ($apacheSession->{username},$apacheSession->{password});
    my $session = $self->getOMESession ($username,$password);
    return undef unless $session;
    $session->{ApacheSession} = $apacheSession;
    $session->{SessionKey} = $apacheSession->{SessionKey};
print STDERR "createWithKey: {SessionKey}=".$session->{SessionKey}."\n";
print STDERR "createWithKey: SessionKey()=".$session->SessionKey()."\n";
    return $session;
}


#
# getOMESession
# ----------------

sub getOMESession {
    my $self = shift;
    my ($username,$password) = @_;

    return undef unless $username and $password;

    my $sth = $self->sql_find_user();
    return undef unless $sth->execute($username);

    my $results = $sth->fetch();
    my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass and defined $experimenterID;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    require OME::Session;
    require OME::Factory;
    my $session;
print STDERR "getOMESession: looking for session, experimenter_id=$experimenterID.\n";
    my @sessions = OME::Session->search ('experimenter_id' => $experimenterID);
    $session = $sessions[0] if defined $sessions[0];
print STDERR "getOMESession: found ".scalar(@sessions)." session(s).\n";

# FIXME:  This should probably be a remote host.
    my $host = `hostname`;
    chomp ($host);

    if (not defined $session) {
        $session = OME::Session->create ({
            experimenter_id => $experimenterID,
            started         => 'now',
            last_access     => 'now',
            host            => $host
        });
print STDERR "getOMESession: created new session.\n";
    }
    die ref($self)."->getOMESession:  Could not create session object\n" unless defined $session;

    $session->last_access('now');
    $session->host($host);
    
    $session->{Factory} = OME::Factory->new();
    $session->{Manager} = $self;
	OME->Session($session);

print STDERR "getOMESession: updating session.\n";
    $session->writeObject();
    $session->dbi_commit();
print STDERR "getOMESession: returning session.\n";
    return $session;
}




#
# newApacheSession
# ----------------

sub newApacheSession {
my $self = shift;
my ($userName,$password) = @_;
my $apacheSession = $self->getApacheSession();


    $apacheSession->{username} = $userName;
    $apacheSession->{password} = $password;
print STDERR "newApacheSession: username=".$apacheSession->{username}."\n";
print STDERR "newApacheSession: key=".$apacheSession->{SessionKey}."\n";

    return $apacheSession;
}


#
# getApacheSession
# ----------------

sub getApacheSession {
my $self = shift;
my $sessionKey = shift;
print STDERR "getApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined')."\n";
my %tiedApacheSession;
my $apacheSession;
my ($key,$value);

    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => '/var/tmp/OME/sessions',
            LockDirectory => '/var/tmp/OME/lock'
        };
    };
    return undef if $@;
    while ( ($key,$value) = each %tiedApacheSession ) {
        if ($key eq '_session_id') {
            $apacheSession->{SessionKey} = $value;
        } else {
            $apacheSession->{$key} = $value;
        }
    }
    untie %tiedApacheSession;
    
    $self->refreshApacheSession ($apacheSession);

print STDERR "getApacheSession: username=".$apacheSession->{username}."\n";
print STDERR "getApacheSession: key=".$apacheSession->{SessionKey}."\n";
    return $apacheSession;
}

#
# refreshApacheSession
# --------------------

sub refreshApacheSession {
my $self = shift;
my $apacheSession = shift;
# FIXME:  Need some code here to expire stale sessions, calling tied(%apacheSession)->delete;
    
}

#
# storeApacheSession
# ------------------

sub storeApacheSession {
my $self = shift;
my $session = shift;
return undef unless defined $session;
my $apacheSessionRef = $session->{ApacheSession};
my $sessionKey = $apacheSessionRef->{SessionKey};
my %apacheSessionTied;
print STDERR "storeApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined')."\n";
my ($key,$value);

    tie %apacheSessionTied, 'Apache::Session::File', $sessionKey, {
    Directory     => '/var/tmp/OME/sessions',
    LockDirectory => '/var/tmp/OME/lock'
    };
    
    while ( ($key,$value) = each %$apacheSessionRef ) {
        $apacheSessionTied{$key} = $value unless $key eq '_session_id';
    }
    untie %apacheSessionTied;

    return $apacheSessionRef;
}


# Accessors
# ---------

sub DBH { my $self = shift; return $self->db_Main(); }


# failedAuthentication()
# ----------------------

sub failedAuthentication() {
}

1;
