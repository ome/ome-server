# OME/Tasks/ProjectManager.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  J-M Burel <j.burel@dundee.ac.uk>
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


package OME::Tasks::ProjectManager;




our $VERSION = '1.0';


=head 1 NAME

OME::Tasks::ProjectManager - manage user's projects

=head 1 SYNOPSIS

	use OME::Tasks::ProjectManager;
	my $projectManager=new OME::Tasks::ProjectManager($session);
	

=head 1 DESCRIPTION

The OME::Tasks::ProjectManager provides a list of methods to manage user's projects


=head 1 OBTAINING A PROJECTMANAGER

To retrieve an OME::Tasks::ProjectManager to use for managing the project, the
user must log in to OME.  This is done via the
L<OME::SessionManager|OME::SessionManager> class.  Logging in via
OME::SessionManager yields an L<OME::Session|OME::Session> object.

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $projectManager = new OME::Tasks::ProjectManager($session);



=head1 METHODS (ALPHABETICAL ORDER)

=head2 add ($id)

Add an existing dataset to a project.

=head2 change ($description,$name)

Modify name/description of a project.

=head2 create ($ref)

Create a new project and update the OME session i.e. current dataset sets to undef.

=head2 delete ($id)

Delete a project, update OME session if the project is the current project.
If the user doesn't have other project: current project and current dataset set to undef
otherwise set the first (arbitrary in the project list) project (+ dataset) to the current project.

=head2 exist ($name)

Check if the project's name already exists (in DB).
Return: 1 or undef

=head2 listMatching (userID)

List projects owned by a given user if no parameter
List projects in a given Research group if userId parameter

Return: ref array of project objects 

=head2 load ($projectID)

Load a project object 
Return: project object

=head2 switch ($id,$bool)
Switch project 


=cut


use strict;
use OME::SetDB;



sub new{
	my $class=shift;
	my $self={};
	$self->{session}=shift;
	bless($self,$class);
   	return $self;


}

###############################
# Parameters:
# 	id = dataset_id to add

sub add{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $project=$session->project();
	my $dataset=$project->addDatasetID($id);
	#my $object=$session->Factory()->loadObject("OME::Dataset",$dataset->dataset_id());
	$session->dataset($dataset);
	$project->writeObject();
	$session->writeObject();

	return 1;

}


###############################
# Paramaters:
#	description = project's description 
#	name		= project's name

sub change{
 	my $self=shift;
	my $session=$self->{session};
	my ($description,$name)=@_;
	my $project=$session->project();
	$project->name($name) if defined $name;
	$project->description($description) if defined $description;
	$project->writeObject();
	return 1;


}

#####################
# Parameters:
#	ref = project's informations

sub create{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my $existingDataset=$session->dataset();
	my $project = $session->Factory()->newObject("OME::Project", $ref);
	$project->writeObject();

	$session->project($project);

	if (defined $existingDataset){
		 $session->dissociateObject('dataset');
	}
	$session->writeObject();

	return 1;

}

######################
# Parameters:
#	id = project_id to delete

sub delete{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $result=undef;
	my $rep=undef;
	my $currentProject=$session->project();
	my $deleteProject=$session->Factory()->loadObject("OME::Project",$id);
	my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
      my @datasets=$deleteProject->datasets();
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());  	
	if (scalar(@datasets)>0){
	  $result=deleteProjectDatasetMap($deleteProject,\@datasets,$db);
	  return $result unless (defined $result);
	}
	if ($deleteProject->project_id()==$currentProject->project_id()){
	  if (scalar(@projects)==1){
	     $session->dissociateObject('dataset') if scalar(@datasets)>0;
	     $session->dissociateObject('project');
	     $session->writeObject();
	  }else{
		reorganizeSession($session,$deleteProject,\@projects);
 	  }
	}
	$rep=deleteProject($deleteProject,$db);
	$db->Off();
	return $rep;
	 
}

################
# Parameters:
#	name = project's name
# Return: 1 or undef

sub exist{
	my $self=shift;
	my $session=$self->{session};
	my ($name)=@_;
	my @list=$session->Factory()->findObjects("OME::Project",'name'=>$name);
	return scalar(@list)==0?1:undef;
}

###############
# Parameters: no
# Return: ref array of project objects owned by a given user.

sub listMatching{
	my $self=shift;
	my $session=$self->{session};
	my ($userID)=@_;
	my @projects=();
	if (defined $userID){
	   @projects=$session->Factory()->findObjects("OME::Project",'group_id'=>$userID);
	}else{
	   @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
	}
	return \@projects;
}

#sub list{
#	my $self=shift;
#	my $session=$self->{session};
#	my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
#	return \@projects;

#}

##############
# Parameters:
# 	usergpID = user's group_id
# Return : ref array of project objects in a given research group.

#sub listGroup{
#	my $self=shift;
#	my $session=$self->{session};
#	my ($usergpID)=@_;
#	#my @projects=$session->Factory()->findObjects("OME::Project",'group_id'=>$session->User()->Group()->id());
#	my @projects=$session->Factory()->findObjects("OME::Project",'group_id'=>$usergpID);
#	return \@projects;

#}

############
# Parameters:
#	projectID =project_id to load
# Return: project object

sub load{
	my $self=shift;
	my $session=$self->{session};
	my ($projectID)=@_;
	my $project=$session->Factory()->loadObject("OME::Project",$projectID);
	return $project;
}

###############
# Parameters:
#	id = project_id
#	bool (optional) = check associated dataset

sub switch{
	my $self=shift;
	my $session=$self->{session};
	my ($id,$bool)=@_;
	my $project=$session->Factory()->loadObject("OME::Project",$id);
	$session->project($project);
	if (not defined $bool){
	  my @datasets=$project->datasets();
	  if (scalar(@datasets)==0){
	   $session->dissociateObject('dataset'); 		
	  }else{
	   $session->dataset($datasets[0]);
	  }
	}
	$session->writeObject();
	return 1;

}


###########################
# PRIVATE METHODS		  #
###########################

# METHODS DON'T USE delete function of Class::DBI

sub deleteProject{
	my ($deleteProject,$db)=@_;
	my $tableProject="projects";	
 	my ($condition,$result);
 	$condition="project_id=".$deleteProject->project_id();
 	$result=do_request($tableProject,$condition,$db);
 	return (defined $result)?1:undef;
}


sub deleteProjectDatasetMap{
  	my ($deleteProject,$ref,$db)=@_;
  	my $tableProjectMap="project_dataset_map";
  	my $result;
  	foreach (@$ref){
   	 my ($condition);
    	 $condition="project_id=".$deleteProject->project_id()." AND dataset_id=".$_->dataset_id();
    	 $result=do_request($tableProjectMap,$condition,$db);
    	 return undef if (!defined $result);
	
      }
  	return (defined $result)?1:undef;
}



sub reorganizeSession{
	my ($session,$deleteProject,$ref)=@_;
	my @new=();
	foreach (@$ref){
        push(@new,$_) unless $_->project_id()==$deleteProject->project_id();
	}
	my $newproject=$new[0];
	my @newdataset=$newproject->datasets();
	$session->project($newproject);
	if (scalar(@newdataset)==0){
		$session->dissociateObject('dataset');	
	}else{
		$session->dataset($newdataset[0]);
	}
	$session->writeObject(); 
	return 1;
}


sub do_request{
 	my ($table,$condition,$db)=@_;
 	my $result;
 	if (defined $db){
      	$result=$db->DeleteRecord($table,$condition);
	 }
 	return $result;
}

=head1 AUTHOR

JMarie Burel (jburel@dundee.ac.uk)

=head1 SEE ALSO

L<OME::DBObject|OME::DBObject>,
L<OME::Factory|OME::Factory>,
L<OME::SetDB|OME::SetDB>,

=cut

1;

