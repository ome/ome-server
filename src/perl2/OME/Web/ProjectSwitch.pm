# OME/Web/ProjectSwitch.pm

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


package OME::Web::ProjectSwitch;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

sub getPageTitle {
	return "Open Microscopy Environment - Project Metadata";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

	# figure out what to do: switch & print form or just print?
	if( $cgi->param('Switch')) {

		# load new project
		my $newProject = $session->Factory()->loadObject("OME::Project", $cgi->param('newProject') );

		# validate input
		if( not defined $newProject ) {
			$body .= "Error: unable to load project (id: ".$cgi->param('newProject')."<br>";
			return ('HTML',$body)
		}
		
		# validate permissions
# FIXME: is this the right way to validate access permission? note: message reflects validation method.
		if(not ($session->User()->group()->group_id() eq $newProject->owner()->group()->group_id()) ) {
			$body .= "You do not have permission to access this. You are not a member of this group";
			return ('HTML',$body);
		}
		
		# switch current project to new project
		$session->project($newProject);
		$session->writeObject();
		
		# print sucess message
		$body .= "Switch sucessful. ";
		
		# update titlebar
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}
	# print form
	$body .= $self->print_form();

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $cgi = $self->CGI();
	my $project = $self->Session()->project();
	# find all projects involving user's group
	my @projects = OME::Project->search( group_id => $self->Session()->User()->group()->group_id() );
	my %projectList = map { $_->project_id() => $_->name()} @projects
		if (scalar @projects) > 0;
	my $text = '';
	
	$text .= "\n".$cgi->startform;
	$text .= "Current project is ".$project->name()."<BR>";

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'newProject',
						-values => [keys %projectList],
						-labels => \%projectList
					) ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'Switch',-value=>'Switch Projects') ) ),
		);
			
	$text .= $cgi->endform."\n";
	return $text;
}

1;