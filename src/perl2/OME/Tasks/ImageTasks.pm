# OME/Tasks/ImageTasks.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Tasks::ImageTasks;

use OME::Session;
use OME::Dataset;
use OME::Image;
use OME::ImportExport::Importer;
use OME::Project;
use IO::File;
use Carp;


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


# removeWeirdCharacter(hash)
# --------------------------
# By weird, I mean the null character currently.  Ensures that the
# input from an image file won't trash the Postgres DBI driver (which
# a null character in the input string will do).

sub removeWeirdCharacters {
	my $hash = shift;
	my $anyRemoved = 0;

	foreach my $key (keys(%$hash)) {
		my $value = $hash->{$key};
		if (!ref($value)) {
			my $replaced = ($value =~ s/[\x00]//g);
			$hash->{$key} = $value;
			print STDERR "	 $key $replaced\n";
			$anyRemoved = $replaced if $replaced;
		}
	}

	return $anyRemoved;
}


# importFiles(session,project,filenames)
# --------------------------------------
# Imports the selected files into OME.	The session is used to
# interact with the database, and all of the images are assigned to
# the given project.

sub importFiles {
	my ($session,$dataset,$filenames, $switch) = @_;
	my $importer;
	my $fn_groups;
	my $status = "Failed import";

	return $status	unless
		(defined $session) &&
		(defined $dataset)	  &&
		(defined $filenames);

	$status = "";

	$importer = OME::ImportExport::Importer->new($filenames, $session);
	$fn_groups = $importer->{fn_groups};
	carp "No files to import"
	unless scalar @$fn_groups > 0;

	foreach $image_group_ref (@$fn_groups) {
		$importer->import_image($dataset, $image_group_ref, $switch);
		if ($importer->{did_import}) {
			$session->DBH()->commit();
		}
		else {
			$status = "Failed to import at least one image";
		}
	}

	# could test here - if either any or all imports failed,
	# don't write dataset record to db.
	$dataset->writeObject();


	return $status;


}


# findRepository(session,pixel array)
# -----------------------------------
# This function should determine, based on (currently) the size of the
# pixel array, which repository an image should be stored in.  For now
# we assume that there is only one repository, with an ID of 1.
# (Which, if the bootstrap script worked properly, will be the case.)

my $onlyRepository;

sub findRepository {
	return $onlyRepository if defined $onlyRepository;
	
	my ($session, $aref) = @_;
	$onlyRepository = $session->Factory()->loadObject("OME::Repository",1);
	return $onlyRepository if defined $onlyRepository;
	die "Cannot find repository #1.";
}


1;
