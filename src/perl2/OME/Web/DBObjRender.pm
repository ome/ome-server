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

=pod

=head1 NAME

OME::Web::DBObjRender - Render DBObjects for display

=head1 DESCRIPTION

DBObjRender will render things from the database for display. It can
render a single object or a group of objects. It provides paging
mechanisms for rendering groups of objects. It has generic mechanisms to
render anything by examining the object definition. These generic
renderings can be easily overridden by writing html templates and/or
subclassing this class.

It also has methods for asking other questions about an object such as 
	What fields provide a summary description of this object? A full description?
	What are the html form fields to use on search pages?
In addition to providing rendering, I set this class up to handle any
object services that are specific to the web interface need to be
overriden occasionally.

=head1 Using Rendering Services

=head2 Synopsis

	# get a renderer. $self is an instance of an OME::Web subclass
	my $renderService = $self->Renderer();
	# render a list of objects
	$html .= $renderService->renderArray( \@objects, $mode, \%options );
	# render a single object
	$html .= $renderService->render( $object, $mode, \%options );

Important!! Subclasses should not be accessed directly. All Rendering
should go through DBObjRendering. Specialization is completely
transparent.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Session;
use OME::Web;
use OME::Tasks::LSIDManager;
use CGI;
use Log::Agent;
use Carp;
use Carp qw(cluck);
use HTML::Template;

use base qw(OME::Web);

# set up class constants
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ page_limits } = {
		list  => 10,
		popup => 0,
		ref_list => 10,
		tiled_list => 24,
		tiled_ref_list => 24
	};
	
	return $self;
}

=head2 getName

	my $object_name = OME::Web::DBObjRender->getName( $object, $options );

Gets a name for this object. Subclasses may override this by implementing a _getName method.

If a 'name' or a 'Name' field exists for this object, that will be returned.
Otherwise, 'id' will be returned.
By default, the name returned will be a maximum of 23 characters long. This is enforced by
truncation and concatenation of '...'. This length may be overridden by specifying a
'max_text_length' option. A 0 or undefined value results in no truncation. A
'max_text_length' of 3 or less will result in irregular behavior.

=cut

sub getName {
	my ($self, $obj, $options) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->_getName( $obj, $options )
		if( $specializedRenderer and $specializedRenderer->can('_getName') );
 
	my $name;
	$name = $obj->name() if( $obj->getColumnType( 'name' ) );
	$name = $obj->Name() if( $obj->getColumnType( 'Name' ) );
	$name = $obj->id() unless $name;
	$name = $self->_trim( $name, $options );
	
	return $name;
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

	return '' unless $obj;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->_getRef( $obj, $format, $options )
		if( $specializedRenderer and $specializedRenderer->can('_getRef') );
	
	my $q = $self->CGI();
	if( $format eq 'html' ) {
		my ($package_name, $common_name, $formal_name, $ST) =
			OME::Web->_loadTypeAndGetInfo( $obj );
		my $id = $obj->id();
		my $name = $self->getName( $obj, $options );
		return  $q->a( 
			{ 
				href => $self->getObjDetailURL( $obj ),
				title => "Detailed info about this $common_name",
				class => 'ome_detail'
			},
			$name
		);
	}
	return $obj->id();
}


=head2 render

	my $obj_summary = OME::Web::DBObjRender->render( $object, $mode, \$options );

$object is an instance of a DBObject or an Attribute.
$mode is 'summary', 'detail', or 'ref'
$options is a grab bag that gets added to and removed from as development progresses.
nothing in it is terribly stable.

$obj_summary is an html rendering of the object. 

This method looks for templates (read up on HTML::Template) in the
OME/src/html/Templates directory that match the object and mode. If no
template is found, then generic templates are used instead.

If a specialized template is found, the parameter list is extracted, and
renderData() is called to populate it. Variables not defined by DBObject
methods (or STD elements) may be populated by the _renderData() method
of specialized subclasses. See 'thumb_url' in OME_Image_summary.tmpl and
OME::Web::DBObjRender::__OME_Image::_renderData() for an example of
this.

See also the section below on writing templates for specialized rendering.

=cut

sub render {
	my ($self, $obj, $mode, $options) = @_;
	my ($tmpl, %tmpl_data);

	# HACK to render references
	return $self->getRef( $obj, 'html' ) if $mode eq 'ref';

	# look for custom template
	my $tmpl_path = $self->_findTemplate( $obj, $mode );
	if( $tmpl_path ) {
		$tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
		# load template variable requests
		my @fields = grep( !m/^!/, $tmpl->param() );
		%tmpl_data = $self->renderData( $obj, \@fields, 'html', $mode, $options );
	} else {

		# use generic template
		my $tmpl_dir = $self->Session()->Configuration()->ome_root().'/html/Templates/';
		$tmpl = HTML::Template->new( 
			filename => 'generic_'.$mode.'.tmpl',
			path     => $tmpl_dir,
			case_sensitive => 1
		);
	
		# load object data
		my @fields = $self->getFields( $obj, $mode );
		my %data = $self->renderData( $obj, \@fields, 'html', $mode, $options );
		my @name_values;
		push @name_values, { name => $_, value => $data{ $_ } }
			foreach @fields;
		
		# load template variable requests
		@fields = grep( !m'^name_value_pairs$|^!relations$', $tmpl->param() );
		%tmpl_data = $self->renderData( $obj, \@fields, 'html', $mode, $options );
		$tmpl_data{ name_value_pairs } = \@name_values;
	}

	# load magic fields
	# !relations = iterate over the object's relations
	if( $tmpl->query( name => '!relations' ) ) {
		my $relations = $self->getRelations( $obj, $mode );
		my @tmpl_fields = $tmpl->query( loop => '!relations' );
		my @a = grep( m/^!/, @tmpl_fields); my $relation_render_mode = $a[0];
		my @relations_data;
		foreach my $relation( @$relations ) {
			my( $title, $method, $relation_type ) = @$relation;

			push( @relations_data, { 
				name => $title, 
				$relation_render_mode => $self->renderArray( 
					[ $obj, $method ], 
					substr( $relation_render_mode, 1 ), 
					{ _more_info_url => $self->getSearchAccessorURL( $obj, $method ),
					  type => $obj->getAccessorReferenceType( $method )->getFormalName()
					}
				)
			} );
		}
		$tmpl_data{ '!relations' } = \@relations_data;
	}

	# populate template
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

=head2 renderArray

	$rendered_objects = $self->renderArray( 
		\@objects, 
		$render_mode, 
		{ type => $object_type }
	);

This function uses templates to render a group of objects. It will
attach paging controls if the object list is too long.

@objects should contain either 
	a bunch of DBObjects to render or 
	a DBObject and an accessor that will yield a bunch of DBObject to render (i.e. [ $dataset, 'images' ] )

$render_mode is used to find a template for rendering this. Generic
templates for rendering groups are:

list - Produces a table with one object (rendered as summary) per row.
ref_list - Same as list, but with references instead of summaries.
tiled_list - Produces a table with three objects (rendered as summary) per row.
tiled_ref_list - Same as tiled_list, but with references instead of summaries.
ref_mass - Mushes all the references together without formatting.

These templates can be found under OME/src/html/Templates/generic_* 

%options holds optional parameters
	type is used to look for specialized templates. It's the formal name
	of the objects to be rendered. This is needed to find the specialized
	template.
	_more_info_url is a URL to a search page of these objects.



=cut

sub renderArray {
	my ($self, $objs, $mode, $options) = @_;
	$options = {} unless $options; # don't have to do undef error checks this way
	
	# [ $obj, $method ] calling style - load the objects and paging text.
	if( ref( $objs ) eq 'ARRAY' && scalar( @$objs ) eq 2 && !ref($objs->[1]) ) {
		my ($obj, $method) = @$objs;
		my ( @relation_objects, $pager_text );
		
		# try to get paging controls
		my ($offset, $limit);
		$limit = $self->{ page_limits }->{ $mode };
		my $count_method = 'count_'.$method;
		( $offset, $pager_text ) = $self->_pagerControl( 
			$method,
			$obj->$count_method,
			$limit
		);

		# set up paging if there is a limit for this type and if pagerControl returned ok
		if( $limit and $pager_text ) {
			@relation_objects = $obj->$method( __limit => $limit, __offset => $offset );
			$options->{_pager_text} = $pager_text;
		
		# get objs w/o paging
		} else {
			@relation_objects = $obj->$method();
		}
		$objs = \@relation_objects
	}
	
	# try to load custom template
	my $tmpl_path = $self->_findTemplate( $options->{type}, $mode );
	# use generic if there is no custom
	$tmpl_path = $self->Session()->Configuration()->ome_root().'/html/Templates/'.'generic_'.$mode.'.tmpl'
		unless $tmpl_path;
	my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
	my %tmpl_data;

	# put together data for template
	if( $objs && scalar( @$objs ) > 0 ) {
		my ($package_name, $common_name, $formal_name, $ST) =
			$self->_loadTypeAndGetInfo( $objs->[0] );
		
		# populate magic fields
		if( $tmpl->query( name => '_more_info_url' ) ) {
			$tmpl_data{ _more_info_url } = $options->{ _more_info_url };
		}
		if( $tmpl->query( name => '_pager_text' ) ) {
			$tmpl_data{ _pager_text } = $options->{ _pager_text };
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
				my @objs_data = $self->renderData( \@objs2tile, \@obj_fields, 'html', $mode, $options );
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
			$tmpl_data{ _obj_loop } = [ $self->renderData( \@$objs, \@obj_fields, 'html', $mode, $options ) ];
					
		}
	}

	# populate template
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

sub _pagerControl {
	my ( $self, $control_name, $obj_count, $limit ) = @_;
	return () unless ( $obj_count and $limit );

	# setup
	my $q = $self->CGI();
	my $offset = ($q->param( $control_name.'___offset' ) or 0);
	my $pagingText;
	my $numPages = POSIX::ceil( $obj_count / $limit );

	# Turn the page
	my $action = $q->param( 'page_action' ) ;
	if( $action ) {
		if( $action eq 'FirstPage_'.$control_name ) {
			$offset = 0;
		} elsif( $action eq 'PrevPage_'.$control_name ) {
			$offset -= $limit;
		} elsif( $action eq 'NextPage_'.$control_name ) {
			$offset += $limit;
		} elsif( $action eq 'LastPage_'.$control_name ) {
			$offset = ($numPages - 1)*$limit;
		}
	}
	my $currentPage = int( $offset / $limit ) + 1;


	# make controls
	if( $numPages > 1 ) {
		$pagingText = "<input type='hidden' name='".$control_name."___offset' VALUE='$offset'>";
		$pagingText .= $q->a( {
				-title => "First Page",
				-href => "javascript: document.forms[0].page_action.value='FirstPage_$control_name'; document.forms[0].submit();",
				}, 
				'<<'
			)." "
			if ( $currentPage > 1 and $numPages > 2 );
		$pagingText .= $q->a( {
				-title => "Previous Page",
				-href => "javascript: document.forms[0].page_action.value='PrevPage_$control_name'; document.forms[0].submit();",
				}, 
				'<'
			)." "
			if $currentPage > 1;
		$pagingText .= sprintf( "%u of %u ", $currentPage, $numPages);
		$pagingText .= "\n".$q->a( {
				-title => "Next Page",
				-href  => "javascript: document.forms[0].page_action.value='NextPage_$control_name'; document.forms[0].submit();",
				}, 
				'>'
			)." "
			if $currentPage < $numPages;
		$pagingText .= "\n".$q->a( {
				-title => "Last Page",
				-href  => "javascript: document.forms[0].page_action.value='LastPage_$control_name'; document.forms[0].submit();",
				}, 
				'>>'
			)
			if( $currentPage < $numPages and $numPages > 2 );
	}

	return ( $offset, $pagingText );
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
	_name: will be populated with whatever is returned by getName( $object, $options )
		allows a maximum length to be specified a la: _name!MaxLength:23
	_common_name: the commonly used name of this object type
	_ref: a reference to the object

Other behaviors:
	name and id fields will be rendered as links in html summary view
	To render a has many accessor (i.e. Dataset's images() method), the syntax is:
		ACCESSOR!MODE (i.e. images!popup or images!tiled_list)

=cut

sub renderData {
	my ($self, $obj, $field_requests, $format, $mode, $options) = @_;
	my ( %record, $specializedRenderer );
	$options = {} unless $options; # makes things easier
	
	# handle plural calling style
	if( ref( $obj ) eq 'ARRAY' ) {
		my @records;
		push( @records, { $self->renderData( $_, $field_requests, $format, $mode, $options) } )
			foreach @$obj;
		return @records;
	}
	
	# specialized rendering
	$specializedRenderer = $self->_getSpecializedRenderer( $obj );
	%record = $specializedRenderer->_renderData( $obj, $field_requests, $format, $mode, $options )
		if $specializedRenderer and $specializedRenderer->can('_renderData');

	# set mode-based behavior
	if( $mode eq 'summary' ) {
		$options->{ max_text_length } = 71 unless exists $options->{ max_text_length };
	}

	# default rendering
	my $q = $self->CGI();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $id   = $obj->id();
	foreach my $request ( @$field_requests ) {
		# don't override specialized renderings
		next if exists $record{ $request };
		
		# _id = plain text id
		if( $request eq '_id' ) {
			$record{ $request } = $obj->id();
		
		# _common_name = object's commone name
		} elsif( $request eq '_common_name' ) {
			$record{ $request } = $common_name;
		
		# _name = object name
		} elsif( $request =~ m/^_name(!MaxLength\:)?(\d+)?$/ ) {
			my %options;
			%options = %$options if $options;
			$options{ max_text_length } = $2 if $2;
			$record{ $request } = $self->getName( $obj, \%options );

		# _ref = reference to object
		} elsif( $request eq '_ref' ) {
			$record{ $request } = $self->getRef( $obj, $format, $options );
					
		# _checkbox = Checkbox w/ LSID
		} elsif( $request eq '_checkbox' ) {
			$record{ $request } = $q->checkbox( 
				-name => "selected_objects",
				-value => $self->_getLSIDmanager()->getLSID( $obj ),
				-label => '',
			)
				if( $options->{ draw_checkboxes } );
					
		# populate mode render requests
		} elsif( $request =~ m/^!(.+)$/ ) {
			my $render_mode = $1;
			$record{ $request } = $self->render( $obj, $render_mode, $options );
		
		# make name and id into links for html summary views
		} elsif( ( $request eq 'id' || $request eq 'name' ) &&
		         ( $format eq 'html' && $mode eq 'summary' ) ) {
			$record{ $request } = $q->a( 
				{ 
					href  => "serve.pl?Page=OME::Web::DBObjDetail&Type=$formal_name&ID=$id",
					title => "Detailed info about this $common_name",
					class => 'ome_detail'
				},
				$obj->$request
			);
		
		# populate field requests
		} else {
			# field!command
			my ($field, $command) = split( /!/, $request );
			my $type = $obj->getColumnType( $field );
			
			# data fields
			if( $type eq 'normal' ) {
				my $SQLtype = $obj->getColumnSQLType( $field );
				$record{ $request } = $obj->$field;
				my %booleanConvert = ( 0 => 'False', 1 => 'True' );
				$record{ $request } =~ s/^([^:]+(:\d+){2}).*$/$1/
					if $SQLtype eq 'timestamp';
				$record{ $request } = $booleanConvert{ $record{ $request } }
					if $SQLtype eq 'boolean';
				$record{ $request } = $self->_trim( $record{ $request }, $options )
					if( $SQLtype =~ m/^varchar|text/ ); 
			}
			
			# reference field
			if( $type eq 'has-one' ) {
				# ref if no field specified in command
				my $render_mode = ( $command || 'ref' );
				$record{ $request } = $self->render( $obj->$field(), $render_mode, $options );
			}

			# *many reference accessor
			if( $type eq "has-many" || $type eq 'many-to-many' ) {
				# ref_list if no field specified in command
				my $render_mode = ( $command || 'ref_list' );
				$record{ $request } = $self->renderArray( 
					[$obj, $field], 
					$render_mode, 
					{ _more_info_url => $self->getSearchAccessorURL( $obj, $field ),
					  type => $obj->getAccessorReferenceType( $field )->getFormalName()
					}
				);
			}
		}
	}
	
	return %record;
}

=head2 getFields

	my @fields = OME::Web::DBObjRender->getFields( $type, $mode );

$type can be a DBObject name ("OME::Image"), an Attribute name ("@Pixels"), or an instance
of either
$mode may be 'summary' or 'all'.

Returns an ordered list of field names for the specified object type and mode.

This list will be constructed in one of three ways. 

	First, it will try to load a specialized renderer and look for hash
	data '_summaryFields' or '_allFields' ( depending on the mode ).

	If that fails, it will try loading a custom template (specific to
	the type and mode), and return fields from $type that appear in
	that template.

	If no custom template is found, it will return every published field
	in the type. See OME::DBObject->getPublishedCols()

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

	# default: return all fields (insensitive to mode)
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	my @cols = $package_name->getPublishedCols();
	
	# last chance: filter fields by specialized templates
	# try to find a template specific to this type & mode
	my $tmpl_path = $self->_findTemplate( $type, $mode );
	if( $tmpl_path ) {
		my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
		# only keep columns that exist in the template
		@cols = grep( $tmpl->query( name => $_ ), @cols );
	}
	
	# We don't need no target
	return ( 'id', sort( grep( $_ ne 'target', @cols) ) );
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
	return $specializedRenderer->_getFieldTitles( $type, $field_names, $format )
		if( $specializedRenderer and $specializedRenderer->can( '_getFieldTitles') );
	
	$format = 'txt' unless $format;

	# make titles by prettifying the aliases. Add links to Semantic
	# Element documentation as available.
	my %titles;
	my $q = $self->CGI();
	my $factory = OME::Web->Session()->Factory();
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	
	# _fieldTitles allows specialized renderers to overide titles
	my $pkg_titles = $specializedRenderer->{ _fieldTitles } if $specializedRenderer;
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

	my $relations = OME::Web::DBObjRender->getRelations( $type );

$type is an instance of a DBObject or an Attribute.
$relations is an array reference. It is formatted like so:
	[ $title, $method, $relation_type ]

This method returns a description of an object's has many relations.

=cut

sub getRelations {
	my ($self, $obj) = @_;

	my $specializedRenderer = $self->_getSpecializedRenderer( $obj );
	return $specializedRenderer->_getRelations( $obj )
		if( $specializedRenderer and $specializedRenderer->can('_getRelations') );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $obj );
	my ( @relations, @names );
	my $relation_accessors = $obj->getPublishedManyRefs();
	foreach my $method ( sort( keys %$relation_accessors ) ) {
		(my $title = $method) =~ s/_/ /g;
		$title = ucfirst( $title );
		push( @relations, [
			$title,
			$method,
			$relation_accessors->{ $method },
		] );
	}
	
	return \@relations;
}

=head2 getSearchFields

	# get html form elements keyed by field names 
	my ($form_fields, $search_paths) = OME::Web::DBObjRender->getSearchFields( $type, \@field_names, \%default_search_values );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
@field_names is used to populate the returned hash.
%default_search_values is also optional. If given, it is used to populate the search form fields.

$form_fields is a hash reference of html form inputs { field_name => form_input, ... }
$search_paths is also a hash reference keyed by field names. It's values
are search paths. In most cases the search path will be the same as
the field name. For reference fields, the path will specify a field in the referent. 
For example, a reference field named 'dataset' would have a search path 'dataset.name'

=cut

sub getSearchFields {
	my ($self, $type, $field_names, $defaults) = @_;
	my ($form_fields, $search_paths);
	
	my $specializedRenderer = $self->_getSpecializedRenderer( $type );
	($form_fields, $search_paths) = $specializedRenderer->_getSearchFields( $type, $field_names, $defaults )
		if( $specializedRenderer and $specializedRenderer->can('_getSearchFields') );

	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );

	my $q = $self->CGI();
	my %fieldRefs = map{ $_ => $package_name->getAccessorReferenceType( $_ ) } @$field_names;
	foreach my $field ( @$field_names ) {
		next if exists $form_fields->{ $field };
		if( $fieldRefs{ $field } ) {
			( $form_fields->{ $field }, $search_paths->{ $field } ) = 
				$self->getRefSearchField( $formal_name, $fieldRefs{ $field }, $field, $defaults->{ $field } );
		} else {
			$q->param( $field, $defaults->{ $field }  ) 
				unless defined $q->param( $field );
			$form_fields->{ $field } = $q->textfield( 
				-name    => $field , 
				-size    => 17, 
				-default => $defaults->{ $field } 
			);
			$search_paths->{ $field } = $field;
		}
	}

	return ( $form_fields, $search_paths );
}

=head2 getRefSearchField

	# get an html form element that will allow searches to $to_type
	my ( $searchField, $search_path ) = OME::Web::DBObjRender->getRefSearchField( $from_type, $to_type, $accessor_to_type );

the types may be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$from_type is the type you are searching from
$accessor_to_type is an accessor of $from_type that returns an instance of $to_type
$to_type is the type the accessor returns

returns a form input and a search path for that input. The search path
for a module_execution's module field is module.name

=cut

sub getRefSearchField {
	my ($self, $from_type, $to_type, $accessor_to_type, $default) = @_;
	
	my $specializedRenderer = $self->_getSpecializedRenderer( $to_type );
	return $specializedRenderer->_getRefSearchField( $from_type, $to_type, $accessor_to_type, $default )
		if( $specializedRenderer and $specializedRenderer->can('_getRefSearchField') );

	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );
	my ($to_package) = OME::Web->_loadTypeAndGetInfo( $to_type );
	my $searchOn = '';
	$searchOn = '.name' if( $to_package->getColumnType( 'name' ) );
	$searchOn = '.Name' if( $to_package->getColumnType( 'Name' ) );

	my $q = $self->CGI();
	$q->param( $accessor_to_type.$searchOn, $default  ) 
		unless defined $q->param($accessor_to_type.$searchOn );
	return ( 
		$q->textfield( -name => $accessor_to_type.$searchOn , -size => 17 ),
		$accessor_to_type.$searchOn
	);
}


=head1 Internal Methods

These methods should not be accessed from outside the class

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

	return $self if( ref( $self ) eq $specializedPackage );
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
		defined $options->{ max_text_length } and
		defined $str and 
		( length( $str ) > $options->{ max_text_length } )
	);
	return substr( $str, 0, $options->{ max_text_length } - 3 ).'...';
}

=head2 _findTemplate

	my $template_path = $self->_findTemplate( $obj, $mode );

returns a path to a custom template (see HTML::Template) for this $obj
and $mode - OR - undef if no matching template can be found

=cut

sub _findTemplate {
	my ( $self, $obj, $mode ) = @_;
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $tmpl_path = $formal_name; 
	$tmpl_path =~ s/@//g; 
	$tmpl_path =~ s/::/_/g; 
	$tmpl_path .= "_".$mode.".tmpl";
	$tmpl_path = $tmpl_dir.'/'.$tmpl_path;
	return $tmpl_path if -e $tmpl_path;
	return undef;
}

=head2 _findTemplate

	my $lsidManager = $self->_getLSIDmanager();

returns an lsid manager from cache or makes a new one and puts it in cache.

=cut

sub _getLSIDmanager {
	my $self=shift;
	return $self->{ _LSIDmanager } if $self->{ _LSIDmanager };
	$self->{ _LSIDmanager } = new OME::Tasks::LSIDManager ();
	return $self->{ _LSIDmanager };
}

=head1 Specialized Rendering

There are two mechanisms for adding specialized rendering. Those are
subclasses and templates. 
Templates are used for specifing what parts of an object get displayed
and how to display them.
Subclasses are used to implement necessary logic for display.

=head2 Naming

The naming convention for templates is:
	for an 'OME::Image' DBObject and 'summary' mode, OME_Image_summary.tmpl
	for a 'Pixels' Attribute in 'detail' mode, Pixels_detail.tmpl

The naming convention for subclasses is:
	OME::Image's rendering class is OME::Web::DBObjRender::__OME_Image
	@Pixels' renderering class is OME::Web::DBObjRender::__Pixels

=head1 Writing Templates

Basically, you write chunks of html peppered with tags that look like
	<!-- TMPL_VAR NAME='field_name' -->
that get replaced with the field in question. Look at
OME_Image_detail.tmpl and OME_Image_summary.tmpl for simple examples.
See OME_Image_ref_mass.tmpl, generic_list.tmpl, or
generic_tiled_list.tmpl for examples of rendering lists of objects.

field_name can be any of the object's fields from its DBObject
definition, a field populated by the _renderData method of the
specialized subclass, or a magic field.

Magic fields for individual objects
	_id: will be populated solely with the id, regardless of format or mode
	_name: returns a name for the object, even if there isn't a name field.
		currently populated with whatever is returned by getName( $object, $options )
		allows a maximum length to be specified a la: _name!MaxLength:23
	_common_name: the commonly used name of this object type
	_ref: a reference to the object
	_checkbox: a form checkbox named 'selected_objects' and valued with the objects' LSID
	!mode: render the object in the mode given. evaluates to a render() call.
	has_many_ref!mode: render the objects given by has_many_ref in the specified mode.
		evaluates to a renderArray() call.

Magic fields for lists of objects (templates picked up by renderArray().)
	_more_info_url: shows a url to more detailed version of the list
	_pager_text: text to control paging after a big list of objevts is
		split into several pages of display
	_formal_name: formal name of the object type (i.e. OME::Image, @Pixels)
	_common_name: common name of the object type (i.e. Image, Pixels)
	_tile_loop: used to make a multi column table with one object rendered per cell. see generic_tiled_list.tmpl
	_obj_loop: used to loop across objects.

Either of the loop Magic fields can contain specific fields or render mode requests.

See also HTML::Template at http://html-template.sourceforge.net

=head1 Subclass Methods 

Subclasses should implement one or more of these

=head2 _getName

	my $object_name = $specializedRenderer->_getName( $object, $options );

Overrides getName()

Subclasses are expected to implement $options->{ 'max_text_length' }.
Names returned should not be longer than that value.

=head2 _getRef

	my $object_ref = $specializedRenderer->_getRef( $object, $options );

Overrides getName()

Subclasses are expected to implement $options->{ 'max_text_length' }.
Names returned should not be longer than that value.

=head2 _renderData

	%partial_record = $specializedRenderer->_renderData( $obj, $format, \@field_names, \%options );

Implement this to do custom rendering of certain fields or to implement
fields not implemented in DBObject. Examples of this are:
	Experimenter's email turned to active link if format is html
	Image having an 'Original File' field.

Subclasses need only populate fields they are overriding.

=head2 _getSearchFields

	%partial_search_fields = 
		$specializedRenderer->_getSearchFields( $type, $field_names, $defaults );

Implement this to do custom rendering of search fields. Subclasses need
only populate fields they are overriding.

=head2 _getRefSearchField

	my ( $form_input, $search_path ) = $specializedRenderer->_getRefSearchField( 
		$from_type, $to_type, $accessor_to_type, $default )
	
	overrides getRefSearchField()

=head1 Roadmap/2do list

=over 4

=item *

Depricate getRef($obj) in favor of render( $obj, 'ref' ). Implement a
_ref magic field in renderData() that does the same thing. Subclasses
would override self references with _renderData() instead of _getRef()

=item *

move the guts of getName() into renderData(). Force subclasses to
implement that in _renderData(). This simplifies the structure of
subclasses even more. Retain getName( $obj, $options ) as a conveint
shortcut to renderData( $obj, 'txt', [ '_name' ], $options )

=item *

Support !MaxLength for all field requests in renderData()

=item *

Implement context dependent rendering of types. i.e. module executions under image a la:

	<TMPL_LOOP NAME='module_executions'>
		<TMPL_VAR NAME='_name!Ref'>
	</TMPL_LOOP>

Requires changes to render to detect when variables are loops and deal with them appropriately.
Alternately, use <TMPL_VAR NAME='module_executions!name_ref_list'> and make another template.

=item *

Make a table mode for renderArray(). Code will needed to be added. This
would allow simple tables to be phased out of DBObjTable. DBObjTable is
fairly complicated and was designed against an earlier version of
DBObjRender. I get nervous about people using it. I guess as long as it
works, there's no need to switch. I just don't want to expend effort to
support or develop another rendering model.

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
