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
	my $importer = OME::ImportEngine::ImportEngine->new(%flags);
	my $images = $importer->importImages(\@filenames);

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
                [AllowDuplicates => 1]);

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

	my $images = $importer->importFiles($filenames);

Imports a list of image files.  Note that there is no implicit mapping
between filenames and images; in several image formats, an image is
split across several files.  The import classes for those formats will
correctly group the filenames by image, and import the grouped files
accordingly.

The $filenames parameter is given as an array reference to allow it to
be modified by the import engine.  Any files which are successfully
imported into some image will be removed from the list.  After the
call to C<importFiles> returns, none of the files left in the array
were recognized by any of the import formats.

The list of images imported is returned as an array reference.  If you
want these newly imported images to be added to a dataset for the
user, this must be done separately.

Note that if you are only going to make a single call to importFiles,
there is a shorter, alternative syntax that combines the calls to new
and importFiles into a single method call:

	my $importer = OME::ImportEngine::ImportEngine->new(%flags);
	$importer->importFiles($filenames);

would become

	OME::ImportEngine::ImportEngine->importFiles(%flags,$filenames);

The two syntaxes are identical in behavior.  All of the rules
governing the parameters to C<new> are also in effect in the
alternative syntax for C<importEngine> (i.e., C<session> is mandatory,
whereas C<AllowDuplicates> is optional).

=cut

sub importFiles {
    my $self = shift;
    my $filenames;

    # Allows this to be called as a class method.
    if (!ref($self)) {
        $filenames = pop;
        $self = $self->new(@_);
    } else {
        $filenames = shift;
    }

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    # Create the new dummy dataset.

    my $dataset = $factory->
      newObject("OME::Dataset",
                {
                 name => "ImportSet",
                 description => "Images imported by OME::ImportEngine",
                 locked => 'f',
                 owner_id => $session->User()->id(),
                });

    # Have the manager officially start the import process, and create
    # the MEX (module execution record) that represents the act of
    # importation, which creates the OME file.
    OME::Tasks::ImportManager->startImport();
    my $files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();
    $session->commitTransaction();

    # Find the formats that are known to the system.

    my $formats = $self->__getFormats();
    my %formats;
    my %groups;

    # Instantiate all of the format classes and retrieve the groups for
    # each.

    foreach my $format_class (@$formats) {
	last
	    unless (scalar(@$filenames) > 0);

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
            my $group = $format->getGroups($filenames);

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
                }
            } else {
                # TODO: Should this be an error if getSHA1 returns undef?
            }

            # This hasn't been imported yet, so slurp it in.
            my $image;
            eval {
                $image = $format->importGroup($group);
            };

            if ($@) {
                logwarn "Error $@ importing image: $format_class $group";
                $session->rollbackTransaction();
                next GROUP;
            }

            if (!defined $image) {
                logwarn "Undefined image: $format_class $group";
                $session->rollbackTransaction();
                next GROUP;
            }

            # Add the new image to the dummy dataset.
            $factory->newObject("OME::Image::DatasetMap",
                                {
                                 image_id   => $image->id(),
                                 dataset_id => $dataset->id(),
                                });

            my $image_mex = OME::Tasks::ImportManager->
              getImageImportMEX($image);
            $image_mex->status('FINISHED');
            $image_mex->storeObject();

            $session->commitTransaction();

            push @images, $image;
        }
    }

    #print STDERR "\n";

    # Wrap up things in the database.

    $files_mex->status('FINISHED');
    $files_mex->storeObject();

    OME::Tasks::ImportManager->finishImport();

    $session->commitTransaction();

    return \@images;
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
