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
use CGI;
use Log::Agent;
use Carp;
use Carp qw(cluck);
use HTML::Template;

use base qw(OME::Web);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	my %params = @_;
		
	return $self;
}

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

Subclasses must follow the naming convention implemented in _getSpecializedRenderer.

All methods work with Object Prototypes, SemanticTypes, attributes, and dbobject instances.
If using with a Semantic Type, prefix the ST name with '@' (i.e. '@Pixels').

All methods are sensitive to array context. That is, they will return an
array or hash if called in an array context, and will otherwise return
references to arrays and hashes.

=head1 Synopsis

	use OME::Web::DBObjRender;

# FIXME: add examples

=head1 Methods

=head2 getName

	my $object_name = OME::Web::DBObjRender->getName( $object, $options );

Gets a name for this object. Subclasses may override this method.
If a 'name' or a 'Name' method exists for this object, it will be returned.
Otherwise, 'id' will be returned.
By default, the name returned will be a maximum of 23 characters long. This is enforced by
truncation and concatenation of '...'. This length may be overridden by specifying a
'max_text_length' option. A 0 or undefined value results in no truncation. A
'max_text_length' of 3 or less will result in irregular behavior.

Subclasses must implement 'max_text_length'. 

=cut

sub getName {
	my ($self, $obj, $options) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->getName( $obj )
		if( $specializedRenderer );

	$options->{ max_text_length } = 23 unless exists $options->{ max_text_length };
	my $name;
	$name = $obj->name() if( $obj->getColumnType( 'name' ) );
	$name = $obj->Name() if( $obj->getColumnType( 'Name' ) );
	$name = $obj->id() unless $name;
	$name = $self->_trim( $name, $options );
	
	return $name;
}

=head2 getTitle

	my $title = OME::Web::DBObjRender->getTitle( $object, $format );

Gets a title for this object. Subclasses may override this method.
If a 'name' or a 'Name' method exists for this object, it will be returned.
Otherwise, '[Common name] [id] (from [Source Module Name])' will be returned.

=cut

sub getTitle {
	my ($self, $obj, $format) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->getTitle( $obj, $format )
		if( $specializedRenderer );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $obj );
	my $q = new CGI;
	my $prefix = ( ( $ST and ($format eq 'html') ) ? 
		$q->a( { 
			href  => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id(),
			title => 'Semantic Type Documentation'
		},$common_name) : 
		$common_name
	);
	my $name = $self->getName( $obj, { max_text_length => undef } );

	return "$prefix: $name".
		( ( $ST and $obj->module_execution() and $obj->module_execution()->module() ) ?
			' from '.__PACKAGE__->getRef( $obj->module_execution(), $format ) :
			''
		);

}

=head2 getRef

	my $formated_ref = OME::Web::DBObjRender->getRef( $object, $format );

$object is an instance of a DBObject or an Attribute.
$format is either 'html' or 'txt'

This method returns a text reference. 
For 'txt' format, it will be an id number. 
For 'html' format, it will be an '<a href=...' that links to a
detailed display of the object.

=cut

sub getRef {
	my ($self, $obj, $format, $options) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->getRef( $obj, $format )
		if( $specializedRenderer );
	
	my $q = new CGI;
	for( $format ) {
		if( /^html$/ ) {
			my ($package_name, $common_name, $formal_name, $ST) =
				OME::Web->_loadTypeAndGetInfo( $obj );
			my $id = $obj->id();
			my $name = $self->getName( $obj, $options );
			return  $q->a( 
				{ 
					href => "serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id",
					title => "Detailed info about this $common_name",
					class => 'ome_detail'
				},
				$name
			);
		}
		return $self->getName( $obj );
	}
}

=head2 render

	my $obj_summary = OME::Web::DBObjRender->render( $object, $mode );

$object is an instance of a DBObject or an Attribute.
$mode is 'summary' or 'detail'

returns an html rendering of the object. 

This method looks for templates (read up on HTML::Template) in the html/Templates
directory that match the object and mode. If no template is found, then 
generic templates are used instead.

The naming convention for templates is:
	for an 'OME::Image' DBObject and 'summary' mode, OME_Image_summary.tmpl
	for a 'Pixels' Attribute in 'detail' mode, Pixels_detail.tmpl

If a specialized template is found, the parameter list is extracted, and renderData() is
called to populate it. Variables not defined by DBObject methods (or STD elements) may be
populated by the _renderData() method of specialized subclasses. See 'thumb_url' in
OME_Image_summary.tmpl and OME::Web::DBObjRender::__OME_Image::_renderData() for an example of
this.

=cut

sub render {
	my ($self, $obj, $mode) = @_;
	my ($tmpl, %tmpl_data);

	# look for custom template
	my $summary_tmpl = $self->_findTemplate( $obj, $mode );
	if( $summary_tmpl ) {
		$tmpl = HTML::Template->new( filename => $summary_tmpl );
		# load template variable requests
		my @fields = grep( !m'^_relations$', $tmpl->param() );
		%tmpl_data = $self->renderData( $obj, \@fields, 'html', $mode );
	} else {

		# use generic template
		my $tmpl_dir = $self->Session()->Configuration()->ome_root().'/html/Templates/';
		$tmpl = HTML::Template->new( filename => 'generic_'.$mode.'.tmpl',
										path     => $tmpl_dir);
	
		# load object data
		my @fields = $self->getFields( $obj, $mode );
		my %data = $self->renderData( $obj, \@fields, 'html', $mode );
		my @name_values;
		push @name_values, { name => $_, value => $data{ $_ } }
			foreach @fields;
		
		# load template variable requests
		@fields = grep( !m'^name_value_pairs$|^_relations$', $tmpl->param() );
		%tmpl_data = $self->renderData( $obj, \@fields, 'html', $mode );
		$tmpl_data{ name_value_pairs } = \@name_values;
	}

	# load magic fields
	# _relations = iterate over the object's relations
	if( $tmpl->query( name => '_relations' ) ) {
		my ($relations, $names) = $self->getRelations( $obj, $mode );
		my @relations_data;
		foreach my $relation( @$relations ) {
			my $name = shift @$names;
# FIXME: clean up paging logic here! in fact, clean up this whole hack
			my $tableMaker = $self->Tablemaker();
			my ( $objects, $options, $title, $formal_name ) =
				$tableMaker->__parseParams( @$relation );
			my $_options = {
				more_info_url => ( 
					$tableMaker->pageURL( "OME::Web::DBObjTable", $tableMaker->{__params} ) or
					$options->{ URLtoMoreInfo }
				)
			};
			push( @relations_data, { 
				name => $name, 
				'!tiled_list' => $self->renderArray( \@$objects, 'tiled_list', $_options ) 
			} );
		}
		$tmpl_data{ _relations } = \@relations_data;
	}

	# populate template
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

sub renderArray {
	my ($self, $objs, $mode, $options) = @_;
	$options = {} unless $options; # don't have to do undef error checks this way
	
	# use generic template
	my $tmpl_dir = $self->Session()->Configuration()->ome_root().'/html/Templates/';
	my $tmpl = HTML::Template->new( filename => 'generic_'.$mode.'.tmpl',
                                    path     => $tmpl_dir);
	my %tmpl_data;

	if( $objs && scalar( @$objs ) > 0 ) {
		my ($package_name, $common_name, $formal_name, $ST) =
			$self->_loadTypeAndGetInfo( $objs->[0] );
		
		# populate magic fields
		if( $tmpl->query( name => '_more_info_url' ) ) {
			$tmpl_data{ _more_info_url } = $options->{more_info_url};
		}
		if( $tmpl->query( name => '_paging_text' ) ) {
			$tmpl_data{ _paging_text } = $options->{_paging_text};
		}
		if( $tmpl->query( name => '_formal_name' ) ) {
			$tmpl_data{ _formal_name } = $formal_name;
		}
		if( $tmpl->query( name => '_common_name' ) ) {
			$tmpl_data{ _common_name } = $common_name;
		}
	
		# populate loops that tile objects
		if( $tmpl->query( name => '_tile_loop' ) ) {
			# find out about the object loop.
			my @innards = $tmpl->query( loop => '_tile_loop' );
			( my $obj_loop_command = $innards[0] ) =~ m/^_obj_loop!(\d+)/;
			my $n_tiles = $1;
			my @obj_fields = $tmpl->query( loop => ['_tile_loop', $obj_loop_command] );
			my @tile_data;
			while( @$objs ) {
				# grab the next bunch of objects
				my @objs2tile = splice( @$objs, 0, $n_tiles );
				# render their data
				my @objs_data = $self->renderData( \@objs2tile, \@obj_fields, 'html', $mode );
				# pad the data block to match the other rows. Now we have a 'tile'
				if( scalar( @tile_data ) ) {
					push( @objs_data, {} ) for( 1..( $n_tiles - scalar( @objs2tile ) ) );
				}
				# push the 'tile' on the stack of tiles
				push( @tile_data, { $obj_loop_command => \@objs_data } );
			}
			$tmpl_data{ _tile_loop } = \@tile_data;
		}
		
		# populate loops around objects
		if( $tmpl->query( name => '_obj_loop' ) ) {
			# populate the fields inside the loop
			my @obj_fields = $tmpl->query( loop => '_obj_loop' );
			$tmpl_data{ _obj_loop } = [ $self->renderData( \@$objs, \@obj_fields, 'html', $mode ) ];
					
		}
	}

	# populate template
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

=head2 renderData

	# plural
	my @records = OME::Web::DBObjRender->renderData( \@objects, \@field_names, $format, $mode );
	# singular
	my %record = OME::Web::DBObjRender->renderData( $object, \@field_names, $format, $mode );

@objects is an array of instances of a DBObject or a Semantic Type.
$field_names is used to populate the returned hash.
$format is either 'html' or 'txt'
$mode is either 'summary' or 'detail'

When called in plural context, returns an array of hashes.
When called in singular context, returns a single hash.
The hashes will be of the form { field_name => rendered_field, ... }

Special field names:
	_id: will be populated solely with the id, regardless of format or mode
	_title: will be populated with whatever is returned by getTitle( $object, $format ) 

=cut

sub renderData {
	my ($self, $obj, $field_names, $format, $mode, $options) = @_;
	my ( %record, $specializedRenderer );
	$options = {} unless $options; # makes things easier
	
	# handle plural calling style
	if( ref( $obj ) eq 'ARRAY' ) {
		my @records;
		push( @records, { $self->renderData( $_, $field_names, $format, $mode, $options) } )
			foreach @$obj;
		return @records;
	}
	
	# specialized rendering
	$specializedRenderer = $self->_getSpecializedRenderer( $obj );
	%record = $specializedRenderer->_renderData( $obj, $field_names, $format, $mode, $options )
		if $specializedRenderer;

	# set mode-based behavior
	if( $mode eq 'summary' ) {
		$options->{ max_text_length } = 71 unless exists $options->{ max_text_length };
	}

	# default rendering
	my $q = new CGI;
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $id   = $obj->id();
	foreach my $field( @$field_names ) {
		# don't override specialized renderings
		next if exists $record{ $field };
		
		# _id = plain text id
		if( $field eq '_id' ) {
			$record{ _id } = $obj->id();
		
		# _title = object title
		} elsif( $field eq '_title' ) {
			$record{ _title } = $self->getTitle( $obj, $format );
		
		# _name = object name
		} elsif( $field eq '_name' ) {
			$record{ _name } = $self->getName( $obj, $options );
					
		# _ref = reference to object
		} elsif( $field eq '_ref' ) {
			$record{ _ref } = $self->getRef( $obj, $format, $options );
					
		# make name and id into links for html summary views
		} elsif( ( $field eq 'id' || $field eq 'name' ) &&
		         ( $format eq 'html' && $mode eq 'summary' ) ) {
			$record{ $field } = $q->a( 
				{ 
					href  => "serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id",
					title => "Detailed info about this $common_name",
					class => 'ome_detail'
				},
				$obj->$field
			);
		
		# populate has many aliases
		} elsif( $field =~ m/^(.+)!(.+)$/ ) {
			my ($method, $render_mode) = ($1, $2);
# FIXME: add paging logic here! FIX these hacks too!
			my @list = $obj->$method();
			my $returnedClass;
			my $accessorType = $obj->getColumnType( $method );
			if( $accessorType eq 'has-many' ) {
				 $returnedClass = $obj->__hasManys()->{$method}->[0];
			} elsif( $accessorType eq 'many-to-many' ) {
				 $returnedClass = $obj->__manyToMany()->{$method}->[0];
			}
			my $url = $self->pageURL( "OME::Web::DBObjTable", { 
					Type => $returnedClass,
					$returnedClass.'_accessor' => join( ',', $formal_name, $id, $method )
				} );
			my $options = { more_info_url => $url };
			$record{ $field } = $self->renderArray( \@list, $render_mode, $options );

		# populate mode render requests
		} elsif( $field =~ m/^!(.+)$/ ) {
			my $render_mode = $1;
			$record{ $field } = $self->render( $obj, $render_mode );
		
		# populate all other fields
		} else {
			$record{ $field } = $obj->$field;
			if( ref( $record{ $field } ) ) {
				$record{ $field } = $self->getRef( $record{ $field }, $format, $options );
			} else {
				my $type = $obj->getColumnSQLType( $field );
				my %booleanConvert = ( 0 => 'False', 1 => 'True' );
				$record{ $field } =~ s/^([^:]+(:\d+){2}).*$/$1/
					if $type eq 'timestamp';
				$record{ $field } = $booleanConvert{ $record{ $field } }
					if $type eq 'boolean';
				$record{ $field } = $self->_trim( $record{ $field }, $options )
					if( $type =~ m/^varchar|text/ ); 
			}
		}
	}
	
	return %record;
}


=head2 _renderData

	%partial_record = $specializedRenderer->_renderData( $obj, $format, $field_names, $options );

Virtual method. Subclasses should override this if to do custom rendering of certain fields
or to implement fields not implemented in DBObject. Examples of this are:
	Experimenter's email turned to active link if format is html
	Image having an 'Original File' field.

Subclasses need only populate fields in the record they are overriding. i.e. Image does NOT
need to populate the 'name' field.

=cut

sub _renderData{ return (); }

=head2 getFields

	my @fields = OME::Web::DBObjRender->getFields( $type, $mode );

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance
of either
$mode may be 'summary' or 'all'.

Returns an ordered list of field names for the specified object type and mode.

This method should not be overridden.

=cut

sub getFields {
	my ($self, $type, $mode) = @_;
	my $specializedRenderer = ( $self->_getSpecializedRenderer( $type ) or {} );

	# use subclass data for summary mode
	if( $mode eq 'summary' and $specializedRenderer->{ _summaryFields }) {
		return @{ $specializedRenderer->{ _summaryFields } };

	# use subclass data for all mode
	} elsif ( $mode eq 'all' and $specializedRenderer->{ _allFields }) {
		return @{ $specializedRenderer->{ _allFields } };
	}

	# autopopulate fields insensitive to mode
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	# We don't need no target
	return ( 'id', sort( grep( $_ ne 'target', $package_name->getPublishedCols()) ) );
}

=head2 getFieldTypes

	my %fieldTypes = OME::Web::DBObjRender->getFieldTypes($type, \@field_names);

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance
of either.
$field_names is used to populate the returned hash.

returns a hash { field_name => field_type }
field_type is the reference type the field will return. it is equivalent to ref(
$instance_of_type->$field_name )

=cut

sub getFieldTypes {
	my ($self,$type,$field_names,$doNotSpecialize) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $type );
	return $specializedRenderer->getFieldTypes( $type,$field_names )
		if( $specializedRenderer );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	my %fieldTypes = map{ $_ => $package_name->getAccessorReferenceType($_) } @$field_names;

	return %fieldTypes if wantarray;
	return \%fieldTypes;
}


=head2 getFieldTitles

	my %fieldTitles = OME::Web::DBObjRender->getFieldTitles( $type, \@field_names, $format );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
@field_names is used to populate the returned hash.
$format may be 'txt' or 'html'. it is also optional (defaults to 'txt').

returns a hash { field_name => title }

=cut

sub getFieldTitles {
	my ($self,$type,$field_names,$format) = @_;
	
	my $specializedRenderer = $self->_getSpecializedRenderer( $type );
	return $specializedRenderer->getFieldTitles( $type, $field_names, $format )
		if( $specializedRenderer );
	
	$format = 'txt' unless $format;

	# make titles by prettifying the aliases. Add links to Semantic
	# Element documentation as available.
	my %titles;
	my $q = new CGI;
	my $factory = OME::Web->Session()->Factory();
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	
	# _fieldTitles allows specialized renderers to overide titles
	my $pkg_titles = $self->{ _fieldTitles };
	foreach( @$field_names ) {
		my ($alias,$title) = ($_,$_);
		$title =~ s/_/ /g;
		if( $format eq 'txt' ) {
			$titles{$alias} = ( $pkg_titles->{$alias} or ucfirst($title) );
		} else {
			$titles{$alias} = ( $pkg_titles->{$alias} or ucfirst($title) );
			if( $ST ) {
				my $SE = $factory->findObject( 
					'OME::SemanticType::Element', 
					semantic_type => $ST,
					name          => $alias
				);
				$titles{$alias} = $q->a(
					{ 
						href => "serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType::Element&ID=".$SE->id(), 
						title => 'Documentation on '.$SE->name()
					},
					$titles{$alias}
				) if $SE;
			}
		}
	};
	return %titles;
}


=head2 getRelations

	my ($relations, $names) = OME::Web::DBObjRender->getRelations( $object );
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	foreach( @$relations ) {
		$table_hash{ shift @$names } = $tableMaker->getTable( @$_ );
		...
	}

$object is an instance of a DBObject or an Attribute.
$relations is an array reference. For convenienve, its members are formatted for DBObjTable
getTable and getList methods. That is, 
[
	{ title => $title },
	$relation_accessors->{ $method },
	( { accessor => [ $formal_name, $obj->id, $method ] } OR
	  /@objects )
]
$names is an array reference. It holds the names of the relations. Each name will be
composed of alphanumeric characters, underscores, and dashes.

This method gets an object's has many relations. This may include relations that are
convenient but to avoid redundancy in the DB, have not defined with DBObject methods. (i.e.
Module Execution's inputs and outputs)

=cut

sub getRelations {
	my ($self, $obj) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->getRelations( $obj )
		if( $specializedRenderer );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $obj );
	my ( @relations, @names );
	my $relation_accessors = $obj->getPublishedManyRefs();
	foreach my $method ( sort( keys %$relation_accessors ) ) {
		(my $title = $method) =~ s/_/ /g;
		$title = ucfirst( $title );
		push( @relations, [
			{ title => $title },
			$relation_accessors->{ $method },
			{ accessor => [ $formal_name, $obj->id, $method ] }
		] );
		push @names, $method;
	}
	
	return (\@relations, \@names);
}

=head2 getSearchFields

	# get html form elements keyed by field names 
	my %searchFields = OME::Web::DBObjRender->getSearchFields( $type, \@field_names, \%default_search_values );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
@field_names is used to populate the returned hash.
%default_search_values is also optional. If given, it is used to populate the search form fields.

returns a hash { field_name => form_input, ... }

=cut

sub getSearchFields {
	my ($self, $type, $field_names, $defaults) = @_;
	
	my $specializedRenderer = $self->_getSpecializedRenderer( $type );
	return $specializedRenderer->getSearchFields( $type, $field_names )
		if( $specializedRenderer );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );

	my %searchFields;
	my $q = new CGI;
	my %fieldRefs = map{ $_ => $package_name->getAccessorReferenceType( $_ ) } @$field_names;
	my $size;
	foreach my $accessor ( @$field_names ) {
		if( $fieldRefs{ $accessor } ) {
			$searchFields{ $accessor } = $self->getRefSearchField( $formal_name, $fieldRefs{ $accessor }, $accessor, $defaults->{ $accessor } );
		} else {
			if( $accessor eq 'id' ) { $size = 5; }
			else { $size = 8; }
			$searchFields{ $accessor } = $q->textfield( 
				-name    => $formal_name."_".$accessor , 
				-size    => $size, 
				-default => $defaults->{ $accessor } 
			);
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
	my ($self, $from_type, $to_type, $accessor_to_type) = @_;
	
	my $specializedRenderer = $self->_getSpecializedRenderer( $to_type );
	return $specializedRenderer->getRefSearchField( $from_type, $to_type, $accessor_to_type )
		if( $specializedRenderer );

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
	my ($self,$type) = @_;
	
	# get DBObject prototype or ST name from instance
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	
	# construct specialized package name
	my $specializedPackage = $formal_name;
	($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
	$specializedPackage = "OME::Web::DBObjRender::__".$specializedPackage;

	return undef if( ref( $self ) eq $specializedPackage );
	# return cached renderer
	return $self->{ $specializedPackage } if $self->{ $specializedPackage };

	# load specialized package
	eval( "use $specializedPackage" );
	unless( $@ ) {
		$self->{ $specializedPackage } = $specializedPackage->new( CGI => $self->CGI() );
		return $self->{ $specializedPackage };
	}
	
	# couldn't load the special package? return undef
	return undef;
}

=head2 _trim

	$string = $self->_trim( $string, $options );

Package utility for trimming strings. 
if $options->{ max_text_length } exists, is defined, and is non-zero,
then the returned string will be trimmed to that length 
	(original string is truncated and '...' is appended)

=cut

sub _trim { 
	my( $self, $str, $options ) = @_;

	return $str unless(
		( ref( $options ) eq 'HASH' ) and
		exists $options->{ max_text_length } and
		$options->{ max_text_length } and
		( length( $str ) > $options->{ max_text_length } )
	);
	return substr( $str, 0, $options->{ max_text_length } - 3 ).'...';
}

sub _findTemplate {
	my ( $self, $obj, $mode ) = @_;
	my $tmpl_dir = $self->Session()->Configuration()->ome_root().'/html/Templates/';
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $summary_tmpl = $formal_name; 
	$summary_tmpl =~ s/@//g; 
	$summary_tmpl =~ s/::/_/g; 
	$summary_tmpl .= "_".$mode.".tmpl";
	$summary_tmpl = $tmpl_dir.'/'.$summary_tmpl;
	return $summary_tmpl if -e $summary_tmpl;
	return undef;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
