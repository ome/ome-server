# OME/Web/DBObjRender/__OME_Dataset.pm
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
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_Dataset;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_Dataset - Specialized rendering for OME::Dataset

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::Dataset

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Tasks::DatasetManager;
use OME::Session;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _renderData

makes virtual fields 
	current_annotation: the text contents of the current Dataset annotation
		according to OME::Tasks::DatasetManager->getCurrentAnnotation()
	current_annotation_author: A ref to the author of the current annotation 
		iff it was not written by the user
	annotation_count: The total number of annotations about this dataset

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my %record;

	# current_annotation:
	if( exists $field_requests->{ 'current_annotation' } ) {
		foreach my $request ( @{ $field_requests->{ 'current_annotation' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $currentAnnotation = OME::Tasks::DatasetManager->
				getCurrentAnnotation( $obj );
			$record{ $request_string } = $currentAnnotation->Content
				if $currentAnnotation;
		}
	}
	# current_annotation_author:
	if( exists $field_requests->{ 'current_annotation_author' } ) {
		foreach my $request ( @{ $field_requests->{ 'current_annotation_author' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $currentAnnotation = OME::Tasks::DatasetManager->
				getCurrentAnnotation( $obj );
			$record{ $request_string } = $self->Renderer()->
				render( $currentAnnotation->module_execution->experimenter(), 'ref' )
				if( ( defined $currentAnnotation ) && 
# a bug in the ACLs are not always letting the mex come through. so, hack-around
				    ( defined $currentAnnotation->module_execution ) &&
				    ( $currentAnnotation->module_execution->experimenter->id() ne 
				      $session->User()->id() )
				);
		}
	}
	# annotation_count:
	if( exists $field_requests->{ 'annotation_count' } ) {
		foreach my $request ( @{ $field_requests->{ 'annotation_count' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $factory->
				countObjects( '@DatasetAnnotation', dataset => $obj );
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
