# OME/Web/ManageProject.pm

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
# Written by:    JM Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ManageProject;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;

use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;


use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Project Manager";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	
	my $session = $self->Session();
	my $currentproject=$session->project();
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $datasetManager= new OME::Tasks::DatasetManager($session);
	my $htmlFormat= new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";
	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
	 $body .= $jscriptFormat->openInfoProject();
	if (exists $revArgs{Select}){

	    $projectManager->switch($revArgs{Select});
	    my @datasets=$session->project()->datasets();

	    $body.=$htmlFormat->formatProject($session->project());
	    if (scalar (@datasets)>0){
		 $body.=format_datasetList($htmlFormat,$session->dataset()->name(),\@datasets,$cgi);	
	    }else{
		 $body.="No Dataset associated to this project. Please define a dataset.";
	    }
	    $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif (exists $revArgs{Delete}){
		$projectManager->delete($revArgs{Delete});
		if (defined $session->project()){
		  $body.=print_form($session,$projectManager,$htmlFormat,$cgi);
		}else{
		  $body .= "<script>top.location.href = top.location.href;</script>";
		}
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
	}elsif ($cgi->param('execute')){
	   $datasetManager->switch($cgi->param('newdataset'));

	   my @datasets=$session->project()->datasets();
	   my $formatdata=format_datasetList($htmlFormat,$session->dataset()->name(),\@datasets,$cgi);
	   $body.=$htmlFormat->formatProject($session->project());
	   $body.=$formatdata;
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	}else{
	   $body .= print_form($session,$projectManager,$htmlFormat,$cgi);
	}
    return ('HTML',$body);
}








#####################
# PRIVATE METHODS	  #
#####################

sub print_form {

	my ($session,$projectManager,$htmlFormat,$cgi)=@_;
	my $text ="";
	my $ref=$projectManager->listMatching($session->User()->id());
	$text.="Please define a project first.<br>"; 
	return $text if (scalar(@$ref)==0);
	$text="";
	$text .="<h3>You own these projects:</h3>";
	$text .= $cgi->startform;
	$text.=$htmlFormat->projectList($ref,1);
	$text.=$cgi->endform;
	return $text;

}



sub format_datasetList{
	my ($htmlFormat,$dataname,$ref,$cgi)=@_;
 	my $html="";
 	if (defined $dataname){
 		$html.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 	}else{
		$html.="No dataset defined for this project";
	 }
 	if (scalar(@$ref)>1){
		my %datasetList= map {$_->dataset_id() => $_->name()} @$ref;
		$html.="<p> If you want to switch, please choose a dataset in the list below.</p>";
		$html.=$cgi->startform;
		$html.=$htmlFormat->dropDownTable("newdataset",\%datasetList,"execute","Switch Dataset");			
		$html .= $cgi->endform;

 	}
 	return $html;
}

1;
