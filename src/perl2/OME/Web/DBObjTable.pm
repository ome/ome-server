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
use Log::Agent;
use Carp;
use Carp 'cluck';

use base qw(OME::Web::Authenticated);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _default_Length } = 25;
	# Set a 30 second timeout
	$self->timeout(60);

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
		if( $q->param( "Format" ) and $q->param( "Format" ) eq 'txt' ) {
			my ($title,$table) = $self->getTextTable();
			$self->contentType('text/tab-separated-values');
			return ('FILE', {
				downloadFilename => $title.'.tsv',
				content          => $table,
			});
#			return ('TXT', $table );

		} elsif( $q->param( 'no_decorations' ) ) {
			return ('HTML-complete', 
				$q->start_html.
				$self->getTable( {
					width         => '100%',
				}).
				$q->end_html
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
			my ($title,$table) = $self->getJoinTextTable();
			$self->contentType('text/tab-separated-values');
			return ('FILE', {
				downloadFilename => $title.'.tsv',
				content          => $table,
			});	
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

Please don't use this if you can use DBObjRender and a custom template instead. 
OME::Web::TaskProgress and OME_Task_table.tmpl provide an example of using 
DBObjRender services to get a table.
This was made some time ago and was built according to a since
depricated rendering model.
This does allow selections and actions, which is not fully and readily
implemented in Search or DBObjRender. Yet...

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
	includefields    => { field_name => undef, ... }
	noTxtDownload    => 1|0                          # 1 disables 'Download [table] as txt' link

a Length of 0 or less is considered to be 'no limit'. an undef Length is
assumed to be the default Length of 10.

=cut

sub getTable {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @_ );
	my $form_name    = $self->{form_name};
	my $pagingText   = $self->{pagingText};

	# build table
	my $html;
	my @fieldNames;
	if (exists $options->{fields} and $options->{fields}) {
		@fieldNames = @{$options->{fields}};
	} else {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
		@fieldNames = $package_name->getPublishedCols();
		@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
			if exists $options->{excludeFields};
		push (@fieldNames, keys %{$options->{includeFields}})
			if exists $options->{includeFields};
	}
	my %labels     = $self->Renderer()->getFieldTitles( $formal_name, \@fieldNames, 'txt' );
	my ($searches, $search_on) = $self->SearchUtil()->getSearchFields( $formal_name, \@fieldNames, $self->{search_params} );
	my @records    = $self->Renderer()->renderData( $objects, [@fieldNames, 'id', '/obj_detail_url' ]);

	# table data
	my @table_data;
	foreach my $record ( @records ) {
		my $table_cells;
		$table_cells = 
			$q->td( { -class => 'ome_td', -align => 'center'},
				$q->checkbox( {
					-name    => ($options->{ select_name } or 'Selected_'.$formal_name), 
					-value   => $record->{id}, 
					-checked => '',
					-label => ''
				} )
			)
			if( $options->{ select_column } );
		$table_cells .= 
			$q->td( { -class => 'ome_td', -align => 'center'},
				$q->a( {
					-href    => $record->{ '/obj_detail_url' },
					-title   => "Detailed info about this object"
				}, $record->{ 'id' } )
			);
		$table_cells .= 
			$q->td( { -class => 'ome_td' }, 
				[ map( defined $record->{$_} ? $record->{$_} : '', @fieldNames ) ] 
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
			[ map( $searches->{ $_ }, @fieldNames ) ]
		);
	}
	# allow paging ?
	my $allowPaging = ( $pagingText ? 1 : 0 );
	
	my %text_params = %{ $self->{__params} };
	foreach (keys %text_params) {
		delete $text_params{$_} if $_ =~ /((__limit)|(__offset))$/;
	}

	$options->{ noTxtDownload } = 1 if $options->{ no_decorations };
	my @downloadAsTxt = ( $options->{ noTxtDownload } ? () : 
		( $q->a( { -href => 
			$self->pageURL('OME::Web::DBObjTable', { 
				%text_params,
				Format => 'txt',
			} ),
			-title => 'Download this table as tab delimited text' }, 
			"Download as txt" 
		) )
	);
	
	# column headers
	my @columnHeaders;
	my $table_sort_field = '';
	# do not enable column sorting
	if( $options->{ no_decorations } || 
	         ($options->{ embedded_in_form } && !$options->{ table_id }) 
	       ) {
		@columnHeaders = map( $labels{ $_ }, @fieldNames );
		unshift( @columnHeaders, 'ID' );
		unshift( @columnHeaders, 'Select' )
			if( $options->{ select_column } );
	# enable column sorting. make the column that records are currently sorted on inactive.
	} else {
		my $table_id = ( $options->{ table_id } || '' );
		my $inactiveColumn;
		$table_sort_field = $table_id.'_OrderBy';
		if( $q->param( $table_sort_field ) and $q->param( $table_sort_field ) ne '' ) {
			$inactiveColumn = $q->param( $table_sort_field );
		} else {
			$inactiveColumn = 'id';
		}
		@columnHeaders = map( ($_ ne $inactiveColumn ? 
			$q->a( 
				{ -href => "javascript: document.forms['$form_name'].${table_sort_field}.value='".$_."'; document.forms['$form_name'].submit();", },
				$labels{ $_ }
			) : 
			$labels{ $_ } )
		, @fieldNames );
		unshift( @columnHeaders, 'ID' );
		unshift( @columnHeaders, 'Select' )
			if( $options->{ select_column } );
		$table_sort_field = $q->hidden( -name => $table_sort_field );
	}
	
	# Build the table
	$html = $q->startform( { -name => $form_name })
		unless $options->{ embedded_in_form };
	$html .= $q->a( { name => $options->{ anchor } }, ' ' )
		if exists $options->{ anchor };
	$html .=
		$table_sort_field.
		$q->table( {
				-class => 'ome_table',
				-width => $options->{width},
				-cellpadding => '4',
				-cellspacing => '1',
				-border => '0',
			},
			# Table title
			( $options->{ no_decorations } ? '' : $q->caption( $title ) ),
			$q->Tr( [
				# table descriptor
				($options->{ no_decorations } ? () :
					$q->td( { -class => 'ome_td', -colspan => scalar( @columnHeaders ), -align => 'right' }, 
						$q->span( { -class => 'ome_widget' }, join( " | ", (
							@downloadAsTxt,
							( $allowPaging ? $pagingText : ()), 
							map( $self->__getActionButton( $_, $form_name ), @{ $options->{ actions } } )
						) ) )
					)
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
		$q->hidden({-name => "PageNum_$formal_name", -default => ( $q->param( "PageNum_$formal_name" ) or undef ) })
		if( $allowPaging );
	unless( $options->{ embedded_in_form } || $options->{ no_decorations }){
		$q->param( 'search_names', values %$search_on ) if $q->param( 'search_names' );
		$html .= 
			$q->hidden({-name => 'action', -default => ''}).
			join( "\n", map( 
				$q->hidden({-name => $_, -default => $self->{__params}->{$_} }),
				keys %{ $self->{__params} } )
			).
			$q->hidden( {-name => 'search_names', -default => [ values %$search_on ] } ).
			$q->endform();
	}

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
	my $form_name    = ($options->{embedded_in_form} || 0);
	# { joining_group_id => {
	#	field_names => [...], # doubles as column order
	#	records     => { joining_record_id => { field_name => value, ... }, ... }, # joined records
	#	common_names => [...], 
	#	formal_names => [...],
	# }, ... }

	# build tables
	my @tables;
	foreach my $j_group_id (  sort( keys( %joined_groups ) ) ) {
		my $j_group = $joined_groups{ $j_group_id };
		my $table;
		
		# table content
		my @records = values( %{ $j_group->{records} } );
		my @fieldNames = @{ $j_group->{ field_names } };
		my %labels = %{ $j_group->{ field_labels } };
		my @headers = @{ $j_group->{ col_header } };		
		my $title = "Displaying ".join( ', ', @{ $j_group->{ titles } } ).
			join( '', map( $q->a( { -name => $_ }, ' ' ), @{ $j_group->{ titles } } ) );

		# order records
		my $field_name_of_orderBy = ( $options->{ group_id } ? $options->{ group_id } : '' ).$j_group_id.'_OrderBy';
		$field_name_of_orderBy =~ s/[,\.]/_/g;
		$field_name_of_orderBy = '_'.$field_name_of_orderBy
			if $field_name_of_orderBy =~ m/^\d/;
		my $order_by = $fieldNames[ 0 ];
		if( $q->param( $field_name_of_orderBy ) && $q->param( $field_name_of_orderBy ) ne '' ) {
			$order_by = $q->param( $field_name_of_orderBy );
			@records = sort( { $a->{ $order_by } <=> $b->{ $order_by } } @records );
		}

		# translate to html
		my @table_data;
		foreach my $record ( @records ) {
			my $table_cells = 
				$q->td( { -class => 'ome_td' }, 
					[ map( defined $record->{$_} ? $record->{$_} : '', @fieldNames ) ] 
				);
			push( @table_data, $table_cells );
		}
	
		# column descriptors
		my @columnHeaders;
		foreach my $entry( @headers ) {
			my ($name, $colspan) = @$entry;
			push( @columnHeaders, $q->td( { -class => 'ome_td', -colspan => $colspan, -align => 'center' }, $name ) );
		}
		my @columnLabels = map( 
				$q->td( { -class => 'ome_td' }, 
					# Make column headers into "Order By" links. Except the one that is currently ordering the table.
					( $_ ne $order_by ?
						$q->a( { -href  => "javascript: document.forms['$form_name'].${field_name_of_orderBy}.value = '$_'; document.forms[0].submit(); ",
								 -title => "Order table by this column" },
							   $labels{ $_ }
						) :
						$labels{ $_ }
					)
				), @fieldNames 
		);
		
		# link to text table
		my %text_params = %{ $self->{__params} };
		foreach (keys %text_params) {
			delete $text_params{$_} if $_ =~ /((__limit)|(__offset))$/;
		}
		my $txt_table_link = 
			$q->a( { -href => 
				$self->pageURL('OME::Web::DBObjTable', { 
					%text_params,
					Format => 'txt',
				} ) }, "Download as txt"
			);
		
		# Build the table
		$table .=
			$q->hidden( -name => $field_name_of_orderBy ).
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
	my @titles;
	
	$options->{delimiter} = "\t" unless $options->{delimiter};
	foreach my $j_group ( values( %joined_groups ) ) {
		my @records = values( %{ $j_group->{records} } );
		my @fieldNames = @{ $j_group->{ field_names } };
		my %labels = %{ $j_group->{ field_labels } };
		push (@titles,join( '-', @{ $j_group->{ titles } } ) );

		# order records
		if( $q->param( '_OrderBy' ) && $q->param( '_OrderBy' ) ne '' ) {
			my $order_by = $q->param( '_OrderBy' );
			@records = sort( { $a->{ $order_by } <=> $b->{ $order_by } } @records );
		}

		# column labels
		my @columnLabels = map( $labels{ $_ }, @fieldNames );
		
		# Build the table
		my $table = join( $options->{delimiter}, @columnLabels )."\n";

		# table data
		foreach my $record ( @records ) {
			$table .= join( $options->{delimiter}, map( defined $record->{$_} ? $record->{$_} : '', @fieldNames ) )."\n";
		}
		
		push( @tables, $table );
	}
	
	return ( join (':',@titles), join ("\n",@tables)."\n" );
}

=head2 getTextTable

	my $tableMaker = OME::Web::DBObjTable->new( CGI => $cgi );

	# make a table from CGI parameters 'Type' and search params with the format $type.'_'.$searchKey
	my ($title,$textTable) = $tableMaker->getTextTable( \%options );

	# or use search options to make a table
	my ($title,$textTable) = $tableMaker->getTextTable( \%options, $type, \%search_options );

	# or use a list of objects to make a table
	my ($title,$textTable) = $tableMaker->getTextTable( \%options, $type, \@obj_array );

If a search key is 'accessor', the objects retrieved will be from a
DBObject accessor method. The value for the 'accessor' search key is
exepected to be a reference to an array of the form [ $typeToAccessFrom,
$idToAccessFrom, $accessorMethod ].


recognized %options are:
	title            => 'table_title'
	excludeFields    => { field_name => undef, ... }
	includeFields    => { field_name => undef, ... }
	fields           => { field_name => undef, ... }
	delimiter        => $field_delimiter

=cut

sub getTextTable {
	my $self = shift;
	my $q       = $self->CGI();
	my @params = @_;
	$params[0]->{ Format } = 'txt';
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @params );
	
	$options->{delimiter} = "\t" unless $options->{delimiter};
	
	my @fieldNames;
	if (exists $options->{fields} and $options->{fields}) {
		@fieldNames = @{$options->{fields}};
	} else {
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
		@fieldNames = ('id', sort( $package_name->getPublishedCols() ) );
		@fieldNames = grep( (not exists $options->{excludeFields}->{$_}), @fieldNames )
			if exists $options->{excludeFields};
		push (@fieldNames, keys %{$options->{includeFields}})
			if exists $options->{includeFields};
	}
	my %labels     = $self->Renderer()->getFieldTitles( $formal_name, \@fieldNames, 'txt' );
	my @records    = $self->Renderer()->renderData( $objects, \@fieldNames, {text => 1});

	# column headers
	my @columnHeaders = map( $labels{ $_ }, @fieldNames );
	
	# Build the table
	my $table = join( $options->{delimiter}, @columnHeaders )."\n";

	# table data
	foreach my $record ( @records ) {
		$table .= join( $options->{delimiter}, map( defined $record->{$_} ? $record->{$_} : '', @fieldNames ) )."\n";
	}
	$table .= "\n";
	
	return ($title,$table);
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
	URLtoMoreInfo    => $href

a Length of 0 or less is considered to be 'no limit'. an undef Length is assumed to be the
default Length of 10.
URLtoMoreInfo defaults to a table view of the same data. the link 'More details' will reference this.

=cut

sub getList {
	my $self = shift;
	my $q       = $self->CGI();
	my ( $objects, $options, $title, $formal_name ) =
		$self->__parseParams( @_ );
	my $form_name    = $self->{form_name};
	my $pagingText   = $self->{pagingText};
	$options->{ URLtoMoreInfo } = $self->pageURL( "OME::Web::DBObjTable", $self->{__params} )
		unless exists $options->{ URLtoMoreInfo };
	
	return $self->Renderer()->renderArray( $objects, 'list', { more_info_url => $options->{ URLtoMoreInfo } } );
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
#		module_execution => undef,
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
			my %options;
			if ( my $fields = $q->param( $type."___fields" ) ) {
				$options{ fields } = [ split (/,/,$fields ) ];
			}
			if ( my $fields = $q->param( $type."___includeFields" ) ) {
				foreach my $field( split (/,/,$fields ) ) {
					$options{ includeFields }->{$field} = undef;
				}
			}
			if ( my $fields = $q->param( $type."___excludeFields" ) ) {
				foreach my $field( split (/,/,$fields ) ) {
					$options{ excludeFields }->{$field} = undef;
				}
			}
			my %searchParams = __get_CGI_search_params( $q, $type );
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
			my ( $objects, $object_count, $minimalParams ) = __load_objects( $self->Session()->Factory(), $formal_name, \%searchParams );
			while( my( $param, $value ) = each %$minimalParams ) {
				next if $param eq 'Type';
				$self->{__params}->{ $param } = $value;
			}
			my $title = ( $q->param( "Title_$type" ) or $common_name);
			push( @$entries, {
				title   => $title,
				type    => $formal_name,
				objects => $objects,
				search  => {%searchParams},
				options => {%options}
			});
		}
	} else {
		my %types;
		foreach my $entry ( @$entries ) {
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $entry->{ type } );
			if (exists $entry->{ search }) {
				my %searchParams = %{$entry->{ search }};
				while ( my ($search_key,$search_val) = each (%searchParams) ) {
					$self->{__params}->{$formal_name.'.'.$search_key} = $search_val;
				}
				( $entry->{ objects }, undef, undef ) = __load_objects( $self->Session()->Factory(), $formal_name, \%searchParams );
				$types{$formal_name} = undef;
			} else {
				push (@{$types{$formal_name}},  @{ $entry->{ objects } } );
			}
		}
		while (my ($formal_name,$objects) = each (%types)) {
			$self->{__params}->{$formal_name.'.id'} = join (',', map($_->id, @$objects) ) if $objects;
		}
		$self->{__params}->{Types} = join( ',', keys (%types) );
	}

	foreach my $entry ( @$entries ) {
		my $title = $entry->{ title };
		my $type  = $entry->{ type };
		my $objects  = $entry->{ objects };
		my $entry_options = $entry->{ options };

		# load type
		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

		# collect records & such for objects
		my @fieldNames;
		if (exists $entry_options->{fields} and $entry_options->{fields}) {
			@fieldNames = @{$entry_options->{fields}};
		} else {
			my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
			@fieldNames = $package_name->getPublishedCols();
			@fieldNames = grep( (not exists $entry_options->{excludeFields}->{$_}), @fieldNames )
				if exists $entry_options->{excludeFields};
			push (@fieldNames, keys %{$entry_options->{includeFields}})
				if exists $entry_options->{includeFields};
		}

		my %labels     = $self->Renderer()->getFieldTitles( $formal_name, \@fieldNames, 'txt' );
		my @records    = $self->Renderer()->renderData( $objects, \@fieldNames, {text => 1} );

		# Determine what known indexes this record contains.
		my @index_fields = sort( grep( exists( $standard_index_fields{$_} ), @fieldNames ) );
		push( @index_fields, sort( grep( exists( $image_index_fields{$_} ), @fieldNames ) ) )
			if( scalar( grep( $_ eq 'image', @index_fields ) ) > 0 );
		
		# merge_records will be used for merging the other records
		my @merge_records = $self->Renderer()->renderData( $objects, \@index_fields );

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
				$q->a( { href  => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id(),
				         title => "Documentation of this Semantic Type"
				       },
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
		$options->{ no_decorations } = $q->param( 'no_decorations' ) ;
		$options->{ Length } = $q->param( $type."___limit" ) 
			unless $options->{ Length };
		$options->{ Length } = -1 unless $options->{ Length };
		if ( my $fields = $q->param( $type."___fields" ) ) {
				$options->{ fields } = [split (/,/,$fields )];
		}
		if ( my $fields = $q->param( $type."___includeFields" ) ) {
			foreach my $field( split (/,/,$fields ) ) {
				$options->{ includeFields }->{$field} = undef;
			}
		}
		if ( my $fields = $q->param( $type."___excludeFields" ) ) {
			foreach my $field( split (/,/,$fields ) ) {
				$options->{ excludeFields }->{$field} = undef;
			}
		}
		%searchParams = __get_CGI_search_params( $q, $type );
	}
	# load type
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

	# PAGING: prepare offset & limit
	unless( $options->{ no_decorations } ) {
		$searchParams{ __limit } = ( $options->{ Length } or $self->{ _default_Length } );
		if( $searchParams{ __limit } > 0 ) {
			$searchParams{ __offset } = ( $q->param( "PageNum_$formal_name" ) ? $q->param( "PageNum_$formal_name" ) : 0 );
			$searchParams{ __offset } *= $searchParams{ __limit };
		} else {
			delete $searchParams{ __limit };
			delete $searchParams{ __offset };
		}
	}
	
	my $orderBy = ( $package_name->getColumnType( 'id' ) ? 'id' : undef );
	my $table_id = ( $options->{ table_id } || '' );
	if( $q->param( $table_id.'_OrderBy' ) and $q->param( $table_id.'_OrderBy' ) ne '' ) {
		$orderBy = $q->param( $table_id.'_OrderBy' );
	}
	if( exists $searchParams{ __order } ) {
		$orderBy = $searchParams{ __order };
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
			$formal_name.'.id' => join( ',', map( $_->id, @objects ) )
		} if $package_name->getColumnType( 'id' );
		$object_count = scalar( @objects );
		@objects = splice( @objects, $searchParams{ __offset }, $searchParams{ __limit } )
			if( $searchParams{ __limit } );
	}
	
	# make form name, title, display type
	my $form_name   = ( $options->{ embedded_in_form } or $common_name."_TABLE" );
	my $title       = ( $options->{ title } or $common_name ).
		( $ST && $options->{ Format } && $options->{ Format } ne 'txt' ?
			' '.$q->a( { href => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id() },'?') 
			: ''			
		);
	
	# paging
	my $pagingText;
	if( $searchParams{ __limit } ) {
		my $currentPage = ( 
			( defined $q->param( "PageNum_$formal_name" ) and $q->param( "PageNum_$formal_name" ) ne "" ) ? 
			$q->param( "PageNum_$formal_name" ) + 1 :
			1 
		);
		my $numPages = POSIX::ceil( $object_count / $searchParams{ __limit });
		if( $object_count and $numPages > 1) {
			$pagingText .= $q->a( {
					-title => "First Page",
					-href => "javascript: document.forms['$form_name'].elements['PageNum_$formal_name'].value=0; document.forms['$form_name'].action.value='TurnPage_$formal_name'; document.forms['$form_name'].submit();",
					}, 
					'<<'
				)." "
				if ( $currentPage > 1 and $numPages > 2 );
			$pagingText .= $q->a( {
					-title => "Previous Page",
					-href => "javascript: document.forms['$form_name'].elements['PageNum_$formal_name'].value=($currentPage-2); document.forms['$form_name'].action.value='TurnPage_$formal_name'; document.forms['$form_name'].submit();",
					}, 
					'<'
				)." "
				if $currentPage > 1;
			$pagingText  .= sprintf( "%u of %u ", $currentPage, $numPages);
			$pagingText .= "\n".$q->a( {
					-title => "Next Page",
					-href  => "javascript: document.forms['$form_name'].elements['PageNum_$formal_name'].value=$currentPage; document.forms['$form_name'].action.value='TurnPage_$formal_name'; document.forms['$form_name'].submit();",
					}, 
					'>'
				)." "
				if $currentPage < $numPages;
			$pagingText .= "\n".$q->a( {
					-title => "Last Page",
					-href  => "javascript: document.forms['$form_name'].elements['PageNum_$formal_name'].value=($numPages-1); document.forms['$form_name'].action.value='TurnPage_$formal_name'; document.forms['$form_name'].submit();",
					}, 
					'>>'
				)
				if( $currentPage < $numPages and $numPages > 2 );
		}
	}
	
	$self->{mode}          = $mode;
	$self->{pagingText}    = $pagingText;
	$self->{form_name}     = $form_name;
	$self->{title}         = $title;
	$self->{common_name}   = $common_name;
	$self->{formal_name}   = $formal_name;
	$self->{ST}            = $ST;
	$self->{search_params} = \%searchParams;
	
	return ( \@objects, $options, $title, $formal_name );
}

sub __getActionButton {
	my ($self, $action, $form_name) = @_;
	my $q = $self->CGI();
	return 
		$q->a( 
			{
				-title => $action,
				-href  => "javascript: document.forms['$form_name'].action.value='$action'; document.forms['$form_name'].submit();",
				-class => 'ome_widget'
			}, 
			$action 
		);
}

# CGI params come in two flavors.  One for joined tables, one for a single-type table.
# In a single-type table, cgi parameters correspond to elements in the base type (the Type param).
# In a joined table, each type's search elements are constructed from the formal name of the type
# followed by a dot followed by that type's element name.
# i.e. @Location.TheX=123.5
# The type parameter is required when getting search_params for multi-type tables.
sub __get_CGI_search_params {
	my ( $q, $type ) = @_;
	my %searchParams;

	if ($q->param ('Types')) {
		die "object type must be specified in __get_CGI_search_params for multi-type tables"
			unless defined $type;
	} else {
		$type = $q->param ('Type');
	}

	my @params = $q->param();
	my $param;
	foreach $param (@params) {
		next if $param eq 'Type' or $param eq 'Types';
		next if $param eq 'Format' or $param eq 'Page';
		my $value = $q->param ($param);
		if (index ($param,$type) == 0) {
			$param = substr ($param, length($type)+1);
			undef $param if $param =~ /^_/;
		} elsif( ($param eq '__order' ) || ($param eq '__distinct') ) {
			if ($value =~ m/,/ ) {
				$value = [ split( m/,/, $value ) ];
			} else {
				$value = [ $value ];
			}
			foreach (@$value) {
				if( m/^~(.*)$/ ) {
					$_ = '!'.$1;
				}
			}
		} else {
			undef $param;
		}
		if ($value =~ m/,/ and $param) {
			if ($param eq 'accessor' ) {
				$value = [ split( m/,/, $value ) ];
			} else {
				$value = [ 'in', [ split( m/,/, $value ) ] ];
			}
		}

		$searchParams{$param} = $value if $param;
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
		$minimalParams->{Type} = $formal_name;
		my ($key,$value);
		while ( ($key,$value) = each (%$searchParams) ) {
			if (ref ($value) eq 'ARRAY') {
				if ( ref ($value->[0]) ) {
					$value = join ( ',', map ($_->id() , @$value) );
					$key .= '_id';
				} else {
					$value = join ( ',', @$value );
				}
			} elsif ( ref ($value) ) {
				$key .= '_id';
				$value = $value->id();
			}
			$key = $formal_name.'.'.$key;
			$minimalParams->{$key} = $value;
		}
	}
	
	return ( \@objects, $object_count, $minimalParams );
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
