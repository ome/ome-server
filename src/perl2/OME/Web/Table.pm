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
use Log::Agent;

# OME Modules
use OME;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

#*********
#********* PRIVATE METHODS
#*********

sub __getDisplayLinks {
	my $self = shift;
	my $q = $self->CGI();

	return $q->a({href => 'serve.pl?Page=OME::Web::ProjectTable'}, 'Projects') . ' | ' .
	       $q->a({href => 'serve.pl?Page=OME::Web::DatasetTable'}, 'Datasets') . ' | ' .
	       $q->a({href => 'serve.pl?Page=OME::Web::ImageTable'}, 'Images')     . ' | ' .
	       $q->a({href => 'serve.pl?Page=OME::Web::MEXTable'}, 'MEXes');
}

sub __genericTableHeader {
	my ($self, $title_text) = @_;
	my $q = $self->CGI();

	# Title text, yay variable reuse!
	$title_text = $q->span({-class => 'ome_title'}, $title_text);

	# "Display:" selection box table and form
	my $table = $q->table( {
			-border => '0',
			-width => '100%',
		},
		$q->start_form() .
		$q->Tr(
			$q->td({-align => 'left'}, $title_text),
			$q->td({-align => 'right'},
				$q->b("Display: ") . $self->__getDisplayLinks()
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
			$q->td({-align => 'center', -class => 'ome_action_td'}, 
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

# FIXME: parse incoming search parameters to allow multiple search criteria and operators
#	afterwards, make a help page explaining the search syntax
sub __filterObjects {
	my $self = shift;
	my $options = shift;

	my $factory = $self->Session()->Factory();
	my @objects;

	# Filter the objects if needed
	if ($options->{filters}) { 
		@objects = $factory->findObjectsLike($options->{filter_object}, %{$options->{filters}});
	} else {
		@objects = $factory->findObjects($options->{filter_object});
	}

	return @objects;
}

sub __getRelationTD {
	my ($self, $object, @relations) = @_;
	my $q = $self->CGI();
	my $relation_boxes;

	# Gen relationship checkboxes
	foreach my $relation (@relations) {
		$relation_boxes .= $q->checkbox(
			-name => 'rel_selected',
			-value => $object->id . "," . $relation->id(),
			-label => $relation->name()
		);
		$relation_boxes .= $q->br();
	}
	
	return $q->td({-align => 'left', -class => 'ome_td'}, $relation_boxes || 'None');
}


sub __getOptionsTable {
	my ($self, $options, $span) = @_;
	my $q = $self->CGI();

	unless ($span) {
		carp "WARNING: Span not specified in __getOptionsTR(), using default of 1.";
		$span = 1;
	}

	# Build our buttons
    my $option_buttons;

	my $i = 0;

    foreach (@$options) {
		# Only prepend a pipe ("|") after the first option
		$option_buttons .= ' | ' if $i > 0;
		$option_buttons .= $q->a( {
				-href => "#",
				-onClick => "document.forms['datatable'].action.value='$_'; document.forms['datatable'].submit(); return false",
				-class => 'ome_widget'
			}, $_
		),
		++$i;
    }

	# Build our table and return it
	if ($option_buttons) {
    	return $q->table( {-cellspacing => 0, -cellpadding => 3, -width => '100%'},
			$q->Tr(
				$q->td( {
						-colspan => $span,
						-align => 'right',
						-bgcolor => '#EFEFEF',
						-class => 'ome_menu_td',
					},
					$option_buttons,
				)
			)
		);
	}

	return;
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
	my ($main_table, $header);
	
	# Make a filterset to pass to getTable()
	my $filterset;
	if ($q->param('filter_field') and $q->param('filter_string')) {
		$filterset->{ $q->param('filter_field') } = $q->param('filter_string');
	}
	
	# Cleanup so we don't get superfluous propagation
	$q->delete('filter_field', 'filter_string', 'selected');

	my @column_aliases = $self->__getColumnAliases();
	$header = $self->__genericTableHeader();
	$main_table = $self->getTable( {
				options_row => [$q->param('options_row')],
				relations => $q->param('relations') || 0,
				filters => $filterset || undef,
				select_column => 0,
		},
	);

	
	return (
		'HTML',
		$header . $main_table
	);
}


1;
