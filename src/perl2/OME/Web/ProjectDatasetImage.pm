# OME/Web/ProjectDatasetImage.pm

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


package OME::Web::ProjectDatasetImage;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use OME::Web::Validation;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Make Dataset from existing images";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $imageManager=new OME::Tasks::ImageManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;


	my $body = "";
	my $project =$session->project();
	my $userID=$session->User()->id();
	my $usergpID=$session->User()->Group()->id();
	if( not defined $project ) {
		$body .= OME::Web::Validation->ReloadHomeScript();
		return ("HTML",$body);
     }
     $body .= $jscriptFormat->openExistingDataset();	

     if ($cgi->param('create')){
         my $datasetName=cleaning($cgi->param('name'));
         my @addImages=$cgi->param('ListImage');
	   return ('HTML',$htmlFormat->noNameMessage("dataset")) unless $datasetName;
	   my $rep=$datasetManager->exist($datasetName);
         return ('HTML',$htmlFormat->existMessage("dataset")) unless (defined $rep);
	   return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@addImages)>0;
	   my $result=$datasetManager->create($datasetName,$cgi->param('description'),$userID,$usergpID,$project->project_id(),\@addImages); 
		


	  # my $result=$datasetManager->create($cgi->param('name'), $cgi->param('description'),\@addImages); 
	 if (defined $result){
         $body .= "<script>top.location.href = top.location.href;</script>";
         $body .= "<script>top.title.location.href = top.title.location.href;</script>";
	 }else{
	   $body .= print_form($usergpID,$imageManager,$htmlFormat,$cgi);
	 }			
    }else{
	   $body .= print_form($usergpID,$imageManager,$htmlFormat,$cgi);
    }
    return ('HTML',$body);	
}




#--------------------
#
sub print_form {
	my ($usergpID,$imageManager,$htmlFormat,$cgi)=@_;
	my $text="";
	my $images=$imageManager->listMatching();
 	if (scalar(@$images)>0){
	   my %list=map { $_->image_id() => $_} @$images;
         $text.=$cgi->startform;
  	   $text.=$htmlFormat->formCreate("dataset",$usergpID,\%list);
	   $text.$cgi->endform;
 	}else{
	   $text.="no images in your Research group";
 	}
 	return $text;
}



sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}


1;
