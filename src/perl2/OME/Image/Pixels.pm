# OME/Image/Pixels.pm
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

package OME::Image::Pixels;

=head1 NAME

OME::Image::Pixels - interface for reading files

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

sub abstract { die __PACKAGE__." is an abstract class"; }

=head1 SYNOPSIS

=head1 DESCRIPTION

The OME::Image::Pixels interface provides a generalized way of reading
and writing to pixels files.  This is provided as a generic class to
ease the transition from a local image repository to the image server.
There are currently two implementations of this interface --
OME::Image::LocalPixels and OME::Image::Server::Pixels.

A pixels file has an explicitly defined life cycle: It can only be
written to immediately after creation.  Once the writing has finished,
and the pixels marked as complete, they cannot be written to anymore.
Further, they cannot be read from until the writing phase is finished.

=head1 METHODS

=head2 getDimensions

	my ($x,$y,$z,$c,$t,$bytesPerPixel) = $pixels->getDimensions();

Returns the dimensions (in pixels) of the pixels files.

=cut

sub getDimensions { abstract }

=head2 getSHA1

	my $sha1 = $pixels->getSHA1();

Returns a SHA-1 digest of the entire pixels file.  This method should
throw an error if the pixels file is not readable.

=cut

sub getSHA1 { abstract }

=head2 isReadable

	my $readable = $pixels->isReadable();

Returns whether a pixels file is readable, i.e., that the
C<finishPixels> method has been called on this pixels file at some
point in the past.

=cut

sub isReadable { abstract }

=head2 isWriteable

	my $writeable = $pixels->isWriteable();

Returns whether a pixels file is writeable, i.e., that the
C<finishPixels> method has never been called on this pixels file.

=cut

sub isWriteable { abstract }

=head2 getPixels

	my $buf = $pixels->getPixels($bigEndian);

Returns the entire pixel array from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getPixels { abstract }

=head2 getStack

	my $buf = $pixels->getStack($c,$t,$bigEndian);

Returns one stack of pixels from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getStack { abstract }

=head2 getPlane

	my $buf = $pixels->getPlane($z,$c,$t,$bigEndian);

Returns one plane of pixels from this file.  The $bigEndian parameter
specifies which endian-ness you want the pixels to be in.  If not
specified, it defaults to network order (big-endian).

=cut

sub getPlane { abstract }

=head2 getROI

	my $roi = $pixels->getROI($x0,$y0,$z0,$c0,$t0,
	                          $x1,$y1,$z1,$c1,$t1,
	                          $bigEndian);

Returns an arbitrary hyper-rectangular region of pixels from this
file.  The $bigEndian parameter specifies which endian-ness you want
the pixels to be in.  If not specified, it defaults to network order
(big-endian).

=cut

sub getROI { abstract }

=head2 setPixels

	$pixels->setPixels($buf,$bigEndian);

Sets the entire pixel array for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setPixels { abstract }

=head2 setStack

	$pixels->setStack($buf,$c,$t,$bigEndian);

Sets a single stack of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setStack { abstract }

=head2 setPlane

	$pixels->setPlane($buf,$z,$c,$t,$bigEndian);

Sets a single plane of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setPlane { abstract }

=head2 setROI

	$pixels->setROI($buf,
	                $x0,$y0,$z0,$c0,$t0,
	                $x1,$y1,$z1,$c1,$t1,
	                $bigEndian);

Sets an arbitrary hyper-rectangular region of pixels for this file.
The $bigEndian parameter specifies which endian-ness the given pixels
are in.  If not specified, it defaults to network order (big-endian).

=cut

sub setROI { abstract }

=head2 convert

	$pixels->convert($fileID,$offset,$bigEndian);

Copies pixels from an original file into a new pixels file.  The $file
parameter should be an instance of the OME::File interface.  

The Pixels in this file are in XYZCT order, which matches the order in
Pixels files. Otherwise, you would call ConvertRows, ConvertPlane,
ConvertTIFF or ConvertStack. The optional Offset parameter is used to
skip headers. It is the number of bytes from the begining of the file to
begin reading.

The $bigEndian parameter should specify the endian-ness of the pixels
to be copied out of the $file object.  If it isn't specified, it
defaults to network order (big-endian).

=cut

sub convert {
    my ($self,$file,$offset,$bigEndian) = @_;
    my ($xx,$yy,$zz,$cc,$tt,$bbp) = $self->getDimensions();
    my $size = $xx * $yy * $zz * $cc * $tt * $bbp;
    my $buf = $file->readData($offset,$size);
    $self->setPixels($buf,$bigEndian);
}

=head2 convertStack

	$pixels->convertStack($file,$offset,$c,$t,$bigEndian);

Fills in a stack in this pixels file from another file.  The $file
parameter should be an instance of the OME::File interface.  This is
equivalent to the following code snippet, assuming that $size is the
size, in bytes, of an XYZ stack in this pixels file:

	my $buf = $file->readData($offset,$size);
	$pixels->setStack($buf,$c,$t,$bigEndian);

This class provides a default implementation which is, in fact, this
code snippet.  However, cooperative implementations of OME::File and
OME::Image::Pixels can possibly execute the convertStack method much
faster.  (For instance, by reducing the necessary amount of data
transfer.)

The $bigEndian parameter should specify the endian-ness of the pixels
to be copied out of the $file object.  If it isn't specified, it
defaults to network order (big-endian).

=cut

sub convertStack {
    my ($self,$file,$offset,$c,$t,$bigEndian) = @_;
    my ($xx,$yy,$zz,$cc,$tt,$bbp) = $self->getDimensions();
    my $stackSize = $xx * $yy * $zz * $bbp;
    my $buf = $file->readData($offset,$stackSize);
    $self->setStack($buf,$c,$t,$bigEndian);
}

=head2 convertPlane

	$pixels->convertPlane($file,$offset,$z,$c,$t,$bigEndian);

Fills in a plane in this pixels file from another file.  The $file
parameter should be an instance of the OME::File interface.  This is
equivalent to the following code snippet, assuming that $size is the
size, in bytes, of an XY plane in this pixels file:

	my $buf = $file->readData($offset,$size);
	$pixels->setPlane($buf,$z,$c,$t,$bigEndian);

This class provides a default implementation which is, in fact, this
code snippet.  However, cooperative implementations of OME::File and
OME::Image::Pixels can possibly execute the convertPlane method much
faster.  (For instance, by reducing the necessary amount of data
transfer.)

The $bigEndian parameter should specify the endian-ness of the pixels
to be copied out of the $file object.  If it isn't specified, it
defaults to network order (big-endian).

=cut

sub convertPlane {
    my ($self,$file,$offset,$z,$c,$t,$bigEndian) = @_;
    my ($xx,$yy,$zz,$cc,$tt,$bbp) = $self->getDimensions();
    my $planeSize = $xx * $yy * $bbp;
    my $buf = $file->readData($offset,$planeSize);
    $self->setPlane($buf,$z,$c,$t,$bigEndian);
}

=head2 convertPlaneFromTIFF

	$pixels->convertPlaneFromTIFF($tiffFile,$z,$c,$t);

Fills in a plane in the pixels file from another file, which is
assumed to be in the TIFF format.  The TIFF is assumed to contain
exactly one plane of pixels.

=cut

sub convertPlaneFromTIFF { abstract }

=head2 convertRows

	$pixels->convertRows($file,$offset,$y,$numRows,$z,$c,$t,$bigEndian);

Fills in a row of pixels in this pixels file from another file.  The
$file parameter should be an instance of the OME::File interface.
This is equivalent to the following code snippet, assuming that $size
is the size, in bytes, of a row of pixels in this file, and that
$sizeX is the size of the X dimension of the pixels:

	my $buf = $file->readData($offset,$size * $numRows);
	$pixels->setROI($buf,
	                0,$y,$z,$c,$t,
	                $sizeX,$y+$numRows,$z+1,$c+1,$t+1,
	                $bigEndian);

This class provides a default implementation which is, in fact, this
code snippet.  However, cooperative implementations of OME::File and
OME::Image::Pixels can possibly execute the convertRows method much
faster.  (For instance, by reducing the necessary amount of data
transfer.)

The $bigEndian parameter should specify the endian-ness of the pixels
to be copied out of the $file object.  If it isn't specified, it
defaults to network order (big-endian).

=cut

sub convertRows {
    my ($self,$file,$offset,$y,$numRows,$z,$c,$t,$bigEndian) = @_;
    my ($xx,$yy,$zz,$cc,$tt,$bbp) = $self->getDimensions();
    my $rowSize = $xx * $bbp;
    my $buf = $file->readData($offset,$rowSize * $numRows);
    $self->setROI($buf,
                  0,$y,$z,$c,$t,
                  $xx,$y + $numRows,$z+1,$c+1,$t+1,
                  $bigEndian);
}

=head2 finishPixels

	$pixels->finishPixels();

Marks the end of the writeable phase of this pixels file's life cycle.
After this method has been called, none of the set* or convert*
methods can be called.

=cut

sub finishPixels { abstract }

=head2 getTemporaryLocalPixels

	my $filename = $self->getTemporaryLocalPixels($big_endian);

This method should be used for legacy code which must read the pixels
from a local file.  Returns the filename of a local file, copying the
pixels from wherever they might be.  This local file can be opened for
reading.  When the file is no longer needed, it should be closed, and
the finishLocalPixels method should be called.

The $big_endian parameter can be specified to the get the pixels file
in a certian endianness.  If it is omitted, then the pixels will be
returned in the endianness of the local machine.

=cut

sub getTemporaryLocalPixels {
    my ($self,$big_endian) = @_;
    my $session = OME::Session->instance();
    my $filename = $session->getTemporaryFilename("pixels","raw");
    $big_endian = OME->BIG_ENDIAN() unless defined $big_endian;

    open my $pix, ">", $filename
      or die "Could not open local pixels file";

    my $buf = $self->getPixels($big_endian);
    print $pix $buf;

    close $pix;

    return $filename;
}

=head2 getTemporaryLocalStack

	my $filename = $self->getTemporaryLocalStack($c,$t,$big_endian);

This method should be used for legacy code which must read the pixels
from a local file.  Returns the filename of a local file, copying the
specified stack from wherever they might be.  This local file can be
opened for reading.  When the file is no longer needed, it should be
closed, and the finishLocalPixels method should be called.

The $big_endian parameter can be specified to the get the pixels file
in a certian endianness.  If it is omitted, then the pixels will be
returned in the endianness of the local machine.

=cut

sub getTemporaryLocalStack {
    my ($self,$c,$t,$big_endian) = @_;
    my $session = OME::Session->instance();
    my $filename = $session->getTemporaryFilename("pixels","raw");
    $big_endian = OME->BIG_ENDIAN() unless defined $big_endian;

    open my $pix, ">", $filename
      or die "Could not open local pixels file";

    my $buf = $self->getStack($c,$t,$big_endian);
    print $pix $buf;

    close $pix;

    return $filename;
}

=head2 getTemporaryLocalPlane

	my $filename = $self->getTemporaryLocalPlane($z,$c,$t,$big_endian);

This method should be used for legacy code which must read the pixels
from a local file.  Returns the filename of a local file, copying the
specified plane from wherever they might be.  This local file can be
opened for reading.  When the file is no longer needed, it should be
closed, and the finishLocalPixels method should be called.

The $big_endian parameter can be specified to the get the pixels file
in a certian endianness.  If it is omitted, then the pixels will be
returned in the endianness of the local machine.

=cut

sub getTemporaryLocalPlane {
    my ($self,$z,$c,$t,$big_endian) = @_;
    my $session = OME::Session->instance();
    my $filename = $session->getTemporaryFilename("pixels","raw");
    $big_endian = OME->BIG_ENDIAN() unless defined $big_endian;

    open my $pix, ">", $filename
      or die "Could not open local pixels file";

    my $buf = $self->getPlane($z,$c,$t,$big_endian);
    print $pix $buf;

    close $pix;

    return $filename;
}

=head2 getTemporaryLocalROI

	my $filename = $self->
	    getTemporaryLocalROI($x0,$y0,$z0,$c0,$t0,
	                         $x1,$y1,$z1,$c1,$t1,
	                         $big_endian);

This method should be used for legacy code which must read the pixels
from a local file.  Returns the filename of a local file, copying the
specified ROI from wherever they might be.  This local file can be
opened for reading.  When the file is no longer needed, it should be
closed, and the finishLocalPixels method should be called.

The $big_endian parameter can be specified to the get the pixels file
in a certian endianness.  If it is omitted, then the pixels will be
returned in the endianness of the local machine.

=cut

sub getTemporaryLocalROI {
    my ($self,$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1,$big_endian) = @_;
    my $session = OME::Session->instance();
    my $filename = $session->getTemporaryFilename("pixels","raw");
    $big_endian = OME->BIG_ENDIAN() unless defined $big_endian;

    open my $pix, ">", $filename
      or die "Could not open local pixels file";

    my $buf = $self->getROI($x0,$y0,$z0,$c0,$t0,
                            $x1,$y1,$z1,$c1,$t1,
                            $big_endian);
    print $pix $buf;

    close $pix;

    return $filename;
}

=head2 finishLocalPixels

	$self->finishLocalPixels($filename);

Signifies that the temporary file returned by a previous call to
getTemporaryLocalPixels, getTemporaryLocalStack, or
getTemporaryLocalPlane is no longer needed.  If a temporary file was
created to handle the request, it will be deleted.

=cut

sub finishLocalPixels {
    my ($self,$filename) = @_;

    OME::Session->instance()->finishTemporaryFile($filename);
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


