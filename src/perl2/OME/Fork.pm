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

OME::Fork - centralized handling for OME process forking

=head1 SYNOPSIS

	use OME::Fork;

	sub callback {
	    my ($child_pid) = @_;
	    # do something once the child finishes
	}
	my $pid = OME::Fork->fork(\&callback);
	# $pid determines parent/child exactly like CORE::fork

=head1 DESCRIPTION

There are several parts of the OME Perl API which need a separate
process in order to work correctly.  For instance, the Web UI and
Remote Framework both run image imports in a separate process, so as
not to block the main mechanisms of the transport layer.

In practice, there are two main problems with code which uses the fork
call:

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
when its children exit.

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

