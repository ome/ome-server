# OME::SessionManager

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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

=head1 NAME

OME::SessionManager - Get an L<C<OME::Session>|OME::Session> object.

=head1 SYNOPSIS

	use OME::SessionManager;
	use OME::Session;

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $sessionKey = $session->SessionKey();
	$manager->logout($session);

	my $session = $manager->createSession($sessionKey);
	$manager->logout($session);

	my $session = OME::SessionManager->TTYlogin();
	$manager->logout($session);

=head1 DESCRIPTION

This class is used to get an initial OME::Session object.
There are several authentication methods implemented including username/password,
a string token (SessionKey) and a TTY login from the command line.  The SessionKey
token is used for short-term persistance between a client and the OME server.

=cut


# Ilya's add
# JM 14-03
# JM 14-05 fix bug when log in with wrong username/password

package OME::SessionManager;
use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;
use Log::Agent;
use Class::Accessor;
use Class::Data::Inheritable;
use Apache::Session::File;
use OME::Factory;
use OME::Session;
use OME::Configuration;
use Term::ReadKey;
use POSIX;

use base qw(Class::Accessor Class::Data::Inheritable);

use constant FIND_USER_SQL => <<"SQL";
      select attribute_id, password
        from experimenters
       where ome_name = ?
SQL

# The lifetime of server-side session keys in seconds
our $APACHE_SESSION_LIFETIME = 30;  # 30 minutes

# FIXME:  This hard-coded path should come from Configuration->tmp_dir()
# Or some other cleverness other than hard-coding it here
our $TEMP_ROOT = '/var/tmp/OME';

=head1 METHODS

=cut

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

=head2 createSession

	$manager->createSession ($username,$password);
	$manager->createSession ($sessionKey);

This method will attempt a connection to the DB using $username/$password or $sessionKey,
and return an L<C<OME::Session>|OME::Session> object if successful.

=cut

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
     
    if (defined $session){
		$self->storeApacheSession($session);
    }

    return $session or undef;
}


# TTYlogin
# --------

=head2 TTYlogin

	$manager->TTYlogin ();

This method will attempt to get login information from the user using a terminal interface.
If successfull, it will cache the SessionKey in the user's ~/.omelogin file.

=cut

sub TTYlogin {
    my $self = shift;
    my $homeDir = $ENV{"HOME"} || ".";
    my $loginFile = "$homeDir/.omelogin";

    my $session;

    my $loginFound = open LOGINFILE, "< $loginFile";

    if ($loginFound) {
        my $key = <LOGINFILE>;
        chomp($key);
        $session = $self->createSession($key);
        close LOGINFILE;

        if (!defined $session) {
            print "Cannot login via previous session.\n";
        }
    }

    until (defined $session) {
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

        $session = $self->createSession($username,$password);

        if (defined $session) {
            my $created = open LOGINFILE, "> $loginFile";
            if ($created) {
                print LOGINFILE $session->{SessionKey}, "\n";
                close LOGINFILE;
            }

            print "Great, you're in.\n\n";
        } else {
            print "That username/password is not valid. Please try again.\n\n";
        }
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

    my $apacheSession = $self->getApacheSession($key) or return undef;
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

    my $bootstrap_factory = OME::Factory->new();

    my $dbh = $bootstrap_factory->obtainDBH();
    my ($experimenterID,$dbpass);
    eval {
        ($experimenterID,$dbpass) =
          $dbh->selectrow_array(FIND_USER_SQL,{},$username);
    };
# We're not supposed to release the Factory's DBH.  Only ones we get from Factory->newDBH
#   $bootstrap_factory->releaseDBH($dbh);

    return undef if $@;



    #return undef unless $sth->execute($username);

    #my $results = $sth->fetch();
   # my ($experimenterID,$dbpass) = @$results;
    
    return undef unless defined $dbpass and defined $experimenterID;
    return undef if (crypt($password,$dbpass) ne $dbpass);


    my $host;
   	if (exists $ENV{'REMOTE_HOST'} ) {
   		$host = $ENV{'REMOTE_HOST'};
	} else {
		$host = $ENV{'HOST'};
	}

    logdbg "debug", "getOMESession: looking for userState, experimenter_id=$experimenterID";
    my $userState = $bootstrap_factory->
      findObject('OME::UserState',experimenter_id => $experimenterID);
    logdbg "debug", "getOMESession: found existing userState(s)" if defined $userState;

    if (!defined $userState) {
        $userState = $bootstrap_factory->
          newObject('OME::UserState',
                    {
                     experimenter_id => $experimenterID,
                     started         => 'now',
                     last_access     => 'now',
                     host            => $host
                    });
        logdbg "debug", "getOMESession: created new userState";
        $bootstrap_factory->commitTransaction();
    } else {
        $userState->last_access('now');
        $userState->host($host);
    }

    logdie ref($self)."->getOMESession:  Could not create userState object"
      unless defined $userState;

    my $session = OME::Session->instance($userState, $bootstrap_factory);
    
    logdbg "debug", "getOMESession: updating userState";
    $userState->storeObject();
    $session->commitTransaction();

    logdbg "debug", "getOMESession: returning session";
    return $session;
}


#
# logout
# ------

=head2 logout

	$manager->logout ($session);

Unregisters the $session from this $manager.

=cut

sub logout {
    my $self = shift;
    my $session = shift;
    return undef unless defined $session;
    logdbg "debug", ref($self)."->logout: logging out";
    $self->deleteApacheSession ($session->{ApacheSession});
    delete $session->{ApacheSession};
    delete $session->{SessionKey};
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
    my ($lock_dir,$sess_dir) = ("$TEMP_ROOT/lock","$TEMP_ROOT/sessions");
	unless (-d $TEMP_ROOT)
		{ mkdir($TEMP_ROOT) or croak "Couldn't make directory $TEMP_ROOT: $!" }
	unless (-d $lock_dir)
		{ mkdir($lock_dir) or croak "Couldn't make directory $lock_dir: $!" }
	unless (-d $sess_dir)
		{ mkdir($sess_dir) or croak "Couldn't make directory $sess_dir: $!" }


    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => $sess_dir,
            LockDirectory => $lock_dir,
        };
    };
    return undef if $@;

    #
    # Check for a stale session key.  If its stale, delete it and return undef.
    if (defined $sessionKey) {
    	my $sessionAge = sprintf ( "%d",(POSIX::difftime(time(),$tiedApacheSession{timestamp}) / 60) );
		logdbg "debug", "getApacheSession: timestamp = ".$tiedApacheSession{timestamp}.".  Session is $sessionAge minutes old";
		if ($sessionAge > $APACHE_SESSION_LIFETIME) {
			logdbg "debug", "Deleting session";
			tied (%tiedApacheSession)->delete();
			print STDERR "Session is $sessionAge minutes long - expired.\n";
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
    
    logdbg "debug", "getApacheSession: username=" . ($apacheSession->{username} || "");
    logdbg "debug", "getApacheSession: key=" . ($apacheSession->{SessionKey} || "");
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
my ($lock_dir,$sess_dir) = ("$TEMP_ROOT/lock","$TEMP_ROOT/sessions");

    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => $sess_dir,
            LockDirectory => $lock_dir
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
my ($lock_dir,$sess_dir) = ("$TEMP_ROOT/lock","$TEMP_ROOT/sessions");

	unless (-d $TEMP_ROOT)
		{ mkdir($TEMP_ROOT) or croak "Couldn't make directory $TEMP_ROOT: $!" }
	unless (-d $lock_dir)
		{ mkdir($lock_dir) or croak "Couldn't make directory $lock_dir: $!" }
	unless (-d $sess_dir)
		{ mkdir($sess_dir) or croak "Couldn't make directory $sess_dir: $!" }

    eval {
        tie %tiedApacheSession, 'Apache::Session::File', $sessionKey, {
            Directory     => $sess_dir,
            LockDirectory => $lock_dir
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
