# OME/Analysis/Engine/Worker.pm

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


package OME::Analysis::Engine::Worker;

=head1 NAME

OME::Analysis::Engine::Worker - A class to keep track of Analysis Workers available to the Analysis Engine.

=head1 DESCRIPTION

The C<Analysis::Engine::Worker> class is used to keep track of workers available to the Analysis Engine.
This DBObject keeps track of the status of local and remote workers.

Objects of this class are created by an installation/configuration program.  Once created in the DB,
the analysis engine gathers available workers and directs them to execute its analysis tasks (modules).
In the current implementation, this class is used by
L<OME::Analysis::Engine::SimpleWorkerExecutor|OME::Analysis::Engine::SimpleWorkerExecutor>, but any Worker
Executor (scheduler) can use the same pool of workers.

Note that several workers may have a common URL - for example in SMP or other multi-CPU architectures.
Workers may also be local to the back-end (with a localhost URL).

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

=head2 URL ()

The Worker's URL - fully qualified.  This is what will be called to get the worker to execute a module.

=head2 status ()

The Worker's status.  Can be 'IDLE', 'BUSY', 'OFF-LINE'.  Note that workers that are off-line
cannot be placed on-line directly by a remote host.  These workers are ignored for executing
tasks until something external places them back on-line.

=head2 process_id ()

When a worker's status is 'BUSY', this is the worker's process ID on the host that its running on.

=cut


__PACKAGE__->newClass();
__PACKAGE__->setSequence('analysis_worker_seq');
__PACKAGE__->setDefaultTable('analysis_workers');
__PACKAGE__->addPrimaryKey('worker_id');
__PACKAGE__->addColumn(URL => 'url',
                       {
                        SQLType => 'varchar(255)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(status => 'status',
                       {
                        SQLType => 'varchar(16)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(last_used => 'last_used',
                       {
                        SQLType => 'timestamp',
                        NotNull => 1,
                        Indexed => 1,
                        Default => 'now()',
                       });
__PACKAGE__->addColumn(PID => 'pid',
                       {
                        SQLType => 'integer',
                       });

# These objects should never be cached to make sure that their status is always current.
__PACKAGE__->Caching(0);

=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=head1 SEE ALSO

L<OME::Tasks::NotificationManager|OME::Tasks::NotificationManager>

=cut


1;

