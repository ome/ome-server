# OME/Web/ImportImages.pm
# OME local image browser and importer for the OME Web interface.

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

package OME::Web::ImportImages;

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
	my $d_manager = new OME::Tasks::DatasetManager;

	my $new_or_existing = $q->param('new_or_existing') || '';

	# New Radio Button
	my $new_button_data = {
		type => 'radio',
		name => 'new_or_existing',
		value => 'new',
		checked => 'checked',
	};

	# Existing Radio Button
	my $existing_button_data = {
		type => 'radio',
		name => 'new_or_existing',
		value => 'existing',
		checked => 'checked',
	};

	if ($new_or_existing eq 'existing') {
		delete($new_button_data->{checked});
	} else {
		delete($existing_button_data->{checked});
	}

	my @user_datasets = $d_manager->getUserDatasets();
	my @user_dataset_names;

	foreach (@user_datasets) {
		my $d_name = $_->name();
		push (@user_dataset_names, $d_name)
			unless ($d_name eq 'Dummy import dataset' or
			        $d_name eq 'ImportSet');
	}

	my $metadata = $q->Tr({-bgcolor => '#FFFFFF'}, [
		# ROW
		$q->td($q->input($existing_button_data)) .
		$q->td({width => '25%'}, $q->span('Existing dataset')) .
		$q->td({width => '75%'}, $q->popup_menu( {
					name => 'existing_dataset',
					values => ['None', @user_dataset_names],
					default => 'None',
				}
			)
		),
		# ROW
		$q->td($q->input($new_button_data)) .
		$q->td({width => '25%'}, $q->span("New dataset with name *")) .
		$q->td({width => '75%'}, $q->textfield( {
					-name => 'name',
					-size => 40
				}
			)
		),
		# ROW
		$q->td('') .
		$q->td({width => '25%'}, $q->span("[Description]")) .
		$q->td({width => '75%'}, $q->textarea( {
					-name => 'description',
					-rows => 3,
					-columns => 50,
				}
			)
		)
		]
	);

	my $footer_table = $q->table( {
			-width => '100%',
			-cellspacing => 0,
			-cellpadding => 3,
		},
		$q->Tr( {-bgcolor => '#E0E0E0'},
			$q->td({-align => 'left'},
				$q->span( {
						-class => 'ome_info',
						-style => 'font-size: 10px;',
					}, "Items marked with a * are required unless otherwise specified"
				),
			),
			$q->td({-align => 'right'},
				$q->a( {
						-href => "#",
						-onClick => "openExistingDataset($group_id); return false",
						-class => 'ome_widget'
					}, "Existing Datasets"
				),
				"|",
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
		$metadata,
	);	

	return $border_table .
	       $footer_table;
}

sub __getImportBody {
	my $self = shift;
	my $q = $self->CGI();

	# CGI data
	my $new_or_existing = $q->param('new_or_existing');
	my $d_description = $q->param('description');
	my @import_q = $q->param('import_queue');

	# Session data
	my $factory = $self->Session()->Factory();
	my $uid = $self->Session()->User();
	my $gid = $self->Session()->User()->Group()->id(); 
	my $home_dir = $self->Session()->User()->DataDirectory();

	# Managers
	my $d_manager = new OME::Tasks::DatasetManager;

	# Import dataset
	my $import_d;

	my $body = $q->p({class => 'ome_title', align => 'center'}, 'Importing Images');

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

		@import_q = @$good_paths;
	}

	if (scalar(@import_q) < 1) {
		$body .= $q->p({class => 'ome_error'},
			'You must place at least one image in the import queue. Press the BACK button on your browser to try again.');
		return $body;  # Return with failure
	}

	# DATASET stuff
	if ($new_or_existing eq 'new') {
		my $d_name = $q->param('name');

		unless ($d_name) {
			$body = $q->span({class => 'ome_error'}, 'You must specify a name for the dataset. Press the BACK button on your browser to try again.');
			return $body;  # Return with failure.
		}

		my $info = $q->span({class => 'ome_info'},
			"Creating new dataset: '$d_name' ... ");

		if ($import_d = $d_manager->create($d_name, $d_description, $uid, $gid)) {
			$self->Session->dataset($import_d);
			$info .= $q->span({class => 'ome_info_strong'}, "[DONE]");
			$body .= $q->p($info);
		} else {
			$info .= $q->span({class => 'ome_error'}, "[FAILURE]");
			return $body . $q->p($info);  # Return with failure
		}
	} elsif ($new_or_existing eq 'existing') {
		my $d_name = $q->param('existing_dataset');

		unless($import_d = $factory->findObject("OME::Dataset", name => $d_name)) {
			$body .= $q->p({class => 'ome_error'},
				"Unable to find dataset with name '$d_name'");
			return $body;  # Return with failure
		}
		$body .= $q->p($q->span({class => 'ome_info'},
				"Using existing dataset '$d_name'."));
		
		$self->Session()->dataset($import_d);
	} else {
		croak "Unknown dataset option: '$new_or_existing'";
	}

	unless ($import_d) {
		$body .= $q->p({class => 'ome_error'}, 'Import failed, failure creating or loading import dataset.');
		return $body;  # Return with failure
	}

	# IMPORT
	while ($self->OME::Web::ImportFiles::__resolveQueue(\@import_q)) {};

	OME::Tasks::ImageTasks::forkedImportImages($import_d, \@import_q);

	return '';
}

#*********
#********* PUBLIC METHODS
#*********

# Override's OME::Web
sub getPageTitle {
	return "Open Microscopy Environment - Import Images";
}

# Override's OME::Web
{
	my $menu_text = "Import";

	sub getMenuText { return $menu_text }
}

# Override's OME::Web
sub getOnLoadJS {
	my $js = <<JS;
for (i = 0; i < document.datatable.length; i++)
{
	if (document.datatable.elements[i].type == "checkbox")
		document.datatable.elements[i].checked = false;
}
JS

	return $js;
}

# Override's OME::Web
sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	foreach ($q->param()) {
		print STDERR "*DEBUG* PARAM[$_]: ", $q->param($_), "\n";
	}

	#my $body = '';
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
		$body .= $q->p({class => 'ome_title', align => 'center'}, 'Import Images');
		$body .= $self->OME::Web::ImportFiles::__getQueueBody();
		return ('HTML',$body);
	}
	
}
