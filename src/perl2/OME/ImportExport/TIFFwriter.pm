#!/usr/bin/perl -w
#
# OME/ImportExport/TIFFwriter.pm
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

# This class contains the methods to export a TIFF format file from an OME
# image


# ---- Public routines -------
# new()
# export()

# ---- Private routines ------
# exportImage()
# writeTiffHdr()
# writeTiffPix()
# Hdr_subfile()
# Hdr_sizeX()
# Hdr_sizeY()
# Hdr_bps()
# Hdr_compression()
# Hdr_photointerp()
# Hdr_stripoffset()
# Hdr_rowsPerStrip()
# Hdr_stripByteCounts()
# Hdr_xresolution()
# Hdr_yresolution()
# Hdr_resolutionUni()
# makeRatTbl()

package OME::ImportExport::TIFFwriter;
our @ISA = ("IO::Seekable", "OME::ImportExport::Exporter", "OME::ImportExport::Export_writer");
use strict;
use Carp;
use IO::Seekable;
use IO::File;
use OME::ImportExport::FileUtils;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

# for remembering header file positions
my $num_IFD_entries;
my $stripOffset_pos;
my $byteCount_pos;
my $eof_fld;
my $eof_pos;
my $eof_bcnt = 0;

# for remembering image size info
my ($sizeX, $sizeY, $bps, $byteps, $size);

# for building TIFF file header image
my @hdr;

my @RatTbl = ();

# Keys of this hash are the TIFF tag ID numbers
my %hdr_tags = (254 => 'Subfile',
		256 => 'SizeX',
		257 => 'SizeY',
		258 => 'BitsPerSample',
		259 => 'Compression',
		262 => 'PhotometricInterpretation',
		273 => 'StripOffset',
		277 => 'SamplesPerPixel',
		278 => 'RowsPerStrip',
		279 => 'StripByteCounts',
		282 => 'XResolution',
		283 => 'YResolution',
		296 => 'ResolutionUnit'
		);

# Routine to call to fill in tag info for each TIFF hdr tag field
my %hdr_subs = (Subfile => \&Hdr_subfile,
		SizeX => \&Hdr_sizeX,
		SizeY => \&Hdr_sizeY,
		BitsPerSample => \&Hdr_bps,
		Compression => \&Hdr_compression,
		PhotometricInterpretation => \&Hdr_photointerp,
		StripOffset => \&Hdr_stripoffset,
                SamplesPerPixel => \&Hdr_samplesperpixel,
		RowsPerStrip => \&Hdr_rowsPerStrip,
		StripByteCounts => \&Hdr_stripByteCounts,
		XResolution => \&Hdr_xresolution,
		YResolution => \&Hdr_yresolution,
		ResolutionUnit => \&Hdr_resolutionUnit
		);


sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $self = {};
    $self->{parent} = shift;

    return bless $self, $class;

}


sub export {
    my $status = "";
    my $fih;
    my $image;
    my @image_info;

    my $self = shift;
    my $image_list_ref = shift;
    my $parent = $self->{parent};

    $fih = new IO::File;
    while (scalar @$image_list_ref) {
	my %href;
	my ($x, $y);
	my $pix;     # reference to pixel array
	$image = pop @$image_list_ref;
	$status = $parent->accessImage($image, \%href);
	last
	    unless $status eq "";
	$x = $href{SizeX};
	$x--;
	$y = $href{SizeY};
	$y--;
	$status = $parent->accessImagePix($image, \$pix, 0, $x, 0, $y, 0, 0, 0, 0, 0, 0);
	last
	    unless $status eq "";
	#$pix = GetPixels(0, $x, 0, $y, 0, 0, 0, 0, 0, 0);

	$status = exportImage($self, $image, \%href, $pix);
	last
	    unless $status eq "";
    }

    return $status;

}


sub exportImage {
    my $self = shift;
    my $image = shift;
    my $href = shift;
    my $pix = shift;

    my $fh;
    my $fn = "";
    my $status = "";
    my $parent = $self->{parent};

    $fn = $href->{Name};
    if ($fn eq "") {
	$fn = "image".$image;
    }
    $fn = "OME_".$fn.".tif";
    if ($fh = IO::File->new(">".$fn)) {
	binmode($fh);
	$status = writeTiffHdr($href, $fh, $parent->{endian});
	if ($status eq "") {
	    $status = writeTiffPix($pix, $fh, $parent->{endian}, $byteps);
	}
	$fh->close;
    }

    return $status;
}


sub writeTiffHdr {
    my $href = shift;
    my $fh   = shift;
    my $endian = shift;

    my $buf;
    my ($hdr1, $hdr2);
    my ($fmt, $ratfmt, $offfmt);
    my $sub_name;
    my $fpos;
    my $curpos;
    my $num_entries = 0;
    my $status = "Failed to write file";
    my ($hdr_id, $fname);
    my ($fld_type, $fld_val);

    $offfmt = ($endian eq "little") ? "V" : "N";   # pack formatting for 4-byte integers

    if ($endian eq "little") {
	$hdr1 = 73;  # the ascii value of 'I'
	$hdr2 = 73;
    }
    else {
	$hdr1 = 77;  # the ascii value of 'M'
	$hdr2 = 77;
    }
    # write 1st 8 bytes of tiff file (see Adobe's TIFF6.pdf document)
    $fmt = "CCSLS";
    push @hdr, $hdr1, $hdr2, 42, 8, 0;
    $eof_bcnt += 10;
    $num_IFD_entries = 4;

    # write each required Tiff tag into header
    foreach $hdr_id (sort keys %hdr_tags) {
	$fname = $hdr_tags{$hdr_id};
	$sub_name = $hdr_subs{$fname};
	($fld_type, $fld_val) = &$sub_name($fname, $href, $fh);
	$fmt .= ($endian eq "little") ? "vvVV" : "nnNN";
	push @hdr, $hdr_id, $fld_type, 1, $fld_val;   # hardwired count of 1
	$eof_bcnt += 12;
	$num_entries++;
    }

    # enter # of entries in this IFD in relevant field
    $hdr[$num_IFD_entries] = $num_entries;

    # end of this IFD is offset to next IFD.
    # hardwire to 0 - no more IFDs;
    push @hdr, 0;
    $eof_bcnt += 4;
    $fmt .= $offfmt;

    # Write in values for any rational types
    $ratfmt = ($endian eq "little") ? "VV" : "NN";
    @RatTbl = reverse @RatTbl;
    while (scalar @RatTbl) {
	my $fld_pos = pop @RatTbl;              # saved offset fld position
	my $num = pop @RatTbl;
	my $denom = pop @RatTbl;
	$fmt .= $ratfmt;
	push @hdr, $num, $denom;
	$hdr[$fld_pos] = $eof_bcnt;
	$eof_bcnt += 8;
    }

    # Fill in header offset & bytecount arrays with current EOF & byte count

    # Use following logic if > 1 byteCount value
    #$hdr[$byteCount_pos] = $eof_bcnt;  # where image byte count will be stored
    $size = $sizeX * $sizeY;
    $size *= $byteps;
    #push @hdr, $size;
    $hdr[$byteCount_pos] = $size;
    #$fmt .= $offfmt;
    #$eof_bcnt += 4;
    $hdr[$stripOffset_pos] = $eof_bcnt;
    #$eof_bcnt += 4;                   # where image will start
    #push @hdr, $eof_bcnt;
    #$fmt .= $offfmt;

    $buf = pack($fmt, @hdr);
    if (print ($fh $buf)) {
	$status = "";
    }

    return $status;
}


sub writeTiffPix {
    my $pix    = shift;
    my $fh     = shift;
    my $endian = shift;
    my $byteps    = shift;
    my $fmt;
    my $buf;
    my $status = "Failed to write image in TIFF file";

    #my $i;
    #my $len = length $pix;
    #my $ndx = 0;
    #my $byt;
    #for ($i = 0; $i < $len; $i += 2) {
	#$byt = substr($pix, $i, 1);
	#print $fh $byt;
    #}
    if (print $fh $pix) {
	$status = "";
    }

    return $status;
}


sub Hdr_subfile {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return (4, 0);
}


sub Hdr_sizeX {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    $sizeX = $href->{$fld_name};

    return(4, $sizeX);
}

sub Hdr_sizeY {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    $sizeY = $href->{$fld_name};

    return(4, $sizeY);
}

sub Hdr_bps {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    $bps = $href->{$fld_name};
    $byteps = $bps/8;  # change from bits per sample to byte per sample

    return(3, $bps);
}

# No compression, at least for now
sub Hdr_compression {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return(3,1);
}

# Say that Black is 0
sub Hdr_photointerp {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return(3, 1);
}

# will have to come back after writing pixels & fill this in
sub Hdr_stripoffset {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    $stripOffset_pos = scalar @hdr;
    $stripOffset_pos += 3;
    print "tag position for strip offsets: $stripOffset_pos\n";
    return(4, 0);
}

# only 1 sample per pixel (until we support RGB)
sub Hdr_samplesperpixel {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return (3, 1);
}

# Assume always write whole image as 1 strip
sub Hdr_rowsPerStrip {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return(4, $href->{SizeY});
}

# will have to come back after writing pixels & fill this in
sub Hdr_stripByteCounts {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    $byteCount_pos = scalar @hdr;
    $byteCount_pos += 3;
    print "tag position for byte counts: $byteCount_pos\n";
    return(4, 0);
}

sub Hdr_xresolution {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    makeRatTbl($fh, 72, 1);
    return(5,72);
}

sub Hdr_yresolution {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    makeRatTbl($fh, 72, 1);
    return(5,72);
}

# Return code for "Inch"
sub Hdr_resolutionUnit {
    my $fld_name = shift;
    my $href = shift;
    my $fh   = shift;

    return(3, 2);
}

# Save location of this tag's offset field, plus 2 values that make up a rational
# Assumes current file pos. is at begining of an IFD tag entry
sub makeRatTbl {
    my $fh = shift;
    my $num = shift;
    my $denom = shift;
    my $pos;

    $pos = scalar @hdr;
    $pos += 3;
    push @RatTbl, ($pos, $num, $denom);
}


    


1;
