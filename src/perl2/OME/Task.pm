# OME/Task.pm

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


package OME::Task;

=head1 NAME

OME::Task - OME Tasks are used to keep track of long-running processes.

=head1 DESCRIPTION

The C<Task> class is used to keep track of long-running tasks.  This DBObject
allows updating task information independently of any other transactions
that may be running.

This class is meant to be created, recalled and deleted through the
L<OME::Tasks::NotificationManager|OME::Tasks::NotificationManager> class.
	my $task = new OME::Tasks::NotificationManager ($name, $nSteps);

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;

use OME::DBObject;
use base qw(OME::DBObject);

=head1 FIELDS

Note that using these fields as mutators will not make the values available to other
processes until storeObject() is called.  Use the provided methods to do immediate
updates.

=head2 name ()

Acessor/mutator for getting/setting the task's name.  It is bad practice to
re-set the tasks name after its been created.  Use C<message()> to send messages.

=head2 session_id ()

Acessor for getting the task's associated session ID.

=head2 session ()

Acessor for getting the task's associated L<OME::UserState|OME::UserState> object.

=head2 process_id ()

Acessor for getting the task's process ID (i.e., the operating system's PID).

=head2 state ()

Acessor for getting the task's state.  This is a controlled
vocabulary, so state is supposed to be 'IN PROGRESS', 'FINISHED', and 'ABORTED'.
Do not modify the state directly.

=head2 message ()

Acessor/mutator for getting/setting a message for the task.  The messages are not
cumulative.  Each call replaces the message in the task.

=head2 error ()

Acessor/mutator for getting/setting a error message for the task.
The error messages are not cumulative.  Each call replaces the error message in the task.

=head2 n_steps ()

Acessor for getting the number of steps in the task.

=head2 last_step ()

Acessor for getting the last completed step in the task.

=head2 t_start ()

Acessor for getting the timestamp when the task started.

=head2 t_stop ()

Acessor for getting the timestamp when the task finished.

=head2 t_last ()

Acessor for getting the timestamp when the previous step in the task finished.

=cut


__PACKAGE__->newClass();
__PACKAGE__->setSequence('task_seq');
__PACKAGE__->setDefaultTable('tasks');
__PACKAGE__->addPrimaryKey('task_id');
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(process_id => 'process_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(session_id => 'session_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'ome_sessions',
                       });
__PACKAGE__->addColumn(session => 'session_id','OME::UserState');
__PACKAGE__->addColumn(state => 'state',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(message => 'message',
                       {
                        SQLType => 'text',
                       });
__PACKAGE__->addColumn(error => 'error',
                       {
                        SQLType => 'text',
                       });
__PACKAGE__->addColumn(n_steps => 'n_steps',
                       {
                        SQLType => 'integer',
                       });
__PACKAGE__->addColumn(last_step => 'last_step',
                       {
                        SQLType => 'integer',
                       });
__PACKAGE__->addColumn(t_start => 't_start',
                       {
                        SQLType => 'timestamp',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(t_stop => 't_stop',
                       {
                        SQLType => 'timestamp',
                       });
__PACKAGE__->addColumn(t_last => 't_last',
                       {
                        SQLType => 'timestamp',
                       });

use OME::Tasks::NotificationManager;


# Over-ride the DBObject->getFactory() method.
# We return a special factory here - one that is not tied
# to a session, and who's DB handle is totally independent
# of the Session's Factory's DB handle.
# This is all so that this object can be updated to the DB
# asynchronously and independently of any transactions that
# may be going on.
# This special factory is managed by OME::Tasks::NotificationManager
# Since this handle is auto-commit, we only need one.
# Hence the class (not instance) variable to hold the factory.
sub getFactory {
	return OME::Tasks::NotificationManager->taskFactory();
}

=head1 METHODS

=head2 step($stepNum)

Update the step we're on in the task.  If C<$stepNum> is specified, the
tasks's last_step is set to the specified $stepNum.  Otherwise, the
last_step is incremented.  The current timestamp is also set for t_last.
Returns the last completed step ($stepNum).

=cut

sub step {
	my $self = shift;
	my $nSteps = shift;
	$nSteps = $self->last_step()+1 unless $nSteps;
	$self->last_step($nSteps);
	$self->t_last('now');
	$self->storeObject();
	return $nSteps;
}


=head2 finish()

Signal that the task is finished.  The state is set to 'FINISHED', and the t_stop
timestamp is set to the current time.  Nothing is done with last_step or t_last.

=cut

sub finish {
	my $self = shift;
	$self->t_stop('now');
	$self->state ('FINISHED');
	$self->storeObject();
}

=head2 setMessage()

Set the message for the task.  Unlike the C<message()> field, this will immediately
write the object to the DB, making the message available to other processes.

=cut

sub setMessage {
	my $self = shift;
	my $message;
	
	if (@_) {
		$message = shift;
		$self->message($message);
		$self->storeObject();
	}
	return $message;
}


=head2 setError()

Set the error message for the task.  Unlike the C<error()> field, this will immediately
write the object to the DB, making the error message available to other processes.

=cut

sub setError {
	my $self = shift;
	my $error;
	
	if (@_) {
		$error = shift;
		$self->error($error);
		$self->storeObject();
	}
	return $error;
}

=head2 died()

Specify that the task has died.  The optional parameter is stored in the error message.

=cut

sub died {
	my $self = shift;
	my $error;
	
	$self->t_stop('now');
	$self->state ('DIED');

	if (@_) {
		$error = shift;
		$self->error($error);
	}
	$self->storeObject();
}



=head2 setnSteps()

Set (or re-set) the number of steps in the task.

=cut

sub setnSteps {
	my $self = shift;
	my $nSteps;
	
	if (@_) {
		$nSteps = shift;
		$self->n_steps($nSteps);
		$self->storeObject();
	}
	return $nSteps;
}



=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=head1 SEE ALSO

L<OME::Tasks::NotificationManager|OME::Tasks::NotificationManager>

=cut


1;

