#!/usr/bin/perl -w
# OME/Analysis/Engine/DistributedAnalysisEngineCGI.pl

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
# Written by:    Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

=head1 NAME

DistributedAnalysisEngineCGI - The master-node of the OME Analysis Engine that
is called by remote execution worker-agents.


=head1 SYNOPSIS

curl 'http://worker1.host.com/DistributedAnalysisEngineCGI.pl?\
	Method=RegisterWorker&\
	URL=???&\
	PID=XXXX'
	
	(Assigns a WorkerID to the worker and returns WorkerID)

curl 'http://worker1.host.com/DistributedAnalysisEngineCGI.pl?\
	Method=GetJob&\
	WorkerID=???'
	
	Returns:
	DataSource=dbi:Pg:dbname=ome;host=back-end.host.com&\
	SessionKey=9bca3b0e1a8fbde72aeb0db4f41e7d58&\
	NEX=123'
	
	The DataSource, SessionKey, MasterID, MEX, and Dependence are required parameters.
	DataSource is a perl DBI Datasource Name (DSN).
	SessionKey is the standard OME SessionKey
	MasterID is an ID that uniquely identifies an
	L<OME::Analysis::Engine::SimpleWorkerExecutor|OME::Analysis::Engine::SimpleWorkerExecutor> instance.

	Target is required if Dependence is 'I' or 'D' (ImageID or DatasetID respectively)

curl 'http://worker1.host.com/DistributedAnalysisEngineCGI.pl?\
	Method=JobUpdate&\
	WorkerID=???'
	
	(Returns Message Ack -- these messages keep the master satisfied that the
	worker is still running and trying to be productive)

curl 'http://worker1.host.com/DistributedAnalysisEngineCGI.pl?\
	Method=FinishedJob&\
	WorkerID=???'
	
	(Returns Message Ack)

curl 'http://worker1.host.com/DistributedAnalysisEngineCGI.pl?\
	Method=UnregisterWorker&\
	WorkerID=???'
	
	(The Master Node makes a note that this worker has signed off)
	(Returns Message Ack)
	


=head1 DESCRIPTION

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
use CGI qw/:standard -no_xhtml/;
use Log::Agent;
use Time::HiRes qw(gettimeofday tv_interval);
require Log::Agent::Driver::File;

# Comment this out if you do not want debug statements written to apache's error log
my $driver = Log::Agent::Driver::File->make(
	-prefix     => "$0",
	-stampfmt   => "date",
	-showpid    => 1,
	);
logconfig(-driver => $driver, -level => 'debug');

use constant STATUS_OK       => 200;
use constant BAD_REQUEST     => 400;
use constant SERVER_ERROR    => 500;
use constant NOT_IMPLEMENTED => 501;
use constant SERVER_BUSY     => 503;

################
# Start of Code
################

our $CGI = new CGI;
our $SESSION = OME::SessionManager->su_session();
our $FACTORY = $SESSION->Factory();

# figure out what method is called
my $Method = $CGI->url_param('Method');
$Method = $CGI->param('Method') unless $Method;
do_response (BAD_REQUEST,"Method not specified") unless $Method;

if ($Method eq 'RegisterWorker') {
	my ($Worker_URL, $Worker_PID); # all are required

	$Worker_URL = $CGI->url_param('URL');
	$Worker_URL = $CGI->param('URL') unless $Worker_URL;
	do_response (BAD_REQUEST,"Worker's URL not specified") unless $Worker_URL;
	
	$Worker_PID = $CGI->url_param('PID');
	$Worker_PID = $CGI->param('PID') unless $Worker_PID;
	do_response (BAD_REQUEST,"Worker's PID not specified") unless $Worker_PID;

	my $worker = $FACTORY->newObject ('OME::Analysis::Engine::Worker',
									 {
									  PID => $Worker_PID,
									  URL => $Worker_URL,
									  last_used => 'now()',
									  status => 'IDLE'
									 });
	do_response (SERVER_ERROR,"Unable to register new worker: $@") unless $worker;

	$worker->storeObject();
	$SESSION->commitTransaction();

	do_response (STATUS_OK,$worker->id());

} elsif ($Method eq 'GetJob') {
	my $Worker_ID; # required

	$Worker_ID = $CGI->url_param('WorkerID');
	$Worker_ID = $CGI->param('WorkerID') unless $Worker_ID;
	do_response (BAD_REQUEST,"Worker's ID not specified") unless $Worker_ID;

	get_job ($Worker_ID);
} elsif ($Method eq 'JobUpdate') {
	my $Worker_ID; # required

	$Worker_ID = $CGI->url_param('WorkerID');
	$Worker_ID = $CGI->param('WorkerID') unless $Worker_ID;
	do_response (BAD_REQUEST,"Worker's ID not specified") unless $Worker_ID;
	
	# NOT IMPLEMENTED, IMPLEMENTATION GOES HERE
	do_response (STATUS_OK,'OK');
} elsif ($Method eq 'FinishedJob') {
	my $Worker_ID; # required

	$Worker_ID = $CGI->url_param('WorkerID');
	$Worker_ID = $CGI->param('WorkerID') unless $Worker_ID;
	do_response (BAD_REQUEST,"Worker's ID not specified") unless $Worker_ID;

	my $worker = $FACTORY->findObject ('OME::Analysis::Engine::Worker',
										 {
										  id => $Worker_ID,
										 });
	do_response (SERVER_ERROR,"Worker $Worker_ID doesn`t seem to exist: $@") unless $worker;
	do_response (SERVER_ERROR,"Worker $Worker_ID is not BUSY. It's ".$worker->status())
		unless ($worker->status() eq 'BUSY');

	my $job = $FACTORY->findObject ('OME::Analysis::Engine::Job',
						  {
						   executing_worker => $Worker_ID,						  
						   status => 'BUSY',
						  });
	do_response (SERVER_ERROR,"Worker $Worker_ID doesn`t seem to be executing a job: $@") unless $job;

	my $nex  = $job->NEX();
	my $node = $nex->analysis_chain_node();
	my $chex = $nex->analysis_chain_execution();
	
	my $dependence = $node->dependence();
	logdbg "debug", "FinishedJob (nex:".$nex->id()." node:".$node->id()." chex:".$chex->id();
	logdbg "debug", "    MEX is ".$nex->module_execution()->id();

	my $target;
	if ($dependence eq 'I') {
		$target = $nex->module_execution()->image();
	}elsif ($dependence eq 'D') {
		$target = $nex->module_execution()->dataset();
	}

	$job->deleteObject(); # must be done before finishedJob();

	###########################################
	# worker can now go execute some more jobs
	##########################################
	$worker->status('IDLE');
	$worker->executing_mex(undef);
	$worker->storeObject();
	$SESSION->commitTransaction();
	non_exiting_do_response (STATUS_OK,'OK');

	###########################################
	# master can analyze chain structure to add new jobs
	##########################################

	# change sessions from the super-user to the experimenter (so the new MEXs
	# are created in the name of the experimenter)
	my $experimenter = $FACTORY->findObject ('OME::SemanticType::BootstrapExperimenter',
					  {
					   id => $nex->module_execution->experimenter->id(),
					  });
	my $sudo_session = OME::SessionManager->sudo_session($experimenter->OMEName());
	OME::Analysis::Engine->finishedJob($chex,$nex,$node,$target);

	$sudo_session->commitTransaction();

} elsif ($Method eq 'UnregisterWorker') {
	my $Worker_ID; # required

	$Worker_ID = $CGI->url_param('WorkerID');
	$Worker_ID = $CGI->param('WorkerID') unless $Worker_ID;
	do_response (BAD_REQUEST,"Worker's ID not specified") unless $Worker_ID;

	non_exiting_do_response (STATUS_OK,'OK');
	
	my $worker = $FACTORY->findObject ('OME::Analysis::Engine::Worker',
									 {
									  id => $Worker_ID,
									 });
	if ($worker) {									
		# FIXME: if the worker is executing a NEX when it is unregistered, clean up the NEX
		$worker->last_used ('now()');
		$worker->status ('OFFLINE');
		$worker->storeObject();
		$SESSION->commitTransaction();
	}	
} else {
	do_response (BAD_REQUEST,"Method $Method is not supported");
}

exit;
################
# End of Code
################

sub get_job {
	my ($worker_id) = shift;

	my $worker = $FACTORY->findObject ('OME::Analysis::Engine::Worker',
										 {
										  id => $worker_id,
										 });
	do_response (SERVER_ERROR,"Worker $worker_id doesn`t seem to exist: $@") unless $worker;
	do_response (SERVER_ERROR,"Worker $worker_id is not IDLE. It's ".$worker->status())
		unless ($worker->status() eq 'IDLE');

	my $nex = OME::Analysis::Engine->getJob($worker_id);

	if (defined ($nex)) {
		my $ENVIRONMENT = OME::Install::Environment->initialize();
		
		# Parameters for database connection 
		my $DATA_SOURCE = OME::Database::Delegate->getDefaultDelegate()->getDSN();
		$DATA_SOURCE .= ';host='.$ENVIRONMENT->hostname()
			unless ($DATA_SOURCE =~ /;host=\S+/);
		my $DB_conf = $ENVIRONMENT->DB_conf();
		my $DB_USER = $DB_conf->{User};
		$DB_USER = getpwuid($<) unless $DB_USER;
		my $DB_PASS = $DB_conf->{Password};
		$DB_PASS = "" unless $DB_PASS;

		# convert the superuser's SessionKey to the right experimenter's SessionKey
		my $experimenter = $FACTORY->findObject ('OME::SemanticType::BootstrapExperimenter',
						  {
						   id => $nex->module_execution->experimenter->id(),
						  });
		my $sudo_session = OME::SessionManager->sudo_session($experimenter->OMEName());
		my $SessionKey = $sudo_session->SessionKey();

		do_response (STATUS_OK, "NEX=".$nex->id()."\n".
								"DataSource=".$DATA_SOURCE."\n".
							    "DBUser=".$DB_USER."\n".
							    "DBPassword=".$DB_PASS."\n".
							    "SessionKey=".$SessionKey."\n");
	} else {
		do_response (STATUS_OK, "No Jobs");
	}
}

# Note that this always results in an exit
sub do_response {
my ($code,$message) = @_;
	non_exiting_do_response($code,$message);
	exit 1;
}

sub non_exiting_do_response {
my ($code,$message) = @_;
# If the message spans multiple lines, put the first line in the header, and the rest as text/plain
	my @lines = split (/\n/,$message);
	
	my $line1 = shift @lines;
	print $CGI->header(-type => 'text/plain', -status => "$code $line1", -Connection => 'Close');

	print "$line1\n".join ("\n",@lines)."\n";
	logerr "$line1\n".join ("\n",@lines) unless $code == STATUS_OK;
}

1;

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>

=cut
