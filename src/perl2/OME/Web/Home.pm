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
use CGI;
use Carp;
use Data::Dumper;
use UNIVERSAL::require;

# OME Modules
use OME;
use OME::Web::Table;
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

=head2 __getQuickViewFooter

Builds a table row/table definition pair for inclusion in the quick view.

=cut

sub __getQuickViewFooter {
	my $self = shift;
	my $q = $self->CGI();

	my @footer_elements = (
		['New Project', $self->pageURL('OME::Web::MakeNewProject')],
		['New Dataset', $self->pageURL('OME::Web::MakeNewDataset')],
		['Import Files', $self->pageURL('OME::Web::ImportFiles')],
	);

	my ($footer_data, $prev);

	foreach my $element (@footer_elements) {
		$footer_data .= ' | ' if $prev;
		$footer_data .= $q->a( {
				class => 'ome_quiet',
				href => $element->[1]
			}, $element->[0]);
		
		$prev = 1;  # Track if this is the first element
	}

	return $q->Tr(
		$q->td( {
				colspan => 3,
				align => 'right',
				class => 'ome_menu_td',
			}, $footer_data)
	);
}

=head2 __getQuickViewImageData

Composes the header and content for the thumbs/image area of the quick view. Each element of content is a thumbnail for an image in the dataset, limited by the MAX_PREVIEW_THUMBS constant.

=cut

sub __getQuickViewImageData {
	my ($self, $d) = @_;
	my $q = $self->CGI();

	# Build image header/content
	my ($i_header, $i_content);
	
	# Managers
	my $i_manager = $self->{'__i_manager'};
	my $d_manager = $self->{'__d_manager'};

	# Count of images in the dataset
	my $d_icount = $d_manager->getImageCount($d);
	
	if ($d) {
		# Header
		$i_header  = $q->a( {
				href => $self->pageURL('OME::Web::DatasetManagement') . '&DatasetID=' . $d->id(),
				class => 'ome_quiet',
			}, $d->name() . ' Preview ');
		$i_header .= $q->span({class => 'ome_quiet'}, "[$d_icount image(s)]");

		my $i = 0;

		# Content
		if ($d_icount == 0) {
			$i_content .= 'No images in this dataset. Click <i>\'Import Files\'</i> below to import some.';
		} else {
			foreach ($d->images()) {
				$i_content .= $q->a( {
						href => 'javascript:openPopUpImage(' . $_->id() . ');',
						alt => 'N/A',
					}, $q->img({src => $i_manager->getThumbURL($_), border => 1}));
				$i_content .= '&nbsp';  # Spacing
				++$i;	
				last if ($i == MAX_PREVIEW_THUMBS);
			}
		}
	} else {
		$i_header .= $q->span({style => 'font-weight: bold;'}, 'No Dataset');
		$i_content .= 'No dataset is available for preview. Click <i>\'New Dataset\'</i> below to create one.';
	}
	
	return ($i_header, $i_content);
}

=head2 __getQuickViewProjectData

Composes the header and content for the project area of the quick view.

=cut

sub __getQuickViewProjectData {
	my ($self, $p) = @_;
	my $q = $self->CGI();

	# Managers
	my $p_manager = $self->{'__p_manager'};

	# Count of projects owned by the Sesssion's user in teh entire DB
	my $p_count  = $p_manager->getUserProjectCount();

	# Build projects header/content
	my ($p_header, $p_content);

	# Project ID for the Session's project
	my $p_id = $p->id() if $p;

	if ($p_count > 0) {
			# Header
		$p_header .= $q->a( {
				href => $self->pageURL('OME::Web::ProjectTable'),
				class => 'ome_quiet',
			}, 'Project Preview ');
		$p_header .= $q->span({class => 'ome_quiet'}, "[$p_count project(s)]");

			# Content
		foreach ($p_manager->getUserProjectsLimit(MAX_PREVIEW_PROJECTS)) {
			my $a_options = {
				href => $self->pageURL('OME::Web::ProjectManagement') . '&ProjectID=' . $_->id(),
				class => 'ome_quiet',
			};
	
			# Local count of the datasets for *THIS* project
			my $local_p_dcount = $p_manager->getDatasetCount($_);

			# Active/most recent objects are highlighted
			if ($_->id == $p_id) { $a_options->{'bgcolor'} = 'grey'; }

			$p_content .= $q->a($a_options, $_->name()) .
			              $q->span({class => 'ome_quiet'}, " [$local_p_dcount dataset(s)]") .
						  $q->br();
		}
	} else {
		$p_header .= $q->span({style => 'font-weight: bold;'}, 'No Projects');
		$p_content .= 'The database currently contains no projects. Click <i>\'New Project\'</i> below to create one.';
	}

	return ($p_header, $p_content);
}

=head2 __getQuickViewDatasetData

Composes the header and content for the dataset area of the quick view.

=cut

sub __getQuickViewDatasetData {
	my ($self, $p) = @_;
	my $q = $self->CGI();

	# Managers
	my $p_manager = $self->{'__p_manager'};
	my $d_manager = $self->{'__d_manager'};

	# Count of datasets in the "most recent" project
	my $p_dcount = $p_manager->getDatasetCount($p);

	# Build datasets in project header/content
	my ($d_header, $d_content);

	if ($p) {
		# Header
		$d_header .= $q->a( {
				href => $self->pageURL('OME::Web::ProjectManagement') . '&ProjectID=' . $p->id(),
				class => 'ome_quiet',
			}, 'Datasets in ' . $p->name());
		$d_header .= $q->span({class => 'ome_quiet'}, " [$p_dcount dataset(s)]");

		my $i = 0;

		# Content
		foreach ($p->datasets()) {
			# Local count of the images for *THIS* dataset
			my $local_d_icount = $d_manager->getImageCount($_);

			$d_content .= $q->a( {
					href => $self->pageURL('OME::Web::DatasetManagement') . '&DatasetID=' . $_->id(),
					class => 'ome_quiet',
				}, $_->name());

			$d_content .= $q->span({class => 'ome_quiet'}, " [$local_d_icount image(s)]");
			$d_content .= $q->br();

			++$i;
			last if ($i == MAX_PREVIEW_DATASETS);
		}
	} else {
		$d_header .= $q->span({style => 'font-weight: bold;'}, 'No Project');
		$d_content .= 'No project is available for preview. Click <i>\'New Project\'</i> below to create one.';
	}

	return ($d_header, $d_content);
}

=head2 __getQuickView

Assembles image, project and dataset previews into a common "quick view" table.

=cut

sub __getQuickView {
	my $self = shift;
	my $q = $self->CGI();
	my $session = $self->Session();

	# Managers
	my $p_manager = $self->{'__p_manager'} = new OME::Tasks::ProjectManager;
	my $d_manager = $self->{'__d_manager'} = new OME::Tasks::DatasetManager;
	my $i_manager = $self->{'__i_manager'} = new OME::Tasks::ImageManager;

	# Project, dataset and counts we'll be using for the quick view
	my $p = $session->project();
	my $d = $session->dataset();

	# Build image header/content
	my ($i_header, $i_content) = $self->__getQuickViewImageData($d);
	
	# Build projects header/content
	my ($p_header, $p_content) = $self->__getQuickViewProjectData($p);

	# Build datasets in project header/content
	my ($d_header, $d_content) = $self->__getQuickViewDatasetData($p);

	my $quickview = $q->table( {
			cellspacing => 0,
			cellpadding => 3,
			width => '100%'
		}, $q->Tr( [
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 0px;',
					width => '33%',
					align => 'center',
				}, $i_header) .
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 2px;',
					width => '33%',
					align => 'center',
				}, $p_header) .
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 2px;',
					width => '33%',
					align => 'center',
				}, $d_header),
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 0px;',
					width => '33%',
					valign => 'top',
				}, $i_content) .
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 2px;',
					width => '33%',
					valign => 'top',
					align => 'right',
				}, $p_content) .
			$q->td( {
					style => 'border-style: solid; border-width: 0px 0px 2px 2px;',
					width => '33%',
					valign => 'top',
					align => 'right',
				}, $d_content),
			]), $self->__getQuickViewFooter(),
	);

	return $quickview;
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
	my $q = $self->CGI();

	# The initial "quick view" of the experimenter's data
	my $body = $self->__getQuickView();

	# Home page content, to be extended!
	$body .= $q->p({class => 'ome_menu_title'}, 'Welcome to the Open Microscopy Environment!');
	$body .= $q->p('Most of your initial tasks with OME will start with this page; the <i>\'Home\'</i> page. From here you can create new projects and datasets as well as import images. For more sophisticated tasks, you can nativigate to various pages using the menu on the left or using the links given to you in the previews above. If for some reason you get lost, you can always return to this <i>\'Home\'</i> page by clicking the OME logo in the top-left hand corner of your screen.');
	$body .= $q->hr();
	$body .= $q->p({class => 'ome_quiet', align => 'center'}, 'Copyright &copy 2004 the OME Project.');

	return ('HTML', $body);
}


1;
