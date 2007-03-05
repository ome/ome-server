# OME/Analysis/Engine/SimpleWorkerExecutor.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:	 Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Analysis::Engine::SimpleWorkerExecutor;

=head1 NAME

OME::Analysis::Engine::SimpleWorkerExecutor - an implementation of the
L<OME::Analysis::Engine::Executor|OME::Analysis::Engine::Executor>
interface which executes modules by calling one of the workers represented by the
L<OME::Analysis::Engine::Worker|OME::Analysis::Engine::Worker> class.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use OME::Util::cURL;
use Log::Agent;
use Sys::Hostname;
use CGI qw/-no_xhtml/;

use OME::Session;
use OME::Analysis::Engine::Worker;
use OME::Tasks::NotificationManager;
use OME::Database::Delegate;
use OME::Install::Environment;

use constant SERVER_BUSY     => 503;
our $DATA_SOURCE;
our $DB_USER;
our $DB_PASS;


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	unless ($DATA_SOURCE) {
		$DATA_SOURCE = OME::Database::Delegate->getDefaultDelegate()->getDSN();
		my $DB_conf = OME::Install::Environment->initialize()->DB_conf();
		$DB_USER = $DB_conf->{User};
		$DB_PASS = $DB_conf->{Password};
		$DB_USER = getpwuid($<) unless $DB_USER;

		# Uncomment this next line if you want to use a Mac for a backend
		# and a non-mac for the worker nodes.
		# Note that this only works if your computer name (i.e. the part before '.local')
		# gets properly resolved by your DNS server
		# Also, this is only necessary if your mac uses a non-localhost DB, which is also on
		# a .local domain.
#		$DATA_SOURCE =~ s/\.local//;
	}

# When DBUser is not presented to the worker node as a url parameter, it defaults
# to the name of the apache user on the worker node. It needs to be the name of
# a postgres user on the backend. Here is the error I get trying to use my 
# laptop as the backend and ome as the worker node:
# ModPerl::Registry: DBI connect('dbname=ome;host=siah-tibook','',...) failed: FATAL 1:  user "apache" does not exist at /usr/lib/perl5/site_perl/5.8.3/OME/Database/Delegate.pm line 269\n
# I can't get this from the install environment because it's not set.
	my $self = {
	# This is a unique ID for this executor instance
		instance_id => undef,
	# Array of hashrefs, keyed by 'MexID','Dep','TargetID'
		queue       => [],
		UA          => undef,
	# The messages the worker will send us when its done.
		OurWorker   => undef,
		AnyWorker   => undef,
		DBUser => $DB_USER,
		DBPassword => $DB_PASS,
	};
	bless $self, $class;
	
	# Generate a unique instace ID for ourselves
	my $codecVocab = [0..9,'a'..'z','A'..'Z'];
	$self->{instance_id} = 
		to_base ($codecVocab,$$).
		to_base ($codecVocab,time()).
		to_base ($codecVocab,int(rand(65535))); 
	
	# Get our user agent
	$self->{UA} = OME::Util::cURL->new ();

	# Get our DataSource
	$self->{DataSource}	  = $DATA_SOURCE;

	logdbg "debug", "SimpleWorkerExecutor->new: Registering listeners";
	
	# Register our listener
	$self->{OurWorker} = 'WorkerIdle_'.$self->{instance_id};
	$self->{AnyWorker} = 'WorkerIdle';
	OME::Tasks::NotificationManager->registerListener ($self->{OurWorker});
	OME::Tasks::NotificationManager->registerListener ($self->{AnyWorker});

	logdbg "debug", "SimpleWorkerExecutor->new: preparing the backup unthreaded_executor";
	my $unthreaded_executor  = 'OME::Analysis::Engine::UnthreadedPerlExecutor';
    $unthreaded_executor->require();
    $self->{unthreaded_executor} = $unthreaded_executor->new();

	logdbg "debug", "SimpleWorkerExecutor->new: returning new executor";
	
	return $self;
}

#
# Get an idle worker
sub getWorker {
	my ($self) = @_;
	my @workers = OME::Session->instance()->Factory()->findObjects (
		'OME::Analysis::Engine::Worker',{
			status	=> 'IDLE',
			__order => 'last_used',
			__limit => 1,
		});
	return ($workers[0]);
}

#
# Count busy workers.  The count is only for workers pressed by this
# executor instance
sub countBusyWorkers {
	my ($self) = @_;
	return OME::Session->instance()->Factory()->countObjects (
		'OME::Analysis::Engine::Worker',{
			status	=> 'BUSY',
			master  => $self->{instance_id},
		});
}

# Free busy workers (e.g. after a chain execution is interrupted with ctrl^Z)
# cleans up the mess in the analysis_workers table.
sub freeBusyWorkers {
	my ($self) = @_;
	
	my @workers = OME::Session->instance()->Factory()->findObjects (
		'OME::Analysis::Engine::Worker',{
			status	=> 'BUSY',
			master  => $self->{instance_id},
	});
	
	#
	# TODO: signal the worker node to kill the running workers
	#
	
	# clear the workers' table
	foreach (@workers) {
		$_->refresh();
		$_->executing_mex(undef);
		$_->master(undef);
		$_->PID(undef);
		$_->status("IDLE");
		$_->scheduling_token(undef);
		$_->storeObject();
	}
	OME::Session->instance()->commitTransaction();
	logdbg "debug", "SimpleWorkerExecutor->freeBusyWorkers: finished";
}

sub inspectWorkers {
	my ($self) = @_;
	logdbg ("debug", "inspectWorkers");
	my @workers = OME::Session->instance()->Factory()->findObjects (
		'OME::Analysis::Engine::Worker',{
			status	=> 'BUSY',
			master  => $self->{instance_id},
	});
	
	foreach my $worker (@workers) {
		my $elapsed_time = $worker->elapsed_since_last_used();
#		print "WorkerID is".$worker->id()." - elapsed time is $elapsed_time\n";
		# after 5 min be sure that worker's MEX status was set to busy
		if ($elapsed_time > 60) {
			my $mex = $worker->executing_mex();
			
			if ($mex->status ne "BUSY") {
				logdbg "debug", "inspectWorkers: Worker (".$worker->id().")'s MEX isn't busy";
				$self->fixBrokenWorker($worker);
			}
		}
		
		# after 50min the worker is doing something weird and we will pass the
		# mex to another worker for executing
		if ($elapsed_time > 60*60) {
			logdbg "debug", "inspectWorkers: Worker (ID".$worker->id().") has been executing for too long";
			$self->fixBrokenWorker($worker);
		}
	}
#	logdbg ("debug", "inspectWorkers: finished");
}

sub fixBrokenWorker {
	my ($self, $worker) = @_;
	my $mex = $worker->executing_mex();
	logdbg ("debug", "fixBrokenWorker. Worker: ".$worker->id()."  MEX: ".$worker->executing_mex->id());
	
	# unassign the MEX from current worker, ATM the worker is simply returned as IDLE
	$worker->last_used('now()'); # so the broken worker won`t be selected as the first to be used
	$worker->PID(undef);
	$worker->master(undef);
	$worker->executing_mex(undef);
	$worker->scheduling_token('fixed '.localtime time);
	$worker->status('IDLE');
	$worker->storeObject();
	
	# clean up the MEX
	# TODO: figure out if the MEX has made any attributes, if so, delete the
	# attributes
	$mex->status('UNFINISHED');
	$mex->executed_by_worker(undef);
	$mex->storeObject();
	
	# put the MEX back on the module execution queue
	my $queue = $self->{queue};
	my $dependence = $mex->dependence();
	my $target;
	if ($dependence eq 'I') {
		$target = $mex->image_id();
	} elsif ($dependence eq 'D') {
		$target = $mex->dataset_id();
	}

	my $job = {
		MEX          => $mex->id(),
		Dependence   => $dependence,
		Target       => $target,
		DataSource   => $self->{DataSource},
		DBUser       => $self->{DBUser},
		DBPassword   => $self->{DBPassword},
	};
	push (@$queue,$job);
	OME::Session->instance()->commitTransaction();
}

#
# Make a worker do something
# returns 1 or undef.
sub pressWorker {
	my ($self,$worker,$job) = @_;
	
	return undef unless $worker and $job and $job->{MEX};
	
	$job->{WorkerID} = $worker->id();

	# Put together the url parameters. Use CGI to make all the characters safe.
	my $q = CGI->new($job);
	# Put our notices on the parameter list
	$q->param( "Notice", $self->{OurWorker}, $self->{AnyWorker} );
	# Put our instance ID as the MasterID
	$q->param( "MasterID", $self->{instance_id} );
	$q->param( "SessionKey", OME::Session->instance()->SessionKey() );
	
	my $params = $q->self_url();
	undef $q;
	$params =~ s/.*?\?//; # Strip the leading junk. ex: http://junk/is/here?params
	my $url = $worker->URL().'?'.$params;

	# This function is the source of 'use of uninitialized value in sprintf' errors
	# one of the weird character in the url interfer with Log::Agent
	logdbg "debug", "pressWorker: Calling '".$url."'";
	my $response = $self->{UA}->GET($url);

	return 1 if $self->{UA}->status() == 200;
	logerr "pressWorker: Error pressing worker: ".$response;
	# Update last_used if the responce was an error
	# Maybe it will fix itself?
	# This is mostly used to retry 503 - SERVER_BUSY responces at a later time.
	$worker->last_used ('now()');
	$worker->storeObject();
	OME::Session->instance()->commitTransaction();
	
	return undef;
	
}


#
# This method attempts to keep shifting items off the queue
# by pressing workers until the queue is empty or until
# no more workers can be pressed.
# This method will return undef if no items were shifted.
sub shiftQueue {
	my ($self) = @_;
	my $queue = $self->{queue};

	my ($worker,$shifted);
	while (scalar @$queue) {
		logdbg "debug", "SimpleWorkerExecutor->shiftQueue: Getting an idle worker for MEX=".$queue->[0]->{MEX};
		# Get an idle worker
		$worker = $self->getWorker();
		# Give up if there is not an idle worker.
		last unless $worker;

		# Try to press him
		if ($self->pressWorker($worker,$queue->[0]) ) {
			logdbg "debug", "shiftQueue: shifted job for MEX=".$queue->[0]->{MEX};
			$shifted = shift @$queue;
		} else {
		# Give up if we were rebuffed
			last;
		}

		# Break if we're done
		last unless scalar @$queue;
	}
	$self->inspectWorkers();
	return $shifted ? 1 : undef;
}

sub executeModule {
	my ($self,$mex,$dependence,$target) = @_;
	logdbg "debug", "SimpleWorkerExecutor->executeModule: Executing module";

	# we assume that modules executed by a MATLAB Handler are computationally
	# bound (i.e. should be distributed if in DAE configuration) and other modules
	# are database IO bound (e.g. ROI or Typecaster modules) and so should be
	# executed sequentially on the master node
	if ($mex->module->module_type() ne "OME::Analysis::Handlers::MatlabHandler") {
		my $unthreaded_executor = $self->{unthreaded_executor};
		logdbg ("debug", "     [Unthreaded]");
		$unthreaded_executor->executeModule($mex,$dependence,$target);
	} else {		
		# Add it to the queue
		my $queue = $self->{queue};
		my $job = {
			MEX          => $mex->id(),
			Dependence   => $dependence,
			Target       => $target ? $target->id() : undef,
			DataSource   => $self->{DataSource},
			DBUser       => $self->{DBUser},
			DBPassword   => $self->{DBPassword},
		};
		push (@$queue,$job);
	}
	
	# Shift the queue
	$self->shiftQueue();
}

sub modulesExecuting {
	my ($self) = @_;
	return scalar (@{$self->{queue}}) + $self->countBusyWorkers();
}

sub waitForAnyModulesToFinish {
	my ($self) = @_;
	
	my ($events,$event,$ourEvent) =
		(undef,'',$self->{OurWorker});

	my $nWorking = $self->countBusyWorkers();

	# Return if the queue is empty and no workers are busy.
	unless( $nWorking || scalar( @{ $self->{queue} } ) ) {
		logdbg "debug", "waitForAnyModulesToFinish: No workers are busy, and no modules are waiting to execute. Returning to avoid an indefinite wait.";
		return;
	}

	# Our "event loop"$
	my $loopCount = 0;
	while ($event ne $ourEvent) {
		# Block until something happens
		# log a debug message every 100 cycles.
		logdbg "debug", "waitForAnyModulesToFinish: waiting for a worker to finish"
			if( $loopCount++ % 100 == 0 );
		$events = OME::Tasks::NotificationManager->listen (5);
		$event = '';
		if ($events) {
			# Somebody sent a message:  Either one of our workers, or an unrelated worker
			# Shift the queue if anything happened
			$self->shiftQueue();

			# Return if one of our workers finished
			foreach (@$events) {
				$event = $_ and last if $_ eq $ourEvent;
			}
		} else {
#			logdbg "debug", "waitForAnyModulesToFinish: TIMEOUT while waiting for a worker to finish";
			# we timed out waiting for a message.  Maybe we missed it.
			# If the number of busy workers now is less than before then return
			if ($self->countBusyWorkers() < $nWorking) {
				logdbg "debug", "waitForAnyModulesToFinish: Missed a worker message while waiting for a worker to finish";
				$self->shiftQueue();
				return;
			} else {
				# Apparently, we timed out without any workers finishing.
				# Shift the queue, and wait some more.
#				logdbg "debug", "waitForAnyModulesToFinish: Nobody finished";
				$self->shiftQueue();
			}
		}
	}
	logdbg "debug", "waitForAnyModulesToFinish: Received notification from finished worker";
}

sub waitForAllModulesToFinish {
	my ($self) = @_;

	while ($self->modulesExecuting()) {
		$self->waitForAnyModulesToFinish ();
		sleep(2); # a short pause allows workers started (by shiftQueue() )
				  # to set their state to busy in the DB, before we check the DB
	}
}

sub DESTROY {
	my ($self) = @_;
	OME::Tasks::NotificationManager->unregisterListener ($self->{OurWorker});
	OME::Tasks::NotificationManager->unregisterListener ($self->{AnyWorker});
}


# Shamelessly stolen from Math::BaseCalc by Ken Williams, ken@forum.swarthmore.edu
sub to_base {
	my ($digits,$num) = @_;
	return '-'.to_base(-1*$num) if $num<0; # Handle negative numbers
	
	my $dignum = @{$digits};
	
	my $result = '';
	while ($num>0) {
		substr($result,0,0) = $digits->[ $num % $dignum ];
		$num = int ($num/$dignum);
		#$num = (($num - ($num % $dignum))/$dignum);  # An alternative to the above
	}
	return length $result ? $result : $digits->[0];
}


1;

__END__

=head1 AUTHOR

Ilya Goldberg <igg@nih.gov>

=cut
