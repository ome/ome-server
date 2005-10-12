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

=head1 NAME

OME::Tasks::ImageManager - utility methods to manage images

=head1 SYNOPSIS

	use OME::Tasks::ImageManager;
	my $imageManager = OME::Tasks::ImageManager->new();

=head1 DESCRIPTION

OME::Tasks::ImageManager provides utility methods to manage images

=head1 METHODS (ALPHABETICAL ORDER)

=head2 delete ($id)

Delete Image from database

=head2 getAllImages ()

	my @images = $imageManager->getAllImages();

Get all the images in the database.

=head2 getAllImageCount ()

	my $i_count = $imageManager->getAllImageCount();

Gets a count of all the images in the database.

=head2 getUserImages ($experimenter)

	my @user_images = $imageManager->getUserImages();
	my @other_user_images = $imageManager->getUserImages(
		$other_experimenter
	);

Get all the images related to an experimenter.

Note: The method uses the Session's experimenter as a filter if none is specified.

=head2 getUserImageCount ()

	my $i_count = $imageManager->getUserImageCount();
	my $other_i_count = $imageManager->getUserImageCount(
		$other_experimenter
	);

Gets a count of all the images owner by a user.

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

use OME::Tasks::PixelsManager;


sub new{
	my $class=shift;
	my $self={};
	bless($self,$class);
   	return $self;


}

=head2 deleteCurrentAnnotation

	OME::Tasks::ImageManager->deleteCurrentAnnotation( $image );

This tries to get an annotation from getCurrentAnnotationgetCurrentAnnotation()
If it gets one that belongs to the current user, it will mark it invalid.

=cut

sub deleteCurrentAnnotation {
	my ($class, $image) = @_;
	my $session = OME::Session->instance();
	my $annotation = $class->getCurrentAnnotation( $image );
	if( ( defined $annotation ) &&
	    ( defined $annotation->module_execution() ) && 
	    ( $annotation->module_execution()->experimenter->id eq
	      $session->User->id ) ) {
		$annotation->Valid( 0 );
		$annotation->storeObject();
	}
}

=head2 getCurrentAnnotation

	my $imageAnnotation = OME::Tasks::ImageManager->
	    getCurrentAnnotation( $image );

This will look for the most recent ImageAnnotation created by 
the current user that is marked Valid.
Failing to that, it will look for the most recent ImageAnnotation
created by anyone that is marked Valid.

If no Valid ImageAnnotations are found, an undef will be returned.

=cut

sub getCurrentAnnotation {
	my ($class, $image) = @_;
	my $session = OME::Session->instance();
    my $factory = $session->Factory();

	# Load the image if they passed in an id
	$image = $factory->
		loadObject( 'OME::Image', $image )
		or die "Could Not load image with id '$image'"
		unless( ref( $image ) );
	# param type check
	die "image parameter is not an image object"
		unless ref( $image ) eq 'OME::Image';
	
	# First look foe this User's annotations
	my $imageAnnotation = $factory->
		findObject( '@ImageAnnotation',
			image                           => $image,
			Valid                           => 1,
			'module_execution.experimenter' => $session->User(),
			__order                         => '!module_execution.timestamp'
		);
	# Then look for other people's
	$imageAnnotation = $factory->
		findObject( '@ImageAnnotation',
			image                           => $image,
			Valid                           => 1,
			__order                         => '!module_execution.timestamp'
		)
		unless $imageAnnotation;


	return $imageAnnotation;
}

=head2 writeAnnotation

	my $imageAnnotation = OME::Tasks::ImageManager->
	    writeAnnotation( $image, $data_hash );

This will write a new ImageAnnotation attribute. The data_hash should
follow the format for factory NewObject calls. e.g.
	{ Content => $content, ... }
If the Content is identical to the current annotation, a new ImageAnnoation
attribute will not be created, and the current annotation will be returned.

If this user has a current annotation on this image, the other
annotation will be marked invalid. If another user has a current annotation
on this image, the other user's annotation will be left alone.

Note, this method does NOT commit the db transaction.

=cut

sub writeAnnotation {
	my ($class, $image, $data_hash) = @_;
	my $session = OME::Session->instance();
    my $factory = $session->Factory();

	# Load the image if they passed in an id
	$image = $factory->
		loadObject( 'OME::Image', $image )
		or die "Could Not load image with id '$image'"
		unless( ref( $image ) );
	# param type check
	die "image parameter is not an image object"
		unless ref( $image ) eq 'OME::Image';
	
	my $lastImageAnnotation = $class->
		getCurrentAnnotation( $image );
	
	# Don't allow a write unless the contents have changed.
	if( ( defined $lastImageAnnotation ) &&
		( $lastImageAnnotation->Content() eq $data_hash->{ Content } ) ) {
		return $lastImageAnnotation;
	}
	
	# Make a new one
	$data_hash->{ Valid } = 1;
	my ($mex, $newImageAnnotation) = OME::Tasks::AnnotationManager->
	    annotateImage( 
	    	$image, 'ImageAnnotation', $data_hash
	    );

	# Mark the last one as invalid if this user is overwriting their own annotation.
	if( ( defined $lastImageAnnotation ) &&
	    ( $lastImageAnnotation->module_execution->experimenter->id eq
		  $session->User->id ) ) {
		$lastImageAnnotation->Valid( 0 );
		$lastImageAnnotation->storeObject();
	}
	
	return $newImageAnnotation;
}

###############
# Parameters:
#	id =image_id to delete

sub delete{
	my $self=shift;
	my $session=$self->__Session();
	my ($id)=@_;
	my $db=new OME::SetDB();
	
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
# Parameters: (void)
# 	
sub getAllImageCount {
	my $self = shift;
	my $factory = $self->__Session()->Factory();

	return $factory->countObjects("OME::Image");
};

#################
# Parameters: (experimenter object)
#
sub getUserImages {
	my ($self, $experimenter) = @_;
	my $factory = $self->__Session()->Factory();

	$experimenter = $self->__Session()->User() unless defined $experimenter;

	return $factory->findObjects("OME::Image", experimenter_id => $experimenter->id());
}

#################
# Parameters: (experimenter object)
#
sub getUserImageCount {
	my ($self, $experimenter) = @_;
	my $factory = $self->__Session()->Factory();

	$experimenter = $self->__Session()->User() unless defined $experimenter;

	return $factory->countObjects("OME::Image", experimenter_id => $experimenter->id());
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

	# retrieve the URL for the thumbnail of the default pixels of a given image
	my $thumbnailURL = $imageManager->getThumbURL($image);

	# retrieve the URL for the thumbnail of the default pixels of a given image_id
	my $thumbnailURL = $imageManager->getThumbURL($imageID);

Will return undef if there is not a default pixels associated with the
image.

=cut

sub getThumbURL{
	my $self=shift;
	my $session=$self->__Session();
	my $param = shift;
	my $pixels;
	# image id
	if( not ref( $param ) ) {
		my $img = $session->Factory()->loadObject('OME::Image', $param )
			or die "Could not load OME::Image, id=$param";
		$pixels = $img->default_pixels()
			or return undef;
	# image
	} elsif( $param->isa( "OME::Image" ) ) {
		$pixels = $param->default_pixels()
			or return undef;
	# pixels (depricated)
	} else {
		$pixels = $param;
	}
	return OME::Tasks::PixelsManager->getThumbURL($pixels);
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
	my $db=new OME::SetDB();
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




sub getImageStatsMEX {
    my ($self,$pixels) = @_;
	my $session = OME::Session->instance();
	my $factory=$session->Factory();

	foreach my $module_name( 'Fast Stack statistics', 'Stack statistics (image server)' ) {
		my $stackStats = $factory->findObject( "OME::Module", 
											   name => $module_name )
		  or next;
	
		my $pixelsFI = $factory->findObject( "OME::Module::FormalInput",
			module_id => $stackStats->id(),
			name       => 'Pixels' )
		  or next;
	
		my $actualInput = $factory->findObject( "OME::ModuleExecution::ActualInput",
			formal_input_id   => $pixelsFI->id(),
			input_module_execution_id => $pixels->module_execution()->id() )
		  or next;
	
		return $actualInput->module_execution();
	}
    return undef;
}


sub getImageStats{
	my ($self,$image,$pixels)=@_ ;
	$pixels = $image->DefaultPixels()
		unless $pixels;
  	# new version
	my $session=$self->__Session();
	my $factory=$session->Factory();

    my $stackStatsAnalysis = $self->getImageStatsMEX( $pixels )
		or die "Could not find stack statistics for these pixels!";

	my @mins = $factory->findAttributes( "StackMinimum", {
		image            => $image, 
		module_execution => $stackStatsAnalysis
	} );
	my @maxes = $factory->findAttributes( "StackMaximum", {
		image            => $image, 
		module_execution => $stackStatsAnalysis
	} );
	my @means = $factory->findAttributes( "StackMean", {
		image            => $image, 
		module_execution => $stackStatsAnalysis
	} );
	my @gmeans = $factory->findAttributes( "StackGeometricMean", {
		image            => $image, 
		module_execution => $stackStatsAnalysis
	} );
	my @geosigmas = $factory->findAttributes( "StackGeometricSigma", {
		image            => $image, 
		module_execution => $stackStatsAnalysis
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
		Pixels => $pixels } );
	if( @channelComponents ) {
		@channelComponents = sort 
			{ $b->LogicalChannel()->EmissionWavelength() <=> $a->LogicalChannel()->EmissionWavelength() } 
			@channelComponents;
		foreach my $cc (@channelComponents) {
			my $ChannelNum = $cc->Index();
			my $Label;
			$Label = $cc->LogicalChannel()->Name()  || 
					 $cc->LogicalChannel()->Fluor() || 
					 $cc->LogicalChannel()->EmissionWavelength();
	
			$Label .= $cc->Index() if( $Label eq "" );
			my %h=();
			$h{WaveNum}=$ChannelNum;
			$h{Label}=$Label;
			push (@Wavelengths,\%h);
		}
	
	# If there's no PixelChannelComponents found, throw something else together.
	} else {
		# Wavenumbers 0 to (SizeC - 1); Labels 1 to SizeC
		( push( @Wavelengths, { WaveNum => $_, Label => $_ } ) and print STDERR "it is $_\n" )
			foreach( 0..($pixels->SizeC() - 1) );
	}

	return \@Wavelengths;
}

########################
# Parameters:
# 	image = image object
# this was written by Josiah Johnston and used to be in __OME_Image.pm
sub getImageOriginalFiles{
	my ($self,$image)=@_ ;
	my $session=$self->__Session();
	my $factory=$session->Factory();
	
	# Maybe dying here is to harsh for OME::ModuleExecution and ActualInput.
	# Let's start dieing and if this is the wrong behaviour, we can change it later
	my $import_mex = $factory->findObject( "OME::ModuleExecution", 
		'module.name' => 'Image import', 
		image => $image, 
		__order => 'timestamp' ) or die "No Image import MEX found for this image.";

	my $ai = $factory->findObject( 
		"OME::ModuleExecution::ActualInput", 
		module_execution => $import_mex,
		'formal_input.semantic_type.name' => 'OriginalFile'
	) or die "No OriginalFile inputs were found for Image import MEX id=".$import_mex->id;

	my $original_files = OME::Tasks::ModuleExecutionManager->getAttributesForMEX(
		$ai->input_module_execution,
		'OriginalFile'
	);
	
	return $original_files;
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
	@tables=qw(image_dataset_map ome_sessions_images);	#last one just in case!
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

