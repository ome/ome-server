# OME/Web/ImageSearch.pm

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


package OME::Web::ImageSearch;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;

use OME::Research::SearchEngine;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw(OME::Web);

#####################
sub getPageTitle {
	return "Open Microscopy Environment - Image Search" ;

}
####################

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$htmlFormat=new OME::Web::Helper::HTMLFormat;
	my 	$jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my 	$body="" ;

	##########################
	# DB info
	# 	table name 
	#	selected columns

	my 	$table="images";			
      my 	$selectedcolumns="name,inserted,image_id";	
	##########################

	my    $ref;
	if ($cgi->param('search') ) {
	   my $tableRows="";
         my $string=cleaning($cgi->param('name'));
         return ('HTML',"<b>Please enter a data.</b>") unless length($string)>1;
         my $research=new OME::Research::SearchEngine($table,$string,$selectedcolumns);
         if (defined $research){
	    $ref=$research->searchEngine;
         }
         if (defined $ref){
		$body .= $jscriptFormat->popUpImage();    
		$body .=format_output($ref,$htmlFormat,$cgi);
         }else{
		$body.="No Image found.";
		$body .=format_form($htmlFormat,$cgi);

         }

	}else{
	   $body .=format_form($htmlFormat,$cgi);
      }
	return ('HTML',$body) ;
}


#---------------------
# PRIVATE METHODS
#---------------------


sub format_output{
	my ($ref,$htmlFormat,$cgi)=@_;
	my $text="";
	$text.="<h3>List of image(s) matching your data.</h3>";
	$text.="<form>";
	$text.=$htmlFormat->imageInDataset($ref,1,1);	
	$text.="</form>";
	return $text;
}



sub format_form{
	my ($htmlFormat,$cgi) =@_ ;
	my $form="";
	$form .=$cgi->startform;
	$form.=$htmlFormat->formSearch("Images");
	$form .=$cgi->endform;
	return $form ;
}


sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}

1;



