# OME/Web/Table.pm
# HTML table generation class for inclusion or general use. It supports Datasets,
# Images and Projects at current.

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


package OME::Web::Table;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;

# OME Modules
use OME;
use OME::Web::Helper::JScriptFormat;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

# Global display types, one for each object type we have a table method for
my @DISPLAY_TYPES = qw(Projects Datasets Images);  # First element is default

#*********
#********* PRIVATE METHODS
#*********

sub __datasetTable {
	my $self = shift;
	my $options = shift;

	# Method variables
	my $q = $self->CGI();
	my $factory = $self->Session()->Factory();
	my $table_data;
	my @datasets = $self->__filterObjects({filter_object => 'OME::Dataset',
			                               filter_field => $options->{filter_field},
										   filter_string => $options->{filter_string}});

	my @column_headers = qw(ID Status Name Owner Group Description);

	# Generate our table data
	foreach my $dataset (@datasets) {
		my $id = $dataset->id();
		my $checkbox = $q->checkbox(-name => 'selected', -value => $id, -label => '');
		my $name = $dataset->name();
		my $description = $dataset->description();
		my $owner = $dataset->owner()->FirstName() . " " . $dataset->owner()->LastName();
		my $status = $dataset->locked() ? "Locked" : " - ";
		my $group = $dataset->group() ? $dataset->group()->Name() : " - ";

		unless ($name eq 'Dummy import dataset') {  # XXX Man I hate this...
			$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
				$q->td({-align => 'center'}, [
					$checkbox,
					$id,
					$status,
					$q->a({-href => "javascript:openInfoDataset($id);"}, $name),
					$owner,
					$group,
					$description,
					]
				)
			);
		}
	}

	# Options row
	my $options = $q->Tr( {-bgcolor => '#EFEFEF'},
		$q->td({-colspan => scalar(@column_headers) + 1, -align => 'center'}, 
			$q->hidden({-name => 'type', -value => $q->param('type') || 'projects'}) .  # Propagation
			$q->submit({name => 'Delete', value => 'Delete'})
		)
	);
	
	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->startform(),
		$q->th({-bgcolor => '#EFEFEF'}, ["Select", @column_headers]),  # Space for the checkbox field
		$table_data,
		$options,
		$q->endform()
	);

	return $table;
}

sub __projectTable {
	my $self = shift;
	my $options = shift;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;
	my @projects = $self->__filterObjects({filter_object => 'OME::Project',
			                               filter_field => $options->{filter_field},
										   filter_string => $options->{filter_string}});
	
	my @column_headers = qw(ID Name Owner Group Description);

	# Generate our table data
	foreach my $project (@projects) {
		my $id = $project->id();
		my $checkbox = $q->checkbox(-name => 'selected', -value => $id, -label => '');
		my $name = $project->name();
		my $description = $project->description();
		my $owner = $project->owner()->FirstName() . " " . $project->owner()->LastName();
		my $group = $project->group() ? $project->group()->Name() : " - ";

		$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
			$q->td({-align => 'center'}, [
				$checkbox,
				$id,
				$q->a({-href => "javascript:openInfoProject($id);"}, $name),
				$owner,
				$group,
				$description,
				]
			)
		);
	}
	# Options row

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->th({-bgcolor => '#EFEFEF'}, ["Select", @column_headers]),
		$table_data
	);

	return $table;
}

sub __imageTable {
	my $self = shift;
	my $options = shift;

	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;
	my @images = $self->__filterObjects({filter_object => 'OME::Image',
			                             filter_field => $options->{filter_field},
										 filter_string => $options->{filter_string}});

	my @column_headers = qw(ID Name Preview Owner Group Description);

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

		$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
			$q->td({-align => 'center'}, [
				$checkbox,
				$id,
				$name,
				$q->a({-href => "javascript:openPopUpImage($id);"}, $thumbnail),
				$owner,
				$group,
				$description
				]
			)
		);
	}
	# Options row

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->th({-bgcolor => '#EFEFEF'}, ["Select", @column_headers]),
		$table_data
	);

	return $table;
}


sub __genericTableHeader {
	my $self = shift;
	my ($title) = @_;
	my $q = $self->CGI();

	# Title text
	$title = $q->span({-class => 'ome_title'}, $title);

	# "Display:" selection box table and form
	my $table = $q->table( {
			-border => '0',
			-width => '100%',
		},
		$q->start_form() .
		$q->Tr(
			$q->td({-align => 'left'}, $title),
			$q->td({-align => 'right'},
				"Display: " .
				$q->popup_menu( {
						-name => 'type',
						-values => [@DISPLAY_TYPES],
						-default => $DISPLAY_TYPES[0]
					}) .
				'&nbsp' .
				$q->submit({-value => 'Go'})
			)
		) .
		$q->endform()
	);
		   
	return $table;
}

sub __genericTableFooter {
	my $self = shift;
	my @columns = @_;
	my $q = $self->CGI();

	# Put a "none" on the front
	unshift(@columns, "None");

	# A filter form table for filtering display on a Factory like "findObjectsLike" method
	my $table = $q->table( {
			-class => 'ome_table',
			-align => 'center',
			-border => 0,
			#-width => '100%',
			-cellpadding => '4',
			-cellspacing => '1',
		},
		$q->start_form() .
		$q->Tr(
			$q->td({-align => 'center', -bgcolor => '#006699'}, 
			   "Filter field: " .
			   $q->popup_menu({-name => 'filter_field',
					           -values => [@columns],
							   -default => $columns[0]
						   }) .
			   " Filter string: " .
		       $q->textfield({-name => 'filter_string', -default => '', -size => 15}) .
		       "&nbsp" .  # Spacing
			   $q->hidden({-name => 'type', -value => $q->param('type') || 'projects'}) .  # Propagation
		       $q->submit({-name => 'data_filter', -value => 'Go'})
		    )
	    ) .
		$q->endform()
	);

	return $table;
}

sub __filterObjects {
	my $self = shift;
	my $options = shift;

	my $factory = $self->Session()->Factory();
	my @objects;

	# Filter the dataset objects if needed
	if ($options->{filter_field} and $options->{filter_string}) {
		# Get a cursor for our search with a forced lowercase field
		my $cursor = $factory->findObjectsLike($options->{filter_object},
			                                   {lc($options->{filter_field}) => $options->{filter_string}});  

		# Iterate and populate list
		while (my $object = $cursor->next()) { push (@objects, $object) }
	} else {
		@objects = $factory->findObjects($options->{filter_object});
	}

	return @objects;
}

#*********
#********* PUBLIC METHODS
#*********

sub getPageTitle {
    return "Open Microscopy Environment - Data Table"; 
}

sub getPageBody {
    my $self = shift;
    my $q = $self->CGI();
	my $j_format = new OME::Web::Helper::JScriptFormat;
	my ($main_table, $header, $filter_table);
	
	# XXX Testing
	my $status;
	if ($q->param('Delete')) {
		$status = 'Delete activated on... ';
		foreach ($q->param('selected')) { $status .= "id = $_ "; }
	}
	# XXX Testing

	my $type = $q->param('type') || 'projects';  # Projects is the default display
	my $filter_field = $q->param('filter_field') || '';
	my $filter_string = $q->param('filter_string') || '';
	
	# Cleanup so we don't get superfluous propagation
	$q->delete('filter_field', 'filter_string', 'selected');

	# Based on the type, gen our page data
	if (lc($type) eq 'datasets') {
		my $columns = OME::Dataset->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Datasets");
		$main_table = $self->__datasetTable({filter_field => $filter_field,
			                                 filter_string  => $filter_string});
		$filter_table = $self->__genericTableFooter(@column_aliases);
	} elsif (lc($type) eq 'projects') {
		my $columns = OME::Project->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Projects");
		$main_table = $self->__projectTable({filter_field => $filter_field,
			                                 filter_string  => $filter_string});
		$filter_table = $self->__genericTableFooter(@column_aliases);
	} elsif (lc($type) eq 'images') {
		my $columns = OME::Image->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Images");
		$main_table = $self->__imageTable({filter_field => $filter_field,
				                           filter_string  => $filter_string});
		$filter_table = $self->__genericTableFooter(@column_aliases);
	}

	return ('HTML',
	        $j_format->openInfoProject() .
			$j_format->openInfoDataset() .
			$j_format->popUpImage() .
			$q->span({-class => 'ome_error'}, $status) .  # XXX Testing
			$header . $main_table . $q->p() . $filter_table);
}


1;
