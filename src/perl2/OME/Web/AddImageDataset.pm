# OME/Web/AddImageDataset.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Jean-Marie Burel <j.burel@dundee.ac.uk>
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


package OME::Web::AddImageDataset;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Add Image/Existing Dataset" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session=$self->Session();
	my 	$datasetManager=new OME::Tasks::DatasetManager($session);
	my 	$imageManager=new OME::Tasks::ImageManager($session);
	my	$htmlFormat=new OME::Web::Helper::HTMLFormat;
	my 	$jscriptFormat=new OME::Web::Helper::JScriptFormat;


	my 	$body="" ;
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
	$body .= $jscriptFormat->popUpImage();    
	if ($cgi->param('Add')){
	    $datasetManager->switch($cgi->param('AddDataset'));
	    my ($a,$b)=format_selected_dataset($session->dataset(),$htmlFormat,$cgi);
	    $body.=$a;
	    if (defined $b){
		$body.=format_list_images($session,$imageManager,$htmlFormat,$cgi);
	    }
 	    $body .= "<script>top.title.location.href = top.title.location.href;</script>";			
	
	}elsif(exists $revArgs{Unlock}){
		$datasetManager->lockUnlock($revArgs{Unlock},"f");
		$datasetManager->switch($revArgs{Unlock});
            my ($a,$b)=format_selected_dataset($session->dataset(),$htmlFormat,$cgi);
	   	$body.=$a;
		if (defined $b){
		    $body.=format_list_images($session,$imageManager,$htmlFormat,$cgi);
	      }
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	  		


	}elsif ($cgi->param('addImage')){
		my $dataset=$session->dataset();
		my @addImages=$cgi->param('ListImage');
		return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@addImages)>0;
		$datasetManager->addImages(\@addImages);
		foreach (@addImages){
			$body.=$_."<br>";

		}		
		my ($a,$b)=format_selected_dataset($session->dataset(),$htmlFormat,$cgi);
	   	$body.=$a;
		if (defined $b){
		   $body.=format_list_images($session,$imageManager,$htmlFormat,$cgi);
	      }
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";



      }else{
	 $body.=print_status($session,$datasetManager,$htmlFormat,$cgi);
      }
	return ('HTML',$body);

		
}


#---------------------
# PRIVATE METHODS
#---------------------

sub print_status{
	my ($session,$datasetManager,$htmlFormat,$cgi)=@_;
 	my $text="";
	my @a=($session->User()->Group()->id());
 	my ($share,$own,$count,$countb)=$datasetManager->share(\@a);
 	if ($count>0){
   		$text.="<h3>Datasets you own but used by others<h3>";
   		$text.=$htmlFormat->datasetList($share);
	}

	 if ($countb>0){
  		 $text.=format_form($own,$htmlFormat,$cgi);
 	}else{
   		$text.="<h3>All your datasets are used. Cannot add new images</h3>";
 	}
	 return $text;
}



sub format_form{
	my ($ref,$htmlFormat,$cgi)=@_;
 	my $text="";
 	my %list=();
 	foreach (keys %$ref){
  		$list{$_}=${$ref}{$_}->name();
 	}
 	$text.="<h3>If you want to add images, please choose a dataset in list below</h3>";
 	$text .= $cgi->startform;
	$text.=$htmlFormat->dropDownTable("AddDataset",\%list,"Add","Dataset");
 	$text .= $cgi->endform;
  	return $text;
}


#------------
#"Add" stuff

sub format_selected_dataset{
 	my ($dataset,$htmlFormat,$cgi)=@_;
 	my $summary="";
 	my $button="";
 	my $word;
 	my $bool=undef;
 	my @images=$dataset->images();
	$summary .=$htmlFormat->formatDataset($dataset);
 	if (scalar(@images)>0){
 	 	$summary.=$htmlFormat->imageInDataset(\@images);
 	}
 	if ($dataset->locked()){
 	 	$summary.="<b>The selected dataset is locked. You cannot add images.</b>";
 	}else{
  	 	$bool=1;
 	}
 	return ($summary,$bool) ;
}


sub format_list_images{
 	my ($session,$imageManager,$htmlFormat,$cgi)=@_;
	my $text="";
 	my $checkbox="";
	my @a=($session->User()->Group()->id());
 	my $rep=$imageManager->listMatching(\@a,1);
	if (!defined $rep){
	  my $html="";
	  $html="<br><b> All images used </b>";
	  return $html;
	}
 	if (scalar(@$rep)>0){
	   my %list=map {$_->image_id()=>$_} @$rep;
	   $text.=$cgi->startform;
   	   $text.=$htmlFormat->listImages(\%list,"addImage","Add Images");
	   $text.=$cgi->endform;   
 	}
 	return $text;
}


1;




