#!/usr/bin/perl -w
#
# OME/ImportExport/Params.pm
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

# It handles at least these parameters:
#   endian        the endian-ness of the input file
#   host_endian   the endian-ness of the host system
#   obuffer       output buffer (may become obsolete)
#   fref          input file ref
#   offset        current read offset in image
#   xml_hash      hash for image metadata
#   image_type    input image type
#   pixel_size    size of pixel
#   temp_fn       temporary output pixel file name

# ---- Public routines -------
# new()
# endian()
# host_endian()
# obuffer()
# fref()
# offset()
# xml_hash()
# image_type()
# pixel_size()
# temp_fn()


package OME::ImportExport::Params;
use OME::ImportExport::Importer;
use Config;
use strict;
use Carp;
use vars qw($VERSION);
$VERSION = 2.000_000;


sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $xref = shift;
    my $self = {};
    bless $self, $class;

    # Find out what byte order this machine has
    my $byteorder = $Config{byteorder};
    my $our_endian = (($byteorder == 1234) ||
		      ($byteorder == 12345678)) ? "little" : "big";
    $self->host_endian($our_endian);

    $self->xml_hash($xref);
    $self->offset(0);

    return $self;
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


# Store/retrieve output (repository) file name
sub oname {
    my $self = shift;
    $self->{oname} = shift if @_;
    return $self->{oname};
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


# Store/retrieve pixel byte size
sub byte_size {
    my $self = shift;
    $self->{byte_size} = shift if @_;
    return $self->{byte_size};
}


# Store/retrieve row size
sub row_size {
    my $self = shift;
    $self->{row_size} = shift if @_;
    return $self->{row_size};
}


# Store/retrieve input file reference
sub fref {
    my $self = shift;
    $self->{fref} = shift if @_;
    return $self->{fref};
}



# Store/retrieve input file offset
sub offset {
    my $self = shift;
    $self->{offset} = shift if @_;
    return $self->{offset};
}


# Store/retrieve image file
sub image_file {
    my $self = shift;
    $self->{image} = shift if @_;
    return $self->{image};
}


# Store/retrieve image group
sub image_group {
    my $self = shift;
    $self->{image_group} = shift if @_;
    return $self->{image_group};
}


# Store/retrieve image strip group
sub image_offsets {
    my $self = shift;
    $self->{image_offsets} = shift if @_;
    return $self->{image_offsets};
}


# Store/retrieve image strip bytecounts
sub image_bytecounts {
    my $self = shift;
    $self->{image_bytecounts} = shift if @_;
    return $self->{image_bytecounts};
}


