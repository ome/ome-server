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

use HTML::Template;
use OME::Tasks::ImageManager;
use OME::Tasks::ModuleExecutionManager;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _fieldTitles } = {
		'default_pixels' => "Preview", 
		'image_guid'     => "GUID",
		'original_file'  => "Original File"
	};
	$self->{ _summaryFields } = [
		'default_pixels',
		'name',
		'description',
		'owner',
		'group',
		'created',
	];
	$self->{ _allFields } = [
		'default_pixels',
		'name',
		'description',
		'owner',
		'group',
		'created',
		'original_file',
		'inserted',
		'image_guid',
	];
	
	return $self;
}

=head2 _getRef

html format returns a thumbnail linking to the image viewer and the image name
linking to the Image object.

=cut

sub _getRef {
	my ($self,$obj,$format) = @_;
	
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		if( /^html$/ ) {
			my ($package_name, $common_name, $formal_name, $ST) =
				OME::Web->_loadTypeAndGetInfo( $obj );
			my $id   = $obj->id();
			my $name = $obj->name();
			my $thumbURL = OME::Tasks::ImageManager->getThumbURL($id); 
			my $ref = #"<a href='serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id' title='Detailed info about this Image' class='ome_detail'>$name</a><br>".
			          "<a href='javascript: openPopUpImage($id);' title='View this image'><img src='$thumbURL'></a>";
			return $ref;
		}
	}
}

=head2 _renderData

populates thumb_url, original_file, and module_executions

=cut

sub _renderData {
	my ($self, $obj, $field_names, $format, $mode, $options) = @_;
	
	my $factory = $obj->Session()->Factory();
	my $q = $self->CGI();
	my %record;

	# thumbnail url
	if( grep( /thumb_url/, @$field_names ) ) {
		$record{ 'thumb_url' } = OME::Tasks::ImageManager->getThumbURL( $obj );
	}
	# original file
	if( grep( /original_file/, @$field_names ) ) {
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
		my $img_name = $obj->name();
		$original_files = [ grep( $_->Path() =~ m/^$img_name/, @$original_files ) ]
			if( $original_files and scalar( @$original_files ) > 1);
		my $original_file = $original_files->[0];
		if( $original_file and $original_file->Repository() ) { 
			my $originalFile_url =  $original_file->Repository()->ImageServerURL().'?Method=ReadFile&FileID='.$original_file->FileID();
			my $path = $self->_trim( $original_file->Path(), $options );
			$record{ 'original_file' } = $q->a( { -href => $originalFile_url, title => 'Download original file' }, $path )
				if( $format eq 'html' );
			$record{ 'original_file' } = $path
				if( $format eq 'txt' );
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
