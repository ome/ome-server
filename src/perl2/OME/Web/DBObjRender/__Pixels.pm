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
use OME::Session;
use OME::Tasks::PixelsManager;
use base qw(OME::Web::RenderData);

# Class data
my %_fieldLabels = (
	'id'               => "ID",
	'image'            => "Image",
	'module_execution' => "Module Execution (MEX)"
);
my @_fieldNames = ('id', 'SizeX', 'SizeY', 'SizeZ', 'SizeC', 'SizeT', 'PixelType', 'BitsPerPixel', 'image', 'module_execution', 'semantic_type');
my @_allFieldNames = (@_fieldNames, 'FileSHA1', 'ImageServerID', 'Repository' );


=head2 getFieldNames
Overrides default behavior, uses class data to return labels
=cut
sub getFieldNames { return @_fieldNames if wantarray; return \@_fieldNames; }

=head2 getAllFieldNames
Overrides default behavior, uses class data to return labels
=cut
sub getAllFieldNames { return @_allFieldNames if wantarray; return \@_allFieldNames; }

=head2 getFieldLabels
Overrides some field labels
=cut
sub getFieldLabels {
	my ($proto,$type,$fieldNames) = @_;
	$fieldNames = $proto->getFieldNames() unless $fieldNames;
	my %fieldLabels = $proto->SUPER::getFieldLabels( $type, $fieldNames, 1 );
	( exists $_fieldLabels{$_} and $fieldLabels{ $_ } = $_fieldLabels{$_} )
		foreach( @$fieldNames );
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
		if( /^html$/ ) {
			my $type = $proto->_getType( $obj );
			my $id   = $obj->id();
			my $image_id = $obj->image()->id();
			my $thumbURL = OME::Tasks::PixelsManager->getThumbURL($id); 
			my $ref = "<a href='serve.pl?Page=OME::Web::GetGraphics&ImageID=$image_id'><img src='$thumbURL'></a>";
			$ref .= "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$type&ID=$id'>P($id)</a>";
			return $ref;
		}
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
