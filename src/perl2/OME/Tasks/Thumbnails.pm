# OME/Tasks/Thumbnails.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  JM Burel <jburel@dundee.ac.uk>
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


package OME::Tasks::Thumbnails;

use POSIX;
use Image::Magick;
use GD;
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

=cut


sub new{

	my $class=shift;
	my $self={};
	$self->{size}=50;
	$self->{OME_JPEG}="/usr/local/apache/cgi-bin/OME_JPEG";
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
	my $WBS=undef;
  	my $RGBon=undef;
  	my $isRGB=undef;
	# retrieve image data

	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$path)=getImageDim($image);
	my $stats=getImageStats($image);			# ref array
	my $wavelengths=getImageWavelengths($image);	# ref array
	
	$theZ = $Z_param || (defined $sizeZ ? $sizeZ / 2 : 0 );
	$theT = $T_param || 0;

	my $displaySettings  = $factory->findObject("OME::DisplaySettings", 'image_id' => $image->id() );
	if (defined $displaySettings){
		$theZ	=$displaySettings->theZ() if (not defined $Z_param);
		$theT	=$displaySettings->theT() if (not defined $T_param);
		$isRGB= $displaySettings->isRGB();
		$WBS	= @{ $displaySettings->WBS() };
		$RGBon= @{ $displaySettings->RGBon() };

	}
	$isRGB=1;
   	$self->initialize($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$isRGB,$WBS,$RGBon);

    	my $jpg_image=$self->writeOMEimage($theZ,$theT);
	return $jpg_image;
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
  	my $color=$self->getConvertedWBS($theT);
	my $rgb="RGB=".join(",",@$color);
	my $rgbon="RGBon=".join(",",@{$self->{RGBon}});
  	my $script=$self->{OME_JPEG};
	my $out="";
	
	
	open (JPG, "$script $path $z $t $d $rgb $rgbon|");
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
	my ($path,$wavelengths,$stats,$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$isRGB,$RGBon,$WBS)=@_;
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
	if (defined $WBS){
  		$self->{WBS}=$WBS;		#ref array	in DB check if the case
	}else{
		my $ref=$self->makeWBS();	#default
		$self->{WBS}=$ref;
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




####
# WBS
# Make WBS default parameters
sub makeWBS{
	my $self=shift;
	my @waves=();
	my @WBS=();
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
		push(@WBS,$waves[$i],0,4);
	}
	return \@WBS;		
}



##################
#
#	utility to convert WBS from hard numbers to native format
#	This and getConvertWBS(theT) are the two functions that do conversion between
#	native format and hard numbers.
#	returns WBS in native format if successful
#	returns undef if unsuccessfull

sub makeWBSNative{
	my $self=shift;
	my ($refWBS,$theT)=@_;
	my @WBS=();
	@WBS=@$refWBS;
	my $refstats=$self->{stats};
	for(my $i=0;$i<4;$i++){
		my $wavenum=$WBS[$i*3];
		if ($wavenum<0 || $wavenum>=$self->{W} || $wavenum != int($wavenum)){
			return undef;
		}
		my ($geomean,$sigma);	
		my $ref=${$refstats}[$wavenum][$theT];
            $geomean=${$ref}{geomean};
     		$sigma=${$ref}{sigma};
     		if ($sigma==0){
			return undef;
		}
		my $value=($WBS[$i*3+1]+$geomean)/$sigma;
		$WBS[$i*3+1]=int($value);
		if ($WBS[$i*3+2]==0){
		   $WBS[$i*3+2]=0.0001;
		}
		$WBS[$i*3+2]=255/($sigma*$WBS[$i*3+2]);
		$WBS[$i*3+2]=int($WBS[$i*3+2]);
	}
	return \@WBS;

}


############
# 	converts WBS from native format to hard numbers
#	This and makeWBSnative(WBS,theT) are the two functions that do conversion between
#			native format and hard numbers.
#		Currently it uses these functions.
#		c indicates converted, n indicates native
#			cB = geomean * nB
#			cS = 255 / ( sigma * nS )
#		White level in OME_JPEG is geomean + sigma*nS
#		returns undef if unsuccessful
#		returns converted WBS if successful

sub getConvertedWBS{
	my $self=shift;
	my ($theT)=@_;
	my @cWBS=();
	my $ref=$self->{WBS};
	my @WBS=@$ref;
	my $refstats=$self->{stats};
	for (my $i=0;$i<4;$i++){
		my $wavenum=$WBS[$i*3];
  		push(@cWBS,$wavenum);
		my ($geomean,$sigma);	
		my $ref=${$refstats}[$wavenum][$theT];

	  	$geomean=${$ref}{geomean};
	  	$sigma=${$ref}{sigma};
       
	  	my $value=$WBS[$i*3+1]+$geomean+$sigma;
	  	$value=int($value);
    	  	push(@cWBS,$value);
	  	if ($WBS[$i*3+2]==0){
		 $WBS[$i*3+2]=0.0001;
	  	}
	  	if ($sigma==0){return undef};
	  	my $B;
   	  	$B=255/($sigma*$WBS[$i*3+2]);
	  	$B=int($B*10000)/10000;
	  	push(@cWBS,$B);
     }
	return \@cWBS;
}


######################

sub getImageStats{
	my ($image)=@_;
	my @s = $image->XYZ_info;
	#my @stats=();
	my $stats;
	foreach (@s) {
		my %a=(
		"min"		=>$_->min(),
		"max"		=>$_->max(),
		"mean"	=>$_->mean(),
		"geomean"	=>$_->geomean(),
		"sigma"	=>$_->sigma()
		);
		$stats->[$_->theW()][$_->theT()] = \%a;
	}
	return $stats;
}

########################
sub getImageWavelengths{
	my ($image)=@_;
	my @w = $image->wavelengths;
	my @wavelengths;
	
	# get this from DB eventually
	my $FluorWavelength = {
		FITC   => 528,
		TR     => 617,
		GFP    => 528,
		DAPI   => 457
	};
	foreach (@w) {
   	 	my @h=();
    	 	my  $em;
       	my  $fluor;
       	$fluor =$_->fluor();
       	if (defined $fluor){
          	  $em=$FluorWavelength->{$fluor} unless  defined $_->em_wavelength()  and   $_->em_wavelength();
      	}
       	$em= $_->wavenumber()+1 unless defined $em and $em; 
       	push(@h,$_->wavenumber(),$em,$fluor);
		push (@wavelengths,\@h);
	}
	my $wav = [sort {${$b}[1] <=> ${$a}[1]} @wavelengths];   
	my @Wavelengths;
	foreach my $rf (@$wav) {
    		my @arr=@$rf;
		my %h=("WaveNum"=>$arr[0]);
		if (exists $arr[2] and defined $arr[2]){
			$h{"Label"}=$arr[2];
		}else{
			$h{"Label"}=$arr[1];
		}
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

print STDERR "sizeX===".$sizeX."\n";
print STDERR "sizeY===".$sizeY."\n";

	#$sizeX = $dimensions->size_x();
	#$sizeY = $dimensions->size_y();
	#$sizeZ = $dimensions->size_z();	
	#$numW  = $dimensions->num_waves();
	#$numT  = $dimensions->num_times(),
  	#$bpp   = $dimensions->bits_per_pixel();
	
	$bpp /= 8;
	return ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp,$path);
}




=head1 AUTHOR

JM Burel (jburel@dundee.ac.uk)

=cut

1;
