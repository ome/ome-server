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


package OME::Web::MakeNewProject;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

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

		my $user = $session->User();
		my $data = {name => $cgi->param('name'),
			description => $cgi->param('description'),
			owner_id => $user->ID(),
			group_id => $user->group()->ID()};
		my $project = $session->Factory()->newObject("OME::Project", $data);
		if (!defined $project) {
			$body .= " Failed to create new project $cgi->param('name').\n";
		}
		else {
			$project->writeObject();
			# is this the first project? if so, we need to redirect to import images
			my $redirectImport = (defined $session->project() ? undef : 1);
			$session->project($project);
			$session->writeObject();
			$body .= "Project creation successful.";

			# update titlebar
			$body .= "<script>top.title.location.href = top.title.location.href;</script>";

			# redirect: import images OR choose datasets?
			if (defined $redirectImport) {
				$body .= " Click ".$cgi->a({href=>'javascript: top.location.href = top.location.href'},'here')." to continue on to import images.";
			} else {
				$body .= "<br>This should redirect you to add datasets to your new project. But that's not implemented yet.";
			}
		}

	
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

	$text .= "\n".$cgi->startform;
	$text .= "<CENTER>\n	".$cgi->submit (-name=>'CreateProject',-value=>'Create Project')."\n</CENTER>\n";

	$text .= 
		$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Name:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textfield(-name=>'name', -size=>32) ) ),
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					'Description:' ),
				$cgi->td( { -align=>'LEFT' },
					$cgi->textarea(-name=>'description', -columns=>32, -rows=>3) ) ) );
			
	$text .= $cgi->endform."\n";
	return $text;
}

1;