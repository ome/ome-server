# OME/Tasks/Analysis/Engine/SimpleWorkerExecutor.pm

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
interface which executes modules by calling
L<OME::Analysis::Engine::Worker|OME::Analysis::Engine::Worker>s

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use LWP::UserAgent;
use Log::Agent;


use OME::Session;
use OME::Analysis::Engine::Worker;
use OME::Tasks::NotificationManager;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		instance_id => undef,
	# Array of hashrefs, keyed by 'MexID','Dep','TargetID'
		queue       => [],
		UA          => undef,
		DataSource  => undef,
		SessionKey  => undef,
	# The messages the worker will send us when its done.
		OurWorker   => undef,
		AnyWorker   => undef,
	};
	bless $self, $class;
	
	# Generate a unique instace ID for ourselves
	my $codecVocab = [0..9,'a'..'z','A'..'Z'];
	$self->{instance_id} = 
		to_base ($codecVocab,$$).
		to_base ($codecVocab,time()).
		to_base ($codecVocab,int(rand(65535))); 
	
	# Get our user agent
	$self->{UA} = LWP::UserAgent->new ();

	# Get our DataSource + SessionKey
	$self->{DataSource}	  = 'dbi:Pg:dbname=ome;host=localhost';
	$self->{SessionKey}	  = OME::Session->instance()->SessionKey();

	logdbg "debug", "SimpleWorkerExecutor->new: Registering listeners";
	
	# Register our listener
	$self->{OurWorker} = 'WorkerIdle'.$self->{instance_id};
	$self->{AnyWorker} = 'WorkerIdle';
	OME::Tasks::NotificationManager->registerListener ($self->{OurWorker});
	OME::Tasks::NotificationManager->registerListener ($self->{AnyWorker});

	logdbg "debug", "SimpleWorkerExecutor->new: returning new executor";
	
	return $self;
}

#
# Get an idle worker
sub getWorker {
	my ($self) = @_;
	return (
		OME::Session->instance()->Factory()->findObject (
			'OME::Analysis::Engine::Worker',{
				status	=> 'IDLE',
				__limit => 1,
		})
	);
}

#
# Make a worker do something
# returns 1 or undef.
sub pressWorker {
	my ($self,$worker,$job) = @_;
	
	return undef unless $worker and $job and $job->{MEX};
	
	$job->{WorkerID} = $worker->id();
	my $params = join ('&', map ($_.'='.$job->{$_},keys %$job));

	# Put our notices on the parameter list
	$params .= "&Notice=".$self->{OurWorker};
	$params .= "&Notice=".$self->{AnyWorker};

	logdbg "debug", "pressWorker: Calling ".$worker->url().'?'.$params;
	my $response = $self->{UA}->get($worker->url().'?'.$params);

	return 1 if $response->is_success();
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

	return $shifted ? 1 : undef;
}

sub executeModule {
	my ($self,$mex,$dependence,$target) = @_;
	logdbg "debug", "SimpleWorkerExecutor->executeModule: Executing module";

	# Add it to the queue
	my $queue = $self->{queue};
	my $job = {
		MEX          => $mex->id(),
		Dependence   => $dependence,
		Target       => $target ? $target->id() : undef,
		DataSource   => $self->{DataSource},
		SessionKey   => $self->{SessionKey},
	};
	push (@$queue,$job);

	# Shift the queue
	$self->shiftQueue();
}

sub modulesExecuting {
	my ($self) = @_;
	return scalar (@{$self->{queue}});
}

sub waitForAnyModules {
	my ($self) = @_;
	
	my ($events,$event,$ourEvent) =
		(undef,'',$self->{OurWorker});

	# Our "event loop"
	while ($event ne $ourEvent) {
		# Block until something happens
		logdbg "debug", "waitForAnyModules: waiting for a worker to finish";
		my $events = OME::Tasks::NotificationManager->listen (30);
		
		# Shift the queue if anything happened
		$self->shiftQueue();
		
		# Return if one of one our workers finished
		foreach (@$events) {
			$event = $_;
			last if $event eq $ourEvent;
		}
	}
}

sub waitForAllModules {
	my ($self) = @_;
	my $queue = $self->{queue};

	while (scalar @$queue) {
		$self->waitForAnyModules ();
	}

}

sub DESTROY {
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
