# OME/Web/DatasetManagement.pm

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
# Written by:    Josiah <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DatasetManagement;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Validation;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Web::Helper::HTMLFormat;
use OME::Web::Helper::JScriptFormat;
use OME::Web::Table;

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
	$text .= $self->makeImageListings($dataset);
	$text .= $cgi->endform;
	
	return $text;
}

sub makeImageListings {
	my ($self, $dataset) = @_;
	my $t_generator = new OME::Web::Table;
	my $cgi = $self->CGI();;
	my $factory = $self->Session()->Factory();
	
	# Grab the ID of each of our images that's in the project
	my $in_project;
	foreach ($dataset->images()) { push (@$in_project, $_->id()) }

	print STDERR "**** Dataset contains @$in_project\n";
	
	# Gen our "Images in Project" table
	my $html = $t_generator->getTable( {
			type => 'images',
			filters => [ ["id", ['in', $in_project] ] ],
			options_row => ["Remove"],
		}
	);

	my @additional_images;

	# Only display the datasets that aren't in the project
	foreach my $image ($factory->findObjects("OME::Image")) {
		my $add_this_id = 1;
		foreach my $id_in_project (@$in_project) {
			if ($dataset->id() == $id_in_project) {
				$add_this_id = 0;
			};
		}
		push(@additional_images, $dataset->name()) if $add_this_id;
	}

	# Add a null to the beginning
	unshift(@additional_images, 'None');

	# Add dataset table
	$html .= $cgi->p .
	         $cgi->table( {
					 -class => 'ome_table',
					 -align => 'center',
					 -cellspacing => 1,
					 -cellpadding => 4
				 },
				 $cgi->Tr({-bgcolor => '#006699'},
					 $cgi->startform(),
					 $cgi->td(
						 '&nbsp',
						 $cgi->span("Add dataset: "),
						 $cgi->popup_menu( {
								 -name => 'selected',
								 -values => [@additional_images],
								 -default => $additional_images[0]
							 }
						 ),
						 '&nbsp',
						 $cgi->submit({-name => 'Add', -value => 'Add'}),
						 '&nbsp'
					 ),
					 $cgi->endform()
				 )
			 );


	return $html;
}

#sub makeImageListings{
#	my $self = shift;
#
#	my $session    = $self->Session();
#	my $htmlFormat = $self->{htmlFormat};
#	my @images     = $session->dataset()->images();
#
#	my $text;
#
#	if( scalar @images > 0 ) {
#		$text .= "<h3>The current dataset contains the image".(scalar @images == 1 ? '' : 's')." listed below.</h3>";
#		$text .= $htmlFormat->imageInDataset(\@images,1);
#	} else {
#		$text .= '<h3>The current dataset contains no images.</h3>';
#	}
#
#	return $text;
#}

1;
