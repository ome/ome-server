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

use OME::Fork;

# $pid_executors{$pid} = $executor -- The ForkedPerlExecutor which
# created the given child process.
my %pid_executors;

# $executor_processes_out{$executor_pid} = $count -- The number of
# outstanding child processes for each ForkedPerlExecutor.
my %executor_processes_out;

# $executor_processes{$executor_pid}->{$child_pid} = 1 -- A list of
# outstanding child processes per ForkedPerlExecutor.
my %executor_processes;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Nothing snazzy here.

    my $self = {};
    bless $self, $class;

    return $self;
}

sub childCallback {
    my ($child_pid) = @_;

    # mark that its done
    $executor_processes{$$}->{$child_pid} = 0;
    # and that there is one fewer child process out there.
    $executor_processes_out{$$}--;
    print STDERR "    **** Reaped $child_pid\n";
}

sub executeModule {
    my ($self,$mex,$dependence,$target) = @_;
    my $session = OME::Session->instance();
    my $module = $mex->module();

    # Fork off the child process

    my $parent_pid = $$;
    my $pid = OME::Fork->fork(\&childCallback);

    if (!defined $pid) {
        # Fork failed, record as such in the ModuleExecution and return
        $mex->status('ERROR');
        $mex->error_message('Could not fork a new process');
        return;
    } elsif ($pid) {
        # Parent process

        # Record some information about the child process for the
        # wait* methods below
        $pid_executors{$pid} = $self;
        $executor_processes_out{$$}++;
        $executor_processes{$$}->{$pid} = 1;
        print STDERR "    **** Forked child $pid\n";
        return;
    } else {
        # Child process

        #$SIG{CHLD} = '';

        # Execute the module in this child process
        $self->childProcess($$,
                            $mex,
                            $dependence,
                            $target);

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
        $mex,
        $dependence,$target) = @_;

    my $session = OME::Session->instance();

    my $module = $mex->module();

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

    CORE::exit(0);
}

sub modulesExecuting {
    my ($self) = @_;
    # It's a good thing we keep track of this
    return $executor_processes_out{$self};
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
        # The childCallback function will get called automatically when
        # each child process exits.  This function modifies the state
        # that we're about to check.

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
        # cause the pause() routine to return.  This signal will cause
        # the childCallback function to be executed.  If the signal
        # which causes pause to return is not SIGCHLD, then none of our
        # state variables will have changed, and we'll quickly fall
        # back to this line.
        POSIX::pause() if $next >= $original;

        # Wait until there's at least one fewer process running now
        # than before.
    } until $next < $original;
}

sub waitForAllModules {
    my ($self) = @_;

    # As long as there are outstanding processes,
    while ($executor_processes_out{$self} > 0) {
        # and wait for some more to finish.
        POSIX::pause();
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
