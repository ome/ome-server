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
# JM 14-05 fix bug when log in with wrong username/password

package OME::SessionManager;
our $VERSION = 2.000_000;

use strict;

use Log::Agent;
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
      select attribute_id, password
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
	
    my $session = $self->getOMESession ($username,$password,'check for stale key');
    return undef unless $session;

    $session->{ApacheSession} = $apacheSession;
    $session->{SessionKey} = $apacheSession->{SessionKey};
    logdbg "debug", "createWithKey: {SessionKey}=".$session->{SessionKey};
    logdbg "debug", "createWithKey: SessionKey()=".$session->SessionKey();
	$session->writeObject();
    return $session;
}


#
# getOMESession
# ----------------

sub getOMESession {
    my $self = shift;
    my ($username,$password,$staleCheck) = @_;
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
    logdbg "debug", "getOMESession: looking for session, experimenter_id=$experimenterID";
    my @sessions = OME::Session->search ('experimenter_id' => $experimenterID);
    $session = $sessions[0] if defined $sessions[0];
    logdbg "debug", "getOMESession: found ".scalar(@sessions)." session(s)";

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
        logdbg "debug", "getOMESession: created new session";
    }
    logdie ref($self)."->getOMESession:  Could not create session object"
      unless defined $session;


	###########################
	# code block to check for stale key
	#
	if( defined $staleCheck ) {
		my $maxMin = 30;
		my $timeStamp = $session->last_access();
	
		# c is for current
		my ($csec,$cmin,$chour,$cday,$cmonth,$cyear) = localtime(time);
		$cmonth++; # cmonth is in range of 0-11
		$cyear+=1900; # cyear is years since 1900

		my $diffMinutes;

		if( $timeStamp =~ m/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+).+$/ ) {
			my ($year, $month, $day, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6);
			if( $year != $cyear or $month != $cmonth or $day != $cday ) {
				$diffMinutes = $maxMin + 1; # if the date doesn't match up, the session is over limit
			} else {
				$min += $hr*60;
				$cmin += $chour*60;
				$diffMinutes = $cmin - $min;
			}
		} else {
			die "Could not parse session->last_access time stamp '$timeStamp' with".
				"regex ".'m/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)-\d+$/'."\n";
		}

		if ($diffMinutes > $maxMin) {
			print STDERR "It has been $diffMinutes minutes since the last transaction. Session key has expired.\n";
			return undef;
		}
	}
	# end stale key codeblock
	############################


    $session->last_access('now');
    $session->host($host);
    
    OME::DBObject->DefaultSession($session);
    $session->{Factory} = OME::Factory->new($session);
    $session->{Manager} = $self;

    logdbg "debug", "getOMESession: updating session";
    $session->writeObject();
    $session->dbi_commit();
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
    while ( ($key,$value) = each %tiedApacheSession ) {
        if ($key eq '_session_id') {
            $apacheSession->{SessionKey} = $value;
        } else {
            $apacheSession->{$key} = $value;
        }
    }
    untie %tiedApacheSession;
    
    $self->refreshApacheSession ($apacheSession);

    logdbg "debug", "getApacheSession: username=".$apacheSession->{username};
    logdbg "debug", "getApacheSession: key=".$apacheSession->{SessionKey};
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

sub DBH { my $self = shift; return $self->db_Main(); }


# failedAuthentication()
# ----------------------

sub failedAuthentication() {
}

1;
