# OME/Tasks/ImageImport.pm

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
# Written by:    Brian S. Hughes <bshughes@mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Tasks::ImageImport;

=head1 NAME

OME::Tasks::ImageImport - drives the importation of proprietary image formats
into OME

=head1 SYNOPSIS

	use OME::Tasks::ImageImport;
        my $importer = new OME::Tasks::ImageImport;
        $importer->importImages(@files);

=head1 DESCRIPTION

    This module drives the ImageImporter to import the supplied list of files.
    After importation into OME, this module associates the images with the
    active dataset, and runs the import analysis chain on the images.

=cut


use OME::Session;
use OME::Dataset;
use OME::Image;
use OME::Project;
use OME::ImportEngine::ImportEngine;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{session} = shift;

    bless $self, $class;
    return $self;
}


sub importImages {
    $self = shift;
    @files = @_;
    my $session = $self->{session};
    my $project = $session->project();
    my $dataset = $session->dataset();

    # TODO if $dataset does not exist, throw an error

    my $importer = OME::ImportEngine::ImportEngine->new((session => $session,
						  AllowDuplicates => 1));
    my $image_ref = $importer->importFiles(\@files);

    # Associate the images with the user specified dataset
    my $dataset = $session->dataset();

    my $dsMgr = new OME::Tasks::DatasetManager;
    $dsMgr->addImages($image_ref);

    # Run the import analysis chain on the dataset
    my $importer_chain = $session->Configuration()->import_chain();
    OME::Analysis::Engine->executeChain($importer_chain, $dataset, {});

    $session->commitTransaction();


}

1;
