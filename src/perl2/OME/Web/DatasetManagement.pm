# OME/Web/DatasetManagement.pm

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
# Original by:    Josiah <siah@nih.gov>
# New version:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::DatasetManagement;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageManager;
use OME::Web::ImageTable;
use Carp;

use base qw{ OME::Web };

#*********
#********* PUBLIC METHODS
#*********

{
	my $menu_text = 'Manage Dataset';

	sub getMenuText {
		return $menu_text;
	}
}

sub getPageTitle {
	return "Open Microscopy Environment - Dataset Management";
}

sub getPageBody {
	my $self = shift;
	my $cgi     = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $dataset;

	# Managers;
	my $d_manager = new OME::Tasks::DatasetManager;
	my $i_manager = new OME::Tasks::ImageManager;
	
	if ($cgi->param('DatasetID')) {
		$self->{__dataset} = $dataset = $d_manager->load($cgi->param('DatasetID'));
	} else {
		$self->{__dataset} = $dataset = $session->dataset();
	}
	
	croak "Dataset not specified or Dataset ID not found" unless $dataset;

	# Header
	my $body = $cgi->p({-class => 'ome_title', -align => 'center'}, $dataset->name() . ' Properties');

	# Image objects that were selected
	my @selected = $cgi->param('selected');

	# The action that was "clicked"
	my $action = $cgi->param('action') || '';
	
	# determine action
	if ($action eq 'save') {
		my $new_name = $cgi->param('name');
		my $new_description = $cgi->param('description') || '';

		unless ($new_name) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'}, 'ERROR: Name is a required field.');
		} elsif (($dataset->name() ne $new_name) and ($d_manager->nameExists($new_name))) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: This name is already used, please choose another.'
			);
		} else { 
			# Action
			$d_manager->change($new_description, $new_name, $dataset->id());

			# Data
			$body .= $cgi->p({-class => 'ome_info'}, 'Save of new project metadata successful.');
		}
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
	my $dataset    = $self->{__dataset};

	my $metadata = $q->Tr({-bgcolor => '#FFFFFF'}, [
		$q->td( [
			$q->span("Name *"),
			$q->textfield( {
					-name => 'name',
					-value => $dataset->name(),
					-size => 40
				}
			)
			]
		),
		$q->td( [
			$q->span("Description"),
			$q->textarea( {
					-name => 'description',
					-value => $dataset->description(),
					-rows => 3,
					-columns => 50,
				}
			)
			]
		),
		$q->td( [
			$q->span("ID"),
			$q->span($dataset->id()),
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
						-href => $self->pageURL('OME::Web::ImportFiles'),
						-class => 'ome_widget',
					}, "Import Images" 
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
		   $self->__makeImageListings();
}

sub __makeImageListings {
	my $self = shift;
	my $t_generator = new OME::Web::ImageTable;
	my $q = $self->CGI();;
	my $factory = $self->Session()->Factory();
	my $dataset = $self->{__dataset};
	
	# Grab the ID of each of our images that's in the project
	my $in_project;
	foreach ($dataset->images()) { push (@$in_project, $_->id()) }

	# Gen our "Images in Project" table
	my $html = $t_generator->getTable({}, $dataset->images());

	my @additional_images;

	# Only display the datasets that aren't in the project
	foreach my $image ($factory->findObjects("OME::Image")) {
		my $add_this_id = 1;
		foreach my $id_in_project (@$in_project) {
			if ($image->id() == $id_in_project) {
				$add_this_id = 0;
			};
		}
		push(@additional_images, $image->name()) if $add_this_id;
	}

	# Add a null to the beginning
	unshift(@additional_images, 'None');

	# Relationship button
	$html .=
		$q->p() . 
		$q->table( {
				-class => 'ome_table',
				-align => 'center',
				-cellspacing => 1,
				-cellpadding => 4,
			},
			$q->Tr($q->td({style => 'background-color: #D1D7DC'}, $q->a( {
				class => 'ome_widget',
				href => "javascript:openRelationships('OME::Dataset', 'OME::Image', " . $dataset->id() . ");"
			}, 'Add/Remove Images'))),
		);


	return $q->p({-class => 'ome_title', -align => 'center'}, "Images") .
	       $html;
}


1;
