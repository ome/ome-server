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

	use OME::Web::RenderData;

	# get field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::RenderData->getFieldNames( $type );

	# get all field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::RenderData->getAllFieldNames( $type );

	# get field types { field_name => field_type, ... }
	my %fieldTypes = OME::Web::RenderData->getFieldTypes( $type );

	# get field labels { field_name => field_label, ... }
	my %fieldLabels = OME::Web::RenderData->getFieldLabels( $type );

	# get search form elements keyed by field names (html only) { field_name => search_field, ... }
	my %searchFields = OME::Web::RenderData->getSearchFields( $type );

	# get an html reference to this object "<a href=...>"
	my $renderedRef = OME::Web::RenderData->getRefToObject( $object, 'html' );

	# render object data to html format ( { field_name => rendered_field, ... }, ... )
	my @records = OME::Web::RenderData->render( \@objects, 'html' );
 	# or txt format
 	my @records = OME::Web::RenderData->render( \@objects, 'txt' );

	# obtain a specialized rendering class
	my $specializedRenderer = ( OME::Web::RenderData->_getSpecializedRenderer($type) || OME::Web::RenderData )


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
	my ($proto,$type, $doNotSpecialize) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getFieldNames( $type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    not $doNotSpecialize);

	$type = $proto->_getProto( $type );
	
	# We don't need no *_id aliases or target
	my @fieldNames = ('id', sort( grep( (!/_id$/ and !/^target$/), $type->getColumns()) ) );
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
	my ( $proto, $type, $doNotSpecialize ) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getAllFieldNames( $type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    not $doNotSpecialize);

	return $proto->getFieldNames($type, $doNotSpecialize);
}

=head2 getFieldTypes

	my %fieldTypes = OME::Web::RenderData->getFieldTypes($type, \@fieldNames);

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either
$fieldNames is optional. It is used to populate the returned hash. Default is the list returned by getFieldNames.

returns a hash { field_name => field_type }
field_type is the reference type the field will return. it is equivalent to ref( $instance_of_type->$field_name )

=cut

sub getFieldTypes {
	my ($proto,$type,$fieldNames,$doNotSpecialize) = @_;

	my $specializedRenderer;
	return $specializedRenderer->getFieldTypes( $type,$fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    not $doNotSpecialize);

	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	$type = $proto->_getProto( $type );
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
	my ($proto,$type,$fieldNames, $doNotSpecialize) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getFieldLabels( $type,$fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    not $doNotSpecialize);
	
	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	$type = $proto->_getProto( $type );
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
	my ($proto,$objects,$format,$fieldnames, $doNotSpecialize) = @_;

	return $proto->renderSingle( $objects, $format,$fieldnames, $doNotSpecialize )
		unless ref( $objects ) eq 'ARRAY';

	my @records;
	foreach ( @$objects ) {
		my $record = $proto->renderSingle( $_, $format, $fieldnames, $doNotSpecialize );
		push( @records, $record );
	}
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
	my ($proto,$obj,$format,$fieldNames, $doNotSpecialize) = @_;

	my $specializedRenderer;
	return $specializedRenderer->renderSingle( $obj, $format, $fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    not $doNotSpecialize);

	my $q = new CGI;
	$fieldNames = $proto->getFieldNames( $obj ) unless $fieldNames;
	my $type = $proto->_getType( $obj );
	my $id   = $obj->id();
	my %record;
	foreach my $field( @$fieldNames ) {
		if( $field eq 'id') {
			$record{ $field } = $q->a( 
				{ href => "serve.pl?Page=OME::Web::ObjectDetail&Type=$type&ID=$id" },
				$id
			);
		} else {
			$record{ $field } = $obj->$field;
			$record{ $field } = OME::Web::RenderData->getRefToObject( $record{ $field }, $format )
				if( ref( $record{ $field } ) );
		}
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
	my ($proto,$obj,$format, $doNotSpecialize) = @_;
	my $specializedRenderer;
	return $specializedRenderer->getRefToObject( $obj, $format )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    not $doNotSpecialize);
	
	my $q = new CGI;
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		# FIXME
		if( /^html$/ ) {
			my $type = $proto->_getType( $obj );
			my $id   = $obj->id();
			return  $q->a( 
				{ href => "serve.pl?Page=OME::Web::ObjectDetail&Type=$type&ID=$id" },
				$id
			);
		}
	}
}

=head2 getSearchFields

	# get html form elements keyed by field names 
	my %searchFields = OME::Web::RenderData->getSearchFields( $type, @fieldNames );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

returns a hash { field_name => search_field, ... }

=cut

sub getSearchFields {
	my ($proto,$type, $fieldNames, $doNotSpecialize) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getSearchFields( $type, $fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    not $doNotSpecialize);

	$type = $proto->_getType( $type );

	my %searchFields;
	my $q = new CGI;
	$searchFields{ $_ } = $q->textfield( -name => $type."_".$_ , -size => '5' )
		foreach ( @$fieldNames );

	return %searchFields if wantarray;
	return \%searchFields;
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
	
	# get DBObject prototype or ST name from instance
	$specialization = $proto->_getProto( $specialization );
	my $type = $proto->_getType( $specialization );
	
	# construct specialized package name
	($type =~ s/::/_/g or $type =~ s/@//);
	my $specializedPackage = "OME::Web::RenderData::__".$type;

	# obtain package
	eval( "use $specializedPackage" );
	return $specializedPackage
		unless $@ or $proto eq $specializedPackage;

	return undef;
}

=head2 _getProto

	my $type = OME::Web::RenderData->_getProto( $type );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either

This holds the magic to return the DBObject prototype from whatever
$type happens to be. It also loads the DBObject so methods can be called on it.

=cut

sub _getProto {
	my ($proto, $type) = @_;

	# get prototype from instance
	if( ref($type) ) {
		$type = ref( $type ) ;
	}
	
	# Don't try to load proto if type is a ST.
	return $type if $type =~ /^OME::SemanticType::__/;
	
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


=head2 _getType

	my $type = OME::Web::RenderData->_getType( $type );

$type can be a DBObject name ("OME::Image"), an Attribute DBObject
("OME::SemanticType::__STName"), or an instance of either

Returns either the DBObject prototype or @AttrName from whatever
$type happens to be.

=cut

sub _getType {
	my ($proto, $type) = @_;

	# get prototype from instance
	$type = ref( $type ) if( ref($type) );

	# @Attr_name is already formatted properly
	return $type if $type =~ /^@/;
	
	# Attribute DBObject -> @AttrName
	return $type if $type =~ s/^OME::SemanticType::__(.*)$/\@$1/;

	# it's a DBObject proto
	return $type;
}

sub _typeIsST {
	my ($proto, $type) = @_;
	$type = $proto->_getProto( $type );
	return 1 if $type =~ /OME::SemanticType::__/;
	return 0;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
