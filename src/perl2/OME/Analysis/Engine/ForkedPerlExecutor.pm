# OME/Tasks/Analysis/Engine/ForkedPerlExecutor.pm

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

package OME::Analysis::Engine::ForkedPerlExecutor;

=head1 NAME

OME::Analysis::Engine::ForkedPerlExecutor - an implementation of the
Executor interface which executes modules by forking the current Perl
interpreter

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use UNIVERSAL::require;

use OME::SessionManager;
use OME::Session;
use OME::Factory;

my $waitedpid;
my %pid_executors;
my %executor_processes_out;
my %executor_processes;

use POSIX ":sys_wait_h";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub executeModule {
    my ($self,$session,$chain_execution,$module,$node,
        $dependence,$target,$inputs) = @_;

    my $module_execution = $session->Factory()->
      newObject("OME::ModuleExecution",
                {
                 module    => $module,
                 dependence => $dependence,
                 dataset    => $chain_execution->dataset(),
                 timestamp  => 'now',
                 status     => 'RUNNING'
                });

    die "Could not create module execution"
      unless defined $module_execution;

    my $pid = fork;

    if (!defined $pid) {
        # Fork failed
        $module_execution->status('ERROR');
        $module_execution->error_message('Could not fork a new process');
        return $module_execution;
    } elsif ($pid) {
        # Parent process
        $pid_executors{$pid} = $self;
        $executor_processes_out{$self}++;
        $executor_processes{$self}->{$pid} = 1;
        print STDERR "    **** Forked child $pid\n";
        return $module_execution;
    } else {
        # Child process

        my $target_id =
          UNIVERSAL::isa($target,"OME::DBObject")?
              $target->id():
              $target;

        $inputs->{$_} = $inputs->{$_}->id() foreach keys %$inputs;

        # Execute the module in the child process
        $self->childProcess($$,
                            $session->SessionKey(),
                            $module_execution->id(),
                            $chain_execution->id(),
                            $module->id(),
                            $node->id(),
                            $dependence,
                            $target_id,
                            $inputs);

        # Once it's done executing, terminate the child process
        exit;
    }
}

sub childProcess {
    my ($self,$pid,
        $session_key,$module_execution_id,$chain_execution_id,
        $module_id,$node_id,
        $dependence,$target_id,$inputs) = @_;

    my $manager = OME::SessionManager->new();
    my $session = $manager->createSession($session_key);
    my $factory = $session->Factory();
    my $module_execution = $factory->
      loadObject("OME::ModuleExecution",$module_execution_id);
    my $chain_execution = $factory->
      loadObject("OME::AnalysisChainExecution",$chain_execution_id);
    my $module = $factory->
      loadObject("OME::Module",$module_id);
    my $node = $factory->
      loadObject("OME::AnalysisChain::Node",$node_id);

    my $target;
    if ($dependence eq 'D') {
        $target = $factory->loadObject("OME::Dataset",$target_id);
    } else {
        $target = $target_id;
    }

    $inputs->{$_} = $factory->
      loadObject("OME::ModuleExecution",$inputs->{$_})
      foreach keys %$inputs;

    my $handler_class = $module->module_type();
    my $location = $module->location();

    croak "Malformed class name $handler_class"
      unless $handler_class =~ /^\w+(\:\:\w+)*$/;
    $handler_class->require();
    print STDERR "    **** $pid - new handler $handler_class\n";
    my $handler = $handler_class->new($location,$session,
                                      $chain_execution,$module,$node);

    eval {
        print STDERR "    **** $pid - startAnalysis\n";
        $handler->startAnalysis($module_execution);
        print STDERR "    **** $pid - execute\n";
        $handler->execute($dependence,$target,$inputs);
        print STDERR "    **** $pid - finishAnalysis\n";
        $handler->finishAnalysis();
    };

    if ($@) {
        print STDERR "    **** $pid - Error - $@\n";
        $module_execution->status('ERROR');
        $module_execution->error_message($@);
    } else {
        print STDERR "    **** $pid - Success\n";
        $module_execution->status('FINISHED');
    }

    $module_execution->storeObject();

    $session->commitTransaction();
}

sub modulesExecuting {
    my ($self) = @_;
    return $executor_processes_out{$self};
}

sub reapProcesses {
    my ($self) = @_;
    my $process_list = $executor_processes{$self};
    my @processes_reaped;

    foreach my $pid (keys %$process_list) {
        my $pid = waitpid($pid,WNOHANG);
        if ($pid > 0) {
            delete $process_list->{$pid};
            $executor_processes_out{$self}--;
            push @processes_reaped, $pid;
            print STDERR "    **** Reaped $pid\n";
        }
    }

    return \@processes_reaped;
}

sub waitForAnyModules {
    my ($self) = @_;
    my $original = $executor_processes_out{$self};
    return if $original == 0;
    my $next;
    do {
        $self->reapProcesses();
        $next = $executor_processes_out{$self};

        $original = $next if $next > $original;

        # This waits for a signal.  This allows the engine to process
        # OS events properly while modules are executing.  When a child
        # process finishes, we'll receive a CHLD signal, which will
        # cause the pause() routine to return.
        POSIX::pause() if $next >= $original;
    } until $next < $original;
}

sub waitForAllModules {
    my ($self) = @_;

    while ($executor_processes_out{$self} > 0) {
        $self->reapProcesses();
        POSIX::pause();
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
