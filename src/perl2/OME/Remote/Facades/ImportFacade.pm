# OME/Remote/Facades/ImportFacade.pm

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
# Written by:  Ilya Goldberg <igg@nih.gov>
# Originaly by Douglas Creager <dcreager@alum.mit.edu>
#                
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::ImportFacade;
use OME;
our $VERSION = $OME::VERSION;

use POSIX;
use OME::SessionManager;
use OME::Session;
use OME::ImportEngine::ImportEngine;
use OME::Image::Server::File;
use OME::Tasks::PixelsManager;
use OME::Tasks::ImportManager;
use OME::Tasks::ImageTasks;
use OME::Analysis::Engine;
use OME::Fork;

=head1 NAME

OME::Remote::Facades::ImportFacade - Implementation of remote facade methods
for image import

=head2 getDefaultRepository

my $repository = getDefaultRepository();

Returns a hash reference of the following form:
  id             => The Repository ID
  ImageServerURL => The base URL of the OME Image Server (OMEIS)

=cut


sub getDefaultRepository {
	my $proto = shift;
	my $repository = OME::Session->instance()->findRemoteRepository();
	return ({
			'id' => $repository->id(),
			'ImageServerURL' => $repository->ImageServerURL()
	});
}



=head2 importFiles, startImport

  my $fileIDs = importFiles($repositoryID,$fileIDs,$datasetID);
  my $fileIDs = importFiles($repositoryID,$fileIDs);

  my $taskID = startImport($repositoryID,$fileIDs,$datasetID);
  my $taskID = startImport($repositoryID,$fileIDs);

importFiles and startImport accept a repository ID returned by getDefaultRepository,
a reference to an array of OMEIS FileIDs returned by UploadFile calls to OMEIS,
and an optional Dataset ID to put the images in (or add images to).

If A Dataset is not specified, one will be created automatically by OME.

importFiles returns a reference to an array of Image IDs resulting from the import.
This method will block until all images are imported.

startImport returns a task ID (OME::Task class), which can be used to track import progress.

=cut

sub importFiles {
	my ($dataset,$files) = _makeObjects (@_);

	my $images = OME::Tasks::ImageTasks::importImageServerFiles ($dataset, $files);

	# Make an array of Image IDs
	my $imageIDs;
	foreach (@$images) {
		push (@$imageIDs,$_->id());
	}
	return $imageIDs;
}

sub startImport {
	my ($dataset,$files) = _makeObjects (@_);

	my $task = OME::Tasks::ImageTasks::forkedImportImageServerFiles ($dataset, $files);

	return $task->id();
}

sub _makeObjects {
	my ($proto,$repositoryID,$fileIDs,$datasetID) = @_;
	my $factory = OME::Session->instance()->Factory();
	my $repository = $factory->findObject(
		'@Repository', id => $repositoryID
	);
	die "Could not find repository with ID=$repositoryID"
		unless $repository;

	my $dataset;
	if (defined $datasetID) {
		$dataset = $factory->findObject(
			"OME::Dataset", id => $datasetID
		);
	}

	my $files;
	foreach (@$fileIDs) {
		push ( @$files,OME::Image::Server::File->new ($_,$repository) );
	}
	return undef unless scalar @$fileIDs;
	return ($dataset,$files);
}
1;

=head1 AUTHORS

Ilya Goldberg (igg@nih.gov)

Originaly by Douglas Creager <dcreager@alum.mit.edu>


=cut
