# OME/Web/DBObjRender.pm
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


package OME::Web::DBObjRender;

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use OME::Web;

$VERSION = $OME::VERSION;

use CGI;
use Log::Agent;

use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata('_fieldLabels');
__PACKAGE__->mk_classdata('_fieldNames');
__PACKAGE__->mk_classdata('_allFieldNames');

=pod

=head1 NAME

OME::Web::DBObjRender - Render DBObjects for display

=head1 DESCRIPTION

DBObjRender will render DBObjects (and attributes) for display in HTML,
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

	use OME::Web::DBObjRender;

	# get field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::DBObjRender->getFieldNames( $type );

	# get all field names for a DBObject  ( field_name, ... )
	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames( $type );

	# get field types { field_name => field_type, ... }
	my %fieldTypes = OME::Web::DBObjRender->getFieldTypes( $type );

	# get field labels { field_name => field_label, ... }
	my %fieldLabels = OME::Web::DBObjRender->getFieldLabels( $type );

	# get search form elements keyed by field names (html only) { field_name => search_field, ... }
	my %searchFields = OME::Web::DBObjRender->getSearchFields( $type );

	# get an html reference to this object "<a href=...>"
	my $renderedRef = OME::Web::DBObjRender->getRefToObject( $object, 'html' );

	# render object data to html format ( { field_name => rendered_field, ... }, ... )
	my @records = OME::Web::DBObjRender->render( \@objects, 'html' );
 	# or txt format
 	my @records = OME::Web::DBObjRender->render( \@objects, 'txt' );

	# obtain a specialized rendering class
	my $specializedRenderer = ( OME::Web::DBObjRender->_getSpecializedRenderer($type) || OME::Web::DBObjRender )


=head1 Methods

=head2 getFieldNames

	my @fieldNames = OME::Web::DBObjRender->getFieldNames($type);

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
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    $proto eq __PACKAGE__);

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	
	# We don't need no target
	my $fieldNames = ( 
		$proto->_fieldNames() or
		['id', sort( grep( $_ ne 'target', $package_name->getPublishedCols()) ) ] 
	);
	return @$fieldNames if wantarray;
	return $fieldNames;
}

=head2 getAllFieldNames

	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames($type);

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either

Returns an ordered list of all relevant field names for the specified object or object type.
e.g. For OME::Image, this will include all time stamps but will exclude id accessors.

Useful for a detailed object representation.

=cut

sub getAllFieldNames { 
	my ( $proto, $type ) = @_;

	my $specializedRenderer;
	return $specializedRenderer->getAllFieldNames( $type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    $proto eq __PACKAGE__);

	my $fieldNames = (
		$proto->_allFieldNames() or
		$proto->getFieldNames($type)
	);
	
	return @$fieldNames if wantarray;
	return $fieldNames;
}

=head2 getFieldTypes

	my %fieldTypes = OME::Web::DBObjRender->getFieldTypes($type, \@fieldNames);

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
		    $proto eq __PACKAGE__);

	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	my %fieldTypes = map{ $_ => $package_name->getAccessorReferenceType($_) } @$fieldNames;

	return %fieldTypes if wantarray;
	return \%fieldTypes;
}


=head2 getFieldLabels

	my %fieldLabels = OME::Web::DBObjRender->getFieldLabels( $type, \@fieldNames );
	
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
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    $proto eq __PACKAGE__);
	
	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;

	# make labels by prettifying the aliases
	my %labels;
	
	# _fieldLabels is class data that allows specialized renderers to overide a subset of labels
	my $pkg_labels = $proto->_fieldLabels();
	foreach( @$fieldNames ) {
		my ($alias,$label) = ($_,$_);
		$label =~ s/_/ /g;
		$labels{$alias} = ( $pkg_labels->{$alias} or ucfirst($label) );
	};
	return %labels if wantarray;
	return \%labels;
}


=head2 render

	my @records = OME::Web::DBObjRender->render( \@objects, $format, \@fieldNames );

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

	my @records;
	foreach ( @$objects ) {
		my $record = $proto->renderSingle( $_, $format, $fieldnames );
		push( @records, $record );
	}
	return @records if wantarray;
	return \@records;
}


=head2 renderSingle

	my %record = OME::Web::DBObjRender->renderSingle( $object, $format, \@fieldNames );

$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

same as render, but works with an individual instance instead of arrays.

=cut

sub renderSingle {
	my ($proto,$obj,$format,$fieldnames) = @_;

	my $specializedRenderer;
	return $specializedRenderer->renderSingle( $obj, $format, $fieldnames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    $proto eq __PACKAGE__);

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
		} else {
			$record{ $field } = $obj->$field;
			$record{ $field } = OME::Web::DBObjRender->getRefToObject( $record{ $field }, $format )
				if( ref( $record{ $field } ) );
		}
	}
	
	return %record if wantarray;
	return \%record;
}

=head2 getObjectLabel

	my $object_label = OME::Web::DBObjRender->getObjectLabel( $object  );

Gets a name for this object. Subclasses may override this method.
If a 'name' or a 'Name' method exists for this object, it will be returned.
Otherwise, 'id' will be returned.

=cut

sub getObjectLabel {
	my ($proto,$obj) = @_;

	my $specializedRenderer;
	return $specializedRenderer->getObjectLabel( $obj )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    $proto eq __PACKAGE__);

	return $obj->name() if( $obj->getColumnType( 'name' ) );
	return $obj->Name() if( $obj->getColumnType( 'Name' ) );
	return $obj->id();
}

=head2 getRefToObject

	my $formated_ref = OME::Web::DBObjRender->getRefToObject( $object, $format );

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
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    $proto eq __PACKAGE__);
	
	my $q = new CGI;
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		# FIXME
		if( /^html$/ ) {
			my ($package_name, $common_name, $formal_name, $ST) =
				OME::Web->_loadTypeAndGetInfo( $obj );
			my $id = $obj->id();
			my $label = $proto->getObjectLabel( $obj, $format );
			return  $q->a( 
				{ href => "serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id" },
				$label
			);
		}
	}
}

=head2 getSearchFields

	# get html form elements keyed by field names 
	my %searchFields = OME::Web::DBObjRender->getSearchFields( $type, @fieldNames );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.

returns a hash { field_name => form_input, ... }

=cut

sub getSearchFields {
	my ($proto,$type, $fieldNames) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getSearchFields( $type, $fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    $proto eq __PACKAGE__);

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;

	my %searchFields;
	my $q = new CGI;
	my %fieldRefs = map{ $_ => $package_name->getAccessorReferenceType( $_ ) } @$fieldNames;
	foreach my $accessor ( @$fieldNames ) {
		if( $fieldRefs{ $accessor } ) {
			$searchFields{ $accessor } = $proto->getRefSearchField( $formal_name, $fieldRefs{ $accessor }, $accessor );
		} else {
			$searchFields{ $accessor } = $q->textfield( -name => $formal_name."_".$accessor , -size => '5' );
		}
	}

	return %searchFields if wantarray;
	return \%searchFields;
}

=head2 getRefSearchField

	# get an html form element that will allow searches to $type
	my $searchField = OME::Web::DBObjRender->getRefSearchField( $from_type, $to_type, $accessor_to_type );

the types may be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$from_type is the type you are searching from
$accessor_to_type is an accessor of $from_type that returns an instance of $to_type
$to_type is the type the accessor returns

returns a form input

=cut

sub getRefSearchField {
	my ($proto, $from_type, $to_type, $accessor_to_type) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getRefSearchField( $from_type, $to_type, $accessor_to_type )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $to_type ) and
		    $proto ne $to_type);

	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );
	my ($to_package) = OME::Web->_loadTypeAndGetInfo( $to_type );
	my $searchOn = '';
	$searchOn = '.name' if( $to_package->getColumnType( 'name' ) );
	$searchOn = '.Name' if( $to_package->getColumnType( 'Name' ) );

	my $q = new CGI;
	return $q->textfield( -name => $from_formal_name."_".$accessor_to_type.$searchOn , -size => '5' );
}

=head2 _getSpecializedRenderer

	my $specializedRenderer = OME::Web::DBObjRender->_getSpecializedRenderer($type);
	
$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance of either

returns a specialized prototype (if one exists) for rendering a
particular type of data.
returns undef if a specialized prototype does not exist or if it was
called with with a specialized prototype.

=cut

sub _getSpecializedRenderer {
	my ($proto,$type) = @_;
	
	# get DBObject prototype or ST name from instance
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	
	# construct specialized package name
	my $specializedPackage = $formal_name;
	($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
	$specializedPackage = "OME::Web::DBObjRender::__".$specializedPackage;

	# obtain package
	eval( "use $specializedPackage" );
	return $specializedPackage
		unless $@ or $proto eq $specializedPackage;

	return undef;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
