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
use OME;
our $VERSION = $OME::VERSION;

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
TXT, (and perhaps someday) SVG. It's default rendering can be overridden by
writing subclasses.

Important!! Subclasses should not be accessed directly. All Rendering
should go through DBObjRendering. Specialization is completely
transparent.

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

	my %fieldLabels = OME::Web::DBObjRender->getFieldLabels( $type, \@fieldNames, $format );
	
$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
@fieldNames is optional. It is used to populate the returned hash.
Default is the list returned by getFieldNames.
$format may be 'txt' or 'html'. it is also optional (defaults to 'txt').

returns a hash { field_name => field_Label }

=cut

sub getFieldLabels {
	my ($proto,$type,$fieldNames,$format) = @_;
	
	my $specializedRenderer;
	return $specializedRenderer->getFieldLabels( $type,$fieldNames )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $type ) and
		    $proto eq __PACKAGE__);
	
	$fieldNames = $proto->getFieldNames( $type ) unless $fieldNames;
	$format = 'txt' unless $format;

	# make labels by prettifying the aliases. Add links to Semantic
	# Element documentation as available.
	my %labels;
	my $q = new CGI;
	my $factory = OME::Web->Session()->Factory();
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	
	# _fieldLabels is class data that allows specialized renderers to overide a subset of labels
	my $pkg_labels = $proto->_fieldLabels();
	foreach( @$fieldNames ) {
		my ($alias,$label) = ($_,$_);
		$label =~ s/_/ /g;
		if( $format eq 'txt' ) {
			$labels{$alias} = ( $pkg_labels->{$alias} or ucfirst($label) );
		} else {
			$labels{$alias} = ( $pkg_labels->{$alias} or ucfirst($label) );
			if( $ST ) {
				my $SE = $factory->findObject( 
					'OME::SemanticType::Element', 
					semantic_type => $ST,
					name          => $alias
				);
				$labels{$alias} = $q->a(
					{ href => "serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType::Element&ID=".$SE->id() },
					$labels{$alias} )
					if $SE;
			}
		}
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

=head2 getObjectLabels

	my $object_labels = OME::Web::DBObjRender->getObjectLabels( \@objects  );

The plural of getObjectLabel. Should not be overriden.

=cut

sub getObjectLabels {
	my ($proto,$objs) = @_;
	my @labels = map( $proto->getObjectLabel( $_ ), @$objs );
	return @labels if wantarray;
	return \@labels;
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

=head2 getRefsToObject

	my $object_refs = OME::Web::DBObjRender->getRefsToObject( \@objects, $format  );

The plural of getRefToObject. Should not be overriden.

=cut

sub getRefsToObject {
	my ($proto,$objs, $format) = @_;
	my @refs = map( $proto->getRefToObject( $_, $format ), @$objs );
	return @refs if wantarray;
	return \@refs;
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

=head2 getRelationAccessors

	my $relationsAccessors = OME::Web::DBObjRender->getRelationAccessors( $object );

$object is an instance of a DBObject or an Attribute.

get an object's has many relations. This may include relations not
defined with DBObject methods.

$relationsAccessors is an iterator. It has methods
	next first name return_type getList

it can be used like so:

	my $relationsAccessors = OME::Web::DBObjRender->getRelationAccessors( $object ); 
	if( $relationsAccessors->first() ) { do {
		my $type = $relationsAccessors->return_type();
		my $objects = $relationsAccessors->getList();
		my $relation_name = $relationsAccessors->name();
		# do stuff
	} while( $relationsAccessors->next() ); }


=cut

sub getRelationAccessors {
	my ($proto,$obj) = @_;
	my $specializedRenderer;
	return $specializedRenderer->getRelationAccessors( $obj )
		if( $specializedRenderer = $proto->_getSpecializedRenderer( $obj ) and
		    $proto eq __PACKAGE__);

	my $iterator = OME::Web::DBObjRender::Iterator->new( 
		$proto->__gather_PublishedManyRefs( $obj ) );

	return $iterator;
}

sub __gather_PublishedManyRefs {
	my ($proto,$obj) = @_;

	my $relation_accessors = $obj->getPublishedManyRefs();
	my @methods = sort( keys %$relation_accessors );
	my @objects = map( \$obj, @methods );
	my @names;
	foreach my $method (@methods ) {
		(my $name = $method) =~ s/_/ /g;
		$name = ucfirst( $name );
		push @names, $name;
	}
	@names             = sort( @names );
	my @params         = map( (), @methods );
	my @call_as_scalar = map( 0, @methods );
	my @return_type    = map{ $relation_accessors->{ $_ } } @methods;

	return( \@objects, \@methods, \@params, \@return_type, \@names, \@call_as_scalar );
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
	my $size;
	foreach my $accessor ( @$fieldNames ) {
		if( $fieldRefs{ $accessor } ) {
			$searchFields{ $accessor } = $proto->getRefSearchField( $formal_name, $fieldRefs{ $accessor }, $accessor );
		} else {
			if( $accessor eq 'id' ) { $size = 5; }
			else { $size = 8; }
			$searchFields{ $accessor } = $q->textfield( -name => $formal_name."_".$accessor , -size => $size );
		}
	}

	return %searchFields if wantarray;
	return \%searchFields;
}

=head2 getRefSearchField

	# get an html form element that will allow searches to $to_type
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
	return $q->textfield( -name => $from_formal_name."_".$accessor_to_type.$searchOn , -size => 6 );
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

package OME::Web::DBObjRender::Iterator;

sub new {
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	
	my ($objects, $methods, $params, $return_type, $names, $call_as_scalar) = @_;
	
	my $self = {
		__objects     => $objects,
		__methods     => $methods,
		__params      => $params,
		__return_type => $return_type,
		__names       => $names,
		__call_as_scalar => $call_as_scalar,
		__count       => 0,
		__length      => scalar( @$objects )
	};
	
	bless $self, $class;
	return $self;
}

sub next {
	my $self = shift;
	return undef
		if( ($self->{__count} + 1) >= $self->{__length} );
	$self->{__count}++;
	return $self;
}

sub first {
	my $self = shift;
	return undef
		if( $self->{__length} eq 0 );
	$self->{__count} = 0;
	return $self;
}

sub name {
	my $self = shift;
	return $self->{__names}->[ $self->{__count} ];
}

sub return_type {
	my $self = shift;
	return $self->{__return_type}->[ $self->{__count} ];
}

sub getList {
	my $self = shift;
	my $object = ${ $self->{__objects}->[ $self->{__count} ] };
	my $method = $self->{__methods}->[ $self->{__count} ];
	my $params = $self->{__params }->[ $self->{__count} ] or [];
	my @list;
	if ( $self->{__call_as_scalar}->[ $self->{__count} ] ) {
		my $list = $object->$method( @$params );
		@list = @$list;
	} else {
		@list = $object->$method( @$params );
	}
	return \@list;
}

1;
