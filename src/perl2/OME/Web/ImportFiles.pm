# OME/Web/ImportFiles.pm
# OME local file browser and importer for the OME Web interface.

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


package OME::Web::ImportFiles;

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

#*********
#********* PRIVATE METHODS
#*********


# Build array for hidden CGI import field
sub __processQueue {
	my ($self, $queue, $add, $remove) = @_;

	my %uniq;

	# Build unique hash and add elements
	foreach (@$queue, @$add) { $uniq{$_} = 1; }
	# Remove elements
	foreach (@$remove) { delete($uniq{$_}); }

	return keys(%uniq);
}

# De-taint sub for FTP style
sub __detaintPaths {
	my ($self, $paths, $home_dir) = @_;
		
	# Settle the trailing "/" if it exists
	$home_dir = File::Spec->canonpath($home_dir);

	my (@good_paths, @bad_paths);
	my $home_path_len = scalar(File::Spec->splitdir($home_dir));

	foreach (@$paths) {
		unless (File::Spec->file_name_is_absolute($_)) {
			# This should *NEVER* happen from our code, only if someone
			# is mucking around with the CGI variables.
			carp "*WARNING*: Removing *nasty* non-absolute path '$_' in __detaintPaths().";
			push (@bad_paths, $_);
			next;
		}

		# Settle the trailing "/" if it exists
		$_ = File::Spec->canonpath($_);

		my @parts = File::Spec->splitdir($_);
		
		# First checkpoint (evil characters/sequences in the path)
		if ($_ =~ /\.\.\/|\||\\|\;|\:/) {
			push (@bad_paths, $_);
			next;
		# Second checkpoint (path obviously not below the home dir)
		} elsif (scalar(@parts) < $home_path_len) {
			push (@bad_paths, $_);
			next;
		# Third checkpoint (path is not a child of homedir)
		} elsif (not ($_ =~ /^$home_dir.*/)) {
			push (@bad_paths, $_);	
			next;
		}

		push (@good_paths, $_);
	}

	return (\@good_paths, \@bad_paths);
}

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

	foreach (@user_datasets) { push (@user_dataset_names, $_->name()); }

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

sub __getDirListHeader {
	my ($self, $path_dir) = @_;
	my $q = $self->CGI();
	my $home_dir = $self->Session()->User()->DataDirectory();

	my @dirs = File::Spec->splitdir($path_dir);

	my ($running_path, $path_text, $previous_path);

	foreach (@dirs) {
		$running_path = File::Spec->catdir($running_path, $_);
		unless ($previous_path eq $running_path) {
			$path_text .= $q->a( {
					-href => '#',
					-onClick => "document.forms['datatable'].Path.value='$running_path'; document.forms['datatable'].submit(); return false",
				}, $_ || '/');
			$path_text .= '/' if $_;  # Root directory is empty
		}
		$previous_path = $running_path;
	}

	# Home icon
	my $icon_td = $q->td($q->a({-href => $self->pageURL(ref($self)) . "&Path=$home_dir"},
		$q->img( {
				border => '0',
				src => '/images/home.png',
				width => '24',
				height => '24'
			})
	));

	# Header text
	my $text_td .= $q->td($q->span({-class => 'ome_title', -align => 'center'},
		"Directory Listing ($path_text)"));

	my $header_table = $q->table({-border => '0', cellspacing => '0', cellpadding => '0'},
		$q->Tr($icon_td, $text_td));

	return $q->p($header_table);
}

sub __getQueueBody {
	my $self = shift;
	my $q = $self->CGI();
	my $user = $self->Session()->User();
	my $home_dir = $user->DataDirectory();

	# Path directory
	my $path_dir = $q->param('Path') || $home_dir;
	   $path_dir = File::Spec->canonpath($path_dir);  # Cleanup path

	# Files selected from the dir listing
	my @add_selected = $q->param('add_selected');
	
	# Files selected from the import queue
	my @q_selected = $q->param('q_selected');
	
	# Files selected from the import queue
	my @importq = $q->param('import_queue');

	# Action button clicked on
	my $action = $q->param('action') || '';
	
	# CGI cleanup
	$q->delete('action');
	$q->delete('add_selected');
	$q->delete('q_selected');
	$q->delete('import_queue');

	if ($action eq 'Add to Queue') { $action = 'add'; }
	if ($action eq 'Remove from Queue') { $action = 'remove'; }

	my $body = $q->p({class => 'ome_title', align => 'center'}, 'Import Images');

	# Rebuild importq
	if ($action eq 'add') {
		@importq = $self->__processQueue(\@importq, \@add_selected, undef);

		foreach (@add_selected) {
			$body .= $q->p({-class => 'ome_info'}, "Added: '$_' to the import queue.\n");
		}
	} elsif ($action eq 'remove') {
		@importq = $self->__processQueue(\@importq, undef, \@q_selected);

		foreach (@q_selected) {
			$body .= $q->p({-class => 'ome_info'}, "Removed: '$_' from the import queue.\n");
		}
	}

	# If we're running using the FTP style de-taint our paths
	if ($STYLE == FTP_STYLE) {
		my ($good_paths, $bad_paths);

		# De-taint the root path dir
		($good_paths, $bad_paths) = $self->__detaintPaths([$path_dir], $home_dir);

		# Report badness
		if (@$bad_paths) {
			foreach (@$bad_paths) {
				$body .= $q->p({class => 'ome_error'},
					"You have been returned to your home directory. The path you attempted to enter '$_' was not a child of your home directory '$home_dir' or contained illegal characters."
				);
			}
			$path_dir = $home_dir;
		} else {
			# De-tainted $path_dir
			$path_dir = shift(@$good_paths);
		}
	
		# Also de-taint the importq
		($good_paths, $bad_paths) = $self->__detaintPaths(\@importq, $home_dir);

		# Report badness
		if (@$bad_paths) {
			foreach (@$bad_paths) {
				$body .= $q->p({class => 'ome_error'},
					"A path '$_' which is not a child of your home directory '$home_dir' or which contained illegal characters, was removed from the 'Import Queue'. Please try again or contact your systems administrator."
				);
			}
		}

		@importq = @$good_paths;
	}

	# Table generator
	my $t_generator = new OME::Web::FileTable;

	$body .= $q->startform({name => 'datatable'});

	# Import queue *hidden*
	$body .= $q->hidden({name => 'import_queue', default => \@importq});

	# Path *hidden*
	$body .= $q->hidden({name => 'Path', default => $path_dir});	
	
	# Action *hidden*
	$body .= $q->hidden({-name => 'action', -default => ''});

	$body .= $self->__getDatasetForm();

	# Directory listing table
	my $dir_list_table = $t_generator->getTable( {
			select_column => '1',
			select_name => 'add_selected',
			parent_pagelink => $self->pageURL(ref($self)),
			parent_form => '1',
			options_row => ["Add to Queue"],
		}, $path_dir);
	my $dir_list_header = $self->__getDirListHeader($path_dir);

	# Import queue table
	my $importq_table = $t_generator->getTable ( {
			select_column => '1',
			select_name => 'q_selected',
			parent_pagelink => $self->pageURL(ref($self)),
			parent_form => '1',
			options_row => ["Remove from Queue"],
		}, @importq);
	my $importq_header = $q->p({-class => 'ome_title', -align => 'center'}, 'Import Queue');

	# Packing table
	$body .= $q->table({width => '100%', border => '0'}, $q->Tr( [
			$q->td({align => 'center'}, $dir_list_header) .
			$q->td({align => 'center'}, $importq_header),
			$q->td({valign => 'top', width => '50%'}, $dir_list_table) .
			$q->td({valign => 'top', width => '50%'}, $importq_table),
		])
	);
	
	$body .= $q->endform();

	return $body;
}

sub __getImportBody {
	my $self = shift;
	my $q = $self->CGI();

	# CGI data
	my $new_or_existing = $q->param('new_or_existing');
	my $d_name = $q->param('name') || $q->param('existing_dataset');
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
		($good_paths, $bad_paths) = $self->__detaintPaths([@import_q], $home_dir);

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
	$body .= $q->p({class => 'ome_info_strong'}, "Importing image paths...");
	
	my $info;

	foreach (@import_q) {
		$info .= $q->span({class => 'ome_info'},
			"$_") . $q->br();
	}

	$body .= $q->p($info);

	my $images = OME::Tasks::ImageTasks::importFiles(@import_q);
	my @image_ids;

	if (scalar(@$images) < 1) {
		$body .= $q->p({class => 'ome_error'}, 'Import failed!');
		return $body;  # Return with failure
	} else {
		my $i_count = $q->span({class => 'ome_info_strong'}, scalar(@$images));
		$body .= $q->p({class => 'ome_info'}, "Imported total ($i_count) images.");
		@image_ids = map($_->id(), @$images);
		$d_manager->addImages(\@image_ids, $import_d->id());
	}

	return $body;
}


#*********
#********* PUBLIC METHODS
#*********


# Override's OME::Web
sub getPageTitle {
	return "Open Microscopy Environment - Import Files";
}

# Override's OME::Web
{
	my $menu_text = "Import Files";

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

	my $body;

	if ($q->param('action') && $q->param('action') eq 'import') {
		$body .= $self->__getImportBody();
	} else {
		$body .= $self->__getQueueBody();
	}
	
	return ('HTML',$body);
}


1;
