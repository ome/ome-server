# OME/Tasks/ImageTasks.pm

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


package OME::Tasks::ImageTasks;

use OME::Session;
use OME::Dataset;
use OME::Image;
use OME::Analysis::Engine;
use OME::ImportEngine::ImportEngine;
use OME::Tasks::PixelsManager;
use OME::Tasks::ImageManager;
use OME::Image::Server::File;

use OME::Fork;

use OME::Project;
use IO::File;
use Carp;
use Log::Agent;

use OME::Task;
use OME::Tasks::NotificationManager;

# addImagesToDataset(dataset, images)
# -----------------------------------
# Adds the given images to a dataset.  The images parameter can be
# specified either as a Class::DBI iterator or as a reference to an
# array of DBObjects.

sub __addOneImageToDataset ($$$) {
	my ($factory, $dataset, $image) = @_;

	eval {
	my $link = $factory->newObject("OME::Image::DatasetMap",
					   {image	=> $image,
					dataset => $dataset});
	}
	
	# This should be a better error check - right now we
	# assume that any error represents an attempt to create a
	# duplicate map entry, which we silently ignore.
}

sub addImagesToDataset ($$$) {
	my ($factory, $dataset, $images) = @_;

	if (ref($images) eq 'ARRAY') {
	# We have an array of image objects

		foreach my $image (@$images) {
		__addOneImageToDataset($factory,$dataset,$image);
	}
	} else {
	# We should have an iterator
	
	while (my $image = $images->next()) {
		__addOneImageToDataset($factory,$dataset,$image);
	}
	}

	$factory->dbi_commit();
}


=head2 importFiles

	my $image_list = importFiles($dataset, \@filenames, \%options);

images described by @filenames will be imported into $dataset
$dataset is optional. It is completely unnecessary for ome files that do
	not contain images. When left unspecified, an Import Dataset will be
	automatically created iff images are returned by the ImportEngine.
If $dataset is unspecified, replace it with undef.
%options is optional. currently recognized options are {AllowDuplicates => 0|1}

Imports the selected files into OME and executes the import analysis chain on them.
Returns a reference to an array of images imported.

=cut
sub importFiles {
	my ($dataset, $filenames, $options, $task) = @_;

	unless ($task) {
		$task = OME::Tasks::NotificationManager->
			new('Importing images',3+scalar(@$filenames))
				unless defined $task;
		
		$task->setPID($$);
		$task->step();
		$task->setMessage('Starting import');
	}

    my $importer = OME::ImportEngine::ImportEngine->new(%$options);
    my $session = OME::Session->instance();

    my $files_mex = $importer->startImport();

	eval {

            my @files;

            foreach my $filename (@$filenames) {
                push @files, OME::Image::Server::File->upload($filename);
                $task->step();
                $task->setMessage("Uploaded $filename");
            }

            $task->step();
            $task->setMessage('Importing');
            my $image_list = $importer->importFiles(\@files);
            $importer->finishImport();

			if( scalar( @$image_list ) > 0 ) {
				my $factory = $session->Factory();
				if( not defined $dataset ) {
					$dataset = $factory->
					  newObject("OME::Dataset",
								{
								 name => "Forked import Dummy Dataset",
								 description => "Images imported by Remote Importer",
								 locked => 0,
								 owner_id => $session->experimenter_id(),
								})
					or die "Couldn't make a new dataset";
				}
	
				# Add the new images to the dataset.
				foreach $image (@$image_list) {
					$factory->newObject("OME::Image::DatasetMap",
										{
										 image_id   => $image->id(),
										 dataset_id => $dataset->id(),
										});
				}
		
				$task->step();
				$task->setMessage('Executing import chain');
				my $chain = $session->Configuration()->import_chain();
				if (defined $chain) {
					$OME::Analysis::Engine::DEBUG = 0;
					OME::Analysis::Engine->executeChain($chain,$dataset,{});
				}
			} else {
				$task->step();
				$task->setMessage('No Images imported. Skipping execution of import chain');
			}
        };

        if ($@) {
            my $error = $@;
            eval {
                $task->died($error);
            };

            logwarn "Could not close task - $@" if $@;
        } else {
            eval {
                $task->finish();
                $task->setMessage('Imported '.$importer->nImages().' images '.
                	'from '.$importer->nImageFiles().' files. '.
                	$importer->nFiles().' scanned. '.
                	$importer->nUnknown().' unknown format, '.
                	$importer->nDups().' duplicates, '.
                	$importer->nError().' errors.'
                );
            };

            logwarn "Could not close task - $@" if $@;
        }
}


=head2 forkedImportFiles

	my $task = forkedImportFiles($dataset,\@filenames,\%options);

Performs the same operation as importFiles, but defers the task
until later.

=cut

sub forkedImportFiles {
	my ($dataset, $filenames, $options) = @_;
    my $task = OME::Tasks::NotificationManager->
      new('Importing images',3+scalar(@$filenames));
	$task->setPID($$);
	$task->step();
	$task->setMessage('Starting import');

	OME::Fork->doLater ( sub {
		OME::Tasks::ImageTasks::importFiles($dataset, $filenames, $options, $task);
	});
}

1;
