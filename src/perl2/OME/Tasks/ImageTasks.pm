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
use OME::ImportExport::Importer;
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


=head2 importFiles($repository, \%options, @filenames)
or importFiles(\%options, @filenames)
or importFiles(@filenames)

currently recognized options are {AllowDuplicates => 0|1}

Imports the selected files into OME. 
Returns 

=cut
sub importFiles {
	my ($param1, $param2, @filenames) = @_;
	my $options;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $repository = $session->findRepository(); # make sure there is one, and its activated.

	if( ref( $param1 ) eq 'HASH' ) {
		unshift( @filenames, $param2);
		$options = $param1;
	} elsif( not ref($param1) ) {
		unshift( @filenames, $param2) if defined $param2; # don't bother adding an undef
		unshift( @filenames, $param1) if defined $param1; # don't bother adding an undef
		$options = {};
	}

	my @files;
	push( @files, OME::Image::Server::File->upload($_) )
		foreach ( @filenames );
	# FIXME: split @files into two groups: xml files & proprietary

	$options->{AllowDuplicates} = 1;
	
	my $chain = $factory->findObject('OME::AnalysisChain', name => 'Image server stats');

	my $importer = OME::ImportEngine::ImportEngine->new(%$options);
	my ($dataset,$global_mex) = $importer->startImport();
	my $image_list = $importer->importFiles( \@files );
	$importer->finishImport();
	
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
    return $image_list;
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
