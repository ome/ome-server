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


=head1 OBTAINING A DATASETMANAGER

To retrieve an OME::Tasks::DatasetManager to use for managing the dataset, the user must log in to OME.  This is done via the L<OME::SessionManager|OME::SessionManager> class.  Logging in via OME::SessionManager yields an L<OME::Session|OME::Session> object.

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $datasetManager = new OME::Tasks::DatasetManager;

=head1 METHODS (ALPHABETICAL ORDER)

The following methods are available to a "DatasetManager."

=head2 addImages ($array_ref, $datasetID)

	$datasetManager->addImages([1,2,5,9], $dataset->id());
	
	$datasetManager->addImages( [1,2,5,9] );

Add images to the current dataset.

Note: The method performs its work on the active dataset ($session->dataset()) if the dataset ID is not specified.

=head2 belong_or_not ($datasetID,$projectID)

	if ($d_manager->belong_or_not($project->id(), $dataset->id())) {
		...
	} else {
		...
	}

Check if a given dataset belongs to a given project. Returns successful (1) or unsuccessful (undef) based on the link's existance.

(extension of OME::Project->DoesDatasetBelong())

=head2 change ($description,$name,$datasetID)

	$datasetManager->change(
		'New description',
		'New Name',
		$dataset->id(),
	);
	
	$datasetManager->change(
		'New description',
		'New Name',
	);

Change a given dataset's metadata.

Note: The method performs its work on the active dataset ($session->dataset()) if the dataset ID is not specified.

=head2 create ($name,$description,$ownerID,$groupID,$projectID,$array_ref)

	my $dataset_a = $datasetManager->create(
		'Great images!',
		'These are really nice images!',
		$session->User->id(),
		$session->User->group()->id(),
		$my_project->id(),
		[1,4,7,9],
	);

	my $dataset_b = $datasetManager->create(
		'Great images again!',
		'These are some more really nice images!',
		$session->User->id(),
		$session->User->group()->id(),
		undef,
		[2,5,7,9],
	);

Create a new dataset with the given parameters and return the dataset object.

Note: The method adds the dataset to the active project ($session->project()) if the project ID is not specified. You can create an imageless dataset using an empty arrayref.

=head2 delete ($id)

	$datasetManager->delete($dataset->id());

Delete a dataset and update OME session if the dataset is the current dataset. If the user doesn't have another dataset, set the current dataset to undefined, otherwise set the first (arbitrary in the dataset list) dataset to the current dataset.

=head2 getAllDatasets ()

	my @datasets = $datasetManager->getAllDatasets();

Get all the datasets in the database.

=head2 getUserDatasets ($experimenter)

	my @user_datasets = $datasetManager->getUserDatasets();
	my @other_user_datasets = $datasetManager->getUserDatasets(
		$other_experimenter
	);

Get all the datasets related to an experimenter.

Note: The method uses the Session's experimenter as a filter if none is specified.

=head2 nameExists ($name)

	if ($datasetManager->nameExists('My unique name')) {
		...
	} else {
		...
	}

Returns successful (1) or unsuccessful (0) based on the dataset name being in the DB.

=head2 imageNotIn ($array_ref,$datasetID)

	my @available_images = $datasetManager->imageNotIn ($datset->id());

Return the images which are not in a given dataset. An optional group ID prefilter is available for those who want to restrict the search to images which are not in the current dataset and are owned by a group to which the user belongs.

	my @available_images = $datasetManager->imageNotIn( [
			$group_a->id(),
			$group_b->id(),
			$session->User()->group(),
		],
		$special_dataset->id(),
	);

Note: If the dataset is not specified the current ($session->dataset()) dataset is used in the search.

=head2 listMatching ($userID,$array_ref)

	my $my_images = $datasetManager->listMatching($user->id());

	my $our_images = $datasetManager->listMatching(
		$session->User()->id(),
		[ $group_a->id(), $group_b->id() ],
	);

Returns an array reference to the images owned by a given user and/or owned by a set of given groups.

=head2 load ($datasetID)

	my $dataset = $datasetManager->load(1);

Return a dataset object via its ID.

=head2 lockUnlock ($id,$bool)

	use constant LOCK => 't';
	use constant UNLOCK => 'f';

	$projectManager->lockUnlock($dataset->id(), LOCK);
	$projectManager->lockUnlock($dataset->id(), UNLOCK);

Lock/Unlock a dataset.

=head2 newDataset ($name,$description,$ownerID,$groupID,$projectID)

	my $new_dataset = $datasetManager->newDataset(
		'My new dataset.',
		'This is my new dataset.',
		$session->User->id(),
		$session->User()->group()->id(),
		$session->project()->id(),
	);

Creates and returns a new dataset.

=head2 notBelongToProject ($array_ref,$projectID)

	my $our_other_projects = $datasetManager->notBelongToProject(
		[$group_a->id(), $group_b->id()],
		$project->id()
	);
	
	my $our_other_projects = $datasetManager->notBelongToProject();


Returns a hash reference to the datasets not used by the specified project.

=head2 remove ($ref)

	$datasetManager->remove( {
		$dataset_a->id() => [$project_y->id(), $project_z->id()],
		$dataset_b->id() => [$project_x->id()],
	);

Remove dataset(s) from project(s).

=head2 share ($ref)

Undocumented.

=head2 switch ($id)

	$datasetManager->switch($new_dataset->id());

Switch the current active dataset.

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

	return bless($self,$class);
}

#################
# Parameters:
#	ref= ref array of image_id to add
#	datasetID (optional)

sub addImages{
	my $self=shift;
	my $session=$self->Session();
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
    my $session=$self->Session();
    my $factory=$session->Factory();
    $factory->maybeNewObject("OME::Image::DatasetMap",
                             {
                              dataset_id => $datasetID,
                              image_id   => $imageID,
                             });
    $session->commitTransaction();
}
#################
# Parameters
#	description = dataset's description 
#	name		= dataset's name
#	datasetID (optional)

sub change{
	my $self=shift;
	my $session=$self->Session();
	my ($description,$name,$datasetID)=@_;
	my $dataset;
	my @groupImages;

	if (defined $datasetID){
		$dataset=$session->Factory()->loadObject("OME::Dataset",$datasetID);
	}else{
		$dataset=$session->dataset();
	}
	$dataset->name($name) if defined $name;
	$dataset->description($description) if defined $description;
	$dataset->storeObject();
	$session->commitTransaction();
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
	my $session=$self->Session();
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
	my $dataset = $self->newDataset($name,$description,$ownerID,$groupID,$project->id());

	if ($dataset){
	   $dataset->storeObject();
	   if (defined $ref){
	     	foreach (@$ref) { $self->addToDataset($dataset->id(),$_) }
 	   }
	   $session->dataset($dataset);
	   $session->storeObject();
	   $session->commitTransaction();
	}
	return $dataset;

}

#################
# Parameters: (void)
# 	
sub getAllDatasets {
	my $self = shift;
	my $factory = $self->Session()->Factory();

	return $factory->findObjects("OME::Dataset");
};

#################
# Parameters: (experimenter object)
#
sub getUserDatasets {
	my ($self, $experimenter) = shift;
	my $factory = $self->Session()->Factory();

	$experimenter = $self->Session()->User() unless defined $experimenter;

	return $factory->findObjects("OME::Dataset", owner_id => $experimenter->id());
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
	my $factory = $self->Session()->Factory();
      my $dataset=$factory->newObject("OME::Dataset",{
		name        => $name,
		description => $description,
		locked      => 'false',
		owner_id    => $ownerID,
		group_id    => $groupID,
	} );
	my $map = $factory->findObject("OME::Project::DatasetMap",
         'dataset_id' => $dataset->id(),
		  'project_id' => $projectID
	);
	if (not defined $map) {
		$map=$factory->newObject("OME::Project::DatasetMap",{
			project_id => $projectID,
      dataset_id => $dataset->id()
			} );
	}
	return $dataset;
	
}

#################
# Parameters:
#	id = image_id 

sub delete{
	my $self=shift;
	my $session=$self->Session();
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
	

  if ($dataset->id()==$currentDataset->id()){
  	 my $project=$session->project();
	 my @datasets=();
     	 my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->id() );
     	 foreach my $d (@dMaps){
      	push(@datasets,$d->dataset());
    	 }

   	 #my @datasets=$project->datasets();
   	 my @new=();
  	 foreach (@datasets){

        push (@new,$_) unless $_->id()==$currentDataset->id();
   	 }
       if (scalar(@new)==0){
	       $session->dataset(undef);
       } else {
	       $session->dataset($new[0]);
       }
       $session->storeObject();
      }
	$result=deleteDataset($dataset,$db);
	$db->Off();
	return $result;
 }



#################
# Parameters:
#	name = project's name
# Return: 1 or 0

sub nameExists{
	my $self=shift;
	my $session=$self->Session();
	my ($name)=@_;
	my @list=$session->Factory()->findObjects("OME::Dataset",'name'=>$name);
	return scalar(@list) > 0 ? 1 : 0;


}

################
# Parameters: 
#	$ref=ref array  list group_id (optional)
#	datasetID (optional)
# Return: ref array of images not used in the current dataset

sub imageNotIn{
	my $self=shift;
	my $session=$self->Session();
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

    my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$dataset->id() );

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
	my $session=$self->Session();
	my ($userID,$ref)=@_;
	my @list=();
	my $refGene;

	if (defined $userID){
		my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$userID);
	   	foreach my $p (@projects){
		  my @data=();
     		  my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$p->id() );
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
	my $session=$self->Session();
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
	my $session=$self->Session();
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

#################
# Parameters: 
#	$ref=ref array  list group_id (optional)
#	$projectID (optional)
# Return: ref hash

sub notBelongToProject{
	my $self=shift;
	my ($ref,$projectID)=@_;
	my $session=$self->Session();
	my $project;
	if (defined $projectID){
		$project=$session->Factory()->loadObject("OME::Project",$projectID);
	}else{
		$project=$session->project();

	}
	my @projectDatasets=();
     	my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->id() );
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

  	foreach my $gd (@groupDatasets){
		    my @images=();
        my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$gd->id() );
        foreach my $d (@dMaps){
      		push(@images,$d->image());
		    }
	      #my @images=$_->images();
	     	if (scalar(@images)>0){
	   	   	push(@notEmptyDatasets,$gd);
	  	  }
  	}
   
   
   
	foreach my $d (@notEmptyDatasets) {
		#24-06
		#$listGeneral{$_->ID()}=$_->name();
     $listGeneral{$d->id()}=$d->name();

    if (not $self->belong_or_not($d->id(),$project->id())) {
			$datasetList{$d->id()} = $d->name();
		}
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
	my $session=$self->Session();
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
	my $session=$self->Session();
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
	  if ($dataset->id()==$currentDataset->id()){
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}



	  # my @datasets=$project->datasets();		#current project
	   if (scalar(@datasets)==0){
		 $session->dataset(undef);
	   }else{
		 $session->dataset($datasets[0]);
	   }
	   $session->storeObject();
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
	my $session=$self->Session();
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
	my $session=$self->Session();
	my ($id)=@_;
	my $dataset=$session->Factory()->loadObject("OME::Dataset",$id);
	$session->dataset($dataset);
	$session->storeObject();
	$session->commitTransaction();
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
	 my $id=$object->id();
    	 push(@a,$object) unless $seen{$id}++;
   	}
  	return \@a;


}

sub deleteDataset{
   	my ($deletedataset,$db)=@_;
   	my $tableDataset="datasets";
   	my ($condition,$result);
   	$condition="dataset_id=".$deletedataset->id();
   	$result=do_request($tableDataset,$condition,$db);
   	return (defined $result)?1:undef;

}


sub deleteInMap{
	my ($table,$dataset,$db)=@_;
	my $result;
	foreach my $nameTable (@$table){	
	  my ($condition);
        $condition="dataset_id=".$dataset->id();
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
   	  $in_b{$_->id()}=1;
 	}
 	foreach (@$refa){
   	  push(@only_a,$_) unless exists $in_b{$_->id()};

 	}
 	return scalar(@only_a)==0?undef:\@only_a;

}


sub notUsedImages{
  	my ($refa,$refb)=@_;
  	my %in_b=();
  	my @only_a=();
  	foreach (@$refb){
        $in_b{$_->id()}=1;
  	}
  	foreach (@$refa){
    	  push(@only_a,$_) unless exists $in_b{$_->id()};
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
	%userDataset= map {$_->id() =>$_} @myDatasets;
      %own=%userDataset;

	if (defined $result){
	  foreach (@$result){				# not my projects
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}


	   #my @datasets=$_->datasets();
	
	   foreach my $d (@datasets){
      	if (exists $userDataset{$d->id()}){
			 $share{$d->id()}=$d;
			 delete($own{$d->id()});
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
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}


		#my @datasets=$_->datasets();
	    foreach my $obj (@datasets){
	 	$share{$obj->id()}=$obj unless (exists $share{$obj->id()});
     	    }
        }
	}
	my $count=0;
	foreach (@$projects){
        my %info=();
	  $info{$_->id()}=$_;
		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->id() );
     		foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    		}

	  #my @datasets=$_->datasets();
        foreach my $dataset (@datasets){
          if (exists($used{$dataset->id()})){
	      my $href= $used{$dataset->id()}->{project};
            my %fusion=();
	      %fusion=(%$href,%info);
	      $used{$dataset->id()}->{project}=\%fusion;
	    }else{
		$count++;
	      $used{$dataset->id()}->{project}=\%info;
	      $used{$dataset->id()}->{object}=$dataset ;
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

# Session macro

sub Session { OME::Session->instance() }


=head1 AUTHOR

JMarie Burel (jburel@dundee.ac.uk)

=head1 SEE ALSO

L<OME::DBObject|OME::DBObject>,
L<OME::Factory|OME::Factory>,
L<OME::SetDB|OME::SetDB>,

=cut

1;

