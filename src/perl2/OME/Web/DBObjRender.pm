# OME/Web/RenderData.pm
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


package OME::Web::RenderData;

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;


$VERSION = $OME::VERSION;

use CGI;
use Log::Agent;

=pod

=head1 NAME

OME::Web::RenderData - Render DBObjects for display

=head1 DESCRIPTION

RenderData will render DBObjects (and attributes) for display in HTML,
TXT, (and potentially) SVG. It's default rendering can be overridden by
writing subclasses.

Subclasses follow the naming convention implemented in specializeRendering.
Subclasses are expected to override one or more of the functions
getFieldNames, getFieldDescriptions, getSearchFields, getRefToObject, render

All methods work with Object Prototypes, SemanticTypes, attributes, and dbobject instances.
If using with a Semantic Type, prefix the ST name with '@' (i.e. '@Pixels').

=head1 Synopsis

	# All these methods work with SemanticTypes, attributes, and dbobject instances
	# If using with a Semantic Type, prefix the ST name with '@' (i.e. '@Pixels')

	use OME::Web::RenderData;

	# get field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::RenderData->getFieldNames( "OME::Image" );

	# get field types { field_name => field_type, ... }
	my %fieldTypes = OME::Web::RenderData->getFieldTypes( "OME::Image" );

	# get field labels { field_name => field_label, ... }
	my %fieldLabels = OME::Web::RenderData->getFieldLabels( "OME::Image" );

	# get search fields keyed by field names (html only) { field_name => search_field, ... }
	my %searchFields = OME::Web::RenderData->getSearchFields( "OME::Image" );

	# get an html reference to this object "<a href=...>"
	my $renderedRef = OME::Web::RenderData->getRefToObject( $image, 'html' );

	# render objects to html format ( { field_name => rendered_field, ... }, ... )
	my @records = OME::Web::RenderData->render( \@image, 'html' );

	# obtain a specialized rendering class
	my $renderer = ( OME::Web::RenderData->specializeRendering("OME::Image") || OME::Web::RenderData )


=head1 Methods

=head2 getFieldNames

	my @fieldNames = OME::Web::RenderData->getFieldNames("OME::Image");
	
returns an ordered list of the field names of the specified object or object type
=cut
sub getFieldNames {
	my ($proto,$type) = @_;
	
	return $proto->getFieldNames( $type )
		if( $proto = $proto->specializeRendering( $type ) );
	
	$type = _getProto( $type );
	# We don't need no *_id aliases.
	return sort( grep( !/_id$/, $type->getColumns()) );
}


=head2 getFieldTypes

	my %fieldTypes = OME::Web::RenderData->getFieldTypes("OME::Image");
	
returns a hash { field_name => field_type }
field_type is the reference type the field will return.
it is equivalent to ref( $image->$field_name )
=cut
sub getFieldTypes {
	my ($proto,$type) = @_;
	
	my @fields = $proto->getFieldNames( $type );
	$type = _getProto( $type );
	return map{ $_ => $type->getPackageReference($_) } @fields;
}


=head2 getFieldLabels
	my %fieldLabels = OME::Web::RenderData->getFieldLabels( "OME::Image" );
	
returns a hash { field_name => field_Label }
=cut
sub getFieldLabels {
	my ($proto,$type) = @_;
	
	return $proto->getFieldLabels( $type )
		if( $proto = $proto->specializeRendering( $type ) );
	
	$type = _getProto( $type );
	# We don't need no *_id aliases.
	my @aliases = sort( grep( !/_id$/, $type->getColumns()) );
	
	# make labels by prettifying the aliases
	my %labels;
	foreach( @aliases ) {
		my ($alias,$label) = ($_,$_);
		$label =~ s/_/ /g;
		$labels{$alias} = ucfirst($label);
	};
	return %labels;
}


=head2 specializeRendering

	my $imageRendering = OME::Web::RenderData->specializeRendering("OME::Image");
	my $imageRendering = OME::Web::RenderData->specializeRendering($image);

	my $pixelRendering = OME::Web::RenderData->specializeRendering("@Pixels");
	my $pixelRendering = OME::Web::RenderData->specializeRendering($pixels);
	
returns a specialized prototype (if one exists) for rendering a particulae type of data.
returns undef if a specialized prototype does not exist.
=cut
sub specializeRendering {
	my ($proto,$specialization) = @_;
	
	# get prototype from instance
	my $type = _getProto( $specialization );
	
	# construct specialized package name
	$specialization =~ s/::/_/g;
	my $specializedPackage = "OME::Web::RenderData::__".$specialization;
	
	# obtain package
	eval( "use $specializedPackage" );
	return $specializedPackage
		unless $@;

	return undef;
}

# loads and returns Prototype
sub _getProto {
	my $type = shift;

	# get prototype from instance
	$type = ref( $type ) if( ref($type) );
	
	# get DBObject from attribute & ensure it is loaded.
	if( $type =~ /^@/ ) {
		my $session = OME::Session->instance();
		my $attr_name = substr( $type, 1 );
		my $ST = $session->Factory->findObject("OME::SemanticType", name=>$attr_name);
		$ST->requireAttributeTypePackage();
		$type = $ST->getAttributeTypePackage();
	} else {
	# make sure DBObject is loaded. We'll be needing to call methods on it later.
		eval( "use $type" ) unless $type =~ /^OME::SemanticType/;
		die "Error loading package $type. Error msg is:\n$@"
			if $@;
	}
	return $type;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
