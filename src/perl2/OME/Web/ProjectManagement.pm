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
# Original by:    Josiah Johnston <siah@nih.gov>
# New version:   Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::ProjectManagement;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::DatasetTable;
use Carp;

use base qw{ OME::Web };

#*********
#********* PUBLIC METHODS
#*********

sub getPageTitle {
	return "Open Microscopy Environment - Project Management";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $project;
	
	# Managers
	my $p_manager = new OME::Tasks::ProjectManager;
	my $d_manager = new OME::Tasks::DatasetManager;

	if ($cgi->param('ProjectID')) {
		$self->{__project} = $project = $p_manager->load($cgi->param('ProjectID'));
	} else {
		$self->{__project} = $project = $session->project();
	}

	croak "Project not specified or Project ID not found" unless $project;

	# Header
	my $body = $cgi->p({-class => 'ome_title', -align => 'center'}, $project->name() . " Properties");
	
	# Dataset objects that were selected
	my @selected = $cgi->param('selected');

	# The action that was "clicked"
	my $action = $cgi->param('action') || '';

	# determine action
	if($action eq 'save') {
		my $new_name = $cgi->param('name');
		my $new_description = $cgi->param('description');

		# Error or Action
		unless ($new_name) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'}, 'ERROR: Name is a required field.');
		} elsif (($project->name() ne $new_name) and ($p_manager->nameExists($new_name))) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: This name is already used, please choose another.'
			);
		} else { 
			# Action
			$p_manager->change($new_description, $new_name, $project->id());

			# Data
			$body .= $cgi->p({-class => 'ome_info'}, 'Save of new project metadata successful.');
		}
		
		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

		# this will add a script to reload OME::Home if it's necessary
		$body .= OME::Web::Validation->ReloadHomeScript();
	} elsif ($action eq 'Remove') {
		# Action
		$p_manager->removeDatasets( {
				$project->id() => \@selected
			}
		);
		
		# Data
		$body = $cgi->p({-class => 'ome_info'}, "Removed dataset(s) @selected from the project.");

		# Refresh current frame and/or top frame
		$body .= "<script>top.location.href = top.location.href;</script>"
			if (scalar($project->datasets())==0);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";		
	} elsif ($action eq 'Switch To') {
		# Warning
		if (scalar(@selected) > 1) {
			$body .= $cgi->p({class => 'ome_error'}, 
				"WARNING: Multiple datasets chosen, selecting first choice ID $selected[0].");
		}
		
		# Action
		$d_manager->switch($selected[0]);
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Selected dataset $selected[0] from the project.");

		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	} elsif (defined $cgi->param('Add')) {
		# Action
		my @datasets = $factory->findObjects("OME::Dataset", name => $selected[0]);
		$p_manager->addToProject($datasets[0]->id(), $project->id());
		
		# Data
		$body .= $cgi->p({-class => 'ome_info'}, "Added dataset $selected[0] to the project.");

		# Refresh top frame
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	} 
	
	# print form
	$body .= $self->__printForm();
	
	return ('HTML',$body);
}


#*********
#********* PRIVATE METHODS
#*********

sub __printForm {
	my $self       = shift;
	my $q          = $self->CGI();
	my $user       = $self->Session()->User();
	my $project    = $self->{__project};

	my $metadata = $q->Tr({-bgcolor => '#FFFFFF'}, [
		$q->td( [
			$q->span("Name *"),
			$q->textfield( {
					-name => 'name',
					-value => $project->name(),
					-size => 40
				}
			)
			]
		),
		$q->td( [
			$q->span("Description"),
			$q->textarea( {
					-name => 'description',
					-value => $project->description(),
					-rows => 3,
					-columns => 50,
				}
			)
			]
		),
		$q->td( [
			$q->span("ID"),
			$q->span($project->id()),
			]
		),
		$q->td( [
			$q->span("Owner"),
			$q->a({-href => "mailto: " . $user->Email()},
				$user->FirstName . ' ' . $user->LastName
			),
			]
		),
		$q->td( [
			$q->span("Group"),
			$q->span($user->Group()->Name()),
			]
		),
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
						-href => '/perl2/serve.pl?Page=OME::Web::MakeNewProject',
						-class => 'ome_widget',
					}, "New Project" 
				),
				"|",
				$q->a( {
						-href => "#",
						-onClick => "document.forms['metadata'].action.value='save'; document.forms['metadata'].submit(); return false",
						-class => 'ome_widget'
					}, "Save Changes"
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
		$q->startform({-name => 'metadata'}),
		$q->hidden(-name => 'action', -default => ''),
		$metadata,
	);	

	return $border_table .
	       $footer_table .
	       $q->endform() .
		   $self->__makeDatasetListings();
}

sub __makeDatasetListings {
	my $self = shift;
	my $q = $self->CGI();;
	my $factory = $self->Session()->Factory();
	
	my $project = $self->{__project};
	my $t_generator = new OME::Web::DatasetTable;
	
	# Grab the ID of each of our datasets that's in the project
	my $in_project;
	foreach ($project->datasets()) { push (@$in_project, $_->id()) }
	
	# Gen our "Datasets in Project" table
	my $html = $t_generator->getTable( {
			options_row => ["Switch To", "Remove"],
			select_column => 1,
		},
		$project->datasets()
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
	$html .= $q->p .
	         $q->table( {
					 -class => 'ome_table',
					 -align => 'center',
					 -cellspacing => 1,
					 -cellpadding => 4
				 },
				 $q->Tr(
					 $q->startform(),
					 $q->td(
						 {-class => 'ome_action_td'},
						 '&nbsp',
						 $q->span("Add dataset: "),
						 $q->popup_menu( {
								 -name => 'selected',
								 -values => [@additional_datasets],
								 -default => $additional_datasets[0]
							 }
						 ),
						 '&nbsp',
						 $q->submit({-name => 'Add', -value => 'Add'}),
						 '&nbsp'
					 ),
					 $q->endform()
				 )
			 );


	return $q->p({-class => 'ome_title', -align => 'center'}, "Datasets") .
	       $html;
}

1;
