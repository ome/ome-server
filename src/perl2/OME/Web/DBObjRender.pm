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

Subclasses follow the naming convention implemented in _getSpecializedRenderer.
Subclasses are expected to override one or more of the functions
getFieldNames, getAllFieldNames, getFieldTypes, getFieldLabels, getSearchFields, getRefToObject, renderSingle

All methods work with Object Prototypes, SemanticTypes, attributes, and dbobject instances.
If using with a Semantic Type, prefix the ST name with '@' (i.e. '@Pixels').

All methods are sensitive to array context. That is, they will return an
array or hash if called in an array context, and will otherwise return
references to arrays and hashes.

=head1 Synopsis

	# All methods work with Object Prototypes, SemanticTypes,
	# attributes, and dbobject instances.
	# If using with a Semantic Type, prefix the ST name with '@'
	# (i.e. '@Pixels')

	use OME::Web::RenderData;

	# get field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::RenderData->getFieldNames( "OME::Image" );

	# get all field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::RenderData->getAllFieldNames( "OME::Image" );

	# get field types { field_name => field_type, ... }
	my %fieldTypes = OME::Web::RenderData->getFieldTypes( "OME::Image" );

	# get field labels { field_name => field_label, ... }
	my %fieldLabels = OME::Web::RenderData->getFieldLabels( "OME::Image" );

	# get search fields keyed by field names (html only) { field_name => search_field, ... }
	my %searchFields = OME::Web::RenderData->getSearchFields( "OME::Image" );

	# get an html reference to this object "<a href=...>"
	my $renderedRef = OME::Web::RenderData->getRefToObject( $image, 'html' );

	# render object data to html format ( { field_name => rendered_field, ... }, ... )
	my @records = OME::Web::RenderData->render( \@images, 'html' );
 	# or txt format
 	my @records = OME::Web::RenderData->render( \@images, 'txt' );

	# obtain a specialized rendering class
	my $specializedRenderer = ( OME::Web::RenderData->_getSpecializedRenderer("OME::Image") || OME::Web::RenderData )


=head1 Methods

=head2 getFieldNames

	my @fieldNames = OME::Web::RenderData->getFieldNames($type);

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either

Returns an ordered list of the most relevant field names for the
specified object or object type.
i.e. for OME::Image, the system insert time stamp will not be returned with this
call.

Useful for constructing an object summary.
=cut
sub getFieldNames {
	my ($proto,$type) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getFieldNames( $type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) );

	$type = _getProto( $type );
	# We don't need no *_id aliases.
	my @fieldNames = ('id', sort( grep( !/_id$/, $type->getColumns()) ) );
	return @fieldNames if wantarray;
	return \@fieldNames;
}

=head2 getAllFieldNames

	my @fieldNames = OME::Web::RenderData->getAllFieldNames($type);

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either

Returns an ordered list of all relevant field names for the specified object or object type.
e.g. For OME::Image, this will include all time stamps but will exclude id accessors.

Useful for a detailed object representation.
=cut
sub getAllFieldNames { 
	my ( $proto, $type ) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getAllFieldNames( $type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) );
	return $proto->getFieldNames( $type );
}

=head2 getFieldTypes

	my %fieldTypes = OME::Web::RenderData->getFieldTypes($type, \@fieldNames);

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either
$fieldNames is optional. It is used to populate the returned hash. Default is the list returned by getFieldNames.

returns a hash { field_name => field_type }
field_type is the reference type the field will return. it is equivalent to ref( $instance_of_type->$field_name )
=cut
sub getFieldTypes {
	my ($proto,$type,$fieldNames) = @_;

	my $specializedRenderer;
	return $specializedRenderer->getFieldTypes( $type,$fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) );

	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	$type = _getProto( $type );
	my %fieldTypes = map{ $_ => $type->getPackageReference($_) } @$fieldNames;

	return %fieldTypes if wantarray;
	return \%fieldTypes;
}


=head2 getFieldLabels
	my %fieldLabels = OME::Web::RenderData->getFieldLabels( $type, \@fieldNames );
	
$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

returns a hash { field_name => field_Label }
=cut
sub getFieldLabels {
	my ($proto,$type,$fieldNames) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getFieldLabels( $type,$fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) );
	
	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	$type = _getProto( $type );
	# make labels by prettifying the aliases
	my %labels;
	foreach( @$fieldNames ) {
		my ($alias,$label) = ($_,$_);
		$label =~ s/_/ /g;
		$labels{$alias} = ucfirst($label);
	};
	return %labels if wantarray;
	return \%labels;
}


=head2 render
	my @records = OME::Web::RenderData->render( \@objects, $format, \@fieldNames );

@objects is an array of instances of a DBObject or a Semantic Type.
$format is either 'html' or 'txt'

Render object data suitable for display in $format. Current supported
formats are 'html' and 'txt'.
Depending on the calling parameters, returns an array of hashes 
the hashes will take the form { field_name => rendered_field, ... }

$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

This relies on renderSingle for actual rendering, so subclasses do not
need to implement this.
=cut
sub render {
	my ($proto,$objects,$format,$fieldnames) = @_;
	return $proto->renderSingle( $objects, $format,$fieldnames )
		unless ref( $objects ) eq 'ARRAY';
	my @records = map( $proto->renderSingle( $_, $format ), @$objects );
	return @records if wantarray;
	return \@records;
}


=head2 renderSingle
	my %record = OME::Web::RenderData->renderSingle( $object, $format, \@fieldNames );

$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

same as render, but works with an individual instance instead of arrays.
=cut
sub renderSingle {
	my ($proto,$obj,$format,$fieldNames) = @_;

	my $specializedRenderer;
	return $specializedRenderer->renderSingle( $obj, $format, $fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) );

	$fieldNames = $proto->getFieldNames( $obj ) unless $fieldNames;
	my %record;
	foreach my $field( @$fieldNames ) {
		$record{ $field } = $obj->$field;
		$record{ $field } = OME::Web::RenderData->getRefToObject( $record{ $field }, $format )
			if( ref( $record{ $field } ) );
	}
	
	return %record if wantarray;
	return \%record;
}


=head2 getRefToObject
	my $formated_ref = OME::Web::RenderData->getRefToObject( $object, $format );

$object is an instance of a DBObject or an Attribute.
$format is either 'html' or 'txt'

This method returns a text reference. 
For 'txt' format, it will be an id number. 
For 'html' format, it will be an '<a href=...' that links to a
detailed display of the object.
=cut
sub getRefToObject {
	my ($proto,$obj,$format) = @_;
	my $specializedRenderer;
	return $specializedRenderer->getRefToObject( $obj, $format )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) );
	
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		# FIXME
		if( /^html$/ ) {
			return $obj->id();
		}
	}
}

=head2 _getSpecializedRenderer

	my $specializedRenderer = OME::Web::RenderData->_getSpecializedRenderer($type);
	
$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either

returns a specialized prototype (if one exists) for rendering a
particular type of data.
returns undef if a specialized prototype does not exist or if it was
called with with a specialized prototype.
=cut
sub _getSpecializedRenderer {
	my ($proto,$specialization) = @_;
	
	# get prototype from instance
	$specialization = _getProto( $specialization );
	
	# construct specialized package name
	$specialization =~ s/::/_/g;
	my $specializedPackage = "OME::Web::RenderData::__".$specialization;

	# obtain package
	eval( "use $specializedPackage" );
	return $specializedPackage
		unless $@ or $proto eq $specializedPackage;

	return undef;
}

=head2 _getProto

	my $type = _getProto( $type );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either

This holds the magic to return the DBObject prototype from whatever
$type happens to be. It also loads the DBObject so methods can be called on it.
=cut
sub _getProto {
	my $type = shift;

	# get prototype from instance
	if( ref($type) ) {
		$type = ref( $type ) ;
		return $type if $type =~ /^OME::SemanticType::/;
	}
	
	# get DBObject from attribute & ensure it is loaded.
	if( $type =~ /^@/ ) {
		my $session = OME::Session->instance();
		my $attr_name = substr( $type, 1 );
		my $ST = $session->Factory->findObject("OME::SemanticType", name=>$attr_name);
		$ST->requireAttributeTypePackage();
		$type = $ST->getAttributeTypePackage();
	} else {
	# make sure DBObject is loaded. We'll be needing to call methods on it later.
		eval( "use $type" ) ;
		die "Error loading package $type. Error msg is:\n$@"
			if $@;
	}
	return $type;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
