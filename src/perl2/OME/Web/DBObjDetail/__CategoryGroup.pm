# OME/Web/DBObjDetail/__Category.pm

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


package OME::Web::DBObjDetail::__CategoryGroup;

=pod

=head1 NAME

OME::Web::DBObjDetail::__CategoryGroup

=head1 DESCRIPTION

implements _takeAction to allow CategoryGroup name and description to be
modified

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub _takeAction {
	my $self = shift;
	my $obj = $self->_loadObject();
	my $q = $self->CGI();
	
	if( $q->param( 'action' ) eq 'SaveChanges' ) {
# [Bug 479] http://bugs.openmicroscopy.org.uk/show_bug.cgi?id=479
	  # $obj->Name( $q->param( 'name' ) );
		$obj->Description( $q->param( 'description' ) );
		$obj->storeObject();
		$self->Session()->commitTransaction();
	}
	
}

=head1 Author

Tom Macura <tmacura@nih.gov>

=cut

1;
