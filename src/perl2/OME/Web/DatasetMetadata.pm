# OME/Web/DatasetMetadata.pm

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
# Written by:    J-M Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::DatasetMetadata;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use CGI;
use OME::Web::Validation;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Dataset Metadata";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	
      my @listdataset=$session->project()->datasets();
      if (scalar(@listdataset)==0){
	 	$body.="<h3>No current dataset. Please define a dataset<h3>";
		return ('HTML',$body);

      }

	if( $cgi->param('save')) {
		my $datasetname=cleaning($cgi->param('name'));
		
		$body.="<b>Please enter a name for your dataset.</b>";
		$body.=print_form($session,$htmlFormat,$cgi);
		return ('HTML',$body) unless $datasetname;
		if ($session->dataset()->name() ne $cgi->param('name')){
         		my $ref=$datasetManager->nameExists($datasetname);
			$body="";
			$body.="<b>This name is already used. Please enter a new name for your dataset.</b>";
			$body.=print_form($session,$htmlFormat,$cgi);
	   		return ('HTML',$body) unless (not defined $ref);

	      }
		$body="";
		$datasetManager->change($cgi->param('description'),$cgi->param('name'));
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "Save successful<br>";
	}
	
	$body .= print_form($session,$htmlFormat,$cgi);
    	return ('HTML',$body);
}

#-----------------
# PRIVATE METHODS
#------------------

sub print_form {
	my ($session,$htmlFormat,$cgi) = @_;
	my $text ="";
	my $userID=$session->dataset()->owner_id();
	my $user=$session->Factory()->loadAttribute("Experimenter",$userID);	

	$text .=$cgi->startform;
	$text .=$htmlFormat->formChange("dataset",$session->dataset(),$user);			
	$text .=$cgi->endform;
	return $text;
}


sub cleaning{
		  my ($string)=@_;
		 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}






1;
