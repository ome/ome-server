# OME/Tasks/DatasetManager.pm

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


package OME::Tasks::DatasetManager;


=head1 NAME

OME::Tasks::DatasetManager - manage user's datasets

=head1 SYNOPSIS

	use OME::Tasks::DatasetManager;
	my $projectManager=new OME::Tasks::DatasetManager($session);
	

=head1 DESCRIPTION

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

=head2 addImages ($ref)

Add images to a dataset.

=head2 addToDataset($datasetID,$imageID)
extension of existing method OME::Dataset 


=head2 belong_or_not($datasetID,$projectID)

Check if a given dataset belongs to a given project
(extension of OME::Project::DoesDatasetBelong)

=head2 change ($description,$name,$datasetID)

datasetId (optional) if not defined dataset=current dataset
Modify name/description of a dataset.

=head2 create ($name,$description,$ownerID,$groupID,$projectID,$ref)

projectID (optional) if not defined add to current project
ref (optional) if defined list of image_id 
Create a new dataset with/without images.


=head2 delete ($id)

Delete a dataset, update OME session if the dataset is the current dataset.
If the user doesn't have other dataset: current dataset sets to undef
otherwise set the first (arbitrary in the dataset list) dataset to the current dataset.

=head2 exist ($name)

Check if the dataset's name already exists (in DB).
Return: 1 or undef

=head2 imageNotIn($ref,$datasetID)
ref (optional) ref array: list of group_id
datasetID (optional): dataset=current dataset if not defined

Check images in dataset


=head2 listMatching ($userID,$ref)
if userID defined: check dataset owned by a given user
$ref optional: ref array list of group_id

=head2 load ($datasetID)

Load a dataset object 
Return: dataset object

=head2 lockUnlock ($id,$bool)

Lock/Unlock a dataset

=head2 manage ($ref)
ref (optional) ref array list of group_id


Check dataset used in others project (in a research group)
and the one used by a given user

Return:	ref hash share,use
		count:number of keys in use
		share: dataset used in others projects
		use: info on dataset + project used by a given user.


=head2 newDataset
extension of OME::Project::newDataset



=head2 notBelongToProject ($ref,$projectID)
projectID (optional) if not defined project=current project
ref (optional) ref array list of group_id

Check dataset belonging to research groups if specified.
If project has no dataset, return ref hash of all datasets in Research group
if project has dataset(s), return ref hash of datasets not already used 
 
Return: ref hash

=head2 remove ($ref)

remove datasets from project
parameters: ref hash: key=dataset_id; value=ref array of associated projects.

=head2 share ($ref)
ref (optional) ref array list of group_id


Check datasets owned by the current user
if they are used by others.
Return : ref hash (share,use)
		count:number of keys in share
		count: nb keys in use
		share: datasets owned by the current user but used by other
		use: datasets user owns ONLY used by user.



=head2 switch ($id)

Switch dataset 

=cut


use strict;
use OME::SetDB;
use OME::DBObject;
OME::DBObject->Caching(0);

use OME;
our $VERSION = $OME::VERSION;

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
#	datasetID (optional)

sub addImages{
	my $self=shift;
	my $session=$self->{session};
	my ($ref,$datasetID)=@_;
	my $factory=$session->Factory();
	my $dataset;
	if (defined $datasetID){
		$dataset=$factory->loadObject("OME::Dataset",$datasetID);
	}else{
		$dataset=$session->dataset();
	}

	if (scalar(@$ref)>0){
	  foreach  (@$ref){
		$self->addToDataset($dataset->id(),$_);
	  }
	  $session->dataset($dataset);
	  $session->storeObject();
          $session->commitTransaction();
	  return 1;
	}else{
	  return undef;
	}
	

}


#################
# Parameters
#	datasetID
#	imageID

sub addToDataset{
	my $self=shift;
	my ($datasetID,$imageID)=@_;
 	my $factory=$self->{session}->Factory();
  	my $map = $factory->findObject("OME::Image::DatasetMap",
		 'dataset_id' => $datasetID,
		 'image_id' => $imageID
	);
	if (not defined $map) {
		$map=$factory->newObject("OME::Image::DatasetMap",{
			'dataset_id' => $datasetID,
			'image_id' => $imageID

			} );
	}


}
#################
# Parameters
#	description = dataset's description 
#	name		= dataset's name
#	datasetID (optional)

sub change{
	my $self=shift;
	my $session=$self->{session};
	my ($description,$name,$datasetID)=@_;
	my $dataset;
	if (defined $datasetID){
		$dataset=$session->Factory()->loadObject("OME::Dataset",$datasetID);
	}else{
		$dataset=$session->dataset();
	}
	$dataset->name($name) if defined $name;
	$dataset->description($description) if defined $description;
	$dataset->writeObject();
	return 1;


}

#################
# Parameters:
#	name = dataset's name
#	description = dataset's description
#	ownerID	
#	groupID: user group ID
#	projectID (optional)
#	ref = ref array of image_id to add (optional)

sub create{
	my $self=shift;
	my $session=$self->{session};
	my ($name,$description,$ownerID,$groupID,$projectID,$ref)=@_;
	if (defined $ref){
	 return undef if (scalar(@$ref)==0);
	}
	my $project;
	if (defined $projectID){
		$project=$session->Factory()->loadObject("OME::Project",$projectID);
	}else{
		$project=$session->project();
	}
	#my $dataset=$session->project()->newDataset($name,$description);
	my $dataset = $self->newDataset($name,$description,$ownerID,$groupID,$project->project_id());

	if ($dataset){
	   $dataset->writeObject();
	   if (defined $ref){
	     	foreach(@$ref){
		 $self->addToDataset($dataset->dataset_id(),$_);
           	}
 	   }
	   $session->dataset($dataset);
	   $session->writeObject();
	}
	return $dataset;

}
################
# Paramaters
#	name= 
#	description=
#	owner=
#	groupID
#	projectID 


sub newDataset{
	my $self=shift;
	my ($name,$description,$ownerID,$groupID,$projectID)=@_;
	my $factory = $self->{session}->Factory();
      my $dataset=$factory->newObject("OME::Dataset",{
		name        => $name,
		description => $description,
		locked      => 'false',
		owner_id    => $ownerID,
		group_id    => $groupID,
	} );
	my $map = $factory->findObject("OME::Project::DatasetMap",
		  'dataset_id' => $dataset->dataset_id(),
		  'project_id' => $projectID
	);
	if (not defined $map) {
		$map=$factory->newObject("OME::Project::DatasetMap",{
			project_id => $projectID,
			dataset_id => $dataset->dataset_id()
			} );
	}
	return $dataset;
	
}

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

	my @tables=();
	#existing
 	@tables=qw(project_dataset_map image_dataset_map);
	#dynamic
	my @tablesDynamic=$session->Factory()->findObjects("OME::DataTable",'granularity'=>'D');
	my @dynamic=();
  	foreach (@tablesDynamic){
  	 push(@dynamic,lc($_->table_name()));
  	}
  	push(@tables,@dynamic);

	$rep=deleteInMap(\@tables,$dataset,$db);
	return undef unless (defined $rep);
	
	if ($dataset->dataset_id()==$currentDataset->dataset_id()){
  	 my $project=$session->project();
	 my @datasets=();
     	 my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->project_id() );
     	 foreach my $d (@dMaps){
      	push(@datasets,$d->dataset());
    	 }

   	 #my @datasets=$project->datasets();
   	 my @new=();
  	 foreach (@datasets){
     		push (@new,$_) unless $_->dataset_id()==$currentDataset->dataset_id();
   	 }
       if (scalar(@new)==0){
	   $session->dataset(undef);
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
# Parameters: 
#	$ref=ref array  list group_id (optional)
#	datasetID (optional)
# Return: ref array of images not used in the current dataset

sub imageNotIn{
	my $self=shift;
	my $session=$self->{session};
	my ($ref,$datasetID)=@_;
	my @groupImages=();
	if (defined $ref){
	  foreach (@$ref){
		push(@groupImages,$session->Factory()->findObjects("OME::Image",'group_id' => $_));
	  }
      }else{
		@groupImages=$session->Factory()->findObjects("OME::Image");
	}
	my $dataset;
	if (defined $datasetID){
		$dataset=$session->Factory()->loadObject("OME::Dataset",$datasetID);
	}else{
		$dataset=$session->dataset();

	}
	my @datasetsImages=();
     	my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$dataset->dataset_id() );
     	foreach my $d (@dMaps){
      	push(@datasetsImages,$d->image());
    	}

	#my @datasetsImages=$dataset->images();
	my $rep=notUsedImages(\@groupImages,\@datasetsImages);	
	return $rep;
}


###################
# Parameters:
#	userID = user id
#	$ref=ref array  list group_id (optional)
# Return: ref array of dataset objects 

sub listMatching{
	my $self=shift;
	my $session=$self->{session};
	my ($userID,$ref)=@_;
	my @list=();
	my $refGene;

	if (defined $userID){
		my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$userID);
	   	foreach my $p (@projects){
		  my @data=();
     		  my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$p->project_id() );
     		  foreach my $d (@dMaps){
      		 push(@data,$d->dataset());
    		 }

		 # my @data=$p->datasets();
	        push(@list,@data);
	     }
	     $refGene=checkDuplicate(\@list);
	}else{
	    my @datasets=();
	    my @keep;
	    if (defined $ref){
		foreach (@$ref){
		      push(@datasets,$session->Factory()->findObjects("OME::Dataset",'group_id'=>$_));
	      }
		    $refGene=\@datasets;

	   }else{
 		   @datasets=$session->Factory()->findObjects("OME::Dataset");
		    $refGene=\@datasets;
	   }
	   # necessary now
	   foreach (@datasets){
		push(@keep,$_) unless ($_->name() eq "Dummy import dataset");
	   }
	   $refGene=\@keep;
	}
	return $refGene;
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
# Parameters: 
#	ref=ref array  list group_id (optional)
# Return:	ref hash share,use
#		count:number of keys in use
#		share: dataset used in others projects
#		use: info on dataset + project used by a given user.

sub manage{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my ($result,$projects)=notMyProject($session,$ref);
	my ($share,$use,$count)=usedDatasets($session,$result,$projects);
	return ($share,$use,$count);  
}


#################
# Parameters: 
#	$ref=ref array  list group_id (optional)
#	$projectID (optional)
# Return: ref hash

sub notBelongToProject{
	my $self=shift;
	my ($ref,$projectID)=@_;
	my $session=$self->{session};
	my $project;
	if (defined $projectID){
		$project=$session->Factory()->loadObject("OME::Project",$projectID);
	}else{
		$project=$session->project();

	}
	my @projectDatasets=();
     	my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->project_id() );
     	foreach my $d (@dMaps){
      	push(@projectDatasets,$d->dataset());
    	}

	#my @projectDatasets=$project->datasets();
	my @groupDatasets=();
	if (defined $ref){
	   foreach (@$ref){
	     push(@groupDatasets,$session->Factory()->findObjects("OME::Dataset",'group_id' =>$_));
	   }
	}else{
	   @groupDatasets = $session->Factory()->findObjects("OME::Dataset") ; 
	}

	my %datasetList=();
	my %listGeneral=();
	# remove empty datasets 
	my @notEmptyDatasets=();

  	foreach (@groupDatasets){
		my @images=();
     		my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$_->dataset_id() );
     		foreach my $d (@dMaps){
      		push(@images,$d->image());
    		}




 		#my @images=$_->images();
	     	if (scalar(@images)>0){
	   		push(@notEmptyDatasets,$_);
	  	}
  	}
	foreach my $d (@notEmptyDatasets) {
		#24-06
		#$listGeneral{$_->ID()}=$_->name();
		$listGeneral{$d->dataset_id()}=$d->name();
		if (not $self->belong_or_not($d->dataset_id,$project->project_id())) {	
			$datasetList{$d->dataset_id()} = $d->name();
		}

		#if (not $self->belong_or_not($_->ID,$project->project_id())) {	
		#	$datasetList{$_->ID()} = $_->name();
		#}


		
	}
	return (scalar(@projectDatasets)==0)?\%listGeneral:\%datasetList;


}

########
# Parameters
#	datasetID
#	projectID

sub belong_or_not{
	my $self=shift;
	my ($datasetID,$projectID)=@_;
	my $session=$self->{session};
	my $factory=$session->Factory();
	return undef unless defined $datasetID and defined $projectID;
	my @datasets =$factory->findObjects("OME::Project::DatasetMap",
				 'dataset_id' => $datasetID, 
				 'project_id' => $projectID
				);
	if (scalar(@datasets)>0){
		return 1
	}else{
		return undef;
	}


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
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->project_id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}



	  # my @datasets=$project->datasets();		#current project
	   if (scalar(@datasets)==0){
		 $session->dataset(undef);
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
# Parameters: 
# 	$ref=ref array  list group_id (optional)
# Return : ref hash (share,use)
#		count:number of keys in share
#		count: nb keys in use
#		share: datasets owned by a given user but used by other
#		use: 	 datasets user owns: ONLY used by user.

sub share{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my ($result)=notMyProject($session,$ref);
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

sub checkDuplicate{
	my ($ref)=@_;
	my %seen=();
  	my $object;
  	my @a=();
  	foreach $object (@$ref){
	 my $id=$object->dataset_id();
    	 push(@a,$object) unless $seen{$id}++;
   	}
  	return \@a;


}

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

##########
sub notMyProject{
	my ($session,$ref)=@_;
	my @groupProjects=();
	if (defined $ref){
		foreach (@$ref){
			push(@groupProjects,$session->Factory()->findObjects("OME::Project",'group_id'=>$_));
		}
 	}else{
	      @groupProjects=$session->Factory()->findObjects("OME::Project");
 	}
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
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->project_id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}


	   #my @datasets=$_->datasets();
	
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
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->project_id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}


		#my @datasets=$_->datasets();
	    foreach my $obj (@datasets){
	 	$share{$obj->dataset_id()}=$obj unless (exists $share{$obj->dataset_id()});
     	    }
        }
	}
	my $count=0;
	foreach (@$projects){
        my %info=();
	  $info{$_->project_id()}=$_;
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->project_id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}

	  #my @datasets=$_->datasets();
        foreach my $dataset (@datasets){
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

