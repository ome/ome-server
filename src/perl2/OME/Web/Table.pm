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
use Data::Dumper;

# OME Modules
use OME;
use OME::Web::Helper::JScriptFormat;
use OME::Project;
use OME::Image;
use OME::Dataset;
use OME::ModuleExecution;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

# Global display types, one for each object type we have a table method for
my @DISPLAY_TYPES = qw(Projects Datasets Images MEXes);  # First element is default

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
	my @datasets = $self->__filterObjects( {
			filter_object => 'OME::Dataset',
			filters => $options->{filters},
		}
	);


	my @column_headers = qw(ID Status Name Owner Group Description);

	# If we're showing relations
	if ($options->{relations}) { push(@column_headers, 'Projects Related') }

	# Generate our table data
	foreach my $dataset (@datasets) {
		my $id = $dataset->id();
		my $checkbox = $q->checkbox(-name => 'selected', -value => $id, -label => '');
		my $name = $dataset->name();
		my $description = $dataset->description();
		my $owner = $dataset->owner()->FirstName() . " " . $dataset->owner()->LastName();
		my $status = $dataset->locked() ? "Locked" : " - ";
		my $group = $dataset->group() ? $dataset->group()->Name() : " - ";
		my $relations;
		
		# Gen our relationship checkboxes
		if ($options->{relations}) {
			my @project_relations = $dataset->projects();
			foreach (@project_relations) {
				$relations .= $q->checkbox(
					-name => 'rel_selected',
					-value => $dataset->id . "," . $_->id(),
					-label => $_->name()
				);
				$relations .= $q->br();
			}
			# Yes, this is variable saving :)
			$relations = $q->td({-align => 'left', -bgcolor => '#EFEFEF'}, $relations || '');
		}
		
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
				),
				$relations || '',
			);
		}
	}

    # Options row
    my ($option_buttons, $options_row);

    foreach (@{$options->{options_row}}) {
        $option_buttons .= $q->submit({-name => $_, -value => $_}) . '&nbsp';
    }
                                                                                                          
	if ($option_buttons) {
    	$options_row = $q->Tr({-bgcolor => '#EFEFEF'},
        	$q->td({-colspan => scalar(@column_headers) + 1, -align => 'center'},
            	$q->hidden({-name => 'type', -value => $q->param('type') || 'projects'}), # Propagation
            	$option_buttons,
        	)
    	);
	}
	
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
		$options_row || '',
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
	my @projects = $self->__filterObjects( {
			filter_object => 'OME::Project',
			filters => $options->{filters},
		}
	);
	
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
				$q->a({-href => 'javascript:window.open("/perl2/serve.pl?Page=OME::Web::GetInfo&ProjectID=1");'}, $name),
				$owner,
				$group,
				$description,
				]
			)
		);
	}

	# Options row
	my ($option_buttons, $options_row);

	foreach (@{$options->{options_row}}) {
		$option_buttons .= $q->submit({-name => $_, -value => $_}) . '&nbsp';
	}

	if ($option_buttons) {
		$options_row = $q->Tr({-bgcolor => '#EFEFEF'},
			$q->td({-colspan => scalar(@column_headers) + 1, -align => 'center'},
				$q->hidden({-name => 'type', -value => $q->param('type') || 'projects'}), # Propagation
				$option_buttons,
			)
		);
	}

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->startform(),
		$q->Tr($q->th({-bgcolor => '#EFEFEF'}, ["Select", @column_headers])),
		$table_data,
		$options_row || '',
		$q->endform(),
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
	my @images = $self->__filterObjects( {
			filter_object => 'OME::Image',
			filters => $options->{filters},
		}
	);

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

		# Gen our relationship checkboxes
		if ($options->{relations}) {
			my @dataset_relations = $image->datasets();
			foreach (@dataset_relations) {  # Yet more Dummy joy
				unless($_->name() eq 'Dummy import dataset') {
					$relations .= $q->checkbox(
						-name => 'rel_selected',
						-value => $image->id . "," . $_->id(),
						-label => $_->name()
					);
				}
				$relations .= $q->br();
			}
			# Yes, this is variable saving :)
			$relations = $q->td({-align => 'left', -bgcolor => '#EFEFEF'}, $relations || '');
		}


		$table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
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

    # Options row
    my ($option_buttons, $options_row);
                                                                                                          
    foreach (@{$options->{options_row}}) {
        $option_buttons .= $q->submit({-name => $_, -value => $_}) . '&nbsp';
    }
                                                                                                          
	if ($option_buttons) {
    	$options_row = $q->Tr({-bgcolor => '#EFEFEF'},
        	$q->td({-colspan => scalar(@column_headers) + 1, -align => 'center'},
            	$q->hidden({-name => 'type', -value => $q->param('type') || 'projects'}), # Propagation
            	$option_buttons,
        	)
    	);
	}

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$q->startform(),
		$q->Tr($q->th({-bgcolor => '#EFEFEF'}, ["Select", @column_headers])),
		$table_data,
		$options_row || '',
		$q->endform()
	);

	return $table;
}

sub __MEXTable {
    my $self = shift;
    my $options = shift;
                                                                                                          
    # Method variables
    my $factory = $self->Session()->Factory();
    my $q = $self->CGI();
    my $table_data;
    my @mexes = $self->__filterObjects( {
			filter_object => 'OME::ModuleExecution',
			filters => $options->{filters},
		}
	);

    my @column_headers = qw(ID Timestamp Status Module Dataset Dependence);
                                                                                                          
    # Generate our table data
    foreach my $mex (@mexes) {
        my $id = $mex->id();
        my $checkbox = $q->checkbox(-name => 'selected', -value => $id, -label => '');
        my $status = $mex->status();
		my $module = $factory->loadObject("OME::Module", $mex->module_id());
		my $module_name = $module ? $module->name() : " - ";
		my $timestamp = $mex->timestamp();
		my $dataset = $factory->loadObject("OME::Dataset", $mex->dataset_id());
		my $dataset_name = $dataset ? $dataset->name() : " - ";
                                                                                                          
        $table_data .= $q->Tr({-bgcolor => '#EFEFEF'},
            $q->td({-align => 'center'}, [
                $checkbox,
                $id,
				$timestamp,
				$q->a({-href => "/perl2/serve.pl?Page=OME::Web::ViewMEXresults&MEX_ID=$id"}, $status),
				$module_name,
				$dataset_name,
				"",
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

	my %filter;

	# Copy each of our array based option filters to a filter hash
	foreach (@{$options->{filters}}) {
		$filter{$_->[0]} = $_->[1];
	}

	# Filter the dataset objects if needed
	if ($options->{filters}) { 
		# Get a cursor for our search with a forced lowercase field
		my $cursor = $factory->findObjectsLike($options->{filter_object}, %filter);

		# Iterate and populate list
		while (my $object = $cursor->next()) { push(@objects, $object) }
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
	
	my $type = $q->param('type') || 'projects';  # Projects is the default display
	   $type = lc($type);

	my $filterset = ();
	
	if ($q->param('filter_field') and $q->param('filter_string')) {
		push(@$filterset, [$q->param('filter_field'), $q->param('filter_string')]);
	}
	
	my @options_row = $q->param('options_row');
	
	# Cleanup so we don't get superfluous propagation
	$q->delete('filter_field', 'filter_string', 'selected');

	# Based on the type, gen our page data
	if ($type =~ /dataset/) {
		my $columns = OME::Dataset->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Datasets");
		$main_table = $self->__datasetTable( {
				filters => $filterset,
				options_row => [@options_row],
				relations => $q->param('relations') || 0,
			}
		);
		$filter_table = $self->__genericTableFooter(@column_aliases);
	} elsif ($type =~ /project/) {
		my $columns = OME::Project->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Projects");
		$main_table = $self->__projectTable( {
				filters => $filterset,
				options_row => [@options_row],
			}
		);
		$filter_table = $self->__genericTableFooter(@column_aliases);
	} elsif ($type =~ /image/) {
		my $columns = OME::Image->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("Images");
		$main_table = $self->__imageTable( {
				filters => $filterset,
				options_row => [@options_row],
				relations => $q->param('relations') || 0,
			}
		);
		$filter_table = $self->__genericTableFooter(@column_aliases);
	} elsif ($type =~ /mex/) {
		my $columns = OME::ModuleExecution->__columns();
		my @column_aliases = ("id", keys(%$columns));  # Primary keys aren't in the column list
		$header = $self->__genericTableHeader("MEXes");
		$main_table = $self->__MEXTable( {
				filters => $filterset,
				options_row => [@options_row],
			}
		);
		$filter_table = $self->__genericTableFooter(@column_aliases);
	}

	return (
		'HTML',
		$j_format->openInfoProject() .
		$j_format->openInfoDataset() .
		$j_format->popUpImage() .
		$header . $main_table . $q->p() . $filter_table
	);
}

sub getTable {
	my ($self, $options) = @_;
	my $table;

	$options->{type} = lc($options->{type});

	# Based on our options, gen our table
	if ($options->{type} =~ /dataset/) {
		$table = $self->__datasetTable( {
				filters     => $options->{filters},
				options_row => $options->{options_row},
				relations   => $options->{relations},
			}
		);
	} elsif ($options->{type} =~ /project/) {
		$table = $self->__projectTable( {
				filters     => $options->{filters},
				options_row => $options->{options_row},
			}
		);
	} elsif ($options->{type} =~ /image/) {
		$table = $self->__imageTable( {
				filters     => $options->{filters},
				options_row => $options->{options_row},
				relations   => $options->{relations},
			}
		);
	}

	return $table
}


1;
