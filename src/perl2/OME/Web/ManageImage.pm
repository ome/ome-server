# OME/Web/ImageManager.pm

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


package OME::Web::ManageImage;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Tasks::ImageManager;
use OME::Web::ImageTable;

use base qw{ OME::Web };

sub getPageTitle {
	return "Open Microscopy Environment - Image Manager";
}

{
	my $menu_text = "Images";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session=$self->Session();
	my $factory=$session->Factory();
	my $imageManager=new OME::Tasks::ImageManager($session);

	my $body .= $cgi->p({-class => 'ome_title'}, 'My Images');

	# Images selected
	my @selected = $cgi->param('selected');

	# Dataset relations selected
	my @rel_selected = $cgi->param('rel_selected');

	# Action "clicked"
	my $action = $cgi->param('action');

	if ($action eq 'Remove from Dataset') {
		# Action
		my $to_remove = {};

		foreach (@rel_selected) {  # Slightly arcane but it works
			my ($image, $dataset) = split(/,/, $_);
			push(@{$to_remove->{$image}}, $dataset);
		}

		# Make sure we're not operating on a locked dataset (values() operates on the actual hash)
		foreach my $datasets (values(%$to_remove)) {
			my $c = 0;
			foreach my $dataset_id (@$datasets) {
				my $dataset = $factory->loadObject("OME::Dataset", $dataset_id);
				if ($dataset->locked()) {
					delete(@$datasets[$c]);
					$body .= $cgi->p({class => 'ome_error'},
						"WARNING: Images not being removed from locked dataset ", $dataset->name(), ".");
				}
				$c++;  # Keep track of the array_index
			}
		}

		# Cleanse our keys
		foreach (keys(%$to_remove)) { delete ($to_remove->{$_}) unless @{$to_remove->{$_}} }

		$imageManager->remove($to_remove);
		
		# Data
		while (my ($image_id, $dataset_ids) = each (%$to_remove)) {
			$body .= $cgi->p({-class => 'ome_info'}, "Removed image $image_id from dataset(s) @$dataset_ids.");
		}
	}  

	$body .= $self->printImages($imageManager);
	
	return ('HTML',$body);
}

#---------------------------
# PRIVATE METHODS
#---------------------------

sub printImages {
	my ($self, $i_manager) = @_;
	my $t_generator = new OME::Web::ImageTable;
	my $cgi = $self->CGI();;
	my $factory = $self->Session()->Factory();
	my $d_name;
	$d_name = $self->Session()->dataset()->name() if $self->Session()->dataset();

	# Gen our images table
	my $html = $t_generator->getTable( {
			options_row => ["Add to '$d_name'", 'Remove from Dataset'],
			select_column => 1,
			relations => 1,
		},
		$i_manager->getUserImages()
	);

	return $html;
}


1;
