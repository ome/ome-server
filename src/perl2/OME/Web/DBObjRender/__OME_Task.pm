# OME/Web/DBObjRender/__OME_ModuleExecution.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:  
#	Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_Task;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_ModuleExecution - Specialized rendering for OME::ModuleExecution

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::ModuleExecution

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use base qw(OME::Web::DBObjRender);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _summaryFields } = [
		'name',
		'state',
		'message',
		'error',
		'last_step',
		'n_steps',
		'process_id',
	];
	$self->{ _allFields } = [
		@{ $self->{ _summaryFields } },
		't_start',
		't_stop',
		't_last'
	];

	$self->{ _fieldTitles } = {
		name              => "Task",
		process_id        => "PID",
		state             => "Status",
	};

	
	return $self;
}


=head1 Author

Ilya Goldberg <igg@nih.gov>

=cut

1;
