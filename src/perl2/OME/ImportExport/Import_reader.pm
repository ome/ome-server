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
# extract_rows()
# endian()
# host_endian()
# obuffer()
# xml_hash()
# image_type()
# fref()
# fouf()
# offset()
# get_image_fmt()
# flip_float()

# ---- Private routines ------
# checkTIFF()
# checkDV()
# getDVID()


package Import_reader;
use Class::Struct;
use strict;
use TIFFreader;
use DVreader;
use Carp;
use vars qw($VERSION);
$VERSION = '1.0';
use Config;

struct Image_reader => {
        image_file => '$',                    # input image file
        project => '$',                       # Project under which image is being imported
	host_endian => '$',                   # endain-ness of host machine
        endian => '$',                        # endian-ness of the image file
        obuffer => '$',
        xml_hash => '$',                      # reference to xml_elements hash
	fref => '$',                          # image file handle
	fouf => '$',                          # output (repository) file handle
	offset => '$',                        # offset to start of image metadata
    # Image DB fields - filled in as we go
    # These key-values map to the Image table
	name => '$',                          # image name
	description => '$',                   # free form text description
	path => '$',                          # path to image in repository
	host => '$',                          # host where repository lives
	url => '$',                           # URL to image
	instrument_id => '$',                 # ID of scope
	project_id => '$',                    # Project imported by this project
	experimenter_id => '$',               # ID of experimenter (who took image? heads project?)
	created => '$',                       # timestamp when created
	inserted => '$',                      # timestamp when inserted
	image_type => '$',                    # image type
	# These key-values map to the Attributes_image_xyzwt table
	size_x => '$',                        # number pixels per row
	size_y => '$',                        # number rows
	size_z => '$',                        # number Z planes
	num_waves => '$',                     # number wavelengths
	num_times => '$',                     # number timepoints
	pixel_size_x => '$',                  # microns/pixel in the X dimension
	pixel_size_y => '$',                  # microns/pixel in the Y dimension
	pixel_size_z => '$',                  # microns/pixel in the z dimension
	wave_increment => '$',                # nm. between wavelengths (?)
	time_increment => '$'                 # seconds between consequtive scans
	};


my %readers = (DV       => "DVreader",
	       TIFF     => "TIFFreader",
	       UIC      => "UICreader",
	       STK      => "STKreader");

my %checkers = (TIFF    => \&checkTIFF,
		DV      => \&checkDV);

sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $image_file = shift;
    croak "No image file to import"
	unless defined $image_file;
    my $image_buf = shift;           # reference to buffer to fill w/ image
    my $project = shift;
    my $xml_elements = shift;        # reference to hash for XML elements & their values
    croak "Image file $image_file not associated with a project"
	unless defined $project;
    my $our_endian;

    my $self = Image_reader->new();

    # Find out what byte order this machine has
    my $byteorder = $Config{byteorder};
    $our_endian = (($byteorder == 1234) || ($byteorder == 12345678)) ? "little" : "big";
    $self->host_endian($our_endian);
    $self->image_file($image_file);
    $self->project($project);
    $self->offset(0);
    $self->obuffer($image_buf);
    $self->xml_hash($xml_elements);

    return bless $self, $class;
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
    my $typ; 
    my $type = "Unknown";
    my $subref;
    my $xml_ref;
    my @check_result;

    my $self = shift;
    croak "Image::check_type must be called on an actual image"
	unless ref($self);

    my $ref = ref($self);
    my $fn = $self->Image_reader::image_file;
    open IMG, $self->Image_reader::image_file
	or die "Can't open $self->Image_reader::image_file\n";
    binmode(IMG);
    my $fh = *IMG;
    $self->fref($fh);

    foreach $typ (keys %checkers) {
	$subref = $checkers{$typ};
	@check_result = &$subref(\*IMG);
	seek($self->fref, 0, 0);   
	if ($check_result[0] ne "") {
	    $endian = $check_result[0];
	    $offset = $check_result[1];
	    $type = $typ;
	    last;
	}
    }

    print "Image is $type format\n";
    
    $self->offset($offset);
    $self->image_type($type);
    $self->endian($endian);
    $xml_ref = $self->Image_reader::xml_hash;
    $$xml_ref{'Image.ImageType'} = $type;
}



# Create a child of the type that can read this image,
# have it do the import, and store the metadata.

sub readFile {
    my $readerref;
    my $type_handler;
    my $status;
    my ($bp, $sz, @szz);

    my $self = shift;
    $self->obuffer($self->Image_reader::obuffer);
    $readerref = $readers{$self->image_type};
    $type_handler = $readerref->new($self);
    {
	$status = $type_handler->readImage($self);      # let child know its parent;
	last unless $status eq "";

	$bp = $self->obuffer;
	$status = $type_handler->formatImage($self);
	$sz = scalar(@$bp);
	#print "Buffer is $sz\n";
	#close_repository($self);
    }

    return $status;
}


# Read the specified number of rows of the specified size from the specified
# file & pack into specified buffer. Assumes rows are contiguous in the file.
# Will unpack & then repack via the specified formats.
# Designed to be used to extract a XY plane of pixels from an image file being
# imported, and convert them prior to being placed into the repository.

sub extract_rows {
    my ($self, $num_rows, $row_size, $fih, $foh, $offset, $ifmt, $ofmt, $oarray) = @_;
    my ($ibuf, $rowbuf);
    my $row;
    my $status;
    my @obuf;
    my @xy;

    for ($row = 0; $row < $num_rows; $row++) {
	$status = FileUtils::seek_and_read($fih, \$ibuf, $offset, $row_size);
	last
	    unless $status eq "";
	@obuf = unpack($ifmt, $ibuf);
	$rowbuf = pack($ofmt, @obuf);
	push @xy, $rowbuf;
	print $foh  $ibuf;              # write to repository file
	$offset += $row_size;
    }
    push @$oarray, \@xy;

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



# Helper method to return the proper format strings for: a) unpacking the image data
# on input, and b) packing it back up in our native format for output to repository
sub get_image_fmt {
    my ($self, $pixel_size, $num_bytes, $endian) = @_;
    my $ifmt = "";
    my $ofmt;
    my $cnt = $num_bytes/$pixel_size;   # convert num. bytes to num. values

    if ($pixel_size == 1) {
	$ifmt = "C$cnt";
    }
    elsif ($pixel_size == 2) {
	if ($endian eq "little") {
	    $ifmt = "v$cnt";
	}
	else {
	    $ifmt = "n$cnt";
	}
    }
    elsif ($pixel_size == 4) {
	if ($endian eq "little") {
	    $ifmt = "V$cnt";
	}
	else {
	    $ifmt = "N$cnt";
	}
    }
    else {
	carp "Can't handle $pixel_size pixels";
    }

    $ofmt = $ifmt;
    $ofmt =~ tr/nNvV/SISI/;      # convert either endian short/long to our endian short/long

    return ($ifmt, $ofmt);
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
    my $Template;
    my $littleTemplate="CCvV";  #decode format if TIFF in little Endian order
    my $bigTemplate="CCnN";     #decode format if TIFF in big Endian order
    my @hdr;

    $len = -s IMG;

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

    return($endian, $offset);
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
