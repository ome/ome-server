# OME/Web/DBObjDetail/__OME_Module.pm

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


package OME::Web::DBObjDetail::__OME_Module;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_Module

=head1 DESCRIPTION

allows editing of execution_instructions iff an 'Edit' url_param is given

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::DatasetManager;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub getPageBody {
	my $self = shift;

	my $q = $self->CGI();
	# default normal: ideally would call superclass method
	unless( $q->url_param( 'Edit' ) ) {
		my $object = $self->_loadObject();
		( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
		my $html = $q->startform( { -name => $self->{ form_name } } ).
				   $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
				   $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
				   $q->hidden({-name => 'action', -default => ''}).
				   $self->Renderer()->render( $object, 'detail' ).
				   $q->endform();
	
		return ('HTML', $html);
	}
	
	# Allow editing
	$self->_takeAction();

	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
			   $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
			   $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
			   $q->hidden({-name => 'action', -default => ''}).
			   $self->Renderer()->render( $object, 'edit' ).
			   $q->endform();

	return ('HTML', $html);	
}

sub _takeAction {
	my $self = shift;
	my $object = $self->_loadObject();
	my $q = $self->CGI();
	if( $q->param( 'action' ) && $q->param( 'action' ) eq 'SaveChanges' ) {
		$object->description( $q->param( 'description' ) );
		$object->execution_instructions( $q->param( 'execution_instructions' ) );
		$object->storeObject();
		$self->Session()->commitTransaction();
	}
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
