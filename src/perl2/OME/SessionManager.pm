# OME::SessionManager

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
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
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


# Ilya's add
# JM 14-03
# JM 14-05 fix bug when log in with wrong username/password

package OME::SessionManager;
our $VERSION = 2.000_000;

use strict;

use Carp;
use Log::Agent;
use Class::Accessor;
use Class::Data::Inheritable;
use Apache::Session::File;
use OME::DBConnection;
use Term::ReadKey;
use POSIX;

use base qw(Class::Accessor Class::Data::Inheritable);

use constant FIND_USER_SQL => <<"SQL";
      select attribute_id, password
        from experimenters
       where ome_name = ?
SQL

# The lifetime of server-side session keys in seconds
our $APACHE_SESSION_LIFETIME = 1800;  # 30 minutes

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
     # 14-05
    if (defined $session){
     $self->storeApacheSession($session);
     $session->Session($session);
    }
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
    logdbg "debug", "createWithPassword: username=".$username;
    my $session = $self->getOMESession ($username, $password);
    return undef unless $session;
    $session->{ApacheSession} = $self->newApacheSession ($username, $password);
    $session->{SessionKey} = $session->{ApacheSession}->{SessionKey};
    logdbg "debug", "createWithPassword: {SessionKey}=".$session->{SessionKey};
    logdbg "debug", "createWithPassword: SessionKey()=".$session->SessionKey();
    logdbg "debug", "createWithPassword: session{username}=".$session->{ApacheSession}->{username};
    return $session;
}


# createWithKey
# ------------------

sub createWithKey {
    my $self = shift;
    my $key = shift;

    my $apacheSession = $self->getApacheSession($key);
    logdbg "debug", "createWithKey: username=".$apacheSession->{username};
    logdbg "debug", "createWithKey: key=".$apacheSession->{SessionKey};
    my ($username, $password) = ($apacheSession->{username},$apacheSession->{password});
	
    my $session = $self->getOMESession ($username,$password);
    return undef unless $session;

    $session->{ApacheSession} = $apacheSession;
    $session->{SessionKey} = $apacheSession->{SessionKey};
    logdbg "debug", "createWithKey: {SessionKey}=".$session->{SessionKey};
    logdbg "debug", "createWithKey: SessionKey()=".$session->SessionKey();
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

    my $bootstrap_factory = OME::Factory->new(undef);

    my $dbh = $bootstrap_factory->obtainDBH();
    my ($experimenterID,$dbpass);
    eval {
        ($experimenterID,$dbpass) =
          $dbh->selectrow_array(FIND_USER_SQL,{},$username);
    };
    $bootstrap_factory->releaseDBH($dbh);

    return undef if $@;



    #return undef unless $sth->execute($username);

    #my $results = $sth->fetch();
   # my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass and defined $experimenterID;
    return undef if (crypt($password,$dbpass) ne $dbpass);

    logdbg "debug", "getOMESession: looking for session, experimenter_id=$experimenterID";
    my $session = $bootstrap_factory->
      findObject('OME::Session',experimenter_id => $experimenterID);
    logdbg "debug", "getOMESession: found ".(defined $session)." session(s)";

# FIXME:  This should probably be a remote host.
    my $host = `hostname`;
    chomp ($host);

    if (!defined $session) {
        $session = $bootstrap_factory->
          newObject('OME::Session',
                    {
                     experimenter_id => $experimenterID,
                     started         => 'now',
                     last_access     => 'now',
                     host            => $host
                    });
        logdbg "debug", "getOMESession: created new session";
    } else {
        $session->last_access('now');
        $session->host($host);
    }

    $session->{__session} = $session;
    logdie ref($self)."->getOMESession:  Could not create session object"
      unless defined $session;

    $session->{Factory} = OME::Factory->new($session);
    $session->{Manager} = $self;

    logdbg "debug", "getOMESession: updating session";
    $session->storeObject();
    $session->commitTransaction();

    logdbg "debug", "getOMESession: returning session";
    return $session;
}


#
# logout
# ------
sub logout {
    my $self = shift;
    my $session = shift;
    return undef unless defined $session;
    logdbg "debug", ref($self)."->logout: logging out";
    $self->deleteApacheSession ($session->{ApacheSession});
    delete $session->{ApacheSession};
    $session->closeSession();
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
    logdbg "debug", "newApacheSession: username=".$apacheSession->{username};
    logdbg "debug", "newApacheSession: key=".$apacheSession->{SessionKey};

    return $apacheSession;
}


#
# getApacheSession
# ----------------

sub getApacheSession {
    my $self = shift;
    my $sessionKey = shift;
    logdbg "debug", "getApacheSession: sessionKey=".
        (defined $sessionKey ? $sessionKey : 'undefined');
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
    
    #
    # Check for a stale session key.  If its stale, delete it and return undef.
    if (defined $sessionKey) {
    	my $sessionAge = POSIX::difftime(time(),$tiedApacheSession{timestamp});
		logdbg "debug", "getApacheSession: timestamp = ".$tiedApacheSession{timestamp}.".  Session is ".($sessionAge / 60)." minutes old";
		if ($sessionAge > $APACHE_SESSION_LIFETIME) {
			logdbg "debug", "Deleting session";
			tied (%tiedApacheSession)->delete();
			print STDERR "Session is ".($sessionAge/60)." minutes long - expired.\n";
			return undef;
		}
    }
    
    $tiedApacheSession{timestamp} = time();

    while ( ($key,$value) = each %tiedApacheSession ) {
        if ($key eq '_session_id') {
            $apacheSession->{SessionKey} = $value;
        } else {
            $apacheSession->{$key} = $value;
        }
    }

    untie %tiedApacheSession;
    
    logdbg "debug", "getApacheSession: username=".$apacheSession->{username};
    logdbg "debug", "getApacheSession: key=".$apacheSession->{SessionKey};
    return $apacheSession;
}



#
# deleteApacheSession
# --------------------

sub deleteApacheSession {
my $self = shift;
my $apacheSession = shift;
my $sessionKey = $apacheSession->{SessionKey};
my %tiedApacheSession;
logdbg "debug", ref($self)."->deleteApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined');

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
logdbg "debug", "storeApacheSession: sessionKey=".(defined $sessionKey ? $sessionKey : 'undefined');
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

sub DBH { croak "No!!!!!"; }
#sub DBH { my $self = shift; return $self->db_Main(); }


# failedAuthentication()
# ----------------------

sub failedAuthentication() {
}

1;
