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
use OME;
our $VERSION = $OME::VERSION;
use CGI;
use Log::Agent;
use Carp;
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

sub getMenuText {
	my $self = shift;
	my $menuText = "DB Browser";
	return $menuText unless ref($self);

	my $type = $self->CGI()->param( 'Type' );
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
		return "$common_name Browser";
    }
	return $menuText;
}

#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' );
	if( $type ) {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    	return "$common_name Table";
    }
    return "Joined Table";
}

sub getPageBody {
	my $self = shift;
	my $q    = $self->CGI();
	
	if( $q->param( "Type" ) ) {
		if( $q->param( "Format" ) eq 'txt' ) {
			return ('TXT', 
				$self->getTextTable( {
				})
			);
		} else {
			return ('HTML', 
				$self->getTable( {
					actions       => ['Search'],
					width         => '100%',
				})
			);
		}
	} elsif( $q->param( "Types" ) ) {
		if( $q->param( "Format" ) eq 'txt' ) {
			return ('TXT', 
				$self->getJoinTextTable( {
				})
			);	
		} else {
			return ('HTML', 
				$self->getJoinTable( {
#					actions       => ['Search'],
#					width         => '100%',
				})
			);
		}
	}
}

=head2 getTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a table from CGI parameters 'Type' and search params. CGI
	# search parameters should follow the format $type.'_'.$searchKey
	my $table      = $tableMaker->getTable( \%options );

	# or use search options to make a table
	my $table      = $tableMaker->getTable( \%options, $type, \%search_options );

	# or use a list of objects to make a table
	my $table      = $tableMaker->getTable( \%options, $type, \@obj_array );

Table content can be retrieved from DBObject accessor methods. To do
this, add a search parameter {'accessor' => [ $typeToAccessFrom,
$idToAccessFrom, $accessorMethod ] }. $typeToAccessFrom and
$idToAccessFrom will be used to load a DBObject that $accessorMethod
will be called from. The advantage to using this feature is only content
being displayed is loaded.

recognized %options are:
	noSearch         => 1|0                          # 1 disables searches
	select_column    => 1|0                          # 1 inserts a select column. 
	                                                 # name will default to 'Selected_'.$formal_name
	select_name      => $select_column_name          # overrides default name. if specified,
	                                                 # select_column is set to 1.
	Length           => $num_items_per_table
	embedded_in_form => $form_name
	title            => 'table_title'
	width            => 'table_width'
	actions          => [ action_button_name, ... ]
	excludefields    => { field_name => undef, ... }

a Length of 0 or less is considered to be 'no limit'. an undef Length is
assumed to be the default Length of 10.

=cut

sub getTable {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @_ );
	my $display_type = $self->{display_type};
	my $form_name    = $self->{form_name};
	my $pagingText   = $self->{pagingText};

	# build table
	my $html;
	
	my @fieldNames = OME::Web::DBObjRender->getFieldNames( $formal_name );
	@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
		if exists $options->{excludeFields};
	my %labels     = OME::Web::DBObjRender->getFieldLabels( $formal_name, \@fieldNames, 'txt' );
	my %searches   = OME::Web::DBObjRender->getSearchFields( $formal_name, \@fieldNames );
	my @records    = OME::Web::DBObjRender->render( $objects, 'html', \@fieldNames );

	# table data
	my @table_data;
	foreach my $record ( @records ) {
		my $table_cells;
		$table_cells = 
			$q->td( { -class => 'ome_td', -align => 'center'},
				$q->checkbox( {
					-name    => $options->{ select_name } or 'Selected_'.$formal_name, 
					-value   => $record->{_id}, 
					-checked => ''} )
			)
			if( $options->{ select_column } );
		$table_cells .= 
			$q->td( { -class => 'ome_td' }, 
				[ map( $record->{$_}, @fieldNames ) ] 
			);
		push( @table_data, $table_cells );
	}

	# allow searches ?
	my ( $allowSearch, $searchFieldRow );
	if( defined $options->{ actions } and 
		scalar( grep( m/^Search$/o, @{ $options->{ actions } }) ) > 0 ) {
		$allowSearch = 1;
		$searchFieldRow = $q->td( { -class => 'ome_td' }, '' )
			if( $options->{ select_column } );
		$searchFieldRow .= $q->td( { -class => 'ome_td' },
			[ map( $searches{ $_ }, @fieldNames ) ]
		);
	}
	# allow paging ?
	my $allowPaging = ( $pagingText ? 1 : 0 );
	
	# column headers
	my @columnHeaders;
	# do not enable column sorting
	if( $options->{ embedded_in_form } ) {
		@columnHeaders = map( $labels{ $_ }, @fieldNames );
		unshift( @columnHeaders, 'Select' )
			if( $options->{ select_column } );
	# enable column sorting. make the column that records are currently sorted on inactive.
	} else {
		my $inactiveColumn;
		if( $q->param( 'action' ) =~ m/^OrderBy_$formal_name/ ) {
			($inactiveColumn = $q->param( 'action' ) ) =~ s/^OrderBy_$formal_name//;
		} else {
			$inactiveColumn = 'id';
		}
		@columnHeaders = map( ($_ ne $inactiveColumn ? 
			$q->a( 
				{ -href => "#", -onClick => "document.forms['$form_name'].action.value='OrderBy_$formal_name".$_."'; document.forms['$form_name'].submit(); return false", },
				$labels{ $_ }
			) : 
			$labels{ $_ } )
		, @fieldNames );
		unshift( @columnHeaders, 'Select' )
			if( $options->{ select_column } );
	}
	
	# Build the table
	$html = $q->startform( { -name => $form_name })
		unless $options->{ embedded_in_form };
	$html .=
		$q->table( {
				-class => 'ome_table',
				-width => $options->{width},
				-cellpadding => '4',
				-cellspacing => '1',
				-border => '0',
			},
			# Table title
			$q->caption( $title ),
			$q->Tr( [
				# table descriptor
				$q->td( { -class => 'ome_td', -colspan => scalar( @columnHeaders ), -align => 'right' }, 
					$q->span( { -class => 'ome_widget' }, join( " | ", (
						$display_type, 
						$q->a( { -href => 
							$self->pageURL('OME::Web::DBObjTable', { 
								%{ $self->{__params} },
								Format => 'txt',
							} ) }, "Download as txt" ),
						( $allowPaging ? $pagingText : ()), 
						( $allowSearch ? $self->__getActionButton( 'Search', $form_name ) : () )
					) ) )
				), 
				# Column headers
				$q->td( { -class => 'ome_td' }, \@columnHeaders ),
				# Search fields
				( $allowSearch ? $searchFieldRow : () ),
				# Table data
				@table_data,
			]
			)
		);
	$html .= 
		'<nobr>'.$pagingText.'</nobr>'.
		$q->hidden({-name => "PageNum_$formal_name", -default => $q->param( "PageNum_$formal_name" ) })
		if( $allowPaging );
	$html .= 
		$q->hidden({-name => 'action', -default => ''}).
		join( "\n", map( 
			$q->hidden({-name => $_, -default => $self->{__params}->{$_} }),
			keys %{ $self->{__params} } )
		).
		$q->endform()
		unless $options->{ embedded_in_form };

	return $html;
}

=head2 getJoinTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# or use a list of objects to make a table
	my $table      = $tableMaker->getTable( \%options, { $type => \@obj_array, ... } );



recognized %options are:
#	select_column    => 1|0                          # 1 inserts a select column. 
	                                                 # name will default to 'Selected_'.$formal_name
#	select_name      => $select_column_name          # overrides default name. if specified,
	                                                 # select_column is set to 1.
#	Length           => $num_items_per_table
#	embedded_in_form => $form_name
	title            => 'table_title'
#	width            => 'table_width'
#	actions          => [ action_button_name, ... ]
	excludefields    => { field_name => undef, ... }

a Length of 0 or less is considered to be 'no limit'. an undef Length is
assumed to be the default Length of 10.

=cut

sub getJoinTable {
	my $self = shift;
	my $q       = $self->CGI();
	
	my ( $options, %joined_groups ) = $self->__getJoinedGroups( @_ );
	# { joining_group_id => {
	#	field_names => [...], # doubles as column order
	#	records     => { joining_record_id => { field_name => value, ... }, ... }, # joined records
	#	common_names => [...], 
	#	formal_names => [...],
	# }, ... }

	# build tables
	my @tables;
	foreach my $j_group ( values( %joined_groups ) ) {
		my $table;
		
		# table content
		my @records = values( %{ $j_group->{records} } );
		my @fieldNames = @{ $j_group->{ field_names } };
		my %labels = %{ $j_group->{ field_labels } };
		my @headers = @{ $j_group->{ col_header } };		
		my $title = "Displaying ".join( ', ', @{ $j_group->{ titles } } ).
			join( '', map( $q->a( { -name => $_ }, ' ' ), @{ $j_group->{ titles } } ) );
		
		# translate to html
		my @table_data;
		foreach my $record ( @records ) {
			my $table_cells = 
				$q->td( { -class => 'ome_td' }, 
					[ map( $record->{$_}, @fieldNames ) ] 
				);
			push( @table_data, $table_cells );
		}
	
		# column descriptors
		my @columnHeaders;
		foreach my $entry( @headers ) {
			my ($name, $colspan) = @$entry;
			push( @columnHeaders, $q->td( { -class => 'ome_td', -colspan => $colspan, -align => 'center' }, $name ) );
		}
		my @columnLabels = map( $q->td( { -class => 'ome_td' }, $labels{ $_ } ), @fieldNames );
		
		# link to text table
		my $txt_table_link = 
			$q->a( { -href => 
				$self->pageURL('OME::Web::DBObjTable', { 
					%{ $self->{__params} },
					Format => 'txt',
				} ) }, "Download as txt"
			);
		
		
		# Build the table
		$table .=
			$txt_table_link.
			$q->table( { -class => 'ome_table', width => $options->{width} },
				# Table title
				$q->caption( $title ),
				$q->Tr( [
					# Column headers
					join( '', @columnHeaders ),
					join( '', @columnLabels ),
					# Table data
					@table_data,
				]
				)
			);
		push( @tables, $table );
	}
	
	return @tables;
}

=head2 getJoinTextTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# use CGI parameters to make a table.
	my $table      = $tableMaker->getJoinTextTable( \%options );

	# or use a list of objects to make a table
	my $table      = $tableMaker->getJoinTextTable( \%options, [ { type => $type, title => $title, objects => \@obj_array }, ... ] );

recognized %options are:
	title            => 'table_title'
	excludefields    => { field_name => undef, ... }
	delimiter        => $field_delimiter

=cut

sub getJoinTextTable {
	my $self = shift;
	my $q       = $self->CGI();	
	my %joined_groups;
	my ( $options, $entries ) = @_;
	$options->{Format} = 'txt';
	( $options, %joined_groups ) = $self->__getJoinedGroups( $options, $entries );
	# { joining_group_id => {
	#	field_names => [...], # doubles as column order
	#	records     => { joining_record_id => { field_name => value, ... }, ... }, # joined records
	#	common_names => [...], 
	#	formal_names => [...],
	# }, ... }

	# build tables
	my @tables;
	$options->{delimiter} = "\t" unless $options->{delimiter};
	foreach my $j_group ( values( %joined_groups ) ) {
		my @records = values( %{ $j_group->{records} } );
		my @fieldNames = @{ $j_group->{ field_names } };
		my %labels = %{ $j_group->{ field_labels } };
#		my $title = "Displaying ".join( ', ', @{ $j_group->{ titles } } );
		
		# column labels
		my @columnLabels = map( $labels{ $_ }, @fieldNames );
		
		# Build the table
		my $table = join( $options->{delimiter}, @columnLabels )."\n";
	
		# table data
		foreach my $record ( @records ) {
			$table .= join( $options->{delimiter}, map( $record->{$_}, @fieldNames ) )."\n";
		}
		
		push( @tables, $table );
	}
	
	return @tables;
}

=head2 getTextTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a table from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my $textTable      = $tableMaker->getTextTable( \%options );

	# or use search options to make a table
	my $textTable      = $tableMaker->getTextTable( \%options, $type, \%search_options );

	# or use a list of objects to make a table
	my $textTable      = $tableMaker->getTextTable( \%options, $type, \@obj_array );

If a search key is 'accessor', the objects retrieved will be from a
DBObject accessor method. The value for the 'accessor' search key is
exepected to be a reference to an array of the form [ $typeToAccessFrom,
$idToAccessFrom, $accessorMethod ].

The __limit and __offset search parameters will be ignored.

recognized %options are:
	title            => 'table_title'
	excludefields    => { field_name => undef, ... }
	delimiter        => $field_delimiter

=cut

sub getTextTable {
	my $self = shift;
	my $q       = $self->CGI();
	my @params = @_;
	$params[0]->{ Length } = -1;
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @params );
	
	$options->{delimiter} = "\t" unless $options->{delimiter};
	
	my @fieldNames = OME::Web::DBObjRender->getFieldNames( $formal_name );
	@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
		if exists $options->{excludeFields};
	my %labels     = OME::Web::DBObjRender->getFieldLabels( $formal_name, \@fieldNames, 'txt' );
	my @records    = OME::Web::DBObjRender->render( $objects, 'txt', \@fieldNames );

	# column headers
	my @columnHeaders = map( $labels{ $_ }, @fieldNames );
	
	# Build the table
	my $table = 
		$title."\n".
		join( $options->{delimiter}, @columnHeaders )."\n";

	# table data
	foreach my $record ( @records ) {
		$table .= join( $options->{delimiter}, map( $record->{$_}, @fieldNames ) )."\n";
	}
	
	return $table;
}

=head2 getList

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a list from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my $list      = $tableMaker->getList( \%options );

	# or use search options to make a list
	my $list      = $tableMaker->getList( \%options, $type, \%search_options );

	# or use a list of objects to make a list
	my $list      = $tableMaker->getList( \%options, $type, \@obj_array );

produces a summary list

If a search key is 'accessor', the objects retrieved will be from a
DBObject accessor method. The value for the 'accessor' search key is
exepected to be a reference to an array of the form [ $typeToAccessFrom,
$idToAccessFrom, $accessorMethod ].

recognized %options are:
	Length           => $num_items_per_list
	embedded_in_form => $form_name
	title            => 'table_title'
	width            => 'table_width'

a Length of 0 or less is considered to be 'no limit'. an undef Length is assumed to be the default Length of 10.

=cut

sub getList {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @_ );
	my $display_type = $self->{display_type};
	my $form_name    = $self->{form_name};
	my $pagingText   = $self->{pagingText};
	
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
						( $allowPaging ? '<nobr>'.$pagingText.'</nobr>' : ()),
						$q->a( { href => $self->pageURL( "OME::Web::DBObjTable", $self->{__params} ) }, "More details" )
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

# { joining_group_id => {
#	field_names => [...], # doubles as column order
#	records     => { joining_record_id => { field_name => value, ... }, ... }, # joined records
#	common_names => [...], 
#	formal_names => [...],
# }, ... }
sub __getJoinedGroups {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $options, $entries ) = @_;
	my %standard_index_fields = (
		feature          => undef,
		image            => undef,
		module_execution => undef,
	);
	my %image_index_fields = (
		TheZ             => undef,
		TheC             => undef,
		TheT             => undef,
	);
	
	$options->{Format} = 'html' unless $options->{Format};
	
	my %joined_groups; 
	# { joining_group_id => {
	#	field_names => [...], # doubles as column order
	#	records     => { joining_record_id => { field_name => value, ... }, ... }, # joined records
	#	common_names => [...], 
	#	formal_names => [...],
	# }, ... }

	# gather input from cgi params if inputs were not given
	unless( defined $entries ) {
		my @types = split( m',', $q->param( 'Types' ) );
		$self->{__params}->{Types} = join( ',', @types );
		foreach my $type( @types ) {
			my %searchParams = __get_CGI_search_params( $q, $type );
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
			my ( $objects, $object_count, $minimalParams ) = __load_objects( $self->Session()->Factory(), $formal_name, \%searchParams );
			while( my( $param, $value ) = each %$minimalParams ) {
				next if $param eq 'Type';
				$self->{__params}->{ $param } = ( ref($value) ? join( ',', @$value ) : $value );
			}
			my $title = ( $q->param( "Title_$type" ) or $common_name);
			push( @$entries, {
				title   => $title,
				type    => $formal_name,
				objects => $objects
			});
		}
	} else {
		my @types;
		foreach my $entry ( @$entries ) {
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $entry->{ type } );
			push( @types, $formal_name );
			$self->{__params}->{$formal_name.'_id'} = join( ',',  map( $_->id, @{ $entry->{ objects } } ));
		}
		$self->{__params}->{Types} = join( ',', @types );
	}

	foreach my $entry ( @$entries ) {
		my $title = $entry->{ title };
		my $type  = $entry->{ type };
		my $objects  = $entry->{ objects };

		# load type
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

		# collect records & such for objects
		my @fieldNames = OME::Web::DBObjRender->getFieldNames( $formal_name );
		@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
			if exists $options->{excludeFields};
		my %labels     = OME::Web::DBObjRender->getFieldLabels( $formal_name, \@fieldNames, 'txt' );
		my @records    = OME::Web::DBObjRender->render( $objects, $options->{Format}, \@fieldNames );

		# Determine what known indexes this record contains.
		my @index_fields = sort( grep( exists( $standard_index_fields{$_} ), @fieldNames ) );
		push( @index_fields, sort( grep( exists( $image_index_fields{$_} ), @fieldNames ) ) )
			if( scalar( grep( $_ eq 'image', @index_fields ) ) > 0 );
		
		# merge_records will be used for merging the other records
		my @merge_records = OME::Web::DBObjRender->render( $objects, 'txt', \@index_fields );

		# identifies which joining group these records belong to
		my $j_group_id = join( '.',  @index_fields);
		
		# instantiate the joining group if neccessary.
		$joined_groups{ $j_group_id } = { 
			field_names       => \@index_fields,
			field_name_lookup => { map { $_ => undef } @index_fields },
			col_header        => [ [ ( (scalar @index_fields gt 1) ? 'Indexes' : 'Index' ), scalar( @index_fields ) ] ],
		} unless exists( $joined_groups{ $j_group_id } );

		# join the records
		my $j_group = $joined_groups{ $j_group_id };
		$j_group->{records} = {} unless exists $j_group->{records};
		my $j_records = $j_group->{records};
		for my $i ( 0..( scalar( @records ) - 1 ) ) {
			my $merge_index = join( '.', map( $merge_records[ $i ]->{$_}, @index_fields ) );
			$j_records->{ $merge_index } = {}
				unless exists $j_records->{ $merge_index };
			my $j_record = $j_records->{ $merge_index };

			foreach (@fieldNames) {
				next if $_ eq 'id';
				$j_record->{ $_ } = $records[ $i ]->{ $_ };
			}
			$j_record->{ $formal_name."_id" } = $records[ $i ]->{ id }
				if( exists $records[ $i ]->{ id } );
		}
		
		# record field names.
		my $colspan = 0;
		foreach( @fieldNames ) {
			if ($_ eq 'id') {
				$j_group->{ field_labels }->{ $formal_name."_id" } = $common_name." id";
				$j_group->{ field_name_lookup }->{ $formal_name."_id" } = undef;
#				push( @{ $j_group->{ field_names } }, $formal_name."_id" );
			} else {
				$j_group->{ field_labels }->{ $_ } = $labels{ $_ };
				next if exists $j_group->{ field_name_lookup }->{ $_ };
				$colspan++;
				$j_group->{ field_name_lookup }->{ $_ } = undef;
				push( @{ $j_group->{ field_names } }, $_ );
			}
		}
		
		# record meta data
		push( @{ $j_group->{ common_names } }, $common_name );
		push( @{ $j_group->{ formal_names } }, $formal_name );
		push( @{ $j_group->{ col_header } }, [ ( 
			$ST ?
				$q->a( { href => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id() },
					   $common_name ) :
				$common_name
			), $colspan ] );
		push( @{ $j_group->{ titles } }, $title );
	}
	
	return ( $options, %joined_groups );
}

sub __parseParams {
	my ($self, $options, $type, $param3 ) = @_;
	my $q       = $self->CGI();
	my $factory = $self->Session()->Factory();
	my $mode;
	
	# determine parameter style: cgi parameters, search parameters pass
	# in, or objects passed in
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

	$options->{ select_column } = 1 if $options->{ select_name };

	# retrieve mode specific parameters
	if( $mode eq 'search' ) {
		%searchParams = %$param3;
	} elsif( $mode eq 'objects' ) {
		@objects = @$param3;
		$options->{ noSearch } = 1;
	} elsif( $mode eq 'cgi' ) {
		$type = $q->param( 'Type' )
			or confess "url parameter Type not specified";
		$options->{ Length } = $q->param( $type."___limit" ) 
			unless $options->{ Length };
		%searchParams = __get_CGI_search_params( $q, $type );
	}

	# PAGING: prepare offset & limit
	$searchParams{ __limit } = ( $options->{ Length } or $self->{ _default_Length } );
	if( $searchParams{ __limit } > 0 ) {
		$searchParams{ __offset } = ( $q->param( "PageNum_$type" ) ? $q->param( "PageNum_$type" ) : 0 );
		$searchParams{ __offset } += 1
			if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageForward_$type" );
		$searchParams{ __offset } -= 1
			if( $q->param( 'action' ) and $q->param( 'action' ) eq "PageBack_$type" );
		$q->param( -name => "PageNum_$type", -value => $searchParams{ __offset } );
		$searchParams{ __offset } *= $searchParams{ __limit };
	} else {
		delete $searchParams{ __limit };
		delete $searchParams{ __offset };
	}

	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

	# collect SortOn
	my $orderBy = ( $package_name->getColumnType( 'id' ) ? 'id' : undef );
	if( $q->param( 'action' ) and $q->param( 'action' ) =~ m/^OrderBy_$formal_name/ ) {
		($orderBy = $q->param( 'action' ) ) =~ s/^OrderBy_$formal_name//;
	}

	# get objects
	if( $mode eq 'cgi' or $mode eq 'search' ) {
		my ( $objects, $minimalParams );
		( $objects, $object_count, $minimalParams ) = __load_objects( $factory, $formal_name, \%searchParams, $orderBy );
		$self->{__params} = $minimalParams;
		@objects = @$objects;
	} else {
		$self->{__params} = { 
			Type               => $formal_name,
			$formal_name.'_id' => join( ',', map( $_->id, @objects ) )
		} if $package_name->getColumnType( 'id' );
		$object_count = scalar( @objects );
		@objects = splice( @objects, $searchParams{ __offset }, $searchParams{ __limit } )
			if( $searchParams{ __limit } );
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
	if( $searchParams{ __limit } ) {
		my $currentPage = ( defined $q->param( "PageNum_$formal_name" ) ? $q->param( "PageNum_$formal_name" ) + 1 : 1 );
		my $numPages = POSIX::ceil( $object_count / $searchParams{ __limit });
		if( $object_count and $numPages > 1) {
			$pagingText .= $q->a( {
					-href => "#",
					-onClick => "document.forms['$form_name'].action.value='PageBack_$formal_name'; document.forms['$form_name'].submit(); return false",
					}, 
					'<'
				)." "
				if $currentPage > 1;
			$pagingText  .= sprintf( "%u of %u ", $currentPage, $numPages);
			$pagingText .= "\n".$q->a( {
					-href => "#",
					-onClick => "document.forms['$form_name'].action.value='PageForward_$formal_name'; document.forms['$form_name'].submit(); return false",
					}, 
					'>'
				)
				if $currentPage < $numPages;
		}
	}
	
	$self->{mode}         = $mode;
	$self->{pagingText}   = $pagingText;
	$self->{form_name}    = $form_name;
	$self->{title}        = $title;
	$self->{display_type} = $display_type;
	$self->{common_name}  = $common_name;
	$self->{formal_name}  = $formal_name;
	$self->{ST}           = $ST;
	
	return ( \@objects, $options, $title, $formal_name );
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

sub __get_CGI_search_params {
	my ( $q, $type ) = @_;

	# collect search params
	my %searchParams = map{ $_ => $q->param( $_ ) } grep( m/^($type)_/, $q->param( ) );
	foreach my $key (keys %searchParams) {
		# get the key's Real name
		(my $newkey = $key) =~ s/^($type)_//;
		# copy the key into the real name unless the value is blank
		$searchParams{ $newkey } = $searchParams{ $key }
			unless not defined $searchParams{ $key } or $searchParams{ $key } eq '';
		# delete the old key
		delete $searchParams{ $key };
		if ( $searchParams{ $newkey } =~ m/,/) {
			if( $newkey ne 'accessor' ) {
				$searchParams{ $newkey } = [ 'in', [ split( m/,/, $searchParams{ $newkey } ) ] ];
			} else {
				$searchParams{ $newkey } = [ split( m/,/, $searchParams{ $newkey } ) ];
			}
		}
	}
	
	return %searchParams;
}

sub __load_objects {
	my ( $factory, $formal_name, $searchParams, $orderBy ) = @_;
	my ( @objects, $object_count, $minimalParams );

	# use an accessor from another object.
	if( exists( $searchParams->{ 'accessor' } ) ) {
		my ( $typeToAccessFrom, $idToAccessFrom, $accessorMethod ) = @{ $searchParams->{ 'accessor' } };
		my $objectTaAccessFrom = $factory->loadObject( $typeToAccessFrom, $idToAccessFrom )
			or die "Could not load $typeToAccessFrom, id = $idToAccessFrom";
		$typeToAccessFrom->getColumnType( $accessorMethod )
			or die "$accessorMethod is an unknown accessor for $typeToAccessFrom";
		@objects = $objectTaAccessFrom->$accessorMethod(
			( $searchParams->{ __limit } ? 
				(__limit => $searchParams->{ __limit }) : 
				()
			),
			( $searchParams->{ __offset } ?
				( __offset => $searchParams->{ __offset } ) :
				()
			)
		);
		my $countAccessor = "count_".$accessorMethod;
		$object_count = $objectTaAccessFrom->$countAccessor();
		$minimalParams = { 
			Type               => $formal_name,
			$formal_name."_accessor" => join( ',', ( $typeToAccessFrom, $idToAccessFrom, $accessorMethod ) )
		};


	# use the search parameters
	} else {
		@objects = $factory->findObjectsLike( 
			$formal_name, %$searchParams, 
			( $orderBy ? ( __order => $orderBy ) : () )
		);
		$object_count = $factory->countObjectsLike( $formal_name, %$searchParams );
		$minimalParams = { 
			Type               => $formal_name,
			( map{ $formal_name."_".$_ => $searchParams->{ $_ } } keys %$searchParams )
		};
	}
	
	return ( \@objects, $object_count, $minimalParams );
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
