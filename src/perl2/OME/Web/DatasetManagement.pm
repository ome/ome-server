# OME/Web/DatasetManagement.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Josiah <siah@nih.gov>
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


package OME::Web::DatasetManagement;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Dataset Management";
}

sub getPageBody {
	my $self = shift;

	my $cgi     = $self->CGI();
	my $session = $self->Session();

	my $datasetManager      = OME::Tasks::DatasetManager->new($session);
	$self->{datasetManager} = $datasetManager;
	$self->{htmlFormat}     = OME::Web::Helper::HTMLFormat->new();
	my $jscriptFormat       = OME::Web::Helper::JScriptFormat->new();

	my $body;
	$body .= $jscriptFormat->popUpImage();    	     
	
	# determine action
	if( $cgi->param('save')) {
		my $datasetname = $cgi->param('name')
			or return (
				'HTML', 
				"<b>Please enter a name for your dataset.</b>".$self->print_form() 
			);
		if ($session->dataset()->name() ne $cgi->param('name')){
			my $ref=$datasetManager->exist($datasetname)
				or return (
					'HTML',
					"<b>This name is already used. Please enter a new name for your dataset.</b>".$self->print_form()
				);
		}
		$datasetManager->change($cgi->param('description'),$cgi->param('name'));
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "Save successful<br>";
	} 
	
	# print form
	$body .= $self->print_form();
	
	return ('HTML',$body);
}



###################
sub print_form {
	my $self = shift;
	my $cgi        = $self->CGI();
	my $session    = $self->Session();
	my $dataset    = $session->dataset();
	my $factory    = $session->Factory();
	my $htmlFormat = $self->{htmlFormat};
	my $userID     = $dataset->owner_id();
	my $user       = $factory->loadAttribute("Experimenter",$userID);	

	my $datasetManager = $self->{datasetManager};

	my $text = '';

	$text .= $cgi->startform;
	$text .= "<center><h2>Dataset ".$dataset->name()." properties</h2></center>";
	$text .= $htmlFormat->formChange("dataset",$session->dataset(),$user);
	$text .= "<center><h2>Images</h2></center>";
	$text .= $self->makeImageListings();
	$text .= $cgi->endform;
	
	return $text;
}

sub makeImageListings{
	my $self = shift;

	my $session    = $self->Session();
	my $htmlFormat = $self->{htmlFormat};
	my @images     = $session->dataset()->images();

	my $text;

	if( scalar @images > 0 ) {
		$text .= "<h3>The current dataset contains the image".(scalar @images == 1 ? '' : 's')." listed below.</h3>";
		$text .= $htmlFormat->imageInDataset(\@images,1);
	} else {
		$text .= '<h3>The current dataset contains no images.</h3>';
	}

	return $text;
}

1;
