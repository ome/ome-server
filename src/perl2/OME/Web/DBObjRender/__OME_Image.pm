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
use vars qw($VERSION);
use OME;
use OME::Tasks::ImageManager;
use OME::Tasks::ModuleExecutionManager;
use base qw(OME::Web::DBObjRender);

# Class data
__PACKAGE__->_fieldLabels( {
	'id'             => "ID",
	'default_pixels' => "Default Pixels", 
	'image_guid'     => "GUID"
});
__PACKAGE__->_fieldNames( [
	'id',
	'default_pixels',
	'name',
	'description',
	'owner',
	'group',
	'created',
	'original_file'
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
	'inserted',
	'image_guid',
] ) ;

=head2 getRefToObject

html format returns a thumbnail linking to the image viewer and the image name
linking to the Image object.

=cut

sub getRefToObject {
	my ($proto,$obj,$format) = @_;
	
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
			my $ref = "<a href='#' onClick='openPopUpImage($id); return false'><img src='$thumbURL'></a><br>".
			          "<a href='serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id'>$name</a>";
			return $ref;
		}
	}
}

=head2 renderSingle

adds link to original file

=cut

sub renderSingle {
	my ($proto,$obj,$format,$fieldnames) = @_;
	my $factory = $obj->Session()->Factory();
	my $q = new CGI;

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $obj );

	$fieldnames = $proto->getFieldNames( $obj ) unless $fieldnames;
	my $id   = $obj->id();
	my %record;
	foreach my $field( @$fieldnames ) {
		if( $field eq 'id') {
			$record{ $field } = $q->a( 
				{ href => "serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id" },
				$id
			);
		} elsif( $field eq 'original_file' ) {
			my $import_mex = $factory->findObject( "OME::ModuleExecution", 'module.name' => 'Image import', image => $obj, __order => 'timestamp' );
			my @ais = $import_mex->inputs();
			my $ai = $ais[0];
			my $original_file = OME::Tasks::ModuleExecutionManager->
				getAttributesForMEX($ai->input_module_execution,$ai->formal_input()->semantic_type)->[0];
			my $originalFile_url = $original_file->Repository()->ImageServerURL() . '?Method=ReadFile&FileID='.$original_file->FileID();
			$record{ $field } = $q->a( { -href => $originalFile_url }, $original_file->Path() );
		} else {
			$record{ $field } = $obj->$field;
			$record{ $field } = OME::Web::DBObjRender->getRefToObject( $record{ $field }, $format )
				if( ref( $record{ $field } ) );
		}
	}
	
	return %record if wantarray;
	return \%record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
