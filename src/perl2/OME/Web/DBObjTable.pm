# OME/Web/DBObjTable.pm

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


package OME::Web::DBObjTable;

=pod

=head1 NAME

OME::Web::DBObjTable

=head1 DESCRIPTION

Build a table with information about any DBObject or attribute.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Log::Agent;

use OME;
use OME::Web::DBObjRender;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _default_Length } = 10;
	
	return $self;
}

{

my $menuText = "DB Browser";
sub getMenuText {
	my $self = shift;
	return $menuText unless ref($self);
	my $type = $self->CGI()->param( 'Type' )
		or die "Type not specified";
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	return "$common_name Browser";
}
}
#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    return "$common_name Table";
}

sub getPageBody {
	my $self = shift;
	return ('HTML', 
		$self->getTable( {
			actions     => ['Search'],
			width => '100%',
		})
	);
}

=head2 getTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a table from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my $table      = $tableMaker->getTable( \%options );

	# or use search options to make a table (not tested, but might work ;)
	my $table      = $tableMaker->getTable( \%options, $type, \%search_options );

	# or use a list of objects to make a table
	my $table      = $tableMaker->getTable( \%options, $type, \@obj_array );

recognized %options are:
	noSearch
	Length
	embedded_in_form => $form_name
	title
	width
	actions
	excludefields => { field_name => undef }

=cut

sub getTable {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $object_count, $options, 
	     $pagingText, $form_name, $title, $display_type,
	     $common_name, $formal_name, $ST ) =
		$self->__parseParams( @_ );

	# build table
	my $html;
	
	my @fieldNames = OME::Web::DBObjRender->getFieldNames( $formal_name );
	@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
		if exists $options->{excludeFields};
	my %labels     = OME::Web::DBObjRender->getFieldLabels( $formal_name, \@fieldNames );
	my %searches   = OME::Web::DBObjRender->getSearchFields( $formal_name, \@fieldNames );
	my @records    = OME::Web::DBObjRender->render( $objects, 'html', \@fieldNames );
	
	# table data
	my @table_data;
	foreach my $record ( @records ) {
		push( @table_data, 
			$q->td( { class => 'ome_td' }, 
				[ map( $record->{$_}, @fieldNames ) ] 
			)
		);
	}
	
	# allow searches ?
	my $allowSearch;
	$allowSearch = 1
		if( defined $options->{ actions } and 
		    scalar( grep( m/Search/o, @{ $options->{ actions } }) ) > 0
		);

	# allow paging ?
	my $allowPaging = ( $pagingText ? 1 : 0 );
	
	# column headers
	my @columnHeaders;
	if( $options->{ embedded_in_form } ) {
		@columnHeaders = map( $labels{ $_ }, @fieldNames );
	} else {
		my $skipColumn;
		if( $q->param( 'action' ) =~ m/^OrderBy_$formal_name/ ) {
			($skipColumn = $q->param( 'action' ) ) =~ s/^OrderBy_$formal_name//;
		} else {
			$skipColumn = 'id';
		}
		@columnHeaders = map( ($_ ne $skipColumn ? 
			$q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='OrderBy_$formal_name".$_."'; document.forms['$form_name'].submit(); return false",
				},
				$labels{ $_ }
			) : 
			$labels{ $_ } )
		, @fieldNames );
	}
		
	$html = $q->startform( { -name => $form_name })
		unless $options->{ embedded_in_form };
	$html .=
		$q->table( { -class => 'ome_table', width => $options->{width} },
			# Table title
			$q->caption( $title ),
			$q->Tr( [
				# table descriptor
				$q->td( { -class => 'ome_td', -colspan => scalar( @fieldNames ), -align => 'right' }, 
					$q->span( { -class => 'ome_widget' }, join( " | ", (
						$display_type, 
						( $allowPaging ? $pagingText : ()), 
						( $allowSearch ? $self->__getActionButton( 'Search', $form_name ) : () )
					) ) )
				), 
				# Column headers
				$q->td( { -class => 'ome_td' }, \@columnHeaders ),
				# Search fields
				( $allowSearch ? 
					$q->td( { -class => 'ome_td' },
						[ map( $searches{ $_ }, @fieldNames ) ]
					) :
					()
				),
				# Table data
				@table_data,
			]
			)
		);
	$html .= 
		$pagingText.
		$q->hidden({-name => "PageNum_$formal_name", -default => $q->param( "PageNum_$formal_name" ) })
		if( $allowPaging );
	$html .= 
		$q->hidden({-name => 'action', -default => ''}).
		$q->hidden({-name => 'Type', -default => $q->param( "Type" ) }).
		$q->endform()
		unless $options->{ embedded_in_form };

	return $html;
}

=head2 getList

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a list from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my $list      = $tableMaker->getList( \%options );

	# or use search options to make a list (not tested, but might work ;)
	my $list      = $tableMaker->getList( \%options, $type, \%search_options );

	# or use a list of objects to make a list
	my $list      = $tableMaker->getList( \%options, $type, \@obj_array );

=cut

sub getList {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $object_count, $options, 
	     $pagingText, $form_name, $title, $display_type,
	     $common_name, $formal_name, $ST ) =
		$self->__parseParams( @_ );

	# build table
	my $html;
	
	my @object_refs = OME::Web::DBObjRender->getRefsToObject( $objects, 'html'  );
	
	# allow paging ?
	my $allowPaging = ( $pagingText ? 1 : 0 );
		
	$html = $q->startform( { -name => $form_name })
		unless $options->{ embedded_in_form };
	$html .=
		$q->table( { -class => 'ome_table', width => $options->{width} },
			# Table title
			$q->caption( $title ),
			$q->Tr( [
				# table descriptor
				$q->td( { -class => 'ome_td', -align => 'right' }, 
					$q->span( { -class => 'ome_widget' }, join( " | ", (
						$display_type, 
						( $allowPaging ? $pagingText : ()), 
					) ) )
				), 
				# Table data
				map( 
					$q->td( { -class => 'ome_td', -align => 'right' }, $_ ),
					@object_refs
				),
			]
			)
		);
	$html .= 
		$pagingText.
		$q->hidden({-name => "PageNum_$formal_name", -default => $q->param( "PageNum_$formal_name" ) })
		if( $allowPaging );
	$html .= 
		$q->hidden({-name => 'action', -default => ''}).
		$q->hidden({-name => 'Type', -default => $q->param( "Type" ) }).
		$q->endform()
		unless $options->{ embedded_in_form };

	return $html;
}

sub __parseParams {
	my ($self, $options, $type, $param3 ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();
	my $mode;
	if( not defined $type ){
		$mode = 'cgi';
	} elsif( ref($param3) eq 'ARRAY' ){
		$mode = 'objects';
	} elsif( ref($param3) eq 'HASH' ){
		$mode = 'search';
	}
	die "function called in unknown mode" 
		unless defined $mode;
	my (%searchParams, @objects, $object_count);

	# retrieve mode specific parameters
	if( $mode eq 'search' ) {
		%searchParams = %$param3;
	} elsif( $mode eq 'objects' ) {
		@objects = @$param3;
		$options->{ noSearch } = 1;
	} elsif( $mode eq 'cgi' ) {
		$type = $q->param( 'Type' )
			or die "url parameter Type not specified";

		# collect search params
		%searchParams = map{ $_ => $q->param( $_ ) } grep( m/^($type)_/o, $q->param( ) );
		foreach my $key (keys %searchParams) {
			# get the key's Real name
			(my $newkey = $key) =~ s/^($type)_//;
			# copy the key into the real name unless the value is blank
			$searchParams{ $newkey } = $searchParams{ $key }
				unless not defined $searchParams{ $key } or $searchParams{ $key } eq '';
			# delete the old key
			delete $searchParams{ $key };
		}
	}

	# PAGING: prepare offset & limit
	$options->{ Length } = $self->{ _default_Length }
		unless $options->{ Length };
	$searchParams{ __offset } = ( $q->param( "PageNum_$type" ) ? $q->param( "PageNum_$type" ) : 0 );
	$searchParams{ __offset } += 1
		if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageForward_$type" );
	$searchParams{ __offset } -= 1
		if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageBack_$type" );
	$q->param( -name => "PageNum_$type", -value => $searchParams{ __offset } );
	$searchParams{ __offset } *= $options->{ Length };

	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

	# collect SortOn
	my $orderBy = 'id';
	if( $q->param( 'action' ) and $q->param( 'action' ) =~ m/^OrderBy_$formal_name/ ) {
		($orderBy = $q->param( 'action' ) ) =~ s/^OrderBy_$formal_name//;
	}

	# get objects
	if( $mode eq 'cgi' or $mode eq 'search' ) {
		@objects = $factory->findObjectsLike( $formal_name, %searchParams, __limit => $options->{ Length }, __order => $orderBy );
		$object_count = $factory->countObjectsLike( $formal_name, %searchParams );
	} else {
		$object_count = scalar( @objects );
		@objects = splice( @objects, $searchParams{ __offset }, $options->{ Length } );
	}
	
	# make form name, title, display type
	my $form_name   = ( $options->{ embedded_in_form } or $common_name."_TABLE" );
	my $title       = ( $options->{ title } or $common_name );
	my $display_type  =
		"Displaying ".
		( $ST ?
			$q->a( { href => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id() },
				   $common_name ) :
			$common_name
		);
	
	# paging
	my $pagingText;
	my $currentPage = ( defined $q->param( "PageNum_$formal_name" ) ? $q->param( "PageNum_$formal_name" ) + 1 : 1 );
	my $numPages = POSIX::ceil( $object_count / $options->{ Length });
	if( $object_count and $numPages > 1) {
		$pagingText  = sprintf( "%u of %u ", $currentPage, $numPages);
		$pagingText .= $q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='PageBack_$formal_name'; document.forms['$form_name'].submit(); return false",
				}, 
				'<'
			)." "
			if $currentPage > 1;
		$pagingText .= "\n".$q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='PageForward_$formal_name'; document.forms['$form_name'].submit(); return false",
				}, 
				'>'
			)
			if $currentPage < $numPages;
	}
	
	return ( \@objects, $object_count, $options, 
	         $pagingText, $form_name, $title, $display_type,
	         $common_name, $formal_name, $ST )
}

sub __getOptionsTD {
	my ($self, $options, $span, $form_name) = @_;
	my $q = $self->CGI();

	# Build our buttons
	my $option_buttons = join( ' | ', 
		map( $self->__getActionButton( $_, $form_name ), @$options ) );

	# Build our table and return it
	if ($option_buttons) {
    	return $q->td( {
				-colspan => $span,
				-align => 'right',
				-bgcolor => '#EFEFEF',
				-class => 'ome_menu_td',
			},
			$option_buttons,
		);
	}

	return;
}

sub __getActionButton {
	my ($self, $action, $form_name) = @_;
	my $q = $self->CGI();
	return 
		$q->a( 
			{
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='$action'; document.forms['$form_name'].submit(); return false",
				-class => 'ome_widget'
			}, 
			$action 
		);
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
