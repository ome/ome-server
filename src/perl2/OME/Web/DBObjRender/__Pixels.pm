# OME/Web/RenderData/__Pixels.pm
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


package OME::Web::RenderData::__Pixels;

=pod

=head1 NAME

OME::Web::RenderData::__Pixels - specialized rendering of Pixels ST

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
use base qw(OME::Web::RenderData);

# Class data - override default behavior
__PACKAGE__->_fieldLabels( {
	'id'               => "ID",
	'module_execution' => "MEX"
});
__PACKAGE__->_fieldNames( [
	'id',
	'SizeX',
	'SizeY',
	'SizeZ',
	'SizeC',
	'SizeT',
	'PixelType',
	'BitsPerPixel',
	'image',
	'module_execution'
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
	'FileSHA1',
	'ImageServerID',
	'Repository'
] ) ;


=head2 getRefToObject

html format returns a thumbnail linking to the image viewer and an id
linking to the Pixels attribute.

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
			my $image_id = $obj->image()->id();
			my $thumbURL = OME::Tasks::PixelsManager->getThumbURL($id); 
			my $ref = "<a href='serve.pl?Page=OME::Web::GetGraphics&ImageID=$image_id'><img src='$thumbURL'></a>";
			$ref .= "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$formal_name&ID=$id'>P($id)</a>";
			return $ref;
		}
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
