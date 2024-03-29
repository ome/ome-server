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
use Data::Dumper;
use Class::Accessor;
use Class::Data::Inheritable;
use Digest::MD5;
use OME::Factory;
use OME::Session;
use OME::Configuration;
use Term::ReadKey;
use OME::DBObject;
use OME::Install::Environment;
use IPC::Run;

use base qw(Class::Accessor Class::Data::Inheritable);

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

# Info about our crypto keys
our $KEY_FILE = 'ome-key-512.pem';
our $KEY_LENGTH = 512;
# This is the maximum difference between time() and what is passed in the encrypted password string
# In seconds (since time() is in seconds)
our $CRYPT_LIFETIME = 30;

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

	my ($session,$factory,$ACL);
	
	# If a Session instance exists, get the factory from it as well as the ACL
	if (OME::Session->hasInstance()) {
		$factory = OME::Session->instance()->Factory()->revive();
		$ACL = OME::Session->instance()->ACL();
	} else {
	# Otherwise, make a new one and leave $ACL undef
		$factory = OME::Factory->new($flags) unless $factory;
	}
	
	# Not being able to get a Factory means there's no point in doing anything with this process.
	die "Could not obtain a Factory while creating a Session" unless $factory;

	my $dbh = $factory->obtainDBH();

	# UserState has no ACL, so this will allways find it if the key exists.
	my $userState = $self->makeOrGetUserState($factory,session_key => $sessionKey);
	
	# Not finding a UserState is not deadly - just means no Session for you.
	return undef unless defined $userState;
	
	# Now we can get a Session object and update its ACL.
	$session = OME::Session->instance($userState, $factory,$ACL);
	# Not being able to get a Session given a $userState and a $factory means we're in deep doodoo
	die "Could not obtain a Session object" unless $session;
	$self->updateACL();

	my $configuration = $factory->Configuration();

	# check to see if this session is for a guest user. If it is,
	# and if guests are disalllowed, punt.
	# as some installations may not have this configuration
	# variable
	# test for it in eval -if an error happens, guest is not
	# allowed.

	if ($session->isGuestSession()) {
	    my $guestStatus;
	    eval {
			$guestStatus = $configuration->allow_guest_access();
	    };
	    if (!$guestStatus) {
			$userState->session_key(undef);
			$userState->storeObject();
			$session->commitTransaction();
			return undef;
	    }
	}
	
	# We have to get pretty deep into Session making before we can punt on an expired key
	# This is caused by how we check if this is a Guest Session.  Guest's keys don't expire,
	# But to determine if its a Guest Session, we have to go all the way through making it.
	# At this point its not a Guest Session, so check for an expired key.
	else { #non- guest user

	    my $age = 1;
	    eval { 
		 $age =$dbh->selectrow_array(GET_KEY_AGE, undef,
		$sessionKey);
	    };
	    # force it to be too old if need be.
	    $age += $SESSION_KEY_LIFETIME if ($@);

	    if ($age > $SESSION_KEY_LIFETIME) {
# Do not invalidate the session key if it is stale. Another process may 
# be using it. We will invalidate stale session keys again once we have
# implemented multiple session keys per user (e.g. one key per process)
#			$userState->session_key(undef);
#			$userState->storeObject();
#			$session->commitTransaction();
			return undef;		
	    }
	}	
	
	
	
	$userState->storeObject();
	$session->commitTransaction();
	
	return $session;
}

sub su_session {
	my $self = shift;

#	croak "You must be root to create an OME superuser session" unless $< == 0;
#	my $DSN = OME::Database::Delegate->getDefaultDelegate()->getDSN();
#	croak "You can only create an OME superuser session on a local database" if $DSN =~ /host/;
	
    my $factory = OME::Factory->new();
    croak "Couldn't create a new factory" unless $factory;
    
	my $var = $factory->findObject('OME::Configuration::Variable',
			configuration_id => 1, name => 'super_user');
    my $experimenterID = $var->value();
    
   
	croak "The super_user Expreimenter is not defined in the configuration table.\n"
		unless $experimenterID;
	my $userState = $self->makeOrGetUserState ($factory, experimenter_id => $experimenterID);

    # print "  \\__ Getting session for user state ID=".$userState->id()."\n";
    # N.B.: In this case, we are not specifying the visible groups and users - they are all visible.
    my $session = OME::Session->instance($userState, $factory);

    croak "Could not create session from userState.  Something is probably very very wrong" unless defined $session;

    $userState->storeObject();
    $session->commitTransaction();

    return $session;
}

sub sudo_session {
	my ($self, $username) = @_;

	my $session = OME::Session->instance();
	my $factory = $session->Factory();
#	croak "You can only call sudo_session on a super_user session"
#		unless $factory->Configuration()->super_user() == $session->experimenter_id();

	my $userState = $self->makeOrGetUserState ($factory, OMEName => $username);
	croak "Could not get user state for $username" unless $userState;

	# N.B.:  This disables ACL on the sudo session
	return ( OME::Session->instance($userState, $factory,undef) );
	
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
	# We check for this first because calling keys() on an undef variable will turn it into {}
	# which is not the same as undef.
	if ( defined($ACL) ne defined($oldACL) ) {
		$ACLsDiffer = 1;
	} elsif( scalar(keys %$oldACL) != scalar(keys %$ACL) ) {
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




=head2 getRSAmodulus

	my $challenge = $manager->getRSAmodulus();

Generates a private key in $TEMP/$KEY_FILE, and returns its modulus as a hex string.
The public exponent is hard-coded to be -F4 (0x10001).
The modulus is as a public key used by the JavaScript RSA library (or other RSA implementations)
to encrypt passwords (or other data).

=cut

sub getRSAmodulus {
my ($self) = @_;

	my $tmp_dir = OME::Install::Environment->initialize()->tmp_dir();
	my $keyfile = "$tmp_dir/$KEY_FILE";
	my @cmd;
	my ($in,$out,$errorStream,$modulus);
	
	unless (-e $keyfile) {
		`RANDFILE=$tmp_dir/.rnd openssl genrsa -F4 -out $keyfile $KEY_LENGTH`;
		chmod (0400,$keyfile);
	}

	if (-e $keyfile) {
		@cmd = qw( openssl rsa -check -noout -in );
		push (@cmd,$keyfile);
		IPC::Run::run (\@cmd,\$in,\$out,\$errorStream);
	} else {
		return undef;
	}

	return undef unless $out =~ /RSA key ok/;

	@cmd = qw( openssl rsa -modulus -noout -in );
	push (@cmd,$keyfile);
	IPC::Run::run (\@cmd,\$in,\$modulus,\$errorStream);
	chomp ($modulus);
	$modulus = $1 if $modulus =~ /Modulus=(.*)$/;
	
	return ($modulus);
}


=head2 createWithRSAPassword

	my $session = $manager->createWithRSAPassword($username,$password,$flags);

Decrypts the password using the RSA key stored in $TEMP/$KEY_FILE, then calls
CreateWithPassword to make the session.
The plaintext password follows a time signature (result of time() call) in brackets.
For example: [1185410367]abc123
corresponds to 2007-07-26 00:39:27Z, and the plaintext password abc123
This plaintext string is encrypted and then base-64 encoded.

=cut

sub createWithRSAPassword {
	my $self = shift;
	my ($username, $password, $flags) = @_;

	my $keyfile = OME::Install::Environment->initialize()->tmp_dir()."/$KEY_FILE";
	return undef unless -e $keyfile;

	my @cmd;
	my ($decoded,$plaintext,$errorStream);
	@cmd = qw( openssl base64 -d );
	IPC::Run::run (\@cmd,\$password,\$decoded,\$errorStream);
	return undef unless $decoded;

	@cmd = qw( openssl rsautl -decrypt -inkey );
	push (@cmd,$keyfile);
	IPC::Run::run (\@cmd,\$decoded,\$plaintext,\$errorStream);
	return undef unless $plaintext;
	
	my ($time,$plain_password) = ($1,$2) if ($plaintext =~ /^\[(\d+)\](.*)$/);
	return undef unless $time and $password;
	return undef if time() - $time > $CRYPT_LIFETIME;

	return $self->createWithPassword ($username,$plain_password,$flags);
}

#
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

	my ($session,$factory,$ACL);
	
	# If a Session instance exists, get the factory from it as well as the ACL
	if (OME::Session->hasInstance()) {
		$factory = OME::Session->instance()->Factory()->revive();
		$ACL = OME::Session->instance()->ACL();
	} else {
	# Otherwise, make a new one and leave $ACL undef
		$factory = OME::Factory->new($flags) unless $factory;
	}
	
	my $dbh = $factory->obtainDBH();
	my $configuration = OME::Configuration->new($factory );

	my ($experimenter,$experimenterID,$dbpass);
	eval {
		$experimenter = $factory->findObject ('OME::SemanticType::BootstrapExperimenter',
			OMEName => $username);
	};

	return undef if( $@ || not defined $experimenter);
	
    ($experimenterID,$dbpass) = ($experimenter->ID,$experimenter->Password);
	return undef unless $experimenter;
	
	# If LDAP is enabled, try to authenticate against LDAP
	my $ldap_conf = $configuration->ldap_conf();
	if (not ($ldap_conf->{use} and $self->authenticate_LDAP ($ldap_conf,$username,$password) ) ) {
		# LDAP failed or not used.
		# No dbpass - authentication failure.
		return undef unless $dbpass and length ($dbpass) >= 1;
		# Try authentication against the DB
		return undef if (crypt($password,$dbpass) ne $dbpass);
	}

	
	# if the user name and password indicate a guest user,
	# check the configuration to see if guest access is allowed.
	# must wrap the configuration test in an eval
	# as some installations may not have this set up. This can 
	# happen if createWithPassword is used to authenticate for 
	# an installation update, _before_ the configuration flag is
	# set.
	# to avoid problems, check for guest credietnails first,
	# then check guest allowed in an eval.

	if ($experimenter->FirstName() eq 'Guest' &&
	    $experimenter->LastName() eq 'User') {
	    # could be guest. is guest allowed?
	    my $guestStatus;
	    eval { $guestStatus =
		       $configuration->allow_guest_access();};
	    return undef unless $guestStatus;
	} 


	my $userState = $self->makeOrGetUserState($factory,experimenter => $experimenter);

	$session = OME::Session->instance($userState, $factory, $ACL);
	$self->updateACL();

	$userState->storeObject();
	$session->commitTransaction();
	
	logdbg "debug", "createWithPassword: returning session";
	return $session;
}

=head2 makeOrGetUserState

	$manager->makeOrGetUserState ( $factory, experimenter_id => $my_exp_id );
	$manager->makeOrGetUserState ( $factory, experimenter => $my_experimenter_object );
	$manager->makeOrGetUserState ( $factory, OMEName => $my_experimenter_username );
	$manager->makeOrGetUserState ( $factory, session_key => $my_key );
	# Note that passing session_key will return undef unless the key exists.
	# In all other cases, the userstate will be created if it doesn't exist.

=cut

sub makeOrGetUserState {
	my $self = shift;
	my $factory = shift;
	my %flags = @_;
	my $experimenter;
	my $userState;

	if (exists $flags{experimenter_id} and defined $flags{experimenter_id}) {
		$experimenter = $factory->loadObject ('OME::SemanticType::BootstrapExperimenter',
			$flags{experimenter_id})
				or logdie ref($self)."->makeOrGetUserState:  could not find experimenter ID ".$flags{experimenter_id};
	} elsif (exists $flags{experimenter} and defined $flags{experimenter}) {
		$experimenter = $factory->loadObject ('OME::SemanticType::BootstrapExperimenter',
			$flags{experimenter}->id())
				or logdie ref($self)."->makeOrGetUserState:  could not find experimenter ID ".$flags{experimenter}->id();
	} elsif (exists $flags{OMEName} and defined $flags{OMEName}) {
		$experimenter = $factory->findObject ('OME::SemanticType::BootstrapExperimenter',
			OMEName => $flags{OMEName})
				or logdie ref($self)."->makeOrGetUserState:  could not find experimenter OMEName=".$flags{OMEName};
	} elsif (exists $flags{session_key} and defined $flags{session_key}) {
		$userState = $factory->findObject('OME::UserState', session_key => $flags{session_key});
		return undef unless $userState;
	} else {
		logdie ref($self)."->makeOrGetUserState:  missing parameters"
	}



	my $host;
	if (exists $ENV{'HTTP_HOST'} ) {
		$host = $ENV{'HTTP_HOST'};
	} elsif (exists $ENV{'HOST'}) {
		$host = $ENV{'HOST'};
	}


	$userState = $factory->
		findObject('OME::UserState',experimenter_id => $experimenter->ID()) if $experimenter
			and not $userState;
	
	if (!defined $userState) {
		my $sessionKey = $self->generateSessionKey();
		$userState = $factory->
			newObject('OME::UserState', {
				experimenter_id => $experimenter->ID(),
				session_key     => $sessionKey,
				started         => 'now()',
				last_access     => 'now()',
				host            => $host
			});
		logdbg "debug", "makeOrGetUserState: created new userState";
		$factory->commitTransaction();
	} else {
		$userState->last_access('now()');
		$userState->host($host);
		$userState->session_key($self->generateSessionKey()) unless $userState->session_key();
		logdbg "debug", "createWithPassword: found existing userState(s)";
	}

	logdie ref($self)."->makeOrGetUserState:  Could not create userState object"
		unless defined $userState;
	
	return $userState;
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

# While we have a single key per user, we need to avoid stepping on other keys
# that may be issued for the same user.  The user may have the AE running in the background
# for instance.
# In other words, there is no effect on the back-end/DB from logging out - its purely
# up to the client to clear out their own authentication tokens (Session keys).
# 	my $userState = $session->getUserState();
# 	$userState->last_access('now()');
# 	$userState->session_key(undef);
# 	$userState->storeObject();
# 	$session->commitTransaction();

}

#
# authenticate_LDAP
# --------------------

=head2 logout

	$manager->authenticate_LDAP ($ldap_conf,$username,$password);
	OME::SessionManager->authenticate_LDAP ($ldap_conf,$username,$password);

Attempts ldap authentication wether or not $ldap_conf->{use} flag is set.
returns 1 if ldap authentication is successful.
returns 0 if authentication failed.
returns undef on error (failed server connection, etc).

=cut

sub authenticate_LDAP {
	my ($proto,$ldap_conf,$username,$passwd,$exper_hash) = @_;
    my $self = ref($proto) || $proto;
    if (not ($self and $ldap_conf and $username and $passwd)) {
    	$passwd = '***HIDDEN***' if $passwd;
		confess "Bad calling syntax to authenticate_LDAP";
	}
	my $ldap;
	logdbg "debug", $self."->authenticate_LDAP";
	# This is a quoted eval because we want this processed conditionally.
	eval 'use Net::LDAP;';
	# abort if we can't use Net::LDAP;
	return undef if $@;
	logdbg "debug", $self."->authenticate_LDAP Net::LDAP loaded";
	eval { $ldap = Net::LDAP->new ( $ldap_conf->{hosts}, %{$ldap_conf->{options}},%{$ldap_conf->{ssl_opts}} ); };
	if ($ldap) {
		logdbg "debug", $self."->authenticate_LDAP Connected";
		# Start TLS if requested (no point in checking now if the server supoprts it)
		eval { $ldap->start_tls(%{$ldap_conf->{ssl_opts}}); }
			if ( not $ldap->cipher() and $ldap_conf->{use_tls} );
		# The only way we send credentials is over an encrypted connection or if use_tls is off
		if ($username and $passwd and ($ldap->cipher() or not $ldap_conf->{use_tls}) ) {
			my $DN = "uid=$username";
			$DN .= ",$ldap_conf->{DN}" if $ldap_conf->{DN};
			my $mesg;
			logdbg "debug", $self."->authenticate_LDAP Binding $DN";
			eval{$mesg = $ldap->bind ($DN, password => $passwd );};
			if ($@ or not $mesg or $mesg->code != 0) {
				# Authentication failed
				logdbg "debug", $self."->authenticate_LDAP Bind failure";
				return 0;
			} else {
				# Authentication succeeded
				logdbg "debug", $self."->authenticate_LDAP Bind success";
				# Try to populate an experimenter hash from the LDAP entry
				$self->get_Experimenter_from_LDAP ($ldap,$DN,$exper_hash);

				# Don't forget to unbind + disconnect
				$ldap->unbind ( );
				$ldap->disconnect();
				return 1;
			}
		} else {
			# Authentication not attempted: no user/pass or unsecure.  This counts as failure.
			logdbg "debug", $self."->authenticate_LDAP bind not attempted";
			return undef;
		}
		# Don't forget to disconnect
		$ldap->disconnect();
	} else {
		# Couldn't connect to LDAP server:  This counts as failure.
		logdbg "debug", $self."->authenticate_LDAP no connection to server";
		return undef;
	}
}

sub get_Experimenter_from_LDAP {
	my ($self,$ldap,$DN,$exper_hash) = @_;
	logdbg "debug", $self."->get_Experimenter_from_LDAP";
	return undef unless $exper_hash;
	my $mesg;
	eval {
		$mesg = $ldap->search (
			base   => $DN,
			filter => '(objectclass=*)',
		);
	};
	return undef unless $mesg;

	logdbg "debug", $self."->get_Experimenter_from_LDAP search complete";
	my ($entry,$firstName,$lastName,$cn,$sn,$email,$uid,$home);
	foreach $entry ($mesg->all_entries) {
		foreach my $attr ($entry->attributes()) {
			$firstName = $entry->get_value ($attr) if $attr eq 'givenName';
			$lastName = $entry->get_value ($attr) if $attr eq 'sn';
			$cn = $entry->get_value($attr) if $attr eq 'cn';
			$email = $entry->get_value($attr) if $attr eq 'mail';
			$uid = $entry->get_value($attr) if $attr eq 'uid';
			$home = $entry->get_value($attr) if $attr eq 'homeDirectory';
		}
	}
	if (not (defined $firstName and defined $lastName) and defined $cn and defined $sn) {
	# Get firstName from the cn/sn
		$firstName = $1 if $cn =~ /(.+)\w$sn/;
	}
	if (not (defined $firstName and defined $lastName) and defined $cn) {
	# Get it from the cn (no sn)
		($firstName,$lastName) = split (' ',$cn,2);
	}
	logdbg "debug", $self."->get_Experimenter_from_LDAP: OMEName: $uid, FirstName: $firstName, LastName: $lastName, DataDirectory: $home, Email: $email";
	if (defined $firstName and defined $lastName and defined $email and defined $uid) {
		$exper_hash->{OMEName} = $uid;
		$exper_hash->{FirstName} = $firstName;
		$exper_hash->{LastName} = $lastName;
		$exper_hash->{DataDirectory} = $home;
		$exper_hash->{Email} = $email;
	}
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
