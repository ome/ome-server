#!/usr/bin/perl -w
#
# DVreader.pm
# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# This class contains the methods for importing a Softworx file.
#

# ---- Public routines -------
# new()
# readTag()
# formatImage()

# ---- Private routines ------
# readUIHdr()
# readUIExtHdr()
# get_jumps()
# get_fmt()

package OME::ImportExport::DVreader;
our @ISA = ("OME::ImportExport::Import_reader");
use strict;
use Carp;
use OME::ImportExport::FileUtils;
use OME::ImportExport::Repacker::Repacker;
use vars qw($VERSION);
$VERSION = '1.0';


my %pix_size = (0=>1, 1=>2, 2=>4, 3=>2, 4=>4);
my @seq_types = (0, 1, 2);


# This hash lists all the DeltaVision fields - their names, types, and lengths
# See IM_ref.html for the complete UI specification.
#
#   Hash tables entry: Tag name, length, type of value: {s, w, f, c}
#
our %tag_table =  (1     => ['NumCol', 4, 'w'],      # Image width
		  2     => ['NumRows', 4, 'w'],      # Image height
		  3     => ['NumSections', 4, 'w'],  # total sections = NumZSec * NumWaves * NumTimes
		  4     => ['PixelType', 4, 'w'],    # 0: 1 byte integer 
		                                     # 1: 2 byte integer
		                                     # 2: 4 byte float 
		                                     # 3: 2 byte complex
						     # 4: 4 byte complex
		  5     => ['mxst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  6     => ['myst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  7     => ['mzst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  8     => ['mx', 4, 'w'],           # Pixel sampling size along X
		  9     => ['my', 4, 'w'],           # Pixel sampling size along Y
		  10    => ['mz', 4, 'w'],           # Pixel sampling size along Z
		  11    => ['dx', 4, 'f'],           # float - X element length in um.
		  12    => ['dy', 4, 'f'],           # float - Y element length in um.
		  13    => ['dz', 4, 'f'],           # float - Z element length in um.
		  14    => ['alpha', 4, 'f'],        # float - X axis angle in degrees
		  15    => ['beta', 4, 'f'],         # float - Y axis angle in degrees
		  16    => ['gamma', 4, 'f'],        # float - Z axis angle in degrees
		  17    => ['colseq', 4, 'w'],       # column axis seq. can be 1, 2, or 3 (default 1)
		  18    => ['rowseq', 4, 'w'],       # row axis seq. can be 1, 2, or 3 (default 2)
		  19    => ['secseq', 4, 'w'],       # section axis seq. can be 1, 2, or 3 (default 3)
		  20    => ['min', 4, 'f'],          # float - min intensity of 1st wavelength image
		  21    => ['max', 4, 'f'],          # float - max intensity of 1st wavelength image
		  22    => ['mean', 4, 'f'],         # float - mean intensity of 1st wavelength image
		  23    => ['nspg', 4, 'w'],         # space group numner - Xtallography
		  24    => ['next', 4, 'w'],         # size, in bytes, of extended header
		                                   # = (NumInts + NumFloats) * NumSections * 4
		  25    => ['dvid', 2, 's'],       # DeltaVision ID (== -16224)
		  26    => ['blank', 30, 'c'],     # blank section - 30 bytes
		  27    => ['NumInts', 2, 's'],      # number of 4 bytes ints in extended header
		  28    => ['NumFloats', 2, 's'],    # number of 4 bytes floats in extended header
		  29    => ['sub', 2, 's'],          # number of sub-resolution data sets. S.B 1
		  30    => ['zfac', 2, 's'],         # Z axis reduction quotient. S.B. 1
		  31    => ['min2', 4, 'f'],         # float - min intensity of 2nd wavelength image
		  32    => ['max2', 4, 'f'],         # float - max intensity of 2nd wavelength image
		  33    => ['min3', 4, 'f'],         # float - min intensity of 3rd wavelength image
		  34    => ['max3', 4, 'f'],         # float - max intensity of 3rd wavelength image
		  35    => ['min4', 4, 'f'],         # float - min intensity of 4th wavelength image
		  36    => ['max4', 4, 'f'],         # float - max intensity of 4th wavelength image
		  37    => ['type', 2, 's'],         # image type  0 - normal, 1 - tilt-series
		                                       # 2- stereo tilt series, 3 - averaged images
		                                       # 4 - average stereo pairs
		  38    => ['lensnum', 2, 's'],      # Lens ID number
		  39    => ['n1', 2, 's'],           # depends on image type
		  40    => ['n2', 2, 's'],           # depends on image type
		  41    => ['v1', 2, 's'],           # depends on image type
		  42    => ['v2', 2, 's'],           # depends on image type
		  43    => ['min5', 4, 'f'],         # float - min intensity of 5th wavelength image
		  44    => ['max5', 4, 'f'],         # float - max intensity of 5th wavelength image
		  45    => ['NumTimes',2, 's'],       # number of time points
		  46    => ['ImgSeq', 2, 's'],        # 0 = ZTW 1 = WZT, 2 = ZWT
		  47    => ['XTilt', 4, 'f'],        # float - X axis tilt (normally 0)
		  48    => ['YTilt', 4, 'f'],        # float - Y axis tilt (normally 0)
		  49    => ['ZTilt', 4, 'f'],        # float - Z axis tilt (normally 0)
		  50    => ['NumWaves', 2, 's'],     # number of wavelengths
		  51    => ['wave1', 2, 's'],        # Wavelength 1, in nm.
		  52    => ['wave2', 2, 's'],        # Wavelength 2, in nm.
		  53    => ['wave3', 2, 's'],        # Wavelength 3, in nm.
		  54    => ['wave4', 2, 's'],        # Wavelength 4, in nm.
		  55    => ['wave5', 2, 's'],        # Wavelength 5, in nm.
		  56    => ['Xorigin', 4, 'w'],      # X origin, in um.
		  57    => ['Yorigin', 4, 'w'],      # Y origin, in um.
		  58    => ['Zorigin', 4, 'w'],      # Z origin, in um.
		  59    => ['NumTitles', 4, 'w'],    # number of titles (0 - 10)
		  60    => ['Title1', 80, 'c'],      # Title 1
		  61    => ['Title2', 80, 'c'],      # Title 2
		  62    => ['Title3', 80, 'c'],      # Title 3
		  63    => ['Title4', 80, 'c'],      # Title 4
		  64    => ['Title5', 80, 'c'],      # Title 5
		  65    => ['Title6', 80, 'c'],      # Title 6
		  66    => ['Title7', 80, 'c'],      # Title 7
		  67    => ['Title8', 80, 'c'],      # Title 8
		  68    => ['Title9', 80, 'c'],      # Title 9
		  69    => ['Title10', 80, 'c'],     # Title 10
		  70    => ['end', 0, 0]           # flags end of hash
	      );

our %xml_image_entries = (NumCol => 'SizeX',
                          NumRows => 'SizeY',     # SizeZ calculated separately
                          NumWaves =>'NumWaves',
                          NumTimes => 'NumTimes',
			  lensnum  => 'LensID',
                          mx       => 'PixelSizeX',
                          my       => 'PixelSizeY',
                          mz       => 'PixelSizeZ'
			  );

my %xml_wavelength_entries = (wave1  => 'EmWave',
			       wave2  => 'EmWave',
			       wave3  => 'EmWave',
			       wave4  => 'EmWave',
			       wave5  => 'EmWave'
			       );

sub new {

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};
    $self->{parent} = shift;

    return bless $self, $class;

    };


# Read in the DeltaVision image metadata
sub readImage {
    my $self = shift;     # Ourselves
    my $parent = $self->{parent};
    my $fh    = $parent->fref;
    my $sz;
    my $len;
    my $img_len;
    my $calc_len;
    my ($numsecs, $numflds);
    my $k;
    my $pix_OK = 0;
    my $seq;
    my $seq_OK = 0;

    $len = -s $fh;

    croak "Image::UIreader must be called from Import_reader or other class"
	unless ref($self);

    # Read the DeltaVision fixed header
    my $status = readUIHdr($self, $fh,
			   $parent->{endian},
			   $parent->{offset});
    return($status)
	unless ($status eq "");

    # check that PixelType has a valid value
    foreach $sz (keys %pix_size) {
	if ($sz == $self->{"PixelType"}) {
	    $pix_OK = 1;
	    last;
	}
    }
    return ($status = "Bad pixel type")
	unless $pix_OK == 1;

    # check that ImgSeq has a value this program supports
    foreach $seq (@seq_types) {
	if ($seq == $self->{"ImgSeq"}) {
	    $seq_OK = 1;
	    last;
	}
    }
    return ($status = "Unsupported bit plane order: $self->{'ImgSeq'}")
	unless $seq_OK == 1;

    # Calculate & verify image length & total file size;
    $img_len = $self->{NumCol} * $self->{NumRows} * $self->{NumSections};
    $img_len *= $pix_size{$self->{"PixelType"}};   # Calculate size of image
    $calc_len = 1024 + $self->{next} + $img_len;   # + hdr + extended hdrs = file size
    return ($status = "File wrong size")
	unless $len == $calc_len;

    # Read in the extended header segments
    $numsecs = $self->{NumSections};                   # number of planes in image
    $numflds = $self->{NumInts} + $self->{NumFloats};  # number of fields per plane
    $status = readUIExtHdrs($self, $fh, $parent->{endian}, $numsecs, $numflds, 1024);

    return $status;

}



sub formatImage {
    my $self = shift;     # Ourselves
    my $parent = $self->{parent};

    my $fih    = $parent->fref;
    my $foh    = $parent->fouf;
    my $xyzwt  = $parent->obuffer;
    my $endian = $parent->endian;
    my $xml_hash = $parent->Image_reader::xml_hash;
    my @obuf;
    my ($ibuf, $rowbuf);
    my ($i, $j, $k, $row);
    my $status;
    my $start_offset;
    my ($row_size, $plane_size);
    my $pixsz = $pix_size{$self->{"PixelType"}};
    my ($t_jump, $w_jump, $z_jump);
    my ($offset, $t_offset, $w_offset, $z_offset);
    my $order = $self->{ImgSeq};                 # 0 = XYZTW 1 = XYWZT, 2 = XYZWT
    my $rows = $self->{NumRows};
    my $cols = $self->{NumCol};
    my $waves = $self->{NumWaves};
    my $times = $self->{NumTimes};
    my $sections = $self->{NumSections};
    my $zs = ($sections/$waves)/$times;         # number of Z steps in a stack

    $parent->{pixel_size} = $pixsz * 8;
    $row_size   = $cols * $pixsz;               # size of an X vector (row)
    $plane_size = $rows * $row_size;            # size of 1 XY plane

    print STDERR "Times: $times, waves:$waves, zs: $zs, rows: $rows, cols: $cols, sections: $sections\n";
    # Start at begining of image data
    $start_offset = 1024 + $self->{next};

    # get offsets between consequtive time, wave, and Z sections in the file
    ($status, $t_jump, $w_jump, $z_jump) = get_jumps($times, $waves, $zs, $plane_size, $order);
    return $status
	unless $status eq "";
    
    # Read image out of the input file & arrange it in
    # our canonical XYZWT order.
    #print "   DVreader start read loop: ".localtime."\n";
    for ($i = 0; $i < $times; $i++) {
	$t_offset = $start_offset + $i * $t_jump;
	my @xyzw;
	for ($j = 0; $j < $waves; $j++) {
	    $w_offset = $t_offset + $j * $w_jump;
	    my @xyz;
	    for ($k = 0; $k < $zs; $k++) {
		$offset = $w_offset + $k * $z_jump;
		my @xy;
		for ($row = 0; $row < $rows; $row++) {
		    $status = OME::ImportExport::FileUtils::seek_and_read($fih, \$ibuf, $offset, $row_size);
		    last
			unless $status eq "";

		    my $cnt = Repacker::repack($ibuf, $row_size, 
				     $pix_size{$self->{"PixelType"}},
				     $endian eq "little",
				     $parent->{host_endian} eq "little");
		    push @xy, $ibuf;
		    $offset += $row_size;
		}
		push @xyz, \@xy;
	    }
	    push @xyzw, \@xyz;
	}
	push @$xyzwt, \@xyzw;
    }
    #print "   DVreader end read loop: ".localtime."\n";

    if ($status eq "") {
	
    }

    return $status;
}


sub readUIHdr {
    my $self = shift;
    my $fh = shift;
    my $endian = shift;
    my $offset = shift;
    my $parent = $self->{parent};
    my $xml_hash = $parent->Image_reader::xml_hash;
    my $i;
    my $len;
    my $rdlen;
    my $typ;
    my $k;
    my $xel;
    my $buf;
    my $fmt;
    my $val;
    my $status;
    my $w_aref = [];

    $status = OME::ImportExport::FileUtils::seek_it($fh, $offset);
    return ($status)
	unless $status eq "";

    for ($i = 1; ($k = $tag_table{$i}[0]) ne 'end'; $i++) {
	$len = $tag_table{$i}[1];
	$typ = $tag_table{$i}[2];
	$status = OME::ImportExport::FileUtils::read_it($fh, \$buf, $len);
	last
	    unless $status eq "";
	$fmt = get_fmt($typ, $endian);
	$fmt =~ s/^(.)$/$1$len/;
	$val = unpack($fmt, $buf);
	$self->{$k} = $val;
    }
    # Put relevant pieces of metadata into xml_elements for later DB storage
    foreach $k (keys %xml_image_entries) {
	$xel = $xml_image_entries{$k};
	$xml_hash->{"Image.".$xel} = $self->{$k};
    }

    # Make one WavelengthInfo element per wavelength in image
    $i = 1;
    foreach $k (sort keys %xml_wavelength_entries) {
	if ($i > $self->{'NumWaves'}) {
	    last;
	}
	my $whref = {};
	$xel = $xml_wavelength_entries{$k};
	$whref->{'WavelengthInfo.'.$xel} = $self->{$k};
	# IGG 10/06/02:  The wavenumbers start at 0 in OME.
	$whref->{'WavelengthInfo.WaveNumber'} = $i-1;
	#print "WavelengthInfo."."$xel = ". $whref->{'WavelengthInfo.'.$xel}."\n";
	push @$w_aref, $whref;
	$i++;
    }
    $xml_hash->{'WavelengthInfo.'} = $w_aref;

    $i = $self->{NumSections}/$self->{NumWaves};
    $i /= $self->{NumTimes};
    $xml_hash->{'Image.SizeZ'} = $i;

    return $status;
}



sub readUIExtHdrs {
    my $self = shift;
    my $fh = shift;
    my $endian = shift;
    my $numsecs = shift;
    my $numflds = shift;
    my $offset = shift;
    my $parent = $self->{parent};
    my $numInts;
    my $numFlts;
    my $i;
    my $buf;
    my $val;
    my $flt;
    my $len;
    my $rdlen;
    my $curpos;
    my $status;
    my $ctmp;
    my ($c0, $c1, $c2, $c3);
    my @cs;

    $status = OME::ImportExport::FileUtils::seek_it($fh, $offset);
    return ($status)
	unless $status eq "";
    $numInts = $self->{NumInts};
    $numFlts = $self->{NumFloats};
    $status = "File read error";
    $numsecs = $self->{NumSections};
    $len = 4;                                  # Every field in the ext. hdr is 4 bytes long
    $curpos = tell $fh;
    while ($numsecs--) {
	#skip over the integers in the Ext hdr (they're always 0)
	last
	   unless (seek($fh, $numInts * $len, 1));
	#print "\n";

	$status = "File read error";
	for ($i = 0; $i < $numFlts; $i++) {
	    $status = OME::ImportExport::FileUtils::read_it($fh, \$buf, $len);
	    last
		unless ($status eq "");
	    $val = unpack("f", $buf);
	    if ($endian ne $parent->Image_reader::host_endian) {
		$val = $parent->SUPER::flip_float($val);
	    }
	    if ($i < 13) {  # only the 1st 13 floats are interesting
		#printf("flt: %g, ", $val);
	    }
	}
	#print "\n";
    }
    $curpos = tell $fh;
    return ($status = "");
}





# This routine returns the number of bytes between consequtive
# times, waves, and Z planes in an input imaqe file. These will
# allow the reader to position to the next segment to extract
# the image in XYZWT order.

sub get_jumps {
    my ($times, $waves, $zs, $plane_size, $order) = @_;
    my $status = "";
    my ($t_jump, $w_jump, $z_jump);

    # Get input file step offsets as we step thru extracting in XYZWT order
    if ($order == 0) {     # input is in XYZTW order
	$t_jump = $zs * $plane_size;
	$w_jump = $zs * $times * $plane_size;
	$z_jump = $plane_size;
    }
    elsif ($order == 1) {  # input is in XYWZT order
	$t_jump = $waves * $zs * $plane_size;
	$w_jump = $plane_size;
	$z_jump = $waves * $plane_size;
    }
    elsif ($order == 2) {  # input is in XYZWT order
	$t_jump = $waves * $zs * $plane_size;
	$w_jump = $zs * $plane_size;
	$z_jump = $plane_size;
    }
    else {
	$status = "Impossible image type value: $order";
    }

    return ($status, $t_jump, $w_jump, $z_jump);
}


# Helper routine to return the proper format character for unpacking header fields,
# depending upon the length of the field & the endian-ness of the source

sub get_fmt {
    my $type = shift;
    my $endian = shift;
    my $fmt = "";

    if ($type eq 'c') {       # character type
	$fmt = "A";
    }
    elsif (($type eq 'w') || ($type eq 'f')) {    # 'word'or 'float' type - 4 bytes
	$fmt =  $endian eq "little" ? "V" : "N";
    }
    elsif ($type eq 's') {    # 'short' type - 2 bytes
	$fmt = $endian eq "little" ? "v" : "n";
    }

    return $fmt;              # no error checking
}



1;
