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
use Digest::MD5;
use OME::Factory;
use OME::Session;
use OME::Configuration;
use Term::ReadKey;

use base qw(Class::Accessor Class::Data::Inheritable);

use constant FIND_USER_SQL => <<"SQL";
      select attribute_id, password
        from experimenters
       where ome_name = ?
SQL

use constant INVALIDATE_OLD_SESSION_KEYS_SQL => <<"SQL";
	UPDATE OME_SESSIONS
	SET SESSION_KEY = NULL
	WHERE abstime(now()) - abstime(LAST_ACCESS)
			> ?
SQL

# The lifetime of server-side session keys in seconds
our $SESSION_KEY_LIFETIME = 30;  # 30 minutes
our $SESSION_KEY_LENGTH = 32;

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
A set of flags can be optionally passed in the last parameter as a hash reference.
Supported flags include DataSource, DBUser and DBPassword:
	$manager->createSession ($sessionKey, {DataSource => 'foo', DBUser => 'bar'});

=cut

sub createSession {
    my $self = shift;
    my ($username,$password,$key);
    my $flags = pop if ref ($_[1]) eq 'HASH' or ref ($_[2]) eq 'HASH';    
    ($username,$password) = @_ if scalar (@_) == 2;
    ($key) = @_ if scalar (@_) == 1;

    my $session;

    if (defined $username and defined $password) { 
        $session = $self->createWithPassword($username,$password,$flags);
    } elsif (defined $key) {
        $session = $self->createWithKey($key,$flags);
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
    my $flags = pop @_ if ref ($_[0]) eq 'HASH';
    my $homeDir = $ENV{"HOME"} || ".";
    my $loginFile = "$homeDir/.omelogin";

    my $session;

    my $loginFound = open LOGINFILE, "< $loginFile";

    if ($loginFound) {
        my $key = <LOGINFILE>;
        chomp($key);
        $session = $self->createWithKey($key,$flags);
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

        $session = $self->createWithPassword($username,$password,$flags);

        if (defined $session) {
            my $created = open LOGINFILE, "> $loginFile";
            if ($created) {
                print LOGINFILE $session->SessionKey(), "\n";
                close LOGINFILE;
            }

            print "Great, you're in.\n\n";
        } else {
            print "That username/password is not valid. Please try again.\n\n";
        }
	}

    return $session;
}


# createWithKey
# ------------------
# Creates and returns an OME::Session given a SessionKey
# Invalidates any stale keys
# updates last_access + host
# returns OME::Session upon success
# returns undef of invalid or stale key.

sub createWithKey {
	my $self = shift;
	my $sessionKey = shift;
	my $flags = shift;

	
	my $bootstrap_factory = OME::Factory->new($flags);
	my $dbh = $bootstrap_factory->obtainDBH();
	eval {
		$dbh->do (INVALIDATE_OLD_SESSION_KEYS_SQL,{},$SESSION_KEY_LIFETIME*60);
	};

	$sessionKey = $self->validateSessionKey($sessionKey) or return undef;
	
	my $userState = $bootstrap_factory->
		findObject('OME::UserState', session_key => $sessionKey);
	logdbg "debug", "getOMESession: found existing userState(s)" if defined $userState;
	
	return undef unless defined $userState;


	my $host;
	if (exists $ENV{'REMOTE_HOST'} ) {
		$host = $ENV{'REMOTE_HOST'};
	} else {
		$host = $ENV{'HOST'};
	}
	
	$userState->last_access('now');
	$userState->host($host);
	
	my $session = OME::Session->instance($userState, $bootstrap_factory);
	
	logdbg "debug", "createWithKey: updating userState";
	$userState->storeObject();
	$session->commitTransaction();
	
	logdbg "debug", "createWithKey: returning session";
	return $session;
}


#
# createWithPassword
# ----------------
# Creates and returns an OME::Session given a username/password
# Invalidates any stale keys
# updates last_access + host
# returns OME::Session upon success
# returns undef of invalid or stale key.

sub createWithPassword {
	my $self = shift;
	my ($username,$password,$flags) = @_;
	
	return undef unless $username and $password;
	
	my $bootstrap_factory = OME::Factory->new($flags);
	
	my $dbh = $bootstrap_factory->obtainDBH();
	eval {
		$dbh->do (INVALIDATE_OLD_SESSION_KEYS_SQL,{},$SESSION_KEY_LIFETIME*60);
	};

	my ($experimenterID,$dbpass);
	eval {
		($experimenterID,$dbpass) =
			$dbh->selectrow_array(FIND_USER_SQL,{},$username);
	};
# We're not supposed to release the Factory's DBH.  Only ones we get from Factory->newDBH
#   $bootstrap_factory->releaseDBH($dbh);

	return undef if $@;
    
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
		my $sessionKey = $self->generateSessionKey();
		$userState = $bootstrap_factory->
			newObject('OME::UserState', {
				experimenter_id => $experimenterID,
				session_key     => $sessionKey,
				started         => 'now',
				last_access     => 'now',
				host            => $host
			});
		logdbg "debug", "getOMESession: created new userState";
		$bootstrap_factory->commitTransaction();
	} else {
		$userState->last_access('now');
		$userState->host($host);
		$userState->session_key($self->generateSessionKey()) unless $userState->session_key();
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

	my $userState = $session->getUserState();
	$userState->last_access('now');
	$userState->session_key(undef);
	$userState->storeObject();
	$session->commitTransaction();

}


#
# generateSessionKey
# --------------------

sub generateSessionKey {
	my $self = shift;
	
	# Stolen from:
	# Apache::Session::Generate::MD5;
	# Copyright(c) 2000, 2001 Jeffrey William Baker (jwbaker@acm.org)
	# Distribute under the Artistic License

	return substr(
		Digest::MD5::md5_hex(
			Digest::MD5::md5_hex(time(). {}. rand(). $$)),
		0, $SESSION_KEY_LENGTH
	);
    

}



#
# validateSessionKey
# --------------------

sub validateSessionKey {
	my $self = shift;
	my $sessionKey = shift;
	
	return undef unless $sessionKey;
	return undef unless length ($sessionKey) == $SESSION_KEY_LENGTH;
	return undef unless $sessionKey =~ /^[a-fA-F0-9]+$/;
	return $sessionKey;
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
