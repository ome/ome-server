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
	
	$self->{ form_name } = 'primary';
	
	return $self;
}

sub getMenuText {
	my $self = shift;
	my $menuText = "Other";
	return $menuText unless ref($self);

	my $q    = $self->CGI();
	my $type = $q->param( 'SearchType' );
	$type = $q->param( 'Locked_SearchType' ) unless $type;
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
	my $type = $q->param( 'SearchType' );
	$type = $q->param( 'Locked_SearchType' ) unless $type;
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    	return "Search for $common_name";
    }
	return $menuText;
}

sub getPageBody {

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# Setup variables
	my $self = shift;	
	my $factory = $self->Session()->Factory();
	my $q    = $self->CGI();
	# $type is the formal name of type of object being searched for
	my $type = $self->_getCurrentSearchType();
	my $html = $q->startform( -name => 'primary', -action => $self->pageURL( 'OME::Web::Search' ) );
	my %tmpl_data;
	my $form_name = $self->{ form_name };

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# Return results of a select, then close this popup window.
	# This search package can be called as a popup window that searches & selects.
	if( $q->param( 'do_select' ) || $q->param( 'select_all' ) ) {
		my @selected_objects;
		
		# retrieve checked boxes
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
			@selected_objects = map( $resolver->getObject($_), @selection );

		# retrieve all search results
		} else {
			my %searchParams = $self->_getSearchParams();
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
			@selected_objects = $factory->findObjects( $formal_name, %searchParams );
 		}

		my $return_to_form = ( $q->param( 'return_to_form' ) || 'primary');
		my $return_to_form_element = ( $q->param( 'return_to' ) );
		my $ids = join( ',', map( $_->id, @selected_objects ) );
		$self->{ _onLoadJS } = <<END_HTML;
				window.opener.document.forms['$return_to_form'].${return_to_form_element}.value = '$ids';
				window.opener.document.forms['$return_to_form'].submit();
				window.close();
END_HTML
		return( 'HTML', '' );
	}

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# get a Drop down list of search types
	$tmpl_data{ search_types } = $self->__get_search_types_popup_menu();
	
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
		if( $q->param( 'Locked_SearchType' ) ) {
			$tmpl_data{ Locked_SearchType } = $common_name;
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
		# Reset fields if the search type was just switched.
		unless( $search_type && $search_type eq $type || !$search_type ) {
			$q->delete( $_ ) foreach( @cgi_search_names );

 			$q->param( '__order', '' );
 			$q->param( '__offset', '' );
 			$q->param( 'search_type', $type );
 		}
 		
		$tmpl_data{ criteria_controls } = $self->getSearchCriteria( $type );
		 		
		# Get Objects & Render them
		my ($objects, $paging_text ) = $self->search();
		my $select = $q->param( 'select' );
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
			'<ul class="ome_quiet">'.
			'<li><a href="javascript:selectAllCheckboxes( \'selected_objects\' );">Check all boxes on this page</a></li'.
			'<li><a href="javascript:deselectAllCheckboxes( \'selected_objects\' );">Reset all boxes on this page</a></li>'.
			'</ul>'
			if( $select && $select eq 'many' );
		$tmpl_data{do_select} .= 
			$q->submit( { 
				-name => 'do_select',
				-value => 'Select checked objects',
			} )
			if( $select );
		$tmpl_data{do_select} .= 
			$q->submit( { 
				-name => 'select_all',
				-value => 'Select all search results',
			} )
			if( $select && $select eq 'many' );

		# This is used to retain selected objects across pages. 
		# It takes advantage of CGI's "sticky fields". The values (i.e. LSID's)
		# of 'selected_objects' passed in from checkboxes will make their way
		# into these hidden fields. The problem then is unselecting. If I select
		# a checkbox, and go to the next page then that value is saved as a
		# hidden field. If I come back to the first page and unselect the object,
		# the object is still stored as a hidden field, and will appear as checked
		# again if I go back and forth between pages.
		$html .= $q->hidden( -name => 'selected_objects' )
			if( $select && $select eq 'many' );

		# gotta have hidden fields
		$html .= "\n".
			# tell the form what search fields are on it and what type they are for.
			$q->hidden( -name => 'search_names' ).
			$q->hidden( -name => 'search_type', -default => $type ).
			# these are needed for paging
			$q->hidden( -name => '__order' ).
			$q->hidden( -name => '__offset' ).
			$q->hidden( -name => 'last_order_by' ).
			$q->hidden( -name => 'page_action', -default => undef, -override => 1 );
		
	}
	
	my $tmpl = HTML::Template->new( 
		filename       => 'Search.tmpl', 
		path           => $self->_baseTemplateDir(),
		case_sensitive => 1 
	);
	$tmpl->param( %tmpl_data );

	$html .= 
		$q->hidden( -name => 'return_to_form' ).
		$q->hidden( -name => 'return_to' ).
		$q->hidden( -name => 'select' ).
		$q->hidden( -name => 'Popup' ).
		$tmpl->output().
		$q->endform();

	return ( 'HTML', $html );	
}

sub getOnLoadJS { return shift->{ _onLoadJS }; }

=head2 getSearchFields

	# get html form elements keyed by field names 
	my $form_fields = OME::Web::Search->getSearchFields( $type, \@field_names, \%default_search_values );

$type can be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
@field_names is used to populate the returned hash.
%default_search_values is also optional. If given, it is used to populate the search form fields.

$form_fields is a hash reference of html form inputs { field_name => form_input, ... }
$search_fields is a list of DBObject fields (or Semantid Elements if searching 
for an ST) to search on. 

=cut

sub getSearchFields {
	my ($self, $type, $field_names, $defaults) = @_;
	my ($form_fields);
	
	my $specializedSearch = $self->_specialize( $type );
	$form_fields = $specializedSearch->_getSearchFields( $type, $field_names, $defaults )
		if( $specializedSearch and $specializedSearch->can('_getSearchFields') );

	my $q = $self->CGI();
	my ($package_name, $common_name, $formal_name, $ST) =
		OME::Web->_loadTypeAndGetInfo( $type );
	foreach my $field ( @$field_names ) {
		next if exists $form_fields->{ $field };
		# A field may have the form: dataset_links.dataset The code block below
		# finds the package name of the right most method
		my @fields = split( /\./, $field );
		my $foreignClass = $package_name->getAccessorReferenceType( shift @fields );
		foreach my $single_field ( @fields ) {
			$foreignClass = $foreignClass->getAccessorReferenceType( $single_field );
		}
		
		if( $foreignClass ) {
			$form_fields->{ $field } = $self->getRefSearchField( 
				$formal_name, $foreignClass, $field, $defaults->{ $field } );
		} else {
			$q->param( $field, $defaults->{ $field }  ) 
				unless defined $q->param( $field );
			$form_fields->{ $field } = $q->textfield( 
				-name    => $field , 
				-size    => 17, 
				-default => $defaults->{ $field } 
			);
		}
	}

	return $form_fields;
}

=head2 getRefSearchField

	# get an html form element that will allow searches to $to_type
	my $htmlSearchField = 
		$self->getRefSearchField( $from_type, $to_type, $accessor_to_type, $default_obj );

the types may be a DBObject name ("OME::Image"), an Attribute name
("@Pixels"), or an instance of either
$from_type is the type you are searching from
$accessor_to_type is an accessor of $from_type that returns an instance of $to_type
$to_type is the type the accessor returns

returns a form input and a search path for that input.

=cut

sub getRefSearchField {
	my ($self, $from_type, $to_type, $accessor_to_type, $default) = @_;
	my $threshold_Popup = 10;
	
	if( not defined $default ) {
		my $specializedSearch = $self->_specialize( $to_type );
		$default = $specializedSearch->_getDefault( )
			if( $specializedSearch && $specializedSearch->can('_getDefault') );
	}

	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );
	my ($to_package, $to_common_name, $to_formal_name) = OME::Web->_loadTypeAndGetInfo( $to_type );
	$default = $default->id() if $default;

	my $q = $self->CGI();
	$q->param( $accessor_to_type, $default  ) 
		unless defined $q->param($accessor_to_type );

	my $factory = $self->Session()->Factory();
	my $htmlSnippet;

	# Make a popup menu if there aren't very many objects to select from
	if( $factory->countObjects( $to_formal_name ) < $threshold_Popup ) {
		my @objects_to_select = $factory->findObjects( $to_formal_name );
		my %object_names = map{ $_->id() => $self->Renderer()->getName($_) } @objects_to_select;
		my $object_order = [ '', sort( { $object_names{$a} cmp $object_names{$b} } keys( %object_names ) ) ];
		$object_names{''} = 'All';
		$htmlSnippet = 
			$q->scrolling_list( 
				-name     => $accessor_to_type,
				'-values' => $object_order,
				-labels	  => \%object_names,
				-default  => $default,
				-size     => 3,
				-multiple => 'true',
			);
	# Make a click through link if there are very many objects to select from
	} else {
		if( $q->param($accessor_to_type ) ) {
		
			# Work out the selection. It will be one or more ids. If it's
			# one parameter, it could be a comma separated list.
			my ($selectionRepresentation, @ids);
			my @selectionVals = $q->param($accessor_to_type );
			if( scalar( @selectionVals ) == 1 ) {
				@ids = split( /,/, $selectionVals[0] );
			} else {
				@ids = @selectionVals;
			}
			
			# Build a representation of the selection
			# Only show the individual objects if there aren't many selected
			if( scalar( @ids ) < 5 ) {
				my @objs = map( $factory->loadObject( $to_type, $_ ), @ids );
				$selectionRepresentation = $self->Renderer()->renderArray( \@objs, 'ref_list' );
			# If there are too many to show, link to a popup page to show them all
			} else {
				$selectionRepresentation = $q->a(
					{ -href => 'javascript: openPopUp( "'.$self->getSearchURL( $to_type, id => join( ',', @ids ) ).'" )' },
					scalar( @ids )." selected. "
				);
			}
			
			my $form_name = $self->{ form_name };
			$htmlSnippet = 
				$q->hidden( -name => $accessor_to_type ).
				$selectionRepresentation.
				"(<a href='javascript: document.forms[\"$form_name\"].elements[\"$accessor_to_type\"].value = \"\"; ".
									 "document.forms[\"$form_name\"].submit();'".
				   "title='Cancel selection'/>X</a> ".
				"<a href='javascript: selectMany( \"$to_type\", \"$accessor_to_type\" );'".
				   "title='Change selection'/>C</a>)";
		} else { #  then if nothing is selected.
			$htmlSnippet = 
				$q->hidden( -name => $accessor_to_type ).
				"(".
				$q->a( { 
					-href => "javascript: selectMany( '$to_type', '$accessor_to_type' );"
				}, "Select" ).")";
		}
	}

	return $htmlSnippet;
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
	my $form_name = $self->{ form_name };

	my $tmpl_path = $self->_findTemplate( $type );
	my $tmpl = HTML::Template->new( filename => $tmpl_path,
	                                case_sensitive => 1 );
	
	# Acquire search fields
	my @search_fields;
	# Default: template does not care what search fields are given
	my %specialRequestSearchFields;
	if( $tmpl->query( name => '/search_fields_loop' ) ) {
		# First look for any requested via parameters
		@search_fields = $q->param( 'search_names' );
		my %lookup = map{ $_ => undef } @search_fields;
		# Look for fields shown in the object's summary to add to the bottom of the list
		my @summaryFields = ( $render->getFields( $type, 'summary' ), 'id' );
		foreach my $summaryField ( @summaryFields ) {
			push @search_fields, $summaryField
				if( not exists $lookup{ $summaryField } );
		}
	} else {
		# First look for any requested via parameters
		@search_fields = $q->param( 'search_names' );
		my %lookup = map{ $_ => undef } @search_fields;
		# Lookup search fields from the display template.
		my @template_fields = grep( (!m/^\//), $tmpl->param() ); # Screen out special field requests that start with '/'
		# Record which fields were not requested by the template
		my %template_field_lookup = map{ $_ => undef } @template_fields;
		foreach my $requestedField ( @search_fields ) {
			$specialRequestSearchFields{ $requestedField } = undef
				if( not exists $template_field_lookup{ $requestedField } );
		}
		# Add template requests to the list
		foreach my $tpmlField ( @template_fields ) {
			push @search_fields, $tpmlField
				if( not exists $lookup{ $tpmlField } );
		}

	}

	my $form_fields = $self->getSearchFields( $type, \@search_fields );
	my %field_titles = $render->getFieldTitles( $type, \@search_fields );
	$q->param( 'search_names', @search_fields); # explicitly record what fields we are searching on.
	my $specializedSearch = $self->_specialize( $type );
	my $order = ( $specializedSearch ?
		$specializedSearch->__sort_field( \@search_fields, $search_fields[0]) :
		$self->__sort_field( \@search_fields, $search_fields[0] )
	);
	
	# Render search fields
	my $search_field_tmpl = HTML::Template->new( 
		filename       => 'search_field.tmpl',
		path           => $self->_baseTemplateDir(), 
		case_sensitive => 1
	);
	my $specialRequestSection = '';
	foreach my $field( @search_fields ) {
		# a button for ascending sort
		my $sort_up = "<a href='javascript: document.forms[\"$form_name\"].elements[\"__order\"].value = \"".
			$field.
			"\"; document.forms[\"$form_name\"].submit();' title='Sort results by ".
			$field_titles{ $field }." in increasing order'".
			( $order && $order eq $field ?
				" class = 'ome_active_sort_arrow'" : ''
			).'>';
		# a button for descending sort
		my $sort_down = "<a href='javascript: ".
				"document.forms[\"$form_name\"].elements[\"__order\"].value = ".
				"\"!".$field."\";".
				"document.forms[\"$form_name\"].submit();' title='Sort results by ".
			$field_titles{ $field }." in decreasing order'".
			# $order is prefixed by a ! for descending sort. that explains substr().
			( $order && substr( $order, 1 ) eq $field ?
				" class = 'ome_active_sort_arrow'" : ''
			).'>';

		$search_field_tmpl->param(
			field_label  => $field_titles{ $field },
			form_field   => $form_fields->{ $field },
			# Don't put sorting buttons on wildcard searches
			( ( $field ne '*' ) ? (
				sort_up      => $sort_up, 
				sort_down    => $sort_down,
			) : () )
		);
		if( $tmpl->query( name => '/search_fields_loop' ) ) {
			push( 
				@{ $tmpl_data{ '/search_fields_loop' } }, 
				{ search_field => $search_field_tmpl->output() }
			) if $form_fields->{ $field };
		} else {
			if( exists $specialRequestSearchFields{ $field } ) {
				$specialRequestSection .= $search_field_tmpl->output();
			} else {
				$tmpl_data{$field} = $search_field_tmpl->output();
			}
		} 
		$search_field_tmpl->clear_params();
	}
	
	$tmpl->param( %tmpl_data );
	return $specialRequestSection.$tmpl->output();
}

sub search {
	my ($self ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();

	my %searchParams = $self->_getSearchParams();
	my $pagingText;
	($pagingText, %searchParams) = $self->_preparePaging( %searchParams );

	my $type = $self->_getCurrentSearchType();
	my (undef, undef, $formal_name) = $self->_loadTypeAndGetInfo( $type );
# 	logdbg "debug", "Retrieving object from search parameters:\n\tfactory->findObjectsLike( $formal_name, ".join( ', ', map( $_." => ".$searchParams{ $_ }, keys %searchParams ) )." )";
	my @objects = $factory->findObjects( $formal_name, %searchParams );
			
	return ( \@objects, $pagingText );
}


=head2 _getSearchParams

	my %searchParameters = $self->_getSearchParams();
	my $searchType       = $self->_getCurrentSearchType();
	my @objects          = $factory->findObjects( $searchType, %searchParameters );
	
	parses the search parameters from cgi parameters, and makes them ready for 
	a standard factory search. Does not include offset or limit.

=cut

sub _getSearchParams {
	my ($self ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();

	my %searchParams;

	my $type = $self->_getCurrentSearchType();
	my @search_names = $q->param( 'search_names' );
	foreach my $search_on ( @search_names ) {
		next unless ( $q->param( $search_on ) && $q->param( $search_on ) ne '');
		my @values = $q->param( $search_on );
		@values = grep{ (defined $_) && ($_ ne '') } @values;
		if( scalar( @values ) > 1 ) {
			$searchParams{ $search_on } = [ 'in', \@values ];		
		} elsif( $search_on eq '*' ) {
			$searchParams{ $search_on } = $values[0];
		} else {
			my $value = $values[0];
			# search string parsing
			$value =~ s/\*/\%/g;
			unless( $value =~ m/,/ ) {
				$searchParams{ $search_on } = [ 'ilike', '%'.$value.'%' ];
			} else {
				$searchParams{ $search_on } = [ 'in', [ split( m/,/, $value ) ] ];
			}
		}
	}
	return %searchParams;
}


=head2 _preparePaging

	my %searchParameters = $self->_getSearchParams();
	my $pagingText;
	($pagingText, %searchParameters) = $self->_preparePaging( %searchParameters );
	my $searchType       = $self->_getCurrentSearchType();
	my @objects          = $factory->findObjects( $searchType, %searchParameters );
	
	parses the offset or limit from incoming cgi parameters, updates them,
	and generates the paging controls.

=cut

sub _preparePaging {
	my ($self, %searchParams ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();


	# load type
	my $type         = $self->_getCurrentSearchType();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

	# count Objects
 	my $object_count = $factory->countObjects( $formal_name, %searchParams );

	# PAGING: prepare limit, offset, and order_by
	$searchParams{ __limit } = $self->{ _default_limit };
	my $numPages = POSIX::ceil( $object_count / $searchParams{ __limit } );
	$searchParams{ __order } = $self->__sort_field();
	# only use the offset parameter if we're ordering by the same thing as last time
	if( defined $q->param( 'last_order_by') && 
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
	
	# paging controls
	my $pagingText;
	my $form_name = $self->{ form_name };
	if( $searchParams{ __limit } ) {
		my $offset = $searchParams{ __offset };
		my $limit  = $searchParams{ __limit };
		# add 1 to make it human readable (i.e. 1-n instead of 0-(n-1) )
		$currentPage = int( $searchParams{ __offset } / $searchParams{ __limit } ) + 1;
		if( $numPages > 1 ) {
			$pagingText .= $q->a( {
					-title => "First Page",
					-href => "javascript: document.forms['$form_name'].page_action.value='FirstPage'; document.forms['$form_name'].submit();",
					}, 
					'<<',
				).' '
				if ( $currentPage > 1 and $numPages > 2 );
			$pagingText .= $q->a( {
					-title => "Previous Page",
					-href => "javascript: document.forms['$form_name'].page_action.value='PrevPage'; document.forms['$form_name'].submit();",
					}, 
					'<'
				)." "
				if $currentPage > 1;
			$pagingText .= sprintf( "%u of %u ", $currentPage, $numPages);
			$pagingText .= "\n".$q->a( {
					-title => "Next Page",
					-href  => "javascript: document.forms['$form_name'].page_action.value='NextPage'; document.forms['$form_name'].submit();",
					}, 
					'>'
				)." "
				if $currentPage < $numPages;
			$pagingText .= "\n".$q->a( {
					-title => "Last Page",
					-href  => "javascript: document.forms['$form_name'].page_action.value='LastPage'; document.forms['$form_name'].submit();",
					}, 
					'>>'
				)
				if( $currentPage < $numPages and $numPages > 2 );
		}
	}

	return ($pagingText, %searchParams);
}

=head2 __sort_field

	# get the field to sort by. set a default if there isn't a cgi param
	my $order = $self->__sort_field( \@search_fields, $default );
	# retrieve the order from a cgi parameter
	$searchParams{ __order } = $self->__sort_field();

	This method determines what search path the results should be ordered by.
	As a side affect, it stores the search path as a cgi parameter.
	The search path is returned.

	$default will be used if no cgi __order parameter is found, and
	there is no 'Name' or 'name' field in $search_fields
	$search_fields is a list of available search field
	names.

=cut

sub __sort_field {
	my ($self, $search_fields, $default ) = @_;
	my $q = $self->CGI();

	if( $q->param( '__order' ) && $q->param( '__order' ) ne '' ) {
		return $q->param( '__order' );
	}
	
	if( grep( $_ eq 'name', @$search_fields ) ) {
		$q->param( '__order', 'name' );
		return 'name';
	} elsif( grep( $_ eq 'Name', @$search_fields ) ) {
		$q->param( '__order', 'Name' );
		return 'Name';
	} else {
		$q->param( '__order', $default );
		return $default;
	}
}

=head2 _baseTemplateDir

	my $template_dir = $self->_baseTemplateDir();
	
	Returns the directory where specialized templates for this class are stored.

=cut

sub _baseTemplateDir { 
	my $self = shift;
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	return $tmpl_dir."/System/Search/";
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
	my $tmpl_dir = $self->_baseTemplateDir();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $tmpl_path = $formal_name; 
	$tmpl_path =~ s/@//g; 
	$tmpl_path =~ s/::/\//g; 
	$tmpl_path .= "/".$mode.".tmpl";
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

=head2 _getCurrentSearchType

	my $searchType = $self->_getCurrentSearchType();

This loads the current search type from incoming cgi parameters.

=cut

sub _getCurrentSearchType {
	my ($self) = @_;
	my $q    = $self->CGI();
	# $type is the formal name of type of object being searched for
	my $type = $q->param( 'SearchType' ) || $q->param( 'Locked_SearchType' );
	return $type;	
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

=head2 __get_search_types_popup_menu

	my $popupMenuHTML = $self->__get_search_types_popup_menu();

This returns a popup_menu form element that has all available search types.

=cut

sub __get_search_types_popup_menu {

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# Setup variables
	my $self = shift;	
	my $factory = $self->Session()->Factory();
	my $q    = $self->CGI();
	my $searchType = $self->_getCurrentSearchType();
	my $form_name = $self->{ form_name };
	
	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# Make a Drop down list of search types
	my @search_types = $self->__get_search_types();	
	# if the type requested isn't in the list of searchable types, add it. 
	# This stores the type, which is required for paging to work.
	unshift( @search_types, $searchType )
		unless(
			( not defined $searchType ) ||               # it wasn't defined
			( $searchType =~ m/^@/ ) ||                  # we'll add it below
			( grep( $_ eq $searchType, @search_types ) ) # it's already in the list
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
	
	return $q->popup_menu(
		-name     => 'SearchType',
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
		-default  => ( $searchType ? $searchType : '' ),
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
		-onchange => "if(this.value != '' && this.value != 'G' && this.value != 'D' && this.value != 'I' && this.value != 'F' ) { document.forms['$form_name'].submit(); } return false;"
	);

}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
