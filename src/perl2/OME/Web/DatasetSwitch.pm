# OME/Web/DatasetSwitch.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  J-M Burel <j.burel@dundee.ac.uk>
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


package OME::Web::DatasetSwitch;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::Web::Validation;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub getPageTitle {
 	return "Open Microscopy Environment - Switch Dataset";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $datasetManager=new OME::Tasks::DatasetManager($session);
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;

	my $body = "";
	

	if ($cgi->param('Switch')){
	  $datasetManager->switch($cgi->param('newDataset'));
	}
	$body.=print_form($session,$datasetManager,$htmlFormat,$cgi);
	$body .= "<script>top.title.location.href = top.title.location.href;</script>";
      return ('HTML',$body);
}






#--------------------
# PRIVATE METHODS
#------------------

sub print_form {
	my ($session,$datasetManager,$htmlFormat,$cgi)= @_;
	my $text="";
	my $dataset = $session->dataset();
	my @a=($session->User()->Group()->id());
	my $ref=$datasetManager->listMatching(undef,\@a);
	my %h = map { $_->dataset_id() => $_->name() } @$ref;

	if (defined $dataset){
	 $text.=$htmlFormat->formatDataset($dataset);
	}else{
    	 $text.="<h3>No current dataset</h3>";
   	}
   	$text .= $cgi->startform;
   	$text .=$htmlFormat->dropDownTable("newDataset",\%h,"Switch","Switch dataset");
   	$text .= $cgi->endform;
   	return $text;
	
}




1;
