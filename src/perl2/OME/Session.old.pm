# OME::Session
# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
# Created from OMEpl (v1.20) package split.
#
# OMEpl credits
# -----------------------------------------------------------------------------
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# -----------------------------------------------------------------------------
# 
#

package OME::Session;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';

my $sessionLifetime = "3600";
my $tempDirectory     =   '/var/tmp/OME/';


sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self =  {
    	cgi                  => undef,  # A handle for the CGI object.
    	dataSource           => undef,  # the DBI datasource
    	dbHandle             => undef,  # the DBI database handle as returned by DBI->connect
	remoteAddr           => undef,  # the client's remote address ($ENV{REMOTE_ADDR}) or localhost
	user                 => undef,  # The user name.
	password             => undef,  # The user's password
	sessionID            => undef,  # The user's session info (long life).
	sessionKey           => undef,  # The client's state info (very short life).
	referer              => undef,  # The referrer from a redirect.
	OMEloginURL          => undef,
	OMEselectDatasetsURL => undef,
	errorMessage         => undef,
	SelectedDatasets     => undef,  # a reference to an array of dataset IDs in the user's session.
	CurrentAnalysisID    => undef
	};
    
    bless ($self, $class);
    $self->initialize(@_);
    $errorClass = $self;
    return $self;
}


sub initialize ()
{
    my $self = shift;
    my %params = @_;
    my $cgi;
    print STDERR "-----------------------------------------------------------------------------------------------\n";
    print STDERR "initialize:  Begin.\n";

    if (%params) {
	$self->{user} = $params{user} if exists $params{user};
	$self->{password} = $params{password} if exists $params{password};
	$self->{dataSource} = $params{dataSource} if exists $params{dataSource};
	$self->{sessionKey} = $params{sessionKey} if exists $params{sessionKey};
	$self->{referer} = $params{referer} if exists $params{referer};
	# print STDERR "initialize:  Parameter user=".$params{user}."\n";
	# print STDERR "initialize:  Parameter dataSource=".$params{dataSource}."\n";
	# print STDERR "initialize:  Parameter sessionKey=".$params{sessionKey}."\n";
    }

    if ($self->inWebServer())
    {
	$cgi = new CGI;
	$self->{cgi} = $cgi;

	my $script_name = $cgi->url(-relative => 1);
	# print STDERR "initialize:  script name (relative) <".$script_name.">\n";

	my $scriptNameRE = qr/$script_name/;
	my $scriptPath = $cgi->url(-path_info=>1);
	# print STDERR "initialize:  script path ".$scriptPath."\n";
	if ($scriptPath =~ /(.*)$scriptNameRE/) {
	    $OMEbaseURL = $1;
	}
	# print STDERR "initialize:  Base URL=".$OMEbaseURL."\n";
	$self->{OMEbaseURL} = $OMEbaseURL;
	$self->{OMEloginURL} = $OMEbaseURL.$LoginPage;
	$self->{OMEnavURL} = $OMEbaseURL.$NavPage;
	$self->{OMEselectDatasetsURL} = $OMEbaseURL.$SelectDatasetsPage;
	$self->{OMEsessionInfoURL} = $OMEbaseURL.$SessionInfoPage;
	$self->{OMEdefaultAnalysisURL} = $OMEbaseURL.$DefaultAnalysisPage;
	$self->{OMEhomePageURL} = $OMEbaseURL.$OMEhomePage;
	$self->{ViewDatasetsURL} = $OMEbaseURL.$ViewDatasetsPage;

	$self->{sessionKey} = $cgi->cookie ('OMEsessionKey') unless defined $self->{sessionKey};
	$self->{sessionKey} = $cgi->url_param ('Session') unless defined $self->{sessionKey};
	print STDERR "initialize:  Retreived OMEsessionKey cookie=",$self->{sessionKey},"\n" if defined $self->{sessionKey};
	$self->{referer} = $cgi->cookie ('OMEreferer') unless defined $self->{referer};
	print STDERR "initialize:  Retreived OMEreferer cookie=",$self->{referer},"\n" if defined $self->{referer};


	# Calling VerifySession with an invalid or undefined session is fatal.
	# We don't want to give up yet if we're in a browser.
	if (defined $self->{sessionKey} and $self->{sessionKey}) {
	    print STDERR "initialize:  Verifying sessionKey...";
	    eval {$self->VerifySession ();};
	    undef $self->{sessionKey} if $@;
	    # $self->{errorMessage} = $@;
	    print STDERR "Session verified with sessionKey.\n" if defined $self->{sessionKey};
	} elsif (defined $self->{user}) {
	    print STDERR "initialize:  Verifying using user/pass...";
	    eval {$self->Connect ();};
	    undef $self->{user} if $@;
	    print STDERR "initialize:  Session verified with user/pass.\n" if defined $self->{sessionKey};
	}

	# If the above didn't work, or we didn't have a sessionKey in the first place, try logging in.
	if (not defined $self->{sessionKey}) {
	    print STDERR "initialize:  No session info found - redirecting to login page.\n";
	    $self->Login ();
	}
    }

    else
    {
	# $self->{user} = $ENV{'USER'} unless defined $self->{user};
	if (defined $self->{sessionKey}) {
	    $self->VerifySession ();
	    print STDERR "initialize:  Session verified.\n";
	}
	else {
	    $self->Login ();
	}

    }

    # If we still don't have a sessionKey AND a dbHandle, then its time to call it quits.
    die "Could not generate a session ID: ".$self->{errorMessage}
    unless defined $self->{sessionKey} and $self->{sessionKey};

    die "Could not get a database connection: ".$self->{errorMessage}
    unless defined $self->{dbHandle} and $self->{dbHandle};


    # if ($self->gotBrowser() and (not defined $self->{referer} or not $self->{referer}) )
    # {
    # print STDERR "initialize:  Calling SetReferer\n";
    # $self->SetReferer();
    # }
    # If we are back to the referer, then clear it.
    if ($self->gotBrowser() and $self->{referer} and $self->{referer} eq $cgi->url(-relative=>1) ) {
	$self->{referer} = undef;
    }

    $self->{SelectedDatasets} = undef;
    $self->{CurrentAnalysisID} = undef;
    # print STDERR "initialize:  Calling SetExperimenterID\n";
    $self->{ExperimenterID} = $self->SetExperimenterID();
    $self->Commit();
    print STDERR "initialize:  Finished.\n";

}


sub VerifySession
{
    my $self = shift;
    my $sessionKey = $self->{sessionKey};
    die "Need a valid session ID for access." unless defined $sessionKey and $sessionKey;
    print STDERR "VerifySession:  Retreiving sessionKey=",$sessionKey," from Apache::Session::File\n";

    # FIXME:  This should be done in a daemon.
    CleanupSessions();


    my $session = $self->Session();

    # FIXME:  This is kind of messy:
    #	if ( ($self->inWebServer() and ($session{remoteAddr} ne $ENV{REMOTE_ADDR} ) ) or
    #		(not $self->inWebServer() and ($session{remoteAddr} ne "127.0.0.1" )) ){
    #			$self->{sessionKey} = undef;
    #			$self->{dbHandle} = undef;
    #			die "Could not validate session:  Session registered for a different client."
    #	}

    $self->{dataSource} = $session->{dataSource};
    $self->{remoteAddr} = $session->{remoteAddr};
    $self->{user} = $session->{user};
    $self->{password} = $session->{password};
    $self->{sessionID} = $session->{sessionID};
    $self->{sessionKey} = $session->{_session_id};
    #	$session->{lastAccess} = time;
    #	print STDERR "VerifySession:  Retreived sessionKey=",$sessionKey,"  User =",$self->{user}," Session ID=",$self->{sessionID},"\n";
    #	print STDERR "VerifySession:  Calling Connect\n";
    $self->{sessionKey} = $self->Connect();
    #	print STDERR "VerifySession:  Finished\n";
    return $self->{sessionKey};

}


sub Connect
{
    my $self = shift;
    my $session;
    my $id;
    my $dbHandle = $self->{dbHandle};

    # FIXME:  Need to add authentication from an https call, or with a certificate, etc.
    # If the sessionKey field is defined, but invalid, we die.
    # Eventually, we'll need to store everything we need to connect to the database.
    # Storing the DB handle itself doesn't seem to work.  Maybe there's a way to 'cache' it.
    # This gets called at the end of VerifySession.  We should call VerifySession in each method that
    # acesses the database.  Therefore, we should really speed this up by caching what we can.
    $self->{dataSource} = $DefaultDataSource unless defined $self->{dataSource};
    die "User undefined when trying to connect !" unless defined $self->{user} and $self->{user};
    if (not defined $dbHandle or not $dbHandle->ping()) {
	print STDERR "Connecting to ".$self->{dataSource}." as user ".$self->{user}."...\n";
	$dbHandle = DBI->connect($self->{dataSource}, $self->{user}, $self->{password},
				 { RaiseError => 1, AutoCommit => 1, InactiveDestroy => 1})
	    || die "Could not connect to the database: ".$DBI::errstr;
    }
    print STDERR "... Connected to ".$self->{dataSource}." as user ".$self->{user}."\n";

    $self->{dbHandle} = $dbHandle;
    if ($self->gotBrowser()) { $self->{remoteAddr} = $self->{cgi}->remote_host(); }
    elsif ($self->inWebServer() and not $self->gotBrowser()) { $self->{remoteAddr} = $ENV{REMOTE_ADDR}; }
    else { $self->{remoteAddr} = '127.0.0.1'; }

    #	DBI->trace(2);
    if (not exists $self->{sessionKey} or not defined $self->{sessionKey} or not $self->{sessionKey}) {
	print STDERR "Connect:  Getting new session\n";
	$session = $self->Session();
	$self->{sessionKey} = $session->{_session_id};
	$session->{user} = $self->{user};
	$session->{password} = $self->{password};
	$session->{dataSource} = $self->{dataSource};
	$session->{remoteAddr} = $self->{remoteAddr};
	$session->{sessionID} = $self->{sessionID};
	$self->Session($session);
    }
    print STDERR "Connect:  SessionKey = ".$self->{sessionKey}.".  Calling SetSID\n";
    $self->SetSID();

    print STDERR "Connect:  Finished.  Initiating transactions\n";
    $dbHandle->{AutoCommit} = 0;
    return ($self->{sessionKey});


}


sub Login ()
{
    my $self = shift;
    my $cgi = $self->{cgi};
    my $line;

    if ($self->gotBrowser())
    {
	# Where do we set the referer to?
	# If the referer was specified as a parameter, then we go there.
	# If the referer was specified in a cookie, then we ignore it, and return to where we are now.
	$self->SetReferer() unless defined $self->{referer} and $self->{referer} and $self->{referer} ne $cgi->cookie ('OMEreferer');
	$self->Redirect(-location=>$self->{OMEloginURL}, -target=>'_top');
    }
    elsif (not $self->inWebServer ()) # Read connection parameters out of the user's OMErc file (~/.OMErc).
    {
	my $OMErc = glob ("~/.OMErc");
	open (INPUT,"<  $OMErc") or die "Could not open $OMErc for reading: $!\n";
	while (	defined ($line = <INPUT>) ) {
	    chomp $line;
	    if ($line =~ /^OMEdb Connect:.*/) {
		if ($line =~ /dbname=(\S+)/)    { $self->{dataSource} = $DefaultDBI.'dbname='.$1; }
		if ($line =~ /user=(\S+)/)      { $self->{user} = $1;}
		if ($line =~ /password=(\S+)/)  { $self->{password} = $1;}
		if ($line =~ /datasource=(\S+)/){ $self->{dataSource} = $1;}
	    }
	}
	$self->{dataSource} = $DefaultDataSource unless defined $self->{dataSource};
	$self->{user} = $ENV{USER} unless defined $self->{user};
    } else {
	die "Login () does not have any way to authenticate the user.\n";
    }
    # Its fatal if this is defined and bogus.
    $self->{sessionKey} = undef;
    return $self->Connect();
}


sub Variables
{
    my $self = shift;
    my $param = shift;
    my %session;
    my $returnSession;
    my $ID;
    my ($key,$value);

    $ID = $self->{sessionKey} if exists $self->{sessionKey} and defined $self->{sessionKey};
    $ID = $param->{_session_id} if defined $param and exists $param->{_session_id} and defined $param->{_session_id};
    eval {tie %session, 'Apache::Session::File', $ID, {
	Directory => $tempDirectory.'sessions',
	LockDirectory   => $tempDirectory.'lock'
	};
      };
    die "Could not retreive session: $@" if ($@);
    while ( ($key,$value) = each (%$param) ) {
	$session{$key} = $value;
    }
    $returnSession = {%session};
    untie %session;
    undef %session;
    return ($returnSession);
}


sub CleanupSessionVariables
{
    my $self = shift;
    use File::Find;

    find(\&DeleteVariablesFile, $tempDirectory.'sessions');
}


sub DeleteVariablesFile
{
    my $sessionKey = $_;
    my %session;

    return unless defined $sessionKey;
    return unless -f $sessionKey;
    my $created = (stat($sessionKey))[8];
    return unless defined $created;
    my $age = time - $created;
    print STDERR "session '$sessionKey', is $age old.\n";
    return unless $age > $sessionLifetime;
    eval {tie %session, 'Apache::Session::File', $sessionKey, {
	Directory => $tempDirectory.'sessions',
	LockDirectory   => $tempDirectory.'lock'
	};
	  tied(%session)->delete unless ($@);
      };
    print STDERR "Delete unsucessfull because of: $@\n";
}

sub GetUserSessions
{
    my $self = shift;
    use File::Find;
    my @userSessions;
    my $user = $self->{user};

    my $isUserSessionFunc = sub {
	my $sessionKey = $_;
	my %session;
	return unless defined $sessionKey;
	my $created = (stat($sessionKey))[8];
	return unless defined $created;
	eval {tie %session, 'Apache::Session::File', $sessionKey, {
	    Directory => $tempDirectory.'sessions',
	    LockDirectory   => $tempDirectory.'lock'
	    };
	      return if $@;
	      push (@userSessions,$sessionKey) if $session{user} eq $user;
	  };
    };

    find($isUserSessionFunc, $tempDirectory.'sessions');
    return \@userSessions;

}


sub Commit
{
    my $self = shift;
    $self->{dbHandle}->commit if (defined $self->{dbHandle});
}


sub Rollback
{
    my $self = shift;
    $self->{dbHandle}->rollback if (defined $self->{dbHandle});
}



sub Finish
{
    my $self = shift;
    $self->Commit();

    # Update session info
    $self->StopProgress();


    $self->{dbHandle}->disconnect if (defined $self->{dbHandle});
    undef $self->{dbHandle};
    #	if (defined $self->Session and not $self->gotBrowser()) {
    #		$self->Session->delete;
    #	}
}


sub END
{
    my $self = shift;
    
    print STDERR "DESTRUCTOR:  DESTROY, Disconnecting\n";
    $self->{dbHandle}->disconnect if (defined $self->{dbHandle});
    $self->{dbHandle} = undef;
    print STDERR "DESTRUCTOR:  Deleting session\n";
    DeleteVariablesFile($self->{sessionKey});
    print STDERR "DESTRUCTOR:  Disconnected\n";
}


sub SetSID
{
    my $self = shift;
    my $sessionID;
    my $dbh = $self->{dbHandle};

    print STDERR "SetSID:  \n";
    $sessionID = $dbh->selectrow_array ("SELECT session_id FROM ome_sessions WHERE ome_name=? ORDER BY last_access desc limit 1",undef,$self->{user});
    if ($sessionID) {	
	print STDERR "SetSID:  Updating Session ID: $sessionID, host: ",$self->{remoteAddr},", sessionKey: ",$self->{sessionKey},"\n";
	$dbh->do ("UPDATE ome_sessions SET last_access = CURRENT_TIMESTAMP,  host = ?, session_key = ? WHERE session_id = $sessionID",undef,
		  $self->{remoteAddr}, $self->{sessionKey});
	print STDERR "SetSID:  Updated Session ID $sessionID\n";
    }

    else {
	$sessionID = $self->GetOID('SESSION_SEQ');
	# Insert the new session.  The columns 'last_access' and 'started' have default values of CURRENT_TIMESTAMP.
	print STDERR "SetSID:  New Session ID $sessionID\n";
	$dbh->do ("INSERT INTO ome_sessions (session_id,session_key,ome_name,host,dataset_view,feature_view) VALUES (?,?,?,?,?,?)",undef,
		  $sessionID, $self->{sessionKey}, $self->{user}, $self->{remoteAddr}, $DefaultDatasetView, $DefaultFeatureView
		  );
    }

    #	$dbh->commit();
    $self->{sessionID} = $sessionID;
    print STDERR "SetSID:  Session info unpdated\n";
    return $sessionID;
}

1;

