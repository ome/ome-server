# OME/Web/DefaultHeaderBuilder.pm
# Default header generation class for a non-overriden getPageHeader()

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


package OME::Web::DefaultHeaderBuilder;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;

# OME Modules
use OME;
use OME::Task;
use OME::Web;
use OME::Tasks::NotificationManager;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;

my $PM_CREATE     = 'serve.pl?Page=OME::Web::DBObjCreate&Type=OME::Project';
my $DM_CREATE     = 'serve.pl?Page=OME::Web::DBObjCreate&Type=OME::Dataset';
my $HOME_LOCATION = 'serve.pl?Page=OME::Web::Home';

#*********
#********* PRIVATE METHODS
#*********

# Session Macro (Pseudo-private)
sub Session { OME::Session->instance() };

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};

	return bless($self,$class);
}

sub getPageHeader {
	my $self = shift;
	my $q = new CGI;

	# Session goodies
	my $session = $self->Session();
	my $recent_dataset = $session->dataset();
	my $recent_project = $session->project();
	my $full_name = $session->User->FirstName . ' ' . $session->User->LastName;

	# Data
	my ($project_links, $dataset_links );

		# Recent project
	if (my $obj = $session->project()) {
		$project_links = 
			$q->span({class => 'ome_quiet'}, 'Most recent project: ') .
			$q->a({href => OME::Web->getObjDetailURL( $obj ), class => 'ome_quiet'}, $obj->name()) .
			' ' .  # Spacing
 			$q->a({class => 'ome_popup', href => 'javascript:openInfoProject(' . $obj->id() .');'}, '(Popup)');
	} else {
		$project_links = 
			$q->span({class => 'ome_quiet'}, 'No recent project. ') .
			$q->a({href => $PM_CREATE, class => 'ome_quiet'}, 'create new');
	}
	
		# Recent dataset
	if (my $obj = $session->dataset()) {
		$dataset_links = 
			$q->span({class => 'ome_quiet'}, 'Most recent dataset: ') .
			$q->a({href => OME::Web->getObjDetailURL( $obj ), class => 'ome_quiet'}, $obj->name()) .
			' ' .  # Spacing
 			$q->a({class => 'ome_popup', href => 'javascript:openInfoProject(' . $obj->id() .');'}, '(Popup)');
	} else {
		$dataset_links = 
			$q->span({class => 'ome_quiet'}, 'No recent dataset. ') .
			$q->a({href => $DM_CREATE, class => 'ome_quiet'}, 'create new');
	}


	# Logo image link
	my $logo_link;
	my @tasks = OME::Tasks::NotificationManager->list(state=>'IN PROGRESS');
	
	# check if the logo 
	if (scalar @tasks) { 
		$logo_link =
			$q->a({href => $HOME_LOCATION},
				$q->img( {
						alt => 'OME Logo',
						src => '/images/logo-sauron.gif',
						border => '0'
					}
				)
			);
	} else {
			$logo_link =
			$q->a({href => $HOME_LOCATION},
				$q->img( {
						alt => 'OME Logo',
						src => '/images/logo_smaller.gif',
						border => '0'
					}
				)
			);
	}
	
	# Our glorious header table
	my $header_table = $q->table( {
			width => '100%',
			border => '0',
			cellpadding => '0',
			cellspacing => '0',
		},
		$q->Tr(
			$q->td($logo_link),
			$q->td( {-align => 'left', -valign => 'top' },
				$q->span({class => 'ome_menu_title' }, 'Open Microscopy Environment').
				' v'.$VERSION
			),
			$q->td({align => 'right', -valign => 'top' },
				$q->span( {
						class => 'ome_quiet',
						style => 'font-weight: bold;'
					}, 'Welcome ' . $full_name),
				$q->br(),
				$project_links,
				$q->br(),
				$dataset_links,
			)
		)
	);

	return $header_table;
}


1;
