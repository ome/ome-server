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

# Ilya's add
# JM 14-03
package OME::SessionManager;
our $VERSION = '1.00';

use strict;

use Ima::DBI;
use Class::Accessor;
use Class::Data::Inheritable;
use Apache::Session::File;
use OME::DBConnection;
use Term::ReadKey;

use base qw(Ima::DBI Class::Accessor Class::Data::Inheritable);

__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
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


# TTYlogin
# --------
sub TTYlogin {
    my $homeDir = $ENV{"HOME"} || ".";
    my $loginFile = "$homeDir/.omelogin";

    my $manager = OME::SessionManager->new();
    my $session;

    my $loginFound = open LOGINFILE, "< $loginFile";

    if ($loginFound) {
        my $key = <LOGINFILE>;
        chomp($key);
        $session = $manager->createSession($key);
        close LOGINFILE;

        if (!defined $session) {
            print "Cannot login via previous session.\n";
        }
    }

    if (!defined $session) {
	print "Please login to OME:\n";

	print "Username? ";
	ReadMode(1);
	my $username = ReadLine(0);
	chomp($username);

	print "Password? ";
	ReadMode(2);
	my $password = ReadLine(0);
	chomp($password);
	print "\n";
	ReadMode(1);

	$session = $manager->createSession($username,$password);

	if (!defined $session) {
            print "That username/password does not seem to be valid.\nBye.\n\n";
            exit -1;
        } else {
            my $created = open LOGINFILE, "> $loginFile";
            if ($created) {
                print LOGINFILE $session->{SessionKey}, "\n";
                close LOGINFILE;
            }
	}

	print "Great, you're in.\n\n";
    }

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
    my @row		= ();
    my $rows	= 0;
    my @tab		= ();
    my $Err			= undef; 

    return undef unless $username and $password;

    my $sth = $self->sql_find_user();
    # Added JM 13-03-03
    $sth->execute($username) or $Err=$sth->errstr; 
 
    #while ( @row = $sth->fetchrow_array ) {
     while ( @row = $sth->fetch ) { # IMA/DBI call
       push (@tab, @row); 
       $rows++;	       
    }

    if ($Err){
	 $self->disconnect;
	 return undef;
	 
    }
    my ($experimenterID,$dbpass) = @tab;





    #return undef unless $sth->execute($username);

    #my $results = $sth->fetch();
   # my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass and defined $experimenterID;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    require OME::Session;
    require OME::Factory;
    require OME::DBObject;
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
    
    OME::DBObject->Session($session);
    $session->{Factory} = OME::Factory->new();
    $session->{Manager} = $self;

print STDERR "getOMESession: updating session.\n";
    $session->writeObject();
    $session->dbi_commit();
print STDERR "getOMESession: returning session.\n";
    return $session;
}


#
# logout
# ------
sub logout () {
my $self = shift;
my $session = shift;
return undef unless defined $session;
print STDERR ref($self)."->logout: logging out.\n";
	$self->deleteApacheSession ($session->{ApacheSession});
	delete $session->{ApacheSession};
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
# deleteApacheSession
# --------------------

sub deleteApacheSession {
my $self = shift;
my $apacheSession = shift;
my $sessionKey = $apacheSession->{SessionKey};
my %tiedApacheSession;
print STDERR ref($self)."->deleteApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined')."\n";

    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => '/var/tmp/OME/sessions',
            LockDirectory => '/var/tmp/OME/lock'
        };
    };
    return undef if $@;
    
    tied(%tiedApacheSession)->delete();

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
my %tiedApacheSession;
print STDERR "storeApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined')."\n";
my ($key,$value);

    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => '/var/tmp/OME/sessions',
            LockDirectory => '/var/tmp/OME/lock'
        };
    };
    return undef if $@;
    
    while ( ($key,$value) = each %$apacheSessionRef ) {
        $tiedApacheSession{$key} = $value unless $key eq '_session_id';
    }
    untie %tiedApacheSession;

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
