# OME/ImportEngine/TIFFUtils.pm
#
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


=head1 NAME

 OME::ImportEngine::TIFFUtils - contains helper routines for TIFF tag access


=head1 SYNOPSIS

  use OME::ImportEngine::TIFFUtils 

=cut



package OME::ImportEngine::TIFFUtils;

use strict;
our $VERSION = 2.000_000;

use Exporter;
use base qw(Exporter);

our @EXPORT = qw(readTiffIFD getStrips TAGS LITTLE_ENDIAN BIG_ENDIAN);

use constant BIG_ENDIAN => 0;
use constant LITTLE_ENDIAN => 1;
use constant _x => ['n','v'];
use constant _X => ['N','V'];
use constant _XX => ['NN','VV'];
use constant _xxXX => ['nnNN','vvVV'];

use constant TAG_BYTE => 1;
use constant TAG_ASCII => 2;
use constant TAG_SHORT => 3;
use constant TAG_LONG => 4;
use constant TAG_RATIONAL => 5;
use constant TAG_SIZES => [0,1,0,2,4,8];
use constant TAG_FORMATS => [['_','_'],['c','c'],['_','_'],_x,_X,_XX];

=head2 constant TAGS

This set of contants associates meaningful names to standard TIFF
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

# Derived from Import_read->checkTIFF, TIFFreader->readTiffIFD, and
# TIFFreader->readTiffTag
#
# Reads a file that may be a TIFF file. It will return either 'undef'
# if the file is not any sort of TIFF file (or a broken TIFF file), or
# a reference to an IFD hash.

=head2 readTiffIFD

This routine first examines the file at the passed file handle to
determine if it is or is not a TIFF file. If it isn't, the routine
immediately returns I<undef>.

If the file is TIFF, the routine walks the file collecing tags and 
thier values. Any tag whose key lives in the constants hash TAGS 
will have its id and value recorded in a return hash. Any tag whose key does
not have an entry in TAGS will have its id, type, count, and offset
recorded in the return hash. This latter action allows TIFF variant format
importers to access possible custom tags.

When this routine has exhausted all the tags in the passed file, it returns
the return tag hash it has been accumulating.

=cut

sub readTiffIFD (*) {
    my ($fh) = shift;
    my ($buf,$endian,@buf,$offset);

    # Read the TIFF header to determine endianness and to locate the
    # first IFD.

    seek($fh,0,0) or return undef;
    read($fh,$buf,8) or return undef;
    @buf = unpack('CCvV',$buf);

    if ($buf[0] == 73 && $buf[1] == 73 && $buf[2] == 42) {
        $endian = LITTLE_ENDIAN;
        $offset = $buf[3];
        #print STDERR "Found little endian - $offset\n";
    } elsif ($buf[0] == 77 && $buf[0] == 77) {
        @buf = unpack('CCnN',$buf);
        if ($buf[2] == 42) {
            $endian = BIG_ENDIAN;
            $offset = $buf[3];
            #print STDERR "Found big endian - $offset\n";
        } else {
            return undef;
        }
    } else {
        return undef;
    }

    my %ifd;
    $ifd{__Endian} = $endian;

    # Read in each IFD

    while ($offset > 0) {
        #print STDERR "IFD at offset $offset\n";
        seek($fh,$offset,0) or return undef;

        # Read the number of tags in this IFD
        read($fh,$buf,2) or return undef;
        my $tag_count = unpack(_x->[$endian],$buf);

        #print STDERR "  $tag_count tags\n";

        while ($tag_count) {
            # Read the tag
	    my $tell = tell($fh);
            read($fh,$buf,12) or return undef;

            my ($tag_id,$tag_type,$value_count,$value_offset) =
              unpack(_xxXX->[$endian],$buf);

            my @value;

	    # if tag is > max TIFF tag, the file may
	    # still be a TIFF variant
	    if ($tag_id > MAX_TIFF_TAG) {
		push @{$ifd{$tag_id}}, {'tag_id' => $tag_id,
					'tag_type' => $tag_type,
					'value_count' => $value_count,
					'value_offset' => $value_offset};
	    }
	    else {
		return undef
		    if ($tag_type != TAG_BYTE &&
			$tag_type != TAG_ASCII &&
			$tag_type != TAG_SHORT &&
			$tag_type != TAG_LONG &&
			$tag_type != TAG_RATIONAL);



		if ($tag_type == TAG_ASCII) {
		    # If this is an ASCII string, read $value_count bytes
		    # from the offset directly into the value.
		    
		    $tell = tell($fh);
		    seek($fh,$value_offset,0) or return undef;
		    read($fh,$buf,$value_count) or return undef;
		    seek($fh,$tell,0) or return undef;

		    push @{$ifd{$tag_id}}, $buf;
		} elsif ($value_count == 1 && $tag_type != TAG_RATIONAL) {
		    # If this is a simple type, with only a single value,
		    # that value is stored directly in the offset field.
		    push @{$ifd{$tag_id}}, $value_offset;
		} else {
		    # Otherwise read a list of values
		    my $tell = tell($fh);
		    seek($fh,$value_offset,0) or return undef;
		    
		    while ($value_count) {
			read($fh,$buf,TAG_SIZES->[$tag_type]) or return undef;
			my ($val1,$val2) =
			    unpack(TAG_FORMATS->[$tag_type]->[$endian],$buf);
			my $value =
			    ($tag_type == TAG_RATIONAL)? $val1/$val2: $val1;
			
			push @{$ifd{$tag_id}}, $value;
			$value_count--;
		    }
		    
		    seek($fh,$tell,0);
		}
		
		#push @{$ifd{$tag_id}}, @value;
	    }
            $tag_count--;
        }

        # Read the offset to the next IFD.
        read($fh,$buf,4) or return undef;
        $offset = unpack(_X->[$endian],$buf);
    }

    return \%ifd;
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


=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::ImportEngine::AbstractFormat|OME::ImportEngine::AbstractFormat>

=cut

1;
