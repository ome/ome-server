# OME/Web/RenderData/__OME_Image.pm
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


package OME::Web::RenderData::__OME_Image;

=pod

=head1 NAME

OME::Web::RenderData::__OME_Image - Specialized rendering for OME::Image

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::Image

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use OME::Tasks::ImageManager;
use base qw(OME::Web::RenderData);

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
	'created'
] ) ;
__PACKAGE__->_allFieldNames( [
	@{__PACKAGE__->_fieldNames() },
	'inserted',
	'image_guid',
] ) ;

=head2 getRefToObject

Overrides default behavior, html format uses a thumbnail for the link.

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
			my $thumbURL = OME::Tasks::ImageManager->getThumbURL($id); 
			my $ref = "<a href='serve.pl?Page=OME::Web::GetGraphics&ImageID=$id'><img src='$thumbURL'></a>";
			$ref .= "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$formal_name&ID=$id'>I($id)</a>";
			return $ref;
# 			return "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$formal_name&ID=$id'><table style='background-image:url(\"$thumbURL\")' width='50' height='50' cellpadding='0'><tr valign='bottom'><td align='right'><font class='ome_text_over_thumbnail'>I($id)</font></td></tr></table></a>";
		}
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
