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
	my @columns = qw(ID Status Name Owner Group Description);
	my @datasets;

	# Filter the dataset objects if needed
	if ($options->{filter_field} and $options->{filter_text}) {
		carp "Filtering ", $options->{filter_field}, " by ", $options->{filter_text};
		# Get an OME::Dataset cursor for our search with a forced lowercase field
		my $cursor =
			$factory->findObjectsLike("OME::Dataset", {lc($options->{filter_field}) => $options->{filter_text}});  
		# Iterate and populate list
		while (my $dataset = $cursor->next()) {
			push (@datasets, $dataset);
		}
	} else {
		@datasets = $factory->findObjects("OME::Dataset");
	}
	
	foreach my $dataset (@datasets) {
		my $id = $dataset->id();
		my $name = $dataset->name();
		my $description = $dataset->description();
		my $owner = $dataset->owner()->FirstName() . " " . $dataset->owner()->LastName();
		my $status = $dataset->locked() ? "Locked" : " - ";
		my $group = $dataset->group() ? $dataset->group()->Name() : " - ";

		unless ($name eq 'Dummy import dataset') {
			$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
				$q->td({-align => 'center'}, [
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
	
	my $filter_form = $self->__filterForm(@columns);

	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
			-bgcolor => '#000000',
		},
		$q->th({-bgcolor => '#EFEFEF'}, [@columns]),
		$table_data,
		$q->Tr($q->td({-colspan => scalar(@columns), -align => 'center', -bgcolor => '#EFEFEF'}, $filter_form))
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
	my @columns = qw(ID Name Owner Group Description);
	my @projects;

	# Filter the dataset objects if needed
	if ($options->{filter_field} and $options->{filter_text}) {
		carp "Filtering ", $options->{filter_field}, " by ", $options->{filter_text};
		# Get an OME::Dataset cursor for our search with a forced lowercase field
		my $cursor =
			$factory->findObjectsLike("OME::Project", {lc($options->{filter_field}) => $options->{filter_text}});  
		# Iterate and populate list
		while (my $project = $cursor->next()) {
			push (@projects, $project);
		}
	} else {
		@projects = $factory->findObjects("OME::Project");
	}
	
	foreach my $project (@projects) {
		my $id = $project->id();
		my $name = $project->name();
		my $description = $project->description();
		my $owner = $project->owner()->FirstName() . " " . $project->owner()->LastName();
		my $group = $project->group() ? $project->group()->Name() : " - ";
		print STDERR ref($project->owner()), "\n";

		$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
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

	my $filter_form = $self->__filterForm(@columns);
	
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
			-bgcolor => '#000000',
		},
		$q->th({-bgcolor => '#EFEFEF'}, [@columns]),
		$table_data,
		$q->Tr($q->td({-colspan => scalar(@columns), -align => 'center', -bgcolor => '#EFEFEF'}, $filter_form))
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
	my @columns = qw(ID Name Preview Owner Group Description);
	my @images;

	# Filter the dataset objects if needed
	if ($options->{filter_field} and $options->{filter_text}) {
		carp "Filtering ", $options->{filter_field}, " by ", $options->{filter_text};
		# Get a cursor for our search with a forced lowercase field
		my $cursor =
			$factory->findObjectsLike("OME::Image", {lc($options->{filter_field}) => $options->{filter_text}});  
		# Iterate and populate list
		while (my $image = $cursor->next()) {
			push (@images, $image);
		}
	} else {
		@images = $factory->findObjects("OME::Image");
	}

	
	foreach my $image (@images) {
		my $id = $image->id();
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

	my $filter_form = $self->__filterForm(@columns);

	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
			-bgcolor => '#000000',
		},
		$q->th({-bgcolor => '#EFEFEF'}, [@columns]),
		$table_data,
		$q->Tr($q->td({-colspan => scalar(@columns), -align => 'center', -bgcolor => '#EFEFEF'}, $filter_form))
	);


	return $table;
}

sub __genericHeader {
	my $self = shift;
	my ($title) = @_;
	my $q = $self->CGI();

	# Title text
	my $title = $q->p({-class => 'ome_title'}, $title);

	# "Jump To:" selection box form
	my $jump_to = $q->startform({-method => 'get',
			                     -name => 'display',
								 -action => '/perl2/serve.pl'}) .
				  "Display: " .
	              $q->popup_menu({-name => 'type',
						          -values => ['Projects', 'Datasets', 'Images'],
								  -default => 'Projects',}) .
				  "&nbsp" .  # Spacing
				  $q->submit({-name => 'display_filter', -value => 'Go'});
				  $q->endform();

	# Packing table for output
	my $table = $q->table({-border => '0', -width => '100%'},
		$q->Tr($q->td({-align => 'left'}, $title), $q->td({-align => 'right', -valign => 'bottom'}, $jump_to))
	);

	return $table;
}

sub __filterForm {
	my $self = shift;
	my @columns = @_;
	my $q = $self->CGI();

	# Put a "none" on the front
	unshift(@columns, "None");

	# A filter form for filtering display on a Factory like "findObjectsLike" method
	my $form = $q->startform({-method => 'get',
			                  -name => 'filter_form',
							  -action => '/perl2/serve.pl'}) .
			   "Filter on: " .
			   $q->popup_menu({-name => 'filter_field',
					           -values => [@columns],
							   -default => $columns[0],}) .
			    " Text: " .
		        $q->textfield({-name => 'filter_text', -default => '', -size => 15}) .
		        "&nbsp" .  # Spacing
		        $q->submit({-name => 'data_filter', -value => 'Go'});
		        $q->endform();

	return $form;
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
	my ($tables, $header);

	my $type = $q->param('type') || 'projects';  # Projects is the default display
	my $filter_field = $q->param('filter_field') || '';
	my $filter_text = $q->param('filter_text') || '';
	
	# Cleanup so we don't get superfluous propogation
	$q->delete('filter_field', 'filter_text');

	if (lc($type) eq 'datasets') {
		$header = $self->__genericHeader("Datasets");
		$tables = $self->__datasetTable({filter_field => $filter_field,
			                             filter_text  => $filter_text});
	} elsif (lc($type) eq 'projects') {
		$header = $self->__genericHeader("Projects");
		$tables = $self->__projectTable({filter_field => $filter_field,
			                             filter_text  => $filter_text});
	} elsif (lc($type) eq 'images') {
		$header = $self->__genericHeader("Images");
		$tables = $self->__imageTable({filter_field => $filter_field,
			                           filter_text  => $filter_text});
	}

	# XXX Hidden form to store the "Page" parameter for serve.pl
	my $hidden_form = $q->startform() . $q->hidden(-name => 'Page', __PACKAGE__) . $q->endform();

	return ('HTML',
	        $j_format->openInfoProject() .
			$j_format->openInfoDataset() .
			$j_format->popUpImage() .
			$header . $tables . $hidden_form);
}


1;
