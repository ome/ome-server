# OME/Web/NewTable.pm

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


package OME::Web::NewTable;

=pod

=head1 NAME

OME::Web::NewTable

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
use OME::Web::RenderData;

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
	
	$self->{ _default_table_length } = 7;
	
	return $self;
}

sub getMenuBuilder { return undef }  # No menu

sub getHeaderBuilder { return undef }  # No header

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
			table_width => '100%',
		})
	);
}

=head2 getTable

# make a table
	my $tableMaker = OME::Web::NewTable->new( CGI => $cgi );
	# make a table from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my $table      = $tableMaker->getTable( \%table_options );
	# or use search options to make a table (not tested, but might work ;)
	my $table      = $tableMaker->getTable( \%table_options, $type, \%search_options );
	# or use a list of objects to make a table
	my $table      = $tableMaker->getTable( \%table_options, $type, \@obj_array );

=cut

sub getTable {
	my ($self, $table_options, $type, $param3 ) = @_;
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
		$table_options->{ noSearch } = 1;
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

	# prepare offset & limit
	$table_options->{ table_length } = $self->{ _default_table_length }
		unless $table_options->{ table_length };
	$searchParams{ __offset } = ( $q->param( "PageNum_$type" ) ? $q->param( "PageNum_$type" ) : 0 );
	$searchParams{ __offset } += 1
		if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageForward_$type" );
	$searchParams{ __offset } -= 1
		if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageBack_$type" );
	$q->param( -name => "PageNum_$type", -value => $searchParams{ __offset } );
	$searchParams{ __offset } *= $table_options->{ table_length };

	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

	# get objects
	if( $mode eq 'cgi' or $mode eq 'search' ) {
		if( $ST ) {
			@objects      = $factory->findAttributesLike( $ST, %searchParams, __limit => $table_options->{ table_length } );
			$object_count = $factory->countAttributesLike( $ST, %searchParams );
		} else {
			@objects = $factory->findObjectsLike( $package_name, %searchParams, __limit => $table_options->{ table_length } );
			$object_count = $factory->countObjectsLike( $package_name, %searchParams );
		}
	} else {
		$object_count = scalar( @objects );
		@objects = splice( @objects, $searchParams{ __offset }, $table_options->{ table_length } );
	}

	# build table
	my $html;

	# make form name & table label
	my $form_name = ( $table_options->{ embedded_in_form } or $common_name."_TABLE" );
	my $table_label;
	if( $table_options->{ title } ) {
		my $common_name_text = $q->font( { class => 'ome_header_label' }, $common_name);
		$table_label = $q->font( { class => 'ome_header_title' }, " ".$table_options->{ title });
		$table_label .= 
		" (".
		( $ST ?
			$q->a( { href => 'serve.pl?Page=OME::Web::ObjectDetail&Type=OME::SemanticType&ID='.$ST->id() },
				   $common_name_text ) :
			$common_name_text
		).
		")";
	} else {
		my $common_name_text = $q->font( { class => 'ome_header_title' }, $common_name);
		$table_label = ( $ST ?
			$q->a( { href => 'serve.pl?Page=OME::Web::ObjectDetail&Type=OME::SemanticType&ID='.$ST->id() },
				   $common_name_text ) :
			$common_name_text
		);
	}

	# paging
	my $pagingText;
	my $currentPage = $q->param( "PageNum_$type" ) + 1;
	my $numPages = POSIX::ceil( $object_count / $table_options->{ table_length });
	if( $object_count and $numPages > 1) {
		$pagingText  = sprintf( "Table %u of %u ", $currentPage, $numPages);
		$pagingText .= $q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='PageBack_$type'; document.forms['$form_name'].submit(); return false",
				}, 
				'<'
			)." "
			if $currentPage > 1;
		$pagingText .= "\n".$q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='PageForward_$type'; document.forms['$form_name'].submit(); return false",
				}, 
				'>'
			)
			if $currentPage < $numPages;
	}

	#
	my @fieldNames = OME::Web::RenderData->getFieldNames( $formal_name );
	my %labels     = OME::Web::RenderData->getFieldLabels( $formal_name, \@fieldNames );
	my %searches   = OME::Web::RenderData->getSearchFields( $formal_name, \@fieldNames );
	my @records    = OME::Web::RenderData->render( \@objects, 'html', \@fieldNames );
	
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
		if( $mode ne 'objects' and
		    defined $table_options->{ actions } and 
		    scalar( grep( m/Search/o, @{ $table_options->{ actions } }) ) > 0
		);

	# allow paging ?
	my $allowPaging = 1;
		
	$html = $q->startform( { -name => $form_name })
		unless $table_options->{ embedded_in_form };
	$html .=
		$q->table( { class => 'ome_table', width => $table_options->{table_width} },
			# Table title
			$q->caption( $table_label ),
			$q->Tr( [
				# Table headers
				$q->td( { class => 'ome_td' },
					[ map( $labels{ $_ }, @fieldNames ) ]
				),
				# Search fields
				( $allowSearch ? 
					$q->td( { class => 'ome_td' },
						[ map( $searches{ $_ }, @fieldNames ) ]
					) :
					()
				),
				# Table data
				@table_data,
				( $allowSearch ?
					$self->__getOptionsTD( [ 'Search' ], scalar( @fieldNames ), $form_name ) :
					()
				)
			]
			)
		);
	$html .= 
		$pagingText.
		$q->hidden({-name => "PageNum_$type", -default => $q->param( "PageNum_$type" ) })
		if( $allowPaging );
	$html .= 
		$q->hidden({-name => 'action', -default => ''}).
		$q->hidden({-name => 'Type', -default => $q->param( "Type" ) }).
		$q->endform()
		unless $table_options->{ embedded_in_form };

	return $html;
}

sub __getOptionsTD {
	my ($self, $options, $span, $form_name) = @_;
	my $q = $self->CGI();

	# Build our buttons
	my $option_buttons = join( ' | ', 
	 	map( 
			$q->a( {
				-href => "#",
				-onClick => "document.forms['$form_name'].action.value='$_'; document.forms['$form_name'].submit(); return false",
				-class => 'ome_widget'
			}, $_ ),
			@$options
		)
	);

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

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
