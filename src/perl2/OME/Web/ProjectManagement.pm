# OME/Web/ProjectManagement.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::ProjectManagement;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Table;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Management";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $project = $self->Session()->project()
		or die "Project is not defined for the session.\n";
	my $projectManager = new OME::Tasks::ProjectManager;
	my $datasetManager = new OME::Tasks::DatasetManager;

	my $body = $cgi->p({-class => 'ome_title', -align => 'center'}, $project->name() . " Properties");
	
	# Dataset objects that were selected
	my @selected = $cgi->param('selected');

	# determine action
	if( $cgi->param('save')) {
		my $new_name = $cgi->param('name');
		my $new_description = $cgi->param('description');

		# Error or Action
		if (not $new_name) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'}, 'ERROR: Name is a required field.');
		} elsif (($project->name() ne $new_name) and (not $projectManager->exist($new_name))) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: This name is already used, please choose another.'
			);
		} else { 
			# Action
			$projectManager->change($new_description, $new_name);

			# Data
			$body = $cgi->p({-class => 'ome_info'}, 'Save of new project metadata successful.');
		}
		
		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

		# this will add a script to reload OME::Home if it's necessary
		$body .= OME::Web::Validation->ReloadHomeScript();
	} elsif ($cgi->param('Remove')) {
		# Action
		foreach (@selected) {
			$datasetManager->remove( {
					$_ => [$project->id()]
				}
			)
		}
		
		# Data
		$body = $cgi->p({-class => 'ome_info'}, "Removed dataset(s) @selected from the project.");

		# Refresh current frame and/or top frame
		$body .= "<script>top.location.href = top.location.href;</script>"
			if (scalar($project->datasets())==0);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";		
	} elsif ($cgi->param('Delete')) {
		# Action
		foreach (@selected) { $datasetManager->delete($_) }
		
		# Data
		$body = $cgi->p({-class => 'ome_info'}, "Deleted dataset(s) @selected from OME.");

		# Refresh current frame and/or top frame
		$body .= "<script>top.location.href = top.location.href;</script>"
			if (scalar($project->datasets())==0);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";		
	}

	elsif ($cgi->param('Select')) {
		# Warning
		if (scalar(@selected) > 1) {
			$body .= $cgi->p({class => 'ome_error'}, 
				"WARNING: Multiple datasets chosen, selecting first choice ID $selected[0].");
		}
		
		# Action
		$datasetManager->switch($selected[0]);
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Selected dataset $selected[0] from the project.");

		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}
	elsif (defined $cgi->param('Add')) {
		# Action
		my @datasets = $factory->findObjects("OME::Dataset", name => $selected[0]);
		$projectManager->add($datasets[0]->id());
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Added dataset $selected[0] to the project.");

		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	} 
	
	# print form
	$body .= $self->print_form();
	
	return ('HTML',$body);
}



###################
sub print_form {
	my $self = shift;
	my $cgi        = $self->CGI();
	my $session    = $self->Session();
	my $project    = $session->project();
	my $factory    = $session->Factory();
	my $htmlFormat = new OME::Web::Helper::HTMLFormat;
	my $user       = $factory->loadAttribute("Experimenter",$session->User()->id());

	my $text = '';

	$text .= $cgi->startform;
	$text .= $htmlFormat->formChange("project",$project,$user);
	$text .= $cgi->p({-class => 'ome_title', -align => 'center'}, "Datasets");
	$text .= $self->makeDatasetListings($project);
	$text .= $cgi->endform;
	
	return $text;
}

sub makeDatasetListings {
	my ($self, $project) = @_;
	my $t_generator = new OME::Web::Table;
	my $cgi = $self->CGI();;
	my $factory = $self->Session()->Factory();
	
	# Grab the ID of each of our datasets that's in the project
	my $in_project;
	foreach ($project->datasets()) { push (@$in_project, $_->id()) }
	
	# Gen our "Datasets in Project" table
	my $html = $t_generator->getTable( {
			type => 'dataset',
			filters => [ ["id", ['in', $in_project] ] ],
			options_row => ["Switch To", "Remove", "Delete"],
		}
	);

	my @additional_datasets;

	# Only display the datasets that aren't in the project
	foreach my $dataset ($factory->findObjects("OME::Dataset")) {
		my $add_this_id = 1;

		unless ($dataset->name() eq 'Dummy import dataset') {  # Dummy import datasets... joy.  
			foreach my $id_in_project (@$in_project) {
				if ($dataset->id() == $id_in_project) { $add_this_id = 0 }
			}
		} else { $add_this_id = 0 }

		push(@additional_datasets, $dataset->name()) if $add_this_id;
	}

	# Add a null to the beginning
	unshift(@additional_datasets, 'None');

	# Add dataset table
	$html .= $cgi->p .
	         $cgi->table( {
					 -class => 'ome_table',
					 -align => 'center',
					 -cellspacing => 1,
					 -cellpadding => 4
				 },
				 $cgi->Tr(
					 $cgi->startform(),
					 $cgi->td(
						 {-class => 'ome_action_td'},
						 '&nbsp',
						 $cgi->span("Add dataset: "),
						 $cgi->popup_menu( {
								 -name => 'selected',
								 -values => [@additional_datasets],
								 -default => $additional_datasets[0]
							 }
						 ),
						 '&nbsp',
						 $cgi->submit({-name => 'Add', -value => 'Add'}),
						 '&nbsp'
					 ),
					 $cgi->endform()
				 )
			 );


	return $html;
}

1;
