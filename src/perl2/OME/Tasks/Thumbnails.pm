# OME/Tasks/Thumbnails.pm

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
# Written by:    JM Burel <jburel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Tasks::Thumbnails;

use POSIX;
use GD;
use strict;
our $VERSION = '1.0';

=head1 NAME

OME::Tasks::Thumbnails - produces thumbnails using GD

=head1 SYNOPSIS

	use OME::Tasks::Thumbnails;
	my $generator=new OME::Tasks::Thumbnails($session);
	my $out=$generator->generateOMEimage($image);
	# print output
	binmode STDOUT;
	print $out;

=head1 DESCRIPTION

Uses GD lib to create thumbnail image

=head1 METHODS 

=head2 generateOMEimage($image)

image= image object

=head2 generateOMEthumbnail($data,$n);

data= scalar (output of OME_JPEG via generateOMEimage) 
n (optional) size thumbnail




=head2 generateOMEmovie($image)

image= image object

=cut


sub new{

	my $class=shift;
	my $self={};
	$self->{size}=50;
	$self->{OME_JPEG}="OME_JPEG";
	$self->{session}=shift;
	bless($self,$class);
   	return $self;

}

#################
# Parameters:
#	image= image object

sub generateOMEimage{
	my $self=shift;
	my ($image,$Z_param,$T_param)=@_;
	my $session=$self->{session};
	my $factory=$session->Factory();
	my ($theZ,$theT);
	my $CBW=undef;
  	my $RGBon=undef;
  	my $isRGB=undef;
	# retrieve image data
	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$path)=getImageDim($image);
	my $stats=getImageStats($factory,$image);				# ref array
	my $wavelengths=getImageWavelengths($factory,$image);		# ref array
  	if (not defined $sizeX || not defined $sizeY || not defined $sizeZ
 	   ||not defined $numW || not defined $numT || not defined $bpp || not defined $path){
   		return undef;

  	}
   	if (scalar(@$wavelengths) != $numW ||  scalar(@$stats) != $numW){
    		return undef;
   	}
	$theZ = $Z_param || (defined $sizeZ ? $sizeZ / 2 : 0 );
	$theT = $T_param || 0;
	my $displayOptions    = [$factory->findAttributes( 'DisplayOptions', $image )]->[0];
	
	$isRGB=1;

	if (defined $displayOptions){
		$theZ=($displayOptions->ZStart() + $displayOptions->ZStop() ) / 2 unless defined $Z_param;
		$theT=($displayOptions->TStart() + $displayOptions->TStop() ) / 2 unless defined $T_param;
		$isRGB= $displayOptions->DisplayRGB();
		my @cbw=();
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
		$CBW=\@cbw;
		my @rgbon=();
		push (@rgbon,$displayOptions->RedChannelOn(),$displayOptions->GreenChannelOn(),$displayOptions->BlueChannelOn());	
		$RGBon=\@rgbon;
	}
   	$self->initialize($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$isRGB,$CBW,$RGBon);

    	my $jpg_image=$self->writeOMEimage($theZ,$theT);
	return $jpg_image;
}





##########################
#

sub generateOMEmovie{

	my $self=shift;
	my ($image,$Z_param)=@_;
	my $out;
	my $session=$self->{session};
	my $factory=$session->Factory();
	my $CBW=undef;
	my $RGBon=undef;
  	my $isRGB=undef;

	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$path)=getImageDim($image);	
	my $stats=getImageStats($factory,$image);				# ref array
	my $wavelengths=getImageWavelengths($factory,$image);	# ref array
	my $Z;
   my $error;
  if (not defined $sizeX || not defined $sizeY || not defined $sizeZ
  ||not defined $numW || not defined $numT || not defined $bpp || not defined $path){
   return undef;
  
  }
   if (scalar(@$wavelengths) != $numW ||  scalar(@$stats) != $numW){
    return undef;
   }




        
	$Z= $Z_param || (defined $sizeZ ? $sizeZ / 2 : 0) ;
	$isRGB=1;
   	$self->initialize($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$isRGB,$CBW,$RGBon);

	for (my $theZ=0;$theZ<$Z;$theZ++){
		for(my $theT=0;$theT<$self->{T};$theT++){
			#generate image
			my $jpg=$self->writeOMEimage($theZ,$theT);
			$out->[$theZ][$theT]=$jpg;
		}
	}
	return $out;
}

#######################
# Parameters
#	data= jpeg
#	n (optional) = size thumbnail

sub generateOMEthumbnail{
	my $self=shift;
	my ($data,$n)=@_;
	my $image=GD::Image->newFromJpegData($data);
	my ($x,$y) = $image->getBounds();
	$n=$self->{size} unless defined $n;
	my $r = $x>$y ? $x / $n : $y / $n;

	my $thumb = GD::Image->new($x/$r,$y/$r);
	$thumb->copyResized($image,0,0,0,0,$x/$r,$y/$r,$x,$y);
	return $thumb->jpeg;

}


######################################
sub writeOMEimage{
	my $self=shift;
	my ($theZ,$theT)=@_;
	my $dim=$self->{dim};
	my $d="Dims=".join(",",@$dim);
	my $z="theZ=".$theZ;
	my $t="theT=".$theT;
	my $path="Path=".$self->{path};
  	my $color=$self->getConvertedCBW($theT);
	if (not defined $color){
		return undef;
	}
	my $rgb="RGB=".join(",",@$color);
	my $rgbon="RGBon=".join(",",@{$self->{RGBon}});

	my $factory=$self->{session}->Factory();
	my $configuration = $factory->loadObject("OME::Configuration", 1);
	my $bin_dir=$configuration->bin_dir;
  	my $script=$bin_dir."/".$self->{OME_JPEG};
	my $out="";
	open (JPG, "$script $path $z $t $d $rgb $rgbon|") || die ("Error reading file, ",$script," ",$!);
  	while (<JPG>) {
		$out.=$_;
	 };
	close(JPG);
	return $out;
}




###########
# Initiliase the data

sub initialize{
	my $self=shift;
	my ($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$isRGB,$RGBon,$CBW)=@_;
	$self->{path}=$path;
	$self->{wavelengths}=$wavelengths;
	$self->{stats}=$stats;
	$self->{X}=$sizeX;
	$self->{Y}=$sizeY;
	$self->{Z}=$sizeZ;
	$self->{W}=$numW;
	$self->{T}=$numT;
	$self->{bpp}=$bpp;
	my @dim=();
	push(@dim,$self->{X},$self->{Y},$self->{Z},$self->{W},$self->{T},$self->{bpp});
	$self->{dim}=\@dim;
	if (defined $CBW){
  		$self->{CBW}=$CBW;		#ref array	in DB check if the case
	}else{
		my $ref=$self->makeCBW();	#default
		$self->{CBW}=$ref;
     	}

	if (defined $isRGB){
		$self->{inColor}=$isRGB;
	}else{
		$self->{inColor}=1;
	}

	if (defined $RGBon){
		$self->{RGBon}=$RGBon;
	}else{
		my @rgbon=();
		for( my $i=0;$i<3;$i++){
			if ($i<$numW){
				push(@rgbon,1);
			}else{
				push(@rgbon,0);
			}
		}
		$self->{RGBon}=\@rgbon;
	}

}



################################






####
# CBW
# Make CBW default parameters
sub makeCBW{
	my $self=shift;
	my @waves=();
	my @CBW=();
	my @wavelengths=@{$self->{wavelengths}};
	my $l=scalar(@wavelengths);
	# red
	my $ref=$wavelengths[0];
  	push(@waves,${$ref}{WaveNum});

	# green
	my $f=floor($l/2);
	my $refg=$wavelengths[$f];
  	push(@waves,${$refg}{WaveNum});
  
	#blue
	my $refb=$wavelengths[$l-1];	

  	push(@waves,${$refb}{WaveNum});
	my $tempo=$waves[0];
	push(@waves,$tempo);

	for(my $i=0;$i<4;$i++){
		push(@CBW,$waves[$i],0,4);
	}
	return \@CBW;		
}





############
# 	converts CBW from native format to hard numbers
#	This and makeCBWnative(CBW,theT) are the two functions that do conversion between
#			native format and hard numbers.
#		Currently it uses these functions.
#		c indicates converted, n indicates native
#			cB = geomean * nB
#			cS = 255 / ( geosigma * nS )
#		White level in OME_JPEG is geomean + geosigma*nS
#		returns undef if unsuccessful
#		returns converted CBW if successful

sub getConvertedCBW{
	my $self=shift;
	my ($theT)=@_;
	my @cCBW=();
	my $ref=$self->{CBW};
	my @CBW=@$ref;
	my $refstats=$self->{stats};
	my $refdim=$self->{dim};
	if (scalar(@$refstats)==0|| scalar(@$refdim)==0){
		return undef;
	}
	if ($theT<0||$theT>$self->{T} || $theT != round($theT)){
	  return undef;
	}

	for (my $i=0;$i<4;$i++){
		my $wavenum=$CBW[$i*3];
  		push(@cCBW,$wavenum);
		my ($geomean,$geosigma);	

        	$geomean=${$refstats}[$wavenum][$theT]{geomean};
	  	$geosigma=${$refstats}[$wavenum][$theT]{geosigma};
	  	my $value=$CBW[$i*3+1]+$geomean+$geosigma;
	  	$value=int($value);
    	  	push(@cCBW,$value);
	  	if ($CBW[$i*3+2]==0){
		 $CBW[$i*3+2]=0.0001;
	  	}
	  	if ($geosigma==0){return undef};		# must be changed
	  	my $B;
   	  	$B=255/($geosigma*$CBW[$i*3+2]);
	  	$B=int($B*10000)/10000;
	  	push(@cCBW,$B);
     }
	return \@cCBW;
}

######################

sub getImageStats{
	my ($factory,$image)=@_;
  	# new version
  	my $pixels = $image->DefaultPixels();
  	my $stackStats = $factory->findObject( "OME::Module", name => 'Stack statistics' )
		or die "Stack statistics must be installed for this viewer to work!\n";
	my $pixelsFI = $factory->findObject( "OME::Module::FormalInput",
		module_id => $stackStats->id(),
		name       => 'Pixels' )
		or die "Cannot find 'Pixels' formal input for Program 'Stack Statistics'.\n";
	my $actualInput = $factory->findObject( "OME::ModuleExecution::ActualInput",
		formal_input_id   => $pixelsFI->id(),
		input_module_execution_id => $pixels->module_execution()->id() )
		or die "Stack Statistics has not been run on the Pixels to be displayed.\n";
	my $stackStatsAnalysisID = $actualInput->module_execution()->id();

	my @mins   = grep( $_->module_execution()->id() eq $stackStatsAnalysisID,
		$factory->findAttributes( "StackMinimum", $image ) );
	my @maxes  = grep( $_->module_execution()->id() eq $stackStatsAnalysisID,
		$factory->findAttributes( "StackMaximum", $image ) );
	my @means  = grep( $_->module_execution()->id() eq $stackStatsAnalysisID,
		$factory->findAttributes( "StackMean", $image ) );
	my @gmeans = grep( $_->module_execution()->id() eq $stackStatsAnalysisID,
		$factory->findAttributes( "StackGeometricMean", $image ) );
	my @geosigma  = grep( $_->module_execution()->id() eq $stackStatsAnalysisID,
		$factory->findAttributes( "StackGeometricSigma", $image ) );
	
	my $sh; # stats hash
	foreach( @mins ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{min} = $_->Minimum(); }
	foreach( @maxes ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{max} = $_->Maximum(); }
	foreach( @means ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{mean} = $_->Mean(); }
	foreach( @gmeans ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{geomean} = $_->GeometricMean(); }
	foreach( @geosigma ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{geosigma} = $_->GeometricSigma(); }

 
 
 

	return $sh;
}

########################
sub getImageWavelengths{
	my ($factory,$image)=@_;
	my @Wavelengths;

	my $pixels = $image->DefaultPixels()
		or die "Could not a primary set of Pixels for this image\n";
	my @ccs = $factory->findAttributes( "PixelChannelComponent", $image )
		or die "Image has no PixelChannelComponent attributes! Cannot display!\n";
	my @channelComponents = grep{ $_->Pixels()->id() eq $pixels->id() } @ccs;
	die "Image has no channel components for default Pixels!" if( scalar(@channelComponents)==0 );
	foreach my $cc (@channelComponents) {
		my $ChannelNum = $cc->Index();
		my $Label;
    		my @overlap=();
		$Label = $cc->LogicalChannel()->Name()  || 
		         $cc->LogicalChannel()->Fluor() || 
		         $cc->LogicalChannel()->EmissionWavelength();

		#@overlap = grep( $cc->LogicalChannel()->id() eq $_->LogicalChannel()->id(), @channelComponents );
		#$Label .= $cc->Index() if( scalar( @overlap ) > 1 || $Label eq undef );
    		 $Label .= $cc->Index() if( not defined $Label || scalar( @overlap ) > 1);
		my %h=();
		$h{WaveNum}=$ChannelNum;
		$h{Label}=$Label;
		push (@Wavelengths,\%h);
	}

  

	 return \@Wavelengths;
}




################
sub getImageDim{
	my ($image)=@_ ;
	my $pixels = $image->DefaultPixels();
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


#######
sub round{
	my ($x)=@_;
	my $halfhex = unpack('H*', pack('d', 0.5));
	my $half = unpack('d',pack('H*', $halfhex));
	my $y;
 	$y=floor($x + $half);
  	return $y;
}

=head1 AUTHOR

JM Burel (jburel@dundee.ac.uk)

=cut

1;
