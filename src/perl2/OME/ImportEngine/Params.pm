#!/usr/bin/perl -w
#
# OME::ImportEngine::Params.pm
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

=head1 NAME

  OME::ImportEngine::Params - helper routines for image & file parameters


=head1 SYNOPSIS

    use OME::ImportEngine::Params

    $params = new Params(\%metadata);


=head1 DESCRIPTION

    This module handles some the repetitive details of parameter
    storage and retrieval. It offers a set of dual purpose functions
    that each store or retrieve one particular parameter. One of
    these parameters, a reference to a hash of metadata, provides
    a convenient place to store the various pieces of image metadata
    that get collected during image import.

    To store a parameter via one of these routines, provide the parameter
    value as an argument to the function. Calling the function without an
    argument returns the current value of the parameter. For instance,
    this module provides a function, pixel_size, that handles the pixel 
    size parameter. If the importer find that the pixel size is 8, then
    it makes the call "$params->pixel_size(8);". Later on, to recall the
    value of the pixel size, make the call "$size = $params->pixel_size;".

    The current parameter functions are:

=over 12

=item * B<endian> S< > S< > S< >the endian-ness of the input file

=item * B<host_endian> the endian-ness of the host system

=item * B<oname>  S< > S< > S< >S< >the output (repository) file name

=item * B<obuffer> S< > S< >      the output buffer

=item * B<xml_hash> S< >S< >    reference to image metedata hash

=item * B<image_type> S< > the image type

=item * B<pixel_size> S< > the size, in bits, of an image pixel

=item * B<byte_size>   S< >    the size, in bytes, of an image pixel

=item * B<row_size>  S< >S< >     the size of a row

=item * B<fref>    S< > S< > S< >S< >        reference to the input file

=item * B<offset>    S< > S< > S< >    current offset into input file

=item * B<image_file>  S< >   image file

=item * B<image_offsets> set of offsets to TIFF input image strips

=item * B<image_bytecounts>  set of bytecounts of the TIFF input strips

=back

=cut





package OME::ImportEngine::Params;
use Config;
use strict;
use Carp;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);

our @EXPORT = qw( endian host_endian oname obuffer fref offset xml_hash image_type pixel_size byte_size row_size fref offset image_file image_offsets image_butecounts);


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



=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut


