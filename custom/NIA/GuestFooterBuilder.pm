# OME/Web/GuestFooterBuilder.pm
# Custom footer generation class for a guest user
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
# Written by: Harry Hochheiser <hsh@nih.gov>, for Mouse Gene Index
#
#-------------------------------------------------------------------------------


package OME::Web::GuestFooterBuilder;

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

$VERSION = $OME::VERSION_STRING;

my $HOME_LOCATION = 'serve.pl?Page=OME::Web::TableBrowse&Base=1';

my $NIH_LOCATION = 'http://www.nih.gov';
my $NIA_LOCATION = 'http://www.grc.nia.nih.gov';
my $MGI_LOCATION = 'http://lgsun.grc.nia.nih.gov/geneindex5'; 
my $OME_LOCATION = 'http://www.openmicroscopy.org';
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

sub getPageFooter {
	my $self = shift;
	my $q = new CGI;

	# border row
	my $border = $q->table({width=> '90%', border =>'0', cellspacing=>'2',
				cellpadding =>'2'},
			       $q->Tr( $q->td ({bgcolor=>'#0080c8'})));
				       
       #links
	my $irp_link = $q->a({href =>"http://www.grc.nia.nih.gov"},
			     "<font size=2 face=arial>NIA IRP Home</font>");

	my $contact_link = $q->a({href =>"http://www.grc.nia.nih.gov/docs/contact.html"},
			     "Contact Us");

	my $access_link = $q->a({href=>"http://www.grc.nia.nih.gov/docs/accessibility.html"},
				"Accessibility");

	my $disclaimer_link = $q->a({href=>"http://www.grc.nia.nih.gov/docs/disclaimer.html"},
				"Disclaimer");

	my $privacy_link = $q->a({href=>"http://www.grc.nia.nih.gov/docs/privacy.html"},
				"Privacy");

	my $nia_home = $q->a({href=>"http://www.nih.gov/nia"},
				"NIA Home");

	my $divider = "&nbsp;&nbsp;|&nbsp;&nbsp;";

	my $first_row_text = $irp_link . $divider . $contact_link . $divider . $disclaimer_link .
  	      $divider . $privacy_link . $divider . $nia_home;
	my $first_row = 
	    $q->table( {width => '90%', border => '0',cellpadding => '2',cellspacing => '2',},
		       $q->Tr ($q->td({ align=>'center'},
				      $first_row_text
				      )
			       )
		       );

	# second row.
	my $nih_link=  $q->a({href => "http://www.nih.gov"},
				$q->img( {
						alt => 'NIH logo - link to NIH Home Page',
						src => '/ome-images/nih.gif',
						border => '0'
					}
				)
			);
	
	my $dhhs_link = $q->a({href=>"http://www.os.dhhs.gov"},
			   $q->img({
					alt=>'DHHS logo - link to DHHS Web site',
					src=>'/ome-images/dhhs.gif',
					border=>'0'
				   }
 				)
			);

	my $firstgov_link = $q->a({href=>"http://www.firstgov.gov"},
			   $q->img({
					alt=>'FirstGov logo - link to FirstGov Web site',
					src=>'/ome-images/firstgov.gif',
					border=>'0'
				   }
 				)
			);

	
	
	# Our glorious header table
	my $second_row = $q->table( {width => '90%', border => '0',
					   cellpadding => '2',	cellspacing => '2',
		},
		$q->Tr(	$q->td( {align => 'center', -width=>'30%' },
				$nih_link),

			$q->td( {align => 'center', -width=>'30%' },
				$dhhs_link),

			$q->td( {align => 'center', -width=>'30%' },
				$firstgov_link
			)
		)

	 );
	return "<center>$border\n"  . $first_row . "\n" .$second_row . "</center>";
    }


1;
