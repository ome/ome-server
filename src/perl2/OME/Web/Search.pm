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
	
	# _published_search_types gets translated to the 'Look for:' drop-down list
	$self->{ _published_search_types } = [
		'OME::Project', 
		'OME::Dataset', 
		'OME::Image', 
		'OME::ModuleExecution', 
		'OME::Module', 
		'OME::AnalysisChain', 
		'OME::AnalysisChainExecution',
	];

	# _display_modes lists formats the results can be displayed in. 
	#	mode maps to a template name. 
	#	mode_title is presented to the user.
	$self->{ _display_modes } = [
		{ mode => 'tiled_list', mode_title => 'Summaries' },
		{ mode => 'tiled_ref_list', mode_title => 'Names' },
	];
		
	return $self;
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
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' );
	$type = $q->param( 'Locked_Type' ) unless $type;
	my $html = $q->startform();
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
	window.opener.document.forms[0].$return_to.value = '$ids';
	window.opener.document.forms[0].submit();
	window.close();
</script>
END_HTML
		return( 'HTML', $html );
	}

	# load Types to search on	
	foreach my $formal_name ( @{ $self->{ _published_search_types } } ) {
		my ($package_name, $common_name, undef, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
		my $type_data;
		$type_data->{ formal_name } = $formal_name;
		$type_data->{ common_name } = $common_name;
		$type_data->{ selected } = 'selected'
			if( $type && $formal_name eq $type );
		push( @{ $tmpl_data{ types_loop } }, $type_data );
	}
	
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
		
		# accessor mode
		if( grep( /^accessor$/, @cgi_search_names ) ) {
			my ( $typeToAccessFrom, $idToAccessFrom, $accessorMethod ) = split( /,/, $q->param( 'accessor' ) );
			my $objectTaAccessFrom = $self->Session()->Factory()->loadObject( $typeToAccessFrom, $idToAccessFrom )
				or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
			$tmpl_data{ accessor_descriptor } = "Showing $common_name(s) associated with ".$render->render( $objectTaAccessFrom, 'ref' ).".";
		
		# search mode
		} else {
			my @fields = $render->getFields( $type, 'summary' );
			my ($form_fields, $search_paths) = $render->getSearchFields( $type, \@fields );
			my %field_titles = $render->getFieldTitles( $type, \@fields );
 			$q->param( 'search_names', values %$search_paths);
			
			# add search fields & sort buttons to template data
			my $order = $self->__sort_field( $search_paths, $search_paths->{ $fields[0] });
			foreach my $field( @fields ) {
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
	
				push( @{ $tmpl_data{search_fields_loop} }, {
					field_label  => $field_titles{ $field },
					form_field   => $form_fields->{ $field },
					sort_up      => $sort_up, 
					sort_down    => $sort_down,
				} ) if $form_fields->{ $field };
			}
		}
		
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
			$q->hidden( -name => 'page_action' ).
			# This is used to retain selected objects across pages.
			$q->hidden( -name => 'selected_objects' );
		
	}
	
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my $tmpl = HTML::Template->new( filename => 'Search.tmpl', path => $tmpl_dir );
	$tmpl->param( %tmpl_data );

	$html .= 
		$tmpl->output().
		$q->endform();

	return ( 'HTML', $html );	
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
	if( $q->param( $search_on ) && $q->param( $search_on ) ne '') {
			$searchParams{ $search_on } = $q->param( $search_on );
			if( $searchParams{ $search_on } =~ m/,/) {
				if( $search_on ne 'accessor' ) {
					$searchParams{ $search_on } = [ 'in', [ split( m/,/, $searchParams{ $search_on } ) ] ];
				} else {
					$searchParams{ $search_on } = [ split( m/,/, $searchParams{ $search_on } ) ];
				}
			}
		}
	}

	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	my ($objectTaAccessFrom, $accessorMethod);

	# count Objects
 	if( $searchParams{ 'accessor' } ) {
 		my ( $typeToAccessFrom, $idToAccessFrom);
 		( $typeToAccessFrom, $idToAccessFrom, $accessorMethod ) = @{ $searchParams{ 'accessor' } };
 		$objectTaAccessFrom = $factory->loadObject( $typeToAccessFrom, $idToAccessFrom )
 			or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
 		$typeToAccessFrom->getColumnType( $accessorMethod )
 			or die "$accessorMethod is an unknown accessor for $typeToAccessFrom";
 		my $countAccessor = "count_".$accessorMethod;
 		$object_count = $objectTaAccessFrom->$countAccessor();
 	} else {
		$object_count = $factory->countObjectsLike( $formal_name, %searchParams );
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
		if( $action eq 'FirstPage' ) {
			$searchParams{ __offset } = 0;
		} elsif( $action eq 'PrevPage' ) {
			$searchParams{ __offset } = ( $currentPage - 1 ) * $searchParams{ __limit };
		} elsif( $action eq 'NextPage' ) {
			$searchParams{ __offset } = ( $currentPage + 1 ) * $searchParams{ __limit };
		} elsif( $action eq 'LastPage' ) {
			$searchParams{ __offset } = ($numPages - 1) * $searchParams{ __limit };
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


	# get objects
	# Use accessor
 	if( $searchParams{ 'accessor' } ) {
 		@objects = $objectTaAccessFrom->$accessorMethod(
 			( $searchParams{ __limit } ? 
 				(__limit => $searchParams{ __limit }) : 
 				()
 			),
 			( $searchParams{ __offset } ?
 				( __offset => $searchParams{ __offset } ) :
 				()
 			)
 		);
 	# use the search parameters
 	} else {
		@objects = $factory->findObjectsLike( $formal_name, %searchParams );
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
	OME::Web::DBObjRender->getSearchFields()

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

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
