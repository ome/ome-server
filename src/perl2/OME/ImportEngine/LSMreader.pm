# OME/ImportEngine/LSMreader.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:    Arpun Nagaraja
#
#-------------------------------------------------------------------------------

package OME::ImportEngine::LSMreader;

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::PixelsManager;
use OME::ImportEngine::TIFFUtils;
use OME::Tasks::ImportManager;
use Log::Agent;

use Carp;
use base qw(OME::ImportEngine::AbstractFormat);
use vars qw($VERSION);
use constant 'LSM' => 34412; # a valid LSM image has this tag
 
=head1 METHODS

The following public methods are available:


=head2 B<getGroups>

    my $group_output_list = $importer->getGroups(\%filepaths)

This method examines the list of filenames that is passed in by
reference. Any files on the list that are LSM files are removed
from the input list and added to the preliminary output list.

This method uses readTiffIFD, which can be found in TIFFUtils.pm.
If it's a valid tiff file, the tags are read, and then the file
is checked for compression.  LSM images are TIFF images with
the LSM tag defined.

=cut

sub getGroups
{
    my $self = shift;
    my $fref = shift;
    my @outlist;
    my $xref;
	my ($filename,$file);
	my %LSMs;
	my $lsm = LSM;

	# ignore any non-lsm files.
	while ( ($filename,$file) = each %$fref ) {
		# LSM images are TIFF images with a defined LSM tag
		if (defined(verifyTiff($file))) {
			my $tag0 = readTiffIFD( $file,0 );
			$LSMs{$filename} = $file if defined($tag0->{$lsm}->[0]);
		}
	}

    # Group files with recognized patterns together
    # Sort them by channels, z's, then timepoints
    my ($groups, $infoHash) = $self->getRegexGroups(\%LSMs);

	my ($name,$group);
	
    while ( ($name,$group) = each %$groups ) {
    	next unless defined($name);
    	my $nZfiles = $infoHash->{ $name }->{ nZfiles };
		my $nCfiles = $infoHash->{ $name }->{ nCfiles };
		my $nTfiles = $infoHash->{ $name }->{ nTfiles };
		my @groupList;
	
		for (my $z = 0; $z < $nZfiles; $z++) {
    		for (my $c = 0; $c < $nCfiles; $c++) {
    			for (my $t = 0; $t < $nTfiles; $t++) {
    				$file = $group->[$z][$c][$t]->{File};
    				die "Uh, file is not defined at (z,c,t)=($z,$c,$t)!\n"
    					unless ( defined($file) );
    				
					# The other keys of this hash give access to the actual
					# sub-patterns matched by the RE:
    				# $zString = $group->[$z][$c][$t]->{Z};
    				# $cString = $group->[$z][$c][$t]->{C};
    				# $tString = $group->[$z][$c][$t]->{T};
					# Note that undef strings are converted to ''.
    				
    				push (@groupList, $file);
    				
    				# delete the file from the hash, so it's not processed by other importers
    				$filename = $file->getFilename();
					logdbg "debug",  "deleting $filename in group $name";
					delete $fref->{ $filename };
					delete $LSMs{ $filename };
    			}
    		}
    	}
    	push (@outlist, {
    		Files => \@groupList,
    		BaseName => $name,
    		GroupInfo => $group,
    		nZfiles  => $nZfiles,
    		nCfiles  => $nCfiles,
    		nTfiles  => $nTfiles,
    	})
    		if ( scalar(@groupList) > 0 );
    }
    
    # Now look at the rest of the files in the list to see if we
    # have any single-file LSMs.
    foreach $file ( values %LSMs ) {    	
    	
    	$filename = $file->getFilename();
    	my $basename = $self->nameOnly($filename);
    	my $group;
    	$group->[0][0][0]={
    		File => $file,
    		Z    => undef,
    		C    => undef,
    		T    => undef,
    	};
    	push (@outlist, {
    		Files => [$file],
    		BaseName => $basename,
    		GroupInfo => $group,
    		nZfiles  => 1,
    		nCfiles  => 1,
    		nTfiles  => 1,
    	});
		logdbg "debug",  "deleting $filename in singleton group $basename";
		delete $fref->{ $filename };
		delete $LSMs{ $filename };
    }
	
    return \@outlist;
}

=head2 B<importLSM>

    my ($nZ,$nC,$nT) = $importer->importLSM($file, $callback, $pix, $z0, $c0, $t0)

This method imports an individual LSM file into a 5D OME 5D image.
The caller is responsible for figuring out the total size of the 5D array
based on groups of LSMs or a single LSM.  The caller also determines what
position in the 5D array to insert the given LSM file.  The Z, C, T planes in the
LSM file will be inserted into the array at the specified positions $z0, $c0, $t0

Using filename patterns, its possible to re-combine any number of LSM slices in separate files.
For example, say the following two files each contain a 5D array:\

  lsm_z0_w1_t0
  lsm_z1_w2_t1
 
When combined, all the Zs, channels and times in lsm_z0_c1_t0 will be followed
by the Zs, channels and times in lsm_z1_c2_t1.  In other words, the final 5D array
will have the number of Z sections in lsm_z0_c1_t0 plus the number of Z sections in
lsm_z1_c2_t1.  Same for channels and times.  This example is for a 3-D splice, because
the filenames spcify different Zs, different channels and differend Ts.
Note that no check is made
to make sure all the planes specified by the splices are occupied with pixels.  It is possible
for splices to result in blank planes, and this is not considered an error by the importer.

To simply combine two timepoints (i.e. a 1-D splice on T), name the files:

  lsm_z0_w1_t0
  lsm_z0_w1_t1

or,

  lsm_t0
  lsm_t1

The calls to importLSM will take the form:

  ($theZ,$theC,$theT) = (0,0,0);
  ($nZ,$nC,$nT) = $importer->importLSM($file, $callback, $pix, $theZ,$theC,$theT);

Note that if no errors occurred, $nZ, $nC, $nT will allways be > 0, because
even a single plane occupies a ZCT address.  It is the caller's responsibility to advance
($theZ,$theC,$theT) or not depending on what dimensions are being spliced.

=cut

sub importLSM
{
	my ($self, $pix, $file, $callback, $z0, $c0, $t0) = @_;

	my @IFDs = readTiffIFD( $file );
	my ($z,$c,$t);
	my ($fSizeZ,$fSizeC,$fSizeT) = getSizeZCT ($file, $IFDs[0]);
    	
	# Each tiff directory contains a set of channels, which can be arranged
	# by Z or by T
	# Each tiff directory contains either data or a thumbnail.
	# Thumbnails are distinguished by having a SubfileType of 1
	# Images (data) has a SubFile of 0
	#
	# Each tiff directory's StripOffsets are the locations of the channel data.
	# One StripOffset per channel.

	my $IFDindx = 0;
    for ($t = 0; $t < $fSizeT; $t++) {
    	for ($z = 0; $z < $fSizeZ; $z++) {
			$pix->convertPlaneFromTIFF($file, $z+$z0, $c0, $t+$t0, $IFDindx);
			$self->doSliceCallback($callback);
			$IFDindx++;
			# skip thumbnails
			$IFDindx++ while ($IFDs[$IFDindx]->{TAGS->{SubFile}}->[0] != 0);
		}
    }
}

=head2 B<importGroup>

    my $image = $importer->importGroup(\@files)

This method imports individual LSM format files into OME
5D images. The caller passes a set of input files by
reference. This method opens each file in turn, extracts
its metadata and pixels, and creates a corresponding OME image.

The metadata is extracted not only from regular TIFF tags, but from
custom LSM tags designated by key 34412.  It is then written to OME.

If all goes well, this method returns a pointer to a freshly created 
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut

sub importGroup
{
    my ($self, $group, $callback) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    
    my $groupList = $group->{Files};

    my $file = $groupList->[0];
	$file->open('r');
	my $tag0 = readTiffIFD( $file,0 );
	$file->close();

	my $filename = $file->getFilename();
	my $basename = $group->{BaseName};
    
	my $sizeX = $tag0->{TAGS->{ImageWidth}}->[0];
	my $sizeY = $tag0->{TAGS->{ImageLength}}->[0];
	my ($fSizeZ,$fSizeC,$fSizeT) = getSizeZCT ($file, $tag0);

	my ($sizeZ,$sizeC,$sizeT) = ($fSizeZ,$fSizeC,$fSizeT);
	$sizeZ *= $group->{nZfiles};
	$sizeC *= $group->{nCfiles};
	$sizeT *= $group->{nTfiles};

	my $bpp = $tag0->{TAGS->{BitsPerSample}}->[0];
    
    # use TIFF tags to fill-out info about the image
    my $xref = {};
   	readPrivateTags($file, $xref, $tag0);

    my $image = $self->newImage($basename);

    if (!defined($image))
    {
		$file->close();
		die "Failed to open image";
    }

	my ($pixels, $pix) = $self->createRepositoryFile($image, 
						 $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp);

    my ($t, $c, $z);
    my $planeStarts;
    
    my $nZ = $group->{nZfiles};
    my $nC = $group->{nCfiles};
    my $nT = $group->{nTfiles};
	for ($z = 0; $z < $nZ; $z++) {
		for ($c = 0; $c < $nC; $c++) {
			for ($t = 0; $t < $nT; $t++) {
				$file = shift( @$groupList );
				my ($z0,$c0,$t0) = ( $z * $fSizeZ, $c * $fSizeC, $t * $fSizeT);
				$self->importLSM ($pix, $file, $callback, $z0,$c0,$t0);
				$self->storeOneFileInfo($file, $image,
					0, $sizeX-1,
					0, $sizeY-1,
					$z0, $z0+$fSizeZ-1,
					$c0, $c0+$fSizeC-1,
					$t0, $t0+$fSizeT-1,
					"Zeiss LSM 510");
			}
		}
	}
    OME::Tasks::PixelsManager -> finishPixels( $pix, $pixels );

    
    # Now, write the metadata
    $self->writeMetadata($xref, $image);
    
	$self->storeDisplayOptions($image);

	return $image;
}

# Read in the data contained in the private tags of the LSM file.  Store this
# data to xref (the xml hash) so it can be called later in writeMetadata.

sub getSizeZCT {
	my ($file, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $buffer;
	my $template = ($endian == 0) ? "V3" : "N3";
	my @data;

	my $offsetHash = $tags->{ 34412 }->[0]; # 34412 is the key for CZ-private TAG

	my $valueOffset = $offsetHash->{ value_offset };
	$file -> setCurrentPosition( $valueOffset + 16 );
	
	$buffer = $file -> readData(12);
	@data = unpack($template, $buffer);
	
	# The data array contains SizeZ, SizeC, SizeT
	return (@data);

}

sub readPrivateTags
{
	my ($file, $xref, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $buffer;
	my $template;
	my @data;

	my $offsetHash = $tags->{ 34412 }->[0]; # 34412 is the key for CZ-private TAG

	my $valueOffset = $offsetHash->{ value_offset };
	
	($xref->{ 'Image.SizeZ' },$xref->{ 'Image.NumWaves' },$xref->{ 'Image.NumTimes' }) = 
		getSizeZCT ($file, $tags);
	
	$template = "d";

	# Pixel sizes start 40 bytes away from valueOffset
	$file -> setCurrentPosition( $valueOffset + 40 );
	$buffer = $file -> readData(8);	
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	$xref->{ 'Image.PixelSizeX' } = ($data[0] * 1000000); # convert meters to microns

	$buffer = $file -> readData(8);
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	$xref->{ 'Image.PixelSizeY' } = ($data[0] * 1000000); # convert meters to microns

	$buffer = $file -> readData(8);	
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	$xref->{ 'Image.PixelSizeZ' } = ($data[0] * 1000000); # convert meters to microns

	# get to OffsetChannelColors
	# igg:  These don't appear to contain anything useful.
	#     Looking at "Recordings", "Tracks" and "DataChannels" might get somewhere.
	$template = ($endian == 0) ? "V1" : "N1";
	$file -> setCurrentPosition( $valueOffset + 84 );
	$buffer = $file -> readData(4);
	my ($OffsetChannelsColors) = unpack($template, $buffer);

	$xref->{ 'OffsetChannelsColors' } = $OffsetChannelsColors;
	return unless $OffsetChannelsColors;
	

	# Get tthe size of the struct
	$file -> setCurrentPosition( $OffsetChannelsColors );
	$buffer = $file -> readData(4);
	my ($BlockSize) = unpack($template, $buffer);

	$file -> setCurrentPosition( $OffsetChannelsColors + 16 );
	$buffer = $file -> readData(4);
	my ($NamesOffset) = unpack($template, $buffer);

	$file -> setCurrentPosition( $OffsetChannelsColors + $NamesOffset );
	$buffer = $file -> readData($BlockSize - $NamesOffset);
	$template = "Z*";
	my @ChNames = unpack($template, $buffer);
	

}

# Writes the metadata that was extracted from the image
# Usage: $self->writeMetadata($self, $xref, $image);
sub writeMetadata
{
	my ($self, $xref, $image) = @_;
	
	my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);
	my $factory = $self->Session->Factory();
	$factory->newAttribute( 'Dimensions', $image, $image_mex, {
			PixelSizeX => $xref->{ 'Image.PixelSizeX' },
			PixelSizeY => $xref->{ 'Image.PixelSizeY' },
			PixelSizeZ => $xref->{ 'Image.PixelSizeZ' },
		}
	) or die "Couldn't make Dimensions attribute";
	
	# Write more metadata.
}

# Do byte swapping only if the endianness between the cpu and the file is different
# Usage: my $buffer = swapper( $buffer, $endian );
sub swapper
{
	my ($buffer, $endian) = @_;
	my $cpu_big_endian = getCPUBigEndian();
	my $template = "H2H2H2H2H2H2H2H2";
	
	# Grab the 8 bytes of the buffer in hexadecimal and put them in @data, 1 byte per element
	my @data = unpack($template, $buffer);
	
	# Reverse the elements in @data (element 8 will now be 1, element 7 will be 2, etc.)
	if ( ($endian == 0 && $cpu_big_endian == 1) or
	     ($endian == 1 && $cpu_big_endian == 0) ) {
		@data = reverse(@data);
	}
	
	$buffer = "";
	
	# Rebuild the buffer using the newly ordered bytes
	foreach my $byte (@data) {
		$buffer .= $byte;
	}
	
	# Pack the buffer into a single hexadecimal number
	$buffer = pack("H16", $buffer);
	return $buffer;
}

# determine the endianness of this CPU - 1 for big endian, 0 for little endian
# Usage: my $big_endianness = getCPUBigEndian();
sub getCPUBigEndian
{
	my $cpu_big_endian   = unpack("h*", pack("s", 1)) =~ /01/;
	my $cpu_little_endian = unpack("h*", pack("s", 1)) =~ /^1/;
	
	if ($cpu_big_endian == 1)
	{
		return 1;
	}
	elsif ($cpu_little_endian == 1)
	{
		return 0;
	}
	else
	{
		die "Could not compute this machine's endianness!\n";
	}
}

# Get the SHA1 for this file
sub getSHA1
{
    my $self = shift;
    my $grp = shift;

    my $file = $grp->{Files}->[0];
    my $sha1 = $file->getSHA1();

    return $sha1;
}

1;
