# OME/Tasks/ImageManager.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Tasks::ImageManager;

use OME;
our $VERSION = $OME::VERSION;

=head 1 NAME

OME::Tasks::ImageManager - manage images used by a user

=head 1 SYNOPSIS

	use OME::Tasks::ImageManager;
	my $imageManager=new OME::Tasks::ImageManager($session);
	

=head 1 DESCRIPTION

The OME::Tasks::ImageManager provides a list of methods to manage images used by a user


=head 1 OBTAINING AN IMAGEMANAGER

To retrieve an OME::Tasks::ImageManager to use for managing images, the
user must log in to OME.  This is done via the
L<OME::SessionManager|OME::SessionManager> class.  Logging in via
OME::SessionManager yields an L<OME::Session|OME::Session> object.

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $imageManager = new OME::Tasks::ImageManager($session);


=head1 METHODS (ALPHABETICAL ORDER)

=head2 delete ($id)

Delete Image from database


=head2 listMatching ($ref,$used,$datasetID)
datasetID (optional) if not defined dataset=current dataset
ref=ref array  list group_id (optional)

Images in Research group
if used defined, images in Research group not already used by project


=head2 load ($imageID)

Load image object
Return: image object

=head2 manage
ref =ref array list of group_id

Informations to manage images
Return: ref hash (GroupImagesInfo,UserImagesInfo)

GroupImagesInfo:
Check images used in others projects i.e. not user's project
key:image_id => value: image_name 

UserImagesInfo:
hash of hashes:
key: image_id
->{list}=>  ref hash datasetInfo (i.e. key:dataset_id value: dataset object
->{remove}=> ref hash dataset_id value booleen 
->{image} => image object;


=head2 remove ($ref)
Remove image from datasets

=cut



use strict;
use OME::SetDB;
use OME::Tasks::Thumbnails;
use OME::DBObject;
OME::DBObject->Caching(0);


sub new{
	my $class=shift;
	my $self={};
	$self->{session}=shift;	
	bless($self,$class);
   	return $self;


}

###############
# Parameters:
#	id =image_id to delete

sub delete{
	my $self=shift;
	my $session=$self->{session};
	my ($id)=@_;
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());
	
	my $result=deleteInMap($session,$id,$db);
	#my $rep=deleteImage($id,$db) if defined $result;
	$db->Off();
	#return $rep;
	return $result;
	
}


#########################
# Parameters:
#	ref=ref array  list group_id (optional)
#	used = if defined check images used and the ones in Research group
#	datasetID (optional)
# Return: ref array of image objects

sub listMatching{
	my $self=shift;
	my $session=$self->{session};
	my ($ref,$used,$datasetID)=@_;
	my $result;
	my @gpImages=();
	if (defined $ref){
		foreach (@$ref){
		  push(@gpImages,$session->Factory()->findObjects("OME::Image", 'group_id' =>$_));
		}
	}else{
  	  @gpImages = $session->Factory()->findObjects("OME::Image");
	}
	
	if (defined $used){
		my $dataset;
		if (defined $datasetID){
			$dataset=$session->Factory()->loadObject("OME::Dataset",$datasetID);
		}else{
			$dataset=$session->dataset();
		}
	   my @usedImages=$dataset->images();
	   $result=notUsedImages(\@gpImages,\@usedImages);
	}else{
	   $result=\@gpImages;
	}
	return $result;
}



#################
# Parameters
#	userID
#	projectID 
# Return list of image object
sub listImages{
	my $self=shift;
	my ($userID,$projectID)=@_;
	my $session=$self->{session};
	my @listImages=();
	my @projects=();
	if (defined $userID){
		@projects=$session->Factory()->findObjects("OME::Project",'owner_id'=> $userID);
	}elsif (defined $projectID){
		@projects=$session->Factory()->findObjects("OME::Project",'project_id'=> $projectID);
	}
	foreach my $p (@projects){
		my @datasets=();#$p->datasets();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$p->project_id() );
     		foreach my $d (@dMaps){
      		 push(@datasets,$d->dataset());
    		}

		foreach my $d (@datasets){
			my @images=();
     			my @iMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$d->dataset_id() );
     			foreach my $i (@iMaps){
      		 push(@images,$i->image());
    			}

			push(@listImages,@images); 
	   	}
	}
	
	my $out=checkDuplicate(\@listImages);
	return $out;

}

#############
# Parameters: 
#	imageid = image_id 
# Return:  image object

sub load{
	my $self=shift;
	my $session=$self->{session};
	my ($imageID)=@_;
	my $image=$session->Factory()->loadObject("OME::Image",$imageID);
	return $image;


}


###############
# Parameters: 
#	ref=ref array  list group_id (optional)
# Return: ref hash (group images info,user images info)

sub manage{
	my $self=shift;
	my ($ref)=@_;
	my $session=$self->{session};
	my ($result,$projects)=notMyProject($session,$ref);
	my ($gpImages,$userImages)=usedDatasetImage($session,$result,$projects);
   	return ($gpImages,$userImages);
	
}

################
# Parameters:
#	ref = ref hash key:imageid value:ref array with dataset_id 
sub remove{
	my $self=shift;
	my $session=$self->{session};
	my ($ref)=@_;
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());
	my $result;
	foreach my $id (keys %$ref){
	  my $list=${$ref}{$id};
	  foreach my $datasetID (@$list){
	     $result=removeImage($id,$datasetID,$db);
	     return undef unless (defined $result);
        }
	}
	$db->Off();
	return 1;
}




####################
# Parameters: 
#	ref = ref list of image_id
sub createThumbnail{
	my $self=shift;
	my ($ref)=@_;
	my $session=$self->{session};
	my $factory=$session->Factory();
	my $generator= new OME::Tasks::Thumbnails($session);
	my %listThumbnails=();
	foreach my $id (@$ref){
	   my $image=$factory->loadObject("OME::Image",$id);
	   my $out=$generator->generateOMEimage($image);
	   my $thumbnail=$generator->generateOMEthumbnail($out);
	   $listThumbnails{$id}={'name'=>$image->name(), 'thumbnail'=>$thumbnail};
	}
	return \%listThumbnails;

}

####################
# PRIVATE METHODS  #
####################

sub checkDuplicate{
	my ($ref)=@_;
	  my %seen=();
  	my $object;
  	my @a=();
  	foreach $object (@$ref){
	  my $id=$object->image_id();
    	 push(@a,$object) unless $seen{$id}++;
   	}
  	return \@a;
}




sub deleteImage{
	my ($id,$db)=@_;
	my $table="images";
 	my ($condition,$result);
 	$condition="image_id=".$id;
 	$result=do_delete($table,$condition,$db);
 	return (defined $result)?1:undef;

}

sub deleteInMap{
	my ($session,$id,$db)=@_;
	my @tables=();
	#existing
	@tables=qw(image_dataset_map image_files_xyzwt ome_sessions_images);	#last one just in case!
	# dynamic
      my @tablesDynamic=$session->Factory()->findObjects("OME::DataTable",'granularity'=>'I');
  	my @dynamic=();
  	foreach (@tablesDynamic){
		my $tablename=lc($_->table_name());
  	 push(@dynamic,$tablename) unless $tablename eq "image_pixels";
  	}
  	push(@tables,@dynamic);
 	foreach (@tables){
		my ($condition,$result);
     		$condition="image_id=".$id;
     		$result=do_delete($_,$condition,$db);
     		return undef unless (defined $result);
	}
	# must add a delete cascade 
	# table images + image_pixels.
	return 1;
}

sub notMyProject{
	my ($session,$ref)=@_;
	my @groupProjects=();
	if (defined $ref){
		foreach (@$ref){
		   push(@groupProjects,$session->Factory()->findObjects("OME::Project",'group_id'=> $_));
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

sub removeImage{
	my ($id,$datasetID,$db)=@_;
	my ($condition,$result);
	my $table="image_dataset_map";
  	$condition="image_id=".$id." AND dataset_id=".$datasetID;
      $result=do_delete($table,$condition,$db); 
	return (defined $result)?1:undef;

}
sub usedDatasetImage{
	my ($session,$result,$projects)=@_;
	my %gpDatasets=();
	my %gpImages=();
	my %userImages=();
	if (defined $result){
	  foreach (@$result){
	    my @datasets=();#$_->datasets();
	    my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->project_id() );
     	    foreach my $d (@dMaps){
      	push(@datasets,$d->dataset());
    	    }
	    foreach my $obj (@datasets){
		$gpDatasets{$obj->dataset_id()}=$obj unless (exists $gpDatasets{$obj->dataset_id()});
		my @images=();
		my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$obj->dataset_id() );
     	    	foreach my $d (@dMaps){
      	   push(@images,$d->image());
    	      }

		#my @images=$obj->images();
		foreach my $i (@images){
		  $gpImages{$i->image_id()}=$i->name() unless (exists $gpImages{$i->image_id()});
		}
	    }
	  } 
	}
	
	foreach (@$projects){
     		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->project_id() );
     		foreach my $d (@dMaps){
      		 push(@datasets,$d->dataset());
    		}
 
	 	# my @datasets=$_->datasets();
	 	  foreach my $dataset (@datasets){
		    my %datasetInfo=();
       	    my %remove=();
		    $datasetInfo{$dataset->dataset_id()}=$dataset;
	 	    if (exists $gpDatasets{$dataset->dataset_id()} || $dataset->locked()){
         		$remove{$dataset->dataset_id()}=undef ;
	 	   }else{
	   		$remove{$dataset->dataset_id()}=1 ;
       	   }

               my @list=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$dataset->dataset_id() );
               my @images=();
   		   foreach my $l (@list){
		     push(@images,$l->image());
    		   }
		   foreach my $i (@images){
			if (exists($userImages{$i->image_id()})){
	  		  my $list=$userImages{$i->image_id()}->{list};
            	  my %fusion=();
			  %fusion=(%$list,%datasetInfo);
			  $userImages{$i->image_id()}->{list}=\%fusion; 
			  my $rem=$userImages{$i->image_id()}->{remove};
            	  my %mix=();
			  %mix=(%$rem,%remove);
			  $userImages{$i->image_id()}->{remove}=\%mix; 
			}else{
			  $userImages{$i->image_id()}->{list}=\%datasetInfo;
			  $userImages{$i->image_id()}->{remove}=\%remove;
			  $userImages{$i->image_id()}->{image}=$i;
			}

		 }
	    }
	}
	return (\%gpImages,\%userImages);
}


sub do_delete{
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

