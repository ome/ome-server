#!/usr/bin/perl -w
# OME/Tasks/Analysis/Engine/BlockingSlaveWorkerCGI.pl

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

BlockingSlaveWorkerCGI - A worker for the OME Analysis Engine that can be called
remotely with a CGI interface.


=head1 SYNOPSIS

 curl 'http://worker1.host.com/BlockingSlaveWorkerCGI.pl?\
	DataSource=dbi:Pg:dbname=ome;host=back-end.host.com&\
	SessionKey=9bca3b0e1a8fbde72aeb0db4f41e7d58&\
	MEX=123&Dependence=i&Target=465'

The DataSource, SessionKey, MEX, and Dependence are required parameters.

Target is required if Dependence is 'I' or 'D' (ImageID or DatasetID respectively)

=head1 DESCRIPTION

BlockingSlaveWorkerCGI is about as dumb as nails.  Any back-end came come along and have it
do its bidding (enslave it).  Also, its blocking, so the request will hang until this worker
is done.  It does maintain a lock-file with its PID so that it can be determined how many workers
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
use OME::Install::Environment;
use OME::SessionManager;
use OME::Analysis::Engine::UnthreadedPerlExecutor;


use constant ENV_FILE        => '/etc/ome-install.store';
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


# Get the installation environment
OME::Install::Environment::restore_from (ENV_FILE);
my $environment = initialize OME::Install::Environment;
my $worker_conf = $environment->worker_conf();
do_response (NOT_IMPLEMENTED,"Workers not configured") unless $worker_conf;

# Set the path to the pid file
$PID_FILE_PATH = $environment->tmp_dir().'/'.PID_FILE;

# Determine if there are any available workers
do_response (SERVER_BUSY,"Too many workers running") unless
	register_worker($worker_conf->{MaxWorkers});

# Parse parameters
our $CGI = new CGI;
my ($DataSource,$SessionKey,$DBUser,$DBPassword,$MEX_ID,$Dependence,$Target_ID) = get_params ($CGI);

# Try to get a remote session
my $session = OME::SessionManager->createSession ($SessionKey,{
	DataSource => $DataSource,
	DBUser     => $DBUser,
	DBPassword => $DBPassword,
	});
do_response (BAD_REQUEST,"Unable to get remote session") unless $session;

# Get our MEX object and target object if needed.
my $factory = $session->Factory();
my $mex = $factory->loadObject ('OME::ModuleExecution',$MEX_ID);
do_response (BAD_REQUEST,"Unable to load MEX ID $MEX_ID") unless $mex;

my $target;
$target = $factory->loadObject ('OME::Image',$Target_ID) if $Dependence eq 'I';
$target = $factory->loadObject ('OME::Dataset',$Target_ID) if $Dependence eq 'D';
do_response (BAD_REQUEST,"Unable to load Target ID $Target_ID")
	if ($Dependence eq 'I' or $Dependence eq 'D') and not defined $target;

# Off to the races
eval {
	my $executor = OME::Analysis::Engine::UnthreadedPerlExecutor->new();
	$executor->executeModule ($mex,$Dependence,$target);
};

my $status = $mex->status();
my $error;
$error = $mex->error_message() if $status and $status eq 'ERROR';

# report error
if ($error) {
	$session->rollbackTransaction();
	do_response (SERVER_ERROR,$error) if $error;
}

# Commit transaction 
$session->commitTransaction();

# Respond OK and exit
do_response (STATUS_OK,'OK');


################
# End of Code
################


# Note that this always results in an exit
sub do_response {
my ($code,$message) = @_;
# If the message spans multiple lines, put the first line in the header, and the rest as text/plain

	my @lines = split (/\n/,$message);
	
	my $line1 = shift @lines;
	print "HTTP/1.1 $code $line1\015\012".
		"Content-Type: text/plain\015\012\015\012";
	print "$line1\n",join ("\n",@lines),"\n";
	unregister_worker ();
	exit;
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
	my ($DataSource,$SessionKey,$DBUser,$DBPassword); # DataSource is required
	my ($MEX,$Dependence,$Target);        # $target can be undef only if $Dependence = 'G'
	
	$DataSource = $CGI->url_param('DataSource');
	$DataSource = $CGI->param('DataSource') unless $DataSource;
	do_response (BAD_REQUEST,"DataSource not specified") unless $DataSource;
	
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
	return ($DataSource,$SessionKey,$DBUser,$DBPassword,$MEX,$Dependence,$Target);
}

1;

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>

=cut
