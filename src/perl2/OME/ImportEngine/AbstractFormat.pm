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
	                 new();
	my $groups = $format->getGroups($filenames);
	my $sha1 = $format->getSHA1($group);
	my $image = $format->importGroup($group);
	$format->cleanup();

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

=head2 cleanup

	$format->cleanup();

This method will be called once the import finishes (regardless of
whether the import was successful).  If any persistent resources need
to be created during the import process for your format, they can be
freed in this method.

=cut

sub cleanup {
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


=head2 __getRegexGroups

This method is called from an importer and is passed a reference to a hash
whose values are OME files.  This method will look for a Semantic Type that
specifies a regular expression.  If any are found, it compares the filenames
to the regular expression.  If there's a match, the method will group these
elements together by basename in a hash, %groups.

A FilenamePattern Semantic Type is specified in src/xml/OME/Import/FilenamePattern.ome.
An example of how to specify your own regular expression can be found in this file
as a Custom Attribute.

An example of a hash in the array returned by findObjects() is below:

my $FileNameGroups = {
	Format    => 'OME::ImportEngine::TIFFreader',
 	RegEx     => '(basename)_t(\d+)_z(\d+)_c(\d+)',
 	Name 	  => 'foo',
	BaseName  => 1,
	T         => 2,
	Z         => 3,
	C		  => 4

A hash of the number of Z's, C's and T's found is created during the method
call:
		my $maxZ = $infoHash->{ $pattern }->{ maxZ };

To get a file out of @groups, use my $file = $groups{$basename}[$z][$t][$c];

Usage:
my ($groups, $infoHash) = $self->__getRegexGroups(\%file_list);
	
};

=cut

sub __getRegexGroups {
    my ($self, $read_only_file_list) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my %groups;
    my $maxZ;
    my $maxT;
    my $maxC;
    
    # A hash containing the number of patterns, as well as numZ, C, T, for each pattern
    my $infoHash;
    
    # make a copy of the list so we can delete elements without screwing with the original list
    my %file_list_copy = %$read_only_file_list;
    
    my $format = ref( $self );
    # See if there is a FilenamePattern ST in this DB.
	my $ST = $factory->findObject("OME::SemanticType",name => 'FilenamePattern');
    return (\%groups, $infoHash) unless defined $ST;

    # Get the array of filenamePattern hashes
    my @filenamePatternList = $factory->findObjects( 
    	'@FilenamePattern',
    	{ Format => $format }
    );
    
    # apply regular expressions to group %file_list_copy
    # store results in @groups
    # an entry in @groups should look something like:
    # 	$group_entry[$filePatternNumber][$z][$t][$c] = $file;
    foreach my $filenamePattern ( @filenamePatternList )
    {
    	# this naively assumes that the regular expression we get is safe :(
    	# see ImportExport/ModuleImport.pm for some regexp validity/safety checking
    	# Do validity checking of the regular expression.
    	my $regexp = $filenamePattern->RegEx();
    	eval { "" =~ /$regexp/; };
		die "Invalid regular expression pattern: $regexp\n" if $@;
		
		# TODO: Put safety checks here
		#
		#
		#
    	
    	# There has to be a name in the file or you won't be able to group.
    	# Die if there isn't a name!
		die "No name in filePattern!" unless $filenamePattern->BaseName() and $filenamePattern->BaseName() > 0;
		
		# Each file represents at least one Z, T, and C.
		$maxZ = 1;
    	$maxT = 1;
    	$maxC = 1;
    	# Arrays of the Z's, T's, and C's already taken from this batch of files.
    	# Each element is unique (there aren't 2 elements that have the same value).
    	# This provides a way to count how many z's, t's and c's there are in this group.
    	my (@z_list, @t_list, @c_list);

		foreach my $file ( values %file_list_copy )
		{
			my $filename = $file->getFilename();
			if( $filename =~ m/$regexp/ )
			{	
				my $name = "";
				my $z = 0;
				my $t = 0;
				my $c = 0;
				eval ('$name = $'.$filenamePattern->BaseName());
				die "When grouping files, Name capture failed with error: $@\n" if $@;
			
				if ( defined($filenamePattern->TheZ()) && $filenamePattern->TheZ() > 0 )
				{
					# Grab the Z from the file based on the regular expression
					eval ('$z = $'.$filenamePattern->TheZ());
					die "When grouping files, Z capture failed with error: $@\n" if $@;
					
					# Now search the list of z's for a match to the current z.  If
					# there's a match, don't push the new z onto the array.
					# Reset $maxZ to the number of elements in the list.
					my $dupFound = 0;
					foreach my $zAlreadyThere (@z_list)
					{
						if ($z == $zAlreadyThere)
						{
							$dupFound = 1;
							last;
						}
					}
					push (@z_list, $z) if ($dupFound == 0);
					$maxZ = scalar(@z_list);
				}
				if ( defined($filenamePattern->TheT()) && $filenamePattern->TheT() > 0 )
				{
					# Grab the T from the file based on the regular expression
					eval ('$t = $'.$filenamePattern->TheT());					
					die "When grouping files, T capture failed with error: $@\n" if $@;
					
					# Now search the list of t's for a match to the current t.  If
					# there's a match, don't push the new t onto the array.
					# Reset $maxT to the number of elements in the list.
					my $dupFound = 0;
					foreach my $tAlreadyThere (@t_list)
					{
						if ($t == $tAlreadyThere)
						{
							$dupFound = 1;
							last;
						}
					}
					push (@t_list, $t) if ($dupFound == 0);
					$maxT = scalar(@t_list);
				}
				if ( defined($filenamePattern->TheC()) && $filenamePattern->TheC() > 0 )
				{
					# Grab the C from the file based on the regular expression
					eval ('$c = $'.$filenamePattern->TheC());			
					die "When grouping files, C capture failed with error: $@\n" if $@;
					
					# Now search the list of c's for a match to the current c.  If
					# there's a match, don't push the new c onto the array.
					# Reset $maxC to the number of elements in the list.
					my $dupFound = 0;
					foreach my $cAlreadyThere (@c_list)
					{
						if ($c == $cAlreadyThere)
						{
							$dupFound = 1;
							last;
						}
					}
					push (@c_list, $c) if ($dupFound == 0);
					$maxC = scalar(@c_list);					
				}
				
				# Add the file to %groups
				$groups{ $name }[$z][$t][$c] = $file;

				# Add the maxZ, C, and T to the infoHash, specified by the basename of the image
				$infoHash->{ $name }->{ maxZ } = $maxZ;
				$infoHash->{ $name }->{ maxC } = $maxC;
				$infoHash->{ $name }->{ maxT } = $maxT;

				# Remove $file from %file_list_copy to prevent it from being picked up by other filenamePatterns
				delete $file_list_copy{ $file };
			} # end outer if
		}
		
		
	}
	#$infoHash->{ numPatterns } = $numFilenamePatterns;
	
	# TODO: Check to make sure the files are in series.
	
    return (\%groups, $infoHash);
}


=head2 __newImage

	my $image = $self->__newImage($image_name);

Calls the session's Factory to create a new image object. Those attributes
that are known before the import are recorded in the new image.

=cut

sub __newImage {
    my ($self, $fn, $creation) = @_;

    my $session = $self->Session();
    my $guid = $session->Configuration()->mac_address();

    my $experimenter_id = $session->User()->id();
    my $user_group = $session->User()->Group();
    my $group_id = defined $user_group? $user_group->id(): undef;

    $creation = 'now' unless defined $creation;
    my $insertion = 'now';

    my $recordData = {'name' => $fn,
		      'image_guid' => $guid,
		      'description' => "",
		      'experimenter_id' => $experimenter_id,
		      'group_id' => $group_id,
		      'created' => $creation,
		      'inserted' => $insertion,
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

    # remove filetype extension from filename.
	# Assume that the last field (delimited by .) is the 
	# filetype extension. So $basenm of tiff.any.tiff is tiff.any 
	if ($basenm =~ /.*\..*/) {
		$basenm =~ m/(^.*\.)/;
		$basenm = $1;
		chop($basenm); # chop the trailing . 
	}
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
    my $bytesPerPixel = $self->__bitsPerPixel2bytesPerPixel($bitsPerPixel);
	my $pixelType = 
      OME::Tasks::PixelsManager->getPixelType($bytesPerPixel,$isSigned,$isFloat);

    my %image_hash = (SizeX => $sizeX,
		      SizeY => $sizeY,
		      SizeZ => $sizeZ,
		      SizeC => $sizeC,
		      SizeT => $sizeT,
		      PixelType => $pixelType);
    my ($pixels,$attr) = OME::Tasks::PixelsManager->
	createPixels($image,$module_execution, \%image_hash);

    $image->pixels_id( $attr->id() ); # Josiah's viewer hack
    $image->storeObject();

    return ($attr,$pixels);
}





=head2  __bitsPerPixel2bytesPerPixel

        __bitsPerPixel2bytesPerPixel($bitsPerPixel)

logic figures out the correct byte size based on bits.  
this allows for TIFF files with un-natural pixel depth (i.e. 12bits per pixel)
use this instead of bytesPerPixel = bitsPerPixel/8

=cut

sub __bitsPerPixel2bytesPerPixel {
	my ($self,$bitsPerPixel) = @_;
	my $bytesPerPixel;
	
    if ($bitsPerPixel<=8 ){
	    $bytesPerPixel = 1;     
	}elsif ( $bitsPerPixel>8 && $bitsPerPixel<=16 ){
		$bytesPerPixel = 2;
	}else{
		$bytesPerPixel = 4;
    }
	return $bytesPerPixel;
}


=head2  __destroyRepositoryFile

        __destroyRepositoryFile($pixels, $pix)

Destroy the repository file referenced by $pixels/$pix. This would normally
be called if an import fails after __createRepositoryFile() has been
successfully called.

=cut

sub __destroyRepositoryFile {
    my ($self, $pixels, $pix) = @_;

#    ** TODO**  Implement this
}



=head1 AUTHORS

Douglas Creager (dcreager@alum.mit.edu)
Arpun Nagaraja

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine|OME::ImportEngine::ImportEngine>

=cut

1;
