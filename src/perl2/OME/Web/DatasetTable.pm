# OME/Web/DatasetTable.pm
# HTML table generation class for inclusion or general use. It supports Datasets.

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
# Written by:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::DatasetTable;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;
use Data::Dumper;

# OME Modules
use OME;
use OME::Dataset;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web::Table);

#*********
#********* PRIVATE METHODS
#*********

sub __getColumnAliases {
	my $self = shift;

	my $columns = OME::Dataset->__columns;
	return ("id", keys(%$columns));
}

# Table header macro
sub __genericTableHeader { shift->SUPER::__genericTableHeader("Datasets"); }

sub __search_row {
	my ($self, $options) = @_;
	my $q	 = $self->CGI();
	my $factory = $self->Session()->Factory();
	my $filters = $options->{filters} || {};

	# Owner list
	my @owners = $factory->findAttributes( "Experimenter" );
	my %owner_names = map{ $_->id() => $_->FirstName().' '.$_->LastName() } @owners;
	my $owner_order = [ '', sort( { $owner_names{$a} cmp $owner_names{$b} } keys( %owner_names ) ) ];
	$owner_names{''} = "Select an Owner";

	# Group list
	my @groups = $factory->findAttributes( "Group" );
	my %group_names = map{ $_->id() => $_->Name() } @groups;
	my $group_order = [ '', sort( { $group_names{$a} cmp $group_names{$b} } keys( %group_names ) ) ];
	$group_names{''} = "Select a Group";
	
	my $rows = [
		$q->textfield( -name => 'id', -default => $filters->{id} || undef, -size => 5 ),
		$q->textfield( -name => 'status', -default => $filters->{status} || undef, -size => 8 ),
		$q->textfield( -name => 'name', -default => $filters->{name} || undef, -size => 20 ),
		$q->popup_menu( 
			-name	=> 'owner_id',
			-values => $owner_order,
			-default => $filters->{owner_id},
			-labels	 => \%owner_names
		),
		$q->popup_menu( 
			-name	=> 'group_id',
			-values => $group_order,
			-default => $filters->{group_id} || undef,
			-labels	 => \%group_names
		),
		$q->textfield( -name => 'description', -default => $filters->{description} || undef, -size => 30 ),
	];
	unshift @$rows, undef if $options->{select_column};
	
	return $q->Tr({-class => 'ome_td'},
		$q->td({-align => 'center'}, $rows )
	);

}

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	$self->{search_params} = ['id', 'status', 'name', 'owner_id', 'group_id', 'description'];
	$self->{allow_search} = 1;

	return $self;
}

{
	my $menu_text = 'N/A';

	sub getMenuText { return }
}

sub getTable {
	my ($self, $options, @datasets) = @_;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;
	
	$self->{allow_search} = 0 if( @datasets );
	if( $self->{allow_search} ) {
		push @{ $options->{options_row} }, "Search";
		# add search parameters to filter
		foreach ( @{ $self->{search_params} } ) {
			$options->{filters}->{$_} = $q->param($_)
				if $q->param($_) and $q->param($_) ne '' and not $options->{filters}->{$_};
		}
	}
	@datasets = $self->__filterObjects( {
			filters => $options->{filters},
			filter_object => 'OME::Dataset'
		}
	) unless (@datasets or caller ne ref($self));

	my @column_headers = qw(ID Status Name Owner Group Description);

	# If we're showing relations
	if ($options->{relations}) { push(@column_headers, 'Projects Related') }

	# If we're showing select checkboxes
	if ($options->{select_column}) { unshift(@column_headers, 'Select') }

	# Generate our table data
	foreach my $dataset (@datasets) {
		my $id = $dataset->id();
		my $checkbox;

		if ($options->{select_column}) {
			$checkbox = $q->td({-align => 'center'},
				$q->checkbox(-name => 'selected', -value => $id, -label => '')
			);
		}

		my $name = $dataset->name();
		my $description = $dataset->description();
		my $owner = $dataset->owner()->FirstName() . " " . $dataset->owner()->LastName();
		my $status = $dataset->locked() ? "Locked" : " - ";
		my $group = $dataset->group() ? $dataset->group()->Name() : " - ";
		my $relations;
		
		# Get our relationship checkboxes
		if ($options->{relations}) {
			my @project_relations = $dataset->projects();
			$relations = $self->__getRelationTD($dataset, @project_relations);
		}
		
		unless ($name eq 'Dummy import dataset' or $name eq 'ImportSet') {
			$table_data .= $q->Tr({-class => 'ome_td'},
				$checkbox || '',
				$q->td({-align => 'center'}, [
					$id,
					$status,
					$q->a({-href => "/perl2/serve.pl?Page=OME::Web::DatasetManagement&DatasetID=$id"}, $name) . " " .
					$q->a( {
						-href => "javascript:openInfoDataset($id);",
						-class => 'ome_popup',
					}, '(Popup)'),
					$owner,
					$group,
					$description,
					]
				),
				$relations || '',
			);
		}
	}

    # Get options row
	my $options_table = $self->__getOptionsTable(
		$options->{options_row},
		(scalar(@column_headers) + 1)
	);
	
	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->startform({-name => 'datatable'}),
		$q->th({-class => 'ome_td'}, [@column_headers]),  # Space for the checkbox field
		( $self->{allow_search} ? $self->__search_row( $options ) : '' ),
		$table_data,
		$q->hidden({-name => 'action', -default => ''}),
		$q->endform()
	);

	return $table . $options_table;
}


1;
