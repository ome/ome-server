# OME/Web/XMLFileExport.pm

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


package OME::Web::XMLFileExport ;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Tasks::OMEXMLImportExport;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;
use OME::Tasks::OMEXMLImportExport;
use OME::Tasks::ImageManager;


use base qw(OME::Web);


sub getPageTitle {
	return "Open Microscopy Environment - Export to an XML file" ;
}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session = $self->Session() ;
	my 	$body = "" ;
	my 	$htmlformat = new  OME::Web::Helper::HTMLFormat() ;
 
	if ($cgi->param('export')){
		my $fileName=cleaning($cgi->param('name'));
		my $text="Please enter a name<br>";
		return ('HTML',$text) unless $fileName;
		my @images=$cgi->param('ListImage');
		return ('HTML',"<b>No image selected. Please try again </b>") unless scalar(@images)>0;
		
		

		my $imageManager= OME::Tasks::ImageManager->new($session);
		my @list=();
		foreach (@images){
			push(@list,$imageManager->load($_));
		}
		my $exporter= OME::Tasks::OMEXMLImportExport->new($session);
		$exporter->exportToXMLFile(\@list,$fileName);
	
		$body.="Wait and see";
	}else{
	 	$body .= print_form($session,$htmlformat,$cgi) ;
	}
	return ('HTML',$body) ;
}


################
sub print_form {
	my  ($session,$htmlFormat,$cgi) = @_ ;
	my  $html = "" ;
  	my @images=$session->dataset()->images();
	$html.="<h3>Export images to an XML file</h3>";

	
 	if (@images){
		 $html .= $cgi->startform ;
		 $html.="<b>*Name File:</b><input name=\"name\" type=\"text\" size=\"25\">";
		 my %list=map {$_->image_id()=>$_} @images;
		 $html.=$htmlFormat->listImages(\%list,"export","Export");
	

	}else{
		$html.="The selected dataset contains no image<br>";
	}

	return  $html ;
}




sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}





1;
