# OME/Tasks/ImageManager.pm

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


package OME::Tasks::ImageManager;

use OME;
use OME::Session;
use Log::Agent;
our $VERSION = $OME::VERSION;

=head 1 NAME

OME::Tasks::ImageManager - utility methods to manage images

=head 1 SYNOPSIS

	use OME::Tasks::ImageManager;
	my $imageManager = OME::Tasks::ImageManager->new();
	

=head 1 DESCRIPTION

OME::Tasks::ImageManager provides utility methods to manage images

=head1 METHODS (ALPHABETICAL ORDER)

=head2 delete ($id)

Delete Image from database

=head2 getAllImages ()

	my @images = $imageManager->getAllImages();

Get all the images in the database.

=head2 getUserImages ($experimenter)

	my @user_images = $imageManager->getUserImages();
	my @other_user_images = $imageManager->getUserImages(
		$other_experimenter
	);

Get all the images related to an experimenter.

Note: The method uses the Session's experimenter as a filter if none is specified.

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
use OME::DBObject;
OME::DBObject->Caching(0);


sub new{
	my $class=shift;
	my $self={};
	bless($self,$class);
   	return $self;


}

###############
# Parameters:
#	id =image_id to delete

sub delete{
	my $self=shift;
	my $session=$self->__Session();
	my ($id)=@_;
	my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());
	
	my $result=deleteInMap($session,$id,$db);
	#my $rep=deleteImage($id,$db) if defined $result;
	$db->Off();
	#return $rep;
	return $result;
	
}

#################
# Parameters: (void)
# 	
sub getAllImages {
	my $self = shift;
	my $factory = $self->__Session()->Factory();

	return $factory->findObjects("OME::Image");
};

#################
# Parameters: (experimenter object)
#
sub getUserImages {
	my ($self, $experimenter) = shift;
	my $factory = $self->__Session()->Factory();

	$experimenter = $self->__Session()->User() unless defined $experimenter;

	return $factory->findObjects("OME::Image", experimenter_id => $experimenter->id());
}


#########################
# Parameters:
#	ref=ref array  list group_id (optional)
#	used = if defined check images used and the ones in Research group
#	datasetID (optional)
# Return: ref array of image objects

sub listMatching{
	my $self=shift;
	my $session=$self->__Session();
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
	my $session=$self->__Session();
	my @listImages=();
	my @projects=();
	if (defined $userID){
		@projects=$session->Factory()->findObjects("OME::Project",'owner_id'=> $userID);
	}elsif (defined $projectID){
		#@projects=$session->Factory()->findObjects("OME::Project",'project_id'=> $projectID);
    @projects=$session->Factory()->findObjects("OME::Project",'id'=> $projectID);
	}
	foreach my $p (@projects){
		my @datasets=();#$p->datasets();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$p->id() );
     		foreach my $d (@dMaps){
      		 push(@datasets,$d->dataset());
    		}

		foreach my $d (@datasets){
			my @images=();
     			my @iMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$d->id() );
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
	my $session=$self->__Session();;
	my ($imageID)=@_;
	my $image=$session->Factory()->loadObject("OME::Image",$imageID);
	return $image;


}


=head2 getThumbURL

usage:
	# retrieve the URL for the thumbnail of the default pixels of a given image
	my $thumbnailURL = $imageManager->getThumbURL($image);
	
	# retrieve the URL for the thumbnail of the specified pixels attribute
	my $thumbnailURL = $imageManager->getThumbURL($pixels);
	
Will return undef if there is not a default pixels associated with
the image or the repository is not local.
	
=cut
sub getThumbURL{
	my $self=shift;
	my $session=$self->__Session();
	my $param = shift;
	my $pixels;
	if( $param->isa( "OME::Image" ) ) {
		$pixels = $param->default_pixels()
			or return undef;
	} else {
		$pixels = $param;
	}
	my $rep = $pixels->Repository();
	return undef if($rep->IsLocal());
	return $rep->ImageServerURL()."?Method=GetThumb&PixelsID=".$pixels->ImageServerID();
}


###############
# Parameters: 
#	ref=ref array  list group_id (optional)
# Return: ref hash (group images info,user images info)

sub manage{
	my $self=shift;
	my ($ref)=@_;
	my $session=$self->__Session();
	my ($result,$projects)=notMyProject($session,$ref);
	my ($gpImages,$userImages)=usedDatasetImage($session,$result,$projects);
   	return ($gpImages,$userImages);
	
}

################
# Parameters:
#	ref = ref hash key:imageid value:ref array with dataset_id 
sub remove{
	my $self=shift;
	my $session=$self->__Session();
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
#	image = image object

sub getImageDim{
	my ($self,$image,$pixels)=@_ ;
	$pixels = $image->DefaultPixels()
		unless $pixels;
	my $path=$image->getFullPath($pixels);

	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp);
	$sizeX = $pixels->SizeX;
	$sizeY = $pixels->SizeY;
	$sizeZ = $pixels->SizeZ;	
	$numW  = $pixels->SizeC;
	$numT  = $pixels->SizeT,
  	$bpp   = $pixels->BitsPerPixel;	
	$bpp /= 8;
	return ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$path);
}



############################
# Parameters:
#	image = image object

my @stackStatsModules = (
                         'Fast Stack statistics',
                         'Stack statistics (image server)',
                        );
sub __tryOneStatsModule ($$) {
    my ($module_name,$pixels) = @_;
	my $session = OME::Session->instance();
	my $factory=$session->Factory();

  	my $stackStats = $factory->findObject( "OME::Module", 
                                           name => $module_name )
      or return undef;

	my $pixelsFI = $factory->findObject( "OME::Module::FormalInput",
		module_id => $stackStats->id(),
		name       => 'Pixels' )
      or return undef;

	my $actualInput = $factory->findObject( "OME::ModuleExecution::ActualInput",
		formal_input_id   => $pixelsFI->id(),
		input_module_execution_id => $pixels->module_execution()->id() )
      or return undef;

	my $stackStatsAnalysisID = $actualInput->module_execution()->id();

    return $stackStatsAnalysisID;
}

sub getImageStats{
	my ($self,$image,$pixels)=@_ ;
	$pixels = $image->DefaultPixels()
		unless $pixels;
  	# new version
	my $session=$self->__Session();
	my $factory=$session->Factory();

    my $stackStatsAnalysisID;
  MODULE:
    foreach my $module_name (@stackStatsModules) {
        $stackStatsAnalysisID = __tryOneStatsModule($module_name,$pixels);
        last MODULE if defined $stackStatsAnalysisID;
    }

    die "Could not find stack statistics for these pixels!"
      unless defined $stackStatsAnalysisID;

	my @mins = $factory->findAttributes( "StackMinimum", {
		image            => $image, 
		module_execution => $stackStatsAnalysisID
	} );
	my @maxes = $factory->findAttributes( "StackMaximum", {
		image            => $image, 
		module_execution => $stackStatsAnalysisID
	} );
	my @means = $factory->findAttributes( "StackMean", {
		image            => $image, 
		module_execution => $stackStatsAnalysisID
	} );
	my @gmeans = $factory->findAttributes( "StackGeometricMean", {
		image            => $image, 
		module_execution => $stackStatsAnalysisID
	} );
	my @geosigmas = $factory->findAttributes( "StackGeometricSigma", {
		image            => $image, 
		module_execution => $stackStatsAnalysisID
	} );

	my $sh; # stats hash
	$sh->[ $_->TheC() ][ $_->TheT() ]->{min} = $_->Minimum()
		foreach( @mins );
	$sh->[ $_->TheC() ][ $_->TheT() ]->{max} = $_->Maximum()
		foreach( @maxes );
	$sh->[ $_->TheC() ][ $_->TheT() ]->{mean} = $_->Mean()
		foreach( @means );
	$sh->[ $_->TheC() ][ $_->TheT() ]->{geomean} = $_->GeometricMean()
		foreach( @gmeans );
	$sh->[ $_->TheC() ][ $_->TheT() ]->{geosigma} = $_->GeometricSigma()
		foreach( @geosigmas );
	return $sh;
}

####################

########################
# Parameters:
# 	image = image object


sub getImageWavelengths{
	my ($self,$image,$pixels)=@_ ;
	$pixels = $image->DefaultPixels()
		unless $pixels;
	my $session=$self->__Session();
	my $factory=$session->Factory();

	my @Wavelengths;
	my @channelComponents = $factory->findAttributes( "PixelChannelComponent", {
		image  => $image,
		Pixels => $pixels } )
		or die "Cannot find PixelChannelComponent's for image (id=".$image->id()."), pixels (id=".$pixels->id().")\n";
	foreach my $cc (@channelComponents) {
		my $ChannelNum = $cc->Index();
		my $Label;
    		my @overlap=();
		$Label = $cc->LogicalChannel()->Name()  || 
		         $cc->LogicalChannel()->Fluor() || 
		         $cc->LogicalChannel()->EmissionWavelength();

		#@overlap = grep( $cc->LogicalChannel()->id() eq $_->LogicalChannel()->id(), @channelComponents );
		$Label .= $cc->Index() if( scalar( @overlap ) > 1 || $Label eq "" );
    		my %h=();
		$h{WaveNum}=$ChannelNum;
		$h{Label}=$Label;
		push (@Wavelengths,\%h);
	}
	return \@Wavelengths;
}





####################

sub getDisplayOptions{
	my ($self,$image,$pixels)=@_ ;
	$pixels = $image->DefaultPixels()
		unless $pixels;
	my $session=$self->__Session();
	my $factory=$session->Factory();
	my ($theZ,$theT,$isRGB,@cbw,@rgbOn);
	my $displayOptions    = OME::Tasks::PixelsManager->getDisplayOptions( $pixels );
	my %h =();
	$theZ=($displayOptions->ZStart() + $displayOptions->ZStop() ) / 2;
	$theT=($displayOptions->TStart() + $displayOptions->TStop() ) / 2;
	$isRGB= $displayOptions->DisplayRGB();
	@cbw=(
		$displayOptions->RedChannel()->ChannelNumber(),
		$displayOptions->RedChannel()->BlackLevel(),
		$displayOptions->RedChannel()->WhiteLevel(),
		$displayOptions->GreenChannel()->ChannelNumber(),
		$displayOptions->GreenChannel()->BlackLevel(),
		$displayOptions->GreenChannel()->WhiteLevel(),
		$displayOptions->BlueChannel()->ChannelNumber(),
		$displayOptions->BlueChannel()->BlackLevel(),
		$displayOptions->BlueChannel()->WhiteLevel(),
		$displayOptions->GreyChannel()->ChannelNumber(),
		$displayOptions->GreyChannel()->BlackLevel(),
		$displayOptions->GreyChannel()->WhiteLevel(),
		);
	push (@rgbOn,$displayOptions->RedChannelOn(),$displayOptions->GreenChannelOn(),$displayOptions->BlueChannelOn());	
	%h=(
		'theZ' => $theZ,
		'theT' => $theT,
		'isRGB' => $isRGB,
		'CBW' => \@cbw,
		'RGBon' =>\@rgbOn
		);
	return \%h;


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
	  my $id=$object->id();
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
	    my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->id() );
     	    foreach my $d (@dMaps){
      	push(@datasets,$d->dataset());
    	    }
	    foreach my $obj (@datasets){
		$gpDatasets{$obj->id()}=$obj unless (exists $gpDatasets{$obj->id()});
		my @images=();
		my @dMaps=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$obj->id() );
     	    	foreach my $d (@dMaps){
      	   push(@images,$d->image());
    	      }

		#my @images=$obj->images();
		foreach my $i (@images){
		  $gpImages{$i->id()}=$i->name() unless (exists $gpImages{$i->id()});
		}
	    }
	  } 
	}
	
	foreach (@$projects){
     		my @datasets=();
     		my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$_->id() );
     		foreach my $d (@dMaps){
      		 push(@datasets,$d->dataset());
    		}
 
	 	# my @datasets=$_->datasets();
	 	  foreach my $dataset (@datasets){
		    my %datasetInfo=();
       	    my %remove=();
		    $datasetInfo{$dataset->id()}=$dataset;
	 	    if (exists $gpDatasets{$dataset->id()} || $dataset->locked()){
         		$remove{$dataset->id()}=undef ;
	 	   }else{
	   		$remove{$dataset->id()}=1 ;
       	   }

               my @list=$session->Factory()->findObjects("OME::Image::DatasetMap",'dataset_id'=>$dataset->id() );
               my @images=();
   		   foreach my $l (@list){
		     push(@images,$l->image());
    		   }
		   foreach my $i (@images){
			if (exists($userImages{$i->id()})){
	  		  my $list=$userImages{$i->id()}->{list};
            	  my %fusion=();
			  %fusion=(%$list,%datasetInfo);
			  $userImages{$i->id()}->{list}=\%fusion;
			  my $rem=$userImages{$i->id()}->{remove};
            	  my %mix=();
			  %mix=(%$rem,%remove);
			  $userImages{$i->id()}->{remove}=\%mix;
			}else{
			  $userImages{$i->id()}->{list}=\%datasetInfo;
			  $userImages{$i->id()}->{remove}=\%remove;
			  $userImages{$i->id()}->{image}=$i;
			}

		 }
	    }
	}
	return (\%gpImages,\%userImages);
}

sub __Session { return OME::Session->instance() }

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

