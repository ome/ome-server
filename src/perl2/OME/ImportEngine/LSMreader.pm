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
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::AbstractFormat;
use OME::ImportEngine::Params;
use OME::Tasks::PixelsManager;
use OME::ImportEngine::TIFFUtils;
use OME::Tasks::ImportManager;

use Carp;
use base qw(OME::ImportEngine::AbstractFormat);
use vars qw($VERSION);

=head1 METHODS

The following public methods are available:

=head2 B<new>

    my $importer = OME::ImportEngine::LSMReader->new($session, $module_execution)

Creates a new instance of this class. The other public methods of this
class are accessed through this instance.  The caller, which would
normally be OME::ImportEngine::ImportEngine, should already
have created the session and the module_execution.

=cut

sub new
{
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};

    bless $self, $class;
    $self->{super} = $self->SUPER::new();

    my %paramHash;
    $self->{params} = new OME::ImportEngine::Params(\%paramHash);
    return $self;
} # end new

=head2 B<getGroups>

    my $group_output_list = $importer->getGroups(\%filepaths)

This method examines the list of filenames that is passed in by
reference. Any files on the list that are LSM files are removed
from the input list and added to the preliminary output list.

This method uses readTiffIFD, which can be found in TIFFUtils.pm.
If it's a valid tiff file, the tags are read, and then the file
is checked for compression.  If there's no compression, the file
is checked to see if it's a valid LSM image by getting a hash that's
supposed to be assigned to key 34412.

=cut

sub getGroups
{
	my $self = shift;
	my $inlist = shift;  # catch the reference for the filepath hash
	my @outlist;
	
	foreach my $file (values %$inlist)
	{
    	$file->open('r');
  		my $tag0 = readTiffIFD( $file,0 );
		$file->close();
		
		# do a check for compression - this does not support compressed TIFF images (yet?)
		my $compression = $tag0->{ 259 }->[0];
		if ( defined($compression) && $compression == 5 )
		{
			next;
		}
		
		my $offsetHash = $tag0->{ 34412 }->[0]; # 34412 is the key for CZ-private TAG
		if (defined($offsetHash) && ref($offsetHash) eq 'HASH')
		{
			push (@outlist, $file);
		}
    }
    # Clean $inlist.
    $self->__removeFiles($inlist, \@outlist);
    
    return \@outlist;
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
	my ($self, $file, $callback) = @_;
	my $session = ($self -> {super}) -> Session();
	my $tag0 = readTiffIFD( $file,0 ); # gets the cached version
	my $tag2 = readTiffIFD( $file,2 ); # no cached version
	
	$file->open('r');
	my $filename = $file->getFilename();
    my $basename = ($self->{super})->__nameOnly($filename);

    my $params = $self->getParams();
    my $xref = $params->{xml_hash};
    
    $params->fref($file);
    $params->oname($filename);
    $params->endian($tag0->{__Endian});
    
    $xref->{'Image.SizeX'} = $tag0->{TAGS->{ImageWidth}}->[0];
    $xref->{'Image.SizeY'} = $tag0->{TAGS->{ImageLength}}->[0];
    $xref->{'Data.BitsPerPixel'} = $tag0->{TAGS->{BitsPerSample}}->[0];    
    
    $params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $params->row_size($xref->{'Image.SizeX'} * ($params->byte_size));
    
    # use TIFF tags to fill-out info about the image
   	readPrivateTags($file, $params, $tag0);
   	
   	# find the offsets based on the first and third IFD's
	my ($offsets0, $bytesize0) = getStrips($tag0);
	my ($offsets2, $bytesize2) = getStrips($tag2) unless ( !defined($tag2) );
	
	# Calculate the jump between planes
	my $jump = (defined($tag2)) ? ($$offsets2[0] - $$offsets0[0]) : $$bytesize0[0];
	
	# Grab the channel starts from the offsets array of the first IFD for each channel
	my @ch_starts;
	for (my $i = 0; $i < $xref->{'Image.NumWaves'}; $i++)
	{
		push(@ch_starts, $$offsets0[$i]);
	}
   	
    my $image = ($self->{super})->__newImage($basename);
    $self->{image} = $image;
    if (!defined($image))
    {
		$file->close();
		die "Failed to open image";
    }
    
    # Now, write the metadata
    writeMetadata($session, $params, $image);
    
    # pack together & store info in input file
    my @finfo;
    $self->__storeOneFileInfo(\@finfo, $file, $params, $image,
			      0, $xref->{'Image.SizeX'}-1,
			      0, $xref->{'Image.SizeY'}-1,
			      0, $xref->{'Image.SizeZ'}-1,
			      0, $xref->{'Image.NumWaves'}-1,
			      0, $xref->{'Image.NumTimes'}-1,
                  "Zeiss LSM 510");

    my ($pixels, $pix) = 
	($self->{super})->__createRepositoryFile($image, 
						 $xref->{'Image.SizeX'},
						 $xref->{'Image.SizeY'},
						 $xref->{'Image.SizeZ'},
						 $xref->{'Image.NumWaves'},
						 $xref->{'Image.NumTimes'},
						 $xref->{'Data.BitsPerPixel'});
    $self->{pixels} = $pixels;
    my $status = "";
    
    my ($t, $c, $z);	
    my $maxY = $xref->{'Image.SizeY'};
    my $maxZ = $xref->{'Image.SizeZ'};
    my $maxC = $xref->{'Image.NumWaves'};
    my $maxT = $xref->{'Image.NumTimes'};
    
    # Since the planes are not arranged in XYZCT order, this pixel writing jumps around
    # the file as necessary.
    for ($c = 0; $c < $maxC; $c++)
    {
    	my $offset = $ch_starts[$c];
    	for ($t = 0; $t < $maxT; $t++)
		{
			for ($z = 0; $z < $maxZ; $z++)
			{
				$pix->convertPlane($file,$offset,$z,$c,$t,$params->endian == 1);
				doSliceCallback($callback);
				$offset += $jump;
			}
		}
    }

    OME::Tasks::PixelsManager -> finishPixels( $pix, $self->{pixels} );

    $file->close();

    if ($status eq "")
    {
		$self->__storeInputFileInfo($session, \@finfo);
		return $image;
    }
    
    else
    {
		($self->{super})->__destroyRepositoryFile($pixels, $pix);
		die $status;
    }
}

# Read in the data contained in the private tags of the LSM file.  Store this
# data to xref (the xml hash) so it can be called later in writeMetadata.
# Usage: readPrivateTags( $file, $params, $tags );
sub readPrivateTags
{
	my ($file, $params, $tags) = @_;
	my $endian = $params->endian;
	my $buffer;
	my $template = ($endian == 0) ? "V3" : "N3";
	my @data;
	my $xref = $params->{ xml_hash };

	my $offsetHash = $tags->{ 34412 }->[0]; # 34412 is the key for CZ-private TAG

	my $valueOffset = $offsetHash->{ value_offset };
	$file -> setCurrentPosition( $valueOffset + 16 );
	$buffer = $file -> readData(12);
	@data = unpack($template, $buffer);
	
	$xref->{ 'Image.SizeZ' } = $data[0];
	$xref->{ 'Image.NumWaves' } = $data[1];
	$xref->{ 'Image.NumTimes' } = $data[2];
	
	$template = "F";
	
	# Pixel sizes start 40 bytes away from valueOffset
	$file -> setCurrentPosition( $valueOffset + 40 );
	$buffer = $file -> readData(8);
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	if (($data[0] * 1000000) >= 0)
	{
		$xref->{ 'Image.PixelSizeX' } = ($data[0] * 1000000); # convert meters to microns
	}
	
	$buffer = $file -> readData(8);
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	if (($data[0] * 1000000) >= 0)
	{
		$xref->{ 'Image.PixelSizeY' } = ($data[0] * 1000000); # convert meters to microns
	}
	
	$buffer = $file -> readData(8);
	$buffer = swapper($buffer, $endian);
	@data = unpack($template, $buffer);
	if (($data[0] * 1000000) >= 0)
	{
		$xref->{ 'Image.PixelSizeZ' } = ($data[0] * 1000000); # convert meters to microns
	}
	
	$template = ($endian == 0) ? "Vx12Vx4Vx70V" : "Nx12Vx4Nx70N";
	$file -> setCurrentPosition( $valueOffset + 108 );
	$buffer = $file -> readData(102);
	@data = unpack($template, $buffer);
	
	# This information can be used later to locate, read, and write metadata
	$xref->{ 'OffsetChannelsColors' } = $data[0];
	$xref->{ 'OffsetScanInfo' } = $data[1];
	$xref->{ 'OffsetTimestamps' } = $data[2];
	$xref->{ 'OffsetChannelWavelength' } = $data[3];
}

# Writes the metadata that was extracted from the image
# Usage: writeMetadata( $session, $params, $image );
sub writeMetadata
{
	my ($session, $params, $image) = @_;
	my $xref = $params->{ xml_hash };
	
	my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);
	my $factory = $session->Factory();
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
	if ( ($endian == 0 && $cpu_big_endian == 1) || ($endian == 1 && $cpu_big_endian == 0) )
	{
		$buffer =~ s/(.)(.)(.)(.)(.)(.)(.)(.)/$8$7$6$5$4$3$2$1/;
	}
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
		die "Could not compute this computer's endianness!\n";
	}
}

# Get the SHA1 for this file
sub getSHA1
{
    my $self = shift;
    my $file = shift;
    return $file->getSHA1();
}

# Get %params hash reference
sub getParams
{
    my $self = shift;
    return $self->{params};
}

# returns a string representing a hash dump. Usage:
# 	dumpHash( %hash )
sub dumpHash
{
	my %hash = @_;
	return "\t".join( "\n\t", map ( $_.' -> '.$hash{$_}, keys %hash ) )."\n";
}

# returns a string representing an array dump. Usage:
# 	dumpArray( @array )
sub dumpArray
{
	my @array = @_;
	return "\t".join("\n\t", @array)."\n";
}

1;