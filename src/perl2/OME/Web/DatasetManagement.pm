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
use OME::Web::ImageTable;


use Data::Dumper;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Dataset Management";
}

sub getPageBody {
	my $self = shift;

	my $cgi     = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $dataset = $session->dataset();

	my $datasetManager      = OME::Tasks::DatasetManager->new($session);
	my $imageManager        = OME::Tasks::ImageManager->new($session);
	$self->{datasetManager} = $datasetManager;
	$self->{htmlFormat}     = OME::Web::Helper::HTMLFormat->new();

	my $body .= $cgi->p({-class => 'ome_title', -align => 'center'}, $dataset->name() . ' Properties');

	my @selected = $cgi->param('selected');
	
	# determine action
	if( $cgi->param('save')) {
		my $datasetname = $cgi->param('name')
			or return (
				'HTML', 
				"<b>Please enter a name for your dataset.</b>".$self->print_form() 
			);
		if ($session->dataset()->name() ne $cgi->param('name')){
			my $ref=$datasetManager->nameExists($datasetname)
				or return (
					'HTML',
					"<b>This name is already used. Please enter a new name for your dataset.</b>".$self->print_form()
				);
		}
		$datasetManager->change($cgi->param('description'),$cgi->param('name'));
		$body .= "<script>top.title.location.href = top.title.location.href;</script>";
		$body .= "Save successful<br>";
	} elsif ($cgi->param('Add')) {
		if ($dataset->locked()) {
			# Data
			$body .= $cgi->p({class => 'ome_error'},
				"WARNING: Images not being removed from locked dataset.");
		} else {
			# Action
			my $image = $factory->findObject("OME::Image", name => $selected[0]);
			$datasetManager->addImages([$image->id()]);
			$body .= $cgi->p({-class => 'ome_info'},
				"Added image ", $image->name(), " to the dataset.");
		}
	} elsif ($cgi->param('Remove')) {
		# Action
		my $to_remove = {};
		foreach (@selected) { $to_remove->{$_} = [$dataset->id()] }

		print STDERR Dumper($to_remove);

		# Make sure we're not operating on a locked dataset
		if ($dataset->locked()) {
			$body .= $cgi->p({class => 'ome_error'},
				"WARNING: Images not being removed from locked dataset.");
		} else {
			$imageManager->remove($to_remove);
			$body .= $cgi->p({-class => 'ome_info'},
				"Removed image(s) @selected from dataset ", $dataset->name(), ".");
		}
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
	$text .= $htmlFormat->formChange("dataset",$session->dataset(),$user);
	$text .= $cgi->p({-class => 'ome_title', -align => 'center'}, 'Images');
	$text .= $self->makeImageListings($dataset);
	$text .= $cgi->endform;
	
	return $text;
}

sub makeImageListings {
	my ($self, $dataset) = @_;
	my $t_generator = new OME::Web::ImageTable;
	my $cgi = $self->CGI();;
	my $factory = $self->Session()->Factory();
	
	# Grab the ID of each of our images that's in the project
	my $in_project;
	foreach ($dataset->images()) { push (@$in_project, $_->id()) }

	# Gen our "Images in Project" table
	my $html = $t_generator->getTable( {
			options_row => ["Remove"],
			select_column => 1,
		},
		$dataset->images()
	);

	my @additional_images;

	# Only display the datasets that aren't in the project
	foreach my $image ($factory->findObjects("OME::Image")) {
		my $add_this_id = 1;
		foreach my $id_in_project (@$in_project) {
			if ($image->id() == $id_in_project) {
				$add_this_id = 0;
			};
		}
		push(@additional_images, $image->name()) if $add_this_id;
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
				 $cgi->Tr(
					 $cgi->startform(),
					 $cgi->td(
						 {-class => 'ome_action_td'},
						 '&nbsp',
						 $cgi->span("Add images: "),
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
