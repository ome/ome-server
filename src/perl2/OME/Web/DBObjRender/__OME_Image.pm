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

OME::Web::RenderData::__OME_Image - Render DBObjects for display

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
my %_fieldLabels = (
	'id'             => "ID",
	'name'           => "Name", 
	'default_pixels' => "Default Pixels", 
	'description'    => "Description", 
	'owner'          => "Owner",
	'group'          => "Group",
	'created'        => "Created",
	'inserted'       => "Inserted",
	'image_guid'     => "GUID"
);
my @_fieldNames = ('id', 'default_pixels', 'name', 'description', 'owner', 'group', 'created');
my @_allFieldNames = (@_fieldNames, 'inserted', 'image_guid');


=head2 getFieldNames
Overrides default behavior, uses class data to return labels
=cut
sub getFieldNames { return @_fieldNames if wantarray; return \@_fieldNames; }

=head2 getAllFieldNames
Overrides default behavior, uses class data to return labels
=cut
sub getAllFieldNames { return @_allFieldNames if wantarray; return \@_allFieldNames; }

=head2 getFieldLabels
Overrides default behavior, uses class data to return labels
=cut
sub getFieldLabels {
	my ($proto,$type,$fieldNames) = @_;
	$fieldNames = $proto->getFieldNames() unless $fieldNames;
	my %fieldLabels = map{ $_ => $_fieldLabels{$_} } @$fieldNames;
	return %fieldLabels if wantarray;
	return \%fieldLabels;
}

=head2 getRefToObject
Overrides default behavior, html format uses a thumbnail for the link.
=cut
sub getRefToObject {
	my ($proto,$obj,$format) = @_;
	
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		# FIXME
		if( /^html$/ ) {
			my $type = $proto->_getType( $obj );
			my $id   = $obj->id();
			my $thumbURL = OME::Tasks::ImageManager->getThumbURL($id); 
			return "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$type&ID=$id'><table style='background-image:url(\"$thumbURL\")' width='50' height='50' cellpadding='0'><tr valign='bottom'><td align='right'><font class='ome_text_over_thumbnail'>I($id)</font></td></tr></table></a>";
		}
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
