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
use OME::ImportExport::Exporter;
use OME::Analysis::Engine;
use OME::ImportEngine::ImportEngine;
use OME::Tasks::PixelsManager;
use OME::Tasks::ImageManager;
use OME::Image::Server::File;

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
	my ($dataset, $filenames, $options) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $repository = $session->findRepository(); # make sure there is one, and its activated.

	my @files;
    my $progress = 
    	OME::Tasks::NotificationManager->new ('Uploading files to omeis',scalar @$filenames);
	
	foreach ( @$filenames ) {
		push( @files, OME::Image::Server::File->upload($_) );
		$progress->step();
	}
	$progress->finish();
	
	my $image_list = OME::ImportEngine::ImportEngine->importFiles(%$options, \@files );
	
	if( scalar( @$image_list ) > 0 ) {
		$dataset = $factory->newObject("OME::Dataset",
			{
			 name => "Import Dataset",
			 description => "Images imported without a user specified dataset",
			 locked => 0,
			 owner_id => $session->experimenter_id(),
			})
			unless defined $dataset;

		# Add the new images to the dataset.
		foreach $image (@$image_list) {
			$factory->newObject("OME::Image::DatasetMap",
								{
								 image_id   => $image->id(),
								 dataset_id => $dataset->id(),
								});
		}
	
		my $chain = $session->Configuration()->import_chain();
		OME::Analysis::Engine->executeChain($chain,$dataset,{});

		logdbg "debug", "Successfully imported images:";
		logdbg "debug", "\t Image(".$_->id()."): ".$_->name()
			foreach (@$image_list);

		# save default display options to omeis as thumbnail settings.
		foreach my $image (@$image_list) {
			foreach my $pixels ($image->pixels()) {
				OME::Tasks::PixelsManager->saveThumb( $pixels );
			}
		}
		# save any newly created displayOptions.
		$session->commitTransaction();
	}
    
    return $image_list;
}


=head2 forkedImportFiles

	my $task = forkedImportFiles($dataset,\@filenames,\%options);

Performs the same operation as importFiles, but forks off a new
process first.  An OME::Task object is created to track the import's
progress.

=cut

sub forkedImportFiles {
	my ($dataset, $filenames, $options) = @_;

    my $task = OME::Tasks::NotificationManager->
      new('Importing images',3+scalar(@$filenames));

    my $importer = OME::ImportEngine::ImportEngine->new(%$options);
    my $session = OME::Session->instance();

    my $files_mex = $importer->startImport();
    my $session_key = $session->SessionKey();

    my $parent_pid = $$;
    my $pid = fork;

    if (!defined $pid) {
        die "Could not fork off process to perform the import";
    } elsif ($pid) {
        # Parent process

        OME::Tasks::ImportManager->forgetImport();
        return $task;
    } else {
        # Child process

        eval {
            POSIX::setsid() or die "Can't start a new session. $!";
            OME::Session->forgetInstance();
            OME::Tasks::NotificationManager->forget();

            my $session = OME::SessionManager->createSession($session_key);

            $task->step();
            $task->setMessage('Starting import');

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
                $task->setMessage('Successfully imported '.scalar(@$image_list).
                                  ' images');
            };

            logwarn "Could not close task - $@" if $@;
        }

        CORE::exit(0);
    }
}

# exportFiles(session,images)
# --------------------------------------
# Exports the selected images out of OME.  The session is used to
# interact with the database.


sub exportFiles {
	my ($i, $sz, $type);
	my $image_list;
	my ($session, $argref) = @_;

	return unless
		(defined $session) &&
		(defined $argref);

	$type = $$argref[0];
	$sz = scalar(@$argref);
	for ($i = 1; $i < $sz; $i++) {
	push @image_list, $$argref[$i];
	}

	# FIXME:
	# Need to determine how to locate repository for given image IDs\
	# when we go to more than 1 repository.
	my $repository = $session->findRepository();

	my $xporter = OME::ImportExport::Exporter->new($session, $type, \@image_list, $repository);

}



1;
