# OME/ImportEngine/ImportEngine.pm

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


package OME::ImportEngine::ImportEngine;

=head1 NAME

OME::ImportEngine::ImportEngine - imports proprietary image formats
into OME

=head1 SYNOPSIS

	use OME::ImportEngine::ImportEngine;
	OME::ImportEngine::ImportEngine->importFiles(%flags, $dataset, \@filenames);

=head1 DESCRIPTION

The import engine is responsible for taking image files in external
formats and importing them into OME.  It ensures that a repository
file is created to store the pixels of the image, and creates
attributes to represent any metadata in the image file.  It uses a
delegation pattern, in which each external format is recognized and
imported by its own subclass of OME::ImportEngine::AbstractFormat.
The interface that external format importers must adhere to is
described in
L<OME::ImportEngine::AbstractFormat|OME::ImportEngine::AbstractFormat>.

Files are given to the import engine as instances of the OME::File interface.  Currently, there are two implementations of this interface -- 

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Class::Data::Inheritable;
use Log::Agent;
use OME::Image;
use OME::Dataset;
use OME::Tasks::ImportManager;
use UNIVERSAL::require;

# ---------------------
# The formats now come from the CONFIGURATION table.
#use base qw(Class::Data::Inheritable);
#__PACKAGE__->mk_classdata('DefaultFormats');
#__PACKAGE__->DefaultFormats(['OME::ImportEngine::MetamorphHTDFormat']);
# ---------------------

use fields qw(_flags);

=head1 METHODS

The following public methods are available.

=head2 new

	my $importer = OME::ImportEngine::ImportEngine->
	    new(session => $session,
                [AllowDuplicates => 1],
		[GroupCallback => \&groupCallback],
		[SliceCallback => \&sliceCallback]);

Creates a new instance of the import engine.  The session parameter is
mandatory; it specifies, among other things, which OME user is
performing the import.  If the AllowDuplicates parameter is present
and set to a true value, the import engine will allow previously
imported images to be re-imported, creating duplicates in the
database.  This should only be used for testing purposes.  With
AllowDuplicates missing or set to 0, the import engine will attempt to
detect previously imported images, and skip them.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    my %flags = @_;
    $self->{_flags} = \%flags;
    setupRemoteSliceCallback($self->{_flags});

    bless $self, $class;
    return $self;
}

sub __debug {
    print STDERR @_;
}

# Helper method which returns the format classes known to the system.
# Retrieves the list of classes from the CONFIGURATION table in the DB.

sub __getFormats {
    my $self = shift;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    # And find the import formats we can handle
    my @import_formats = split /\s/, $session->Configuration()->import_formats();

    return \@import_formats;
}

=head2 importFiles

	my $images = $importer->importFiles($files);

Imports a list of image files into a dataset.  Note that there is no
implicit mapping between filenames and images; in several image formats,
an image is split across several files.  The import classes for those
formats will correctly group the filenames by image, and import the
grouped files accordingly.

If the $dataset provided is locked, a fatal error will be thrown. The
dataset may already contain images as long as it is not locked.

The $files parameter is given as an array reference to allow it to
be modified by the import engine.  Any files which are successfully
imported into some image will be removed from the list.  After the
call to C<importFiles> returns, none of the files left in the array
were recognized by any of the import formats.

The list of images imported is returned as an array reference.

Note that if you are only going to make a single call to importFiles,
there is a shorter, alternative syntax that combines the calls to new
and importFiles into a single method call:

	my $importer = OME::ImportEngine::ImportEngine->new(%flags);
	my $files_mex = $importer->startImport( $dataset );
	my $images = $importer->importFiles( $filenames );
	$importer->finishImport();

would become

	OME::ImportEngine::ImportEngine->importFiles(%flags, $dataset, $filenames);

The two syntaxes are identical in behavior.  All of the rules
governing the parameters to C<new> are also in effect in the
alternative syntax for C<importEngine> (i.e., C<session> is mandatory,
whereas C<AllowDuplicates> is optional).

=cut

sub startImport {
    my ($self, $dataset) = @_;

    my $session = OME::Session->instance();

    # Have the manager officially start the import process, and create
    # the MEX (module execution record) that represents the act of
    # importation, which creates the OME file.
    OME::Tasks::ImportManager->startImport();
    my $files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();
    $session->commitTransaction();
    
    $self->{ _dataset } = $dataset;

    return $files_mex;
}

sub importFiles {
    my $self = shift;
    my ($dataset, $files);

    my $called_as_class = 0;

    # Allows this to be called as a class method.
    if (!ref($self)) {
        $files = pop;
        $dataset = pop;
        $self = $self->new(@_);
        $self->startImport( $dataset );
        $called_as_class = 1;
    } else {
        $files = shift;
        $dataset = $self->{_dataset};
    }

	# error check
	die "Cannot import into a locked dataset"
		if $dataset->locked();

    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

    my %files;
    foreach my $file (@$files) {
        $files{$file->getFilename()} = $file;
    }

    # Find the formats that are known to the system.

    my $formats = $self->__getFormats();
    my %formats;
    my %groups;

    # Instantiate all of the format classes and retrieve the groups for
    # each.

    foreach my $format_class (@$formats) {
	last
	    unless (scalar(keys %files) > 0);

        eval {
            # Verify that the format class has a well-formed name
            die "Malformed class name $format_class"
              unless $format_class =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;

            # Load the class into memory
            $format_class->require();

            # Create and save a new instance of the format class
            my $format = $format_class->new();
            $formats{$format_class} = $format;

            # Have the format class search for images in the list of
            # filenames.  Any files that correspond to importable
            # images will be removed from the list by the getGroups
            # method.
            my $group = $format->getGroups(\%files);

            # Make sure the getGroups method returned an array ref.
            die "${format_class}: getGroups must return an array ref"
              unless ref($group) eq 'ARRAY';

            $groups{$format_class} = $group;
        };

        if ($@) {
            # If there was an error, allow the other classes in the
            # list of formats to continue processing, but make sure
            # that we don't try to do anything with this class later.
            logwarn "Error getting groups via format $format_class: $@";

            delete $formats{$format_class};
            delete $groups{$format_class};
        }
    }

    # Loop through the formats once again, allowing each to import the
    # groups that it found.

    # You know, come to think of it, we don't really need this to be two
    # separate loops.  An interesting thought.  --DC

    my @images;

  FORMAT:
    foreach my $format_class (@$formats) {
        my $format = $formats{$format_class};
        my $groups = $groups{$format_class};

        # If there is no format class instance or list of groups for
        # this format class, go ahead and skip it.
        next FORMAT unless (defined $format) && (defined $groups);

      GROUP:
        foreach my $group (@$groups) {
            #print STDERR ".";

            # First check to see if this group has been imported yet.
            my $sha1;
            eval {
                $sha1 = $format->getSHA1($group);
            };
            if ($@) {
                logwarn "Error $@ calculating SHA-1: $format_class $group";
                next GROUP;
            }

            if (defined $sha1) {
                my $old_file = $factory->
                  findAttribute("OriginalFile",
                                SHA1 => $sha1);

                if (defined $old_file) {
                    __debug("Image has already been imported.  ");
                    if ($self->{_flags}->{AllowDuplicates}) {
                        __debug("AllowDuplicates is on.\n");
                    } else {
                        __debug("Skipping...\n");
                        next GROUP;
                    }
                } else {
                    # TODO: This should likely be a database corruption error
                    # or could it be what happens if an old file gets archived?
                }
            } else {
                # TODO: Should this be an error if getSHA1 returns undef?
            }

            # This hasn't been imported yet, so slurp it in.
            my ($image,$import_images);
            eval {
                $image = $format->importGroup($group, \&localSliceCallback);
            };

            if ($@) {
                logwarn "Error $@ importing image: $format_class $group";
                $session->rollbackTransaction();
                doGroupCallback($self->{_flags}, 0);
                next GROUP;
            }

            if (!defined $image) {
                logwarn "Undefined image: $format_class $group";
                $session->rollbackTransaction();
                doGroupCallback($self->{_flags}, 0);
                next GROUP;
            } elsif (ref ($image) eq 'ARRAY') {
            	$import_images = $image;
            } elsif (UNIVERSAL::isa($image,'OME::Image')) {
            	$import_images = [$image];
			} else {
				logdie ref ($self)."->importFiles $format_class returned a ".
					ref($image). " instead of an OME::Image";
			}
			
			foreach $image (@$import_images) {
				# Add the new image to the dataset.
				$factory->newObject("OME::Image::DatasetMap",
									{
									 image_id   => $image->id(),
									 dataset_id => $dataset->id(),
									});
	
				my $image_mex = OME::Tasks::ImportManager->
				  getImageImportMEX($image);
				$image_mex->status('FINISHED');
				$image_mex->storeObject();
				doGroupCallback($self->{_flags}, 1);
	
				$session->commitTransaction();
	            push @images, $image;
				logdbg "debug", ref ($self)."->importFiles: imported ".$image->name();
            }

        }
    }

    #print STDERR "\n";
	push( @{ $self->{_images} }, @images );
    $self->finishImport() if $called_as_class;

    return \@images;
}

sub finishImport {
    my $self = shift;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

    # Wrap up things in the database.
	$files_mex->status('FINISHED');
	$files_mex->storeObject();

    OME::Tasks::ImportManager->finishImport();

	# Set thumbnail and display options for each imported pixel set
	foreach my $image ( @{ $self->{_images} } ) {
		foreach my $pixels ( $image->pixels() ) {
			OME::Tasks::PixelsManager->saveThumb( $pixels );
		}
	}

    $session->commitTransaction();

    return;
}


=head2 doGroupCallback

         doGroupCallback(\%flags, $code)

Routine to call a passed callback routine with the results of
importing a group. If %flags hash has an entry for the key 'GroupCallback',
use that entry as a reference to the callback routine, passing it the
$code argument.

=cut

sub doGroupCallback {
    my $flags = shift;
    my $code = shift;
    if (my $grpCallback = $flags->{GroupCallback}) {
	$grpCallback->($code);
    }
}



=head2 localSliceCallback

         localSliceCallback()

Callback routine passed to individual importers. The importers, if they so
choose, will call this callback when they finish importing a single slice of
ann import image. This routine will then call the slice callback routine
passed in from this module's caller.

=cut


my $remoteSliceCallback;

sub localSliceCallback {
    if ($remoteSliceCallback) {
	$remoteSliceCallback->();
    }
}


sub setupRemoteSliceCallback {
    my $flags = shift;
    $remoteSliceCallback = $flags->{SliceCallback};
}


=head2 getFileRef

    getFileRef($group)

Returns the reference to the file carried in $group. If $group is
an array reference, then it will return the 1st array element, else
returns $group itself (which is expected to be a simple scalar).
=cut

sub getFileRef {
    my $group = shift;
    if (ref($group) eq "ARRAY") {
	return $$group[0];
    } else {
	return $group;
    }
}


=heaed2 replaceFileRef

    replaceFileRef($group, $file)

Replaces the 1st file ref of $group with $file. If $group is an
array reference, then the 1st array element will be replaced, and
the updated array reference returned. Else, $file is returned.

=cut

sub replaceFileRef {
    my $group = shift;
    my $file = shift;
    if (ref($group) eq "ARRAY") {
	$$group[0] = $file;
	return $group;
    } else {
	return $file;
    }
}


=head1 IMPLEMENTATION OF C<importFiles>

The pseudo-code algorithm of importFiles is as follows:

=over

=item 1.

Create a new instance of each of the format classes.

=item 2.

Call $format->getGroups($filenames) once for each format class, in
order.  Save the groups which are returned.  (A group is an opaque set
of files for a single image.  See OME::ImportEngine::AbstractFormat
for more information.)

=item 3.

For each group, call $format->getSHA1($group) to retrieve that groups
SHA-1 digest.  If an image has already been imported with that SHA-1,
the group is skipped.  Otherwise, $format->importGroup($group) is
called to perform the actual import of this file group.  Save each
image that is imported into a list.

=item 4.

Return a reference to the list of images that were imported
successfully.

=back

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::ImportEngine::AbstractFormat|OME::ImportEngine::AbstractFormat>

=cut

1;
