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
# Written by:    J-M Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::MakeNewProject;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Make New Project";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $manager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;

	my $user=$session->User();
	my $body = "";
	
		if( $cgi->param('create')) {
		
			my $projectname=cleaning($cgi->param('name'));
			return ('HTML',"<b>Please enter a name for your project.</b>") unless $projectname;
	
			# $projectname exists??
			my $ref=$manager->nameExists($projectname);
			return ('HTML',"<b>This name is already used. Please enter a new name for your project.</b>") unless (defined $ref);
		
			my $data = {name => $cgi->param('name'),
				description => $cgi->param('description'),
				owner_id => $user->id(),
				group_id => $user->Group()->id()
				};
			$manager->create($data); 

			# this will add a script to reload OME::Home. User will be automatically directed to define a dataset.
		
			$body .= "<script>top.title.location.href = top.title.location.href;</script>";
			$body .= "<script>top.location.href = top.location.href;</script>";
		} else {
			# print an input form
			$body .= print_form($htmlFormat,$cgi,$user->Group()->id());
		}

    		return ('HTML',$body);
}

######################

sub print_form {
	my ($htmlFormat,$cgi,$usergpid) = @_;
	my $text="";
	$text.= $cgi->startform;
	$text.=$htmlFormat->formCreate("project",$usergpid);
	$text .= $cgi->endform;
	return $text;

}

sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}




1;
