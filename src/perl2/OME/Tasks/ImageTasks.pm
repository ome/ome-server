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
use OME::ImportExport::Exporter;
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
	my ($session,$dataset,$filenames) = @_;
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

#!!!!!!!!!!!!!
# HACK
my $dbh = $session->DBH();
my $sth = $dbh->prepare( "SELECT IMAGE_ID FROM IMAGES" );
$sth->execute();
my %existingImages;
while( $ar = $sth->fetchrow_arrayref ) {
	$existingImages{$ar->[0]} = 1;
}
# END_HACK
#!!!!!!!!!!!!!

	foreach $image_group_ref (@$fn_groups) {
		$importer->import_image($dataset, $image_group_ref);
		if ($importer->{did_import}) {
			$session->DBH()->commit();
		}
		else {
			$status = "Failed to import at least one image";
		}
	}

###############################################################################
#  !!!!!!!!!           HACK            !!!!!!!!!
#
# PURPOSE: fill out XYZ_IMAGE_INFO table
#
$dbh = $session->DBH();
$sth = $dbh->prepare( "SELECT IMAGE_ID FROM IMAGES" );
$sth->execute();
my @newImages;
while( $ar = $sth->fetchrow_arrayref ) {
	push(@newImages, $ar->[0])
		unless( exists $existingImages{$ar->[0]} );
}

# make appropriate entries so DB won't complain about connections
my $factory = $session->Factory();
my $program = $factory->findObject("OME::Program", program_name=>'dev/null');
if( not defined $program) {
	$program = $factory->newObject( "OME::Program",
		{program_name     => '/dev/null',
		category         => 'hack',
		module_type      => 'hack',
		location         => '/dev/null'}
	) or die "could not make OME::Program object as part of hack\n";
	$program->writeObject();
}
my $attr = $factory->findObject( "OME::AttributeType", name => 'hack' );
if( not defined $attr ) {
	$attr = $factory->newObject( "OME::AttributeType",
{		name        => 'hack',
		granularity => 'I',
	}) or die "could not make OME::AttributeType object as part of hack\n";		
	$attr->writeObject();
}
my $formalOutput = $factory->findObject( "OME::Program::FormalOutput", program_id => $program->id() );
if( not defined $formalOutput) {
	$formalOutput = $factory->newObject( "OME::Program::FormalOutput",
{		name               => 'hack',
		program_id         => $program,
		attribute_type_id  => $attr,
	}) or die "could not make OME::Program::FormalOutput object as part of hack\n";
	$formalOutput->writeObject();
}
my $analysis = $factory->findObject( "OME::Analysis", program_id => $program->id() );
if( not defined $analysis) {
	$analysis = $factory->newObject( "OME::Analysis",
{		program_id => $program,
		dependence => 'I',
		dataset_id => 1
	}) or die "could not make OME::Analysis object as part of hack";
	$analysis->writeObject();
}
my $actual_output = $factory->findObject( "OME::Analysis::ActualOutput", ANALYSIS_ID => $analysis->id() );
if( not defined $actual_output) {
	$actual_output = $factory->newObject( "OME::Analysis::ActualOutput",
{		analysis_id => $analysis,
		formal_output_id => $formalOutput
	}) or die "could not make OME::Analysis::ActualOutput object as part of hack";
	$actual_output->writeObject();
}

foreach my $imageID(@newImages) {
	my $cmdBase = "/OME/bin/OME_Image_XYZ_stats ";
	my $image = $factory->loadObject( "OME::Image", $imageID );
    my $dims = $image->Dimensions();
    my $dimString = "Dims=".$dims->size_x().",".$dims->size_y().
        ",".$dims->size_z().",".$dims->num_waves().",".$dims->num_times().
        ",".$dims->bits_per_pixel()/8;
	my $cmd = $cmdBase .' Path=/OME/repository/' . $image->path() . ' '.$dimString;
	my $out = `$cmd`
		or die "could not open\n$cmd\n";
#	open $out, $cmd
#		or die "could not open\n$cmd\n";
	$out =~ s/^.*?\n//;
	while( $out =~ s/^(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+\.?\d*|\.\d+)\t(\d+\.?\d*|\.\d+)\t(\d+\.?\d*|\.\d+)\t(\d+\.?\d*|\.\d+)\t(\d+\.?\d*|\.\d+)\t(\d+\.?\d*|\.\d+)\n// ) {
		$sth = $dbh->prepare( "INSERT INTO xyz_image_info 
			(actual_output_id , image_id , wavenumber , timepoint , min , max , mean , geomean , sigma , centroid_x , centroid_y , centroid_z , the_w , the_t )
			values ( ".$actual_output->id().", ".$image->id().", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 )" )
			or die "could not prepare statement to write into xyz_image_info";
		$sth->execute();
	}
#	close $out;
$session->DBH()->commit();	
}	

#
# END_HACK
#
###############################################################################

	# could test here - if either any or all imports failed,
	# don't write dataset record to db.
	$dataset->writeObject();


	return $status;


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

	# Need to determine how to locate repository for given image IDs\
	# when we go to more than 1 repository.
	my $repository = findRepository($session, 0);

	my $xporter = OME::ImportExport::Exporter->new($session, $type, \@image_list, $repository);

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
