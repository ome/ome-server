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

# JM change 11-03

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
	my $formatproject;
	my @datasets=();
	my $session = $self->Session();
	# figure out what to do: switch & print form or just print?
	if( $cgi->param('Switch')) {
		my $newProject = $session->Factory()->loadObject("OME::Project", $cgi->param('newProject') )
		or die "Unable to load project (id: ".$cgi->param('newProject').")\n";
		
		# FIXME: validate permissions
		

		# switch current project to new project
		$session->project($newProject);
		$session->writeObject();
		
		#my $formatdataset="";
		my $projectnew=$session->project();
		@datasets=$projectnew->datasets();
		if (scalar(@datasets)==0){
		  $session->dissociateObject('dataset');
		  $session->writeObject();

		  $body.="No Dataset associated to this project. Please define a dataset.";
		  $body .= OME::Web::Validation->ReloadHomeScript();
		  $body .= "<script>top.title.location.href = top.title.location.href;</script>";
		 return('HTML',$body);
		}	
		$session->dataset($datasets[0]);
		$session->writeObject();


		$formatproject=format_project($projectnew,$cgi);
		my $formatdataset=format_dataset($datasets[0]->name(),\@datasets,$cgi);		
		# update titlebar
		$body.=$formatproject;
		$body.=$formatdataset;
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";

		# this will add a script to reload OME::Home if it's necessary
		# $body .= OME::Web::Validation->ReloadHomeScript();

	}
	elsif( $cgi->param('execute')) {

		#$body="";
     		my $newdataset= $session->Factory()->loadObject("OME::Dataset", $cgi->param('newdataset'))
			or die "Unable to load dataset (id: ".$cgi->param('newdataset').")\n";

		$session->dataset($newdataset);
		$session->writeObject();
		my $name=$session->dataset()->name();
		$formatproject=format_project($session->project(),$cgi);
		@datasets=$session->project()->datasets();
		my $formatdata=format_dataset($name,\@datasets,$cgi);
		$body.=$formatproject;
		$body.=$formatdata;
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		# this will add a script to reload OME::Home if it's necessary
		# $body .= OME::Web::Validation->ReloadHomeScript();

      }else{
	# print form
	$body .= $self->print_form();
	}
      return ('HTML',$body);
}

sub print_form {
	my $self = shift;
	my $cgi = $self->CGI();
	my $project = $self->Session()->project();
      my $session =$self->Session();

	# User's projects
     # my @projects = OME::Project->search( owner_id => $self->Session()->User()->id() );
      my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );


      my %projectList = map { $_->project_id() => $_->name()} @projects
		if (scalar @projects) > 0;
	my $text = '';
	$text .= format_project($project,$cgi) if(defined $project);

	$text .= $cgi->startform;
	$text .= $cgi->table(
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



#--------------------
# PRIVATE METHODS
#------------------


sub format_project{
 my ($project,$cgi)=@_;
 my $summary="";
 $summary .= $cgi->h3('Your current project is:') ;
 $summary .= "<P><NOBR><B>Name:</B> ".$project->name()."</NOBR><BR>" ;
 $summary .= "<NOBR><B>ID:</B> ".$project->project_id()."</NOBR><BR>" ;
 $summary .= "<B>Description:</B> ".$project->description()."<BR></P>" ;
 return $summary ;




}

sub format_dataset{
 my ($dataname,$ref,$cgi)=@_;
 my @datasets=();
 my $summary="";
 @datasets=@$ref;
 if (scalar(@datasets)>1){
	# display a list

	my %datasetList= map {$_->dataset_id() => $_->name()} @datasets;
	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
	$summary.="<p> If you want to switch, please choose a dataset in the list below.</p>";
	$summary.=$cgi->startform;
	$summary.=$cgi->table(
			$cgi->Tr( { -valign=>'MIDDLE' },
				$cgi->td( { -align=>'LEFT' },
					$cgi->popup_menu (
						-name => 'newdataset',
						-values => [keys %datasetList],
						-labels => \%datasetList)
					 ),
			$cgi->td( { -align=>'LEFT' },
					$cgi->submit (-name=>'execute',-value=>'Switch') ) ),
		);
	$summary .= $cgi->endform;
		
 }else{
 	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 }
 return $summary;
}




1;
