# OME/Analysis/Engine/Job.pm

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
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Engine::Job;

=head1 NAME

OME::Analysis::Engine::Job - A class to keep track of Jobs (NEXs) available for execution by the Analysis Engine's remote workers

=head1 DESCRIPTION

The C<Analysis::Engine::Job> class is used to keep track of jobs available to the Analysis Engine.
=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Date::Parse;

use OME::DBObject;
use base qw(OME::DBObject);

=head1 FIELDS


=cut

__PACKAGE__->newClass();
__PACKAGE__->setSequence('analysis_engine_jobs_seq');
__PACKAGE__->setDefaultTable('analysis_engine_jobs');
__PACKAGE__->addPrimaryKey('job_id');

# READY (i.e. ready to be assigned to a worker)
# INPROGRESS (i.e. a worker is working on it)
__PACKAGE__->addColumn(status => 'status',
                       {
                        SQLType => 'varchar(16)',
                        NotNull => 1,
                        Indexed => 1,
                       });
                      
# __PACKAGE__->addColumn(last_used => 'last_used',
#                        {
#                         SQLType => 'timestamp',
#                         NotNull => 1,
#                         Indexed => 1,
#                         Default => 'CURRENT_TIMESTAMP',
#                        });

__PACKAGE__->addColumn(NEX => 'NEX', 'OME::AnalysisChainExecution::NodeExecution',
                       {
                        SQLType => 'integer',
                       });

__PACKAGE__->addColumn(executing_worker=> 'executing_worker', 'OME::Analysis::Engine::Worker',
                       {
                        SQLType => 'integer',
                       });

# These objects should never be cached to make sure that their status is always current.
__PACKAGE__->Caching(0);

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>

=head1 SEE ALSO

L<OME::Analysis::Engine::Executor|OME::Analysis::Engine::Executor>,
L<OME::DBObject|OME::DBObject>

=cut


1;

