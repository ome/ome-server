#!/usr/bin/perl -w
#
# Import-reader.pm
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

# This class contains the methods for input image file identification
# and importation.
#
# It will ascertain the type of the file (TIFF, DeltaVision, etc.). Based
# on its knowledge of the filetype, it will instantiate an appropriate
# subclass instance that will extract out the metadata stored within the file,
# and put it into the appropriate fields in the database.
# It will also extract out the image data and place it, in XYZWT order,
# into the OME repository.
# 
# If the script cannot determine or cannot handle the file type, it will exit
# with an error message.
#

# ---- Public routines -------
# new()
# DESTROY()
# check_type()
# readFile()
# endian()
# host_endian()
# obuffer()
# xml_hash()
# image_type()
# fref()
# fouf()
# offset()
# flip_float()

# ---- Private routines ------
# checkTIFF()
# checkDV()
# getDVID()


package OME::ImportExport::Import_reader;
use Class::Struct;
use strict;
use OME::ImportExport::TIFFreader;
use OME::ImportExport::DVreader;
use Carp;
use vars qw($VERSION);
$VERSION = '1.0';
use Config;

# $self holds at least these useful fields:
#struct Image_reader => {
#        image_file  - input image file
#        image_group - input image file group
#	 host_endian - endain-ness of host machine
#        endian      - endian-ness of the image file
#        pixel_size  - number of bits/pixel
#        obuffer     - ref to output buffer
#        xml_hash    - reference to xml_elements hash
#	 fref        - image file handle
#	 fouf        - output (repository) file handle
#	 offset      - offset to start of image metadata
#	 image_type  - image type
#	};


my %readers = (DV       => "OME::ImportExport::DVreader",
	       TIFF     => "OME::ImportExport::TIFFreader",
	       STK      => "OME::ImportExport::STKreader");

my %checkers = (TIFF    => \&checkTIFF,
		DV      => \&checkDV);

sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $self = {};
    bless $self, $class;

    my $image_group = shift;
    my $image_file = $$image_group[0];
    croak "No image file to import"
	unless defined $image_file;
    my $image_buf = shift;           # reference to buffer to fill w/ image
    my $xml_elements = shift;        # reference to hash for XML elements & their values

    my $our_endian;

    # Find out what byte order this machine has
    my $byteorder = $Config{byteorder};
    $our_endian = (($byteorder == 1234) || ($byteorder == 12345678)) ? "little" : "big";
    $self->host_endian($our_endian);
    $self->image_file($image_file);      # save 1st file for those readers that
    $self->image_group($image_group);   #    don't do groups
    $self->offset(0);
    $self->obuffer($image_buf);
    $self->xml_hash($xml_elements);

    return $self;
}


sub DESTROY {
    my $self = shift;
    if (defined $self->fref) {
	close $self->fref;
    }
}

# Figure out what type file we're reading, it's Endian-ness, and the offset to image metadata

sub check_type {
    my $endian;
    my $offset;
    my $can_do_stacks;
    my $typ; 
    my $type = "Unknown";
    my $subref;
    my $xml_ref;
    my @check_result;

    my $self = shift;
    croak "Image::check_type must be called on an actual image"
	unless ref($self);

    my $fn = $self->image_file();
    open IMG, $fn
	or die "Can't open $fn - $@\n";
    binmode(IMG);
    my $fh = *IMG;
    $self->fref($fh);

    # Run against every type checker until
    # find a match or no more types to try
    foreach $typ (keys %checkers) {
	$subref = $checkers{$typ};
	@check_result = &$subref(\*IMG);
	seek($self->fref, 0, 0);   
	if ($check_result[0] ne "") {
	    $endian = $check_result[0];
	    $offset = $check_result[1];
	    $can_do_stacks = 0;
	    if (defined $check_result[2]) {
		$can_do_stacks = $check_result[2];
	    }
	    $type = $typ;
	    last;
	}
    }

    print STDERR "Image is $type format\n";
    
    $self->offset($offset);
    $self->image_type($type);
    $self->endian($endian);
    $xml_ref = $self->xml_hash();
    $$xml_ref{'Image.ImageType'} = $type;
    $$xml_ref{'Image_files_xyzwt.Endian'} = $endian;
}



# Create a child of the type that can read this image,
# have it do the import, and store the metadata.

sub readFile {
    my $readerref;
    my $type_handler;
    my $status;

    my $self = shift;
    $readerref = $readers{$self->image_type};
    $type_handler = $readerref->new($self);
    {
	$status = $type_handler->readImage;
	last unless $status eq "";
	#my $wrapper = new OME::ImportExport::Wrapper($type_handler);

	$status = $type_handler->formatImage;
	if ($status eq "") {
	    my $xml_ref = $self->xml_hash();
	    $xml_ref->{'Image.BitsPerPixel'} = $self->{'pixel_size'};
	}
    }

    return $status;
}




# Store/retrieve endian value
sub endian {
    my $self = shift;
    $self->{endian} = shift if @_;
    return $self->{endian};
}


# Store/retrieve our host's endian-ness
sub host_endian {
    my $self = shift;
    $self->{host_endian} = shift if @_;
    return $self->{host_endian};
}


# Store/retrieve output buffer
sub obuffer {
    my $self = shift;
    $self->{obuffer} = shift if @_;
    return $self->{obuffer};
}


# Store/retrieve xml_elements reference
sub xml_hash {
    my $self = shift;
    $self->{xml_hash} = shift if @_;
    return $self->{xml_hash};
}


# Store/retrieve image type
sub image_type {
    my $self = shift;
    $self->{image_type} = shift if @_;
    return $self->{image_type};
}


# Store/retrieve pixel size
sub pixel_size {
    my $self = shift;
    $self->{pixel_size} = shift if @_;
    return $self->{pixel_size};
}


# Store/retrieve input file reference
sub fref {
    my $self = shift;
    $self->{fref} = shift if @_;
    return $self->{fref};
}


# Store/retrieve output file reference
sub fouf {
    my $self = shift;
    $self->{fouf} = shift if @_;
    return $self->{fouf};
}


# Store/retrieve input file offset
sub offset {
    my $self = shift;
    $self->{offset} = shift if @_;
    return $self->{offset};
}


# Store/retrieve input file group ref
sub image_group {
    my $self = shift;
    $self->{image_group} = shift if @_;
    return $self->{image_group};
}


# Store/retrieve input file name 
sub image_file {
    my $self = shift;
    $self->{image_file} = shift if @_;
    return $self->{image_file};
}



# called if host and input file are of different endian order, and a float
# has been read in. Flips the float to the host's endian-ness.

sub flip_float {
    my $str;
    my ($fld1, $fld2, $fld3, $fld4); 
    my $self = shift;
    my $inflt = shift;

    $str = unpack("B32", $inflt);
    $str = substr("0" x 32 . $str, -32);   #left pad w/ 0's to length 32

    $fld1 = substr($str, 0, 8);
    $fld2 = substr($str, 8, 8);
    $fld3 = substr($str, 16, 8);
    $fld4 = substr($str, 24, 8);
    $str = $fld4.$fld3.$fld2.$fld1;  # reverse the byte order


    $inflt = unpack("f", pack("B32", $str));
    return($inflt);
}



# Routines internal to this module (i.e. not class routines)

# See if the image is a TIFF file
# The TIFF reader will detect and dispatch for any TIFF variants
sub checkTIFF
{
    my $fref = shift;
    my $len;
    my $buf;
    my $endian = "";
    my $offset;
    my $can_do_stacks = 1;
    my $Template;
    my $littleTemplate="CCvV";  #decode format if TIFF in little Endian order
    my $bigTemplate="CCnN";     #decode format if TIFF in big Endian order
    my @hdr;

    $len = -s $fref;

    if ($len >= 8) {
	read $fref, $buf, 8;
	@hdr = unpack("CCvV", $buf);
	$Template = $littleTemplate;
	@hdr = unpack($Template, $buf);
	if ($hdr[0] == 73 && $hdr[1] == 73 && $hdr[2] == 42) {
	    $endian = "little";
	    $offset = $hdr[3];
	}
	elsif ($hdr[0] == 77 && $hdr[0] == 77) {
	    $Template = $bigTemplate;
	    @hdr = unpack($Template, $buf);
	    if ($hdr[2] == 42) {
		$endian = "big";
		$offset = $hdr[3];
	    }
	}
    }

    return($endian, $offset, $can_do_stacks);
}


# See if the image is a DeltaVision file (SoftWorx)
sub checkDV
{
    my $fref = shift;
    my $len;
    my $buf;
    my $dvid;
    my $endian = "";
    my $offset = 0;
    my $DVID = -16224;
    my $DVIbigTemplate    = "NNNx84n";
    my $DVIlittleTemplate = "VVVx84v";

    $len = -s IMG;

    read IMG, $buf, 1024;  # read enough for main DV header

    $dvid = GetDVID($DVIlittleTemplate, $buf);
    if ($dvid == $DVID) {
	$endian = "little";
    }
    else {
	$dvid = GetDVID($DVIbigTemplate, $buf);
	if ($dvid == $DVID) {
	    $endian = "big";
	}
    }

    return($endian, $offset);
}

# Get what might be the DeltaVision ID & convert to signed
sub GetDVID {
    my $template = shift;
    my $buf = shift;
    my $dvid;
    my @hdr;

    @hdr = unpack($template, $buf); 
    $dvid = $hdr[3];
    # it unpacked as unsigned, so 1st convert to signed
    $dvid = $dvid >= 32768 ? $dvid-65536 : $dvid;

    return $dvid;
}

1;
