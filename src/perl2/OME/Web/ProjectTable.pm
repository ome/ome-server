# OME/Web/ProjectTable.pm
# HTML table generation class for inclusion or general use. It supports Projects.

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


package OME::Web::ProjectTable;

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
use OME::Project;

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

	my $columns = OME::Project->__columns;
	return ("id", keys(%$columns));
}

# Table header macro
sub __genericTableHeader { shift->SUPER::__genericTableHeader("Projects"); }

#*********
#********* PUBLIC METHODS
#*********

sub getTable {
	my ($self, $options, @projects) = @_;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;

	unless (@projects) {
		@projects = $self->__filterObjects( {
				filters => $options->{filters},
				filter_object => 'OME::Project'
			}
		);
	}
	
	my @column_headers = qw(ID Name Owner Group Description);
	
	# If we're showing select checkboxes
	if ($options->{select_column}) { unshift(@column_headers, 'Select') }

	# Generate our table data
	foreach my $project (@projects) {
		my $id = $project->id();
		my $checkbox;

		if ($options->{select_column}) {
			$checkbox = $q->td({-align => 'center'},
				$q->checkbox(-name => 'selected', -value => $id, -label => '')
			);
		}

		my $name = $project->name();
		my $description = $project->description();
		my $owner = $project->owner()->FirstName() . " " . $project->owner()->LastName();
		my $group = $project->group() ? $project->group()->Name() : " - ";

		$table_data .= $q->Tr({-class => 'ome_td'},
			$checkbox || '',
			$q->td({-align => 'center'}, [
				$id,
				$q->a({-href => "javascript:openInfoProject($id);"}, $name),
				$owner,
				$group,
				$description,
				]
			)
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
		$q->hidden({-name => 'action', -default => ''}),
		$table_data,
		$q->endform()
	);

	return $table . $options_table;
}


1;
