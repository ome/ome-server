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
		foreach my $request ( @{ $field_requests->{ 'thumb_url' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = OME::Tasks::ImageManager->getThumbURL( $obj );
		}
	}
	# original file
	if( exists $field_requests->{ 'original_file' } ) {
		foreach my $request ( @{ $field_requests->{ 'original_file' } } ) {
			my $request_string = $request->{ 'request_string' };
			# Find the original file (this code should really live in ImageManager)
			my $import_mex = $factory->findObject( "OME::ModuleExecution", 
				'module.name' => 'Image import', 
				image => $obj, 
				__order => 'timestamp' );
			my $ai = $factory->findObject( 
				"OME::ModuleExecution::ActualInput", 
				module_execution => $import_mex,
				'formal_input.semantic_type.name' => 'OriginalFile'
			);
			my $original_files = OME::Tasks::ModuleExecutionManager->getAttributesForMEX(
				$ai->input_module_execution,
				'OriginalFile'
			);
			
			if( scalar( @$original_files ) > 1 ) {
				my $more_info_url = 
 					$self->pageURL( 'OME::Web::Search', {
 						Type => '@OriginalFile',
 						id   => join( ',', map( $_->id, @$original_files ) ),
 					} );
				$record{ $request_string } = 
					scalar( @$original_files )." files found. ".
					"<a href='$more_info_url'>See individual listings</a> or ".
					"<a href='javascript:alert(\"Ilya is gonna do this part\");'>download them all at once</a>";
			} elsif( scalar( @$original_files ) == 1 ) {
				$record{ $request_string } = 
					$self->render( 
						$original_files->[0], 
						( $request->{ render } or 'ref' ), 
						$request 
					);
			} else {
				$record{ $request_string } = "No original files found";
			}
			my @original_file_links = map( 
				$self->render( $_, ( $request->{ render } or 'ref' ), $request ),
				@$original_files
			);
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
