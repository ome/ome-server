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
	What are the html form fields to use on search pages?
	What is a name for this object?
In addition to providing rendering, I set this class up to handle 
object services specific to the web interface that need to be
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

For a simple and complete example of rendering activity, check out: 
src/html/Templates/OME_Image_detail.tmpl,
OME::Web::DBObjRender::__OME_Image, and
OME::Web::DBObjDetail::__OME_Image
Also, check out how dataset asks for it's images in
src/html/Templates/OME_Dataset_detail.tmpl

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

my $VALIDATION_INCS = <<END;
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.config.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.core.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.numbers.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.special.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.lang-enUS.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.validators.js"></script>
END

# set up class constants
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ page_limits } = {
		list  => 10,
		popup => 0,
		ref_list => 10,
		ref_mass => 100,
		tiled_list => 24,
		tiled_ref_list => 24,
	};
	
	return $self;
}

=head2 getName

	my $object_name = OME::Web::DBObjRender->getName( $object, \%options );

Gets a name for this object. Subclasses may override this by implementing a _getName method.

Convenient shortcut to get renderData() to render '/name' with %options.
the most common option is max_text_length => 25

See Also renderData()

=cut

sub getName {
	my ($self, $obj, $options) = @_;
	
	$options->{ 'request_string' } = '/name';
	my %record = $self->renderData( $obj, { '/name' => [$options] } );
	return $record{ '/name' };
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

	return '' unless $obj;

	# load a template
	my $tmpl_path = $self->_findTemplate( $obj, $mode );
	$tmpl_path = $self->Session()->Configuration()->template_dir().'/generic_'.$mode.'.tmpl'
		unless $tmpl_path;
	die "Could not find a specialized or generic template to match Object $obj with mode $mode"
		unless -e $tmpl_path;
	$tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );

	# get data for it	
	%tmpl_data = $self->_populate_object_in_template( $obj, $tmpl, undef, $options );

	# populate template
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

# this function collects data for an object in a template
# it's separate from render to allow data collection for a portion of a template
# that functionality isn't implemented yet. The separation of this functionality is
# meant to be a first step towards that.
sub _populate_object_in_template {
	my ($self, $obj, $tmpl, $tmpl_loc, $options) = @_;
	
	my %tmpl_data;

	# load template variable requests
	my @fields;
	if( $tmpl_loc ) {
		@fields = grep( !m'^/datum$|^/relations$', $tmpl->query( loop => $tmpl_loc ) );
	} else {
		@fields = grep( !m'^/datum$|^/relations$', $tmpl->param() );
	}
	%tmpl_data = $self->renderData( $obj, \@fields, $options ) if( scalar @fields > 0 );

	# /datum = iterate over the object's fields
	my $datum_loc = [ ( $tmpl_loc ? @$tmpl_loc : () ), '/datum' ];
	if( $tmpl->query( name => $datum_loc ) ) {
		# load object data
		my @datums;
		my @fields = $self->getFields( $obj );
		my %data = $self->renderData( $obj, \@fields, $options );
		push( @datums, { 
			# Add name only if requested
			( $tmpl->query( name => ['/datum', 'name' ] ) ? ( name => $_ ) : () ), 
			# Add value only if requested
			( $tmpl->query( name => ['/datum', 'value' ] ) ? ( value => $data{ $_ } ) : () ), 
		} ) foreach @fields;
		$tmpl_data{ '/datum' } = \@datums;
	}

	# /relations = iterate over the object's relations
	my $relations_loc = [ ( $tmpl_loc ? @$tmpl_loc : () ), '/relations' ];
	if( $tmpl->query( name => $relations_loc ) ) {
		my $relations = $self->getRelations( $obj );
		my @tmpl_fields = $tmpl->query( loop => '/relations' );
		my @a = grep( m/^\/object_list/, @tmpl_fields); 
		my $object_list_request = $a[0];
		$object_list_request =~ m/render-([^\/]+)/;
		my $render_mode = $1;
		my @relations_data;
		foreach my $relation( @$relations ) {
			my( $title, $method, $relation_type ) = @$relation;

			push( @relations_data, { 
				name => $title, 
				$object_list_request => $self->renderArray( 
					[ $obj, $method ], 
					$render_mode, 
					{ more_info_url => $self->getSearchAccessorURL( $obj, $method ),
					  type => $obj->getAccessorReferenceType( $method )->getFormalName()
					}
				)
			} );
		}
		$tmpl_data{ '/relations' } = \@relations_data;
	}

	return %tmpl_data;
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
	more_info_url is a URL to a search page of these objects.



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
			$options->{pager_text} = $pager_text;
		
		# get objs w/o paging
		} else {
			@relation_objects = $obj->$method();
		}
		$objs = \@relation_objects
	}
	
	# try to load custom template
	my $tmpl_path = $self->_findTemplate( $options->{type}, $mode );
	# use generic if there is no custom
	$tmpl_path = $self->Session()->Configuration()->template_dir().'/generic_'.$mode.'.tmpl'
		unless $tmpl_path;
	my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
	my %tmpl_data;

	# put together data for template
	if( $objs && scalar( @$objs ) > 0 ) {
		my ($package_name, $common_name, $formal_name, $ST) =
			$self->_loadTypeAndGetInfo( $objs->[0] );
		
		# populate magic fields
		if( $tmpl->query( name => '/more_info_url' ) ) {
			$tmpl_data{ '/more_info_url' } = $options->{ more_info_url };
		}
		if( $tmpl->query( name => '/pager_text' ) ) {
			$tmpl_data{ '/pager_text' } = $options->{ pager_text };
		}
		if( $tmpl->query( name => '/formal_name' ) ) {
			$tmpl_data{ '/formal_name' } = $formal_name;
		}
		if( $tmpl->query( name => '/common_name' ) ) {
			$tmpl_data{ '/common_name' } = $common_name;
		}
	
		# populate loops that tile objects
		my @tmp_array = grep( m/^\/tile_loop/, $tmpl->param() );
		my $tile_loop_command = ( scalar ( @tmp_array ) ? $tmp_array[0] : undef );
		if( $tile_loop_command ) {
			# figure out how many tiles per loop
			$tile_loop_command =~ m/^\/tile_loop\/width-(\d+)/;
			my $n_tiles = $1;
			# find out about the object loop.
			my @obj_fields = $tmpl->query( loop => [$tile_loop_command, '/obj_loop'] );
			my @tile_data;
			while( @$objs ) {
				# grab the next bunch of objects
				my @objs2tile = splice( @$objs, 0, $n_tiles );
				# render their data
				my @objs_data = $self->renderData( \@objs2tile, \@obj_fields, $options );
				# pad the data block to match the other rows. Now we have a 'tile'
				if( scalar( @tile_data ) ) {
					push( @objs_data, {} ) for( 1..( $n_tiles - scalar( @objs2tile ) ) );
				}
				# push the 'tile' on the stack of tiles
				push( @tile_data, { '/obj_loop' => \@objs_data } );
			}
			$tmpl_data{ $tile_loop_command } = \@tile_data;
		}
		
		# populate loops around objects
		if( $tmpl->query( name => '/obj_loop' ) ) {
			# populate the fields inside the loop
			my @obj_fields = $tmpl->query( loop => '/obj_loop' );
			$tmpl_data{ '/obj_loop' } = [ $self->renderData( \@$objs, \@obj_fields, $options ) ];
					
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
		$pagingText = "<input type='hidden' name='page_action'>";
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
	my @records = OME::Web::DBObjRender->renderData( \@objects, \@field_requests, $options );
	# singular
	my %record = OME::Web::DBObjRender->renderData( $object, \@field_requests, $options );

@objects is an array of instances of a DBObject or a Semantic Type.
$field_requests is used to populate the returned hash.

When called in plural context, returns an array of hashes.
When called in singular context, returns a single hash.
The hashes will be of the form { field_request => rendered_field, ... }

Magic field names:
	/name: will be populated by whichever field is found: 'name', 'Name', or 'id'
	/common_name: the commonly used name of this object type

=cut

sub renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my ( %record, $specializedRenderer );
	$options = {} unless $options; # makes things easier
	$field_requests = $self->_parse_tmpl_fields( $field_requests );

	# handle plural calling style
	if( ref( $obj ) eq 'ARRAY' ) {
		my @records;
		push( @records, { $self->renderData( $_, $field_requests, $options) } )
			foreach @$obj;
		return @records;
	}
	
	# specialized rendering
	$specializedRenderer = $self->_getSpecializedRenderer( $obj );
	%record = $specializedRenderer->_renderData( $obj, $field_requests, $options )
		if $specializedRenderer and $specializedRenderer->can('_renderData');

	# default rendering
	my $q = $self->CGI();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	foreach my $field ( keys %$field_requests ) {
		foreach my $request ( @{ $field_requests->{ $field } } ) {
			my $request_string = $request->{ 'request_string' };
			
			# don't override specialized renderings
			next if exists $record{ $request_string };
					
			# /common_name = object's commone name
			if( $field eq '/common_name' ) {
				$record{ $request_string } = $common_name;
			
			# /name = object name
			} elsif( $field eq '/name' ) {
				my $name;
				$name = $obj->name() if( $obj->getColumnType( 'name' ) );
				$name = $obj->Name() if( $obj->getColumnType( 'Name' ) );
				$name = $obj->id() unless $name;
				$name = $self->_trim( $name, $request );
				$record{ $request_string } = $name;
	
			# /object = render the object itself. default render mode is ref
			} elsif( $field eq '/object' ) {
				my $render_mode = ( $request->{ render } or 'ref' );
				$record{ $request_string } = $self->render( $obj, $render_mode, $options );
						
			# /LSID = Object's LSID
			} elsif( $field eq '/LSID' ) {
				$record{ $request_string } = $self->_getLSIDmanager()->getLSID( $obj );

			# /checkbox = Checkbox w/ LSID
			} elsif( $field eq '/selector' ) {
				my $lsid = $self->_getLSIDmanager()->getLSID( $obj );
				$record{ $request_string } = $q->checkbox( 
					-name => "selected_objects",
					-value => $lsid,
					-label => '',
				) if( $options->{ draw_checkboxes } );
				$record{ $request_string } = $q->radio_group( 
					-name => "selected_objects",
					-values => [$lsid],
					-labels => { $lsid => '' },
				) if( $options->{ draw_radiobuttons } );
						
			# /obj_detail_url = url to detailed description of object
			} elsif( $field eq '/obj_detail_url' ) {
				$record{ $request_string } = $self->getObjDetailURL( $obj );
					
			# populate field requests
			} else {
				my $type = $obj->getColumnType( $field );
				next unless $type;
				
				# data fields
				if( $type eq 'normal' ) {
					my $SQLtype = $obj->getColumnSQLType( $field );
					$record{ $request_string } = $obj->$field;
					my %booleanConvert = ( 0 => 'False', 1 => 'True' );
					$record{ $request_string } =~ s/^([^:]+(:\d+){2}).*$/$1/
						if $SQLtype eq 'timestamp';
					$record{ $request_string } = $booleanConvert{ $record{ $request_string } }
						if $SQLtype eq 'boolean';
					$record{ $request_string } = $self->_trim( $record{ $request_string }, $request )
						if( $SQLtype =~ m/^varchar|text/ ); 
				}
				
				# reference field
				if( $type eq 'has-one' ) {
					my $render_mode = ( $request->{ render } or 'ref' );
					$record{ $request_string } = $self->render( $obj->$field(), $render_mode, $request );
				}
	
				# *many reference accessor
				if( $type eq "has-many" || $type eq 'many-to-many' ) {
					# ref_list if no field specified in command
					my $render_mode = ( $request->{ render } or 'ref_list' );
					$record{ $request_string } = $self->renderArray( 
						[$obj, $field], 
						$render_mode, 
						{ more_info_url => $self->getSearchAccessorURL( $obj, $field ),
						  type => $obj->getAccessorReferenceType( $field )->getFormalName()
						}
					);
				}
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

	# default: return all fields (insensitive to mode)
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	my @cols = $package_name->getPublishedCols();
	
	# alternately: filter fields by specialized templates
	# try to find a template specific to this type & mode
	if( $mode ) {
		my $tmpl_path = $self->_findTemplate( $type, $mode );
		if( $tmpl_path ) {
			my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
			# only keep columns that exist in the template
			my $field_requests = $self->_parse_tmpl_fields( [ $tmpl->param() ] );
			@cols = grep( exists $field_requests->{ $_ }, @cols );
		}
	}
	
	# We don't need no target
	return ( sort( grep( $_ ne 'target', @cols) ) );
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


# field syntax is: "field/option-value/option-value..."
# magic fields are distinguished from object fields the prefix '/' (i.e. "/magic_field")

# parse field requests into fields & options. store in hash formatted like so:
#	$parsed_field_requests{ $field_named_foo } = \@requests_for_field_named_foo
#	\@requests_for_field_named_foo is a bunch of hashes formated like so:
#	$request{ $option_name } = $option_value;
# also, the orgininal request is stored in:  $request{ 'request_string' }
sub _parse_tmpl_fields {
	my ( $self, $field_requests ) = @_;

	if( ref( $field_requests ) eq 'ARRAY' ) {
		my %parsed_field_requests;
		foreach my $request ( @$field_requests ) {
			my $field;
			my %parsed_request;
			my @items = split( m'/', $request );
			# the first item will be blank for magic fields because magic fields
			# are prefixed with the delimeter
			if( $items[0] eq '' ) {
				shift( @items );
				$field = '/'.shift( @items );
			} else {
				$field = shift( @items );
			}
			foreach my $option ( @items ) {
				my ($name,$val) = split( m/-/, $option );
				$parsed_request{ $name } = $val;
			}
			$parsed_request{ 'request_string' } = $request;
			push( @{ $parsed_field_requests{ $field } }, \%parsed_request );
		}
		$field_requests = \%parsed_field_requests;
	}
	
	return $field_requests;
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
	return undef unless $obj;
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

=head2 _getLSIDmanager

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

Modifiers:
	field/max_text_length-n : truncates the field length to max_text_length
	reference_field/render-mode: render the objects given by has_many_ref in the specified mode.
		evaluates to a renderArray() call.
	has_many_ref/render-mode: render the objects given by has_many_ref in the specified mode.
		evaluates to a renderArray() call.


Magic fields for individual objects
	/name: returns a name for the object, even if there isn't a name field.
		currently populated with whatever is returned by getName( $object, $options )
		allows a maximum length to be specified a la: _name!MaxLength:23
	/common_name: the commonly used name of this object type
	/obj_detail_url: a url to a detailed description of the given object
	/selector: a form checkbox (or radio button) named 'selected_objects' and valued with the objects' LSID
		Will be a checkbox if $options->{ draw_checkboxes }, 
		a radio button if  $options->{ draw_radiobuttons },
		and blank if neither option is specified.
	/LSID: the object's LSID
	/object/render-mode: render the current object in the mode given. evaluates to a render() call.

Magic fields for lists of objects (templates picked up by renderArray().)
	/more_info_url: shows a url to more detailed version of the list
	/pager_text: text to control paging after a big list of objects is
		split into several pages of display
	/obj_detail_url: URL to a detailed description of teh object
	/formal_name: formal name of the object type (i.e. OME::Image, @Pixels)
	/common_name: common name of the object type (i.e. Image, Pixels)
	/tile_loop/width-n: used to make a multi column table with one object rendered per cell. see generic_tiled_list.tmpl
	/obj_loop: used to loop across objects.

Either of the loop Magic fields can contain specific fields or render mode requests.

See also HTML::Template at http://html-template.sourceforge.net

=head1 Subclass Methods 

Subclasses should implement one or more of these

=head2 _renderData

	%record = $specializedRenderer->_renderData( $obj, \%field_requests, \%options );

Implement this to do custom rendering of certain fields or to implement
fields not implemented in DBObject. Examples of this are:
	OME::Web::DBObjRender::__OME_Image.pm implementing 'original_file' and 'thumb_url' fields for Images.
	OME::Web::DBObjRender::__OME_ModuleExecution.pm implementing a '/name' field.
Also see:
	OME/src/html/Templates/OME_Image_ref.tmpl
	OME/src/html/Templates/OME_ModuleExecution_ref.tmpl

%field_requests is formated like so:
	$field_requests{ $field_named_foo } = \@requests_for_field_named_foo
\@requests_for_field_named_foo is a bunch of hashes formated like so:
	$request{ $option_name } = $option_value;
additionally, the orgininal request is stored in:  $request{ 'request_string' }
the record returned needs to be keyed by the original request.

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

Provide functionality to populate arbitrary template variables from option values.
Something like:
<TMPL_VAR NAME="/option_var/name-more_info_url">

=item *

Implement context dependent rendering of types. i.e. module executions under image a la:

	<TMPL_LOOP NAME='module_executions'>
		<a href="<TMPL_VAR NAME='/obj_detail_url'>"><TMPL_VAR NAME='/name'></a>
	</TMPL_LOOP>

Requires changes to render to detect when variables are loops and deal with them appropriately.
Another way to achieve this functionality is use 
	<TMPL_VAR NAME='module_executions/render-MEX_ref_list_name_only'>
and make another template.

=item *

Make a generic table mode for renderArray(). Code will needed to be added. This
would allow simple tables to be phased out of DBObjTable. DBObjTable is
fairly complicated and was designed against an earlier version of
DBObjRender. I get nervous about people using it. I guess as long as it
works, there's no need to switch. I just don't want to expend effort to
support or develop that old rendering model.

=back

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
