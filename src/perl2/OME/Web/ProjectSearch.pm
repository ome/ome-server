# OME/Web/ProjectSearch.pm

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


package OME::Web::ProjectSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Project Search" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my 	$body="" ;
	my 	$session=$self->Session();
	my	$userID=$session->User()->id();
	my	$datasetManager=new OME::Tasks::DatasetManager($session);
	my	$projectManager=new OME::Tasks::ProjectManager($session);
	my 	$htmlFormat=new OME::Web::Helper::HTMLFormat;
	my 	$jscriptFormat=new OME::Web::Helper::JScriptFormat;

	################
	# DB INFOS
	#	table name
	#	selected colums

	my 	$table="projects";			
      my 	$selectedcolumns="name,description,project_id,owner_id";
	###############

	my    $ref;
      my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;

	if ($cgi->param('search') ) {
         my $string=cleaning($cgi->param('name'));
	   $body.="<b>Please enter a data.</b>";
	   $body.=format_form($htmlFormat,$cgi); 
         return ('HTML',$body) unless length($string)>1;
	   $body="";
         
	  		

	  
         my $research=new OME::Research::SearchEngine($table,$selectedcolumns);
         if (defined $research){
	    $ref=$research->searchEngine($string);
         }
          if (defined $ref){
		$body .= $jscriptFormat->openInfoProject();	
            $body .=format_output($htmlFormat,$ref,$userID,$cgi);
          }else{
		$body.="No Project found.";
		$body .=format_form($htmlFormat,$cgi);

          }
	}elsif ($cgi->param('execute') ) {
		$datasetManager->switch($cgi->param('newdataset'));
		my $name=$session->dataset()->name();
		my @datasets=$session->project()->datasets();
		
		$body.=$htmlFormat->formatProject($session->project());
		$body.=format_datasetList($name,\@datasets,$htmlFormat,$cgi);
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		
	}elsif (exists $revArgs{Select}){
	  $projectManager->switch($revArgs{Select});
        my @datasets=$session->project()->datasets();
	  $body.=$htmlFormat->formatProject($session->project());

	  if (scalar (@datasets)>0){
	    $body.=format_datasetList($session->dataset()->name(),\@datasets,$htmlFormat,$cgi);	
	  }else{
	    $body.="No Dataset associated to this project. Please define a dataset.";
	  }
	  $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}else{
       $body .=format_form($htmlFormat,$cgi);
      }
	return ('HTML',$body) ;
}


#-----------------
# PRIVATE METHODS
#-----------------

sub format_form{
      my ($htmlFormat,$cgi) = @_ ;
	my $form="";
	$form .= $cgi->startform;
	$form .= $htmlFormat->formSearch("Projects");
	$form .=$cgi->endform;
	return $form ;

}



sub format_output{
	my ($htmlFormat,$ref,$userID,$cgi)=@_;
	my $text="";
	$text.= $cgi->startform;
	$text.=$htmlFormat->searchResults($ref,$userID,"Project(s)","project");
	$text .= $cgi->endform;
	return $text;
}


sub format_datasetList{
	my ($dataname,$ref,$htmlFormat,$cgi)=@_;
	my $html="";
 	$html.="<P>Your current dataset is: <B>".$dataname."</B></P>";
 	if (scalar(@$ref)>1){
		# display a list

		my %datasetList= map {$_->dataset_id() => $_->name()} @$ref;
		$html.="<p> If you want to switch, please choose a dataset in the list below.</p>";
		$html.=$cgi->startform;
		$html.=$htmlFormat->dropDownTable("newdataset",\%datasetList,"execute","Switch Dataset");			
		$html .= $cgi->endform;

 	}
 return $html;



}








sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}











1;
