# OME/Web/DBObjRender/__OME_Image.pm
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


package OME::Web::DBObjRender::__OME_Image;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_Image - Specialized rendering for OME::Image

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::Image

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Tasks::ImageManager;
use OME::Tasks::ModuleExecutionManager;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _renderData

makes virtual fields thumb_url and original_file
original file doesn't make sense for images with multiple source files

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	
	my $factory = $obj->Session()->Factory();
	my %record;

	# thumbnail url
	if( exists $field_requests->{ 'thumb_url' } ) {
		$record{ 'thumb_url' } = OME::Tasks::ImageManager->getThumbURL( $obj );
	}
	# original file
	if( exists $field_requests->{ 'original_file' } ) {
		# Find the original file (this code should really live in ImageManager)
		my $import_mex = $factory->findObject( "OME::ModuleExecution", 
			'module.name' => 'Image import', 
			image => $obj, 
			__order => 'timestamp' );
		my $ai = $factory->findObject( 
			"OME::ModuleExecution::ActualInput", 
			module_execution => $import_mex
		);
		my $original_files = OME::Tasks::ModuleExecutionManager->getAttributesForMEX(
			$ai->input_module_execution,
			$ai->formal_input()->semantic_type
		) if $ai;
		# Try to guess which file was the original one
		my $img_name = $obj->name();
		$original_files = [ grep( $_->Path() =~ m/^$img_name/, @$original_files ) ]
			if( $original_files and scalar( @$original_files ) > 1);
		my $original_file = $original_files->[0];
		if( scalar( @$original_files) eq 1 && $original_file && $original_file->Repository() ) { 
			$record{ 'original_file' } = $self->render( 
				$original_file, 
				( $field_requests->{ original_file }->{ render } or 'ref' ), 
				$field_requests->{ original_file } 
			);
		} else {
			$record{ 'original_file' } = undef;
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
