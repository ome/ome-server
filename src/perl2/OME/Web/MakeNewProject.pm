# OME/Web/MakeNewProject.pm

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


# 2do: Add verify form capability to check if they have entered required data in appropriate format.
# 2do: Maintence & redirection after project creation

package OME::Web::MakeNewProject;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Make New Project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

	# figure out what to do: create a project or print an input form
	if( $cgi->param('CreateProject')) {
	# try to make a project, print status message, include some mechanism
	# 	to redirect to import images if this is a first time login

		my $user = $session->User()
			or die "User is not defined for this session";
		my $data = {name => $cgi->param('name'),
			description => $cgi->param('description'),
			owner_id => $user->ID(),
			group_id => $user->group()->ID()};
		my $project = $session->Factory()->newObject("OME::Project", $data)
			or die "Failed to create new project ".$cgi->param('name')."\n";
		$project->writeObject();
		$session->project($project);
		$session->writeObject();
		
		$body .= "<p>At this point, session's dataset should be set to undef and you should be directed to validation for this to be dealt with. The second part is easy. Setting session's dataset is harder. Using \$session->dataset( undef ) to do this results in a fatal error. Message is:<br><pre>";
		$body .= "'' is not an object of type 'OME::Dataset' at /Users/josiah/OME/src/perl2//OME/Web/MakeNewProject.pm line 58";
		$body .= "</pre><br>I tried using 1 instead of undef and it gave the message <pre>'1' is not an object...</pre> This demonstrates that the DBI has_a method includes type checking. We need to find a way around this. Anyone got ideas?</p>";

		# this will add a script to reload OME::Home. User will be automatically directed to define a dataset.
#		$body .= OME::Web::Validation->ReloadHomeScript();
		# javascript to reload titlebar
		$body .= "<script>top.title.location.href = top.title.location.href;</script>"
	} else {
	# print an input form
		$body .= $self->print_form();
	}

    return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $cgi = $self->CGI();
	
	my $text = '';

	$text .= $cgi->startform;
	$text .= "<CENTER>".$cgi->submit (-name=>'CreateProject',-value=>'Create Project')."</CENTER>\n";

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'*Name:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'name', -size=>32) ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3) ) ) );
					
	$text .= $cgi->endform;
	$text .= "<br><font size=-1>An asterick (*) denotes a required field</font>";
	return $text;
}

1;