# OME/Web/DatasetComponents.pm

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


package OME::Web::DatasetComponents;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Images in current Dataset";
}

sub getPageBody {
	my $self = shift;
	my $session=$self->Session();
	my $cgi=$self->CGI();
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;

	my $body = "";
	$body .= $jscriptFormat->popUpImage();    	     
	$body.=print_form($session,$htmlFormat);
	return ('HTML',$body);
}





#---------------------
#PRIVATE METHODS
#---------------------
sub print_form{
	my ($session,$htmlFormat)=@_;
	my $dataset =$session->dataset();
	my @list=$session->project()->datasets();
	my $text="";
	if (scalar(@list)==0){
		$text.="<b>No current dataset. Please define a dataset</b>";
  		return $text;
 	}

 	my @listimages=();
 	@listimages=$dataset->images();
 	$text.=$htmlFormat->formatDataset($dataset);

 	if (scalar(@listimages)>0){
  	 $text.=format_images(\@listimages,$htmlFormat);
 	}else{
  	 $text.="<h3>The current dataset contains no image.</h3>" ;
 	}
  	return $text;
}


sub format_images{
 	my ($ref,$htmlFormat,$cgi)=@_;
  	my $summary="";
  	if (scalar(@$ref)==1){
     		$summary .= "<h3>The current dataset contains the image listed below.</h3>" ;
  	}else{
    		$summary .= "<h3>The current dataset contains the images listed below.</h3>" ;
  	}
   	$summary .="<form>";
   	$summary.=$htmlFormat->imageInDataset($ref,1);
   	$summary .="</form>";
   	return $summary;
}

1;

