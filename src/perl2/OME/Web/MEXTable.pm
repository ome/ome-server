# OME/Web/MEXTable.pm
# HTML table generation class for inclusion or general use. It supports MEXes.

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:	 Chris Allan <callan@blackcat.ca>
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
use Log::Agent;

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

{
	my $menu_text = "MEX's";

	sub getMenuText { return $menu_text }
}

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

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	$self->{search_params} = ['id', 'status', 'module_id'];
	$self->{allow_search} = 1;

	return $self;
}

sub getTable {
	my ($self, $options) = @_;


	# Method variables
	my $factory = $self->Session()->Factory();
	my $q = $self->CGI();
	my $table_data;
	
	if( $self->{allow_search} ) {
		push @{ $options->{options_row} }, "Search";
		# add search parameters to filter
		foreach ( @{ $self->{search_params} } ) {
			$options->{filters}->{$_} = $q->param($_)
				if $q->param($_) and $q->param($_) ne '';
		}
	}
	
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
		( $self->{allow_search} ? $self->__search_row( $options->{select_column} ) : '' ),
		$table_data,
		$q->hidden({-name => 'action', -default => ''}),
		$q->endform()
	);

	return $table . $options_table;
}

sub __search_row {
	my ($self, $check_column) = @_;
	my $q	 = $self->CGI();
	my $factory = $self->Session()->Factory();

	# Module list
	my @modules = $factory->findObjects( "OME::Module", ['name'] );
	my %module_names = map{ $_->id() => $_->name() } @modules;
	my $module_order = [ '', sort( { $module_names{$a} cmp $module_names{$b} } keys( %module_names ) ) ];
	$module_names{''} = "Select a Module";
	
	my $rows = [
		$q->textfield( -name => 'id', -default => $q->param('id') || undef, -size => 5 ),
		undef,
		$q->textfield( -name => 'status', -default => $q->param('status') || undef, -size => 15 ),
		$q->popup_menu( 
			-name	=> 'module_id',
			-values => $module_order,
			-default => $q->param('module_id') || undef,
			-labels	 => \%module_names
		),
		undef
	];
	unshift @$rows, undef if $check_column;

	return $q->Tr({-class => 'ome_td'},
		$q->td({-align => 'center'}, $rows )
	);

}

1;
