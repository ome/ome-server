# OME/Web/DBObjDetail/__OME_Project.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjDetail::__OME_Project;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_Project - Show detailed information on an Project

=head1 DESCRIPTION

_takeAction() sets Session->project to the project displayed and
implements adding datasets to the project and
implements editing name or description and.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use CGI;
use Log::Agent;
use OME::Tasks::ProjectManager;

use base qw(OME::Web::DBObjDetail);

sub _takeAction {
	my $self = shift;
	my $object = $self->_loadObject();
	my $q = $self->CGI();

	# make this project the "most recent"
	$self->Session()->project( $object );
	$self->Session()->storeObject();
	$self->Session()->commitTransaction();

	# allow editing of project name & description
	if( $q->param( 'action' ) eq 'SaveChanges' ) {
		$object->description( $q->param( 'description' ) );
		$object->name( $q->param( 'name' ) );
		$object->storeObject();
		$self->Session()->commitTransaction();
	}

	# allow adding datasets to a project
	my $dataset_ids = $q->param( 'datasets_to_add' );
	if( $dataset_ids ) {
		OME::Tasks::ProjectManager->addDatasets( [ split( m',', $dataset_ids ) ], $object->id() );
	}
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
