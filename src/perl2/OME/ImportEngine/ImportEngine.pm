# OME/ImportEngine/ImportEngine.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
our $VERSION = 2.000_000;

use Class::Data::Inheritable;
use Log::Agent;
use OME::Image;
use OME::Dataset;

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
    my $session = $self->{_flags}->{session};
    my $factory = $session->Factory();
    my $config = $factory->loadObject("OME::Configuration", 1);

    # And find the import formats we can handle
    my @import_formats = split /\s/, $config->import_formats();

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

    my $session = $self->{_flags}->{session};
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

    # Find the importer module and chain based on the CONFIGURATION table.

    my $config = $session->Factory()->loadObject("OME::Configuration", 1);
    my $importer_module = $config->import_module();
    my $importer_chain = $config->import_chain();

    # Create a new module execution to represent what this importer is
    # about to do.

    my $module_execution = $factory->
      newObject("OME::ModuleExecution",
                {
                 dependence => 'I',
                 status     => 'RUNNING',
                 dataset_id => $dataset->id(),
                 module_id  => $importer_module->id(),
                });

    $session->commitTransaction();

    # Find the formats that are known to the system.

    my $formats = $self->__getFormats();
    my %formats;
    my %groups;

    # Instantiate all of the format classes and retrieve the groups for
    # each.

    foreach my $format_class (@$formats) {
        logcroak "Malformed class name $format_class"
          unless $format_class =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;
        eval "require $format_class";

        my $format = $format_class->new($session,$module_execution);
        $formats{$format_class} = $format;

	last
	    unless (scalar(@$filenames) > 0);
        $groups{$format_class} = $format->getGroups($filenames);
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
      GROUP:
        foreach my $group (@$groups) {
            #print STDERR ".";
            # First check to see if this group has been imported yet.
            my $sha1 = $format->getSHA1($group);
            my $old_file = $factory->
              findObject("OME::Image::ImageFilesXYZWT",
                         file_sha1 => $sha1);

            if (defined $old_file) {
                __debug("Image has already been imported.  ");
                if ($self->{_flags}->{AllowDuplicates}) {
                    __debug("AllowDuplicates is on.\n");
                } else {
                    __debug("Skipping...\n");
                    next GROUP;
                }
            }

            # This hasn't been imported yet, so slurp it in.
            my $image = $format->importGroup($group);

            if (!defined $image) {
                $session->rollbackTransaction();
                next GROUP;
            }

            # Add the new image to the dummy dataset.
            $factory->newObject("OME::Image::DatasetMap",
                                {
                                 image_id   => $image->id(),
                                 dataset_id => $dataset->id(),
                                });

            $session->commitTransaction();

            push @images, $image;
        }
    }

    #print STDERR "\n";

    # Wrap up things in the database.

    $module_execution->status('FINISHED');
    $module_execution->storeObject();

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
