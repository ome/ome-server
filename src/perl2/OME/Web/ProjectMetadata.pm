# OME/Web/ProjectMetadata.pm

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


package OME::Web::ProjectMetadata;

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
	return "Open Microscopy Environment - Project Metadata";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $project = $session->project()
		or die "Project is not defined for the session.\n";
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $factory=$session->Factory();
	my $body = "";
	

	# figure out what to do: save & print info or just print?
	if( $cgi->param('save')) {
	  # FIXME: Some validation is needed here
	  my $projectname=cleaning($cgi->param('name'));
	  return ('HTML',"<b>Please enter a name for your project.</b>") unless $projectname;
	  if ($project->name() ne $cgi->param('name')){
         my $ref=$projectManager->exist($cgi->param('name'));
	   return ('HTML',"<b>This name is already used. Please enter a new name for your project.</b>") unless (defined $ref);
        }

		
	 my $reloadTitleBar = ($project->name() eq $cgi->param('name') ? undef : 1);
	 # change stuff.
	 $projectManager->change($cgi->param('description'),$cgi->param('name') );
	 $body .= "Save successful<br>";
	
	 # javascript to reload titlebar
	 $body .= "<script>top.title.location.href = top.title.location.href;</script>"
		if $reloadTitleBar;
	 # this will add a script to reload OME::Home if it's necessary
	 $body .= OME::Web::Validation->ReloadHomeScript();
     }
	# print info & form
	my $userID=$project->owner_id();
	my $user=$factory->loadAttribute("Experimenter",$userID);	


	$body .= print_form($project,$htmlFormat,$cgi,$user);

    return ('HTML',$body);
}



###################
sub print_form {
	my ($project,$htmlFormat,$cgi,$user) =@_;
	my $text = '';

	$text .= $cgi->startform;
	$text .=$htmlFormat->formChange("project",$project,$user);
	$text .= $cgi->endform;
	
	return $text;
}

#-----------------
# PRIVATE METHODS
#------------------


sub cleaning{
	my ($string)=@_;
	chomp($string);
	$string=~ s/^\s*(.*\S)\s*/$1/;
	return $string;

}



1;
