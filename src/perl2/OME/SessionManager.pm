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
use OME::DBObject; 

use base qw(Class::Accessor Class::Data::Inheritable);

use constant INVALIDATE_OLD_SESSION_KEYS_SQL => <<"SQL";
	UPDATE OME_SESSIONS
	SET SESSION_KEY = NULL
	WHERE abstime(now()) - abstime(LAST_ACCESS)
			> ?
SQL

use constant GET_KEY_AGE => <<"SQL";
	SELECT EXTRACT (EPOCH  from abstime(now()) - abstime(LAST_ACCESS))
		from OME_SESSIONS where session_key=?
SQL

use constant GET_VISIBLE_GROUPS_SQL => <<"SQL";
	SELECT distinct g.attribute_id
	FROM groups g, experimenter_group_map egm
	WHERE (g.attribute_id = egm.group_id
		AND egm.experimenter_id = ?)
	OR g.leader = ?
	UNION
	SELECT e.group_id from experimenters e
	WHERE e.attribute_id = ? 
SQL

use constant GET_VISIBLE_USERS_SQL => <<"SQL";
	SELECT distinct e.attribute_id
	FROM groups g, experimenter_group_map egm, experimenters e
	WHERE (g.leader = ?
		AND g.attribute_id = egm.group_id
		AND egm.experimenter_id = e.attribute_id)
	OR (g.leader = ?
		AND e.group_id = g.attribute_id)
	UNION
	SELECT e.attribute_id from experimenters e
	WHERE e.attribute_id = ? 
SQL

# The lifetime of server-side session keys in seconds
our $SESSION_KEY_LIFETIME = 1800;  # 30 minutes, (30*60 sec = 1800 sec)
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
If successfull, it will cache the SessionKey in the user's ~/.omelogin
    file.

    If flags, user name, and password are provided (in order), they
    will be used as appropriate.

=cut

sub TTYlogin {
    my $self = shift;
    #my $flags = pop @_ if ref ($_[0]) eq 'HASH';
    my ($flags,$user,$password) = @_;
    my $homeDir = $ENV{"HOME"} || ".";
    my $loginFile = "$homeDir/.omelogin";

    my $session;


    if (!defined $session) {
	my $key;

	# get user name and password from flags;
	my $loginFound = open LOGINFILE, "< $loginFile";
	if ($loginFound) {
	    $key = <LOGINFILE>;
	    chomp($key);
	    close LOGINFILE;
	}
	$session = $self->createWithKey($key,$flags);

	    
	# At this point, i'm fine if the session is defined.
	# if  i have a password and user name. use them.
	# if this fails, or if I don't have them, try to login via 
	# user name /password prompts.

	if (!(defined $session) && $user && $password) {
	    $session = $self->createWithPassword($user,$password,$flags);
	}
	$session = $self->promptAndLogin($loginFile,$flags) unless
	    ($session);
	if (defined $session) {
	    my $created = open LOGINFILE, "> $loginFile";
	    if ($created) {
		print LOGINFILE $session->SessionKey(), "\n";
		close LOGINFILE;
	    }
	}
    }
    return $session;
}


=sub  promptAndLogin

    $session = $self->promptAndLogin($loginFile,$session);

    ask for a session via prompts and try to create it
=cut

sub promptAndLogin {
    my $self = shift;
    my $loginFile = shift;
    my $flags = pop @_ if ref ($_[0]) eq 'HASH';

    my $session;
    my $username;
    my $password;

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
# Invalidates any stale keys for the associated user
# also allows for guest access if the installation is appropriately configured
# updates last_access + host
# returns OME::Session upon success
# returns undef of invalid or stale key.

sub createWithKey {
	my $self = shift;
	my $sessionKey = shift;
	my $flags = shift;

	return undef unless ($sessionKey && 
			     (length ($sessionKey) ==
			     $SESSION_KEY_LENGTH));

	my ($session,$factory);
	if (OME::Session->hasInstance()) {
		$session = OME::Session->instance();
		$factory = $session->Factory()->revive();
	}

	$factory = OME::Factory->new($flags) unless $factory;
	my $dbh = $factory->obtainDBH();
	
	my $userState = $factory->
		findObject('OME::UserState', session_key => $sessionKey);
#	logdbg "debug", "createWithKey: found existing userState(s)" if defined $userState;
	
	return undef unless defined $userState;
	$session = OME::Session->instance($userState, $factory,
					  undef);

	return undef unless ($session);

	my $configuration = $factory->Configuration();

	my $exp;
	eval {
	    $exp = $userState->User();	    
	};

	# check to see if this session is for a guest user. If it is,
	# and if guests are disalllowed, punt.


	if ($session->isGuestSession()) {
	    if (!$configuration->allow_guest_access()) {
		$userState->session_key(undef);
		$userState->storeObject();
		$session->commitTransaction();
		return undef;
	    }
	}
	else { #non- guest user

	    my $age = 1;
	    eval { 
		 $age =$dbh->selectrow_array(GET_KEY_AGE, undef,
		$sessionKey);
	    };
	    # force it to be too old if need be.
	    $age += $SESSION_KEY_LIFETIME if ($@);

	    if ($age > $SESSION_KEY_LIFETIME) {
		$userState->session_key(undef);
		$userState->storeObject();
		$session->commitTransaction();
		return undef;		
	    }
	}	
	my $host;
	if (exists $ENV{'REMOTE_HOST'} ) {
		$host = $ENV{'REMOTE_HOST'};
	} else {
		$host = $ENV{'HOST'};
	}
	
	$userState->last_access('now()');
	$userState->host($host);
	
	

	$self->updateACL();
	
	$userState->storeObject();
	$session->commitTransaction();
	
	return $session;
}


sub updateACL {
	my $self = shift;
	my $session       = OME::Session->instance();
	my $factory       = $session->Factory();
	my $configuration = $factory->Configuration();
	my $superuser;
	eval {
		$superuser     = $configuration->super_user();
	};
	my $exp_id        = $session->experimenter_id();
	my $dbh           = $factory->obtainDBH();

	# Gather lists of whose data teh logged in user gets to see
	my $ACL;
	if ($superuser and $superuser != $exp_id) {
		$ACL = {
			users  => $dbh->selectcol_arrayref(GET_VISIBLE_USERS_SQL,{},$exp_id,$exp_id,$exp_id),
			groups => $dbh->selectcol_arrayref(GET_VISIBLE_GROUPS_SQL,{},$exp_id,$exp_id,$exp_id),
		}
	}
	
	# Compare old and new lists of whose data the logged in user gets access to.
	my $oldACL = $session->ACL();
	my $ACLsDiffer = 0;
	if( scalar(keys %$oldACL) != scalar(keys %$ACL) ) {
		$ACLsDiffer = 1;
	} else {
		ACL_COMPARISON: foreach my $key ( keys %$oldACL ) {
			if( scalar( @{ $ACL->{ $key } } ) ne scalar( @{ $oldACL->{ $key } } ) ) {
				$ACLsDiffer = 1;
				last ACL_COMPARISON;
			}
			for( my $index = 0; $index < scalar( @{ $ACL->{ $key } } ); $index++ ) {
				if( $oldACL->{ $key }->[ $index ] ne $ACL->{ $key }->[ $index ] ) {
					$ACLsDiffer = 1;
					last ACL_COMPARISON;
				}
			}
		}
	}

	# update the ACL access list if needed.
	if( $ACLsDiffer ) {
		# Update the list itself
		$session->{ACL} = $ACL;
		# The access lists's experimenter & group ids are embedded in 
		# cached SQL text. Those caches are now invalid, and need to be cleared.
		OME::DBObject->__clear_ALL_makeSelectSQL_cache();
	}
}

#
# createWithPassword
# ----------------
# Creates and returns an OME::Session given a username/password
# updates last_access + host
# returns OME::Session upon success
# returns undef if invalid

sub createWithPassword {
	my $self = shift;
	my ($username,$password,$flags) = @_;
	
	return undef unless $username and $password;
	
	my $bootstrap_factory = OME::Factory->new($flags);
	my $dbh = $bootstrap_factory->obtainDBH();
	my $configuration = OME::Configuration->new($bootstrap_factory );

	my ($experimenter,$experimenterID,$dbpass);
	eval {
		$experimenter = $bootstrap_factory->findObject ('OME::SemanticType::BootstrapExperimenter',
			OMEName => $username);
	};

	return undef if( $@ || not defined $experimenter);
	
    ($experimenterID,$dbpass) = ($experimenter->ID,$experimenter->Password);
	return undef unless $experimenter and $dbpass;

	return undef if (crypt($password,$dbpass) ne $dbpass);

	return undef if (!$configuration->allow_guest_access() &&
			   $experimenter->FirstName() eq 'Guest' &&
			 $experimenter->LastName() eq 'User');
	
	my $host;
	if (exists $ENV{'REMOTE_HOST'} ) {
		$host = $ENV{'REMOTE_HOST'};
	} else {
		$host = $ENV{'HOST'};
	}


	logdbg "debug", "createWithPassword: looking for userState,
	experimenter_id=$experimenterID";
	my $userState = $bootstrap_factory->
		findObject('OME::UserState',experimenter_id => $experimenterID);
	
	if (!defined $userState) {
		my $sessionKey = $self->generateSessionKey();
		$userState = $bootstrap_factory->
			newObject('OME::UserState', {
				experimenter_id => $experimenterID,
				session_key     => $sessionKey,
				started         => 'now()',
				last_access     => 'now()',
				host            => $host
			});
		logdbg "debug", "createWithPassword: created new userState";
		$bootstrap_factory->commitTransaction();
	} else {
		$userState->last_access('now()');
		$userState->host($host);
		$userState->session_key($self->generateSessionKey()) unless $userState->session_key();
		logdbg "debug", "createWithPassword: found existing userState(s)";
	}

	logdie ref($self)."->createWithPassword:  Could not create userState object"
		unless defined $userState;
	my $session = OME::Session->instance($userState,
		$bootstrap_factory, undef);

	$userState->storeObject();
	$session->commitTransaction();
	
	$self->updateACL();
	logdbg "debug", "createWithPassword: returning session";
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
	$userState->last_access('now()');
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
