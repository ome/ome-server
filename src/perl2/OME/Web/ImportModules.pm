# OME/Web/ImportModules.pm
# OME local module browser and importer for the OME Web interface.

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
# Written by: Tom Macura <tmacura@nih.gov> based on
#             ImportImages.pm by Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------

package OME::Web::ImportModules;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use vars qw($VERSION);
use CGI;
use Carp;
use Data::Dumper;
use File::Spec;

# OME Modules
use OME;
use OME::Web::FileTable;
use OME::Web::ImportFiles;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::OMEImport;


#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

use constant UNIX_STYLE => 1;
use constant FTP_STYLE  => 2;

my $STYLE = FTP_STYLE;

sub __getDatasetForm {
	my $self = shift;
	my $q = $self->CGI();
	my $group_id = $self->User()->Group()->id();
	
	my $footer_table = $q->table( {
			-width => '100%',
			-cellspacing => 0,
			-cellpadding => 3,
		},
		$q->Tr( {-bgcolor => '#E0E0E0'},
			$q->td({-align => 'right'},
				$q->a( {
						-href => "#",
						-onClick => "document.forms['datatable'].action.value='import'; document.forms['datatable'].submit(); return false",
						-class => 'ome_widget'
					}, "Import Files"
				),
			),
		),
	);

	my $border_table = $q->table( {
			-class => 'ome_table',
			-width => '100%',
			-cellspacing => 1,
			-cellpadding => 3,
		},
	);	

	return $border_table .
	       $footer_table;
}

sub __getImportBody {
	my $self = shift;
	my $q = $self->CGI();

	# CGI data
	my @import_q = $q->param('import_queue');

	# Session data
	my $factory = $self->Session()->Factory();
	my $uid = $self->Session()->User();
	my $gid = $self->Session()->User()->Group()->id(); 
	my $home_dir = $self->Session()->User()->DataDirectory();
	
	# Import dataset
	my $import_q;

	my $body = $q->p({class => 'ome_title', align => 'center'}, 'Importing Analysis Chains and Modules');

	# If we're running using the FTP style de-taint our paths
	if ($STYLE == FTP_STYLE) {
		my ($good_paths, $bad_paths);

		# De-taint the import queue
		($good_paths, $bad_paths) = $self->OME::Web::ImportFiles::__detaintPaths([@import_q], $home_dir);

		# Report badness
		if (@$bad_paths) {
			foreach (@$bad_paths) {
				$body .= $q->p({class => 'ome_error'},
					"A path '$_' which was not a child of your home directory '$home_dir' or contained illegal characters has been removed from the 'Import Queue'."
				);
			}
		}
		
		# filters that allow only files *.ome and *.xml to be added to the upload queue
		my @good_ome_filenames;
		foreach (@$good_paths) {
			if (($_ =~ m/\.ome$/) || ($_ =~ m/\.xml$/)) {
				push (@good_ome_filenames, $_);
			}else {
				$body .= $q->p({class => 'ome_error'},
					"The file '$_' does not end with .ome or .xml. It has been removed from the 'Import Queue'.");
			}
		}
		@import_q = @good_ome_filenames;
	}

	if (scalar(@import_q) < 1) {
		$body .= $q->p({class => 'ome_error'},
			'You must place at least analysis file in the import queue. Press the BACK button on your browser to try again.');
		return $body;  # Return with failure
	}

	# IMPORT the modules
	while ($self->OME::Web::ImportFiles::__resolveQueue(\@import_q)) {};
		
	OME::Tasks::ImageTasks::forkedImportAnalysisModules(\@import_q);	
	return '';
}

#*********
#********* PUBLIC METHODS
#*********

# Override's OME::Web
sub getPageTitle {
	return "Open Microscopy Environment - Import Analysis Modules and Chains";
} 

# Override's OME::Web
{
	my $menu_text = "Import Modules";

	sub getMenuText { return $menu_text }
}

# Override's OME::Web
sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	foreach ($q->param()) {
		print STDERR "*DEBUG* PARAM[$_]: ", $q->param($_), "\n";
	}
	
	my $body;
	
	if ($q->param('action') && $q->param('action') eq 'import') {
		$body .= $self->__getImportBody();
		if (length ($body)) {
			return ('HTML',$body);
		} else {
		# No body, which means we've forked an import process.
		# redirect to the task viewer.
		return( 'REDIRECT', 'serve.pl?Page=OME::Web::TaskProgress');
		}
	} else {
		$body .= $q->p({class => 'ome_title', align => 'center'}, 'Import Analysis Chains and Modules');
		$body .= $self->OME::Web::ImportFiles::__getQueueBody();
		return ('HTML',$body);
	}
	
}
