# OME/Util/Dev/FinishExecute.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2007 Open Microscopy Environment
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
# Written by:    Tom Macura <tmacura>@nih.gov
#-------------------------------------------------------------------------------

package OME::Util::Dev::FinishExecute;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use OME::Session;
use OME::AnalysisChainExecution;
use OME::Analysis::Engine;
use Term::ReadKey;

use Getopt::Long;
Getopt::Long::Configure("bundling");

sub getCommands {
    return
      {
       'finish_execute'     => 'finish_execute',
      };
}

sub finish_execute_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:  
    $script $command_name [<options>] [<flags>]

This command attempts to finish an analysis chain execution that was initiated
before, continued till completetion, but left some MEX's with ERROR or UNREADY
status. This commend re-executes these MEXs.

Options:
  -x, --chex (<id>)
     Analysis Chain Execution ID

USAGE
}

sub finish_execute {
	my $self = shift;
	
	my $chex_id;
	GetOptions ('x|chex=i' => \$chex_id);
	
	my $session = $self->getSession();	
	my $factory = $session->Factory();
	
	# idiot traps
	die "Chain Execution ID (CHEX) must be specified, use the -x flag.\n"
		unless defined $chex_id;
		
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chex_id )
		or die "Couldn't load chex $chex_id";
	
	if (not defined $chex->status () eq 'UNFINISHED') {
		die "Chain Execution is in progress, cannot run FinishExecute on that CHEX!\n";
	} elsif ($chex->status() eq 'FINISHED') {
		print "Chain Execution has status 'FINISHED' so FinishExecute ".
			"probably will do nothing for you. Trying anyway...\n";
	} elsif ($chex->status() eq 'INTERRUPTED') {
		print "Chain Execution has status 'INTERRUPTED' so FinishExecute ".
			"probably will do nothing for you. You probably want to re-execute ".
			"the chain with results-reuse enabled. Trying anyway...\n";
	}
	print "Finishing Chain Execution of Analysis Chain `".$chex->analysis_chain->name()."`\n";
	
	my $task = OME::Tasks::NotificationManager->
		new("Executing (FinishExecute)`".$chex->analysis_chain->name()."`", -1);
	$task->setMessage('Continuing Execution of Analysis Chain');
	
	my $pid = OME::Fork->fork();
	
	if (!defined $pid) {
		die "Could not fork off process to perform the analysis chain execution (FinishExecute)";
	} elsif ($pid) {
		# Execute the chain
		OME::Analysis::Engine->
			finishChainExecution($chex,$task);
	} else {
	
		# Child process prints the task status
		my $lastStep = -1;
		my $status = $task->state();
		my $mem_usage = 0;
		my $mem_usage_steps = 0; # how many steps (each 2 sec) do we average memory over
		while ($status eq 'IN PROGRESS') {
			$task->refresh();
			next if $task->n_steps == -1;
			
			my $step = $task->last_step();
			my $message = $task->message();
			defined $message or $message = "";
			
			if ($step != $lastStep ) {
				print "	 $step/",$task->n_steps(),": [",
				  $task->state(),"] Currently ",
				  $message;
				$lastStep = $step;
				if ($mem_usage > 0) {
					printf(" (Past Usage: %.2dmb)",$mem_usage/1024/$mem_usage_steps);
				}
				print "\n";
				$mem_usage = 0;
				$mem_usage_steps = 0;
			}
		
			$status = $task->state();
		
			sleep 2;
			# if you want to use the lines below, remove the line above (sleep 2)
			#my @output = `sar -r 5`; # inherently results in 2 second wait
			#if($output[-1] =~ m/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/)
			#{
        		#	$mem_usage += $3;
			#	$mem_usage_steps++;
			#}

		}
		
		# print the final task Info
		$task->refresh();
		my $step = $task->last_step();
		print "	 $step/",$task->n_steps(),": [",
		  $task->state(),"] Currently",
		  $task->message();
		if ($mem_usage > 0) {
			printf(" (Past Usage: %.2dmb)",$mem_usage/1024/$mem_usage_steps);
		}
		print "\n";	
	}
}

sub END {
	print "Exiting...\n";
}

1;
