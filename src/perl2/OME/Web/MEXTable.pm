# OME/Web/MEXTable.pm
# HTML table generation class for inclusion or general use. It supports MEXes.

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


package OME::Web::MEXTable;

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
use OME::ModuleExecution;

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

	my $columns = OME::ModuleExecution->__columns;
	return ("id", keys(%$columns));
}

# Table header macro
sub __genericTableHeader { shift->SUPER::__genericTableHeader("MEXes"); }

#*********
#********* PUBLIC METHODS
#*********

sub getTable {
	my ($self, $options) = @_;


    # Method variables
    my $factory = $self->Session()->Factory();
    my $q = $self->CGI();
    my $table_data;
    my @mexes = $self->__filterObjects( {
			filter_object => 'OME::ModuleExecution',
			filters => $options->{filters},
		}
	);

    my @column_headers = qw(ID Timestamp Status Module Target);

	# If we're showing select checkboxes
	if ($options->{select_column}) { unshift(@column_headers, 'Select') }

    # Generate our table data
    foreach my $mex (@mexes) {
        my $id = $mex->id();
		my $checkbox;

		if ($options->{select_column}) {
			$checkbox = $q->td({-align => 'center'},
				$q->checkbox(-name => 'selected', -value => $id, -label => '')
			);
		}

        my $status = $mex->status();
		my $module = $factory->loadObject("OME::Module", $mex->module_id());
		my $module_name = $module ? $module->name() : " - ";
		my $timestamp = $mex->timestamp();
		my ($target, $target_name);
		if( $mex->dependence() eq 'I' ) {
			$target = $factory->loadObject("OME::Image", $mex->image_id());
			$target_name = "<b>I</b> ".$target->name();
		} elsif( $mex->dependence() eq 'D' ) {
			$target = $factory->loadObject("OME::Dataset", $mex->dataset_id());
			$target_name = "<b>D</b> ".$target->name();
		}
		$target_name = " - "
			unless $target_name;

        $table_data .= $q->Tr({-class => 'ome_td'},
				$checkbox || '',
            $q->td({-align => 'center'}, [
                $id,
				$timestamp,
				$q->a({-href => "/perl2/serve.pl?Page=OME::Web::ViewMEXresults&MEX_ID=$id"}, $status),
				$module_name,
				$target_name,
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
        $table_data,
		$q->hidden({-name => 'action', -default => ''}),
		$q->endform()
    );

    return $table . $options_table . $self->__instructions();
}

sub __instructions{
	my $self = shift;
	my $q = $self->CGI();

	return $q->table( {-cellspacing => 0, -cellpadding => 3, -width => '100%'},
		$q->Tr(
			$q->td( {
					-align => 'right',
					-bgcolor => '#EFEFEF',
					-class => 'ome_menu_td',
				},
				"Click the Status to view results."
			)
		)
	);

}

1;
