# OME/Fork.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:  Douglas Creager <dcreager@alum.mit.edu>
#-------------------------------------------------------------------------------


package OME::Fork;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use POSIX ":sys_wait_h";

use OME::Session;
use OME::SessionManager;
use OME::Tasks::ImportManager;
use OME::Tasks::NotificationManager;

=head1 NAME

OME::Fork - centralized handling for OME process forking and task deferal

=head1 SYNOPSIS

	use OME::Fork;

	# Execute task() later
	sub task {
		my $stuff = shift;
		# do something later with $stuff
	}
	
	OME::Fork->doLater ( sub { task ($params) } );
	# N.B.: will execute even if you call die();

	# Fork a process right away
	sub callback {
	    my ($child_pid) = @_;
	    # do something once the child finishes
	}
	my $pid = OME::Fork->fork(\&callback);
	# $pid determines parent/child exactly like CORE::fork

=head1 DESCRIPTION

There are several parts of the OME Perl API which need a separate
or non-blocking process in order to work correctly.  For instance,
the Web UI and Remote Framework both run image imports in a deferred
non-blocking process, so as not to block the main mechanisms of the
transport layer.

In practice, there are two main problems with code which uses the fork
call, which is why it is better to simply defer the task when possible:

=over

=item Forking

=over

=item *

There are certain modules in OME, such as the ImportManager, which
maintain global state.  In almost all cases, this global state is only
valid in one of the two processes created by the fork call.  This
requires the global state to be "cancelled" in one of the processes,
without comitting any changes to the database.

It's fairly straightforward to require any module with global state to
provide a method to perform this cancellation.  (The current
convention is to use the word "forget" in the name of the method.)
However, it also necessary to centrally keep track of all of the
modules which need to be forgotten upon a fork call.  This allows us
to maintain this information in one place, rather than requiring each
method which calls fork to remember this separately.

=item *

It is necessary to reap the child processes which are created, so that
the process table does not get filled with a bunch of zombies.  This
can usually be accomplished by having Perl ignore the CHLD signal, but
this prevents forking code from using its own reaping logic to track
when its children exit.  This is further complicated in Apache 2 which
uses threads as well as processes.

=back

The OME::Fork package aims to solve these two problems.  First, the
package installs a SIGCHLD handler upon being loaded for the first
time.  The handler automatically reaps any processes as they die.

Second, it provides a replacement fork method which automatically
performs any forget operations which are necessary.  (Currently, this
works by calling the appropriate "forget" methods for any module in
OME which maintains global state.  This is obviously not the ideal
solution from the standpoint of writing new modules, since it forces
new module writers to modify this package as well.)  Additionally,
this method takes in a parameter -- a reference to a subroutine.  This
provides a callback mechanism which allows forking code to know when a
child process has finished and been reaped, without having to install
a separate SIGCHLD handler.

Note that this callback function is called from within the SIGCHLD
handler.  This means that it should follow the same guidelines as
those outlines for signal handlers in the perlipc manpage.

=item Deferal

Defering a task is often the desired behavior and it is much more
straigh-forward than forking.  A fork call done inside an Apache
process will fork the entire process, including the mod_perl interpreter
any modules loaded into Apache, etc.  Its a biggie.

Deferal simply schedules a task to execute in the same process once
the main flow of the program is complete.  This is done in two different
ways depending on wether the main program is executing in Apache/mod_perl
or not.  If its in mod_perl, the Apache PerlCleanupHandler is used to
schedule the task after the responce is sent, but before the responce handler
exits completely.  When not in mod_perl, the task is executed in an END block.

Several tasks can be defered for later execution, though the order of execution
is not guaranteed.  Specifically in Apache 1/mod_perl and without mod_perl,
the last task will be executed first.  In Apache 2/mod_perl, the first task
will be executed first.

N.B.:  There is currently no way to un-register deferred tasks.
They will execute even if you call die().

=back

=cut

# This hash is keyed by child process ID, and contains a reference to
# the callback function for the child process.  Note that this must be
# forgotten in child processes....

my %CHILD_PROCESSES;

# This hash is also keyed by child process ID, and contains the status
# codes returned by the waitpid call.  Note that an entry is created in
# this hash for a child process as soon as the fork call which creates
# it is executed.  However, the value is not a valid status code until
# after that child exits.

my %CHILD_STATUSES;

our @TASKS;        # Deferred tasks - only for END blocks
our $MPV;          # mod_perl version

# We need to figure out what mod_perl we're running if we're in
# Apache before we do anything else.
sub BEGIN {
	if ( UNIVERSAL::can ('Apache','request') ) {
		eval { mod_perl->require(); };
		unless ($@) {
			$MPV = 2 if $mod_perl::VERSION >= 1.99;
			$MPV = 1 if $mod_perl::VERSION < 1.99;
		}
	} else {
		$MPV = 0;
	}
}

# This will call the tasks only if we're not in mod_perl
sub END {
	if ($MPV == 0) {&$_ foreach @TASKS;}
}


sub doLater {
my $proto = shift;
my $task = shift;

	if ($MPV == 1) {
		my $r = Apache->request();
		$r->register_cleanup( sub {&$task;return 0;} );
	} elsif ($MPV == 2) {
		APR::Pool->require();
		my $r = Apache->request();
		$r->pool->cleanup_register( sub {&$task;return 0;} );
	} elsif ($MPV == 0) {
		push (@TASKS,$task);
	}
}



# This is taken straight from the perlipc manpage.

sub __reaper {
    my $child;
    my $callback;

    # If a second child dies while in the signal handler caused by the
    # first death, we won't get another signal. So must loop here else
    # we will leave the unreaped child as a zombie. And the next time
    # two children die we get another zombie. And so on.
    while (($child = waitpid(-1,WNOHANG)) > 0) {
        $CHILD_STATUSES{$child} = $?;
        $callback = $CHILD_PROCESSES{$child};
        $callback->($child) if defined $callback;
    }

    $SIG{CHLD} = \&__reaper;  # still loathe sysV
}

sub forget {
    my ($proto) = @_;
    %CHILD_PROCESSES = ();
    %CHILD_STATUSES = ();
}

sub fork {
    my ($proto,$callback) = @_;

    # Make sure that our signal handler is installed
    $SIG{CHLD} = \&__reaper;

    # Grab the current session key so that we can log back in after the
    # fork.
    my $key = OME::Session->instance()->SessionKey();

    # Execute the fork.
    my $pid = CORE::fork();

    # If there was an erroring forking, we should just return.
    return undef unless defined $pid;

    if ($pid) {
        # This is the parent process

        # Set up our callback state

        $CHILD_PROCESSES{$pid} = $callback;
        $CHILD_STATUSES{$pid} = 0;

        # Assume that any active imports will be handled in the child
        # process.

        OME::Tasks::ImportManager->forgetImport();

    } else {
        # This is the child process

        # Clear out the reaper hashes, since they are only valid for
        # the parent process.

        OME::Fork->forget();

        # Log back into OME.  This creates new database handles for
        # the session factory, and the task notification manager.

        OME::Session->forgetInstance();
        OME::Tasks::NotificationManager->forget();
        my $session = OME::SessionManager->createSession($key);

    }

    return $pid;
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

