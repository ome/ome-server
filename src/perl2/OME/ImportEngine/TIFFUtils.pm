# OME/ImportEngine/TIFFUtils.pm
#
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


=head1 NAME

 OME::ImportEngine::TIFFUtils - contains helper routines for TIFF tag access


=head1 SYNOPSIS

  use OME::ImportEngine::TIFFUtils 

=cut



package OME::ImportEngine::TIFFUtils;

use strict;
use OME;
use Carp;
use Carp qw'cluck';
our $VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);

our @EXPORT = qw(readTiffIFD verifyTiff getStrips TAGS LITTLE_ENDIAN BIG_ENDIAN);

use constant LITTLE_ENDIAN => 0;
use constant BIG_ENDIAN    => 1;

use constant _x => ['v','n'];
use constant _X => ['V','N'];
use constant _XX => ['VV','NN'];
use constant _xxXX => ['vvVV','nnNN'];
use constant _xxXx => ['vvVv','nnNn'];

use constant TAG_BYTE => 1;
use constant TAG_ASCII => 2;
use constant TAG_SHORT => 3;
use constant TAG_LONG => 4;
use constant TAG_RATIONAL => 5;
use constant TAG_SIZES => [0,1,0,2,4,8];
use constant TAG_FORMATS => [['_','_'],['c','c'],['_','_'],_x,_X,_XX];

=head2 constant TAGS

This set of constants associates meaningful names to standard TIFF
tag values.

=cut

use constant TAGS =>
  {
   'SubFile' => 254,            #Start of image marker
   'SubfileType' => 255, #1 = full res., 2=reduced res., 3=single page of multi-page image - see PageNumberField
   'ImageWidth' => 256,
   'ImageLength' => 257,
   'BitsPerSample' => 258,
   'Compression' => 259, # 1=none, 2=CCITT ID 3=Grp3 Fax 4=Grp4 Fax, 5=LZW, 6=JPEG, 32773=PackBits
   'PhotometricInterpretation' => 262,
   'Threshholding' => 263, #1=no dithering/halftone, 2=ordered dither/halftone, 3=randomize process)
   'CellWidth' => 264,
   'CellLength' => 265,
   'FillOrder' => 266,
   'DocumentName' => 269,
   'ImageDescription' => 270,
   'Make' => 271,
   'Model' => 272,
   # ONLY WAY TO FIND IMAGE DATA
   'StripOffsets' => 273, # offset to image data strip - one value per strip 
   'Orientation' => 274,        # 1=starts at top row, left column
   'SamplesPerPixel' => 277,    # Usually 3 for RGB, else usually 1
   'RowsPerStrip' => 278,
   'StripByteCounts' => 279,  # How many bytes/strip after compression
   'MinSampleValue' => 280,
   'MaxSampleValue' => 281,
   'XResolution' => 282,
   'YResolution' => 283,
   'PlanarConfig' => 284,       # 1=chunky format (recommended)
   'PageName' => 285,
   'XPos' => 286,
   'YPos' => 287,
   'FreeOffsets' => 287,
   'FreeByteCnt' => 287,
   'GrayResponseUnit' => 290,
   'GrayResponseCurve' => 291,
   'T4Options' => 292,
   'T6Options' => 293,

   'ResolutionUnit' => 296,     # 1=No absolute, 2=Inch, 3=cm.
   'PageNumber' => 297,
   'TransferFunction' => 301,

   # StripsPerImage = floor((ImageLen + RowsPerStrip-1)/RowsPerStrip),
   'Software' => 305,           #Name/version of s/w pkg to make image
   'DateTime' => 306,           # YYYY:MM:DD HH:MM:SS
   'Artist' => 315,
   'Host' => 316,
   'Predictor' => 317,
   'WhitePoint' => 318,
   'PrimaryChroma' => 319,
   'ColorMap' => 320,
   'Halftone Hints' => 321,
   'TileWidth' => 322,
   'TileLength' => 323,
   'TileOffsets' => 324,
   'TileByteCounts' => 325,
   'InkSet' => 332,
   'InkNames' => 333,
   'NumberOfInks' => 334,
   'DotRange' => 336,
   'TargetPrinter' => 337,
   'ExtraSamples' => 338,
   'SampleFormat' => 339,
   'SMinSampleValue' => 340,
   'SMaxSampleValue' => 341,
   'TransferRange' => 342,
   'JPEGTables' => 347,
   'JPEGProc' => 512,
   'JPEGInterchangeFormat' => 513,
   'JPEGInterchangeFormat' => 514,
   'JPEGRestartInterval' => 515,
   'JPEGLosslessPredictors' => 517,
   'JPEGPointTransforms' => 518,
   'JPEGQTables' => 519,
   'JPEGDCTables' => 520,
   'JPEGACTables' => 521,
   'YCbCrCoefficients' => 529,
   'YCbCrSubSampling' => 530,
   'YCbCrPositioning' => 531,
   'Copyright' => 33432,
  };

use constant MAX_TIFF_TAG => 33342;

my $tagHash = TAGS;
my %tagnames = reverse %$tagHash;
my $dumpHeader = 0;
my $tag_hash;

# Derived from Import_read->checkTIFF, TIFFreader->readTiffIFD, and
# TIFFreader->readTiffTag
#
# Reads a file that may be a TIFF file. It will return either 'undef'
# if the file is not any sort of TIFF file (or a broken TIFF file), or
# a reference to an IFD hash.

=head2 readTiffIFD

This function can be called in three different ways:
	%tag  = readTiffIFD($file);
	%tag  = readTiffIFD($file,3);
	@tags = readTiffIFD($file);
	
This function first examines the file at the passed file handle to
determine if it is a TIFF file. If it isn't, the routine immediately 
returns I<undef>.

If the file is a TIFF, the routine walks the file collecting tags and 
their values. Any tag whose key exists in the constants hash TAGS 
will have its id and value recorded. Any tag whose key does not have an entry 
in TAGS will have its id, type, count, and offset recorded in the return hash. 
This allows TIFF variant format importers to access and parse for custom tags.

This function can be called in the scalar context without explicitely specifying
which IFD's tags to return. Then this function returns the 0 IFD directory as a 
hash of tags.

If the function is called in the scalar contex and the the target IFD directory 
is specified, only the tags from that directory will be returned.

If the function is called in the list context, it returns an array of hashes where
each hash corresponds to the tags of an IFD directory. Ipso facto, the length of 
the returned array is equal to the number of IFD directories in the image.

This function uses a caching mechanism keyed on the SHA1 digest of the passed in 
file. So if you call readTiffIFD on the same file, the subsequent times the tags 
are returned from memory. The cache is cleaned out when image format importers's 
cleanup() methods call OME::ImportEngine::TIFFUtils::cleanup(). 

Caching is neccesitated by the extremely slow speed with which this utility reads 
tiff tags. Reading 700 planes (approximately 5000 tags) takes 25 minutes. 
libtiff's tiffdump utility processes the same amount of tags in less than 10 seconds.

However calls to readTiffIFD where the target IFD directory is explicitely specified,
are not cached.

=cut

sub readTiffIFD {
    my $file = shift;
    my $targetIFD = shift;
    my ($buf,$endian,@buf,$offset);
    
    # Read the TIFF header to determine endianness and to locate the first IFD.
    ($endian, $offset) = __verifyTiff($file);
    return undef unless defined($endian);

    my @IFDs;
    
    # CACHING: check if we previously read-in this file's TIFF tags 
    # If so, don't read the tags again, but return the cached tags
    my $sha1 = $file->getSHA1();
    if (exists $tag_hash->{$sha1} and not $targetIFD) {
  		my $IFD_ref =  $tag_hash->{$file->getSHA1()};
  		
  		# did we already compute only the first IFD or all IFDs ? 		
  		if (ref $IFD_ref eq 'ARRAY') {		
			@IFDs = @$IFD_ref;
		}
			
		if (wantarray) {
			return @IFDs if @IFDs;
		} else {
			return ($IFDs[0]) if @IFDs;
			return ($IFD_ref);
		}
	}

    # Read in each IFD
    my $currentIFD = 0;
    while ($offset > 0) {
    	
    	eval {
            my %ifd;
            $ifd{__Endian} = $endian;
            $file->setCurrentPosition($offset,0);
			
            # Read the number of tags in this IFD
            $buf = $file->readData(2);
            my $tag_count = unpack(_x->[$endian],$buf);
			
			# read the IFD
			if (wantarray or not $targetIFD or $targetIFD == $currentIFD) {
				while ($tag_count) {

					# Read the tag
					my $tell = $file->getCurrentPosition();
					$buf = $file->readData(12);
	
					my ($tag_id,$tag_type,$value_count,$value_offset) =
					  unpack(_xxXX->[$endian],$buf);
	
					if ($dumpHeader) { my $tagname = $tagnames{$tag_id}; $tagname = "unknown tag" unless defined($tagname); print STDERR "tag: $tag_id = $tagname, "; }
	
					# Single short values are stored, in the tag's value_offset field
					if (($tag_type == TAG_SHORT) && ($value_count == 1)) {
						($tag_id,$tag_type,$value_count,$value_offset) =
						  unpack(_xxXx->[$endian],$buf);
					}
	
					my @values;

					# if tag is > max TIFF tag, the file might still be a TIFF variant.
					# save tag for tiff variant importers to chew on
					if ($tag_id > MAX_TIFF_TAG) {
						push @{$ifd{$tag_id}},
						  {'tag_id' => $tag_id,
						   'tag_type' => $tag_type,
						   'value_count' => $value_count,
						   'value_offset' => $value_offset,
						   'current_offset' => $file->getCurrentPosition()};

						if ($dumpHeader) { print STDERR " type: $tag_type, count: $value_count, offset: $value_offset\n\t\t"; @values = getTagValue($file, $tag_type, $value_count,$value_offset, $endian); }
					} else {
						if ($tag_type == TAG_BYTE  || $tag_type == TAG_ASCII ||
							$tag_type == TAG_SHORT || $tag_type == TAG_LONG  || 
							$tag_type == TAG_RATIONAL) {
								@values = getTagValue($file, $tag_type, $value_count, $value_offset, $endian);
								push @{$ifd{$tag_id}}, @values;
							} else {
								push @{$ifd{$tag_id}},
								  {'tag_id' => $tag_id,
								   'tag_type' => $tag_type,
								   'value_count' => $value_count,
								   'value_offset' => $value_offset,
								   'current_offset' => $file->getCurrentPosition()};
							}
					}
					$tag_count--;
				}
				push (@IFDs,\%ifd);
				
				# Read the offset to the next IFD.
         	    $buf = $file->readData(4);
            	$offset = unpack(_X->[$endian],$buf);
            } else { 
            	# don't read the IFD but skip to the next IFD
            	$file->setCurrentPosition(12*$tag_count,1);
            	$buf = $file->readData(4);
            	$offset = unpack(_X->[$endian],$buf);
            }            
        };
		if ($@) {
			warn $@;
			return undef;
		}
		
        last if (not wantarray and not $targetIFD); # exit loop if only want IFD 0
        last if ($targetIFD == $currentIFD);        # exit loop if found IFD looking for
        
        $currentIFD++;
    }

	if ($targetIFD and $targetIFD > $currentIFD) { 
		croak "in readTiffIFD, specified targetIFD is greater than number of IFDs\n";
	}

	# CACHING: log this image's IFD tag array.
    if (wantarray) {
    	$tag_hash->{$sha1} = \@IFDs;    # store reference to list
        return (@IFDs);
    } elsif (not $targetIFD) {
        $tag_hash->{$sha1} = $IFDs[0];  # store reference to hash
        return $IFDs[0];
    } else {
    	return $IFDs[0]; # return without caching
  	}
}

=head2 getTagValue

Routine to extract & return value(s) from one tag

=cut

sub getTagValue {
    my ($file, $tag_type, $value_count, $value_offset, $endian) = @_;
    my $buf;
    my @vals;

    eval {
        if ($tag_type == TAG_ASCII) {
            $buf = readASCIITag($file, $value_count, $value_offset);
            push @vals, $buf;
        } elsif ((($tag_type == TAG_BYTE) && ($value_count <= 4)) ||
                 (($tag_type == TAG_SHORT) && ($value_count <= 2)) ||
                 (($tag_type == TAG_LONG) && ($value_count == 1))) {

            # If values are few enough & short enough, they are placed
            # directly in the offset field, per the TIFF spec.
            $file->setCurrentPosition(-4,1);
            $buf = $file->readData(4);

            my $fmt = TAG_FORMATS->[$tag_type]->[$endian].$value_count;
            my ($v1, $v2, $v3, $v4) = unpack($fmt, $buf);
            foreach my $v ($v1, $v2, $v3, $v4) {
                if (defined $v) {
                    push @vals, $v
                } else {
                    last;
                }
            }
        } else {
            #else, the tag's values form a list starting at 'offset'.
            my $tell = $file->getCurrentPosition();

            while ($value_count--) {
                $file->setCurrentPosition($value_offset);
                $buf = $file->readData(TAG_SIZES->[$tag_type]);

                $value_offset += TAG_SIZES->[$tag_type];
                my ($val1,$val2) =
                  unpack(TAG_FORMATS->[$tag_type]->[$endian],$buf);
                my $value =
                  ($tag_type == TAG_RATIONAL)? $val1/$val2: $val1;

                push @vals, $value;
            }

            $file->setCurrentPosition($tell);
        }
        if ($dumpHeader) {
            print "@vals\n";
        }
    };

    print "$@\n" if $@;
    return undef if $@;
    return @vals;
}


=head2 readASCIITag

Routine to extract and return the value from a tag marked as ASCII type.

=cut

sub readASCIITag {
    my ($file, $count, $offset) = @_;
    my $buf;

    eval {
        # <= 4 bytes stored directly in offset field, per TIFF specs
        if ($count <= 4) {
            $file->setCurrentPosition(-4,1);
            $buf = $file->readData(4);
        } else {
            my $tell = $file->getCurrentPosition();
            $file->setCurrentPosition($offset,0);
            $buf = $file->readData($count);
            $file->setCurrentPosition($tell,0);
        }
    };

    return undef if $@;
    return $buf;
}



=head2 verifyTiff

This routine reads the first bytes of a file, and verify that
they adhere to the TIFF specs for the first 14 bytes of a file.
If they don't, this routine returns undef, else it returns
the endianess of the file -- big or little.

=cut

sub verifyTiff {
    my $file = shift;
    my ($endian) = __verifyTiff($file);
    return $endian;
}



sub __verifyTiff {
    my $file = shift;
    my ($buf,$endian,@buf,$offset);

    # Read the TIFF header to determine endianness and to locate the
    # first IFD.

    eval {
        $file->setCurrentPosition(0,0);
        $buf = $file->readData(8);
        @buf = unpack('CCvV',$buf);

        if ($buf[0] == 73 && $buf[1] == 73 && $buf[2] == 42) {
            $endian = LITTLE_ENDIAN;
            $offset = $buf[3];
        } elsif ($buf[0] == 77 && $buf[0] == 77) {
            @buf = unpack('CCnN',$buf);
            if ($buf[2] == 42) {
                $endian = BIG_ENDIAN;
                $offset = $buf[3];
            } else {
                return undef;
            }
        } else {
            return undef;
        }
    };

    if ($@) {
        warn $@;
        return undef;
    }
    return ($endian, $offset);
}


=head2 getStrips

This helper routine returns an array of TIFF strip offsets and TIFF 
strip counts to its caller. A strip offset records the offset of the
begining of the strip from the begining of the file. A strip count
records the length of the associated strip. The two arrays should be
used in tandem - the strip at array offset I<n> in the offset array
has the length recorded at array offset I<n> in the counts array.

=cut

# Return image strip offsets and bytecounts arrays
sub getStrips {
    my $tags = shift;
    my ($offs_arr, $counts_arr);

    $offs_arr = $tags->{TAGS->{'StripOffsets'}};     # offsets to start of each TIFF image strip
    $counts_arr = $tags->{TAGS->{StripByteCounts}};  # how long the strip is
    return($offs_arr, $counts_arr);
} 


=head2 initDump

# Set dump flag to 1, which enables printing out header info

=cut

sub initDump {
    $dumpHeader = 1;
}

=head2 cleanup
This function frees all the memory allocated for TIFF IFD tag caching
=cut
sub cleanup {
	my ($file) = shift;
	
	if (defined $file) {
		    delete ($tag_hash->{$file->getSHA1()});
	} else {
		$tag_hash = undef;
	}
}


=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::ImportEngine::AbstractFormat|OME::ImportEngine::AbstractFormat>

=cut

1;
