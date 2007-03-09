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
use OME::Tasks::SemanticTypeManager;

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
	$self->{ _display_modes } = {
		'summary' => 'Summaries',
		'ref'     => 'Names', 
	};
	
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

=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('Search.tmpl');
	$template->param(ST => $self->getMenuText());
	return $template->output();
}

sub getTemplate {
    my $self=shift;
    return OME::Web::TemplateManager->getBasicSearchTemplate();
}


sub getPageBody {

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# Setup variables
	my $self = shift;	
	my $tmpl = shift;
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
				window.opener.document.forms['$return_to_form'].elements['${return_to_form_element}'].value = '$ids';
				if( window.opener.document.forms['$return_to_form'].elements['action'] ) {
					window.opener.document.forms['$return_to_form'].elements['action'].value = 'refresh';
				}
				window.opener.document.forms['$return_to_form'].submit();
				window.close();
END_HTML
		return( 'HTML', '' );
	}

	#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
	# get a Drop down list of search types
	$tmpl_data{ search_types } = $self->__get_search_types_popup_menu();
	
	# set up display modes
	my $displayMode = ( $q->param( 'DisplayTemplate' ) || 'summary' );
	$q->param( 'DisplayTemplate', $displayMode );
# These lines allow the user to select any display template available for this type.
# The drawback is that many templates have random names and were designed for interal use.
#	my @template_names  = $self->Renderer()->getTemplateList( $type, 'one' );
#	my %template_labels = map{ $_ => ucfirst( $_ ) } @template_names;
	my %template_labels = %{ $self->{ _display_modes } };
	my @template_names  = keys( %template_labels );
	$tmpl_data{ availableTemplates } = $q->radio_group( 
		-name      => 'DisplayTemplate', 
		'-values'  => \@template_names, 
		-labels    => \%template_labels,
		-linebreak => 'true'
	);
		
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

		# clear stale search parameters
		# Reset fields if the search type was just switched.
		unless( $search_type && $search_type eq $type || !$search_type ) {
			# search_names stores the names of the search fields. any or
			# all of these may posted as a cgi parameter
			my @cgi_search_names = $q->param( 'search_names' );
			$q->delete( $_ ) foreach( @cgi_search_names );

 			$q->param( '__order', '' );
 			$q->param( '__offset', '' );
 			$q->param( 'search_type', $type );
 			$q->delete( 'search_names' );
 		}
 		
		$tmpl_data{ criteria_controls } = $self->getSearchCriteria( $type );
		 		
		# Get Objects & Render them
		my %searchParams = $self->_getSearchParams();
		my $select = $q->param( 'select' );
		$tmpl_data{ results } = $render->renderArray( [$formal_name, \%searchParams], 'tiled_list_param',
			{ 
				type => $type, 
				no_more_info => 1, 
				object_mode => $displayMode, 
				( $select && $select eq 'many' ?
					( draw_checkboxes => 1 ) :
				( $select && $select eq 'one' ?
					( draw_radiobuttons => 1 ) :
					()
				) ),
			} 
		);

		# Select button
		$tmpl_data{do_select} = 
			'<ul class="ome_quiet">'.
			'<li><a href="javascript:selectAllCheckboxes( \'selected_objects\' );">Check all boxes on this page</a></li>'.
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

		# Create link to save as table.
		delete $searchParams{ __offset }
			if exists $searchParams{ __offset };
		delete $searchParams{ __limit }
			if exists $searchParams{ __limit };
		$tmpl_data{ Table_URL } = 
			$self->getTableURL( $formal_name, %searchParams );

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
$search_fields is a list of DBObject fields (or Semantic Elements if searching 
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
			$form_fields->{ $field } = $self->getObjectSelectionField( 
				$foreignClass, $field, { default_obj => $defaults->{ $field } } );
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

=head2 getObjectSelectionField

	# get an html form element to select instances of $type
	my $htmlSearchField = 
		$self->getObjectSelectionField( $type, $field_name, $options );

$type is the type of object to select. It may be a DBObject name
("OME::Image"), an Attribute name ("@Pixels"), or an instance of either.
$field_name is the desired name of the form field.
$options is a hash that can optionally contain the following fields:
	default_obj is the object that will be selected when the page 
initially loads. It may also be an id.
	max_elements_in_list is the maximum number of elements to allow
in a list. The default value is 10.
	list_length is the vertical height of the list. The default value is 3.

returns an html snippets to select objects.

If there are a small number of objects in the DB visible to the logged in user,
a multi-select field will be returned. If there are a large number of objects,
the user will see a link to select objects using a popup window. Once they 
select objects, references to selected objects will also be displayed.


=cut

sub getObjectSelectionField {
	my ($self, $type, $field_name, $options) = @_;

	$options = {} unless $options; # makes later code easier
	confess "The options parameter is not a hash reference." 
		unless ref( $options ) eq 'HASH';
	my $default_obj     = $options->{ object } || $options->{ default_obj };
	my $threshold_Popup = $options->{ max_elements_in_list } || 10;
	my $list_length     = $options->{ list_length } || 3;
	
	if( not defined $default_obj ) {
		my $specializedSearch = $self->_specialize( $type );
		$default_obj = $specializedSearch->_getDefault( )
			if( $specializedSearch && $specializedSearch->can('_getDefault') );
	}

	my ($to_package, $to_common_name, $to_formal_name) = OME::Web->_loadTypeAndGetInfo( $type );
	$default_obj = $default_obj->id() 
		if( $default_obj && ref( $default_obj ) );

	my $q = $self->CGI();
	$q->param( $field_name, $default_obj  ) 
		if( ( not defined $q->param($field_name ) ) || ( exists $options->{ object } ) );

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
				-name     => $field_name,
				'-values' => $object_order,
				-labels	  => \%object_names,
				-default  => $default_obj,
				-size     => $list_length,
				-multiple => ( $options->{ select_one } ? undef : 'true' ),
			);
	# Make a click through link if there are very many objects to select from
	} else {
		if( $q->param($field_name ) ) {
		
			# Work out the selection. It will be one or more ids. If it's
			# one parameter, it could be a comma separated list.
			my ($selectionRepresentation, @ids);
			my @selectionVals = $q->param($field_name );
			if( scalar( @selectionVals ) == 1 ) {
				@ids = split( /,/, $selectionVals[0] );
			} else {
				@ids = @selectionVals;
			}
			
			# Build a representation of the selection
			# Render as a reference if there is only 1.
			if( scalar( @ids ) == 1 ) {
				my $obj = $factory->loadObject( $type, $ids[0] );
				$selectionRepresentation = $self->Renderer()->render( $obj, 'ref' );
			# Only show the individual objects if there aren't many selected
			} elsif( scalar( @ids ) < 5 ) {
				my @objs = map( $factory->loadObject( $type, $_ ), @ids );
				$selectionRepresentation = $self->Renderer()->renderArray( \@objs, 'ref_list' );
			# If there are too many to show, link to a popup page to show them all
			} else {
				$selectionRepresentation = $q->a(
					{ -href => 'javascript: openPopUp( "'.$self->getSearchURL( $type, id => join( ',', @ids ) ).'" )' },
					scalar( @ids )." selected. "
				);
			}
			
			my $form_name = $self->{ form_name };
			$htmlSnippet = 
				$q->hidden( -name => $field_name ).
				$selectionRepresentation.
				"(<a href='javascript: document.forms[\"$form_name\"].elements[\"$field_name\"].value = \"\"; ".
									 "document.forms[\"$form_name\"].submit();'".
				   "title='Cancel selection'/>X</a> ".
				"<a href='javascript: ".
					($options->{ select_one } ? 'selectOne' : 'selectMany' ).
					"( \"$type\", \"$field_name\"".
					($options->{ form_name } ? ", '".$options->{ form_name }."'" : "" ).
					");'".
				   "title='Change selection'/>C</a>)";
		} else { #  then if nothing is selected.
			$htmlSnippet = 
				$q->hidden( -name => $field_name ).
				"(".
				$q->a( { 
					-href => "javascript: ".
						($options->{ select_one } ? 'selectOne' : 'selectMany' ).
						"( '$type', '$field_name'".
						($options->{ form_name } ? ", '".$options->{ form_name }."'" : "" ).
						" );"
				}, "Select" ).")";
		}
	}

	return $htmlSnippet;
}

=head2 getSearchCriteria

	my $html_snippet = $self->getSearchCriteria( $type );

Returns search controls for a given type. It first attempts to construct
this with a template specific to the type (for an example see: 
	OME/src/html/Templates/System/Search/OME/Image/search.tmpl )
If it cannot find a custom search template, it will determine search fields 
to include based on fields show in the display template for that type.

Suggestions or trials at improved logic for this method would be welcome.

=cut 

sub getSearchCriteria {
	my ($self, $type)    = @_;
	my $q                = $self->CGI();
	my $render = $self->Renderer();
	my $factory = $self->Session()->Factory();
	my %tmpl_data;
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	my $form_name = $self->{ form_name };

	my $tmpl = OME::Web::TemplateManager->getClassSearchTemplate($type);
	
	# Acquire search fields
	my @search_fields;
	
	# The search template is asking for us for the name of search fields. 
	# Make search fields for any requested by url or post parameters, 
	# fields used in the object's summary display template, and any fields
	# that are requested by the search template.
	my %specialRequestSearchFields;
	if( $tmpl->query( name => '/search_fields_loop' ) ) {
		# First look for any requested via parameters
		@search_fields = $q->param( 'search_names' );
		my %lookup = map{ $_ => undef } @search_fields;
		# Add ALL columns to the list. It ain't necessarily pretty, but at 
		# least it's complete. An admin or developer can always define a 
		# search template if they want pretty.
		my @summaryFields = ( $package_name->getPublishedCols(), 'id' );
		foreach my $summaryField ( @summaryFields ) {
			push @search_fields, $summaryField
				if( not exists $lookup{ $summaryField } );
		}
		# Lookup search fields explicitly requested by the template.
		my @template_fields = grep( (!m/^\//), $tmpl->param() ); # Screen out special field requests that start with '/'
		# Add template requests to the list
		foreach my $tpmlField ( @template_fields ) {
			push @search_fields, $tpmlField
				if( not exists $lookup{ $tpmlField } );
		}

	# The search template is not asking us for the name of search fields. 
	# The search fields will be those requested by url or post parameters 
	# and those explicitly specified in the search template.
	} else {
		# First look for any requested via parameters
		@search_fields = $q->param( 'search_names' );
		my %lookup = map{ $_ => undef } @search_fields;
		# Lookup search fields from the template.
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
	
	my $search_field_tmpl = 
	    OME::Web::TemplateManager->getSearchFieldTemplate();
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
		# Put this search field in the search fields loop if there is such a loop
		# and the field wasn't explicitly requested by the template.
		if( ( $tmpl->query( name => '/search_fields_loop' ) ) && 
		    ( !$tmpl->query( name => $field )  )
		  ) {
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
	# We don't care about the other things this function returns, only the package name
	my ($package_name) = $self->_loadTypeAndGetInfo( $type );
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
			
			# Parse operations that were specified on the search field.
			if( $value =~ m/^[!=><]/ ) {
				my ( $operation, $operand ) = split( m/\s/, $value );
				$operand =~ s/^\s*(.+)\s*$/\1/;
				$searchParams{ $search_on } = [ $operation, $operand ];

			# Parse values that were given as a comma separated list
			} elsif( $value =~ m/,/ ) {
				$searchParams{ $search_on } = [ 'in', [ split( m/,/, $value ) ] ];
				
			# Parse normal search values.
			} else {

				# Determine whether this search path returns a reference.
				# A field may have the form: dataset_links.dataset The code block below
				# finds the package name of the right most method
				my @fields = split( /\./, $search_on );
				my $foreignClass = $package_name->getAccessorReferenceType( shift @fields );
				foreach my $single_field ( @fields ) {
					$foreignClass = $foreignClass->getAccessorReferenceType( $single_field );
				}
		
				# Do not insert wildcards in the search value if the search field is a reference
				if( $foreignClass ) {
					$searchParams{ $search_on } = $value;
				} else {
					$searchParams{ $search_on } = [ 'ilike', '%'.$value.'%' ];
				}
			}
		}
	}
	$searchParams{ __order } = $self->__sort_field();
	return %searchParams;
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

	Regardless what is returned, the secondary order field will be set to 'id'

=cut

sub __sort_field {
	my ($self, $search_fields, $default ) = @_;
	my $q = $self->CGI();
	my $primary_order_field;

	if( $q->param( '__order' ) && $q->param( '__order' ) ne '' ) {
		$primary_order_field = $q->param( '__order' );
	} elsif( grep( $_ eq 'name', @$search_fields ) ) {
		$q->param( '__order', 'name' );
		$primary_order_field = 'name';
	} elsif( grep( $_ eq 'Name', @$search_fields ) ) {
		$q->param( '__order', 'Name' );
		$primary_order_field = 'Name';
	} else {
		$q->param( '__order', $default );
		$primary_order_field = $default;
	}
	
	return [$primary_order_field, 'id'];
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
	$type = undef if exists $self->invisibleObjects()->{ $type };
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
			(map{ '@'.$_->name() => $_->label() } @globalSTs ), 
			'D' => '-- Dataset Semantic Types --',
			(map{ '@'.$_->name() => $_->label() } @datasetSTs ),
			'I' => '-- Image Semantic Types --',
			(map{ '@'.$_->name() => $_->label() } @imageSTs ),
			'F' => '-- Feature Semantic Types --',
			(map{ '@'.$_->name() => $_->label() } @featureSTs ),
		},
		-onchange => "if(this.value != '' && this.value != 'G' && this.value != 'D' && this.value != 'I' && this.value != 'F' ) { document.forms['$form_name'].submit(); } return false;"
	);
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
