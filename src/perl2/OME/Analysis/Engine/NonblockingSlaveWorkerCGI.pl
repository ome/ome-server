#!/usr/bin/perl -w
# OME/Tasks/Analysis/Engine/NonBlockingSlaveWorkerCGI.pl

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------

=head1 NAME

NonBlockingSlaveWorkerCGI - A worker for the OME Analysis Engine that can be called
remotely with a CGI interface.


=head1 SYNOPSIS

 curl 'http://worker1.host.com/NonBlockingSlaveWorkerCGI.pl?\
	DataSource=dbi:Pg:dbname=ome;host=back-end.host.com&\
	SessionKey=9bca3b0e1a8fbde72aeb0db4f41e7d58&\
	MasterID=5t11f1Qnm4Lw&\
	MEX=123&Dependence=i&Target=465'

The DataSource, SessionKey, MasterID, MEX, and Dependence are required parameters.
DataSource is a perl DBI Datasource Name (DSN).
SessionKey is the standard OME SessionKey
MasterID is an ID that uniquely identifies an
L<OME::Analysis::Engine::SimpleWorkerExecutor|OME::Analysis::Engine::SimpleWorkerExecutor> instance.

Target is required if Dependence is 'I' or 'D' (ImageID or DatasetID respectively)

=head1 DESCRIPTION

NonBlockingSlaveWorkerCGI is about as dumb as nails.  Any back-end can come along and have it
do its bidding (enslave it). It does maintain a lock-file with its PID so that it can be determined how many workers
are actually running on a given server.  If the request will cause the number of lock files in
$TEMP_DIR/Workers/ to exceed the number specified by max_workers in the install environment file,
503 Status will be returned.

It will return the following status codes:

 Request was properly processed: 200 OK
 Unable to connect to DB:        400 Bad request
 Died during execution:          500 Server error
 Too many workers running:       503 Service temporarily unavailable
 
=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use CGI qw(:standard);
use Fcntl qw (:flock O_RDWR O_CREAT); # import LOCK_* and OPEN constants
use Log::Agent;

use OME::Install::Environment;
use OME::SessionManager;
use OME::Analysis::Engine::UnthreadedPerlExecutor;
use OME::Fork;
use OME::Tasks::NotificationManager;


use constant PID_FILE        => 'WorkerPIDs';
our $PID_FILE_PATH; # set to $environment->tmp_dir().'/'.PID_FILE

use constant STATUS_OK       => 200;
use constant BAD_REQUEST     => 400;
use constant SERVER_ERROR    => 500;
use constant NOT_IMPLEMENTED => 501;
use constant SERVER_BUSY     => 503;



################
# Start of Code
################

our $CGI = new CGI;

# Get the installation environment
my $environment = OME::Install::Environment->initialize();
my $worker_conf = $environment->worker_conf();
do_response (NOT_IMPLEMENTED,"Workers not configured") unless $worker_conf;

# Set the path to the pid file
$PID_FILE_PATH = $environment->tmp_dir().'/'.PID_FILE;

# Determine if there are any available workers
do_response (SERVER_BUSY,"Too many workers running") unless
	register_worker($worker_conf->{MaxWorkers});

# Parse parameters
my ($DataSource,$SessionKey,$DBUser,$DBPassword,
	$MEX_ID,$Dependence,$Target_ID,
	$Notices,$Worker_ID,$MasterID) = get_params ($CGI);

# Try to get a remote session
my $session;
eval {
	$session = OME::SessionManager->createSession ($SessionKey,{
		DataSource => $DataSource,
		DBUser     => $DBUser,
		DBPassword => $DBPassword,
		});
};
do_response (SERVER_ERROR,"Unable to get remote session: $@") unless $session;

# Get our MEX object and target object if needed.
my ($factory,$mex);
eval {
	$factory = $session->Factory();
	$mex = $factory->loadObject ('OME::ModuleExecution',$MEX_ID);
};
do_response (SERVER_ERROR,"Unable to load MEX ID $MEX_ID: $@") unless $mex;

my $target;
eval {
	$target = $factory->loadObject ('OME::Image',$Target_ID) if $Dependence eq 'I';
	$target = $factory->loadObject ('OME::Dataset',$Target_ID) if $Dependence eq 'D';
};
do_response (SERVER_ERROR,"Unable to load Target ID $Target_ID: $@")
	if ($Dependence eq 'I' or $Dependence eq 'D') and not defined $target;

my $worker;
eval {
	$worker = $factory->loadObject ('OME::Analysis::Engine::Worker',$Worker_ID);
};
do_response (SERVER_ERROR,"Unable to load Worker ID $Worker_ID: $@") unless $worker;

# Set the worker status to 'BUSY'
eval {
	$worker->status('BUSY');
	$worker->PID($$);
	$worker->master($MasterID);
	
	$worker->storeObject();
	
	# Register the module execution for later
	OME::Fork->doLater ( sub {
		# Note that this executor sets the module status on error and stores the MEX
		# We probably don't need an eval here, because there's already one in this
		# executor.
		logdbg "debug", "NonBlockingSlaveWorkerCGI: executing MEX=$MEX_ID, with Dependence=$Dependence and Target=$target";
		eval {
			my $executor = OME::Analysis::Engine::UnthreadedPerlExecutor->new();
			$executor->executeModule ($mex,$Dependence,$target);
		};
		if ($@) {
			logdbg "debug", "NonBlockingSlaveWorkerCGI: ERROR executing MEX=$MEX_ID, with Dependence=$Dependence and Target=$target:\n$@";
		}
		$worker->status('IDLE');
		$worker->last_used('now()');
		$worker->PID(undef);
		$worker->master(undef);
		$worker->storeObject();
		OME::Tasks::NotificationManager->notify ($_) foreach (@$Notices);
		unregister_worker ();
		$session->commitTransaction();
		logdbg "debug", "NonBlockingSlaveWorkerCGI: finished executing MEX=$MEX_ID, with Dependence=$Dependence and Target=$target";
	});
	# Commit transaction, setting worker status to BUSY,
	$session->commitTransaction();
};

if ($@) {
	do_response (SERVER_ERROR,'Could not initialize worker for MEX $MEX_ID: $@');
} else {
	# Send an OK response and exit
	do_response (STATUS_OK,'OK');
}

# The sub we registered with OME::Fork->doLater will execute now (after we've sent the response).

################
# End of Code
################


# Note that this always results in an exit
sub do_response {
my ($code,$message) = @_;
# If the message spans multiple lines, put the first line in the header, and the rest as text/plain

	my @lines = split (/\n/,$message);
	
	my $line1 = shift @lines;
	print $CGI->header(-type => 'text/plain', -status => "$code $line1", -Connection => 'Close');

	print "$line1\n".join ("\n",@lines)."\n";
	logerr "$line1\n".join ("\n",@lines)."\n" unless $code == STATUS_OK;
	
	# We're still running if status is OK
	unregister_worker () unless $code == STATUS_OK;
	exit 1;
}


sub register_worker {
	my($max_pids) = @_;
	sysopen(PID_FH, $PID_FILE_PATH, O_RDWR | O_CREAT)
		or die "Couldn't open $PID_FILE_PATH: $!";

	# Wait here until we can get a lock.
	flock(PID_FH,LOCK_EX)
		or die "Couldn't acquire lock on $PID_FILE_PATH: $!";

	# Get the PIDS
	my @pids = <PID_FH>;

	# Ping each PID to see if its alive, and push the live ones on @live_pids
	my @live_pids=();
	foreach my $pid (@pids) {
		chomp $pid;
		if ($pid and $pid =~ /^\d+$/ and kill (0, $pid) > 0) {
			push (@live_pids, $pid);
		}
	}

	# If there are less than the maximum live pids, push ourselves on
	my $worker_registered = undef;
	if (scalar @live_pids < $max_pids ) {
		push (@live_pids,$$);
		$worker_registered = 1;
	}

	# Rewind and put the live PIDs back in the file
	seek (PID_FH,0,0);
	print PID_FH join ("\n",@live_pids)."\n";

	# Truncate the file, unlock and close
	truncate (PID_FH,tell (PID_FH));
	flock(PID_FH,LOCK_UN);
	close (PID_FH);

	return ($worker_registered);
}


sub unregister_worker {
	sysopen(PID_FH, $PID_FILE_PATH, O_RDWR | O_CREAT) or
		die "Couldn't open $PID_FILE_PATH: $!";

	# Wait here until we can get a lock.
	flock(PID_FH,LOCK_EX) or
		die "Couldn't acquire lock on $PID_FILE_PATH: $!";

	# Get the PIDS
	my @pids = <PID_FH>;

	# Ping each PID to see if its alive,
	# and push the live ones on @live_pids
	# Except this one.
	my @live_pids=();
	foreach my $pid (@pids) {
		chomp $pid;
		if ( $pid and $pid =~ /^\d+$/ and $pid != $$ and kill (0, $pid) > 0) {
			push (@live_pids, $pid);
		}
	}

	# Rewind and put the live PIDs back in the file
	seek (PID_FH,0,0);
	print PID_FH join ("\n",@live_pids)."\n";

	# Truncate the file, unlock and close
	truncate (PID_FH,tell (PID_FH));
	flock(PID_FH,LOCK_UN);
	close (PID_FH);

	return 1;
}


sub get_params {
	my ($DataSource,$SessionKey,$DBUser,$DBPassword,$MasterID); # all are required
	my ($MEX,$Dependence,$Target);        # $target can be undef only if $Dependence = 'G'
	my @Notices;
	my $WorkerID;
	
	$DataSource = $CGI->url_param('DataSource');
	$DataSource = $CGI->param('DataSource') unless $DataSource;
	do_response (BAD_REQUEST,"DataSource not specified") unless $DataSource;
	
	# If the DSN's host is not set, then the caller is self-hosting the DB, which means
	# we set the host for our DSN to the caller's IP.
	# If the DSN's host is not set and the caller is 127.0.0.1, then we leave the DSN alone
	# because everything (the caller, the worker, and the DB) are on localhost.
	my $host = $ENV{REMOTE_ADDR};
	$DataSource .= ';host='.$host
		unless ($host eq '127.0.0.1' or $DataSource =~ /;host=\S+/);
	logdbg "debug", "NonBlockingSlaveWorkerCGI: DataSource = $DataSource";

	$DBUser = $CGI->url_param('DBUser');
	$DBUser = $CGI->param('DBUser') unless $DBUser;
	
	$DBPassword = $CGI->url_param('DBPassword');
	$DBPassword = $CGI->param('DBPassword') unless $DBPassword;
	
	$SessionKey = $CGI->url_param('SessionKey');
	$SessionKey = $CGI->param('SessionKey') unless $SessionKey;
	do_response (BAD_REQUEST,"SessionKey not specified") unless $SessionKey;
	
	$MEX = $CGI->url_param('MEX');
	$MEX = $CGI->param('MEX') unless $MEX;
	do_response (BAD_REQUEST,"MEX not specified") unless $MEX;
	$MEX = int ($MEX);
	do_response (BAD_REQUEST,"MEX does not appear to be a positive integer") unless $MEX;
	
	$Dependence = $CGI->url_param('Dependence');
	$Dependence = $CGI->param('Dependence') unless $Dependence;
	do_response (BAD_REQUEST,"Dependence not specified") unless $Dependence;
	$Dependence = uc ($Dependence);
	
	$Target = $CGI->url_param('Target');
	$Target = $CGI->param('Target') unless $Target;
	if ($Dependence eq 'I' or $Dependence eq 'D') {
		do_response (BAD_REQUEST,"Target not specified. Required for Dependence='$Dependence'") unless $Target;
		$Target = int ($Target);
		do_response (BAD_REQUEST,"Target does not appear to be a positive integer") unless $Target;
	}
	
	@Notices = $CGI->url_param ('Notice');
	$WorkerID = $CGI->url_param ('WorkerID');
	do_response (BAD_REQUEST,"WorkerID must be specified") unless $WorkerID;
	$WorkerID = int ($WorkerID);
	do_response (BAD_REQUEST,"WorkerID must be a positive integer") unless $WorkerID;

	$MasterID = $CGI->url_param('MasterID');
	$MasterID = $CGI->param('MasterID') unless $MasterID;
	do_response (BAD_REQUEST,"MasterID must be specified") unless $MasterID;

	return ($DataSource,$SessionKey,$DBUser,$DBPassword,$MEX,$Dependence,$Target,\@Notices,$WorkerID,$MasterID);
}

1;

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>

=cut
