# OME/Web/FileTable.pm
# HTML table generation class for inclusion or general use. It supports Files.

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


package OME::Web::FileTable;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;
use Data::Dumper;
use File::Spec;

# OME Modules
use OME;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web::Table);

#*********
#********* PRIVATE METHODS
#*********

sub __humanize {
	my ($self, $size) = @_;

	if ($size > 1073741824) {
		return sprintf '%dGB', $size / 1073741824, 1;
	} elsif ($size > 1048576) {
		return sprintf '%dMB', $size / 1048576, 1;
	} elsif ($size > 1024) {
		return sprintf '%dK', $size / 1024, 1;
	} else {
		return ($size) . "b";
	}
}

sub __preSort {
	my ($self, @paths) = @_;

	my (@files, @directories);

	foreach (@paths) {
		if (-d $_) { push (@directories, $_) }
		else { push (@files, $_) }
	}

	@directories = sort @directories;
	@files = sort @files;

	return @directories, @files;
}

sub __getParentDir {
	my ($self, $dir_path) = @_;

	my @dirs = File::Spec->splitdir($dir_path);
	pop(@dirs);           # Drop last directory
	unshift(@dirs, "/");  # Prepend root

	return File::Spec->catdir(@dirs);
}

sub __getItemCount {
	my ($self, $dir_path) = @_;

	my @items = <$dir_path/*>;

	return scalar(@items);
}

#*********
#********* PUBLIC METHODS
#*********

sub getTable {
	my ($self, $options, @paths) = @_;

	# Method variables
	my $q = $self->CGI();
	my $table_data;

	my @column_headers = qw(- Filename Date Size);

	# Parent directory
	my $parent_dir;

	# If we're showing select checkboxes
	if ($options->{select_column}) { unshift(@column_headers, 'Select') }

	# File paths from directory
	if ($#paths == 0 and -d $paths[0] and $options->{'traverse'}) {
		unless (-r $paths[0]) {
			return $q->span({class => 'ome_error'}, "Permission denied for '$paths[0]'\n")
		}
		$parent_dir = $self->__getParentDir($paths[0]);

		@paths = <$paths[0]/*>;
	}

	# Directories first, order by name
	@paths = $self->__preSort(@paths);

	# Prepend parent directory if exists (won't if just displaying files)
	if ($parent_dir) {
		$table_data .= $q->Tr({-class => 'ome_td'},
			$q->td(),
			$q->td(),
			$q->td({-align => 'left'},
				$q->a( {
						href => '#',
						-onClick => "document.forms['datatable'].Path.value='$parent_dir'; document.forms['datatable'].submit(); return false",
					}, 'Parent Directory')),
			$q->td({-align => 'right'}, ''),
			$q->td({-align => 'right'}, '-'),
		);
	}

	# Generate our table data
	foreach my $file_path (@paths) {
		# Cleanup path and find file name
		$file_path = File::Spec->canonpath($file_path);

		# Just nix the loop if the path doesn't exist
		unless (-e $file_path) { next; }

		# Directory flag
		my $directory = (-d $file_path) ? 1 : 0;
		
		# Set name link/text
		my $file_name = (File::Spec->splitpath($file_path))[2];
		
		if ($directory) {
			my $item_count = $self->__getItemCount($file_path);
			$file_name = $q->a( {
					-href => '#',
					-onClick => "document.forms['datatable'].Path.value='$file_path'; document.forms['datatable'].submit(); return false",
				}, "$file_name ($item_count Items)");
		}

		# Select checkbox
		my $checkbox;	
		
		if ($options->{select_column}) {
			$checkbox = $q->td({-align => 'center'},
				$q->checkbox({
						-name => $options->{select_name},
						-value => $file_path,
						-label => '',
						-checked => '0',
					}),
			);
		}

		my ($size, $date) = (stat($file_path))[7,8];
		
		# Type icon link
		my $icon_link = $directory ? '/images/dir.gif' : '/images/file.gif';
		   $icon_link = $q->img({src => $icon_link, border => 0});

		# Make human readable size and date
		$size = $self->__humanize($size) if $size;
		$date = scalar(localtime($date)) if $date;

		# Directories only
		$size = '-' if $directory;

		$table_data .= $q->Tr({-class => 'ome_td'},
			$checkbox || '',
			$q->td({-align => 'center'}, $icon_link),
			$q->td({-align => 'left'}, $file_name),
			$q->td({-align => 'right'}, $date),
			$q->td({-align => 'right'}, $size),
		);
	}

    # Get options row
	my $options_table = $self->__getOptionsTable(
		$options->{options_row},
		(scalar(@column_headers) + 1)
	);
	
	my $start_form   = $q->startform({-name => 'datatable'}) unless $options->{parent_form};
	my $end_form     = $q->endform() unless $options->{parent_form};
	my $action_field = $q->hidden({-name => 'action', -default => ''}) unless $options->{parent_form};

	# Populate and return our table
	my $table = $q->table( {
			-class => 'ome_table',
			-cellpadding => '4',
			-cellspacing => '1',
			-border => '0',
			-width => '100%',
		},
		$start_form || '',
		$q->Tr($q->th({-class => 'ome_td'}, [@column_headers])),
		$table_data || '',
		$action_field || '',
		$end_form || '',
	);

	return $table . ($options_table || '');
}


1;
