# OME/Web/Util/Dataset.pm

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
# Written by:   Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::Util::Dataset;

=pod

=head1 NAME

OME::Web::Util::Dataset - a front end for OME::Tasks::DatasetManager

=head1 DESCRIPTION

This package makes calls to DatasetManager and generates return
messages formatted in html

=head1 METHODS

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::DatasetManager;
use OME::Web;

use Log::Agent;
use base qw(OME::Web);

=head2 addImages

	my $message = $self->DatasetUtil()->addImages( $image_ids);

$image_ids is comma separated list of image ids

=cut

sub addImages {
	my ($self, $image_ids ) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $message;
	my (@these_images_are_already_in_dataset, @succesfully_added_to_dataset);
	
	return "<font color='red'>Cannot add images to dataset. It is locked.</font>"
		if $session->dataset()->locked();
	
	foreach my $image_id ( split( m',', $image_ids ) ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id )
			or die "Couldn't load image id=$image_id";
		my $res = OME::Tasks::DatasetManager->addToDataset($session->dataset(), $image);

		# output from addToDataset is semaphore for whether image is already in Dataset
		if ($res == 1) {
			push (@succesfully_added_to_dataset, $image);
		} else {
			push (@these_images_are_already_in_dataset, $image);
		}
	}
	
	$message .= "Successfully added ".
		$self->Renderer()->renderArray( \@succesfully_added_to_dataset, 'bare_ref_mass', { type => 'OME::Image' } ).".<br>"
		if (@succesfully_added_to_dataset);
	
	$message .= "<font color='red'>Cannot add images ".
		$self->Renderer()->renderArray( \@these_images_are_already_in_dataset, 'bare_ref_mass', { type => 'OME::Image' } ).
		" because they already belong to this dataset.</font><br>"
		if (@these_images_are_already_in_dataset);
		
	
	return $message;
}

=head2 removeImages

	my $message = $self->DatasetUtil()->removeImages( $image_ids);

$image_ids is comma separated list of image ids

=cut

sub removeImages {
	my ($self, $image_ids ) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $message;
	my (@these_images_are_already_in_dataset, @succesfully_added_to_dataset);
	
	# Return a useful message if dataset is locked.
	return "<font color='red'>Cannot remove images from dataset. It is locked.</font>"
		if $session->dataset()->locked();
	
	# load the images and remove them from the dataset
	my @image_list;
	foreach my $image_id ( split( m',', $image_ids ) ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id )
			or die "Couldn't load image id=$image_id";
		OME::Tasks::DatasetManager->deleteImageFromDataset($session->dataset(), $image);
		push( @image_list, $image )
	}
	
	$message .= "Successfully removed ".
		$self->Renderer()->renderArray( \@image_list, 'bare_ref_mass', { type => 'OME::Image' } ).".<br>";

	return $message;
}

=head1 Author

Tom Macura <tmacura@nih.gov>

=cut

1;
