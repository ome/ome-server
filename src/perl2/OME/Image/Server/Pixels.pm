# OME/Image/Server/Pixels.pm
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

package OME::Image::Server::Pixels;

=head1 NAME

OME::Image::Server::Pixels - interface for reading files

=cut

use strict;
use Log::Agent;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Image::Pixels);

use OME::Image::Server;

use constant PIXELS_ID => 0;
use constant SIZE_X    => 1;
use constant SIZE_Y    => 2;
use constant SIZE_Z    => 3;
use constant SIZE_C    => 4;
use constant SIZE_T    => 5;
use constant BBP       => 6;
use constant SIGNED    => 7;
use constant FLOAT     => 8;

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

=head2 new

	my $pixels = OME::Image::Server::Pixels->
	    new($xx,$yy,$zz,$cc,$tt,$bytesPerPixel,$isSigned,$isFloat);

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($xx,$yy,$zz,$cc,$tt,$bytesPerPixel,$isSigned,$isFloat) = @_;

    my $pixelsID = OME::Image::Server->
      newPixels($xx,$yy,$zz,$cc,$tt,$bytesPerPixel,$isSigned,$isFloat);
    die "Could not create pixels file"
      unless defined $pixelsID && $pixelsID >= 0;

    my $self = [$pixelsID,$xx,$yy,$zz,$cc,$tt,
                $bytesPerPixel,$isSigned,$isFloat];

    bless $self,$class;
    return $self;
}

=head2 open

	my $pixels = OME::Image::Server::Pixels->open($pixelsID);

=cut

sub open {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($pixelsID) = @_;

    # Retrieve the pixels' dimensions from the image server
    my ($xx,$yy,$zz,$cc,$tt,$bbp,$isSigned,$isFloat) =
      OME::Image::Server->getPixelsInfo($pixelsID);

    my $self = [$pixelsID,$xx,$yy,$zz,$cc,$tt,
                $bbp,$isSigned,$isFloat];
    bless $self,$class;
    return $self;
}

=head2 getPixelsID

	my $pixelsID = $pixels->getPixelsID();

=cut

sub getPixelsID { shift->[PIXELS_ID] }

=head2 getDimensions

	my ($x,$y,$z,$c,$t,$bytesPerPixel) = $pixels->getDimensions();

Returns the dimensions (in pixels) of the pixels files.

=cut

sub getDimensions { @{shift()}[SIZE_X..BBP]; }

=head2 getSHA1

	my $sha1 = $pixels->getSHA1();

Returns a SHA-1 digest of the entire pixels file.  This method should
throw an error if the pixels file is not readable.

=cut

sub getSHA1 {
    my $self = shift;
    my $pixelsID = $self->[PIXELS_ID];
    return OME::Image::Server->getPixelsSHA1($pixelsID);
}

=head2 isReadable

	my $readable = $pixels->isReadable();

Returns whether a pixels file is readable, i.e., that the
C<finishPixels> method has been called on this pixels file at some
point in the past.

=cut

sub isReadable { OME::Image::Server->isPixelsFinished(shift->[PIXELS_ID]) }

=head2 isWriteable

	my $writeable = $pixels->isWriteable();

Returns whether a pixels file is writeable, i.e., that the
C<finishPixels> method has never been called on this pixels file.

=cut

sub isWriteable { !OME::Image::Server->isPixelsFinished(shift->[PIXELS_ID]) }

=head2 getPixels

	my $buf = $pixels->getPixels($bigEndian);

Returns the entire pixel array from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getPixels {
    my ($self,$destBigEndian) = @_;
    return OME::Image::Server->
      getPixels($self->[PIXELS_ID],$destBigEndian);
}

=head2 getStackStatistics

	my $hash = $pixels->getStackStatistics();

see also OME::Image::Server->getStackStatistics
=cut

sub getStackStatistics {
    my ($self) = @_;
    return OME::Image::Server->
      getStackStatistics($self->[PIXELS_ID]);
}

=head2 getStack

	my $buf = $pixels->getStack($c,$t,$bigEndian);

Returns one stack of pixels from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getStack {
    my ($self,$c,$t,$destBigEndian) = @_;
    return OME::Image::Server->
      getStack($self->[PIXELS_ID],$c,$t,$destBigEndian);
}

=head2 getPlane

	my $buf = $pixels->getPlane($z,$c,$t,$bigEndian);

Returns one plane of pixels from this file.  The $bigEndian parameter
specifies which endian-ness you want the pixels to be in.  If not
specified, it defaults to network order (big-endian).

=cut

sub getPlane {
    my ($self,$z,$c,$t,$destBigEndian) = @_;
    return OME::Image::Server->
      getPlane($self->[PIXELS_ID],$z,$c,$t,$destBigEndian);
}

=head2 getROI

	my $roi = $pixels->getROI($x0,$y0,$z0,$c0,$t0,
	                          $x1,$y1,$z1,$c1,$t1,
	                          $bigEndian);

Returns an arbitrary hyper-rectangular region of pixels from this
file.  The $bigEndian parameter specifies which endian-ness you want
the pixels to be in.  If not specified, it defaults to network order
(big-endian).

=cut

sub getROI {
    my ($self,$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1,
        $destBigEndian) = @_;
    return OME::Image::Server->
      getROI($self->[PIXELS_ID],
             $x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1,
             $destBigEndian);
}

=head2 setPixels

	$pixels->setPixels($buf,$bigEndian);

Sets the entire pixel array for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian). $buf is a binary scalar.
Instead of $buf, you can pass the filename if you use setPixelsFile.

=cut

sub setPixels {
    my ($self,$buf,$destBigEndian) = @_;
    OME::Image::Server->
        setPixels($self->[PIXELS_ID],\$buf,$destBigEndian);
}

sub setPixelsFile {
    my ($self,$filename,$destBigEndian) = @_;
    OME::Image::Server->
        setPixels($self->[PIXELS_ID],$filename,$destBigEndian);
}

=head2 setStack

	$pixels->setStack($buf,$c,$t,$bigEndian);

Sets a single stack of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setStack {
    my ($self,$buf,$c,$t,$destBigEndian) = @_;
    OME::Image::Server->
        setStack($self->[PIXELS_ID],$c,$t,\$buf,$destBigEndian);
}

=head2 setPlane

	$pixels->setPlane($buf,$z,$c,$t,$bigEndian);

Sets a single plane of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setPlane {
    my ($self,$buf,$z,$c,$t,$destBigEndian) = @_;
    OME::Image::Server->
        setPlane($self->[PIXELS_ID],$z,$c,$t,\$buf,$destBigEndian);
}

=head2 setROI

	$pixels->setROI($buf,
	                $x0,$y0,$z0,$c0,$t0,
	                $x1,$y1,$z1,$c1,$t1,
	                $bigEndian);

Sets an arbitrary hyper-rectangular region of pixels for this file.
The $bigEndian parameter specifies which endian-ness the given pixels
are in.  If not specified, it defaults to network order (big-endian).

=cut

sub setROI {
    my ($self,$buf,
        $x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1,
        $destBigEndian) = @_;
    OME::Image::Server->
        setROI($self->[PIXELS_ID],
               $x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1,
               \$buf,$destBigEndian);
}

=head2 setThumb

	# set the Thumbnail image from a display options attribute.
	$pixels->setThumb( $displayOptions );
	
	# set the Thumbnail image from data
	$pixels->setThumb(
		theT  => $theT,
		theZ  => $theZ,
		Red   => [$channelIndex, $blackLevel, $whiteLevel, $gamma],
		Green => [$channelIndex, $blackLevel, $whiteLevel, $gamma],
		Blue  => [$channelIndex, $blackLevel, $whiteLevel, $gamma],
		Gray  => [$channelIndex, $blackLevel, $whiteLevel, $gamma],
		LevelBasis => $levelBasis
	);

Sets an thumbnail image for this Pixels. see also OME::Image::Server->setThumb

=cut

sub setThumb {
	my $self = shift;
	my @params = @_;
	my $displayOptions = shift;
	if( UNIVERSAL::isa($displayOptions,'OME::SemanticType::Superclass')
        && $displayOptions->verifyType('DisplayOptions') ) {
        my %data;
		$data{PixelsID} = $self->getPixelsID();
		$data{theZ}     = ($displayOptions->ZStart() + $displayOptions->ZStop() ) / 2;
		$data{theT}     = ($displayOptions->TStart() + $displayOptions->TStop() ) / 2;
		if( $displayOptions->DisplayRGB() ) {
			if( $displayOptions->RedChannelOn() ) {
				$data{Red}   = [
					$displayOptions->RedChannel()->ChannelNumber(),
					$displayOptions->RedChannel()->BlackLevel(),
					$displayOptions->RedChannel()->WhiteLevel(),
					0
				];
			}
			if( $displayOptions->BlueChannelOn() ) {
				$data{Blue}   = [
					$displayOptions->BlueChannel()->ChannelNumber(),
					$displayOptions->BlueChannel()->BlackLevel(),
					$displayOptions->BlueChannel()->WhiteLevel(),
					0
				];
			}
			if( $displayOptions->GreenChannelOn() ) {
				$data{Green}   = [
					$displayOptions->GreenChannel()->ChannelNumber(),
					$displayOptions->GreenChannel()->BlackLevel(),
					$displayOptions->GreenChannel()->WhiteLevel(),
					0
				];
			}
		} else {
			$data{Gray}   = [
				$displayOptions->GreyChannel()->ChannelNumber(),
				$displayOptions->GreyChannel()->BlackLevel(),
				$displayOptions->GreyChannel()->WhiteLevel(),
				0
			];
		}
		OME::Image::Server->setThumb( %data );
	} else {
		OME::Image::Server->setThumb( PixelsID => $self->getPixelsID, @params );
	}
}

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
    $self->SUPER::convert($file,$offset,$bigEndian)
      unless UNIVERSAL::isa($file,"OME::Image::Server::File");
    my $fileID = $file->getFileID();
    my $pixelsID = $self->[PIXELS_ID];
    OME::Image::Server->convert($pixelsID,$fileID,$offset,$bigEndian);
}

=head2 convertStack

	$pixels->convertStack($file,$offset,$c,$t,$bigEndian);

Fills in a stack in this pixels file from another file.  The $file
parameter should be an instance of the OME::File interface.  This is
equivalent to the following code snippet, assuming that $size is the
size, in bytes, of an XYZ stack in this pixels file:

	my $buf = $file->readData($offset,$size);
	$pixels->setStack($buf,$c,$t,$bigEndian);

The $bigEndian parameter should specify the endian-ness of the pixels
to be copied out of the $file object.  If it isn't specified, it
defaults to network order (big-endian).

=cut

sub convertStack {
    my ($self,$file,$offset,$c,$t,$bigEndian) = @_;
    $self->SUPER::convertStack($file,$offset,$c,$t,$bigEndian)
      unless UNIVERSAL::isa($file,"OME::Image::Server::File");
    my $fileID = $file->getFileID();
    my $pixelsID = $self->[PIXELS_ID];
    OME::Image::Server->convertStack($pixelsID,$c,$t,
                                     $fileID,$offset,$bigEndian);
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
    $self->SUPER::convertPlane($file,$offset,$z,$c,$t,$bigEndian)
      unless UNIVERSAL::isa($file,"OME::Image::Server::File");
    my $fileID = $file->getFileID();
    my $pixelsID = $self->[PIXELS_ID];
    OME::Image::Server->convertPlane($pixelsID,$z,$c,$t,
                                     $fileID,$offset,$bigEndian);
}

=head2 convertPlaneFromTIFF

	$pixels->convertPlaneFromTIFF($tiffFile,$z,$c,$t);

Fills in a plane in the pixels file from another file, which is
assumed to be in the TIFF format.  The TIFF is assumed to contain
exactly one plane of pixels.

=cut

sub convertPlaneFromTIFF {
    my ($self,$tiffFile,$z,$c,$t) = @_;
    die "Can only convert TIFF's which are on the image server"
      unless UNIVERSAL::isa($tiffFile,"OME::Image::Server::File");
    my $fileID = $tiffFile->getFileID();
    my $pixelsID = $self->[PIXELS_ID];
    OME::Image::Server->convertPlaneFromTIFF($pixelsID,$z,$c,$t,$fileID);
}

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
    $self->SUPER::convertRows($file,$offset,$y,$numRows,
                              $z,$c,$t,$bigEndian)
      unless UNIVERSAL::isa($file,"OME::Image::Server::File");
    my $fileID = $file->getFileID();
    my $pixelsID = $self->[PIXELS_ID];
    OME::Image::Server->convertRows($pixelsID,$y,$numRows,$z,$c,$t,
                                    $fileID,$offset,$bigEndian);
}

=head2 finishPixels

	$pixels->finishPixels();

Marks the end of the writeable phase of this pixels file's life cycle.
After this method has been called, none of the set* or convert*
methods can be called.

=cut

sub finishPixels {
    my $self = shift;
    my $ID = OME::Image::Server->finishPixels($self->[PIXELS_ID]);
    $self->[PIXELS_ID] = $ID;
    return ($ID);
}

=head2 deletePixels

	$pixels->deletePixels();

Deletes the Pixels from the image server - this cannot be undone.

=cut

sub deletePixels {
    my $self = shift;
    my $ID = OME::Image::Server->deletePixels($self->[PIXELS_ID]);
    $self->[PIXELS_ID] = $ID;
    return ($ID);
}

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

    OME::Image::Server->
      getPixels($self->[PIXELS_ID],$big_endian,$filename);

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

    OME::Image::Server->
      getStack($self->[PIXELS_ID],$c,$t,$big_endian,$filename);

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

    OME::Image::Server->
      getPlane($self->[PIXELS_ID],$z,$c,$t,$big_endian,$filename);

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

    OME::Image::Server->
      getROI($self->[PIXELS_ID],
             $x0,$y0,$z0,$c0,$t0, $x1,$y1,$z1,$c1,$t1,
             $big_endian,$filename);

    return $filename;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


