# OME/ImportEngine/BioradReader.pm

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

package OME::ImportEngine::BioradReader;

use strict;
use OME;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::AbstractFormat;
use OME::ImportEngine::Params;
use OME::Tasks::PixelsManager;
use OME::Tasks::ImportManager;
use Carp;
use base qw(OME::ImportEngine::AbstractFormat);
use vars qw($VERSION);
$VERSION = $OME::VERSION;

use constant BIORAD_HEADER_LENGTH => 76;
use constant BIORAD_BIG_TEMPLATE =>    "n3x4Nnx2a32x4nx8nx8";
use constant BIORAD_LITTLE_TEMPLATE => "v3x4Vvx2a32x4vx8vx8";
use constant BIORADID => 12345;
use constant NOTES_LENGTH => 96;
use constant NOTE_TYPE_VARIABLE => 20;

=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine::BioradReader->new($session, $module_execution)

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
reference. Any files on the list that are Biorad files are removed
from the input list and added to the preliminary output list.

Since some Biorad images can be composed of several different files,
this subroutine then takes the preliminary outlist and sorts it to
finalOutlist (eventually) based on base filename.
=cut

sub getGroups
{
	my $self = shift;
	my $inlist = shift;  # catch the reference for the filepath hash
	my @prelimOutlist;
	my @secondOutlist;
	my @finalOutlist;
	my $params = $self -> getParams();

	foreach my $file (values (%$inlist))
	{
    	$file->open('r');
		if ($file->getLength() > BIORAD_HEADER_LENGTH)
		{
			push (@prelimOutlist, $file) if getEndian($file) ne "";
		}
		$file->close();
    }
    # Clean out $inlist.
    $self->__removeFiles($inlist, \@prelimOutlist);
    
    # Now that you have a list of the valid files, group them again based on whether or not
    # they're related.
    
    # First you need to read in all the metadata
    foreach my $file ( @prelimOutlist )
    {
    	my $xref = readHeaderData( $file );
    	my $notesExist = $xref -> { 'NotesExist' };
    	
    	if ($notesExist == 1)
    	{
    		$xref = readNotesData( $file, $xref );
   		 	$xref = interpretNotesData ( $xref );
    	}
    	
    	$params -> { $file } -> { xml_hash } = $xref;
    }
	
	# Now create a 2D array where each element represents a list of related files
    for (my $outer = 0; $outer < scalar(@prelimOutlist); $outer++)
    {
    	my @tempList;
    	my $outerFile = $prelimOutlist[$outer];

    	my $outerXref = $params -> { $outerFile } -> { xml_hash };
    	my $first = $outerXref -> { 'Basename' };

    	for (my $inner = 0; $inner < scalar(@prelimOutlist); $inner++)
    	{
    		my $innerFile = $prelimOutlist[$inner];
    		my $innerXref = $params -> { $innerFile } -> { xml_hash };
    		my $second = $innerXref -> { 'Basename' };
    		if ( $first eq $second )
    		{
    			push ( @tempList, $innerFile);
    			splice( @prelimOutlist, $inner, 1);
    			$inner--;
    		}
    	}
    	push( @secondOutlist, \@tempList );
    	$outer-- unless ( $outer < 0 );
    }
	
	# Now sort each list of related files by filename, so they'll be processed in order
	foreach my $subList ( @secondOutlist )
	{
		my @sortedList = sort {$a->getFilename() cmp $b->getFilename()} @$subList;
		push( @finalOutlist, \@sortedList );
	}
	
	# testing purposes
# 	foreach my $element ( @finalOutlist )
# 	{
# 		print "Loop: \n";
# 		foreach my $temp ( @$element )
# 		{
# 			print "\t$temp\n";
# 		}
# 	}
	
    return \@finalOutlist;
} # end getGroups


=head2 B<importGroup>

    my $image = $importer->importGroup(\@fileArray, \%localSliceCallback)
    
This method imports either individual or a group of Biorad images into an OME
5D image.  The caller passes an array of sorted files by reference.  The method
loops through the files in the array, extracting the necessary information from each
to compose an OME 5D image.

Biorad images carry their metadata in a 76 byte header and in optional "notes" that
are found at the end of the file.  By the time this method is called, the metadata
has already been stored by calls to readHeaderData, readNotesData, and interpretNotesData
in the getGroups method.

The method will return a pointer to a new OME::Image.  If there's an error, it will return
I<undef>, signaling the caller to rollback any associated database transactions.

=cut

sub importGroup
{
	my ($self, $fileList, $callback) = @_;
	my $session = ($self -> {super}) -> Session();
	my $image;
	
	foreach my $file (@$fileList)
	{
		my $xref;  # xml hash of all the metadata
		my $params = $self->getParams();
		my @finfo;
		$xref = $params -> { $file } -> { xml_hash };

		$file -> open('r');
		my $filename = $file->getFilename();
		my $basename = $xref -> { 'Basename' };
		#print "Basename is: $basename\n";
		$basename = ($self -> {super}) -> __nameOnly( $basename );
		
		$params->fref($file);
  		$params->oname($basename);
  		
  		my $pixelType = $xref -> { 'PixelType' }; #bps
		my $sizeX = $xref -> { 'SizeX' }; # rows
		my $sizeY = $xref -> { 'SizeY' }; # cols
		my $sizeZ = $xref -> { 'SizeZ' }; # sections
		my $sizeC = $xref -> { 'SizeC' }; # waves (channels)
		my $sizeT = $xref -> { 'SizeT' }; # times
  		
  		#print "XREF is: \n".dumpHash(%$xref)."\n";
		my $endian = $xref -> { 'BigEndian' };
		
		if ($endian == 0)
		{
			$params->endian('little');
		}
		elsif ($endian == 1)
		{
			$params->endian('big');
		}
    	
    	if ( $xref -> { 'MultiChannelMultiSection' } == 1)
    	{
    		$image = ($self -> {super}) -> __newImage($basename);
    		if ( !$image )
    		{
				$file -> close();
				die "Failed to open image";
    		}
    		$sizeT = scalar(@$fileList);
    		$xref -> { 'SizeT' } = $sizeT;
    		
    		my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);
			my $factory = $session->Factory();
			$factory->newAttribute( 'Dimensions', $image, $image_mex, {
				PixelSizeX => $xref->{ 'PixelSizeX' },
				PixelSizeY => $xref->{ 'PixelSizeY' },
				PixelSizeZ => $xref->{ 'PixelSizeZ' },
				}
			) or die "Couldn't make Dimensions attribute";
   
    		$self->__storeOneFileInfo( \@finfo, $file, $params, $image,
			0, $sizeX-1,
		   	0, $sizeY-1,
		   	0, $sizeZ-1,
		   	0, $sizeC-1,
	   	   	0, $sizeT-1,
       		"Bio-Rad PIC");
          		
       		my ($pixels, $pix) = ($self -> {super}) -> __createRepositoryFile(
    			$image, $sizeX, $sizeY, $sizeZ, $sizeC, $sizeT, $pixelType, 0, 0);
    		
    		$self -> {pixels} = $pixels;
    		my $status = readMultiFilePixels($self, $params, $pix, $fileList, $callback, $sizeX, $sizeY,
    							$sizeZ, $sizeC, $sizeT, $pixelType);
    		
    		if ($status ne '')
    		{
    			($self -> {super}) -> __destroyRepositoryFile($pixels, $pix);
				die $status;
    		}
    		
    		$self -> __storeInputFileInfo( $session, \@finfo );
    		return $image;
    	}
    	
    	else
    	{
    		$image = ($self -> {super}) -> __newImage($filename);
    		if ( !defined($image) )
    		{
				$file -> close();
				die "Failed to open image";
    		}
    		
    		my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);
			my $factory = $session->Factory();
			$factory->newAttribute( 'Dimensions', $image, $image_mex, {
				PixelSizeX => $xref->{ 'Image.PixelSizeX' },
				PixelSizeY => $xref->{ 'Image.PixelSizeY' },
				PixelSizeZ => $xref->{ 'Image.PixelSizeZ' },
				}
			) or die "Couldn't make Dimensions attribute";

    		$self->__storeOneFileInfo( \@finfo, $file, $params, $image,
			0, $sizeX-1,
		   	0, $sizeY-1,
		   	0, $sizeZ-1,
		   	0, $sizeC-1,
	   	   	0, $sizeT-1,
       		"Bio-Rad PIC");
          		
       		my ($pixels, $pix) = ($self -> {super}) -> __createRepositoryFile(
    			$image, $sizeX, $sizeY, $sizeZ, $sizeC, $sizeT, $pixelType, 0, 0);
    		
    		$self -> {pixels} = $pixels;
    		my $status = readSingleFilePixels($self, $params, $pix, $callback, $sizeX, $sizeY,
    											$sizeZ, $sizeC, $sizeT, $pixelType);
    		
    		$file -> close();
    			
    		if ($status ne '')
    		{
				($self -> {super}) -> __destroyRepositoryFile($pixels, $pix);
				die $status;
    		}
    		$self -> __storeInputFileInfo( $session, \@finfo );
    		return $image;
    	}
    }
}

###########################################################
#					HELPER METHODS                        #
###########################################################

# Converts the pixels to OME format
sub readSingleFilePixels
{
	my ($self, $params, $pix, $callback, $sizeX, $sizeY, $sizeZ, $sizeC,
		$sizeT, $pixelType) = @_;
	my $offset;
	my $zJump;
	my $file = $params -> fref;
	my $endian = $params -> endian;
	my $bigEndian = $endian eq "big";
	my $status = '';
	
	$params -> byte_size($pixelType / 8);
	$params -> pixel_size($pixelType);
	$zJump = $sizeX * $sizeY;
	
	# Start at begining of image data
	$offset = BIORAD_HEADER_LENGTH;
	
	for (my $theT = 0; $theT < $sizeT; $theT++)
	{
		for (my $theC = 0; $theC < $sizeC; $theC++) 
       	{
			for (my $theZ = 0; $theZ < $sizeZ; $theZ++)
			{
       			eval
           		{
           	   		$pix->convertPlane($file,$offset,
           	                      $theZ,$theC,$theT,
           	                      $bigEndian);
           	   	};
           	   	return $@ if $@;
				doSliceCallback($callback);
				$offset += $zJump; # jump to the next plane
       		}
    	}
    }
    
    OME::Tasks::PixelsManager -> finishPixels( $pix, $self -> {pixels} );
    return $status;
}

# Converts the pixels from multiple files into OME format
sub readMultiFilePixels
{
	my ($self, $params, $pix, $fileList, $callback, $sizeX, $sizeY, $sizeZ, $sizeC,
		$sizeT, $pixelType) = @_;
	my $offset;
	my $zJump;
	my $endian = $params -> endian;
	my $bigEndian = $endian eq "big";
	my $status = '';
	
	$params -> byte_size($pixelType / 8);
	$params -> pixel_size($pixelType);
	$zJump = $sizeX * $sizeY;
	
	# Start at begining of image data
	$offset = BIORAD_HEADER_LENGTH;
	
	my $theT = 0; #this assumes that each file represents a different time
	
	# this dies when you iterate to the second file
	foreach my $file( @$fileList )
	{
		$file -> open('r');
		for (my $theC = 0; $theC < $sizeC; $theC++) 
       	{
			for (my $theZ = 0; $theZ < $sizeZ; $theZ++)
			{
       			eval
           		{
           	   		$pix->convertPlane($file,$offset,
           	                      $theZ,$theC,$theT,
           	                      $bigEndian);
           	   	};
           	   	return $@ if $@;
				doSliceCallback($callback);
				$offset += $zJump; # jump to the next plane
       		}
    	}
    	$theT++;
    	$file -> close();
		$offset = BIORAD_HEADER_LENGTH;
	}
	
	OME::Tasks::PixelsManager -> finishPixels( $pix, $self -> {pixels} );
	return $status;
}

# Read in the metadata from the header of the Biorad file
sub readHeaderData
{
	my $file = shift;
	my $endian = getEndian($file);
	my $template;
	my $cntr = 0;
	my %imageTable; #xref
	
	#list of some keys to create in the hash table..in order of the template!
	my @keys = ('SizeX', 'SizeY', 'SizeZ', 'NotesExist', 'PixelType', 'Basename', 'FileID',
				'Magnification');
	
	#set the endian type..one of OME's image requirements
	if ($endian eq "little")
	{
		$template = BIORAD_LITTLE_TEMPLATE;
		$imageTable { 'BigEndian' } = 0;
	}
	
	elsif ($endian eq "big")
	{
		$template = BIORAD_BIG_TEMPLATE;
		$imageTable { 'BigEndian' } = 1;
	}
	
	$file -> setCurrentPosition(0);
	my $buffer = $file -> readData(BIORAD_HEADER_LENGTH);
	my @headerData = unpack($template, $buffer);
	
	# set each value to its corresponding key
	foreach my $element (@keys)
	{
		$imageTable { $element } = $headerData[$cntr];
		$cntr++;
	}
	
	#set the pixel type to be OME friendly
	my $pixelType = $imageTable { 'PixelType' };
	if ($pixelType == 1)
	{
		$imageTable{ 'PixelType' } = 8;
	}
	
	else
	{
		$imageTable{ 'PixelType' } = 16;
	}
	
	#set the NotesExist value to a boolean
	my $notes = $imageTable { 'NotesExist' };
	if ($notes != 0)
	{
		$imageTable { 'NotesExist' } = 1;
	}
	
	else
	{
		$imageTable { 'NotesExist' } = 0;
	}
	
	# set the defaults for an image
	$imageTable { 'ZSeries' } = 1;
	$imageTable { 'SizeC' } = 1;
	$imageTable { 'SizeT' } = 1;
	$imageTable { 'SingleChannelMultiSection' } = 1;
	$imageTable { 'MultiChannelMultiSection' } = 0;
	
	return \%imageTable;
}

# MUST BE CALLED AFTER readHeaderData!!!!!
# Read in any notes data from the end of the file, if it exists
sub readNotesData
{
	my $file = shift;
	my $imageTable = shift;
	my $endian = $imageTable -> { 'BigEndian' };

	my $template;
	my $buffer;
	
	if ($endian == 0) { $template = "x10vx4a80"; }
	elsif ($endian == 1) { $template = "x10nx4a80"; }

	# check to see if there really are notes
	my $numNotes = getNumNotes($file, $imageTable);
	return 0 if ($numNotes == 0);
	
	# value to jump to notes portion of file
	my $offset = getXYZ( $imageTable ) + BIORAD_HEADER_LENGTH;

	for (my $i = 0; $i < $numNotes; $i++)
	{
		$file -> setCurrentPosition($offset);
		$buffer = $file -> readData(NOTES_LENGTH);
		my ($noteType, $line) = unpack($template, $buffer);
		
		# if $noteType is a note type variable, store it into the hash and reference it by making its
		# uppercase name the key
		if ($noteType == NOTE_TYPE_VARIABLE)
		{
			if( $line =~ m/^([A-Z_0-9]+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)/ )
			{
	 			$imageTable->{ $1 } = "$2 $3 $4 $5";
			}
			elsif( $line =~ m/^([A-Z_0-9]+)\s(\S+)\s(\S+)/ )
			{
	 			$imageTable->{ $1 } = "$2 $3";
			}
			elsif( $line =~ m/^([A-Z_0-9]+)\s=\s(\S+)/ )
			{
	 			$imageTable->{ $1 } = "$2";
			}
			elsif( $line =~ m/^([A-Z_0-9]+)\s(\S+)/ )
			{
	 			$imageTable->{ $1 } = "$2";
			}
		}
		
		$offset += NOTES_LENGTH;
	}
	
	return $imageTable;
}

# Convert the text of the notes into metadata valuable to preserving
# all aspects of the image
sub interpretNotesData
{
	my $imageTable = shift;
	my $version = $imageTable -> { 'PIC_FF_VERSION' };
	if ( defined($version) )
	{
		$version =~ m/=\s(\S{3})/;
		$version = $1;
	}
	else
	{
		$version = 0;
	}

	my $npic = $imageTable -> { 'SizeZ' };

	# find the x and y axis spacing (pixelsize) -- AXIS_2 is x, AXIS_3 is y
	my $axisValue = $imageTable -> { 'AXIS_2' };
	if ($axisValue)
	{
		$axisValue =~ m/^(\d+)\s(\S+)\s(\S+)\s(\S+)/;

		my $type = $1;
		my $increment = $3;
			
		$increment =~ m/^(\d+.\d+)\S+/;
		
		$imageTable -> { 'PixelSizeX' } = $1;
		if ($type == 1) { $imageTable -> { 'PixelSizeX' } = $1; }
	}
	
	$axisValue = $imageTable -> { 'AXIS_3' };
	if ($axisValue)
	{
		$axisValue =~ m/^(\d+)\s(\S+)\s(\S+)\s(\S+)/;
		
		my $type = $1;
		my $increment = $3;
		
		$increment =~ m/^(\d+.\d+)\S+/;
		
		if ($type == 1) { $imageTable -> { 'PixelSizeY' } = $1; }

		# AXIS_2 could be time info. for an XT image, so it'll be in seconds
		elsif ($type == 2) { $imageTable -> { 'SizeT' } = $1; }
	}
	
	# determine what the image is: multi-channel/multi-section etc etc etc!
	my $axisValue9;
	my $axisValue4;
	
	if ($version >= 4.1)
	{
		$axisValue9 = $imageTable -> { 'AXIS_9' };
		$axisValue4 = $imageTable -> { 'AXIS_4' };
	}
	
	else # Axis 9 does not exist before version 4.1
	{
		$axisValue4 = $imageTable -> { 'AXIS_4' };
	}
	
	if ($axisValue4 || $axisValue9)
	{
		my $type4;
		my $origin4;
		my $var3_4;
		my $type9;
		my $origin9;
		my $var3_9;

		if ($axisValue4)
		{
			$axisValue4 =~ m/^(\d+)\s(\S+)\s(\S+)\s(\S+)/ || $axisValue4 =~ m/^(\d+)\s(\S+)\s(\S+)/;
			$type4 = $1;
			$origin4 = $2;
			$var3_4 = $3; # this could be either increment or label, depending on the image type
		}

		if ($axisValue9)
		{
			$axisValue9 =~ m/^(\d+)\s(\S+)\s(\S+)\s(\S+)/ || $axisValue9 =~ m/^(\d+)\s(\S+)\s(\S+)/;
			$type9 = $1;
			$origin9 = $2;
			$var3_9 = $3;
		}

		if ($axisValue4 && $type4 == 1) # XYZ image -- Z-Series
		{
			$var3_4 -= m/^\d+.\d+/ if defined $3;
			$imageTable -> { 'PixelSizeZ' } = $var3_4;
			$imageTable -> { 'ZSeries' } = 1;
		}

		elsif ($axisValue4 && $type4 == 2) # XYT image -- Sequential Study
		{
			$imageTable -> { 'SizeT' } = $var3_4;
			$imageTable -> { 'ZSeries' } = 0;
		}

		# type 11 is axt_RGB, so the file has multiple channels; axis is 4, so it's single section
		if ($type4 == 11 && $axisValue4)
		{
			$imageTable -> { 'ZSeries' } = 0;
			$imageTable -> { 'MultiChannelSingleSection' } = 1;

			if ($npic == 1)
			{				
				if ($origin4 == 0)
				{
					$imageTable -> { 'ChannelA' } = 1;
					$imageTable -> { 'SizeC' } = 1;
				}
				elsif ($origin4 == 1)
				{
					$imageTable -> { 'ChannelB' } = 1;
					$imageTable -> { 'SizeC' } = 1;
				}
				elsif ($origin4 == 2)
				{
					$imageTable -> { 'ChannelC' } = 1;
					$imageTable -> { 'SizeC' } = 1;
				}
			}
			
			elsif ($npic == 2)
			{
				if ($origin4 == 0 && $var3_4 == 1)
				{
					$imageTable -> { 'ChannelA' } = 1;
					$imageTable -> { 'ChannelB' } = 1;
					$imageTable -> { 'SizeC' } = 2;
				}
				elsif ($origin4 == 1 && $var3_4 == 1)
				{
					$imageTable -> { 'ChannelB' } = 1;
					$imageTable -> { 'ChannelC' } = 1;
					$imageTable -> { 'SizeC' } = 2;
				}
				elsif ($origin4 == 0 && $var3_4 == 2)
				{
					$imageTable -> { 'ChannelA' } = 1;
					$imageTable -> { 'ChannelC' } = 1;
					$imageTable -> { 'SizeC' } = 2;
				}
			}
			
			elsif ($npic == 3)
			{
				if ($origin4 == 0 && $var3_4 == 1)
				{
					$imageTable -> { 'ChannelA' } = 1;
					$imageTable -> { 'ChannelB' } = 1;
					$imageTable -> { 'ChannelC' } = 1;
					$imageTable -> { 'SizeC' } = 3;
				}
			}
		}
		
		# the file has multiple channels; axis is 9, so it's multi-section
		if ($type9 == 11)
		{
			$imageTable -> { 'ZSeries' } = 0;
			$imageTable -> { 'MultiChannelMultiSection' } = 1;
			$imageTable -> { 'SingleChannelMultiSection' } = 0;

			if ($origin9 == 0)
			{
				$imageTable -> { 'MixA' } = 1;
			}
			elsif ($origin9 == 1)
			{
				$imageTable -> { 'MixB' } = 1;
			}
			elsif ($origin9 == 2)
			{
				$imageTable -> { 'MixC' } = 1;
			}
		}
	}
	
	return $imageTable;
}


#   Returns the number of notes in this file.  Notes are 96 bytes long.
# 
# 	Usage: my $notes = $importer->getNumNotes($fileObject)
# 
#

sub getNumNotes
{
	my $file = shift;
	my $imageTable = shift;
	my $notes = $imageTable -> { 'NotesExist' };
	
	return 0 if ($notes == 0);
	
	# check to see how many notes there are
	my $actFileSize = $file -> getLength();
	my $xyz = getXYZ( $imageTable );
	$notes = ($actFileSize - $xyz - BIORAD_HEADER_LENGTH) / (NOTES_LENGTH);
	
	return $notes;
}


# - Calculates and returns the file size by getting nx, ny, nz in the first 6 bytes of the
#   header
# - returns a value greater than 0 if the file is valid (value = file length in bytes)
# - returns 0 if the file is invalid or the header has not been read yet
#
# 	Usage: getXYZ($fileObject)
sub getXYZ
{
	my $size = 0;
	my $imageTable = shift;
	
	my $nx = $imageTable -> { 'SizeX' };
	
	if ($nx)
	{
		my $ny = $imageTable -> { 'SizeY' };
		my $nz = $imageTable -> { 'SizeZ' };

		$size = $nx * $ny * $nz;
	}
	return $size;
}


# - Gets the endian type for this image and calls getBioradID to determine if it's a valid file
# - returns a string of "big" or "little" if file's valid
# - returns an empty string "" if file is invalid
# 
# 	Usage: my $endianType = getEndian($filePath)
#
sub getEndian
{
	my $file = shift;
	my $buffer;
	my $endian = "";
	
	$file->setCurrentPosition(0);
    $buffer = $file->readData(BIORAD_HEADER_LENGTH);

	if(getBioradID(BIORAD_BIG_TEMPLATE, $buffer) == BIORADID)
	{
		$endian = "big";
	}
	
	elsif (getBioradID(BIORAD_LITTLE_TEMPLATE, $buffer) == BIORADID)
	{
		$endian = "little";
	}
	return $endian;
}


# - Looks for the tag 12345 in byte 54 (and 55) of the file (2 byte tag)
# - returns the biorad id 12345 if the file's valid
# - returns 0 if it's invalid
#
# 	Usage: my $bioradid = getBioradID($endianTemplate, $buffer)
#
sub getBioradID
{
	my $template = shift;
	my $buffer = shift;
	my $bioradid = 0;
	my @bytelist;
	
	@bytelist = unpack($template, $buffer);
	$bioradid = $bytelist[6];
	
	if ($bioradid != BIORADID)
	{ 
		$bioradid = 0;
	}
	return $bioradid;
}

# Get the SHA1's for these files
sub getSHA1
{
    my $self = shift;
    my $fileList = shift;
    foreach my $file (@$fileList)
    {
    	return $file->getSHA1();
    }
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

1;