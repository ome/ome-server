# OME/Web/DatasetSearch.pm

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


package OME::Web::DatasetSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Dataset Search" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my 	$session=$self->Session();
	my	$datasetManager=new OME::Tasks::DatasetManager($session);
	my	$htmlFormat=new OME::Web::Helper::HTMLFormat;
	my 	$jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my 	$body="" ;
	######################
	# DB info
	#	table name
	# selected columns

	my 	$table="datasets";	
      my 	$selectedcolumns="name,description,locked,dataset_id";	
	##############
	my    $ref;
      my @names = $cgi->param();
	my %revArgs = map { $cgi->param($_) => $_ } @names;
      if (exists $revArgs{Select}){
	   $datasetManager->switch($revArgs{Select});
	   $body.=$htmlFormat->formatDataset($session->dataset());
	   $body .= "<script>top.title.location.href = top.title.location.href;</script>";

	}elsif ($cgi->param('search') ) {
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
		$body .= $jscriptFormat->openInfoDataset();	

            $body.=format_output($session,$ref,$datasetManager,$htmlFormat,$cgi);
          }else{
		$body.="No Dataset found.";
		$body.=format_form($htmlFormat,$cgi);

          }

	}else{
          $body .=format_form($htmlFormat,$cgi);
      }
	return ('HTML',$body) ;
}


#------------------
# PRIVATE METHODS
#------------------


sub format_form{
	my ($htmlFormat,$cgi) =@_;
	my $form="";
	$form .=$cgi->startform;
	$form .=$htmlFormat->formSearch("Datasets");
	$form.=$cgi->endform;
	return $form ;

}

sub format_output{
	my ($session,$ref,$datasetManager,$htmlFormat,$cgi)=@_;
      my $text="";
	my @a=($session->User()->Group()->id());
      my $array=$datasetManager->listMatching(undef,\@a);
	my %h = map { $_->dataset_id() => $_->name() } @$array;
	$text.=$cgi->startform;
	$text.=$htmlFormat->searchResults($ref,undef,"Dataset(s)","dataset",\%h);
      $text.=$cgi->endform;

	return $text;
}



sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}











1;

