# OME/Web/Home.pm
# The initial web interface page. 

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
# Written by:    Chris Allan <callan@blackcat.ca>   03/2004
#
#-------------------------------------------------------------------------------


package OME::Web::Home;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);

use Carp;
use Data::Dumper;
use UNIVERSAL::require;
use HTML::Template;

# OME Modules
use OME;
use OME::Tasks::ProjectManager;
use OME::Tasks::DatasetManager;
use OME::Tasks::ImageManager;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

use constant QUICK_VIEW_WIDTH     => 3;

use constant MAX_PREVIEW_THUMBS   => 10;
use constant MAX_PREVIEW_PROJECTS => 7;
use constant MAX_PREVIEW_DATASETS => 7;

#*********
#********* PRIVATE METHODS
#*********

=head1 PRIVATE METHODS

=head2 __getQuickViewImageData

Composes the header and content for the thumbs/image area of the quick view. Each element of content is a thumbnail for an image in the dataset, limited by the MAX_PREVIEW_THUMBS constant.

=cut

sub __getQuickViewImageData {
	my ($self, $d) = @_;
	my $q = $self->CGI();

	# Build image header/content
	my ($i_header, $i_content);

	if ($d) {
		# Count of images in the dataset
		my $d_icount = $d->count_images();
	
		# Header
		$i_header  = $q->a( {
				href => $self->getObjDetailURL( $d ),
				class => 'ome_quiet',
				}, 
		$d->name() . ' Preview ');
		$i_header .= $q->span({class => 'ome_quiet'}, "[$d_icount image(s)]");

		# Content
		$i_content = $self->Renderer()->renderArray( 
			[ $d, 'images' ], 'bare_ref_mass', 
			{ paging_limit  => MAX_PREVIEW_THUMBS, 
			  type          => 'OME::Image', 
			  more_info_url => $self->getObjDetailURL( $d ) 
			}
		);
	} else {
		$i_header .= $q->span({style => 'font-weight: bold;'}, 'No Dataset');
		$i_content .= $q->span({class => 'ome_quiet'}, 'No dataset is available for preview. Click <i>\'New Dataset\'</i> below to create one.');
	}
	
	return ($i_header, $i_content);
}

=head2 __getQuickViewProjectData

Composes the header and content for the project area of the quick view.

=cut

sub __getQuickViewProjectData {
	my ($self, $p) = @_;
	my $q = $self->CGI();

	# Count of projects owned by the Sesssion's user in teh entire DB
	my $p_count  = OME::Tasks::ProjectManager->getUserProjectCount();

	# Build projects header/content
	my ($p_header, $p_content);

	# Project ID for the Session's project
	my $p_id = $p->id() if $p;

	if ($p_count > 0) {
			# Header
		$p_header .= $q->a( {
				href => $self->getSearchURL( 'OME::Project' ),
				class => 'ome_quiet',
			}, 'Project Preview ');
		$p_header .= $q->span({class => 'ome_quiet'}, "[$p_count project(s)]");

			# Content
		foreach (OME::Tasks::ProjectManager->getUserProjectsLimit(MAX_PREVIEW_PROJECTS)) {
			my $a_options = {
				href => $self->getObjDetailURL( $_ ),
				class => 'ome_quiet',
			};
	
			# Local count of the datasets for *THIS* project
			my $local_p_dcount = $_->count_datasets();

			# Active/most recent objects are highlighted
			if ($_->id == $p_id) { $a_options->{'bgcolor'} = 'grey'; }

			$p_content .= $q->a($a_options, $_->name()) .
			              $q->span({class => 'ome_quiet'}, " [$local_p_dcount dataset(s)]") .
						  $q->br();
		}
	} else {
		$p_header .= $q->span({style => 'font-weight: bold;'}, 'No Projects');
		$p_content .= $q->span({class => 'ome_quiet'}, 'The database currently contains no projects. Click <i>\'New Project\'</i> below to create one.');
	}

	return ($p_header, $p_content);
}

=head2 __getQuickViewDatasetData

Composes the header and content for the dataset area of the quick view.

=cut

sub __getQuickViewDatasetData {
	my ($self, $p) = @_;
	my $q = $self->CGI();

	# Build datasets in project header/content
	my ($d_header, $d_content);

	if ($p) {
		# Count of datasets in the "most recent" project
		my $p_dcount = $p->count_datasets();
	
		# Header
		$d_header .= $q->a( {
				href => $self->getSearchAccessorURL( $p, 'datasets' ),
				class => 'ome_quiet',
			}, 'Datasets in ' . $p->name());
		$d_header .= $q->span({class => 'ome_quiet'}, " [$p_dcount dataset(s)]");

		my $i = 0;

		# Content
		foreach ($p->datasets()) {
			# Local count of the images for *THIS* dataset
			my $local_d_icount = $_->count_images();

			$d_content .= $q->a( {
					href => $self->getObjDetailURL( $_ ),
					class => 'ome_quiet',
				}, $_->name());

			$d_content .= $q->span({class => 'ome_quiet'}, " [$local_d_icount image(s)]");
			$d_content .= $q->br();

			++$i;
			last if ($i == MAX_PREVIEW_DATASETS);
		}
	} else {
		$d_header .= $q->span({style => 'font-weight: bold;'}, 'No Project');
		$d_content .= $q->span({class => 'ome_quiet'}, 'No project is available for preview. Click <i>\'New Project\'</i> below to create one.');
	}

	return ($d_header, $d_content);
}


#*********
#********* PUBLIC METHODS
#*********

{
	my $menu_text = "Home";

	sub getMenuText {
		return $menu_text;
	}
}

sub getPageTitle {
    return "Open Microscopy Environment";
}

sub getPageBody {
	my $self = shift;
	my $session = $self->Session();
	my $q = $self->CGI();

	# Project, dataset and counts we'll be using for the quick view
	my $p = $session->project();
	my $d = $session->dataset();

	# Build image header/content
	my ($i_header, $i_content) = $self->__getQuickViewImageData($d);
	
	# Build projects header/content
	my ($p_header, $p_content) = $self->__getQuickViewProjectData($p);

	# Build datasets in project header/content
	my ($d_header, $d_content) = $self->__getQuickViewDatasetData($p);

	# Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( 
		filename => "Home.tmpl",
		path     => $tmpl_dir,
		case_sensitive => 1 );
	$tmpl->param(
		image_header   => $i_header,
		project_header => $p_header,
		dataset_header => $d_header,
		images         => $i_content,
		projects       => $p_content,
		datasets       => $d_content
	);

	return ('HTML', $tmpl->output());
}


1;
