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
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
 	return "Open Microscopy Environment - Switch Project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

	# figure out what to do: switch & print form or just print?
	if( $cgi->param('Switch')) {

		# load new project
		my $newProject = $session->Factory()->loadObject("OME::Project", $cgi->param('newProject') )
			or die "Unable to load project (id: ".$cgi->param('newProject')."\n";
		
# FIXME: validate permissions
		
		# switch current project to new project
		$session->project($newProject);
		$session->writeObject();
		
		# print sucess message
		$body .= "Switch sucessful. ";
		$body .= "<p>At this point, session's dataset should be set to undef and you should be directed to validation for this to be dealt with. The second part is easy. Setting session's dataset is harder. Using \$session->dataset( undef ) to do this results in a fatal error. Message is:<br><pre>";
		$body .= "'' is not an object of type 'OME::Dataset' at /Users/josiah/OME/src/perl2//OME/Web/MakeNewProject.pm line 58";
		$body .= "</pre><br>I tried using 1 instead of undef and it gave the message <pre>'1' is not an object...</pre> This demonstrates that the DBI has_a method includes type checking. We need to find a way around this. Anyone got ideas?</p>";
		
		# update titlebar
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
		# this will add a script to reload OME::Home if it's necessary
		$body .= OME::Web::Validation->ReloadHomeScript();

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
	
	$text .= $cgi->startform;
	$text .= "Current project is ".$project->name()."<BR>"
		if(defined $project);

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
			
	$text .= $cgi->endform;
	return $text;
}

1;