# OME/Web/Search.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::Search;

=pod

=head1 NAME

OME::Web::Search

=head1 DESCRIPTION

Allow searches and selects for any DBObject or attribute.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use Log::Agent;
use Carp;
use HTML::Template;

use base qw(OME::Web);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	# _default_limit sets the number of results per page
	$self->{ _default_limit } = 27;
	
	# _display_modes lists formats the results can be displayed in. 
	#	mode maps to a template name. 
	#	mode_title is presented to the user.
	$self->{ _display_modes } = [
		{ mode => 'tiled_list', mode_title => 'Summaries' },
		{ mode => 'tiled_ref_list', mode_title => 'Names' },
	];
		
	return $self;
}

# These routines allow filtering of search types.
sub __get_search_types {
	return (
		'OME::Project', 
		'OME::Dataset', 
		'OME::Image', 
		'OME::ModuleExecution', 
		'OME::Module', 
		'OME::AnalysisChain', 
		'OME::AnalysisChainExecution',
		'OME::SemanticType'
	);
}

sub getMenuText {
	my $self = shift;
	my $menuText = "Other";
	return $menuText unless ref($self);

	my $q    = $self->CGI();
	my $type = $q->param( 'Type' );
	$type = $q->param( 'Locked_Type' ) unless $type;
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
		return "$common_name";
    }
	return $menuText;
}

sub getPageTitle {
	my $self = shift;
	my $menuText = "Search for something";
	return $menuText unless ref($self);
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' );
	$type = $q->param( 'Locked_Type' ) unless $type;
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    	return "Search for $common_name";
    }
	return $menuText;
}

sub getPageBody {
	my $self = shift;	
	my $factory = $self->Session()->Factory();
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' ) || $q->param( 'Locked_Type' );
	my $html = $q->startform( -action => $self->pageURL( 'OME::Web::Search' ) );
	# Save the url-parameters if any were passed. The line above will strip them
	# at the first submit.
	my %do_not_save_these_url_params = (
		'Page' => undef,
		'Type' => undef
	);
	my @params_to_save = grep( ( not exists $do_not_save_these_url_params{ $_ } ), 
		$q->url_param() );
	@params_to_save = $q->param( '__save_these_params' ) 
		unless @params_to_save;
	if( @params_to_save ) {
		$html .= $q->hidden( -name => '__save_these_params', -values => \@params_to_save );
		$html .= $q->hidden( -name => $_, -default => $q->param( $_ ) )
			foreach ( @params_to_save );
	}
	my %tmpl_data;

	# Return results of a select
	if( $q->param( 'do_select' ) ) {
		
		my @selection    = $q->param( 'selected_objects' );
		# weed out blank selections
		@selection = grep( $_ && $_ ne '', @selection );
		# and duplicate selections
		my %unique_selection;
		$unique_selection{ $_ } = undef foreach @selection;
		@selection = keys %unique_selection;
		# convert LSIDs into objs.
		my $resolver = new OME::Tasks::LSIDManager();
		@selection = map( $resolver->getObject($_), @selection );

		# close this window after action is complete if it's a popup
		my $return_to = ( $q->url_param( 'return_to' ) || $q->param( 'return_to' ) );
		my $ids = join( ',', map( $_->id, @selection ) );
		$html = <<END_HTML;
			<script language="Javascript" type="text/javascript">
				window.opener.document.forms[0].${return_to}.value = '$ids';
				window.opener.document.forms[0].submit();
				window.close();
			</script>
END_HTML
		return( 'HTML', $html );
	}

	# Drop down list of search types
	my @search_types = $self->__get_search_types();	
	# if the type requested isn't in the list of searchable types, add it. 
	# This stores the type, which is required for paging to work.
	unshift( @search_types, $type )
		unless(
			( not defined $type ) || 
			( $type =~ m/^@/ ) ||
			( grep( $_ eq $type, @search_types ) )
		);
	my %search_type_labels;
	foreach my $formal_name ( @search_types ) {
		my ($package_name, $common_name, undef, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
		$search_type_labels{ $formal_name } = $common_name;
	}
	my @globalSTs = $factory->findObjects( 'OME::SemanticType', 
		granularity => 'G',
		__order     => 'name'
	);
	my @datasetSTs = $factory->findObjects( 'OME::SemanticType', 
		granularity => 'D',
		__order     => 'name'
	);
	my @imageSTs = $factory->findObjects( 'OME::SemanticType', 
		granularity => 'I',
		__order     => 'name'
	);
	my @featureSTs = $factory->findObjects( 'OME::SemanticType', 
		granularity => 'F',
		__order     => 'name'
	);
	
	$tmpl_data{ search_types } = $q->popup_menu(
		-name     => 'Type',
		'-values' => [ 
			'', 
			@search_types, 
			'G', 
			map( '@'.$_->name(), @globalSTs),
			'D',
			map( '@'.$_->name(), @datasetSTs),
			'I',
			map( '@'.$_->name(), @imageSTs),
			'F',
			map( '@'.$_->name(), @featureSTs),
		],
		-default  => ( $type ? $type : '' ),
		-override => 1,
		-labels   => { 
			''  => '-- Select a Search Type --', 
			%search_type_labels,
			'G' => '-- Global Semantic Types --', 
			(map{ '@'.$_->name() => $_->name() } @globalSTs ),
			'D' => '-- Dataset Semantic Types --',
			(map{ '@'.$_->name() => $_->name() } @datasetSTs ),
			'I' => '-- Image Semantic Types --',
			(map{ '@'.$_->name() => $_->name() } @imageSTs ),
			'F' => '-- Feature Semantic Types --',
			(map{ '@'.$_->name() => $_->name() } @featureSTs ),
		},
		-onchange => "if(this.value != '' && this.value != 'G' && this.value != 'D' && this.value != 'I' && this.value != 'F' ) { document.forms[0].submit(); } return false;"
	);

	# set up display modes
	my $current_display_mode = ( $q->param( 'Mode' ) || 'tiled_list' );
	foreach my $entry ( @{ $self->{ _display_modes } } ) {
		my %mode_data = %$entry;
		$mode_data{ checked } = 'checked'
			if( $entry->{mode} eq $current_display_mode );
		push( @{ $tmpl_data{ modes_loop } }, \%mode_data );
	}
	
	# If a type is selected, write in the search fields.
	# Also search if search fields are ready.
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
		
		# finish setting template data not specific to search results
		if( $q->param( 'Locked_Type' ) ) {
			$tmpl_data{ Locked_Type } = $common_name;
			$tmpl_data{ formal_name } = $formal_name;
		}

		my $render = $self->Renderer();
		# search_type is the type that the posted search parameters are
		# meant for. It will be different than Type if the user just
		# switched what type she is looking for.
 		my $search_type = $q->param( 'search_type' );
 		# search_names stores the names of the search fields. any or
 		# all of these may posted as a cgi parameter
		my @cgi_search_names = $q->param( 'search_names' );

		# clear stale search parameters
		unless( $search_type && $search_type eq $type || !$search_type ) {
			$q->delete( $_ ) foreach( @cgi_search_names );
		}
		
		$tmpl_data{ criteria_controls } = $self->getSearchCriteria( $type );
		
		# Reset fields if the search type was just switched.
 		unless( !$search_type || $type eq $search_type ) {
 			$q->param( '__order', '' );
 			$q->param( '__offset', '' );
 			$q->param( 'search_type', $type );
 		}
 		
		# Get Objects & Render them
		my ($objects, $paging_text ) = $self->search();
		my $select = ( $q->param( 'select' ) or $q->url_param( 'select' ) );
		$tmpl_data{ results } = $render->renderArray( $objects, $current_display_mode, 
			{ pager_text => $paging_text, type => $type, 
				( $select && $select eq 'many' ?
					( draw_checkboxes => 1 ) :
				( $select && $select eq 'one' ?
					( draw_radiobuttons => 1 ) :
					()
				) )
			} );

		# Select button
		$tmpl_data{do_select} = 
			'<span class="ome_quiet">'.
			'<a href="javascript:selectAllCheckboxes( \'selected_objects\' );">Select All</a> | '.
			'<a href="javascript:deselectAllCheckboxes( \'selected_objects\' );">Reset</a><br>'.
			'</span>'
			if( $select && $select eq 'many' );
		$tmpl_data{do_select} .= 
			$q->submit( { 
				-name => 'do_select',
				-value => 'Make Selection',
			} )
			if( $select );

		# gotta have hidden fields
		$html .= "\n".
			# tell the form what search fields are on it and what type they are for.
			$q->hidden( -name => 'search_names' ).
			$q->hidden( -name => 'search_type', -default => $type ).
			# these are needed for paging
			$q->hidden( -name => '__order' ).
			$q->hidden( -name => '__offset' ).
			$q->hidden( -name => 'last_order_by' ).
			$q->hidden( -name => 'page_action', -default => undef, -override => 1 ).
			$q->hidden( -name => 'accessor_id' );
		# This is used to retain selected objects across pages.
		$html .= $q->hidden( -name => 'selected_objects' )
			if( $select && $select eq 'many' );
		
	}
	
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my $tmpl = HTML::Template->new( filename => 'Search.tmpl', path => $tmpl_dir,
                                    case_sensitive => 1 );
	$tmpl->param( %tmpl_data );

	$html .= 
		$tmpl->output().
		$q->endform();

	return ( 'HTML', $html );	
}

=head2 getSearchFields

	# get html form elements keyed by field names 
	my ($form_fields, $search_paths) = OME::Web::Search->getSearchFields( $type, \@field_names, \%default_search_values );

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
	
	my $specializedSearch = $self->_specialize( $type );
	($form_fields, $search_paths) = $specializedSearch->_getSearchFields( $type, $field_names, $defaults )
		if( $specializedSearch and $specializedSearch->can('_getSearchFields') );

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
	my ( $searchField, $search_path ) = 
		$self->getRefSearchField( $from_type, $to_type, $accessor_to_type, $default_obj );

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
	
	my $specializedSearch = $self->_specialize( $to_type );
	return $specializedSearch->_getRefSearchField( $from_type, $to_type, $accessor_to_type, $default )
		if( $specializedSearch and $specializedSearch->can('_getRefSearchField') );

	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );
	my ($to_package) = OME::Web->_loadTypeAndGetInfo( $to_type );
	my $searchOn = '';
	if( $to_package->getColumnType( 'name' ) ) {
		$searchOn = '.name';
		$default = $default->name() if $default;
	} elsif( $to_package->getColumnType( 'Name' ) ) {
		$searchOn = '.Name';
		$default = $default->Name() if $default;
	} else {
		$default = $default->id() if $default;
	}

	my $q = $self->CGI();
	$q->param( $accessor_to_type.$searchOn, $default  ) 
		unless defined $q->param($accessor_to_type.$searchOn );
	return ( 
		$q->textfield( -name => $accessor_to_type.$searchOn , -size => 17, -default => $default ),
		$accessor_to_type.$searchOn,
		$default
	);
}

=head1 Internal Methods

These methods should not be accessed from outside the class

=cut 

sub getSearchCriteria {
	my ($self, $type)    = @_;
	my $q                = $self->CGI();
	my @cgi_search_names = $q->param( 'search_names' );
	my $render = $self->Renderer();
	my $factory = $self->Session()->Factory();
	my %tmpl_data;
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );

	my $tmpl_path = $self->_findTemplate( $type );
	my $tmpl = HTML::Template->new( filename => $tmpl_path,
	                                case_sensitive => 1 );

	# accessor stuff. 
	if( $q->param( 'accessor_id' ) && $q->param( 'accessor_id' ) ne '' ) {
	# We are working in accessor mode. Set object reference
		my $typeToAccessFrom = $q->param( 'accessor_type' );
		my $idToAccessFrom   = $q->param( 'accessor_id' );
		my $accessorMethod   = $q->param( 'accessor_method' );
		my $objectToAccessFrom = $factory->
			loadObject( $typeToAccessFrom, $idToAccessFrom )
			or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
		$tmpl_data{ '/accessor_object_ref' } = $render->render( $objectToAccessFrom, 'ref' ).
			"(<a href='javascript: document.forms[0].elements[\"accessor_id\"].value = \"\"; ".
			                     "document.forms[0].submit();'".
			   "title='Cancel selection'/>X</a> ".
			"<a href='javascript: selectOne( \"$typeToAccessFrom\", \"accessor_id\" );'".
			   "title='Change selection'/>C</a>)";
	}
	
	# Acquire search fields
	my @search_fields;
	if( $tmpl->query( name => '/search_fields_loop' ) ) {
	# Query the object for its fields
		@search_fields = ( $render->getFields( $type, 'summary' ), 'id' );
	} else {
	# Otherwise, the search fields are in the template.
		@search_fields = grep( (!m/^\//), $tmpl->param() ); # Screen out special field requests that start with '/'
	}

	my ($form_fields, $search_paths) = $self->getSearchFields( $type, \@search_fields );
	my %field_titles = $render->getFieldTitles( $type, \@search_fields );
	$q->param( 'search_names', values %$search_paths); # explicitly record what fields we are searching on.
	my $specializedSearch = $self->_specialize( $type );
	my $order = ( $specializedSearch ?
		$specializedSearch->__sort_field( $search_paths, $search_paths->{ $search_fields[0] }) :
		$self->__sort_field( $search_paths, $search_paths->{ $search_fields[0] })
	);
	
	# Render search fields
	my $search_field_tmpl = HTML::Template->new( 
		filename => $self->Session()->Configuration()->template_dir().'/search_field.tmpl',
		case_sensitive => 1
	);
	foreach my $field( @search_fields ) {
		# a button for ascending sort
		my $sort_up = "<a href='javascript: document.forms[0].elements[\"__order\"].value = \"".
			$search_paths->{ $field }.
			"\"; document.forms[0].submit();' title='Sort results by ".
			$field_titles{ $field }." in increasing order'".
			( $order && $order eq $search_paths->{ $field } ?
				" class = 'ome_active_sort_arrow'" : ''
			).'>';
		# a button for descending sort
		my $sort_down = "<a href='javascript: ".
				"document.forms[0].elements[\"__order\"].value = ".
				"\"!".$search_paths->{ $field }."\";".
				"document.forms[0].submit();' title='Sort results by ".
			$field_titles{ $field }." in decreasing order'".
			# $order is prefixed by a ! for descending sort. that explains substr().
			( $order && substr( $order, 1 ) eq $search_paths->{ $field } ?
				" class = 'ome_active_sort_arrow'" : ''
			).'>';

		$search_field_tmpl->param(
			field_label  => $field_titles{ $field },
			form_field   => $form_fields->{ $field },
			sort_up      => $sort_up, 
			sort_down    => $sort_down,
		);
		if( $tmpl->query( name => '/search_fields_loop' ) ) {
			push( 
				@{ $tmpl_data{ '/search_fields_loop' } }, 
				{ search_field => $search_field_tmpl->output() }
			) if $form_fields->{ $field };
		} else {
			$tmpl_data{$field} = $search_field_tmpl->output();
		} 
		$search_field_tmpl->clear_params();
	}
	
	$tmpl->param( %tmpl_data );
	return $tmpl->output();
}

sub search {
	my ($self ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();

	my (%searchParams, @objects, $object_count);

	my $type = $q->param( 'Type' );
	$type = $q->param( 'Locked_Type' ) unless $type;
	my @search_names = $q->param( 'search_names' );
	foreach my $search_on ( @search_names ) {
		next unless ( $q->param( $search_on ) && $q->param( $search_on ) ne '');
		my $value = $q->param( $search_on );
		# search string parsing
		$value =~ s/\*/\%/g;
		unless( $value =~ m/,/ ) {
			$searchParams{ $search_on } = [ 'ilike', $value ];
		} else {
			$searchParams{ $search_on } = [ 'in', [ split( m/,/, $value ) ] ];
		}
	}

	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	my ($objectToAccessFrom, $accessorMethod);

	# count Objects
 	if( $q->param( 'accessor_id' ) ) {
		my $typeToAccessFrom = $q->param( 'accessor_type' );
		my $idToAccessFrom   = $q->param( 'accessor_id' );
		$accessorMethod   = $q->param( 'accessor_method' );
 		$objectToAccessFrom = $factory->loadObject( $typeToAccessFrom, $idToAccessFrom )
 			or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
# getColumnType doesn't report on valid but as yet uninferred relations, so I'm disabling this error check for now.
# 		ref( $objectToAccessFrom )->getColumnType( $accessorMethod )
# 			or die "$accessorMethod is an unknown accessor for $typeToAccessFrom";
 		my $countAccessor = "count_".$accessorMethod;
 		$object_count = $objectToAccessFrom->$countAccessor( %searchParams );
 	} else {
		$object_count = $factory->countObjects( $formal_name, %searchParams );
	}

	# PAGING: prepare limit, offset, and order_by
	$searchParams{ __limit } = $self->{ _default_limit };
	my $numPages = POSIX::ceil( $object_count / $searchParams{ __limit } );
	$searchParams{ __order } = $self->__sort_field();
	# only use the offset parameter if we're ordering by the same thing as last time
	if( $q->param( 'last_order_by') && 
	    $q->param( 'last_order_by') eq $searchParams{ __order } &&
	    $q->param( "__offset" ) ne '') {
		$searchParams{ __offset } = $q->param( "__offset" );
	} else {
		$searchParams{ __offset } = 0;
	}

	# Turn pages
	my $currentPage = int( $searchParams{ __offset } / $searchParams{ __limit } );
	my $action = $q->param( 'page_action' ) ;
	if( $action ) {
		my $max_offset = ($numPages - 1) * $searchParams{ __limit };
		if( $action eq 'FirstPage' ) {
			$searchParams{ __offset } = 0;
		} elsif( $action eq 'PrevPage' ) {
			$searchParams{ __offset } = ( $currentPage - 1 ) * $searchParams{ __limit };
			# paranoid check
			$searchParams{ __offset } = 0
				if $searchParams{ __offset } < 0;
		} elsif( $action eq 'NextPage' ) {
			$searchParams{ __offset } = ( $currentPage + 1 ) * $searchParams{ __limit };
			# paranoid check
			$searchParams{ __offset } = $max_offset
				if $searchParams{ __offset } > $max_offset;
		} elsif( $action eq 'LastPage' ) {
			$searchParams{ __offset } = $max_offset;
		}
	}
	# update last_order_by. don't add a key to searchParams by accident in the process.
	$q->param( 'last_order_by', (
			exists $searchParams{ __order } ?
			$searchParams{ __order } :
			undef
		) );
	# update the __offset parameter
	$q->param( "__offset", $searchParams{ __offset } );

	# get objects: from an accessor method
 	if( $objectToAccessFrom ) {
		logdbg "debug", "Retrieving object from an accessor method:\n\t". $objectToAccessFrom->getFormalName()."(id=".$objectToAccessFrom->id.")->$accessorMethod ( ". join( ', ', map( $_." => ".$searchParams{ $_ }, keys %searchParams ) )." )";
 		@objects = $objectToAccessFrom->$accessorMethod( %searchParams );
 	# or with factory
 	} else {
 		logdbg "debug", "Retrieving object from search parameters:\n\tfactory->findObjectsLike( $formal_name, ".join( ', ', map( $_." => ".$searchParams{ $_ }, keys %searchParams ) )." )";
		@objects = $factory->findObjects( $formal_name, %searchParams );
	}
		
	# paging controls
	my $pagingText;
	if( $searchParams{ __limit } ) {
		my $offset = $searchParams{ __offset };
		my $limit  = $searchParams{ __limit };
		# add 1 to make it human readable (i.e. 1-n instead of 0-(n-1) )
		$currentPage = int( $searchParams{ __offset } / $searchParams{ __limit } ) + 1;
		if( $numPages > 1 ) {
			$pagingText .= $q->a( {
					-title => "First Page",
					-href => "javascript: document.forms[0].page_action.value='FirstPage'; document.forms[0].submit();",
					}, 
					'<<',
				).' '
				if ( $currentPage > 1 and $numPages > 2 );
			$pagingText .= $q->a( {
					-title => "Previous Page",
					-href => "javascript: document.forms[0].page_action.value='PrevPage'; document.forms[0].submit();",
					}, 
					'<'
				)." "
				if $currentPage > 1;
			$pagingText .= sprintf( "%u of %u ", $currentPage, $numPages);
			$pagingText .= "\n".$q->a( {
					-title => "Next Page",
					-href  => "javascript: document.forms[0].page_action.value='NextPage'; document.forms[0].submit();",
					}, 
					'>'
				)." "
				if $currentPage < $numPages;
			$pagingText .= "\n".$q->a( {
					-title => "Last Page",
					-href  => "javascript: document.forms[0].page_action.value='LastPage'; document.forms[0].submit();",
					}, 
					'>>'
				)
				if( $currentPage < $numPages and $numPages > 2 );
		}
	}
	
	return ( \@objects, $pagingText );
}

=head2 __sort_field

	# get the field to sort by. set a default if there isn't a cgi param
	my $order = $self->__sort_field( $search_paths, $default );
	# retrieve the order from a cgi parameter
	$searchParams{ __order } = $self->__sort_field();

	This method determines what search path the results should be ordered by.
	As a side affect, it stores the search path as a cgi parameter.
	The search path is returned.

	$default will be used if no cgi __order parameter is found, and
	there is no 'Name' or 'name' field in $search_paths
	$search_paths is a hash that is keyed by available search field
	names. It's values are search paths for each of those fields. see
	getSearchFields()

=cut

sub __sort_field {
	my ($self, $search_paths, $default ) = @_;
	my $q = $self->CGI();

	if( $q->param( '__order' ) && $q->param( '__order' ) ne '' ) {
		return $q->param( '__order' );
	}
	
	if( exists $search_paths->{ 'name' } ) {
		$q->param( '__order', $search_paths->{ 'name' } );
		return $search_paths->{ 'name' };
	} elsif( exists $search_paths->{ 'Name' } ) {
		$q->param( '__order', $search_paths->{ 'Name' } );
		return $search_paths->{ 'Name' };
	} else {
		$q->param( '__order', $default );
		return $default;
	}
}

=head2 _findTemplate

	my $template_path = $self->_findTemplate( $obj );

returns a path to a custom template (see HTML::Template) for this $obj
and $mode - OR - undef if no matching template can be found

=cut

sub _findTemplate {
	my ( $self, $obj ) = @_;
	my $mode = 'search';
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
	$tmpl_path = $tmpl_dir.'/generic_search.tmpl';
	die "could not find a search template"
		unless -e $tmpl_path;
	return $tmpl_path;
}

=head2 _specialize

	my $specializedClass = $self->_specialize($type);

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either

returns a specialized prototype (if one exists) for rendering a
particular type of data.
returns undef if a specialized prototype does not exist or if it was
called from a specialized prototype.

=cut

sub _specialize {
	my ($self,$type) = @_;
	
	# get DBObject prototype or ST name from instance
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	
	# construct specialized package name
	my $specializedPackage = $formal_name;
	($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
	$specializedPackage = "OME::Web::Search::".$specializedPackage;

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

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
