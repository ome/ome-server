# OME/Web/ImageTable.pm
# HTML table generation class for inclusion or general use. It supports Images.

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


package OME::Web::ImageTable;

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
use OME::Image;
use OME::Tasks::ImageManager;

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

	my $columns = OME::Image->__columns;
	return ("id", keys(%$columns));
}

# Table header macro
sub __genericTableHeader { shift->SUPER::__genericTableHeader("Images"); }

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
		$q->textfield( -name => 'name', -default => $filters->{name} || undef, -size => 20 ),
		undef,
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

	$self->{search_params} = ['id', 'name', 'owner_id', 'group_id', 'description'];
	$self->{allow_search} = 1;

	return $self;
}

sub getTable {
	my ($self, $options, @images) = @_;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $image_manager = OME::Tasks::ImageManager->new();
	my $table_data;

	$self->{allow_search} = 0 if( @images );
	if( $self->{allow_search} ) {
		push @{ $options->{options_row} }, "Search";
		# add search parameters to filter
		foreach ( @{ $self->{search_params} } ) {
			$options->{filters}->{$_} = $q->param($_)
				if $q->param($_) and $q->param($_) ne '' and not $options->{filters}->{$_};
		}
	}
	@images = $self->__filterObjects( {
			filters => $options->{filters},
			filter_object => 'OME::Image'
		}
	) unless (@images);
	
	my @column_headers = qw(ID Name Preview Owner Group Description);

	# If we're showing relations
	if ($options->{relations}) { push(@column_headers, 'Datasets Related') }
	
	# If we're showing select checkboxes
	if ($options->{select_column}) { unshift(@column_headers, 'Select') }

	# Generate our table data
	foreach my $image (@images) {
		my $id = $image->id();
		my $checkbox;	
		
		if ($options->{select_column}) {
			$checkbox = $q->td({-align => 'center'},
				$q->checkbox(-name => 'selected', -value => $id, -label => '')
			);
		}

		my $name = $image->name();
		my $thumbnail = $q->img( {
				-align => 'bottom',
				-border => 1,
				-src => $image_manager->getThumbURL($image),
				-alt => 'N/A',
			}
		);
		my $experimenter = $factory->loadAttribute("Experimenter", $image->experimenter_id());
		my $owner = $experimenter->FirstName() . " " . $experimenter->LastName();
		my $group = $image->group() ? $image->group()->Name() : " - ";
		my $description = $image->description() ? $image->description() : " - ";
		my $relations;

		# Get our relationship checkboxes
		if ($options->{relations}) {
			my @dataset_relations = $image->datasets();

			# Remove dummy import datasets
			for (my $c = 0; $c < scalar(@dataset_relations); $c++) {
				if ($dataset_relations[$c]->name() eq 'Dummy import dataset' or
				    $dataset_relations[$c]->name() eq 'ImportSet'
				) {
					splice (@dataset_relations, $c, 1);
				}
			}
			$relations = $self->__getRelationTD($image, @dataset_relations);
		}

		$table_data .= $q->Tr({-class => 'ome_td'},
			$checkbox || '',
			$q->td({-align => 'center'}, [
				$id,
				$name,
				$q->a({-href => "javascript:openPopUpImage($id);", -class => 'ome_imagelink'}, $thumbnail),
				$owner,
				$group,
				$description,
				],
			),
			$relations || '',
		);
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
		$q->Tr($q->th({-class => 'ome_td'}, [@column_headers])),
		( $self->{allow_search} ? $self->__search_row( $options ) : '' ),
		$table_data,
		$q->hidden({-name => 'action', -default => ''}),
		$q->endform()
	);

	return $table . $options_table;
}


1;
