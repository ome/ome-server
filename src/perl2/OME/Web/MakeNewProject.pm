# OME/Web/MakeNewProject.pm

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
# Original by:    J-M Burel <j.burel@dundee.ac.uk>
# New version:    Chris Allan <callan@blackcat.ca>
#
#-------------------------------------------------------------------------------


package OME::Web::MakeNewProject;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Tasks::ProjectManager;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Make New Project";
}

{
	my $menu_text = "New Project";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $user = $self->Session()->User();
	my $p_manager = new OME::Tasks::ProjectManager;
	
	my $body = $cgi->p({-class => 'ome_title', -align => 'center'}, 'Make New Project');
	
	# The action that was "clicked"
	my $action = $cgi->param('action') || '';
	
	if ($action eq 'create') {
		my $name = cleaning($cgi->param('name'));
		my $description = $cgi->param('description') || '';

		unless ($name) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: Name is a required field.');
		} elsif ($p_manager->nameExists($name)) {
			# Error
			$body .= $cgi->p({-class => 'ome_error'},
				'ERROR: This name is already used, please choose another.');
		} else {
			# Action
			$p_manager->create( {
					name => $name,
					description => $description,
					owner_id => $user->id(),
					group_id => $user->Group()->id(),
				}
			);
			
            return ('REDIRECT',$self->pageURL('OME::Web::Home'));
		}
	}

	# Input-form
	$body .= $self->__printForm();

	return ('HTML',$body);
}

######################

sub __printForm {
	my $self = shift;
	my $q = $self->CGI();
	my $group_id = $self->User()->Group()->id();

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
						-onClick => "openExistingProject($group_id); return false",
						-class => 'ome_widget'
					}, "Existing Projects"
				),
				"|",
				$q->a( {
						-href => "#",
						-onClick => "document.forms['metadata'].action.value='create'; document.forms['metadata'].submit(); return false",
						-class => 'ome_widget'
					}, "Create Project"
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
		   $q->endform();
}

# Clean superfluous spaces
sub cleaning {
	my ($string)=@_;

	chomp($string);
	$string=~ s/^\s*(.*\S)\s*/$1/;

	return $string;
}


1;
