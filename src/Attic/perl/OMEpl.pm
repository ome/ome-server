# OMEpl.pm:  The OME Perl API.
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
# 
#
# Modifications Feb. 2001 by igg:
# Change all database access to DBI calls.
# Change the cookie and connection scheme.
#	One cookie is sent to the browser containing a session key (sessionKey).
#	The sesionKey is not to be confused with the sessionID.
#	sessionID maintains the user's preferences, etc across many connections from different clients.
#	In principle, a user can have the same sessionID for years.
#	The sessionKey on the other hand, identifies and maintains state for a connection from a single client.
#	It gets stored in a browser as a cookie (with a short lifetime), and gets returned to the client in an OME.Connect xmlrpc call.
#	The sessionKey must be sent as the first parameter in all xmlrpc calls other than OME.Connect
#	The sessionKey also gets stored in the OME_SESSIONS table in the SESSION_KEY column.
#	The sessionKey and other $session parameters are stored in Apache::Session.  Currently Apache::Session::File.
#	In effect, the sessionKey is used internally - there is no reason to mess with it in normal clients or servers.
#	The only exception to that is that it must be returned in every xmlrpc call (other than OME.Connect).
#	The other difference is that sessionKey is a string, while sessionID is an integer.
#	Added optional parameters to new(), like user, password, dataSource, and sessionKey.
#   Added gotBrowser() to check if there's a browser at the other end.
#	Simplified the connection scheme.  new() now does one of these:
#		Call VerifySession if we have a session ID.
#		Call Login if we want to log in using environment parameters (like ~/.OMErc, $ENV{USER}) or interactively with the user.
#		Call Connect once we're pretty sure we have all the right info.  Connect is the place to add certificate-based authentication.
#	Login and ValidateSession call Connect.  Connect returns a $sessionKey or dies.
#	Connect can also be called via xmlrpc.
# Get rid of the requirement for CPAN::Alias.

package OMEpl;
use strict;
use vars qw($VERSION);
$VERSION = '1.20';

=pod

=head1 OMEpl.pm - The OME Perl API.

Version 1.10, (c) Ilya G. Goldberg (igg@mit.edu)

=head1 Abstract

This documentation covers the perl OME API.  The purpose of the API is to provide an interface to the OME database
by performing mapping between the database relational model and a more object-oriented model useful for programming.
The documentation is split into several parts:
L<"Initialization">, L<"Session Management">, L<"Browser Navigation">, L<"Datasets and Dataset Selections">, L<"Analyses">, and L<"Miscelaneus Methods">.

=cut

use OMEfeature;
use OMEDataset;
my @knownDatasetTypes;

use OMEDataset::ICCB_TIFF;
push (@knownDatasetTypes,'ICCB_TIFF');
use OMEDataset::TIFF;
push (@knownDatasetTypes,'TIFF');
use OMEDataset::SoftWorx;
push (@knownDatasetTypes,'SoftWorx');
# FIXME:  It seems like there should be a better way of importing all supported datasets and knowing
# what they are without hard-coding them here.

use CGI qw (:html3);
#use CGI::Carp qw(fatalsToBrowser);
#set_message (\&handle_errors);

use Apache::Session::File;
use DBI;
use Sys::Hostname;
use Fcntl;
use File::Basename;

# Class data:
# The URLs will be constructed by prepending the OMEbaseURL to the specific pages.
my ($OMEbaseURL,$OMEloginURL,$OMEnavURL,$OMEselectDatasetsURL,$OMEsessionInfoURL,$OMEdefaultAnalysisURL,$OMEhomePageURL);
my $LoginPage           = "OMElogin.pl";
my $NavPage             = "OMEnav.pl";
my $SelectDatasetsPage  = "OMEselectDatasets.pl";
my $SessionInfoPage     = "OMEdisplayDatasets.pl";
my $DefaultAnalysisPage = "OMErunfindSpots.pl";
my $OMEhomePage         = "OMEanalyze.pl";
my $ViewDatasetsPage = "OMEDatasetView.pl";

my $sessionLifetime = "3600";

my $DefaultDataSource =   "dbi:Pg:dbname=ome";
my $DefaultDBI        =   "dbi:Pg:";

my $tempDirectory     =   '/var/tmp/OME/';
my $datasetDirectory  =   '/OME/Datasets/';
my $binPath           =   '/OME/bin/';

my $DefaultDatasetView = "SELECT name,path FROM datasets WHERE";
my $DefaultFeatureView = "location.attribute_of location.x location.y location.z";

my $OMEpreInited = undef;

my %SQLtypes_Postgres = (
# PostgreSQL  => SQL (ODBC)
	20   =>  8,	 # int8
	21   =>  5,	 # int2
	23   =>  4,	 # int4
	26   =>  8,  # OID type.
	700  =>  6,	 # float4
	701  =>  7,	 # float8
	1042 =>  1,	 # bpchar
	1043 => 12,	 # varchar
	1082 =>  9,	 # date
	1083 => 10,	 # time
	1296 => 11,	 # timestamp
	);

my $DATASETSDISPLAYLIMIT = 250;
my $SQLLISTLIMIT = 1000;


my $errorClass;
$SIG{'USR2'} = sub { 
my $self = $errorClass;

	if (defined $self) {
		my $session = $self->Session;
		my $analysis;
		if (not exists $session->{Analyses}->{$$} or not defined $session->{Analyses}->{$$}) {
			my %analysisInfo;
			$analysisInfo{ProgramPID} = $$;
			$analysisInfo{ProgramName} = $0;
			$analysisInfo{Status} = undef;
			$analysisInfo{Error} = undef;
			$session->{Analyses}->{$$} = {%analysisInfo};
		}
		$analysis = $session->{Analyses}->{$$};
		if (not ($analysis->{Status} eq 'Finished')) {
			$analysis->{Status} = 'Aborted';	
			$analysis->{Error} = 'Analysis aborted by user.';
			$self->Session ($session);
		} else {
			return;
		}
	}
	die "Analysis aborted by user.";
};

# Trap the die call.
$main::SIG{__DIE__} = sub {
my ($message) = @_;
my $htmlMessage;
my $self = $errorClass;
my $mod_perl = exists $ENV{MOD_PERL};
my $browser = exists $ENV{HTTP_USER_AGENT};
my $i = 0;
my $isEval = 0;
my ($pack,$file,$line,$sub);

# This here is to see if we're in an eval.
# an eval in the main package or in Apache::Registry doesn't count - meaning we process it here.
	do  {
		($pack,$file,$line,$sub) = caller $i;
		if ($sub eq '(eval)') {
			$isEval = 1;
			$isEval = 0 if $pack eq 'main';
			$isEval = 0 if $pack eq 'Apache::Registry';
		}
		$i++;
	} while ($pack and not $isEval);

	CORE::die($message) if $isEval;
	($pack,$file,$line,$sub) = caller 0;
	my $location = "at $file line $line"; 
	$message .= " $location." unless $message=~/$location/;

	if (defined $self) {
		my $session = $self->Session;
		my $analysis;
		if (not exists $session->{Analyses}->{$$} or not defined $session->{Analyses}->{$$}) {
			my %analysisInfo;
			$analysisInfo{ProgramPID} = $$;
			$analysisInfo{ProgramName} = $0;
			$analysisInfo{Status} = undef;
			$analysisInfo{Error} = undef;
			$session->{Analyses}->{$$} = {%analysisInfo};
		}
		$analysis = $session->{Analyses}->{$$};
		if (not defined $analysis->{Status} or not $analysis->{Status} or not $analysis->{Status} eq 'Finished' or not $analysis->{Status} eq 'Aborted' ) {
			$analysis->{Status} = 'Error';	
			$analysis->{Error} = $message;
			$self->Session ($session);
		} elsif ($analysis->{Status} eq 'Finished') {
			return;
		}
	} else {
		$message .= "\nCould not store session status - OME object is undefined.\n";
	}


	$htmlMessage = $message;
    $htmlMessage=~s/&/&amp;/g;
    $htmlMessage=~s/>/&gt;/g;
    $htmlMessage=~s/</&lt;/g;
    $htmlMessage=~s/\"/&quot;/g;
	$htmlMessage = '<h2>Error:</h2><pre>'.$htmlMessage.'</pre>';
	print STDOUT "Content-type: text/html\n\n" 
		if not $mod_perl and $browser;
	if ($mod_perl && (my $r = Apache->request)) {
	# If bytes have already been sent, then
	# we print the message out directly.
	# Otherwise we make a custom error
	# handler to produce the doc for us.
		if ($r->bytes_sent) {
			$r->print($htmlMessage);
		} else {
			$r->status(500);
			$r->custom_response(500,$htmlMessage);
		}
	} elsif ($browser) {
		print STDOUT $htmlMessage;
	} else {
		print STDERR $message;
	}
	CORE::die($message);
};


=pod

=head2 Initialization

Methods used in the construction of the OME object.  Normally, it is sufficient to do something like:

 my $OME = new OMEpl;

B<Method List:>

C<new()>, C<VerifySession()>, C<Connect()>, C<Login()>

=over 4

X<new()>

=item new()

If this is a local call (no web browser or other user agent), get connection info from the user's ~/.OMErc.
If we have an interactive browser, then get the sessionID from a cookie, or re-direct to the login page.
This is the prefered style of calling the new() method.

B<Examples:>

=over 4

=item new OMEpl ( sessionKey => 'a session key string')

The sessionKey will be checked for validity - an invalid L<sessionKey> is fatal.
This style is used to re-connect to a saved session.  Use this when reconnecting without cookies (i.e. xmlrpc).

=item new OMEpl ( user => 'username', password => 'password')

These parameters will be ignored if we can get a L<sessionKey> cookie from the browser (or have a L<sessionKey> parameter).
Otherwise, they will be used to make a connection to the default datasource in the $DefaultDataSource package global.
We call die if this fails.

=item new OMEpl ( user => 'username', password => 'password', dataSource => 'a DBI data source')

These parameters will be ignored if we can get a L<sessionKey> cookie from the browser (or have a L<sessionKey> parameter).
Otherwise, they will be used to make a connection to the specified DBI datasource.
We call die if this fails.

=back

Internally, there are two ways to make a connection:  C<VerifySession()> and C<Login()> - these get called by the C<new()> method.
If a L<sessionKey> is passed as a parameter to new() or the new() method can get a L<sessionKey> from a browser cookie (OMEsessionKey),
then C<VerifySession()> is called.  Otherwise, new() calls C<Login()>.  The call to C<VerifySession()> is encased in an eval statement,
so that if the cookie is expired or invalid (which is normally fatal in C<VerifySession()>), new() calls C<Login()>.


=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
    	cgi                    => undef,  # A handle for the CGI object.
    	dataSource             => undef,  # the DBI datasource
    	dbHandle               => undef,  # the DBI database handle as returned by DBI->connect
		remoteAddr             => undef,  # the client's remote address ($ENV{REMOTE_ADDR}) or localhost (127.0.0.1).
		user                   => undef,  # The user name.
		password               => undef,  # The user's password
		sessionID              => undef,  # The user's session info (long life).
		sessionKey             => undef,  # The client's state info (very short life).
		referer                => undef,  # The referrer from a redirect.
		OMEloginURL            => undef,
		OMEselectDatasetsURL   => undef,
		errorMessage           => undef,
		SelectedDatasets       => undef,  # a reference to an array of dataset IDs in the user's session.
		CurrentAnalysisID      => undef
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
#	print STDERR "initialize:  Parameter user=".$params{user}."\n";
#	print STDERR "initialize:  Parameter dataSource=".$params{dataSource}."\n";
#	print STDERR "initialize:  Parameter sessionKey=".$params{sessionKey}."\n";
	}
	
	if ($self->inWebServer())
	{
		$cgi = new CGI;
		$self->{cgi} = $cgi;

		my $script_name = $cgi->url(-relative => 1);
#	print STDERR "initialize:  script name (relative) <".$script_name.">\n";

		my $scriptNameRE = qr/$script_name/;
		my $scriptPath = $cgi->url(-path_info=>1);
#	print STDERR "initialize:  script path ".$scriptPath."\n";
		if ($scriptPath =~ /(.*)${scriptNameRE}/){ $OMEbaseURL = $1;}
#	print STDERR "initialize:  Base URL=".$OMEbaseURL."\n";
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


	# Calling VerifySession with an invalid or undefined session is fatal.  We don't want to give up yet if we're in a browser.
		if (defined $self->{sessionKey} and $self->{sessionKey}) {
			print STDERR "initialize:  Verifying sessionKey...";
			eval {$self->VerifySession ();};
			undef $self->{sessionKey} if $@;
#			$self->{errorMessage} = $@;
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
#		$self->{user} = $ENV{'USER'} unless defined $self->{user};
		if (defined $self->{sessionKey}) {
			$self->VerifySession ();
			print STDERR "initialize:  Session verified.\n";
		}
		else {
			$self->Login ();
		}

	}

# If we still don't have a sessionKey AND a dbHandle, then its time to call it quits.
	die "Could not generate a session ID: ".$self->{errorMessage} unless defined $self->{sessionKey} and $self->{sessionKey};
	die "Could not get a database connection: ".$self->{errorMessage} unless defined $self->{dbHandle} and $self->{dbHandle};


#	if ($self->gotBrowser() and (not defined $self->{referer} or not $self->{referer}) )
#	{
#		print STDERR "initialize:  Calling SetReferer\n";
#		$self->SetReferer();
#	}
# If we are back to the referer, then clear it.
	if ($self->gotBrowser() and $self->{referer} and $self->{referer} eq $cgi->url(-relative=>1) ) {
		$self->{referer} = undef;
	}

	$self->{SelectedDatasets} = undef;
	$self->{CurrentAnalysisID} = undef;
#	print STDERR "initialize:  Calling SetExperimenterID\n";
	$self->{ExperimenterID} = $self->SetExperimenterID();
	$self->Commit();
	print STDERR "initialize:  Finished.\n";

}

=pod

=item VerifySession()

This methods sets the DB handle (and user and password, etc) based on Apache::Session and L<sessionKey>.
This method gets called by C<new()> if it gets a L<sessionKey> from the browser, parameter, URL, etc.
This method calls C<Connect()> at the end and returns the L<sessionKey>.
If the L<sessionKey> is invalid, we die.  C<Connect()> will also die if the connection could not be made.

=cut



sub VerifySession {
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

=pod

=item Connect()

The idea here is that we connect based on what is in the OME object, or what can be determined from the web server, or from
the environment.  This non-interactive method gets called at the end of C<Login()> and at the end of C<VerifySession()>,
which in-turn get called by C<new()>.
These methods are supposed to provide whatever Connect() needs to connect to the database (i.e. username and password).
If Connect() cannot connect to a database, it calls die().  After making a database connection, it gets a L<sessionKey>.
If the L<sessionKey> field is already set in the object, but can't be retreived from Apache::Session, then it calls die().
If the L<sessionKey> field is undef, then it generates a new Apache::Session.
It stores the parameters needed to connect to the database
in the Apache::Session.  After this, it calls C<SetSID()> to update/set the OME user's session, and returns the L<sessionKey>.

Some decision has to be made to decide where a certificate (i.e. X509) should be checked - in Connect() or Login().  
Probably here because Login() is potentially interactive, whereas Connect() is not.
There should normally be no reason to call this function, as it gets called by C<new()> via C<VerifySession()> or C<Login()>.

=cut

sub Connect {
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

=pod

=item Login()

This method is used to collect user information from the user - either interactively in a browser or from (~/.OMErc).
This method gets called by C<new()> when it can't get its hands on a L<sessionKey>.

This method should be over-ridden depending on the interface you're setting up.
i.e.  If you want to prompt the user for login information, over-ride this method.
See F<OMEwebLogin.pm> and F<OMELogin.pl> for an exaple.
The Login method should return sessionKey by calling Connect at the end.
The default behavior is to re-direct the browser to a login page if there is a browser.
If there is no browser or ~/.OMErc, then this method calls die.

=cut




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


#sub DESTROY {
#print "Destroying the OME object\n";
#	my $self = shift;
#
#	$self->Commit();
#}



=pod

=back

=head2 Session Management

Methods used to manage user sessions, persistent variables, etc.

B<Method List:>

C<Session()>, C<Commit()>, C<Rollback()>, C<Finish()>, C<SetSID()>, C<RefreshSessionInfo()>

=over 4

=item Session()

Manages a persistent hash referenced by $self->L<sessionKey> by using Apache::Session.
Gets a new session from Apache::Session if there is no parameter and $self->L<sessionKey> is undef.
Gets a new session from Apache::Session if there is a prameter hash reference, but the _session_id key doesn't exist or is undef.
Gets an existing session if not making a new session - _session_id key in the parameter hash ref overrides $self->L<sessionKey>.
Calls die if tries to fetch an existing session but it doesn't exist.
Copies keys and values in the passed hash ref (if any) to the tied session hash, 
unties the session, and 
returns a reference to the untied hash.

B<Examples>:

 my $session = $OME->Session();
 $session->{myPersistentVariable} = $someScalar;
 $OME->Session ($session);
 
some time later...

 my $session = $OME->Session();
 my $recoveredScalar = $session->{myPersistentVariable};

=cut

sub Session {
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

#
# I suppose we can just erase the old files, but we're going to use Apache::Session to do it.
# We avoid death in Apache::Session by using eval - ignoring any errors.
sub CleanupSessions {
my $self = shift;
use File::Find;

    find(\&DeleteOMEsession, $tempDirectory.'sessions');
	
}


sub DeleteOMEsession {
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

sub GetUserSessions {
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


=pod

=item Commit()

Call this method to commit the current transaction to the database - before calling C<Finish()>.
Do not call this method unless you can guarantee that you will not leave the database in an invalid state.

=cut

sub Commit ()
{
my $self = shift;
#print "Commiting work to database\n";
	$self->{dbHandle}->commit if (defined $self->{dbHandle});
}

=pod

=item Rollback()

Call this method to revert the database to a state prior to calling C<new()>, C<Commit()> or C<Finish()>.

=cut

sub Rollback ()
{
my $self = shift;
	$self->{dbHandle}->rollback if (defined $self->{dbHandle});
}


=pod

=item Finish()

This method B<must> be called when you are finished using the OME object.
Failure to do so will leave you database handles untidy, and your work will not be commited to the database.

=cut

sub Finish ()
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

sub END {
	my $self = shift;

	print STDERR "DESTRUCTOR:  DESTROY, Disconnecting\n";
	$self->{dbHandle}->disconnect if (defined $self->{dbHandle});
	$self->{dbHandle} = undef;
	print STDERR "DESTRUCTOR:  Deleting session\n";
	DeleteOMEsession($self->{sessionKey});
	print STDERR "DESTRUCTOR:  Disconnected\n";
}

=pod

=item SetSID()

B<Internal use>.  Writes the session key into the database, and maintains persistance for the user's session (sessionID).
If there is a session for the user in the database, we update the session_key and the last_access columns.
If there is no user found, we do an INSERT.

=cut

sub SetSID ()
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

=pod

=item RefreshSessionInfo()

This method directs the session information frame to be refreshed.  Call this after calling C<SetSelectedDatasets()> for instance.

=cut

sub RefreshSessionInfo {
my $self = shift;

	return unless $self->gotBrowser;
	print $self->CGIheader (-type=>'text/html');
	print qq {
		<script language="JavaScript">
			<!--
				top.SessionFrame.location.reload();
			//-->
		</script>
		}	
}






=pod

=back

=head2 Browser Navigation

Methods to redirect the browser to various places.  These have no effect if there is no browser, but some of these do not return.

B<Method List:>

C<Redirect()>, C<ReturnHome()>, C<SetReferer()>, C<Return_to_referer()>, C<SelectDatasets()>, C<RefreshSessionInfo()>

=over 4

=cut

sub Redirect_old()
{
my $self = shift;
my %params = @_;

	$params{-cookie} = [$self->RefererCookie,$self->SIDcookie];
	$self->Finish();
	print STDERR "Redirect:  Redirecting to: <".$params{-location}.">\n";
	print $self->{cgi}->redirect (%params);
	exit (0);

}

=pod

=item Redirect()

Use this method to send the browser to another page.  Call C<Return_to_referer()> to get back to the page that called Redirect().
This method does not return.

 $OME->Redirect (-location=>'http://foo.bar.com');
 $OME->Redirect (-location=>'AnotherScript.pl');

=cut
 
sub Redirect {
my $self = shift;
return unless $self->gotBrowser;
my %params = @_;
my $URL = $params{-location};

	$self->SetReferer() unless defined $self->{referer} and $self->{referer};
	print $self->CGIheader (-type=>'text/html');
	print qq {
		<script language="JavaScript">
			<!--
				location = "$URL";
			//-->
		</script>
		};
	$self->{dbHandle}->disconnect if (defined $self->{dbHandle});
	undef $self->{dbHandle};
	exit (0);
	
}

=pod

=item ReturnHome()

Use this method if you're done, and don't want to draw another page.
This will send the browser to the URL specified by L<OMEhomePageURL>.

=cut

sub ReturnHome()
{
my $self = shift;

	self->Redirect(-location=>$self->{OMEhomePageURL});
}

=pod

=item SetReferer()

This will set the page that C<Return_to_referer()> will return to next time it is called.
Since this accepts no parameters, it can only be used for returning to the current script.

=cut

sub SetReferer ()
{
	my $self = shift;
#	$self->{referer} = $self->{OMEhomePageURL};
#	$self->{referer} = $self->{cgi}->url(-relative=>1);
	$self->{referer} = $self->{cgi}->self_url;
	print STDERR "SetReferer:  setting self->{referer} to <",$self->{referer},">\n";
}

sub Return_to_referer_old()
{
	my $self = shift;
	my $referer = $self->{referer};
	
	if ($referer)
	{
		$self->{referer} = undef;
	# This never returns:
		$self->Redirect(-location=>$referer, -target=>'_top');
	}
}

sub Return_to_referer_old3 {
my $self = shift;
	$self->Redirect(-location=>$self->{OMEhomePageURL});
}

=pod

=item Return_to_referer()

Call this method to go back to the referencing page.

=cut

sub Return_to_referer {
my $self = shift;

	return unless $self->gotBrowser;
	$self->{referer} = $self->{OMEhomePageURL} unless defined $self->{referer} and $self->{referer};
	my $URL = $self->{referer};
	print $self->CGIheader (-type=>'text/html');
	print qq {
		<script language="JavaScript">
			<!--
				location = "$URL";
			//-->
		</script>
		};
	$self->{dbHandle}->disconnect if (defined $self->{dbHandle});
	undef $self->{dbHandle};
	exit (0);
}



=pod

=back

=head2 Datasets and Dataset Selections

Methods to select datasets, return user selections, import datasets, etc.
B<Method List:>

C<GetSelectedDatasetIDs()>, C<GetSelectedDatasetObjects()>, C<GetDatasetObjects()>,
C<SelectDatasets()>, C<SetSelectedDatasets>, C<DatasetsTableHTML()>

=over 4

=cut




=pod

=item GetSelectedDatasetIDs()

This method returns a reference to an array of dataset IDs selected by the user.

=cut

sub GetSelectedDatasetIDs()
{
	my $self = shift;
	my $row;
	my $sth;
	my @selectedDatasets;
	my $selectedDatasetsRef=undef;

	$sth = $self->{dbHandle}->prepare ("SELECT dataset_id FROM ome_sessions_datasets WHERE SESSION_ID=?");
	$sth->execute( $self->{sessionID} );
	$sth->bind_columns(\$row);
	while ( $sth->fetch ) {
		push (@selectedDatasets,$row);
	}
	undef $sth;
	undef $row;
	
	$selectedDatasetsRef = \@selectedDatasets if ($selectedDatasets[0]);

	$self->{SelectedDatasets} = $selectedDatasetsRef;
	return $selectedDatasetsRef;
}

#
# GetSelectedDatasets
# FIXME:  This method should return objects.  GetSelectedDatasetIDs should return IDs
sub GetSelectedDatasets()
{
my $self = shift;

	return $self->GetSelectedDatasetIDs();
}


=pod

=item GetSelectedDatasetObjects()

Returns an array of dataset objects selected by the user.

=cut

sub GetSelectedDatasetObjects () {
my $self = shift;

	return $self->GetDatasetObjects ($self->GetSelectedDatasetIDs());
}



sub GetSelectedDatasetsWavelengths () {
#	select distinct wave from attributes_iccb_tiff where dataset_id = ome_sessions_datasets.dataset_id
	my $self = shift;
	my $row;
	my $sth;
	my @wavelengths;

	$sth = $self->{dbHandle}->prepare (
		"SELECT DISTINCT attributes_iccb_tiff.wave ".
			"FROM attributes_iccb_tiff,ome_sessions_datasets ".
			"WHERE attributes_iccb_tiff.dataset_id = ome_sessions_datasets.dataset_id ".
			"AND ome_sessions_datasets.SESSION_ID=".$self->{sessionID});
	$sth->execute();
	$sth->bind_columns(\$row);
	while ( $sth->fetch ) {
		push (@wavelengths,$row);
	}


	$sth = $self->{dbHandle}->prepare (
		"SELECT DISTINCT dataset_wavelengths.em_wavelength ".
			"FROM dataset_wavelengths,ome_sessions_datasets ".
			"WHERE dataset_wavelengths.dataset_id = ome_sessions_datasets.dataset_id ".
			"AND ome_sessions_datasets.SESSION_ID=".$self->{sessionID});
	$sth->execute();
	$sth->bind_columns(\$row);
	while ( $sth->fetch ) {
		push (@wavelengths,$row);
	}

	undef $sth;
	
	return \@wavelengths;
}

=pod

=item GetDatasetObjects()

This method will return an array of Dataset objects, with all known fields filled in.
The required parameter is a reference to an array of dataset IDs.

=cut

sub GetDatasetObjects {
my $self = shift;
my $selectedDatasetIDs = shift;
my @datasets;
my $datasetID;

	die "Attempt to call GetDatasetObjects without the required reference to an array of dataset IDs.\n"
		unless defined $selectedDatasetIDs;
	foreach $datasetID (@$selectedDatasetIDs) {
		push (@datasets,$self->NewDataset (ID => $datasetID));
	}

	return \@datasets;
	
}


=pod

=item SelectDatasets()

This method does a redirect to the dataset selection form if we're in a browser.

=cut

sub SelectDatasets()
{
	my $self = shift;
	if ($self->gotBrowser())
	{
	   $self->SetReferer();
	   $self->Redirect (-location=>$self->{OMEselectDatasetsURL});
	}
}


=pod

=item SetSelectedDatasets()

Given a reference to a list of dataset IDs, this method will set the user's selection in the database.
This method is not called from within the OMEpl package - it is solely an end-user method.

=cut

sub SetSelectedDatasets()
{
	my $self = shift;
	my $datasets = shift;
	my $datasetID;
	my $SID = $self->{sessionID};
	return unless defined $datasets and $datasets and scalar @$datasets > 0;
# Delete the previously selected datasets
	$self->{dbHandle}->do ("DELETE FROM ome_sessions_datasets WHERE session_id = $SID");
	$self->{SelectedDatasets} = undef;

	my $sliceStart = 0;
	my $maxDSidx = scalar (@$datasets)-1;
	my $sliceStop = $maxDSidx;
	if ($sliceStop > $SQLLISTLIMIT) {$sliceStop = $SQLLISTLIMIT - 1;}
	while ($sliceStop <= $maxDSidx) {
		my @datasetSlice = @$datasets[$sliceStart .. $sliceStop];
# Only copy unique datasets that exist in the datasets table.
		$self->DBIhandle->do(
			"INSERT INTO ome_sessions_datasets (session_id,dataset_id) ".
			"SELECT DISTINCT $SID,datasets.dataset_id WHERE datasets.dataset_id IN (".join (',',@datasetSlice).')');
		$sliceStart = $sliceStop + 1;
		$sliceStop += $SQLLISTLIMIT;
		$sliceStop = $maxDSidx if ($sliceStop > $maxDSidx);
		$sliceStop = $maxDSidx + 1 if ($sliceStart > $maxDSidx);
		push (@{$self->{SelectedDatasets}},@datasetSlice);
	}

#	$self->Commit();
	$self->SetSessionProjectID();
	$self->RefreshSessionInfo();
	
	return $self->{SelectedDatasets};
}

=pod

=item DatasetsTableHTML()

Returns an HTML table (as a string) of the session's selected datasets with the user's chosen info.
The columns displayed in this table are defined in the table.column OME_SESSIONS.DATASET_VIEW.

B<Parameters:>

=over 4

=item DatasetIDs => [1,2,3,4]

Will make a table of the selected dataset IDs only.  The default is the user-selected datasets.

=item Limit => 123

If this parameter exists, but is 0 or undef, then display all datasets.
If this parameter is a non-zero integer, limit the display to that many datasets.
If the parameter does not exist, the limit is $OME->DatasetsDisplayLimit;
This does not apply if the DatasetIDs parameter is set.

=item CGItableParams => {}

A reference to a hash containing parameters that will be passed directly to Perl's CGI->table method.
Default is {-border=>1,-cellspacing=>1,-cellpadding=>1}.

=item SupressLinks

If this parameter exists and is defined and true, will supress links to OMEDatasetView in the table.
Default is to make entries in the 'name' column (not case-sensitive) links to OMEDatasetView
targeted to a new window to display an image of the dataset.  If there is no name column, the first column will be used for the links.

=back

B<Example:>

 $OME->DatasetsTableHTML ();
 $OME->DatasetsTableHTML ( DatasetIDs=>[1,2,3,4,5], CGItableParams => {-border=>0} );
 
N.B.:  This returns the HTML table ONLY - not a full HTML page.

=cut

sub DatasetsTableHTML {
my $self = shift;
my %params = @_;
my $limit = $self->DatasetsDisplayLimit();
my $datasetIDs;
my @datasetRows;
my $datasetViewSQL;
my $dbh = $self->DBIhandle();
my $CGI = $self->cgi();
my $viewDatasetsURL = $self->ViewDatasetsURL().'?ID=';
my $datasetView = $dbh->selectrow_array("SELECT dataset_view FROM ome_sessions WHERE session_id=".$self->SID);
my $dropTable;

	die "Could not determine Dataset view from database\n" unless defined $datasetView and $datasetView;
	$datasetView =~ s/FROM/, datasets.dataset_id AS link_id FROM/i;

	$limit = $params{Limit} if exists $params{Limit};
	$limit = undef if $limit < 1;
	
	$datasetIDs = $params{DatasetIDs} if exists $params{DatasetIDs};
	if (not defined $datasetIDs or not defined $datasetIDs->[0] or not $datasetIDs->[0]) {
		$datasetViewSQL = $datasetView.' datasets.dataset_id=ome_sessions_datasets.dataset_id AND ome_sessions_datasets.session_id='.$self->SID;
		$datasetViewSQL .= ' ORDER BY datasets.name';
		$datasetViewSQL .= ' LIMIT '.$limit if defined $limit;
	} else {
		if (scalar (@$datasetIDs) < $SQLLISTLIMIT) {
			$datasetViewSQL = $datasetView.' datasets.dataset_id in ('.join (',',@$datasetIDs).') ORDER BY datasets.name';
		} else {
			$self->DBIhandle->do ('CREATE TEMPORARY TABLE foobar (dataset_id OID)');
			foreach (@{$params{DatasetIDs}}) {
				$self->DBIhandle->do ("INSERT INTO foobar VALUES ($_)");
			}
			$datasetViewSQL = $datasetView.' datasets.dataset_id in (SELECT dataset_id FROM foobar) ORDER BY datasets.name';
			$dropTable = 1;
		}
	}
	
print STDERR "OME:DatasetsTableHTML:Executing <$datasetViewSQL>\n";
	my $sth = $dbh->prepare($datasetViewSQL);
	$sth->execute();
	my @tuple;
	my $idColumn = $#{$sth->{NAME}};
	my $colNum=0;
	my $linkColumn=0;
	foreach (@{$sth->{NAME}}) {push (@tuple,$_)};
	pop @tuple;
	$datasetRows[0] = $CGI->th(\@tuple);
	foreach (@tuple) {
		my $colName = uc ($_);
		if ( ($colName eq 'NAME') or ($colName eq 'DATASETNAME') or ($colName =~ m/DATASET.NAME/) ) {$linkColumn = $colNum;}
		$colNum++;
	}

	while ( @tuple = $sth->fetchrow_array() ) {
		$tuple[$linkColumn] = $CGI->a({-href=>$viewDatasetsURL.$tuple[$idColumn],-target=>'ViewDatasetWindow'},$tuple[$linkColumn]);
		pop (@tuple);
		push (@datasetRows,$CGI->td(\@tuple));
	}

	$self->DBIhandle->do ('DROP TABLE foobar') if defined $dropTable;

	my $CGItableParams = {-border=>1,-cellspacing=>1,-cellpadding=>1};
	$CGItableParams = $params{CGItableParams} if exists $params{CGItableParams} and defined $params{CGItableParams} and $params{CGItableParams};
	return $CGI->table($CGItableParams,
			$CGI->Tr(\@datasetRows));

}


sub DatasetsDisplayLimit {
my $self = shift;
	return $DATASETSDISPLAYLIMIT;
}

=pod

=back

=head2 Analyses

These are methods to initiate an analysis, read and write results, etc.

B<Method List:>

C<StartAnalysis()>, C<RegisterAnalysis()>, C<WriteFeatures()>

=over 4

=item StartAnalysis()

Call this method whenever you are about to analyze some datasets.
Basically, this does some initialization things, starts a transaction, and sets up a way to keep track of your analysis while
its crunching away on datasets.

=cut

sub StartAnalysis()
{
	my $self = shift;
	my $full_url;

	if ($self->inWebServer()) {$full_url = $self->{cgi}->url(-relative=>1);}
	else {$full_url = $ENV{'PWD'}."/".$0;}

	$self->{dbHandle}->do ("UPDATE ome_sessions SET analysis = ? WHERE SESSION_ID = ?",undef,
		$full_url, $self->{sessionID});
	$self->{SelectedDatasets} = undef;
#	if (not defined $self->GetSelectedDatasetIDs()) {
#		$self->SelectDatasets;
#	}
#	
#	$self->GetSelectedDatasetIDs();
#	die "Attempt to start an analysis without selecting datasets." unless defined $self->{SelectedDatasets};

	$self->Commit();
	
	$self->TrackProgress();

#	my %Analysis_Data = (
#		AnalysisID => undef,
#		ProgramID => undef,
#		InputTableName => undef,
#		ExperimenterID => undef,
#		DatasetID => undef,
#		Status => undef
#		);

}




=pod

=item TrackProgress()

This method initiates a progress tracker.  By default, the number of total number of items is set to C<NumSelectedDatasets()>.
The number of items processed are set by calling C<IncrementProgress()>.
The total number of items can be sent as an integer parameter.  This method is called by C<StartAnalysis()>, so one normally
does not need to call it unless you are processing something that can fail and will take some time, but is not in fact an
OME analysis.  One example of this use is during Dataset import.

B<Examples:>

 # Begin tracking progress with total number of items set to the number of user-selected datasets.
   $OME->TrackProgress ();
   foreach (@datasets) {
     # Do some stuff
     ...
     $OME->IncrementProgress();
   }
 # Begin tracking progress with total number of items set to 123:
   $OME->TrackProgress (123);
   foreach (@items) {
     # Do some stuff
     ...
     $OME->IncrementProgress();
   }

=cut

sub TrackProgress()
{
my $self = shift;
my $numItems = shift;
	
	my $session = $self->Session;
	my %analysis;
	$analysis{ProgramPID} = $$;
	$analysis{ProgramStarted} = time;
	$analysis{ProgramName} = $0;
	$analysis{ProgramID} = undef;
	$analysis{Status} = 'Executing';
	$analysis{Message} = '';
	$analysis{Error} = '';
	if (defined $numItems) {
		$analysis{NumSelectedDatasets} = $numItems;
	} else {
		$analysis{NumSelectedDatasets} = $self->NumSelectedDatasets();
	}
	$analysis{NumDatasetsCompleted} = 0;
	$analysis{CurrentAnalysisID} = undef;
	$analysis{CurrentDatasetID} = undef;	
	$analysis{LastCompletedDatasetID} = undef;
	$analysis{LastCompletedDatasetTime} = undef;
	$analysis{AverageTimePerDataset} = undef;
	$analysis{TimeFinished} = undef;
	$session->{Analyses}->{$$} = {%analysis};
	$self->Session ($session);
}


=pod

=item IncrementProgress()

Once TrackProgress has been called, call IncrementProgress once for each 'item'.
This method is also called by C<WriteFeatures()>.  If the item count reaches the total number of items,
C<StopProgress()> is called automatically.  See also C<TrackProgress()> and C<UpdateProgress>.

=cut

sub IncrementProgress
{
my $self = shift;

	my $session = $self->Session;
	return unless exists $session->{Analyses};
	return unless exists $session->{Analyses}->{$$};
	my $analysis = $session->{Analyses}->{$$};
	$analysis->{CurrentAnalysisID} = undef;
	$analysis->{LastCompletedDatasetID} = $analysis->{CurrentDatasetID};
	$analysis->{LastCompletedDatasetTime} = time;
	$analysis->{NumDatasetsCompleted}++;
	$analysis->{AverageTimePerDataset} = ($analysis->{LastCompletedDatasetTime} - $analysis->{ProgramStarted}) / $analysis->{NumDatasetsCompleted};

	$analysis->{CurrentDatasetID} = undef;
	if ($analysis->{NumDatasetsCompleted} ge $analysis->{NumSelectedDatasets}) {
		$self->StopProgress();
	}
	$self->Session($session);
}

=pod

=item UpdateProgress()

Call this to update progress info without incrementing the item count.  This is called from C<RegisterAnalysis>.
Named parameters passed in here are written directly to the progress info for this session.

B<Examples:>

 UpdateProgress(Error => 'Help me!');
 UpdateProgress(Message => 'Hi there!');
 UpdateProgress(ProgramName => 'SomeBigProgram');

Note that anything sent in the Error parameter will be appended to the existing contents of the Error field (if any).
All other fields will be set to the passed-in value.
 	

=cut

sub UpdateProgress
{
my $self = shift;
my %params = @_;
my ($key,$value);

	my $session = $self->Session;
	return unless exists $session->{Analyses};
	return unless exists $session->{Analyses}->{$$};
	my $analysis = $session->{Analyses}->{$$};
	while ( ($key,$value) = each %params ) {
		if ($key eq 'Error' and defined $analysis->{Error} and $analysis->{Error}) {
			$analysis->{$key} .= "\n------------\n$value";
		} else {
			$analysis->{$key} = $value;
		}
	}
	$self->Session($session);
}

=pod

=item StopProgress()

Terminates progress tracking.  Records the time, and sets the Status field to 'Finished'.

=cut

sub StopProgress
{
my $self = shift;
	my $session = $self->Session;
	return unless exists $session->{Analyses};
	return unless exists $session->{Analyses}->{$$};
	my $analysis = $session->{Analyses}->{$$};

	$analysis->{Status} = 'Finished' if defined $analysis->{Status} and $analysis->{Status} eq 'Executing' ;
	$analysis->{TimeFinished} = time;
	$self->Session($session);
}


=pod

=item RegisterAnalysis()

This method is called to register an analysis with OME.  It must be called once per analyzed dataset.
Required parameters are the
programName or programID, the datasetID, and the parameter values required by the particular
program.
This method will put an entry in the ANALYSES table in the DB, and return with an AnalysisID. 
This AnalysisID must be used in order to write features to the database.

B<Examples:>

 $OME->RegisterAnalysis (programName => 'MyProgram', datasetID => 123,
 	PROGRAM_PARAM1 => 'something',
 	PROGRAM_PARAM2 => 'something else',
 	PROGRAM3 => 123 );

This will register a program run for the specified program and dataset, and set the run parameters
(PROGRAM_PARAM1, PROGRAM_PARAM2, and PROGRAM3) to 'something', 'something else' and 123.
These three parameters are specified in the program's input table, whose
name is stored in the table.column PROGRAMS.INPUT_TABLE.

=cut

sub RegisterAnalysis()
{
	my $self = shift;
	my %params = @_;
	my $sth;

#	die "You must call StartAnalysis prior to RegisterAnalysis" unless @SelectedDatasets;
	
	die "You must register an analysis using a programName or programID." unless
		( $params{'programName'} or $params{'programID'} );
	
	die "You must supply a datasetID to register an analysis." unless
		$params{'datasetID'};

# Get the programID if all we have is a programName
	my $programID;
	if ($params{'programName'})
	{
		$sth = $self->{dbHandle}->prepare ("SELECT program_id FROM programs WHERE program_name=?");
		$sth->execute( $params{'programName'} );
		$programID = $sth->fetchrow_array;	
		die "Program '".$params{'programName'}."' is not registered with OME\n" unless defined $programID;
	}
	else {
		$programID = $params{'programID'};
	}

# Get the analysisID and the datasetID
	my $analysisID = $self->GetOID ('ANALYSIS_SEQ');
	my $datasetID = $params{'datasetID'};

# Make an entry in the Analyses table.
	$sth = $self->{dbHandle}->do (
		"INSERT INTO analyses (analysis_ID,experimenter_ID,dataset_ID,program_ID,status) VALUES (?,?,?,?,?)",undef,
		$analysisID,$self->{ExperimenterID},$datasetID,$programID,'EXECUTING'
	);

# Get the name of the input table for this program
	my $inputTableName;
	$sth = $self->{dbHandle}->prepare ("SELECT input_table FROM programs WHERE program_id=?");
	$sth->execute( $programID );
	$inputTableName = $sth->fetchrow_array;
	die "Program ID: $programID not properly registered with OME (INPUT_TABLE not found).\n" unless defined $inputTableName;

# Delete the datasetID, programID, and programName keys from the params hash
	delete $params{'datasetID'};
	delete $params{'programID'};
	delete $params{'programName'};

# Add the ANALYSIS_ID key to the params hash.
	$params{'ANALYSIS_ID'} = $analysisID;

# Now the params hash has all the keys and values to stuff it directly into the program's
# input table.  This funny business here is to make as many '?' as there are keys in the hash.
# We go the '?' route so that DBI can do the proper quoting of strings.
	my @questions;
	while ( each %params) {
		push (@questions,"?");
    }

	$sth = $self->{dbHandle}->do (
		"INSERT INTO $inputTableName (".join (",",keys %params).") VALUES (".join (",",@questions).")",undef,
		values %params
	);


# Return the analysisID
	$self->{CurrentAnalysisID} = $analysisID;

# Update session info
	$self->UpdateProgress(
		CurrentAnalysisID => $analysisID,
		CurrentDatasetID => $datasetID,
		ProgramID => $programID
	);	

	return $analysisID;
}


 

#sub WriteFeatures ($analysisID,$features,$featureDBmap)
#
# $featureDBmap has the following structure:
# General case:  DataMember  => ['TABLE','COLUMN',  'TYPE', 'TYPE OPTIONS'... ],
# one to many:  DataMember  => ['TABLE','COLUMN',  'TYPE', 'ONE2MANY', 'DISCRIMINATOR COLUMN','DISCRIMINATOR VALUE' ],
# Example: i[528]  => ['SIGNAL','INTEGRAL',  'FLOAT', 'ONE2MANY', 'WAVELENGTH','528' ]
# FIXME:  The requirement for a type specifier should go away soon.
#
# It seems more efficient to dump entire tables at a time instead of doing one feature at a time.
# In the previous incarnation of this method (before DBI) we wrote the entire table to a buffer and
# sent it to the database.  This was wast because we didn't do any index updates until the whole buffer was written.
# Don't know how the DBI driver deals with prepared statmenets, but hopefully something quick.
# In any case, we should give the driver a chance to do a buffered write using a prepared statement.
# Since features have datamembers that end up in different tables, we sort the datamembers for the feature list into the
# corresponding tables, and then write one table at a time.
# If there is a more efficient way, please implement it.
# There are three ways (probably more) of doing this, listed below.
# The first method is the one used.
# 1:
# $tableNames = {'TABLE1' => {'COLUMN1' => [1,2,3,4,5,6,7,8,9,0],
#                            'COLUMN2' => [1,2,3,4,5,6,7,8,9,0],
#                            'COLUMN3' => [1,2,3,4,5,6,7,8,9,0]},
#               'TABLE2' => {'COLUMN1' => [1,2,3,4,5,6,7,8,9,0],
#                            'COLUMN2' => [1,2,3,4,5,6,7,8,9,0],
#                            'COLUMN3' => [1,2,3,4,5,6,7,8,9,0]}
#              }
# It is easy to construct the $tableNames hash, but it is not very memory efficient.
# Also, we have to re-make an array of column values when we do the actual database write (i.e. [1,1,1] then [2,2,2], etc.).
# 2:
#$tableNames = {'TABLE1' => {ColumnNames  =>  ['COLUMN1','COLUMN2','COLUMN3'],
#                            ColumnValues => [[    1    ,     1   ,    1    ],
#                                            [     2    ,     2   ,    2    ],
#                                            [     3    ,     3   ,    3    ]]
#                           }
#              }
# This is more efficient to write to the database (don't have re-make any arrays), but more of a pain to construct the $tableNames hash.
# Also, this is not very memory efficient.
# 3:
#$tableNames = {'TABLE1' => {'COLUMN1' => datamember1,
#                            'COLUMN2' => datamember2}
#               'TABLE2' => {'COLUMN3' => datamember3,
#                            'COLUMN4' => datamember4}
#               }
# This is more memory efficient, but suffers from the same array problem as method 1.
# Also, although most columns refer to a datamember, others have hard values such as $analysisID,
# and discriminator values in ONE2MANY relationships.  This would make it hard to process - lots of checking inside loops.
#
# DBI notes:  Without DBI, it is possible to do a buffered write to the database (at least with postgres) using the 
# 'COPY table FROM stdin' command, then feedind all the rows to the table (without INSERT) using $dbHandle->putline(), then finishing
# with $dbHandle->endcopy().  This way, the back-end doesn't update the indexes (presumably) until we issue the endcopy().
# Apparently DBI causes the backend to update indexes with every execute(), even though that could be done only when the prepared
# statement handle is disposed.  There should probably be database-specific ways of doing high-volume reads and writes.
# FIXME:  Implement database-specific high-volume reads and writes.  The database type can be determined from the datasource.
sub WriteFeaturesOLD ()
{
	my $self = shift;
	my ($analysisID,$features,$featureDBmap) = @_;
	my ($dataMember,$memberTypeData);
	my ($table,$row,$column);
	my (%tableNames,$tableHash);
	my $feature;
	my %featuresTable;
	my $sth;
	my $cmd;
	
# Die several different ways
	die "First required parameter (analysis ID) undefined in call to WriteFeatures\n"
		unless defined $analysisID;
	die "Second required parameter (reference to array of features) undefined in call to WriteFeatures\n"
		unless defined $features;
	die "Third required parameter (reference to hash mapping datamembers to DB) undefined in call to WriteFeatures\n"
		unless defined $featureDBmap;
	die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got a scalar.\n"
		unless ref($features);
	die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got ".ref($features)."\n"
		unless ref($features) eq "ARRAY";
	die "The third argument to Add_Feature_Attributes must be a HASH reference. Got a scalar.\n"
		unless ref($featureDBmap);
	die "The second argument to Add_Feature_Attributes must be an HASH reference. Got ".ref($featureDBmap)."\n"
		unless ref($featureDBmap) eq "HASH";

	foreach $feature (@$features)
	{
		while ( ($dataMember,$memberTypeData) = each (%$featureDBmap) )
		{
			$table = $$memberTypeData[0];
			$column = $$memberTypeData[1];
			if (exists $tableNames{$table}) { $tableHash = $tableNames{$table}; }
			else { $tableNames{$table} = {};  $tableHash = $tableNames{$table}; }
			if (defined $$memberTypeData[2] and $$memberTypeData[2] eq 'ONE2MANY')
			{
			# Set the discriminator value.
				push ( @{$$tableHash{$$memberTypeData[3]}},$$memberTypeData[4] );
			}
			push (@{$$tableHash{$column}},$feature->$dataMember());
		}

	# Make sure that each feature has an ID.
		if (!defined $feature->ID() ) { $feature->ID($self->GetOID('FEATURE_SEQ')); }
#print "Feature ID: ",$feature->ID(),"\n";
		push ( @{$featuresTable{'FEATURE_ID'} },$feature->ID );
		push ( @{$featuresTable{'ANALYSIS_ID'}},$analysisID );

	# push the feature ID and the analysis ID into each table.
		while ( ($table,$tableHash) = each (%tableNames) )
		{
#print "Setting $table ATTRIBUTE_OF = ".$feature->ID()." and ANALYSIS_ID = $analysisID\n";
		
			push ( @{$tableNames{$table}{'ATTRIBUTE_OF'}}, $feature->ID() );
			push ( @{$tableNames{$table}{'ANALYSIS_ID'}},  $analysisID );
		}
		
	}

	$tableNames{FEATURES} = \%featuresTable;

	my $lastRow = $#{$features};
#	if ($self->{dbHandle}->{Driver}->{Name} eq 'Pg') {
#		$self->WriteDBtables_PostgreSQL (\%tableNames,$lastRow);
#	}
#	else {
		$self->WriteDBtables_DBI (\%tableNames,$lastRow);
#	}
}

sub WriteFeatures ()
{
	my $self = shift;
	my ($analysisID,$features,$featureDBmap) = @_;
	my ($dataMember,$memberTypeData);
	my ($table,$row,$column);
	my (%tableNames,$tableHash);
	my $feature;
	my $sth;
	my $cmd;

# Die several different ways
	die "First required parameter (analysis ID) undefined in call to WriteFeatures\n"
		unless defined $analysisID;
	die "Second required parameter (reference to array of features) undefined in call to WriteFeatures\n"
		unless defined $features;
	die "Third required parameter (reference to hash mapping datamembers to DB) undefined in call to WriteFeatures\n"
		unless defined $featureDBmap;
	die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got a scalar.\n"
		unless ref($features);
	die "The second argument to Add_Feature_Attributes must be an ARRAY reference. Got ".ref($features)."\n"
		unless ref($features) eq "ARRAY";
	die "The third argument to Add_Feature_Attributes must be a HASH reference. Got a scalar.\n"
		unless ref($featureDBmap);
	die "The second argument to Add_Feature_Attributes must be an HASH reference. Got ".ref($featureDBmap)."\n"
		unless ref($featureDBmap) eq "HASH";
  
# Create a flat features table.
# Do a select from the tables+columns in the $featureDBmap into an empty temporary table - the select should not return any tuples.
# General case:  $featureDBmap = {DataMember  => ['TABLE','COLUMN', 'TYPE OPTIONS'... ], ...};
# one to many:  $featureDBmap = {DataMember  => ['TABLE','COLUMN', 'ONE2MANY', 'DISCRIMINATOR COLUMN','DISCRIMINATOR VALUE' ], ...};
#
# M
	my @selectExpression = ('FEATURES.FEATURE_ID AS FEATURE_ID','FEATURES.ANALYSIS_ID AS ANALYSIS_ID');
	my @flatColumnNames =  ('FEATURE_ID','ANALYSIS_ID');
	my @questions =        ('?',$analysisID);
	my @featureFields =        ('ID');
	my ($flatColumnName,$selectColumn);
	my ($discColumn,$discValue,%discHash);

	delete $featureDBmap->{ID};
	delete $featureDBmap->{AnalysisID};
	while ( ($dataMember,$memberTypeData) = each (%$featureDBmap) )
	{
		$table = $memberTypeData->[0];
		$column = $memberTypeData->[1];
		if (uc ($table) ne 'FEATURES')
		{
#
# $tableNames = {TABLE1 => {'flatColumns' => ["Column1","Column2"],
#                          'dataMemebers' => [dataMember1,dataMember2],
#                          'tableColumns' => [column1,column2],
#                          'subTables'    => {$discValue => {'flatColumns' => ["Column1","Column2"],
#                                                            'dataMemebers' => [dataMember1,dataMember2],
#                                                            'tableColumns' => [column1,column2]
#                                                           }
#                                         }
#                          }
#               }
			if (not exists $tableNames{$table}) {
				$tableNames{$table} = {
					flatColumns  => ['FEATURE_ID','ANALYSIS_ID'],
					dataMemebers => ['ID','AnalysisID'],
					tableColumns => ['ATTRIBUTE_OF','ANALYSIS_ID'],
				};
			}

			$tableHash = $tableNames{$table};
			if (defined $memberTypeData->[2] and $memberTypeData->[2] eq 'ONE2MANY')
			{
				$discColumn = $memberTypeData->[3];
				$discValue = $memberTypeData->[4];
				if (not exists $tableHash->{subTables}) {$tableHash->{subTables} = {}};

				if (not exists $tableHash->{subTables}->{$discValue}) {
					$flatColumnName = qq/"$discColumn$discValue"/;
					$tableHash->{subTables}->{$discValue} = {
						flatColumns  => ['FEATURE_ID','ANALYSIS_ID',$flatColumnName],
						dataMemebers => ['ID','AnalysisID',undef],
						tableColumns => ['ATTRIBUTE_OF','ANALYSIS_ID',$discColumn]
					};

					push (@flatColumnNames,$flatColumnName);
					push (@selectExpression,qq/$table.$discColumn AS $flatColumnName/);
					push (@questions,qq/'$discValue'/);
				}
				$tableHash = $tableHash->{subTables}->{$discValue};
			}

			$selectColumn = qq/$table.$column/;
			$flatColumnName = qq/"$dataMember"/;
			push (@flatColumnNames,$flatColumnName);
			push (@selectExpression,qq/$selectColumn AS $flatColumnName/);
			push (@questions,'?');
			push (@featureFields,$dataMember);
			push (@{$tableHash->{flatColumns}},$flatColumnName);
			push (@{$tableHash->{dataMemebers}},$dataMember);
			push (@{$tableHash->{tableColumns}},$column);
		}
	}

# Some notes on a DbMap Object implementation:
# Method : feature->DBmap->SelectExpressions() - a list with members of the form 'table.column AS flatColumnName'
# Method : feature->DBmap->TableNames() - a list of UNIQUE table names - i.e. keys from a hash.
# Method : feature->DBmap->FlatColumnNames() - a list of UNIQUE column names for a flat table.
#          This and the two lists below share the same column order.
# Method : feature->DBmap->FlatColumnValuesPre() - a list - either a value or ?.
#          Values should be in single quotes.  ? are unquoted (nekid).
#          The two lists above are exactly the same size.  Values specified in this list will be plugged into columns specified above.
# Method : feature->DBmap->FlatColumnValues(ID) - a list - values corresponding ? in FlatColumnValuesPre().
#          This list's size is the number of '?' members in the list above.
#
# Fields:
#  One field for every datamember in the Feature object that maps to the database.
#  
	my @values;
	my $subTableHash;
	$cmd = "SELECT ".join (',',@selectExpression).
		q/ INTO TEMPORARY TABLE foobar WHERE /.
		join ('.attribute_of=0 AND ',keys %tableNames).
		q/.attribute_of=0 AND features.feature_id = 0/;
	$self->{dbHandle}->do ($cmd);
	
	$sth = $self->{dbHandle}->prepare("INSERT INTO foobar (".
		join (',',@flatColumnNames).") VALUES (".join (',',@questions).")");
	foreach $feature (@$features)
	{
	# Make sure that each feature has an ID.
		if (!defined $feature->{ID} ) { $feature->{ID} = $self->GetOID('FEATURE_SEQ'); }

		$feature->{AnalysisID} = $analysisID;
		@values = ();
		foreach $dataMember (@featureFields) {
			push (@values,$feature->{$dataMember});
		}
		$sth->execute(@values);
	}

	$self->{dbHandle}->do ("INSERT INTO features (feature_id,analysis_id) SELECT feature_id,analysis_id FROM foobar");

	while ( ($table,$tableHash) = each (%tableNames) )
	{
		if (exists $tableHash->{subTables}) {
			foreach $subTableHash (values %{$tableHash->{subTables}}) {
				$self->{dbHandle}->do (
					"INSERT INTO $table (".join (',',@{$subTableHash->{tableColumns}}).
					") SELECT ".join (',',@{$subTableHash->{flatColumns}})." FROM foobar"
				);
			}
		}
		
		else {
			$self->{dbHandle}->do (
				"INSERT INTO $table (".join (',',@{$tableHash->{tableColumns}}).
				") SELECT ".join (',',@{$tableHash->{flatColumns}})." FROM foobar"
			);
		}

	}
	
	$self->{dbHandle}->do ("DROP TABLE foobar");


}



#
# This method cleans up after an analysis is finished.  Currently what happens is that
# all previous analyses by the current user on the given dataset with the same program are deleted.
# This is done by calling the method PurgeAnalysis.
# FIXME:  The status of PurgeDataset is somewhat in flux, so PurgeDataset should be called manually after an analysis.
sub FinishAnalysis {
	my $self = shift;

	$self->{dbHandle}->do ("UPDATE analyses SET status='ACTIVE' WHERE analysis_id=".$self->{CurrentAnalysisID});
#	$self->Commit();
#	$self->SetDatasetView();

# Update session info
	$self->IncrementProgress();

	$self->{CurrentAnalysisID} = undef;
}


sub GetLatestAnalysisID {
my $self = shift;
my %params = @_;
my $analysisID;

	die "Parameter DatasetID must be supplied to GetLatestAnalysisID" unless exists $params{DatasetID} and $params{DatasetID}; 
	if (exists $params{ProgramID} and $params{ProgramID}) {
		$analysisID = $self->DBIhandle->selectrow_array (
			"SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND program_ID=?",undef,$params{DatasetID},$params{ProgramID});
	}
	
	elsif (exists $params{ProgramName} and $params{ProgramName}) {
		$analysisID = $self->DBIhandle->selectrow_array (
			"SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND ".
			"program_ID=programs.program_ID AND programs.program_name = ?",undef,$params{DatasetID},$params{ProgramName});
	}
	
	else {
		die "Parameter ProgramName or ProgramID must be supplied to GetLatestAnalysisID";
	}
	return $analysisID;
}

# GetAnalysisIDs
# Returns an array of analysis IDs performed on the given DatasetID by the given ProgramName or ProgramID - latest analysis first.
sub GetAnalysisIDs {
my $self = shift;
my %params = @_;
my $sth;
my $row;
my @analysisIDs;

	die "Parameter DatasetID must be supplied to GetAnalysisIDs" unless exists $params{DatasetID} and $params{DatasetID}; 
	if (exists $params{ProgramID} and $params{ProgramID}) {
		$sth = $self->DBIhandle->prepare (
			"SELECT max (analysis_id) FROM analyses WHERE dataset_id = ? AND program_ID=?".
			" ORDER BY analysis_ID DESC");
		$sth->execute($params{DatasetID},$params{ProgramID});
		$sth->bind_columns(\$row);
		while ( $sth->fetch ) {
			push (@analysisIDs,$row);
		}
		undef $sth;
	}
	
	elsif (exists $params{ProgramName} and $params{ProgramName}) {
		$sth = $self->DBIhandle->prepare (
			"SELECT analysis_id FROM analyses WHERE dataset_id = ? AND program_ID=programs.program_ID AND programs.program_name = ?".
			" ORDER BY analysis_ID DESC");
		$sth->execute($params{DatasetID},$params{ProgramName} );
		$sth->bind_columns(\$row);
		while ( $sth->fetch ) {
			push (@analysisIDs,$row);
		}
		undef $sth;
	}
	
	else {
		die "Parameter ProgramName or ProgramID must be supplied to GetAnalysisIDs";
	}
	
	return \@analysisIDs;
}

# Delete all features and attributes generated by previous analyses.
#FIXME:  This is broken - don't use it!  Fix it if you can.
#Second attempt:  Do this based on a DatasetID.
# Get all analyses for a given dataset.  Go through each one and determine:
# Is this analysis the latest run of this program on this dataset?
# Does this analysis have dependents that are the latest run of their program on this dataset?
# If both answers are no, then delete the dataset.
# GetDependentsOf Gets a list of dependant analyses given an analysis ID.
# 

sub PurgeDataset ()
{
	my $self = shift;
	my $datasetID = shift;
	my ($analysisID,$programID);
	my $analysisIDs;
	my @programIDs;
	my %latestAnalyses;
	my %allAnalyses;
	my $sth;

	return unless defined $datasetID;

# Get the programIDs that were used to analyze this dataset.  Make a hash of lists where the keys are the programIDs
# and the list items are the corresponding analysisIDs.
	$sth = $self->{dbHandle}->prepare ("SELECT analysis_id, program_id FROM analyses WHERE dataset_id = ? AND experimenter_id = ? AND ".
		"(status <> 'EXPIRED' OR status = NULL)");
	$sth->execute( $datasetID,$self->{ExperimenterID} );
	while ( ($analysisID,$programID) = $sth->fetchrow_array) { push (@{$allAnalyses{$programID}},$analysisID); }

# For each programID, get the latest analysisID, and put it in the latestAnalyses hash.
	while ( ($programID,$analysisIDs) = each (%allAnalyses) )
	{
		$latestAnalyses{$programID} = undef;
		foreach $analysisID (@$analysisIDs)
		{
			$latestAnalyses{$programID} = $analysisID unless defined ($latestAnalyses{$programID});
			if ($analysisID > $latestAnalyses{$programID}) {$latestAnalyses{$programID} = $analysisID; }
		}
	}

# Now we go through every analysis done on this dataset and check if it matches our latestAnalyses hash.
# For each analysis, we also check if any of its dependants are in the latestAnalyses hash.

LOOP:
# For each programID, get the latest analysisID, and put it in the latestAnalyses hash.
	while ( ($programID,$analysisIDs) = each (%allAnalyses) )
	{
		foreach $analysisID (@$analysisIDs)
		{
			if ($analysisID != $latestAnalyses{$programID})
			{
				my $dependents = $self->GetDependentsOf ($analysisID);
				my $dependent;
				foreach $dependent (@$dependents)
				{
					if ($dependent = $latestAnalyses{$programID}) { next LOOP; }
				}
				$self->ExpireAnalysis ($analysisID);
			}
		}
	}

	
}

# A dependent analysis has feature IDs in common with the parent analysis, and also a higher analysisID.
sub GetDependentsOf ()
{
	my $self = shift;
	my $analysisID = shift;
	my $tuple;
	my @dependents;
	my $sth;
	my $cmd;

	return unless defined $analysisID;
	
# All we want is to select an analysis ID that is greater than the one we're checking, was produced by a different 
# program than the one we're checking, and has features in common with the one we're checking.
# There are two alternative queries here, one of which is commented out.
# Here is an alternative query which requires determining the programID:
	$sth = $self->{dbHandle}->prepare ("SELECT program_id FROM analyses WHERE analysis_id = ?");
	$sth->execute( $analysisID );
	my $programID =  $sth->fetchrow_array;

	$cmd = "SELECT analysis_id FROM analyses a1 WHERE a1.analysis_id > $analysisID AND a1.program_id <> $programID ".
		"AND EXISTS (SELECT f1.feature_id FROM features f1 WHERE f1.analysis_id = a1.analysis_id AND feature_id IN ".
		"(SELECT feature_id FROM features WHERE analysis_id = $analysisID))";
# This is the other alternative, which seems to be potentially slower:
#	$cmd = "SELECT DISTINCT f1.analysis_id FROM features f1, features f2 , analyses a1, analyses a2 WHERE ".
#		"f2.analysis_id = $analysisID AND f2.feature_id = f1.feature_id AND f1.analysis_id > $analysisID ".
#		"AND f1.analysis_id = a1.analysis_id AND a2.analysis_id = f2.analysis_id AND a1.program_id <> a2.program_id";
	$sth = $self->{dbHandle}->prepare ($cmd);
	$sth->execute( );
	while ( $tuple = $sth->fetchrow_array ) { push (@dependents,$tuple); }

#print "AnalysisID: $analysisID, Dependents=(";
#my $dep;
#foreach $dep (@dependents) { print $dep,","; }
#print ")\n";
#
	return \@dependents;
	
}


# Delete all attributes of the analysis, and mark the analysis expired.
sub ExpireAnalysis {
	my $self = shift;
	my $analysisID = shift;
	my $tuple;
	my @featureTables;
	my $tableName;
	my $sth;

	return unless defined $analysisID;

# Get the table names of the attributes computed by this analysis.
	$sth = $self->{dbHandle}->prepare ("SELECT table_name FROM attribute_list WHERE list_id = programs.attribute_list_id AND ".
		"programs.program_id = analyses.program_id AND analyses.analysis_id = ?");
	$sth->execute( $analysisID );
	while ( $tuple = $sth->fetchrow_array ) {push (@featureTables,$tuple) ; }

# Push the features table into the list of tables as well.
	push (@featureTables,'features');

# Go through all the attribute tables and delete attributes with matching analysisIDs.
	foreach $tableName (@featureTables)
	{
		$self->{dbHandle}->do ("DELETE FROM $tableName WHERE analysis_id=$analysisID");
	}

# Mark the analysis EXPIRED in the analyses table.
	$self->{dbHandle}->do ("UPDATE analyses SET status='EXPIRED' WHERE analysis_id=$analysisID");
	$self->UnlinkExpiredFiles();
}


sub UnlinkExpiredFiles {
my $self = shift;

	$self->{dbHandle}->do("DELETE FROM expired_files WHERE fullpath=NULL");
	my $paths = $self->{dbHandle}->selectcol_arrayref("SELECT fullpath FROM expired_files");
	my $file;
	my $deleted;
	foreach (@$paths) {
		my $file = $_;
		my $deleted = unlink ($_);
		if (defined $deleted and $deleted) {
			$self->{dbHandle}->do ("DELETE FROM expired_files WHERE fullpath='$file'");
		}
	}
}



=pod

=back

=head2 Miscellaneous Methods

=over 4

=item GetOID()

This method returns a unique object identifier.  The required parameter is a string containing the name of the
identifier.  In the database, this name is a SEQUENCE (PostgreSQL - probably a non-SQL92 extension).  The effect
is that the number returned is guaranteed unique for the sequence specified.
This method will die if a sequence is not specified.
This method will die if the specified sequence does not exist in the database.  It should probably not be the
responsibility of this method to create the sequence if it doesn't exist.  That should be done elsewhere.

=cut

sub GetOID {
	my $self = shift;
	my $sequence = shift;
	my $sth;
	
	die "OME: Attempt to get a unique object identifier for an unspecified object type\n" unless defined $sequence;
	$sth = $self->{dbHandle}->prepare("SELECT nextval (?)");
	$sth->execute( $sequence );
	return ($sth->fetchrow_array);	
			
}


# Getting the pixel sizes and dataset sizes in any way other than these methods is
# almost guaranteed to break in the future
# FIXME:  This should instatiate an OMEDataset object, and get these values from there.
sub GetPixelSizes {
	my $self = shift;
	my $datasetID = shift;
	my $attributesTable = undef;
	my %pixelSizes;
	my $sth;



	return unless defined $datasetID;
# Determine the dataset type.
	$attributesTable = uc ($self->{dbHandle}->selectrow_array ("SELECT ATTRIBUTES_TABLE FROM datasets WHERE dataset_id=$datasetID"));
    SWITCH: for ($attributesTable) {
                /ATTRIBUTES_DATASET_XYZWT/ && 
					do {
						($pixelSizes{X},$pixelSizes{Y},$pixelSizes{Z}) = $self->{dbHandle}->selectrow_array (
							"SELECT pixel_size_x, pixel_size_y, pixel_size_z FROM $attributesTable WHERE dataset_id=$datasetID");
					last; };

                /ATTRIBUTES_ICCB_TIFF/ &&
					do {
						($pixelSizes{X},$pixelSizes{Y}) = $self->{dbHandle}->selectrow_array (
							"SELECT pixel_size_x, pixel_size_y FROM $attributesTable WHERE dataset_id=$datasetID");
					last; };

                die "unknown dataset type ATTRIBUTES_TABLE =: `$attributesTable'";
            }	

	return %pixelSizes;

}




sub GetDatasetSize {
	my $self = shift;
	my $datasetID = shift;
	my $attributesTable = undef;
	my %datasetSize;
	my $sth;



	return unless defined $datasetID;
# Determine the dataset type.
	$sth = $self->{dbHandle}->prepare ("SELECT ATTRIBUTES_TABLE FROM datasets WHERE dataset_id=?");
	$sth->execute( $datasetID );
	$attributesTable = uc ( $sth->fetchrow_array );
    SWITCH: for ($attributesTable) {
                /ATTRIBUTES_DATASET_XYZWT/ && 
					do {
						$sth = $self->{dbHandle}->prepare ("SELECT size_x, size_y, size_z ".
							"FROM $attributesTable WHERE dataset_id=$datasetID");
						$sth->execute( );
						($datasetSize{X},$datasetSize{Y},$datasetSize{Z}) = $sth->fetchrow_array;
					last; };

                /ATTRIBUTES_ICCB_TIFF/ &&
					do {
						$sth = $self->{dbHandle}->prepare ("SELECT size_x, size_y ".
							"FROM $attributesTable WHERE dataset_id=$datasetID");
						$sth->execute( );
						($datasetSize{X},$datasetSize{Y}) = $sth->fetchrow_array;
					last; };

                die "unknown dataset type ATTRIBUTES_TABLE =: `$attributesTable'";
            }	

	return %datasetSize;
}

#
# Call this function with a query to set the current feature view for a dataset.
# This will make a view in the database.
# If DatasetID parameter is not set, this method will get the dataset_id from the $CurrentAnalysisID.
# If the view name parameter (ViewName) is not specified, the view name will be the name of the
# dataset.  If the name lookup fails (i.e. invalid DatasetID), this method will return silently.
# Lastly, we need the SQL query for the view (ViewSQL).  This can be a query returned by the MakeFeatureQuery
# method, or some other query of your own choosing.  The SQL command will be checked by the database
# when the view is made.
# If the ViewSQL parameter is not set, then the desired attributes will be retreived from the FEATURE_VIEW column
# of the current session, and the SQL query generated by calling MakeFeatureQuery with the $datasetID
#  Before the view is made, a "DROP VIEW" command will be issued with the view name.
# This will result in any previous view of the same name to be deleted.  If there were errors in the SQL query,
# the old view by the same name will still be deleted.
# If all goes well, this method will return the name of the view.
sub SetDatasetView {
	my $self = shift;
	my %params = @_;
	my $viewName;
	my $ViewSQL;
	my $featureView;
	my $sth;

# Get the datasetID
	if (! defined  $params{DatasetID} )
	{
		$sth = $self->{dbHandle}->prepare ("SELECT dataset_id FROM analyses WHERE analysis_id = ?");
		$sth->execute($self->{CurrentAnalysisID} );
		$params{DatasetID} = $sth->fetchrow_array;
	}	
	return unless defined  $params{DatasetID};

# Get the viewName.
	if (! defined $params{ViewName} )
	{
		$sth = $self->{dbHandle}->prepare ("SELECT name FROM datasets WHERE datasets.dataset_id = ?");
		$sth->execute($params{DatasetID} );
		$params{ViewName} = $sth->fetchrow_array;
	}
	return unless defined $params{ViewName};

# Get the ViewSQL
	if (! defined $params{ViewSQL} )
	{
		$params{ViewSQL} = $self->{dbHandle}->selectrow_array ("SELECT feature_view FROM ome_sessions WHERE session_ID = ?",undef,$params{sessionID});
	}
	return unless defined $params{ViewSQL};

# Ignore an error at this point.
	eval { $self->{dbHandle}->do ("DROP VIEW ?",undef,$params{ViewName}) ; };
# But not here.
	$sth = $self->{dbHandle}->do ('CREATE VIEW "'.$params{ViewName}.'" AS '.$params{ViewSQL});
	return $params{ViewName};

}

sub SetProjectView ($$\%) {
my ($self,$projectID,$projectName,$DBmap) = @_;

	
}



#
# returns a SQL query where the attributes specified are the latest ones for the given dataset.
# Call with a list of parameters.  The first parameter is the dataset_id.  Subsequent parameters are
# feature attributes in table.column format.
# i.e. $OME->MakeFeatureQuery ($datasetID,'location.x','location.y','location.z');
sub MakeFeatureQuery {
	my $self = shift;
	my $datasetID = shift;
	my @table_columns = @_;
	my $table_column;
	my @selectClauseBits;
	my @fromClauseBits;
	my @featureIdBits;
	my @analysisIdBits;
	my $SQLquery=undef;
	my $tNum=0;
	my ($table,$column);
	my %shortTable;
	my $analysesClause = "analysis_id = analyses.analysis_id AND analyses.dataset_id=$datasetID";
	my $i;
	

	return unless defined $datasetID;

# Build the SELECT clause
	foreach $table_column ( @table_columns )
	{
		($table,$column) = split (/\./,$table_column);
	# Each NEW table in table_columns gets aliased to a 't#'
		if (! exists ($shortTable{$table}) )
		{
			$shortTable{$table} = 't'.$tNum++;
			push (@fromClauseBits,$table.' '.$shortTable{$table});
			push (@featureIdBits,$shortTable{$table}.'.attribute_of');
			push (@analysisIdBits,$shortTable{$table}.".analysis_ID = (SELECT max (analysis_id) FROM $table WHERE $analysesClause)");
		}

		push (@selectClauseBits,$shortTable{$table}.".$column");
	}

	for ($i = 0;$i < $#featureIdBits; $i++ )
	{
		$featureIdBits[$i] = $featureIdBits[$i]." = ".$featureIdBits[$i+1]." AND ";
	}
	$#featureIdBits--;

	if (@selectClauseBits)
	{
		$SQLquery = "SELECT ".join (',',@selectClauseBits).
			" FROM ".join (',',@fromClauseBits).
			" WHERE @featureIdBits".join (' AND ',@analysisIdBits);
	}	
return  $SQLquery
}







# Set the ExperimenterID
sub SetExperimenterID {
	my $self = shift;
	my $sth;

	$sth = $self->{dbHandle}->prepare ("SELECT experimenter_id FROM experimenters WHERE ome_name=?");
	$sth->execute( $self->{user} );
	$self->{ExperimenterID} = $sth->fetchrow_array;
	die "'". $self->{user}."' is not in the EXPERIMENTERS table.\n" unless defined $self->{ExperimenterID};
	return $self->{ExperimenterID};
}

sub GetExperimenterID {
	my $self =  shift;
	return    $self->{ExperimenterID};
}


#
# This returns an array of Feature objects from the OME database.
# The named parameters should be of the form:
# AnalysisID => 234,
# DatasetID => 567,
# FeatureID => 890,
# TABLE1.COLUMN1 => undef,
# TABLE1.COLUMN2 => 1,
# TABLE2.COLUMN3 => 1,
# etc..
# You allways get the ID, so don't specify it.
# Basically, if you make a key in the hash, it will be in the array of objects you get back.
# The OMEfeature objects returned are specified by either the AnalysisID, the DatasetID or the FeatureID.
# At least one of these must be present.  Obviously, specifying the FeatureID will result in an array with one element.
# Not only must one of these exist in the parameter list, but it must also be a valid ID in the OME database.
# If it is not, it is a fatal error.
# If the requested attributes exist in the OME database, they will be filled in with values
# from the database appropriate for the specified AnalysisID or DatasetID or FeatureID.  If they don't exist
# (i.e. "user" attributes), they will be set to undef.  The user parameters
# don't have to follow the TABLE.COLUMN format - they can be named anything you want.
# FIXME:  Attributes are read one at a time.  These should be sorted by table, and read a table at a time.
# SELECT table1.column1 as 'datamember', table2.column2 as 'datamember2'
# where table1.attribute_of = table2.attribute_of... and tablen.attribute_of = feature.feature_id
# and features.analysis_id = analyses.analysis_id and analyses.dataset_id = $datasetID.
sub GetFeatures {
	my $self = shift;
	my ($featureFields,$featureDbMap) = @_;
	my ($key,$attribute);
	my ($table,$column);
	my ($featureID,$datasetID,$analysisID,$attributeVal);
	my $sth;
	my $cmd;

# This is a hash that we will use to temporarily hold feature values.
# The keys are identical to the objects we're creating.
	my %feature;
	while ( ($key,$attribute) =  each (%$featureFields) ) {
		$feature{$key} = $attribute;
	}

# This hash has featureIDs for keys and feature object references as values.
	my %features;

# This is the list we'll return a reference to.
	my @featureList = undef;


# Make sure we have either an AnalysisID, DatasetID or FeatureID parameter.
	die "Called GetFeatures without required parameters.\n"
		unless ($featureFields->{'AnalysisID'} or $featureFields->{'DatasetID'} or $featureFields->{'FeatureID'});


#
# If the user supplied other ID keys as undef, we try to look them up.
# The only exception so far is looking up the analysisID given a datasetID - these can differ b/w attributes.
	if ($featureFields->{'AnalysisID'})
	{
		$analysisID = $featureFields->{'AnalysisID'};
		$feature{'AnalysisID'} = $analysisID;
		if (exists $feature{'DatasetID'})
		{
			$sth = $self->{dbHandle}->prepare ("SELECT dataset_id FROM analyses WHERE analysis_id = ?");
			$sth->execute( $analysisID );
			$datasetID = $sth->fetchrow_array;
			$feature{'DatasetID'} = $datasetID;		
		}
	}

	elsif ($featureFields->{'DatasetID'})
	{
		$datasetID = $featureFields->{'DatasetID'};
		$feature{'DatasetID'} = $datasetID;
	# We find the latest analysisID below
	}

	elsif ($featureFields->{'FeatureID'})
	{
		$featureID = $featureFields->{'FeatureID'};
		$feature{'FeatureID'} = $featureID;
		if (exists $feature{'DatasetID'})
		{
			$sth = $self->{dbHandle}->prepare (
				"SELECT dataset_id FROM analyses WHERE analysis_id = features.analysis_id and features.feature_id=?");
			$sth->execute( $featureID );
			$datasetID = $sth->fetchrow_array;
			$feature{'DatasetID'} = $datasetID;		
		}
		if (exists $feature{'AnalysisID'})
		{
			$sth = $self->{dbHandle}->prepare ("SELECT analysis_id FROM features WHERE feature_id=?");
			$sth->execute( $featureID );
			$analysisID = $sth->fetchrow_array;
			$feature{'AnalysisID'} = $analysisID;		
		}
	}
# Sort attributes by table so we don't waste a lot of time re-processing the same table.  Something like:
# %tableHash = { 'TABLE1' => [COLUMN1,COLUMN2,COLUMN3],
#                'TABLE2' => [COLUMN4,COLUMN5,COLUMN6]
#              }
# Make up the WHERE clause based on what kind of ID we got
# If we are given a datasetID, we should select the latest analysis that produced the requested attribute.
# We'll stuff the where clause into the value of the OMEattributes hash.
	my $whereClause;
	while ( ($key,$attribute) =  each (%$featureDbMap) )
	{
		($table,$column) = ( uc ($attribute->[0]),uc ($attribute->[1]) );

		if ($featureFields->{'AnalysisID'})
		{
			$analysisID = $featureFields->{'AnalysisID'};
			$whereClause = "WHERE attribute_of = features.feature_id AND features.analysis_id = ".$featureFields->{'AnalysisID'};
		}

		elsif ($featureFields->{'DatasetID'})
		{

		# Find the latest analysisID that has this attribute.
			$sth = $self->{dbHandle}->prepare ("SELECT MAX (analysis_id) FROM analyses WHERE dataset_id = ? AND ".
				"program_id = programs.program_id AND programs.attribute_list_id = attribute_list.list_id AND ".
				"attribute_list.table_name = ?");
			$sth->execute( $featureFields->{'DatasetID'}, $table );
			$analysisID = $sth->fetchrow_array;

			if (! defined $analysisID) { $analysisID = "NULL"; }
			$whereClause = "WHERE attribute_of = features.feature_id AND features.analysis_id = $analysisID";
			if (exists $feature{'AnalysisID'})   { $feature{'AnalysisID'} = $analysisID; }
		}

		elsif ($featureFields->{'FeatureID'})
		{
			$whereClause = "WHERE attribute_of = ".$featureFields->{'FeatureID'};
		}

	# Make the selection
		if ($whereClause)
		{
			$cmd = "SELECT attribute_of,$column FROM $table $whereClause";
			$sth = $self->{dbHandle}->prepare ($cmd);
			print STDERR "GetFeatures:  Executing >$cmd< \n";
			$sth->execute();
		}
		while ( ($featureID,$attributeVal) = $sth->fetchrow_array )
		{
		# Make a new object if the feature with the right ID doesn't exist.
		# We set the attribute value in the temp hash, make the object, and undef the
		# attribute value.
			if  (! exists $features{$featureID} ) 
			{
				$feature{'ID'} = $featureID;
				$feature{$key} = $attributeVal;
				$features{$featureID} = new OMEfeature ( %feature );
				$feature{$key} = undef;
			}

		# Set the attribute value of an existing feature.
			$features{$featureID}->{$key} = $attributeVal;
		}
		print STDERR "GetFeatures:  returned ".$sth->rows." rows.\n";
		
		
	}


	@featureList = values %features;
	
	return (\@featureList);
	
}




sub WriteOMEobject {
	my $self = shift;
	my $Object = shift;
	my $FieldsArray;
	my $Fields;
	die "Object not specified when calling 'WriteOMEobject'\n" unless defined $Object;
	my %tables;
	my %values;
	my (%IDname,%IDval);
	my $value;
	
	my ($ObjectFieldName,$fieldData);
	my ($table,$column);
	my $columns;
	my $cmd;
	my $sth;
	my $ObjectID;
	my $ObjectIDcolumn;

# Make a tableName -> list-of-column-names hash for the attributes.
	foreach $Fields (@{$Object->{_OME_FIELDS_}})
	{
		while ( ($ObjectFieldName,$fieldData) = each (%$Fields) )
		{
			$table = $fieldData->[0];
			$column = $fieldData->[1];
			$value = $Object->{$ObjectFieldName};
		# Put single quotes around value if its a string
			if (defined $value)
			{
				if ($fieldData->[2] eq 'STRING') { $value = "'$value'"; }
				if ($fieldData->[2] eq 'TIMESTAMP') { $value = "'$value'" unless $value eq 'CURRENT_TIMESTAMP'; }
			}
			
		# Set value to NULL if its not defined.
			else { $value = 'NULL'; }

			push (@{$tables{$table}},$column);
			push (@{$values{$table}},$value);
			if ($ObjectFieldName eq 'ID' || $fieldData->[2] eq 'OID')
			{
				$IDname{$table} = $column;
				$IDval{$table} = $value;
				$ObjectID = $value unless defined $ObjectID;
				$ObjectIDcolumn = $column unless defined $ObjectIDcolumn;
			}
		}
	}

# Go through the tables hash, and write the values.
# For each table, look up the column that pertains to the ID datamember, and query the DB
# for such an ID.  If it exists, do an update.  If it doesn't do an insert.
	while ( ($table,$columns) = each (%tables) )
	{
		if (not exists $IDname{$table} or not defined $IDname{$table} or not exists $IDval{$table} or not defined $IDval{$table}) {
			$IDname{$table} = $ObjectIDcolumn;
			$IDval{$table} = $ObjectID;
			push (@{$tables{$table}},$ObjectIDcolumn);
			push (@{$values{$table}},$ObjectID);
		}
		$cmd = "SELECT * FROM $table WHERE ".$IDname{$table}." = ".$IDval{$table};
		$sth = $self->{dbHandle}->prepare ($cmd);
		$sth->execute();

		if ($sth->fetchrow_array)
		{
		my (@nameValues,$i);
		my $colValues = $values{$table};
		my $nColumns = scalar(@$columns);

			for ($i=0; $i<$nColumns; $i++)
			{
				push (@nameValues,@$columns[$i]." = ".@$colValues[$i]);
			}
			$cmd = "UPDATE $table SET ". join (',',@nameValues)." WHERE ".$IDname{$table}." = ".$IDval{$table};
#print $cmd,"\n";
			$self->{dbHandle}->do ($cmd);
		}
		else
		{
		# Issue the querry to insert the new entry into the appropriate table.
			$cmd = "INSERT INTO $table (". join (',',@$columns).") VALUES (".join ( ',',@{$values{$table}} ).")";
#print $cmd,"\n";
			$self->{dbHandle}->do ($cmd);
		}
			
	}

}


# Required parameters are either Name and Type or just the ID.
sub NewDataset {
my $self = shift;
my %params = @_;
my $Type;

	if (exists $params{ID} ) {
		my $ID = $params{ID};
		$Type = $self->GetDatasetType ($ID);
		%params = (ID => $ID);
	} else {	
		$Type = $params{Type};
		die "'Name' is a required parameter to OME->NewDataset()\n" unless defined $params{Name};
		die "'Type' is a required parameter to OME->NewDataset()\n" unless defined $Type;
	}

	my $Object;
	my $Package;

	$Package = "OMEDataset::$Type";
	$params{OME} = $self;
	$Object = $Package->new(%params);
	return ($Object);
}

# ImportDataset
# Parameters:
# Name => '/absolute/path/to/file'  ** REQUIRED **
# Types => ['A_DATASET_TYPE','ANOTHER_DATASET_TYPE']  ** OPTIONAL **
# The types will be processed in the order given in the array, or in the order returned by the
# GetKnownDatasetTypes method.
sub ImportDataset {
my $self = shift;
my %params = @_;
my $datasetTypes;
my $datasetType;
my $Name = $params{Name};
my $Package;
my $Object;

	die "Calling ImportDataset without the required 'Name' parameter.\n" unless defined $Name;

	if ( exists $params{Types} ) {
		$datasetTypes = $params{Types};
	} else {
		$datasetTypes = $self->GetKnownDatasetTypes;
	}
	
	foreach $datasetType (@$datasetTypes) {
		$Package = "OMEDataset::$datasetType";
		$Object = $Package->new( OME => $self, Import => $Name );
		last if defined $Object;
	}
	
	return $Object;

}


sub GetKnownDatasetTypes {
return \@knownDatasetTypes;
}



sub GetDatasetID ($)  {
my $self = shift;
my $nameIN = shift;
my $path;
my $name;

	# get the path components out of the name.
		($name,$path,undef) = fileparse ($nameIN);
	
	# If we didn't get path bits in Path, get the absolute path from the Name.
		$path = abs_path ($path)."/";

	return ( $self->{dbHandle}->selectrow_array ("SELECT dataset_id FROM datasets WHERE name = '$name' AND path = '$path'") );
}

sub GetDatasetName ($) {
	my $self = shift;
	my $datasetID = shift;
	return ( $self->{dbHandle}->selectrow_array ("SELECT name FROM datasets WHERE DATASET_ID = $datasetID") );
}

sub GetDatasetPath ($) {
	my $self = shift;
	my $datasetID = shift;
	return ( $self->{dbHandle}->selectrow_array ("SELECT path FROM datasets WHERE DATASET_ID = $datasetID") );
}


sub GetDatasetType ($) {
	my $self = shift;
	my $datasetID = shift;
	return ( $self->{dbHandle}->selectrow_array ("SELECT dataset_type FROM datasets WHERE DATASET_ID = $datasetID") );
}


# The project name is a required, unnamed parameter.  The name must be unique in the DB.
# If the name is not unique or is empty or undefined, undef will be returned, and an error
# string put into errorMessage.
sub NewProject  {
my $self = shift;
my $projectName = shift;
my $projectID;


		if (length ($projectName) < 1) {
			$self->{errorMessage} = "Name of new project cannot be blank.";
			return undef;
		}

		$projectID = $self->DBIhandle()->selectrow_array ("SELECT project_id FROM projects where name='$projectName'");
		if (defined $projectID and $projectID) {
			$self->{errorMessage} = "Project '$projectName' already exists - duplicate project names are not allowed.";
			return undef;
		}

		$projectID = $self->GetOID ('PROJECT_SEQ');
		$self->DBIhandle()->do ("INSERT INTO projects (project_id,name) VALUES ($projectID,'$projectName')");
		return $projectID;
}






# AddProjectDatasets (123);
#   Will add the datasets selected in the current session to project ID 123.
# AddProjectDatasets (123,DatasetIDs=>[1,2,3,4]);
#   Will add the datasets with IDs 1,2,3,4 to project ID 123
# returns the project ID if no error.
sub AddProjectDatasets {
my $self = shift;
my $projectID = shift;
my %params = @_;
my $existProjectID;
my $projectDatasets = $self->GetProjectDatasetIDs($projectID);

	return undef unless defined $projectID and $projectID;
	
	
	
	if (defined $params{DatasetIDs} and $params{DatasetIDs}) {
		push (@$projectDatasets,@{$params{DatasetIDs}});
		$existProjectID = $self->GetProjectID(DatasetIDs=>$projectDatasets);
		if ($existProjectID) { # Check if a project exists with these datasets.
			$self->{errorMessage} = "A project with these datasets already exists (".$self->GetProjectName(ProjectID=>$existProjectID).").";
			print STDERR $self->{errorMessage},"\n";
			return undef;
		} else { # No project with these datasets.
			my $sliceStart = 0;
			my $maxDSidx = scalar (@{$params{DatasetIDs}})-1;
			my $sliceStop = $maxDSidx;
			if ($sliceStop > $SQLLISTLIMIT) {$sliceStop = $SQLLISTLIMIT - 1;}
			while ($sliceStop <= $maxDSidx) {
				my @datasetSlice = @{$params{DatasetIDs}}[$sliceStart .. $sliceStop];
			# Delete any rows in datasets_projects that already have this project ID and any of these datasetIDs
				$self->DBIhandle->do(
					"DELETE FROM datasets_projects WHERE project_id=$projectID ".
					"AND datasets_projects.dataset_id IN (".join (',',@datasetSlice).")");
				$self->DBIhandle->do(
					"INSERT INTO datasets_projects SELECT DISTINCT $projectID as project_id, dataset_id ".
					"FROM datasets WHERE datasets.dataset_id IN (".join (',',@datasetSlice).")");
				$sliceStart = $sliceStop + 1;
				$sliceStop += $SQLLISTLIMIT;
				$sliceStop = $maxDSidx if ($sliceStop > $maxDSidx);
				$sliceStop = $maxDSidx + 1 if ($sliceStart > $maxDSidx);
			}
			
		}
	} else {
		my $selectedDatasets = $self->GetSelectedDatasetIDs();
		if (defined $selectedDatasets and defined $selectedDatasets->[0]) {
			push (@$projectDatasets,@$selectedDatasets);
		}
		$existProjectID = $self->GetProjectID(DatasetIDs=>$projectDatasets);
		if ($existProjectID) { # Check if a project exists with the selected datasets.
			$self->{errorMessage} = "A project with these datasets already exists (".$self->GetProjectName(ProjectID=>$existProjectID).").";
			print STDERR $self->{errorMessage},"\n";
			return undef;
		} else { # No project with these datasets.
			$self->DBIhandle->do(
				"DELETE FROM datasets_projects WHERE project_id=$projectID ".
				"AND datasets_projects.dataset_id=ome_sessions_datasets.dataset_id ".
				"AND ome_sessions_datasets.session_id=".$self->SID);
			$self->DBIhandle->do(
				"INSERT INTO datasets_projects SELECT $projectID as project_id, dataset_id ".
				"FROM ome_sessions_datasets WHERE session_id=".$self->SID);
		}
	}
	return $projectID;
}

sub GetProjectDatasetIDs {
my $self = shift;
my $projectID = shift;

		return undef unless defined $projectID and $projectID;
		return $self->DBIhandle()->selectcol_arrayref ("SELECT dataset_id FROM datasets_projects where project_id=$projectID");

}


# ClearProjectDatasets (123);
#   Will delete the datasets in project ID 123.
# returns the project ID if no error.
sub ClearProjectDatasets {
my $self = shift;
my $projectID = shift;

	return undef unless defined $projectID and $projectID;

	$self->DBIhandle->do("DELETE FROM datasets_projects WHERE project_id=".$projectID);
	return $projectID;
}


# DeleteProject (123);
#   Will delete project ID 123.
# Calls ClearProjectDatasets before deleting the project.
# returns the project ID if no error.
sub DeleteProject {
my $self = shift;
my $projectID = shift;

	return undef unless defined $projectID and $projectID;
	my $selectedProject = $self->DBIhandle->selectrow_array (
		"SELECT project_id FROM ome_sessions WHERE project_id = ".$projectID);
	
	if (defined $selectedProject and $selectedProject) {
		$self->{errorMessage} = "Project is being used in a user session - it cannot be deleted.";
		return undef;
	}
	
	$self->ClearProjectDatasets ($projectID);
	$self->DBIhandle->do("DELETE FROM projects WHERE project_id=".$projectID);
	return $projectID;
}



sub SetSessionProjectID {
my $self = shift;
my $SID = $self->SID;

	$self->DBIhandle->do (
		'UPDATE ome_sessions set project_id=( '.
		'SELECT project_id from projects p WHERE NOT EXISTS '.
			'(SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id '.
			"EXCEPT SELECT ome_sessions_datasets.dataset_id WHERE ome_sessions_datasets.session_id=$SID) ".
		'AND NOT EXISTS '.
			"(SELECT ome_sessions_datasets.dataset_id WHERE ome_sessions_datasets.session_id=$SID ".
			'EXCEPT SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id) LIMIT 1) '.
		"WHERE session_id=$SID"
	);

}





# Returns the project ID (if any) associated with the current session.
# Optionally, pass the parameter ProjectName to get its ID.
# Optionally pass an array reference in DatasetIDs to get a project with those dataset IDs
# FIXME:  A very long list of dataset IDs will produce a very long line of SQL.
#    Possible work-around is to put the list in a temporary table.
sub GetProjectID () {
my $self = shift;
my %params = @_;
my $returnVal;

	if (defined $params{ProjectName} and $params{ProjectName}) {
		return $self->DBIhandle->selectrow_array (
			"SELECT project_id FROM projects WHERE name = '".$params{ProjectName}."'");
	} elsif (defined $params{DatasetIDs} and $params{DatasetIDs}->[0]) {
		if (scalar (@{$params{DatasetIDs}}) < $SQLLISTLIMIT) {
			my $datasetsSQL = join(',',@{$params{DatasetIDs}});
			return $self->DBIhandle->selectrow_array (
				'SELECT project_id from projects p WHERE NOT EXISTS '.
					'(SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id '.
					"EXCEPT SELECT datasets.dataset_id WHERE datasets.dataset_id IN ($datasetsSQL)) ".
				"AND NOT EXISTS (SELECT datasets.dataset_id WHERE datasets.dataset_id IN ($datasetsSQL) ".
					'EXCEPT SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id) '
			);
		} else {
#			$self->DBIhandle->do ('CREATE TEMPORARY TABLE foobar (dataset_id OID)');
#			foreach (@{$params{DatasetIDs}}) {
#				$self->DBIhandle->do ("INSERT INTO foobar VALUES ($_)");
#			}
#			my $datasetsSQL = 'SELECT dataset_id FROM foobar';
#			$returnVal = $self->DBIhandle->selectrow_array (
#				'SELECT project_id from projects p WHERE NOT EXISTS '.
#					'(SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id '.
#					"EXCEPT SELECT datasets.dataset_id WHERE datasets.dataset_id IN ($datasetsSQL)) ".
#				"AND NOT EXISTS (SELECT datasets.dataset_id WHERE datasets.dataset_id IN ($datasetsSQL) ".
#					'EXCEPT SELECT datasets_projects.dataset_id WHERE datasets_projects.project_id=p.project_id) '
#			);
#			$self->DBIhandle->do ('DROP TABLE foobar');
#			return $returnVal;
			return undef;
		}
	} else {
		$self->SetSessionProjectID();
		return $self->DBIhandle->selectrow_array (
			"SELECT project_id FROM ome_sessions WHERE session_id = ".$self->SID);
	}
}


# Returns the project name (if any) associated with the current session.
# Optionally, pass the parameter ProjectID to get its name.
sub GetProjectName () {
my $self = shift;
my %params = @_;

	if (defined $params{ProjectID} and $params{ProjectID}) {
		return $self->DBIhandle->selectrow_array (
			"SELECT name FROM projects WHERE project_id = ".$params{ProjectID});
	} else {
		return $self->DBIhandle->selectrow_array (
			"SELECT name FROM projects WHERE project_id = ome_sessions.project_ID ".
				"AND ome_sessions.session_ID=".$self->SID);
	}
}

# Return the names of all projects as an array reference.
sub GetProjectNames () {
my $self = shift;
	return $self->DBIhandle()->selectcol_arrayref ("SELECT name FROM projects");
}




sub DropView ($) {
my $self = shift;
my $viewName = shift;
	
	my $RaiseError = $self->DBIhandle->{RaiseError};
	$self->DBIhandle->{RaiseError} = 0;
	eval {
		$self->DBIhandle->do (qq/DROP VIEW "$viewName"/);
	};
	$self->DBIhandle->{RaiseError} = $RaiseError;
# The database will ignore further queries in this transaction block if we generated an error.
	$self->Commit();
}




sub CGIheader ()
{
	my $self = shift;
	my %params = @_;
	
	$params{-cookie} = [$self->SIDcookie,$self->RefererCookie];
	$params{-expires} = '-1d';
	return ($self->{cgi}->header(%params));
}

# Get a name for a temporary file.  The file will be created in the temp directory.
# Parameter one is a base name.  Parameter two is the extension, not including the '.'.  The filename will
# end in a '.' if no extension is provided.
# This method will generate a filename in the temp directory with a 3-digit number between the base-name and
# the extension (baseName-nnn.extension).
# The file name is guaranteed to be unique.  The file will be created, opened for writing and closed.
# FIXME: Nothing is done now to unlink this temporary file.  It is the caller's responsibility.
sub GetTempName ()
{
my $self = shift;
my $progName = shift;
my $extension = shift;
my $count=-1;
#my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP};
my $base_name;
local *FH;

	until (defined(fileno(FH)) || $count++ > 999)
	{
		$base_name = sprintf("%s/%s-%03d.%s", $tempDirectory, $progName,$count,$extension);
		sysopen(FH, $base_name, O_WRONLY|O_EXCL|O_CREAT);
	}
	if (defined(fileno(FH)) )
	{
		close (FH);
		return ($base_name);
	}
	else
	{
		return ();
	}
}



sub GetNewDatasetName {
my $self = shift;
my $baseName = shift;
my $count=-1;
#my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP};
my $filePath;
my $fileName;
local *FH;
my $extension = '';

	if ($baseName =~ /(.*)\.(.*)/) {$baseName = $1; $extension = $2;}
	until (defined(fileno(FH)) || $count++ > 100)
	{
		$fileName = sprintf("%s-%03d.%s", $baseName,$count,$extension);
		$filePath = "$datasetDirectory$fileName";
		sysopen(FH, $filePath, O_WRONLY|O_EXCL|O_CREAT);
	}
	if (defined(fileno(FH)) )
	{
		close (FH);
		if (wantarray) {
			return ($datasetDirectory,$fileName);
		} else {
			return ($filePath);
		}
	}
	else
	{
		return (undef);
	}
}


sub binPath {
	return ($binPath);
}

sub inWebServer {
	my $self = shift;
	return defined $ENV{SERVER_SIGNATURE};
}

sub gotBrowser {
	my $self = shift;
	return (exists $ENV{HTTP_USER_AGENT} and defined $ENV{HTTP_USER_AGENT} and (
		$ENV{HTTP_USER_AGENT} =~/Mosaic/ or
		$ENV{HTTP_USER_AGENT} =~/Mozilla/ or
		$ENV{HTTP_USER_AGENT} =~/MSIE/ or
		$ENV{HTTP_USER_AGENT} =~/iCab/ or
		$ENV{HTTP_USER_AGENT} =~/Lynx/ or
		$ENV{HTTP_USER_AGENT} =~/Opera/
		) )
}

sub inShell {
	my $self = shift;
	return exists $ENV{SHELL} and defined $ENV{SHELL};
}

sub hasConsole {
	my $self = shift;
	return defined $ENV{CONSOLE};
}

sub Connected {
	my $self = shift;
	return ($self->{dbHandle}->ping());
}

sub DBIhandle {
	my $self = shift;
	return ($self->{dbHandle});
}

sub errorMessage {
	my $self = shift;
	return $self->{errorMessage};
}
sub ReportError {
my $self = shift;
my $message = shift;

	$message = $self->errorMessage unless defined $message;
	print qq {
		<script language="JavaScript">
			<!--
				alert("Error:  $message");
			//-->
		</script>
		}
}



sub cgi {
	my $self = shift;
	return    $self->{cgi};
}

sub SID {
	my $self = shift;
	return    $self->{sessionID};
}

sub sessionKey {
	my $self = shift;
	return    $self->{sessionKey};
}

sub user {
	my $self = shift;
	return    $self->{user};
}


# Get a list of dataset views owned by the current user.
# N.B.:  This may be dataset dependent, and certainly is with Postgres because $dbh->table_info doesn't work as documented.
sub GetUserViews {
my $self = shift;
my $driverName = $self->DBIhandle->{Driver}->{Name};
my @views;

# If the database we're talking to is Postgres, then get the views from the pg_views system table.
	if ($driverName eq 'Pg') {
		@views = @{$self->DBIhandle->selectcol_arrayref(
			"select viewname from pg_views where viewowner = '".$self->user."'")};
		}
	
	return \@views;
}


# Get a list of dataset views not owned by the database (non-system views).
# Note that by default, users do not have access proviledges to other user's views.
# N.B.:  This may be dataset dependent, and certainly is with Postgres because $dbh->table_info doesn't work as documented.
sub GetViews {
my $self = shift;
my $driverName = $self->DBIhandle->{Driver}->{Name};
my @views;

# If the database we're talking to is Postgres, then get the views from the pg_views system table.
	if ($driverName eq 'Pg') {
		@views = @{$self->DBIhandle->selectcol_arrayref(
			"select viewname from pg_views where viewowner != 'postgres'")};
		}


	return \@views;
}






sub SIDcookie {
	my $self = shift;
	if ($self->gotBrowser()) {
		return $self->{cgi}->cookie (-name=>'OMEsessionKey',
			-value=>$self->{sessionKey},-path=>'/');
	} else {
		return undef;
	}

}

sub RefererCookie {
	my $self = shift;
	my $cookie;

	if (! $self->gotBrowser()) { return undef; }

	if ($self->{referer}) {
		$cookie = $self->{cgi}->cookie (-name=>'OMEreferer',-value=>$self->{referer},-path=>'/');
	}
	else {
		$cookie = $self->{cgi}->cookie (-name=>'OMEreferer',-value=>"",-expires=>'-1d',-path=>'/');
	}
	return $cookie;

}


sub NumSelectedDatasets {
	my $self = shift;
	if (exists $self->{SelectedDatasets} and defined $self->{SelectedDatasets} and scalar @{$self->{SelectedDatasets}} > 0) {
		$self->{NumSelectedDatasets} = scalar @{$self->{SelectedDatasets}};
	} else {
		$self->{NumSelectedDatasets} = $self->{dbHandle}->selectrow_array ('SELECT count(*) FROM ome_sessions_datasets WHERE SESSION_ID='.$self->{sessionID});
	}
	return ($self->{NumSelectedDatasets});

}


sub BaseURL {
	my $self = shift;
	return    $self->{OMEbaseURL};
}


sub LoginURL {
	my $self = shift;
	return    $self->{OMEloginURL};
}


sub NavURL {
	my $self = shift;
	return    $self->{OMEnavURL};
}


sub SelectDatasetsURL {
	my $self = shift;
	return    $self->{OMEselectDatasetsURL};
}


sub SessionInfoURL {
	my $self = shift;
	return    $self->{OMEsessionInfoURL};
}


sub DefaultAnalysisURL {
	my $self = shift;
	return    $self->{OMEdefaultAnalysisURL};
}


sub ViewDatasetsURL {
	my $self = shift;
	return    $self->{ViewDatasetsURL};
}

1;

=pod

=back

=cut

