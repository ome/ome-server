# OME/ImportEngine/AbstractFormat.pm

# Copyright (C) 2003 Open Microscopy Environment
#    Massachusetts Institute of Technology
#    National Institute of Health
#    University of Dundee
#
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::ImportEngine::AbstractFormat;

=head1 NAME

OME::ImportEngine::AbstractFormat - the superclass of all proprietary
image format importers

=head1 SYNOPSIS

	use OME::ImportEngine::AbstractFormat;
	my $format = OME::ImportEngine::AbstractFormat->
	                 new($module_execution);
	my $groups = $format->getGroups($filenames);
	my $sha1 = $format->getSHA1($group);
	my $image = $format->importGroup($group);

=head1 DESCRIPTION

The import engine delegates most of the work of importing an image to
subclasses of this class.  Each image format that the import engine
supports is defined as a separate subclass of AbstractFormat.

=cut

use strict;
our $VERSION = 2.000_000;

use fields qw(_session _module_execution);
use File::Basename;

=head1 CONTRACT

The following public methods must be available for a class to be used
by the import engine to import images.

=head2 new

	my $format = OME::ImportEngine::AbstractFormat->
	    new($session,$module_execution);

Creates a new instance of this format import class.  The module
execution parameter specifies an instance of the Importer analysis
module which will have been already created by the import engine.  Any
new attributes created by this importer should point to this module
execution, otherwise they will not be visible to any future analysis
chains.

This is the only contract method which has a non-abstract
implementation in AbstractFormat.  Any subclasses should be sure to
call $self->SUPER::new($module_execution) in their own constructors.

=cut

sub new {
    my ($proto,$session,$module_execution) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{_session} = $session;
    $self->{_module_execution} = $module_execution;
    my %paramHash;

    bless $self, $class;
    return $self;
}

=head2 getGroups

	my $groups = $format->getGroups($filenames);

Searches the list of filenames for files that this class can import.
It should perform any necessary grouping if this format stores a
single 5D image in multiple files.  It should not actually import the
image, it should just determine which files in the list it is able to
import.

Each group of files that would comprise a single OME image should be
grouped together.  Programmatically, this group can be represented by
any Perl scalar; the import engine will not do anything to it other
than use it as a parameter to the getSHA1 and importGroup methods.  At
the very least, the group should store the names of the files that
will be imported to form the image; the import engine does not track
this information for you.

Any files which can be imported should be removed from the $filenames
array.  (Since it's a reference, these changes will be visible to the
import engine and to the other format classes.)  A helper method
(C<__removeFilenames>) is provided to aid in this.  If the files are
not removed from the list, other format classes will have a chance to
import the file as well, creating duplicates.  This is almost never
the correct behavior.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub getGroups {
    my ($self,$filenames) = @_;
    die "AbstractFormat->getGroups is abstract";
}

=head2 getSHA1

	my $sha1 = $format->getSHA1($group);

The import engine will call this method to determine whether an image
has already been imported into OME.  If it has, the import engine will
skip this group (and therefore not call the importGroup method on it.)

This method should return a unique SHA-1 digest for the image group.
Usually, this is accomplished by calculating the SHA-1 of one of the
files in the image group.  However, this must be done against a file
which does not appear in any other image.  (Header files describing
filename schemes or plate arrangements would not qualify, as they
would be used by more than one image.)

A helper method (C<__getFileSHA1>) is provided to aid in the
calculation of the SHA-1 digest.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub getSHA1 {
    my ($self,$group) = @_;
    die "AbstractFormat->getSHA1 is abstract";
}

=head2 importGroup

	my $image = $format->importGroup($group);

Imports one of the groups returned by the getGroups method.  This
method will be caused once for each group that should be imported.
This method is responsible for creating a new OME::Image instance to
represent the image, for creating a new repository file (and
corresponding Pixels attribute) to store the imported pixels, and for
creating attributes to represent any other metadata in the external
image files.  Further, this method should create instances of
OME::Image::ImageFilesXYZWT for each file in the group.

Helper methods will be provided to aid in this as soon as I figure out
what they should be.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub importGroup {
    my ($self,$group) = @_;
    die "AbstractFormat->importGroup is abstract";
}

=head1 HELPER METHODS

The following methods are available to subclasses of AbstractFormat.
They are intended to factor out the tasks common to all formats.
B<NOTE:> In the following prototypes, the object is called $self, to
represent the fact that these methods are to be called from within
overrides of the above contract methods, and are not meant to be
called publicly.

=head2 ModuleExecution

	my $module_execution = $self->ModuleExecution();

Returns the module execution that was given as a parameter to the
C<new> method.  Note that this will only return a correct value if the
overridden C<new> method calls its superclass C<new> method.

=cut

sub ModuleExecution { return shift->{_module_execution}; }

=head2 Session

	my $session = $self->Session();

Returns the session that was given as a parameter to the C<new> method.
Note that this will only return a correct value if the overridden
C<new> method calls its superclass C<new> method.

=cut

sub Session { return shift->{_session}; }


=head2 newImage(initialAttributes)

Calls the session's Factory to create a new image object. Those attributes
that are known before the import are recorded in the new image.

=cut

sub newImage {
    my ($self, $session, $fn) = @_;

    my $config = $session->Factory()->loadObject("OME::Configuration", 1);
    my $guid = $config->mac_address;

    my $experimenter_id = $session->User()->id();
    my $user_group = $session->User()->Group();
    my $group_id = defined $user_group? $user_group->id(): undef;


    my $recordData = {'name' => $fn,
		      'image_guid' => $guid,
		      'description' => "",
		      'experimenter_id' => $experimenter_id,
		      'group_id' => $group_id,
		      'created' => "now",
		      'inserted' => "now",
              };

    my $image = $session->Factory->newObject("OME::Image", $recordData);
    if (!defined $image) {
	my $status = "Can\'t create new image";
    }

    return $image;

}


=head2 __getFileSHA1

	my $sha1 = $self->__getFileSHA1($filename);

Calculates the SHA-1 digest of the contents of the given file.  If the
file could not be read, or any other error occurred during the
calculation of the digest, this method returns C<undef>.

=cut

sub __getFileSHA1 {
    my ($self,$filename) = @_;

    my $cmd = "openssl sha1 $filename |";
    my $sh;
    my $sha1;

    open (STDOUT_PIPE,$cmd);
    chomp ($sh = <STDOUT_PIPE>);
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;
    close (STDOUT_PIPE);

    return $sha1;
}

=head2 __removeFilenames

	$self->__removeFilenames($filenames,$to_remove);

Takes in two array references of filenames.  After this method
returns, none of the members of the $to_remove list will exist in the
$filenames list.

=cut

sub __removeFilenames {
    my ($self,$filename_list,$to_remove) = @_;

    # turn to_remove into a hash for easier access
    my %to_remove;
    $to_remove{$_} = undef foreach @$to_remove;

    my $i = 0;
    while ($i < scalar(@$filename_list)) {
        if (exists $to_remove{$filename_list->[$i]}) {
            # This element should be removed
            splice(@$filename_list,$i,1);
        } else {
            # This element is okay
            $i++;
        }
    }

    return;
}


=head2 __nameOnly(full_file_name)

Takes in a fully qualified file name, and returns just the base filename.
No path components and no extension will be returned.

=cut

sub __nameOnly {
    shift;
    my $basenm = basename($_[0]);
    # remove filetype extension from filename (assumes '.' delimiter)
    $basenm =~ s/\..+?$//;
    return $basenm;
}



=head2 __createRepositoryFile

	my ($pixels_attribute,$pix_object) = $self->
	    __createRepositoryFile($image,$sizeX,$sizeY,$sizeZ,
	                           $sizeC,$sizeT,$bitsPerPixel);

Creates a new repository file for the given image, creates a Pixels
attribute to refer to it ($pixels_attribute), and creates an instance
of OME::Image::Pix to access the pixel data ($pix_object).  The
dimensions of the image must be specified before the repository file
is created.

The Pixels attribute will not be very useful to most import code,
except that any newly created attributes which require a reference to
a Pixels will point to it.  The import code will use the
OME::Image::Pix instance much more, as it provides the low-level
access to the repository file.  For reasons of efficiency, most import
code should use the SetPlane method of OME::Image::Pix to store the
pixels in the repository.  (Using SetStack or SetPixels would use too
much memory in the case of large images; using SetROI would take more
time than the other Set* methods.)

=cut


sub __createRepositoryFile {
    my ($self,$image,$sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bitsPerPixel) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my $module_execution = $self->ModuleExecution();
    my @repository = $factory->findAttributes("Repository");
    my $repository = $repository[0];

    # Create the Pixels attribute.  Note that the Path element depends
    # on the primary key ID assigned to the attribute, so we must set
    # it to a dummy value first.

    my $pixels = $factory->
      newAttribute("Pixels",$image,$module_execution,
                   {
                    Repository   => $repository->id(),
                    SizeX        => $sizeX,
                    SizeY        => $sizeY,
                    SizeZ        => $sizeZ,
                    SizeC        => $sizeC,
                    SizeT        => $sizeT,
                    BitsPerPixel => $bitsPerPixel,
                    Path         => 'x',
                   });

    # Now that the attribute has an ID, calculate the actual Path
    # element and store it.

    my $path = $pixels->id()."-".$image->name().".ori";
    $path =~ s/[^A-Za-z0-9-_.]/_/g;
    $pixels->Path($path);
    $pixels->storeObject();

    $image->pixels_id( $pixels->id() ); # Josiah's viewer hack
    $image->storeObject();

    # Create an OME::Image::Pix instance to correspond to this new
    # Pixels attribute.

    my $pix = $image->GetPix($pixels);

    return ($pixels,$pix);
}

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine|OME::ImportEngine::ImportEngine>

=cut

1;
