# OME/Tasks/NotificationManager.pm

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


package OME::Tasks::NotificationManager;

use OME;
use OME::Session;
use OME::Database::Delegate;
use Log::Agent;
our $VERSION = $OME::VERSION;

our $__soleFactory = undef;




=head1 NAME

OME::Tasks::NotificationManager - utility methods to manage OME::Tasks objects

=head1 SYNOPSIS

	# Create a new task notification object
	# $nsteps is optional, but the first parameter (name) is required.
	my $progress = new OME::Tasks::NotificationManager ("Reaaly long task", $nsteps);

	# do something
	$progress->step(); # or optionally, $progress->step ($theStepNum)
	# report an error
	$progress->setError ("Is och und vey, I'm verklempt!");
	# message - the message is replaced every time its called
	$progress->setMessage ("Zei gezunt!");
	# finish
	$progress->finish()

	#  Meanwhile, in another process:
	# optionally, supply a state or taskID filter.
	my @tasks = OME::Tasks::NotificationManager->list (ID=>$taskID);

	# Clear tasks
	# optionally, supply a state or taskID filter.
	OME::Tasks::NotificationManager->clear (state=>'FINISHED');

=head1 DESCRIPTION

OME::Tasks::NotificationManager provides utility methods to manage L<OME::Task|OME::Task> objects

=head1 METHODS

=head2 new ($name, $nsteps)

Make and return a new L<OME::Task|OME::Task> object with the specified name and
optionally, number of steps in the task.  The steps can mean anything you want.  It could be
number of images or number of bytes or whatever.  Everytime a step (or several) are completed,
call L<OME::Task|OME::Task>->step().

=cut

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
   	my ($name,$nsteps) = @_;

	$task = $class->taskFactory()->newObject("OME::Task", {
		name        => $name,
		process_id  => $$,
		session_id  => OME::Session->instance()->id(),
		state       => 'IN PROGRESS',
		message     => undef,
		error       => undef,
		n_steps     => $nsteps,
		last_step   => 0,
		t_start     => 'now',
		t_stop      => undef,
		t_last      => undef
	});
	return ($task);

}

=head2 list (ID => $taskID, state => $state, session => $session)

Return a list of L<OME::Task|OME::Task> objects with the specified optional criteria.
See the fields of the OME::Task class for a full list of useable criteria.
If C<session> is not supplied, the current user's session is used.

=cut

sub list {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my %criteria = @_;

    $criteria{session_id} = OME::Session->instance()->ID()
    	unless exists $criteria{session_id}
    	or  exists $criteria{session};

    return ($class->taskFactory()->findObjects('OME::Task',%criteria));
}

=head2 clear (ID => $taskID, state => $state, session => $session)

Clear (delete) all of the L<OME::Task|OME::Task> objects that fit the supplied criteria.
See the fields of the OME::Task class for a full list of useable criteria.
If C<session> is not supplied, the current user's session is used.

=cut

sub clear {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my %criteria = @_;

    $criteria{session_id} = OME::Session->instance()->ID()
    	unless exists $criteria{session_id}
    	or  exists $criteria{session};

    my @tasks = $class->taskFactory()->findObjects('OME::Task',%criteria);
    foreach (@tasks) {
    	$_->deleteObject();
    }
}

=head2 registerListener ('condition')

This method can be called to register a listener for a certain named condition.
Anybody connected to the DB (locally or remotely) can issue the condition by calling:

 OME::Tasks::NotificationManager->notify ('condition');

The condition string can be any "normal" kind of string.  What's a normal
kind of string, you may ask?  Well, it shouldn't have any "funny stuff" in it.

This method only registers a listener - it doesn't actually listen for any events.
To block and wait for any condition with a registered listener, call:
 OME::Tasks::NotificationManager->listen ('condition',$timeout);

=cut

sub registerListener {
	my ($proto,$condition) = @_;
    my $class = ref($proto) || $proto;

	my $dbh = $class->taskFactory()->obtainDBH();
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
	$delegate->registerListener ($dbh,$condition);

	return 1;
}

=head2 unregisterListener ('condition')

This method is  called to un-register a listener for a certain named condition.

=cut

sub unregisterListener {
	my ($proto,$condition) = @_;
    my $class = ref($proto) || $proto;

	my $dbh = $class->taskFactory()->obtainDBH();
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
	$delegate->unregisterListener ($dbh,$condition);

	return 1;
}

=head2 listen ($timeout)

This method will block until $timeout seconds (can be fractional) or forever
if $timeout is undef, listening for any conditions with registered listeners.

An array ref is returned containing a list of conditions that occured.  If the
timeout expires without any conditions occuring, returns undef.

=cut

sub listen {
	my ($proto,$timeout) = @_;
    my $class = ref($proto) || $proto;

	my $dbh = $class->taskFactory()->obtainDBH();
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
	return ($delegate->waitNotifies ($dbh,$timeout));
}

=head2 notify ('condition')

This method can be called to notify listeners of a specified condition.  Listeners can
wait for a specified condition to occur by calling:

 OME::Tasks::NotificationManager->wait ('condition',$timeout);

The same restrictions on the condition string as specified for wait() apply here.

N.B.:  Unlike the other methods in this class, this method does not use a separate handle
for the notification, which means that the notification will not be sent until the
session's transaction is comitted.

=cut

sub notify {
	my ($proto,$condition) = @_;
    my $class = ref($proto) || $proto;

	# We're just going to use the session's factory for this
	my $dbh = OME::Session->instance()->Factory()->obtainDBH();
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
	$delegate->notifyListeners ($dbh,$condition);
	return (1);
}

# This is a semi-private method.  Besides this class, it should only be used by OME::Task.
sub taskFactory {

	if ($__soleFactory) {
		return ($__soleFactory);
	} else {
		$__soleFactory = OME::Factory->new({AutoCommit => 1});
		return ($__soleFactory);
	}
}

sub forget {
    if (defined $__soleFactory) {
        $__soleFactory->forget();
        $__soleFactory = undef;
    }
}


=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=head1 SEE ALSO

L<OME::Task|OME::Task>

=cut


1;

