# OME/Web/ProjectManager.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Web::ProjectManager;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

sub getPageTitle {
	return "Open Microscopy Environment - Project Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	
	# do we need to save?
	# ... check for save in cgi params, save, display message
	# display projects that user owns 
	$body .= $self->print_form();
	

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $session = $self->Session();
	my @userProjects = OME::Project->search( owner_id => $session->User()->experimenter_id );
	my $cgi = $self->CGI();
	my $text = '';
	my $tableRows;
	
	$text .= "You own these projects:<br><br>";
	
	foreach (@userProjects) {
		$tableRows .= 
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$_->name() ),
				$cgi->td( { -align=>'LEFT' },
					$_->project_id() ) );
	}
	
	$text .=
		$cgi->table( { -border=>1 },
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'<b>Name</b>' ),
				$cgi->td( { -align=>'LEFT' },
					'<b>ID</b>' ) ),
			$tableRows );
		
	$text .= '<br><br>What would you like to do with these? Think about it. <a href="mailto:igg@nih.gov,bshughes@mit.edu,dcreager@mit.edu,siah@nih.gov,a_falconi_jobs@hotmail.com">email</a> the developers.';
	
	return $text;

}

1;