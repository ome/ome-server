# OME/Web/DBObjRender/__Pixels.pm
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


package OME::Web::DBObjRender::__Pixels;

=pod

=head1 NAME

OME::Web::DBObjRender::__Pixels - specialized rendering of Pixels ST

=head1 DESCRIPTION

Provides custom behavior for rendering Pixels ST

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Web;
use OME::Session;
use OME::Tasks::PixelsManager;
use base qw(OME::Web::DBObjRender);

# Class data - override default behavior
__PACKAGE__->_fieldNames( [
	'id',
	'SizeX',
	'SizeY',
	'SizeZ',
	'SizeC',
	'SizeT',
	'image',
	'module_execution'
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
	'PixelType',
	'BitsPerPixel',
	'FileSHA1',
	'ImageServerID',
	'Repository'
] ) ;


=head2 getRefToObject

html format returns a thumbnail linking to the image viewer and a link
to the Pixels attribute.

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
			my $source_module; $source_module = $obj->module_execution()->module()->name()
				if $obj->module_execution() and $obj->module_execution()->module();
			my $thumbURL = OME::Tasks::PixelsManager->getThumbURL($id); 
			my $ref = "<a href='#' onClick='openPopUpPixels($id); return false'><img src='$thumbURL'></a><br>".
			          "<a href='serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id'>Pixels from $source_module</a>";
			return $ref;
		}
	}
}

=head2 getRefSearchField

No search field to Pixels

=cut

sub getRefSearchField {
	my ($proto, $from_type, $to_type, $accessor_to_type) = @_;
	
	return undef;
}



=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
