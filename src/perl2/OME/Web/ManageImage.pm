# OME/Web/ImageManager.pm

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
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ManageImage;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::SetDB;
use OME::Tasks::ImageManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Image Manager";
}

# project owner
# datasets used
# images in datasets.

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session=$self->Session();
	my $imageManager=new OME::Tasks::ImageManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";

	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
	my @dynamics=$session->Factory()->findObjects("OME::DataTable",'granularity'=>'D');

	if (exists $revArgs{Remove}){
	   my @groupdatasets=$cgi->param('List');
	   $body.=remove_image($imageManager,\@groupdatasets);
	}elsif(exists $revArgs{Delete}){
         $body.=delete_image_process($imageManager,$revArgs{Delete});	  
	}  
	$body .= $jscriptFormat->popUpImage();    
	$body.=print_list($session,$imageManager,$htmlFormat,$cgi);  
      return ('HTML',$body);
}






#---------------------------
# PRIVATE METHODS
#---------------------------

sub delete_image_process{
	my ($imageManager,$id)=@_;
	my $text="";
	my $result=$imageManager->delete($id);
	$text.="Image deleted" if (defined $result);
	return $text;
}





sub remove_image{
	my ($imageManager,$ref)=@_;
	my %list=();
	my $text="";
	return undef if (scalar(@$ref)==0);
	foreach (@$ref){
		my ($imageID,$datasetID)=split("-",$_);
		if (exists $list{$imageID}){
	 	 my $val=$list{$imageID};
	  	 push(@$val,$datasetID);
	 	 $list{$imageID}=$val;
		}else{
	  	 my @a=($datasetID);
	  	 $list{$imageID}=\@a;
		}
  	}
  	my $rep=$imageManager->remove(\%list);
  	$text.="<b>image removed<b>" if (defined $rep);
  	return $text;

}


sub print_list{

	my ($session,$imageManager,$htmlFormat,$cgi)=@_;;
	my $text="";
	my ($gpImages,$userImages)=$imageManager->manage();
	my $count=0;
	foreach (keys %$userImages){
		$count++;
		my $a=${$userImages}{$_}->{remove};
		my $boolremove=undef;
      	foreach my $r (keys %$a){
	 	  if (defined ${$a}{$r}){
	  		 $boolremove=1;
	 	  }
      	}
		my $booldel=1;
      	if (exists ${$gpImages}{$_}){
	   		$booldel=undef;
		}
		my $formatimage=format_image($session->Factory(),${$userImages}{$_}->{image},$session->User()->id(),$htmlFormat,$booldel);
  	 	${$userImages}{$_}->{text}=$formatimage;

  	}
  	if ($count==0){
   		$text.="<br><b>no images to display.</b>";
  	}else{
     		$text.=format_output($userImages,$htmlFormat,$cgi);
  	}
	return $text;
}

sub format_output{
	my ($userImage,$htmlFormat,$cgi)=@_;   
	my $summary="";
	my $rows="";
	$summary.="<h3>List of image(s) used:</h3>";
	$summary.=$cgi->startform;
	$summary.=$htmlFormat->manager($userImage,"Remove","Remove","image");
	$summary.=$cgi->endform;
	return $summary;
}


sub format_image{
	my ($factory,$image,$userID,$htmlFormat,$bool)=@_;
	my $summary="";
	my $ownerID=$image->experimenter_id();
	my $owner=$factory->loadAttribute("Experimenter",$ownerID);
	$summary.=$htmlFormat->formatImage($image);
	my $imID=$image->image_id();


	my $thumbnail="<a href=\"#\" onClick=\"return openPopUpImage($imID)\"><img src=/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID=".$imID." align=\"bottom\" border=0></a>";
	$summary.=$thumbnail;
	$summary.=$htmlFormat->buttonControl($image,$userID,$owner,$bool,"image");
	return $summary;
}


1;

