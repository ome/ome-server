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
use OME::Tasks::ImageManager;
our $VERSION = '1.0';

=head1 NAME

OME::Tasks::Thumbnails - produces thumbnails using GD

=head1 SYNOPSIS

	use OME::Tasks::Thumbnails;
	my $generator=new OME::Tasks::Thumbnails();
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

=cut


sub new{

	my $class=shift;
	my $self={};
	$self->{size}=50;
	$self->{OME_JPEG}="OME_JPEG";
	bless($self,$class);
   	return $self;

}

#################
# Parameters:
#	image= image object

sub generateOMEimage{
	my $self=shift;
	my ($imageID,$Z_param,$T_param)=@_;
	my $session=$self->__Session() or die "Unable to retrieve session object.";
	my $factory=$session->Factory();
	my $imageManager=OME::Tasks::ImageManager->new($session);
	my ($theZ,$theT);
	my $CBW=undef;
	my $RGBon=undef;
  	my $isRGB=1;
	my $image=$factory->loadObject("OME::Image",$imageID);
	# retrieve image data
	my ($sizeX,$sizeY,$sizeZ,$numC,$numT,$bpp,$path)=$imageManager->getImageDim($image);

	my $stats=$imageManager->getImageStats($image);			     	# ref array
	my $wavelengths=$imageManager->getImageWavelengths($image);		# ref array
  	if (not defined $sizeX || not defined $sizeY || not defined $sizeZ
 	   ||not defined $numC || not defined $numT || not defined $bpp || not defined $path){
   		return undef;

  	}
   	if (scalar(@$wavelengths) != $numC ||  scalar(@$stats) != $numC){
    		return undef;
   	}
	$theZ = $Z_param || (defined $sizeZ ? $sizeZ / 2 : 0 );
	$theT = $T_param || 0;

	my $displayOptions=$imageManager->getDisplayOptions($image);
	if (defined $displayOptions){
				
		$theZ=${$displayOptions}{theZ} unless defined $Z_param;
		$theT=${$displayOptions}{theT} unless defined $T_param;
		$isRGB= ${$displayOptions}{isRGB};
		$CBW=${$displayOptions}{CBW};
		$RGBon=${$displayOptions}{RGBon};
	}
   	$self->initialize($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numC,$numT,$bpp,$isRGB,$CBW,$RGBon);

	my $jpg_image=$self->writeOMEimage($theZ,$theT);

	return $jpg_image;
}


#######################

sub generateOMEimages{

	my ($self,$imageID)=@_;
	my $session=$self->__Session();
	my $factory=$session->Factory();
	my $imageManager=OME::Tasks::ImageManager->new($session);
	my $image=$factory->loadObject("OME::Image",$imageID);
	my $CBW=undef;
	my $RGBon=undef;
  	my $isRGB=1;
	my $out;
	# retrieve image data
	my ($sizeX,$sizeY,$sizeZ,$numC,$numT,$bpp,$path)=$imageManager->getImageDim($image);

	my $stats=$imageManager->getImageStats($image);			     	# ref array
	my $wavelengths=$imageManager->getImageWavelengths($image);		# ref array
	if (not defined $sizeX || not defined $sizeY || not defined $sizeZ
  		||not defined $numC || not defined $numT || not defined $bpp || not defined $path){
   		return undef;
  
  	}
   	if (scalar(@$wavelengths) != $numC ||  scalar(@$stats) != $numC){
    		return undef;
   	}
	my $displayOptions=$imageManager->getDisplayOptions($image);

	if (defined $displayOptions){
		$isRGB= ${$displayOptions}{isRGB};
		$CBW=${$displayOptions}{CBW};
		$RGBon=${$displayOptions}{RGBon};
	}

	$self->initialize($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numC,$numT,$bpp,$isRGB,$CBW,$RGBon);
	for (my $theZ=0;$theZ<$sizeZ;$theZ++){
		for(my $theT=0;$theT<$self->{T};$theT++){
			#generate image
			my $jpg=$self->writeOMEimage($theZ,$theT);
			$out->[$theZ][$theT]=$jpg;		#array
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
	my $refstats=$self->{stats};
  	my $cCBW=$self->getConvertedCBW($theT);
	if (not defined $cCBW){
		return undef;
	}
	
	for (my $i=0;$i<4;$i++){
		my $wavenum=$cCBW->[$i*3];
		if ($cCBW->[$i*3+1]<${$refstats}[$wavenum][$theT]{min}){
			$cCBW->[$i*3+1]=ceil(${$refstats}[$wavenum][$theT]{min});
		}
		if ($cCBW->[$i*3+1]>${$refstats}[$wavenum][$theT]{max}){
			$cCBW->[$i*3+1]=floor(${$refstats}[$wavenum][$theT]{max});
		}
		my $whiteLevel=${$refstats}[$wavenum][$theT]{geomean}+$cCBW->[$i*3+2]*${$refstats}[$wavenum][$theT]{geosigma};
		my $recalculate=undef;
		if ($whiteLevel<${$refstats}[$wavenum][$theT]{min}){
			$whiteLevel=${$refstats}[$wavenum][$theT]{min};
			$recalculate=1;
		}
		if ($whiteLevel>${$refstats}[$wavenum][$theT]{max}){
			$whiteLevel=${$refstats}[$wavenum][$theT]{max};
			$recalculate=1;
		}
		if (defined $recalculate){
			if ($whiteLevel-${$refstats}[$wavenum][$theT]{geomean}){
				$whiteLevel=$whiteLevel+0.00001;
			}
			$cCBW->[$i*3+2]=255/($whiteLevel-${$refstats}[$wavenum][$theT]{geomean});
		}
		
	}

	if ($self->{inColor}==1){
	    splice(@$cCBW,-3);	
	}else{
	     splice(@$cCBW,0,9);
	}
	
	my $rgb="RGB=".join(",",@$cCBW);
	my $rgbon="RGBon=".join(",",@{$self->{RGBon}});

	my $factory=$self->__Session()->Factory();
	my $configuration =$self->__Session()->Configuration();
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
	my ($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numC,$numT,$bpp,$isRGB,$CBW,$RGBon)=@_;
	$self->{path}=$path;
	$self->{wavelengths}=$wavelengths;
	$self->{stats}=$stats;
	$self->{X}=$sizeX;
	$self->{Y}=$sizeY;
	$self->{Z}=$sizeZ;
	$self->{W}=$numC;
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
			if ($i<$numC){
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
		push(@CBW,$waves[$i],0,3.5);		
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

sub __Session { OME::Session->instance() };



#############
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
