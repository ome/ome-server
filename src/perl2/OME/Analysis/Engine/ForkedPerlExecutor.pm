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

# $pid_executors{$pid} = $executor -- The ForkedPerlExecutor which
# created the given child process.
my %pid_executors;

# $executor_processes_out{$executor} = $count -- The number of
# outstanding child processes for each ForkedPerlExecutor.
my %executor_processes_out;

# $executor_processes{$executor}->{$pid} = 1 -- A list of outstanding
# child processes per ForkedPerlExecutor.
my %executor_processes;

use POSIX ":sys_wait_h";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Nothing snazzy here.

    my $self = {};
    bless $self, $class;

    return $self;
}

sub executeModule {
    my ($self,$mex,$dependence,$target) = @_;
    my $session = OME::Session->instance();
    my $module = $mex->module();

    # Fork off the child process

    my $parent_pid = $$;
    my $pid = fork;

    if (!defined $pid) {
        # Fork failed, record as such in the ModuleExecution and return
        $mex->status('ERROR');
        $mex->error_message('Could not fork a new process');
        return;
    } elsif ($pid) {
        # Parent process

        OME::Session->forgetInstance();

        # We need to add a dummy handler for the SIG_CHLD signal.  On
        # Linux, the pause function (which we use below) only returns
        # in response to a signal that "either terminates [the
        # process] or causes it to call a signal-catching function".
        # On Mac (and I assume, other BSD's), it returns in response
        # to any signal.  To make it work on both platforms, we
        # install a SIG_CHLD handler which does nothing.

        # On second glance, we only need this handler in the parent
        # process.  If we declare it in the child process, too, then
        # some system calls could possibly fail in the child process
        # under Perl 5.8.0, since it does not trap EINTR responses as
        # previous versions of Perl did.  Since we can assume that all
        # of the affected system calls will only happen in the child
        # process, we should be able to safely set the CHLD handler in
        # the parent process.

        $SIG{CHLD} = sub { return; };

        # Record some information about the child process for the
        # wait* methods below
        $pid_executors{$pid} = $self;
        $executor_processes_out{$self}++;
        $executor_processes{$self}->{$pid} = 1;
        print STDERR "    **** Forked child $pid\n";
        return;
    } else {
        # Child process

        $SIG{CHLD} = '';

        # Since we create a new Session and Factory in the
        # childProcess method, we need to pass in the parameters as
        # ID's, not objects.

        # If $target isn't an object, don't bother trying to change it.
        my $target_id =
          UNIVERSAL::isa($target,"OME::DBObject")?
              $target->id():
              $target;

        # Execute the module in this child process
        $self->childProcess($$,
                            $session->SessionKey(),
                            $mex->id(),
                            $dependence,
                            $target_id);

        #kill 'USR1', $parent_pid;

        # Once it's done executing, terminate the child process
        CORE::exit(0);
    }
}

# This method is called from the child process to actually execute a
# module.  We go ahead and create a new session object, so that we're
# not clobbering the parent process's Factory and DB handles.  (That
# means we take in all of the inputs to executeModule as ID's, so that
# we can load fresh copies from the database with our new Factory.)

sub childProcess {
    my ($self,$pid,
        $session_key,$mex_id,
        $dependence,$target_id) = @_;

    # Create a new session
    my $manager = OME::SessionManager->new();
    my $session = $manager->createSession($session_key);
    my $factory = $session->Factory();

    # Load in all of the parameters to executeModule
    my $mex = $factory->loadObject("OME::ModuleExecution",$mex_id);
    my $module = $mex->module();

    # This will only need to be loaded if the module is not globally
    # dependent.
    my $target;
    if ($dependence eq 'I') {
        $target = $factory->loadObject("OME::Image",$target_id);
    } elsif ($dependence eq 'D') {
        $target = $factory->loadObject("OME::Dataset",$target_id);
    } else {
        $target = $target_id;
    }


    # Create an instance of the module's Handler.

    my $handler_class = $module->module_type();
    my $location = $module->location();

    croak "Malformed class name $handler_class"
      unless $handler_class =~ /^\w+(\:\:\w+)*$/;
    $handler_class->require();
    print STDERR "    **** $pid - new handler $handler_class\n";
    my $handler = $handler_class->new($mex);

    # And try to execute it.

    eval {
        print STDERR "    **** $pid - startAnalysis\n";
        $handler->startAnalysis();
        print STDERR "    **** $pid - execute\n";
        $handler->execute($dependence,$target);
        print STDERR "    **** $pid - finishAnalysis\n";
        $handler->finishAnalysis();
    };

    # Mark the status of the module -- whether it finished
    # succesfully, or barfed with in error.

    if ($@) {
        print STDERR "    **** $pid - Error - $@\n";
        $mex->status('ERROR');
        $mex->error_message($@);
        print STDERR "      Error during execution: $@\n";
    } else {
        print STDERR "    **** $pid - Success\n";
        $mex->status('FINISHED');
    }

    # Store the new module execution and commit the changes.
    $mex->storeObject();
    $session->commitTransaction();
}

sub modulesExecuting {
    my ($self) = @_;
    # It's a good thing we keep track of this
    return $executor_processes_out{$self};
}

sub reapProcesses {
    my ($self) = @_;

    # Get the list of child processes which are still out.
    my $process_list = $executor_processes{$self};
    my @processes_reaped;

    foreach my $pid (keys %$process_list) {
        # Check if this child process has finished.
        my $result_pid = waitpid($pid,WNOHANG);

        # If so,
        if ($result_pid > 0) {
            # mark that its done
            delete $process_list->{$pid};
            # and that there is one fewer child process out there.
            $executor_processes_out{$self}--;
            # and keep track of which ones finished during this method
            # call.
            push @processes_reaped, $pid;
            print STDERR "    **** Reaped $pid\n";
        }
    }

    return \@processes_reaped;
}

sub waitForAnyModules {
    my ($self) = @_;

    # Determine how many child processes are currently out there.
    my $original = $executor_processes_out{$self};

    # If there aren't any, go ahead and return immediately, since
    # there's nothing to wait for.
    return if $original == 0;

    my $next;

    do {
        # Check if any child processes have finished.
        $self->reapProcesses();

        # Count how many processes are out there.
        $next = $executor_processes_out{$self};

        # If any new processes have been started, then we have to take
        # that into account.  (I.e., without this line, we'd wait for
        # all of the new processes, plus one more, to quit, as opposed
        # to waiting for any one of them to quit.)
        $original = $next if $next > $original;

        # This waits for a signal.  This allows the engine to process
        # OS events properly while modules are executing.  When a child
        # process finishes, we'll receive a CHLD signal, which will
        # cause the pause() routine to return.
        POSIX::pause() if $next >= $original;

        # Wait until there's at least one fewer process running now
        # than before.
    } until $next < $original;
}

sub waitForAllModules {
    my ($self) = @_;

    # As long as there are outstanding processes,
    while ($executor_processes_out{$self} > 0) {
        # clean up after any that might have just finished,
        $self->reapProcesses();
        # and wait for some more to finish.
        POSIX::pause();
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
