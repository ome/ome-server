# OME/Tasks/ImageManager.pm

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


package OME::Tasks::ImageManager;

our $VERSION = '1.0';

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


=head2 listMatching ($usergpID,$used)
Images in Research group
if bool defined, images in Research group not already used by project


=head2 listGroup

Check images associated to a given Research group
Return: ref array with image objects

=head2 listNotUsed

Compare images in the current dataset and ones available in the Research group
return list of images not used.
Return: ref array with image object

=head2 load ($imageID)

Load image object
Return: image object

=head2 manage
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
	my $result=deleteInMap($id,$db);
	my $rep=deleteImage($id,$db) if defined $result;
	$db->Off();
	return $rep;
	
}


#########################
# Parameters:
#	used if defined check images used and the ones in Research group
# Return: ref array of image objects

sub listMatching{
	my $self=shift;
	my $session=$self->{session};
	my ($usergpID,$used)=@_;
	my $result;
	if (defined $used){
		
	   my @gpImages = $session->Factory()->findObjects("OME::Image", 'group_id' =>$usergpID);
	   my @usedImages=$session->dataset()->images();
	   $result=notUsedImages(\@gpImages,\@usedImages);
	}else{
	   my @images = $session->Factory()->findObjects("OME::Image", 'group_id' =>$usergpID);
	   $result=\@images;
	}
	return $result;
}
###############
# Parameters: 
#	usergp = group_id (future) ?
# Return: ref array with image objects

#sub listGroup{
#	my $self=shift;
#	my $session=$self->{session};
#	#my ($usergpID)=@_;
#	my @images = $session->Factory()->findObjects("OME::Image", 'group_id' => $session->User()->Group()->id());
#	
#	return \@images;
#
#}


###############
# Parameters: no
# Return: ref array with image object

#sub listNotUsed{
#	my $self=shift;
#	my $session=$self->{session};
#	my @gpImages = $session->Factory()->findObjects("OME::Image", 'group_id' => $session->User()->Group()->id() );
#	my @usedImages=$session->dataset()->images();
#	my $result=notUsedImages(\@gpImages,\@usedImages);
# 	return $result;

#}


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
# Parameters: no
# Return: ref hash (group images info,user images info)

sub manage{
	my $self=shift;
	my $session=$self->{session};
	my ($result,$projects)=notMyProject($session);
	#return undef unless (defined $result);
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
# PRIVATE METHODS  #
####################

sub deleteImage{
	my ($id,$db)=@_;
	my $table="images";
 	my ($condition,$result);
 	$condition="image_id=".$id;
 	$result=do_delete($table,$condition,$db);
 	return (defined $result)?1:undef;

}

sub deleteInMap{
	my ($id,$db)=@_;
	# MUST FIND OTHER SOLUTION
	my @tables=qw(image_dataset_map image_dimensions image_files_xyzwt image_screen_info image_stage_info image_wavelengths xy_image_info xy_softworx_info xyz_image_info features ome_sessions_images);
 	foreach (@tables){
		my ($condition,$result);
     		$condition="image_id=".$id;
     		$result=do_delete($_,$condition,$db); 
     		return undef unless (defined $result);
	}
	return 1;
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
	    foreach my $obj ($_->datasets()){
		$gpDatasets{$obj->dataset_id()}=$obj unless (exists $gpDatasets{$obj->dataset_id()});
		foreach my $i ($obj->images()){
		  $gpImages{$i->image_id()}=$i->name() unless (exists $gpImages{$i->image_id()});
		}
	    }
	  } 
	}
	
	foreach (@$projects){
	  foreach my $dataset ($_->datasets()){
		my %datasetInfo=();
       	my %remove=();
		$datasetInfo{$dataset->dataset_id()}=$dataset;
	 	if (exists $gpDatasets{$dataset->dataset_id()} || $dataset->locked()){
         		$remove{$dataset->dataset_id()}=undef ;
	 	}else{
	   		$remove{$dataset->dataset_id()}=1 ;
       	}
		foreach my $i ($dataset->images()){
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

