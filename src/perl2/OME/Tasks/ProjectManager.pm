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




use strict;
use OME::SetDB;

our $VERSION = '1.0';

sub new{
	my $class=shift;
	my $self={};
	$self->{session}=shift;
	bless($self,$class);
   	return $self;


}

###############################

sub add{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $project=$session->project();
	my $dataset=$project->addDatasetID($id);
	$session->dataset($dataset);
	$session->writeObject();
	$project->writeObject();
	return 1;

}
###############################

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
sub exist{
	my $self=shift;
	my $session=$self->{session};
	my ($name)=@_;
	my @list=$session->Factory()->findObjects("OME::Project",'name'=>$name);
	return scalar(@list)==0?1:undef;
}

###############
sub list{
	my $self=shift;
	my $session=$self->{session};
	my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
	return \@projects;

}

##############
sub listGroup{
	my $self=shift;
	my $session=$self->{session};
	my ($usergpID)=@_;
	#my @projects=$session->Factory()->findObjects("OME::Project",'group_id'=>$session->User()->Group()->id());
	my @projects=$session->Factory()->findObjects("OME::Project",'group_id'=>$usergpID);
	return \@projects;

}

############
sub load{
	my $self=shift;
	my $session=$self->{session};
	my ($projectID)=@_;
	my $project=$session->Factory()->loadObject("OME::Project",$projectID);
	return $project;
}
###############
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


1;

