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

#*********
#********* PUBLIC METHODS
#*********

sub getTable {
	my ($self, $options, @images) = @_;
	my $i_manager = new OME::Tasks::ImageManager;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;

	unless (@images) {
		@images = $self->__filterObjects( {
				filters => $options->{filters},
				filter_object => 'OME::Image'
			}
		);
	}
	
	my @column_headers = qw(ID Name Preview Owner Group Description);

	# If we're showing relations
	if ($options->{relations}) { push(@column_headers, 'Datasets Related') }

	# Generate our table data
	foreach my $image (@images) {
		my $id = $image->id();
		my $checkbox = $q->checkbox(-name => 'selected', -value => $id, -label => '');
		my $name = $image->name();
		my $thumbnail = $q->img( {
				-align => 'bottom',
				-border => '0',
				-src => "/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID=$id",
				-alt => 'N/A'
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
				if ($dataset_relations[$c]->name() eq 'Dummy import dataset') {
					splice (@dataset_relations, $c, 1);
				}
			}
			$relations = $self->__getRelationTD(@dataset_relations);
		}

		$table_data .= $q->Tr({-class => 'ome_td'},
			$q->td({-align => 'center'}, [
				$checkbox,
				$id,
				$name,
				$q->a({-href => "javascript:openPopUpImage($id);"}, $thumbnail),
				$owner,
				$group,
				$description,
				],
			),
			$relations || '',
		);
	}

    # Get options row
	my $options_row = $self->__getOptionsTR($options->{options_row}, (scalar(@column_headers) + 1));

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->startform(),
		$q->Tr($q->th({-class => 'ome_td'}, ["Select", @column_headers])),
		$table_data,
		$options_row || '',
		$q->endform()
	);

	return $table;
}


1;
