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

Build a table with information about any DBObject or attribute.

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
	
	$self->{ _default_limit } = 27;
	
	$self->{ _types } = [
		{ formal_name => 'OME::Image', common_name => 'Images' },
		{ formal_name => 'OME::Dataset', common_name => 'Datasets' },
		{ formal_name => 'OME::Project', common_name => 'Projects' },
		{ formal_name => 'OME::ModuleExecution', common_name => 'Module Executions' },
		{ formal_name => 'OME::Module', common_name => 'Modules' },
		{ formal_name => 'OME::AnalysisChain', common_name => 'Analysis Chains' },
		{ formal_name => 'OME::AnalysisChainExecution', common_name => 'Analysis Chain Executions' },
	];
	$self->{ _modes } = [
		{ mode => 'tiled_list', mode_title => 'Summaries' },
		{ mode => 'tiled_ref_list', mode_title => 'Names' },
	];
	
	return $self;
}

sub getMenuText {
	my $self = shift;
	my $menuText = "Search";
	return $menuText unless ref($self);

	my $type = $self->CGI()->param( 'Type' );
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
		return "$common_name Search";
    }
	return $menuText;
}

#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	return "OME Search";
	my $self = shift;
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' );
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    	return "$common_name Search";
    }
}

sub getPageBody {
	my $self = shift;	
	my $q    = $self->CGI();

	# load Types to search on	
	my $type = $q->param( 'Type' );
	my $types_data = $self->{ _types };
	foreach( @$types_data ) {
		$_->{ selected } = 'selected'
			if $_->{formal_name} eq $type;
	}
	# load Modes to show results with
	my $display_mode = ( $q->param( 'Mode' ) || 'tiled_list' );
	my $modes_data = $self->{ _modes };
	foreach( @$modes_data ) {
		$_->{ checked } = 'checked'
			if $_->{mode} eq $display_mode;
	}
	my %tmpl_data = ( types_loop => $types_data, modes_loop => $modes_data,  );
	
	my $html = $q->startform();
	
	# If a type is selected, write in the search fields.
	# Also search if search fields are ready.
	if( $type && $type ne '') {
		my $render = $self->Renderer();
		my $search_names;
		
 		my $search_type = $q->param( 'search_type' );
		my @cgi_search_names = $q->param( 'search_names' );
		if( grep( /^accessor$/, @cgi_search_names ) ) {
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
			my ( $typeToAccessFrom, $idToAccessFrom, $accessorMethod ) = split( /,/, $q->param( 'accessor' ) );
			my $objectTaAccessFrom = $self->Session()->Factory()->loadObject( $typeToAccessFrom, $idToAccessFrom )
				or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
			$tmpl_data{ accessor_descriptor } = "Showing $common_name(s) associated with ".$render->getRef( $objectTaAccessFrom, 'html' ).".";
		} else {
			my @fields = $render->getFields( $type, 'summary' );
			my $form_fields;
			($form_fields, $search_names) = $render->getSearchFields( $type, \@fields );
			my %field_titles = $render->getFieldTitles( $type, \@fields );
			# clear stale search fields
			# (search_type stores the type that search fields were meant for.)
# FIXME: this does not work
# 	 		unless( !$search_type || $type eq $search_type ) {
# 				$q->param( $_, '' )
# 					foreach( values %$search_names);
# 			}
			
			# add search fields.
			my $order = $self->_get_order( $search_names->{ $fields[0] }, $search_names );
			foreach my $field( @fields ) {
				my $sort_up = "<a href='javascript: document.forms[0].elements[\"__order\"].value = \"".
					$search_names->{ $field }.
					"\"; document.forms[0].submit();' title='Sort results by ".
					$field_titles{ $field }." in increasing order'".
					( $order && $order eq $search_names->{ $field } ?
						" class = 'ome_active_sort_arrow'" : ''
					).'>';
				my $sort_down = "<a href='javascript: document.forms[0].elements[\"__order\"].value = \"!".
					$search_names->{ $field }.
					"\"; document.forms[0].submit();' title='Sort results by ".
					$field_titles{ $field }." in increasing order'".
					( $order && substr( $order, 1 ) eq $search_names->{ $field } ?
						" class = 'ome_active_sort_arrow'" : ''
					).'>';
	
				push( @{ $tmpl_data{search_fields_loop} }, {
					field_label  => $field_titles{ $field },
					form_field   => $form_fields->{ $field },
					sort_up      => $sort_up, 
# FIXME: factory doesn't support this (yet)
#					sort_down    => $sort_down,
				} ) if $form_fields->{ $field };
			}
		}
		
		# SEARCH & RENDER 		
		my ($objects, $paging_text ) = $self->search();
		my $rendering = $render->renderArray( $objects, $display_mode, { _pager_text => $paging_text } );
		# render & print results
		$tmpl_data{ results } = $rendering;

		# Reset fielse if the search type was just switched.
 		unless( !$search_type || $type eq $search_type ) {
 			$q->param( '__order', '' );
 			$q->param( '__offset', '' );
 			$q->param( 'search_names', values %$search_names);
 			$q->param( 'search_type', $type );
 		}

		# gotta have hidden fields
		$html .= "\n".
			# tell the form what search fields are on it and what type they are for.
			$q->hidden( -name => 'search_names', -default => [values %$search_names] ).
			$q->hidden( -name => 'search_type', -default => $type ).
			# these are needed for paging
			$q->hidden( -name => '__order' ).
			$q->hidden( -name => '__offset' ).
			$q->hidden( -name => 'last_order_by' ).
			$q->hidden( -name => 'action' );
		
	}
	
	my $tmpl_dir = $self->Session()->Configuration()->ome_root().'/html/Templates/';
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
	$searchParams{ __order } = $self->_get_order();
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
	my $action = $q->param( 'action' ) ;
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
					-href => "javascript: document.forms[0].action.value='FirstPage'; document.forms[0].submit();",
					}, 
					'<<',
				).' '
				if ( $currentPage > 1 and $numPages > 2 );
			$pagingText .= $q->a( {
					-title => "Previous Page",
					-href => "javascript: document.forms[0].action.value='PrevPage'; document.forms[0].submit();",
					}, 
					'<'
				)." "
				if $currentPage > 1;
			$pagingText .= sprintf( "%u of %u ", $currentPage, $numPages);
			$pagingText .= "\n".$q->a( {
					-title => "Next Page",
					-href  => "javascript: document.forms[0].action.value='NextPage'; document.forms[0].submit();",
					}, 
					'>'
				)." "
				if $currentPage < $numPages;
			$pagingText .= "\n".$q->a( {
					-title => "Last Page",
					-href  => "javascript: document.forms[0].action.value='LastPage'; document.forms[0].submit();",
					}, 
					'>>'
				)
				if( $currentPage < $numPages and $numPages > 2 );
		}
	}
	
# 	$self->{pagingText}    = $pagingText;
# 	$self->{common_name}   = $common_name;
# 	$self->{formal_name}   = $formal_name;
# 	$self->{ST}            = $ST;
# 	$self->{search_params} = \%searchParams;
	
	return ( \@objects, $pagingText );
}

sub _get_order {
	my ($self, $first_search_name, $search_names ) = @_;
	my $q = $self->CGI();

	if( $q->param( '__order' ) && $q->param( '__order' ) ne '' ) {
		return $q->param( '__order' );
	}
	
	if( exists $search_names->{ 'name' } ) {
		$q->param( '__order', 'name' );
		return 'name';
	} elsif( exists $search_names->{ 'Name' } ) {
		$q->param( '__order', 'Name' );
		return 'Name';
	} else {
		$q->param( '__order', $first_search_name );
		return $first_search_name;
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
