# OME/ImportEngine/AbstractFormat.pm

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
use OME;
our $VERSION = $OME::VERSION;

use OME::Tasks::ImportManager;
use OME::Tasks::PixelsManager;

use fields qw(_session _module_execution);
use File::Basename;

=head1 CONTRACT

The following public methods must be available for a class to be used
by the import engine to import images.

=head2 new

	my $format = OME::ImportEngine::AbstractFormat->new();

Creates a new instance of this format import class.  Any new
attributes created by this importer should point to the appropriate
import module executions, otherwise they will not be visible to any
future analysis chains.  This MEX's can be obtained via the get*MEX
methods in the OME::Tasks::ImportManager class.

This is the only contract method which has a non-abstract
implementation in AbstractFormat.  Any subclasses should be sure to
call $self->SUPER::new() in their own constructors.

=cut

sub new {
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};

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

=head2 Session

	my $session = $self->Session();

Returns the session that was given as a parameter to the C<new> method.
Note that this will only return a correct value if the overridden
C<new> method calls its superclass C<new> method.

=cut

sub Session { return OME::Session->instance(); }


=head2 __newImage

	my $image = $self->__newImage($image_name);

Calls the session's Factory to create a new image object. Those attributes
that are known before the import are recorded in the new image.

=cut

sub __newImage {
    my ($self, $fn) = @_;

    my $session = $self->Session();
    my $guid = $session->Configuration()->mac_address();

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

=head2 __touchOriginalFile

	my $file_attribute = $self->__touchOriginalFile($filename,$format);

Should be called once for each file which constitutes an image.
Creates an OriginalFile attribute for this file.  If this file is
touched more than once during the import process, only one attribute
will be created.

=cut

sub __touchOriginalFile {
    my ($self,$file,$format) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $file_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

    print STDERR "Touch '$format' $file\n";

    return OME::Tasks::PixelsManager->
      createOriginalFileAttribute($file,$format,$file_mex);
}


=head2 __storeInstrumemtInfo

        $self->storeInstrumemtInfo($image,$model, $manufacturer, $orientation, $sn);

Creates an Instruments attribute for this image. Parameters are ordered
in expected frequency of occurrence; unknown parameters may be left off
the end of the argument string. Should be called once per image if there
is any instrument data to store. This will not accurately handle the
creation of an image composed from input images taken by different instruments.

=cut

sub __storeInstrumemtInfo {
    my ($self,$image,$model,$manufacturer,$orientation,$serialnum) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $img_mex = OME::Tasks::ImportManager->getImageImportMEX($image);

    $factory->newAttribute("Instrument", undef, $img_mex,
			   {
			       Model => $model,
			       Manufacturer => $manufacturer,
			       SerialNumber => $serialnum,
			       Type => $orientation,
			   });
}


=head2 __removeFiles

	$self->__removeFiles($files,$to_remove);

Takes in two array references of files.  After this method returns,
none of the members of the $to_remove list will exist in the $files
list.

=cut

sub __removeFiles {
    my ($self,$file_list,$to_remove) = @_;

    foreach my $file (@$to_remove) {
        my $filename = $file->getFilename();
        delete $file_list->{$filename};
    }

    return;
}


=head2 __nameOnly

	my $basename = $self->__nameOnly($full_pathname);

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
	                           $sizeC,$sizeT,$bitsPerPixel,
	                           [$isSigned],[$isFloat]);

Creates a new repository file for the given image, creates a Pixels
attribute to refer to it ($pixels_attribute), and creates an instance
of OME::Image::Pixels to access the pixel data ($pix_object).  The
dimensions of the image must be specified before the repository file
is created.

The Pixels attribute will not be very useful to most import code,
except that any newly created attributes which require a reference to
a Pixels will point to it.  The import code will use the
OME::Image::Pixels instance much more, as it provides the low-level
access to the repository file.

=cut


sub __createRepositoryFile {
    my ($self,$image,$sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,
        $bitsPerPixel,$isSigned,$isFloat) = @_;

    $isSigned ||= 0;
    $isFloat ||= 0;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);

    my ($pixels,$attr) = OME::Tasks::PixelsManager->
      createPixels($image,$module_execution,
                   $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,
                   $bitsPerPixel/8,$isSigned,$isFloat);

    $image->pixels_id( $attr->id() ); # Josiah's viewer hack
    $image->storeObject();

    return ($attr,$pixels);
}

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine|OME::ImportEngine::ImportEngine>

=cut

1;
