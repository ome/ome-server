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


package OME::Web::GuestHeaderBuilder;

#*********
#********* INCLUDES
#*********

use strict;
use CGI qw/-no_xhtml/;
use Carp;

# OME Modules
use OME;
use OME::Task;
use OME::Web;
use base qw(OME::Web::DefaultHeaderBuilder);


#*********
#********* PUBLIC METHODS
#*********


sub getPageHeader {
	my $self = shift;
	my $q = new CGI;

	# Session goodies
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $recent_dataset = $session->dataset();
	my $recent_project = $session->project();

	# Data
	my ($project_links, $dataset_links );

	# Logo image link
	my $logo_link;
	$logo_link =
	    $q->a({href => $self->getHomeLocation()},
		  $q->img( {
		      alt => 'OME Logo',
		      src => '/images/logo_smaller.gif',
#						src => '/images/logo-4.png',
		      border => '0'
			   }
		  )
	    );
	
	# Our glorious header table
	my $header_table = $q->table( {
			width => '100%',
			border => '0',
			cellpadding => '0',
			cellspacing => '0',
		},
		$q->Tr(
		        $q->td({align => 'left', -valign => 'top' },
			),
			$q->td( {-align => 'center', -valign => 'top' },
				$q->span({class => 'ome_menu_title' }, 'Open Microscopy Environment').
				' v'.$self->getVersion()
			),
			$q->td($logo_link),
		)
	);
print 
	return $header_table;
}


1;
