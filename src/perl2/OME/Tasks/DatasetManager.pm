# OME/Tasks/DatasetManager.pm

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


package OME::Tasks::DatasetManager;


=head 1 NAME

OME::Tasks::DatasetManager - manage user's datasets

=head 1 SYNOPSIS

	use OME::Tasks::DatasetManager;
	my $projectManager=new OME::Tasks::DatasetManager($session);
	

=head 1 DESCRIPTION

The OME::Tasks::DatasetManager provides a list of methods to manage user's dataset


=head 1 OBTAINING A DATASETMANAGER

To retrieve an OME::Tasks::DatasetManager to use for managing the dataset, the
user must log in to OME.  This is done via the
L<OME::SessionManager|OME::SessionManager> class.  Logging in via
OME::SessionManager yields an L<OME::Session|OME::Session> object.

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $datasetManager = new OME::Tasks::DatasetManager($session);



=head1 METHODS (ALPHABETICAL ORDER)

=head2 addImages

Add images to a dataset.

=head2 change

Modify name/description of a dataset.

=head2 create

Create a new dataset with/without images.


=head2 delete

Delete a dataset, update OME session if the dataset is the current dataset.
If the user doesn't have other dataset: current dataset sets to undef
otherwise set the first (arbitrary in the dataset list) dataset to the current dataset.

=head2 exist

Check if the dataset's name already exists (in DB).
Return: 1 or undef

=head2 imageNotIn

Check images not used in the current dataset

=head2 listAll

Given a user, Check datasets used in user's projects 

Return ref hash of datasets used in projects of a given user

Return: ref array of project objects owned by a given user.

=head2 listGroup

List datasets used in a given Research group
Return : ref array of  dataset objects in a given research group.

=head2 load

Load a dataset object 
Return: dataset object

=head2 lockUnlock

Lock/Unlock a dataset

=head2 manage

Check dataset used in others project (in a research group)
and the one used by a given user

Return:	ref hash share,use
		count:number of keys in use
		share: dataset used in others projects
		use: info on dataset + project used by a given user.

=head2 notBelongToProject

Check dataset belonging to a research group.
If current project has no dataset, return ref hash of all datasets in Research group
if current project has dataset(s), return ref hash of datasets not already used 
 
Return: ref hash

=head2 remove

remove datasets from project
parameters: ref hash: key=dataset_id; value=ref array of associated projects.

=head2 share

Check datasets owned by the current user
if they are used by others.
Return : ref hash (share,use)
		count:number of keys in share
		count: nb keys in use
		share: datasets owned by the current user but used by other
		use: datasets user owns ONLY used by user.



=head2 switch

Switch dataset 



=cut








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

#################
# Parameters:
#	ref= ref array of image_id to add

sub addImages{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my $dataset=$session->dataset();
	if (scalar(@$ref)>0){
	  foreach (@$ref){
		$dataset->addImageID($_);
	  }
	  $session->dataset($dataset);
	  $session->writeObject();
	  return 1;
	}else{
	  return undef;
	}
	

}

#################
# Parameters
#	description = dataset's description 
#	name		= dataset's name

sub change{
	my $self=shift;
	my $session=$self->{session};
	my ($description,$name)=@_;
	my $dataset=$session->dataset();
	$dataset->name($name) if defined $name;
	$dataset->description($description) if defined $description;
	$dataset->writeObject();
	return 1;


}

#################
# Parameters:
#	name = dataset's name
#	description = dataset's description
#	ref = ref array of image_id to add (optional)

sub create{
	my $self=shift;
	my $session=$self->{session};
	my ($name,$description,$ref)=@_;
	if (defined $ref){
	 return undef if (scalar(@$ref)==0);
	}
	my $project=$session->project();
	my $dataset = $project->newDataset($name,$description);
	if ($dataset){
	   $dataset->writeObject();
	   if (defined $ref){
	     	foreach(@$ref){
           	 $dataset->addImageID($_);
	    	}
 	   }
	   $session->dataset($dataset);
	   $session->writeObject();
	}
	return 1;

}

#################
# Parameters:
#	name = dataset's name
#	description = dataset's description


#sub createWithoutImage{
#	my $self=shift;
#	my $session=$self->{session};
#	my ($name,$description)=@_;
#	my $project=$session->project();
#	my $dataset = $project->newDataset($name,$description);
#	if ($dataset){
#	   $dataset->writeObject();
#	   $session->dataset($dataset);
#	   $session->writeObject();
#	   return 1;
#	}else{
#		return undef;
#	}

#}


#################
# Parameters:
#	id = image_id 

sub delete{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $currentDataset=$session->dataset();
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());  
	my $dataset = $session->Factory()->loadObject("OME::Dataset",$id);

	
	my $rep=undef;
	my $result=undef;
	## MUST BE CHANGED
	## Names of OME tables

 	my @tables=qw(project_dataset_map image_dataset_map);
	$rep=deleteInMap(\@tables,$dataset,$db);
	return undef unless (defined $rep);
	
	if ($dataset->dataset_id()==$currentDataset->dataset_id()){
  	 my $project=$session->project();
   	 my @datasets=$project->datasets();
   	 my @new=();
  	 foreach (@datasets){
     		push (@new,$_) unless $_->dataset_id()==$currentDataset->dataset_id();
   	 }
       if (scalar(@new)==0){
	   $session->dissociateObject('dataset');
       }else{
	   $session->dataset($new[0]);
       }
       $session->writeObject();
      }
	$result=deleteDataset($dataset,$db);
	$db->Off();
	return $result;
 }



#################
# Parameters:
#	name = project's name
# Return: 1 or undef

sub exist{
	my $self=shift;
	my $session=$self->{session};
	my ($name)=@_;
	my @list=$session->Factory()->findObjects("OME::Dataset",'name'=>$name);
	return scalar(@list)==0?1:undef;


}

################
# Parameters: no
# Return: ref array of images not used in the current dataset

sub imageNotIn{
	my $self=shift;
	my $session=$self->{session};
	my @groupImages=$session->Factory()->findObjects("OME::Image", 'group_id' =>  $session->User()->Group()->id() );
	my @datasetsImages=$session->dataset()->images();
	my $rep=notUsedImages(\@groupImages,\@datasetsImages);	
	return $rep;
}

################
# Parameters: no
# Return: ref hash of datasets used in projects of a given user

sub listAll{
	my $self=shift;
	my $session=$self->{session};
	my %list=();
	my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
	
	foreach (@projects){
	   my @datasets=$_->datasets();
     	   foreach my $dataset (@datasets){
	     $list{$dataset->dataset_id()}=$dataset->name() unless $list{$dataset->dataset_id()};
         }

	}

	return \%list;
}

##############
# Parameters:
#	userID= user id
# Return: ref array of dataset objects (datasets used in a Research group)

sub listGroup{
	my $self=shift;
	my $session=$self->{session};
	my ($usergpID)=@_;
	my @datasets=$session->Factory()->findObjects("OME::Dataset",'group_id'=>$usergpID);
	return \@datasets;

}


#################
# Parameters:
#	datasetID = dataset_id to load
# Return: dataset object

sub load{
	my $self=shift;
	my $session=$self->{session};
	my ($datasetID)=@_;
	my $dataset=$session->Factory()->loadObject("OME::Dataset",$datasetID);
	return $dataset;

}

#################
# Paramaters:
#	id=dataset_id
#	bool= booleen to lock/unlock dataset

sub lockUnlock{
	my $self=shift;
	my $session=$self->{session};
	my ($id,$bool)=@_;
	my ($table,$condition,$result);
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword()); 
      $table="datasets";
      $condition="dataset_id=".$id;
      my %h=(locked =>"'".$bool."'");
      $result=doUpdate($table,\%h,$condition,$db);
      $db->Off();
 	return $result;


}

###############
# Parameters: no
# Return:	ref hash share,use
#		count:number of keys in use
#		share: dataset used in others projects
#		use: info on dataset + project used by a given user.

sub manage{
	my $self=shift;
	my $session=$self->{session};
	my ($result,$projects)=notMyProject($session);
	my ($share,$use,$count)=usedDatasets($session,$result,$projects);
	return ($share,$use,$count);  
}


#################
# Parameters: no
# Return: ref hash

sub notBelongToProject{
	my $self=shift;
	my $session=$self->{session};
	my $project=$session->project();
	my @projectDatasets=$project->datasets();
	my @groupDatasets = $session->Factory()->findObjects("OME::Dataset", 'group_id' =>$session->User()->Group()->id() ) ; 
	my %datasetList=();
	my %listGeneral=();
	# remove empty datasets 
	my @notEmptyDatasets=();
  	foreach (@groupDatasets){
     	  if (scalar($_->images())>0){
	   push(@notEmptyDatasets,$_);
	  }
  	}
	foreach (@notEmptyDatasets) {
		$listGeneral{$_->ID()}=$_->name();
		if (not $project->doesDatasetBelong($_)) {
			$datasetList{$_->ID()} = $_->name();
		}
	}
	return (scalar(@projectDatasets)==0)?\%listGeneral:\%datasetList;


}

########################
# Parameters:
#	ref= ref hash 
sub remove{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my $result=undef;
	my $project=$session->project();
	my $currentDataset=$session->dataset();
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());  
	
	foreach my $id (keys %$ref){
	  my $dataset = $session->Factory()->loadObject("OME::Dataset",$id);
	  my $list=${$ref}{$id};
	  foreach my $delProjectID (@$list){
	  	$result=removeDataset($id,$delProjectID,$db);
		return undef unless (defined $result);
	  }
	  if ($dataset->dataset_id()==$currentDataset->dataset_id()){
	   my @datasets=$project->datasets();		#current project
	   if (scalar(@datasets)==0){
		 $session->dissociateObject('dataset');
	   }else{
		 $session->dataset($datasets[0]);
	   }
	   $session->writeObject();
	 }

	}
	
	$db->Off();
	return 1;
}


################################
# Parameters: no
# Return : ref hash (share,use)
#		count:number of keys in share
#		count: nb keys in use
#		share: datasets owned by a given user but used by other
#		use: datasets user owns ONLY used by user.

sub share{
	my $self=shift;
	my $session=$self->{session};
	my ($result)=notMyProject($session);
	my ($share,$own,$count,$countown)=shareDatasets($session,$result);
	return ($share,$own,$count,$countown);
}



################################
# Parameters:
#	id= dataset_id


sub switch{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $dataset=$session->Factory()->loadObject("OME::Dataset",$id);
	$session->dataset($dataset);
	$session->writeObject();
	return 1;

}





##########################
# PRIVATE METHODS		 #
##########################

sub deleteDataset{
   	my ($deletedataset,$db)=@_;
   	my $tableDataset="datasets";
   	my ($condition,$result);
   	$condition="dataset_id=".$deletedataset->dataset_id();
   	$result=do_request($tableDataset,$condition,$db);
   	return (defined $result)?1:undef;

}


sub deleteInMap{
	my ($table,$dataset,$db)=@_;
	my $result;
	foreach my $nameTable (@$table){	
	  my ($condition);
        $condition="dataset_id=".$dataset->dataset_id();
        $result=do_request($nameTable,$condition,$db);
        return undef unless (defined $result);
  	} 
      return (defined $result)?1:undef;
}


sub notMyProject{
	my ($session)=@_;
	my @groupProjects=$session->Factory()->findObjects("OME::Project",'group_id'=> $session->User()->Group()->id());
 	my @myProjects=$session->Factory()->findObjects("OME::Project",'owner_id'=> $session->User()->id());
	my $result=notUsed(\@groupProjects,\@myProjects);
	return ($result,\@myProjects);
}


sub notUsed{
 	my ($refa,$refb)=@_;
 	my %in_b=();
 	my @only_a=();
 	foreach (@$refb){
   	  $in_b{$_->project_id()}=1;
 	}
 	foreach (@$refa){
   	  push(@only_a,$_) unless exists $in_b{$_->project_id()};

 	}
 	return scalar(@only_a)==0?undef:\@only_a;

}


sub notUsedImages{
  	my ($refa,$refb)=@_;
  	my %in_b=();
  	my @only_a=();
  	foreach (@$refb){
        $in_b{$_->image_id()}=1;
  	}
  	foreach (@$refa){
    	  push(@only_a,$_) unless exists $in_b{$_->image_id()};
  	}
  	return scalar(@only_a)==0?undef:\@only_a;

}

sub removeDataset{
  	my ($datasetID,$projectID,$db)=@_;
 	 my ($condition,$result,$table);
  	$table="project_dataset_map";
  	$condition="dataset_id=".$datasetID." AND project_id=".$projectID;
  	$result=do_request($table,$condition,$db);
  	return (defined $result)?1:undef;

}

sub shareDatasets{
	my ($session,$result)=@_;
	my @myDatasets=$session->Factory()->findObjects("OME::Dataset",'owner_id' => $session->User()->id() );
      my %userDataset=();
	my %share;
	my %own;
	%userDataset= map {$_->dataset_id() =>$_} @myDatasets;
      %own=%userDataset;

	if (defined $result){
	  foreach (@$result){				# not my projects
	   my @datasets=$_->datasets();
	
	   foreach my $d (@datasets){
      	if (exists $userDataset{$d->dataset_id()}){
			 $share{$d->dataset_id()}=$d;
			 delete($own{$d->dataset_id()});	
       	}
         }
   	  }
	}
	my $count=0;
	my $countown=0;
	foreach (keys %share){
	  $count++;
	  if ($share{$_}->name() eq  "Dummy import dataset"){
		delete($share{$_});
		$count--;
	  }

	}
	foreach (keys %own){
	   $countown++;
	   if ($own{$_}->name() eq  "Dummy import dataset"){
		delete($own{$_});
		$countown--;
	  }
	}
	return (\%share,\%own,$count,$countown);
}


sub usedDatasets{
	my ($session,$result,$projects)=@_;
	my %share=();
	my %used=();
	if (defined $result){
	  foreach (@$result){
	    foreach my $obj ($_->datasets()){
	 	$share{$obj->dataset_id()}=$obj unless (exists $share{$obj->dataset_id()});
     	    }
        }
	}
	my $count=0;
	foreach (@$projects){
        my %info=();
	  $info{$_->project_id()}=$_;	
        foreach my $dataset ($_->datasets()){
          if (exists($used{$dataset->dataset_id()})){
	      my $href= $used{$dataset->dataset_id()}->{project};
            my %fusion=();
	      %fusion=(%$href,%info);
	      $used{$dataset->dataset_id()}->{project}=\%fusion;
	    }else{
		$count++;
	      $used{$dataset->dataset_id()}->{project}=\%info;
	      $used{$dataset->dataset_id()}->{object}=$dataset ;
	   }
       }
  	}
	return (\%share,\%used,$count);

}

#############
# DB work

sub do_request{
 	my ($table,$condition,$db)=@_;
 	my $result;
 
 	if (defined $db){
       $result=$db->DeleteRecord($table,$condition);
 
 	}
 	return $result;

}

sub doUpdate{
  	my ($table,$ref,$condition,$db)=@_;
  	my $result=undef;
  	if (defined $db){
       $result=$db->UpdateRecord($table,$ref,$condition);
 
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

