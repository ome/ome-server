# OME/Web/DatasetInProjects.pm

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
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::DatasetInProjects;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;


use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Projects Containing Current Dataset";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $projectManager=new OME::Tasks::ProjectManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";
      my @list=$session->project()->datasets();
      if (scalar(@list)==0){
		$body.="<h3>No current dataset. Please define a dataset<h3>";
		return ('HTML',$body);
	}

	my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if (exists	$revArgs{Select}){
	   $projectManager->switch($revArgs{Select},1);
     	   my @datasets=$session->project()->datasets();
         $body.=$htmlFormat->formatProject($session->project());
	   $body.=format_datasetList($session->dataset()->name(),\@datasets,$htmlFormat,$cgi);
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif ($cgi->param('execute')){
	   $datasetManager->switch($cgi->param('newdataset'));

	   my $name=$session->dataset()->name();
	   my @datasets=$session->project()->datasets();
	   my $formatdata=format_datasetList($name,\@datasets,$htmlFormat,$cgi);
	   $body.=$htmlFormat->formatProject($session->project());
	   $body.=$formatdata;
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}else{
         if (defined $session->dataset()){
            my @listprojects=$session->dataset()->projects();
	      $body.=$htmlFormat->formatDataset($session->dataset());
            if (scalar(@listprojects)>0){
		   $body .= $jscriptFormat->openInfoProject();
		   $body.=format_projectList(\@listprojects,$htmlFormat,$cgi);
            }else{
	         $body.="<h3>The current dataset is contained in no project.</h3>" ;
            }
         }else{
               $body .="<h3>You have no dataset currently selected. Please select one.</h3>" ;
         }

     }
	

     return ('HTML',$body);
}

#---------------------
#PRIVATE METHODS
#---------------------



sub format_datasetList{
	my ($dataname,$ref,$htmlFormat,$cgi)=@_;
	my $summary="";
	$summary.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 	if (scalar(@$ref)>1){
		my %datasetList= map {$_->dataset_id() => $_->name()} @$ref;	
		$summary.="<p> If you want to switch, please choose a dataset in the list below.</p>";
		$summary.=$cgi->startform;
		$summary.=$htmlFormat->dropDownTable("newdataset",\%datasetList,"execute","Switch");
		$summary .= $cgi->endform;
		
 	}
	return $summary;
}







sub format_projectList{
	my ($ref,$htmlFormat,$cgi)=@_;
  	my $summary="";
	$summary .="<h3>The current dataset is contained in the project(s) listed below.</h3>" ;
	$summary.=$cgi->startform;
	$summary.=$htmlFormat->projectList($ref);
 	$summary.=$cgi->endform;

 	return $summary;
}



1;
