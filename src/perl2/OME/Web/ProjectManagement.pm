# OME/Web/ProjectMetadata.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Josiah Johnston <siah@nih.gov>
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


package OME::Web::ProjectManagement;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Management";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $project = $session->project()
		or die "Project is not defined for the session.\n";
	my $projectManager      = new OME::Tasks::ProjectManager($session);
	$self->{projectManager} = $projectManager;
	my $datasetManager      = new OME::Tasks::DatasetManager($session);
	$self->{datasetManager} = $datasetManager;
	$self->{htmlFormat}     = new OME::Web::Helper::HTMLFormat;
	my $htmlFormat          = $self->{htmlFormat};
	my $factory             = $session->Factory();
	my $body = "";
	
	# check for validity of session
	if( not defined $project ) {
		$body .= "<script>top.location.href = top.location.href;</script>";
		return ("HTML",$body);
	}

	# revArgs is a hash of value => name pairs for the parameters
	# Select and Remove buttons are named by datasetID and valued by operation
	# In short, this is necessary to detect a Select or Remove action.
	my %revArgs = map { $cgi->param($_) => $_ } $cgi->param();

	# determine action
	if( $cgi->param('save')) {
		my $projectname = $cgi->param('name');
		return ('HTML',"<center><b>Please enter a name for your project.</b></center>".$self->print_form()) unless $projectname;
		if ($project->name() ne $cgi->param('name')) {
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
	} elsif( exists $revArgs{Remove} ) {
		my %h=();
		my @a=($session->project()->project_id());
		
		$h{$revArgs{Remove}} = \@a;
		$datasetManager->remove(\%h);		 
		my @datasets = $session->project()->datasets();

		$body .= "<script>top.location.href = top.location.href;</script>"
			if (scalar(@datasets)==0);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";		
	}
	elsif ( exists $revArgs{Select} ) {
		$datasetManager->switch($revArgs{Select});
		$body .= "Operation successful. Current dataset is: <b>".$session->dataset()->name()."</b><br>";
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}
	# do we need to add a dataset to the project?
	elsif( defined $cgi->param('addDataset') ) {

		$projectManager->add($cgi->param('addDatasetID'));
		$body .= "Dataset <b>".$session->dataset()->name()."</b> successfully added to this project and set to current dataset.<br>";
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	} elsif( $cgi->param('Switch')) {
		$projectManager->switch($cgi->param('newProject'));
		$self->Session()->project()
			or die ref ($self) . " cannot find session via self->Session()->project()";
		
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "<b>Successfully switched project.</b>";

	} 
	
	# print form
	$body .= $self->print_form();
	
	return ('HTML',$body);
}



###################
sub print_form {
	my $self = shift;
	my $cgi        = $self->CGI();
	my $session    = $self->Session();
	my $project    = $session->project();
	my $factory    = $session->Factory();
	my $htmlFormat = $self->{htmlFormat};
	my $userID     = $project->owner_id();
	my $user       = $factory->loadAttribute("Experimenter",$userID);	

	my $projectManager = $self->{projectManager};
	my $ref            = $projectManager->listMatching($session->User()->id());

	my %projectList    = map { $_->id() => $_->name()} grep( $_->id ne $project->id, @$ref );

	my $text = '';

	$text .= $cgi->startform;
	$text .= "<center><h2>Properties</h2></center>";
	$text .= $htmlFormat->formChange("project",$project,$user);
	$text .= $htmlFormat->dropDownTable("newProject",\%projectList,"Switch","Switch Project")
		if( scalar keys %projectList > 0 );
	$text .= "<center><h2>Datasets</h2></center>";
	$text .= $self->formatList();
	$text .= $cgi->endform;
	
	return $text;
}

sub formatList{
	my $self = shift;

	my $session = $self->Session();
	my $cgi     = $self->CGI();
	my $text="";
	my @control;
    my @datasets=$session->project()->datasets();
	my $name=$session->project()->name();
	my $datasetManager = $self->{datasetManager};
	my @a=($session->User()->Group()->id());
	my $refhash=$datasetManager->notBelongToProject(\@a);

	foreach (keys %$refhash){
	  push(@control,$_);
	}

	if (scalar(@datasets)>0){
		$text .= "The current Project <b>".$name."</b> contains these datasets.<br><br>";
		$text.=$self->{htmlFormat}->datasetListInProject(\@datasets);
	}else{
		$text.="The current project <b>".$name."</b> doesn't contain a dataset. <br><br>";

	}
	if (scalar(@control)>0){
	
	 $text.="<p>To add an existing dataset to the current project, choose from the list below.</p>";
	 $text.=$self->{htmlFormat}->dropDownTable("addDatasetID",$refhash,"addDataset","add a Dataset");
	}

	return $text;

}

1;
