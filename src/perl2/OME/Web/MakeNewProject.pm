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
	my $ExistingDataset;
      $ExistingDataset=$session->dataset();
      my $user = $session->User() or die "User is not defined for this session";

	# figure out what to do: create a project or print an input form
	if( $cgi->param('CreateProject')) {
	# try to make a project, print status message, include some mechanism
	# 	to redirect to import images if this is a first time login

		
		my $projectname=cleaning($cgi->param('name'));
		return ('HTML',"<b>Please enter a name for your project.</b>") unless $projectname;
	
		# $projectname exists??
		my @nameprojects=OME::Project->search(name=>$projectname);
		return ('HTML',"<b>This name is already used. Please enter a new name for your project.</b>") unless scalar(@nameprojects)==0;
		my $data = {name => $cgi->param('name'),
			description => $cgi->param('description'),
			owner_id => $user->ID(),
			group_id => $user->group()->ID()};
		my $project = $session->Factory()->newObject("OME::Project", $data)
			or die "Failed to create new project ".$cgi->param('name')."\n";
		$project->writeObject();
		$session->project($project);
		$session->writeObject();
		if (defined $ExistingDataset){
		 $session->dissociateObject('dataset');
		 $session->writeObject();

		}
		$body.="<B>YOU DID IT!</B>";

		# this will add a script to reload OME::Home. User will be automatically directed to define a dataset.
		
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "<script>top.location.href = top.location.href;</script>";
	      #$body .= OME::Web::Validation->ReloadHomeScript();
	} else {
		# print an input form
		$body .= print_form($cgi,$user->group()->ID());
	}

    return ('HTML',$body);
}

sub print_form {
 my ($cgi,$usergpid) = @_;
 my $textProjectfields="";
 my $text="";
 my $button=create_button($usergpid);

 $textProjectfields.=$cgi->table(
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
 
 $text.=format_popup();
 $text.= $cgi->startform;
 $text.=$textProjectfields;
 $text.= "<CENTER>".$cgi->submit (-name=>'CreateProject',-value=>'Create Project')."</CENTER><br><br>";
 
 $text.=$button;
 $text .= $cgi->endform;
 $text .= "<br><font size=-1>An asterick (*) denotes a required field</font>";

	return $text;

}

sub format_popup{
  my ($text)=@_;
 $text.=<<ENDJS;
<script language="JavaScript">
<!--
var ID;
function OpenPopUp(id) {
      ID=id;
	var OMEfile;
	var DatasetViewer;
	OMEfile='/perl2/serve.pl?Page=OME::Web::InfoProject&UsergpID='+ID;
	DatasetViewer=window.open(
		OMEfile,
		"ImageViewer",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
	DatasetViewer.focus();
      return false;
}
-->
</script>
ENDJS

return $text;
}
sub create_button{
 my ($id)=@_;
 my $text="";
 $text.=<<END;
	<input type=button
	onclick="return OpenPopUp($id)"
	value="Description existing project(s)"
	name="submit">
END
 return $text;
}













sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}




1;
