# OME/Web/ProjectDatasetImage.pm

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
# Original by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
# New version:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::ProjectDatasetImage;

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
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

#*********
#********* PUBLIC METHODS
#*********

{
	my $menu_text = 'Make dataset';

	sub getMenuText { return $menu_text; }
}

sub getPageTitle {
	return "Open Microscopy Environment - Make Dataset from existing images";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $user = $self->Session()->User();

	# Managers
	my $d_manager = new OME::Tasks::DatasetManager;
	
	# Header
	my $body = $cgi->p({-class => 'ome_title', -align => 'center'}, 'Make New Dataset');
	
	# The action that was "clicked"
	my $action = $cgi->param('action') || '';
	
	# Image objects that were selected
	my @selected = $cgi->param('selected');

	if ($action eq 'create') {
		my $name = cleaning($cgi->param('name'));
		my $description = $cgi->param('description') || '';

		unless ($name) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: Name is a required field.');
		} elsif ($d_manager->nameExists($name)) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: This name is already used, please choose another.');
		} else {
			# Action
			# XXX SYNTAX DIFFERENT!!!
			$d_manager->create( {
					name => $name,
					description => $description,
					owner_id => $user->id(),
					group_id => $user->Group()->id(),
				}
			);
			
			# Info
			$body .= $cgi->p({-class => 'ome_info'},
				'Creation of dataset successful.');

			# Reload top-frame
			$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		}
	}
	
	# Input-form
	$body .= $self->__printForm();

    return ('HTML',$body);	
}

#*********
#********* PRIVATE METHODS
#*********

sub __printForm {
	my $self = shift;
	my $q = $self->CGI();
	my $group_id = $self->User()->Group()->id();

	# Managers
	my $i_manager = new OME::Tasks::ImageManager;
	
	# Table generator	
	my $t_generator = new OME::Web::ImageTable;

	my $metadata = $q->Tr({-bgcolor => '#FFFFFF'}, [
		$q->td( [
			$q->span("Name *"),
			$q->textfield( {
					-name => 'name',
					-size => 40
				}
			)
			]
		),
		$q->td( [
			$q->span("Description"),
			$q->textarea( {
					-name => 'description',
					-rows => 3,
					-columns => 50,
				}
			)
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
						-href => "#",
						-onClick => "openExistingDataset($group_id); return false",
						-class => 'ome_widget'
					}, "Existing Datasets"
				),
				"|",
				$q->a( {
						-href => "#",
						-onClick => "document.forms['metadata'].action.value='create'; document.forms['metadata'].submit(); return false",
						-class => 'ome_widget'
					}, "Create Dataset"
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

	# Gen our images table
	my $image_list = $t_generator->getTable( {
			select_column => 1,
		},
		$i_manager->getUserImages()
	);

	return $border_table .
	       $footer_table .
		   $q->endform() .
		   $q->p({-class => 'ome_title', -align => 'center'}, 'Select Image(s)') .
		   $image_list;
}

sub cleaning {
	my ($string)=@_;

	chomp($string);
	$string=~ s/^\s*(.*\S)\s*/$1/;

	return $string;
}


1;
