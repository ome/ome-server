# OME/Remote/Facades/DatasetFacade.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::DatasetFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Dataset;

=head1 NAME

OME::Remote::Facades::DatasetFacade - implementation of remote facade
methods pertaining to dataset objects

=cut

sub addImagesToDataset {
    my ($proto,$dataset_id,$image_ids) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
    die "Dataset does not exist" unless defined $dataset;

    my @images;
    $image_ids = [$image_ids] unless ref($image_ids);
    foreach my $image_id (@$image_ids) {
        my $image = $factory->loadObject('OME::Image',$image_id);
        die "Image does not exist" unless defined $image;
        push @images, $image;
    }

    foreach my $image (@images) {
        $factory->maybeNewObject('OME::Image::DatasetMap',
                                 {
                                  dataset => $dataset,
                                  image => $image,
                                 });
    }

    return;
}

sub addImageToDatasets {
    my ($proto,$dataset_ids,$image_id) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my @datasets;
    $dataset_ids = [$dataset_ids] unless ref($dataset_ids);
    foreach my $dataset_id (@$dataset_ids) {
        my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
        die "Dataset does not exist" unless defined $dataset;
        push @datasets, $dataset;
    }

    my $image = $factory->loadObject('OME::Image',$image_id);
    die "Image does not exist" unless defined $image;

    foreach my $dataset (@datasets) {
        $factory->maybeNewObject('OME::Image::DatasetMap',
                                 {
                                  dataset => $dataset,
                                  image => $image,
                                 });
    }

    return;
}

sub removeImagesFromDataset {
    my ($proto,$dataset_id,$image_ids) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
    die "Dataset does not exist" unless defined $dataset;

    my @images;
    $image_ids = [$image_ids] unless ref($image_ids);
    foreach my $image_id (@$image_ids) {
        my $image = $factory->loadObject('OME::Image',$image_id);
        die "Image does not exist" unless defined $image;
        push @images, $image;
    }

    foreach my $image (@images) {
        my $link = $factory->
          findObject('OME::Image::DatasetMap',
                     {
                      dataset => $dataset,
                      image => $image,
                     });
        $link->deleteObject()
          if defined $link;
    }

    return;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
