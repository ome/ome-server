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
use OME::Tasks::DatasetManager;
use OME::Tasks::NotificationManager;

=head1 METHODS

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
	my $repository = OME::Session->instance()->findRepository();

	unless ($task) {
		$task = OME::Tasks::NotificationManager->
			new('Importing images',3+scalar(@$filenames))
				unless defined $task;
		
		$task->setPID($$);
		$task->step();
		$task->setMessage('Starting import');
	}

	$task->setPID($$);

	my %files;		

	eval {
		foreach my $filename (@$filenames) {
			my $omeis_file = OME::Image::Server::File->upload($filename,$repository)
				if -f $filename and -r $filename and -s $filename;
			$files{ $filename } = $omeis_file;
			$task->step();
			$task->setMessage("Uploaded $filename");
		}
	};
	
	if ($@) {
		my $error = $@;
		eval {
			$task->died($error);
		};
		logwarn "Could not close task - $@" if $@;
		die $error;
	}

	return ( importImageServerFiles ($dataset,\%files,$options,$task) );
}

=head2 importImageServerFiles

my $image_list = importImageServerFiles($dataset, \@files, \%options);

This method imports files which are already present in an image server
repository. The import analysis chain is executed and a reference to an array
of images is returned.

$dataset is optional. It is completely unnecessary for ome files that do not
contain images. When left unspecified, an Import Dataset will be automatically
created if images are returned by the ImportEngine.  If $dataset is
unspecified, replace it with undef.  %options is optional. currently recognized
options are {AllowDuplicates => 0|1}
	
=cut

sub importImageServerFiles {
	my ($dataset, $files, $options, $task) = @_;

	unless ($task) {
		$task = OME::Tasks::NotificationManager->
			new('Importing images',3+scalar(@$files))
				unless defined $task;
		
		$task->setPID($$);
		$task->step();
		$task->setMessage('Starting import');
	}

	$task->setPID($$);
    my $importer = OME::ImportEngine::ImportEngine->new(%$options);
    my $session = OME::Session->instance();
	my $datasetManager = OME::Tasks::DatasetManager->new($session);

    my $files_mex = $importer->startImport();

	eval {
            $task->step();
            $task->setMessage('Importing');
            my $image_list = $importer->importFiles($files);
            my $dup_image_list = $importer->getDuplicateImages();
            $importer->finishImport();

			my @images_for_the_dataset = ( @$image_list, @$dup_image_list );
			if( scalar( @images_for_the_dataset ) > 0 ) {
				if( not defined $dataset ) {
					my $timestamp = time;
					my $timestr = localtime $timestamp;
					
					$dataset = $datasetManager->newDataset("$timestr Import Dataset",
					"These images were imported on $timestr.\nThe dataset name and description were auto-generated because the user did not specify them at import time.")
					or die "Couldn't make a new dataset";
				}
	
				# Add the new images to the dataset.
				foreach $image (@images_for_the_dataset){
				
					OME::Tasks::DatasetManager->addToDataset ($dataset,$image)
				}
				$task->step();
				$task->setMessage('Executing import chain');
				my $chain = $session->Configuration()->import_chain();
				if (defined $chain) {
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
            die $error;
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
	return $importer->{_images};
}

=head2 forkedImportFiles

	$task = forkedImportFiles($dataset,\@filenames,\%options);

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
	
	return $task;
	
}

=head2 forkedImportImageServerFiles

	$task = forkedImportImageServerFiles($dataset,\@files,\%options);

Performs the same operation as importFiles, but defers the task
until later.

=cut

sub forkedImportImageServerFiles {
	my ($dataset, $files, $options) = @_;
    my $task = OME::Tasks::NotificationManager->
      new('Importing images',3+scalar(@$files));
	$task->setPID($$);
	$task->step();
	$task->setMessage('Starting import');

	OME::Fork->doLater( sub {
		OME::Tasks::ImageTasks::importImageServerFiles($dataset, $files,
		                                               $options, $task);
	});
	
	return $task;
}

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>
 
=cut

1;
