# OME/Image/LocalPixels.pm
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

package OME::Image::LocalPixels;

=head1 NAME

OME::Image::LocalPixels - interface for reading files

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Image::Pixels);

use OME::Image::Pix;
use OME::ImportExport::Repacker::Repacker;

use constant PIX        =>  0;
use constant SIZE_X     =>  1;
use constant SIZE_Y     =>  2;
use constant SIZE_Z     =>  3;
use constant SIZE_C     =>  4;
use constant SIZE_T     =>  5;
use constant BBP        =>  6;
use constant FINISHED   =>  7;
use constant SIGNED     =>  8;
use constant FLOAT      =>  9;
use constant BIG_ENDIAN => 10;
use constant FILENAME   => 11;

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

	my $pixels = OME::Image::LocalPixels->
	    new($filename,$xx,$yy,$zz,$cc,$tt,$bytesPerPixel,
	        $isSigned,$isFloat,$bigEndian);

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($filename,$xx,$yy,$zz,$cc,$tt,$bytesPerPixel,
        $isSigned,$isFloat,$bigEndian) = @_;
    die "$filename already exists" if -e $filename;

    $isSigned ||= 0;
    $isFloat ||= 0;
    $bigEndian ||= 1;

    my $self = [undef,$xx,$yy,$zz,$cc,$tt,
                $bytesPerPixel,0,$isSigned,$isFloat,
                $bigEndian,$filename];

    my $header_filename = "${filename}.header";
    open HEADER, "> $header_filename"
      or die "Cannot open header file $header_filename";
    print HEADER join("\t",@{$self}[SIZE_X..BIG_ENDIAN]),"\n";
    close HEADER;

    $self->[PIX] = OME::Image::Pix->
      new($filename,$xx,$yy,$zz,$cc,$tt,$bytesPerPixel);

    bless $self,$class;
    return $self;
}

=head2 open

	my $pixels = OME::Image::LocalPixels->open($filename);

=cut

sub open {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($filename) = @_;
    my $header_filename = "${filename}.header";

    # Read in the pixels' dimensions from the header file
    open HEADER, "< $header_filename"
      or die "Cannot open header file $header_filename";
    my $dims = <HEADER>;
    chomp $dims;
    close HEADER;

    my @dims = split(/\t/,$dims);
    die "Invalid header file"
      unless scalar(@dims) == 8;

    # Use an old-school OME::Image::Pix object for I/O
    my $pix = OME::Image::Pix->new($filename,@dims[0..5])
      or die "Could not create pixel I/O object";

    # [$pix,$xx,$yy,$zz,$cc,$tt,$bytesPerPixel,
    #  $isFinished,$isSigned,$isFloat,$bigEndian,$filename]
    my $self = [$pix,@dims,$filename];
    bless $self,$class;
    return $self;
}

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
    my $filename = $self->[FILENAME];

    my $cmd = "openssl sha1 $filename |";
    my $sh;
    my $sha1;

    CORE::open (STDOUT_PIPE,$cmd);
    chomp ($sh = <STDOUT_PIPE>);
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;
    close (STDOUT_PIPE);

    return $sha1;
}

=head2 isReadable

	my $readable = $pixels->isReadable();

Returns whether a pixels file is readable, i.e., that the
C<finishPixels> method has been called on this pixels file at some
point in the past.

=cut

sub isReadable { shift->[FINISHED] }

=head2 isWriteable

	my $writeable = $pixels->isWriteable();

Returns whether a pixels file is writeable, i.e., that the
C<finishPixels> method has never been called on this pixels file.

=cut

sub isWriteable { !(shift->[FINISHED]) }

=head2 getPixels

	my $buf = $pixels->getPixels($bigEndian);

Returns the entire pixel array from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getPixels {
    my ($self,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are write-only" unless $isFinished;

    my $buf = $pix->GetPixels();
    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    return $buf;
}

=head2 getStack

	my $buf = $pixels->getStack($c,$t,$bigEndian);

Returns one stack of pixels from this file.  The $bigEndian
parameter specifies which endian-ness you want the pixels to be in.
If not specified, it defaults to network order (big-endian).

=cut

sub getStack {
    my ($self,$c,$t,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are write-only" unless $isFinished;

    my $buf = $pix->GetStack($c,$t);
    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    return $buf;
}

=head2 getPlane

	my $buf = $pixels->getPlane($z,$c,$t,$bigEndian);

Returns one plane of pixels from this file.  The $bigEndian parameter
specifies which endian-ness you want the pixels to be in.  If not
specified, it defaults to network order (big-endian).

=cut

sub getPlane {
    my ($self,$z,$c,$t,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are write-only" unless $isFinished;

    my $buf = $pix->GetPlane($z,$c,$t);
    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    return $buf;
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
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are write-only" unless $isFinished;

    my $buf = $pix->GetROI($x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1);
    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    return $buf;
}

=head2 setPixels

	$pixels->setPixels($buf,$bigEndian);

Sets the entire pixel array for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setPixels {
    my ($self,$buf,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are read-only" if $isFinished;

    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    $pix->SetPixels($buf);
    return;
}

=head2 setStack

	$pixels->setStack($buf,$c,$t,$bigEndian);

Sets a single stack of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setStack {
    my ($self,$buf,$c,$t,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are read-only" if $isFinished;

    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    $pix->SetStack($buf,$c,$t);
    return;
}

=head2 setPlane

	$pixels->setPlane($buf,$z,$c,$t,$bigEndian);

Sets a single plane of pixels for this file.  The $bigEndian parameter
specifies which endian-ness the given pixels are in.  If not
specified, it defaults to network order (big-endian).

=cut

sub setPlane {
    my ($self,$buf,$z,$c,$t,$destBigEndian) = @_;
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are read-only" if $isFinished;

    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    $pix->SetPlane($buf,$z,$c,$t);
    return;
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
    $destBigEndian ||= 1;
    my ($pix,undef,undef,undef,undef,undef,
        $bbp,$isFinished,undef,undef,$srcBigEndian,undef) = @$self;
    die "Pixels are read-only" if $isFinished;

    Repacker::repack($buf,length($buf),$bbp,
                     $srcBigEndian,$destBigEndian);
    $pix->SetROI($buf,$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1);
    return;
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

# inherit sub convertStack

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

# inherit sub convertPlane

=head2 convertPlaneFromTIFF

	$pixels->convertPlaneFromTIFF($tiffFile,$z,$c,$t);

Fills in a plane in the pixels file from another file, which is
assumed to be in the TIFF format.  The TIFF is assumed to contain
exactly one plane of pixels.

=cut

sub convertPlaneFromTIFF {
    my ($self,$tiffFile,$z,$c,$t) = @_;
    die "Pixels are read-only" if $self->[FINISHED];
    die "Only OME::LocalFile TIFF's are currently supported"
      unless UNIVERSAL::isa($tiffFile,"OME::LocalFile");
    my $pix = $self->[PIX];
    $pix->TIFF2Plane($tiffFile->getFilename(),$z,$c,$t);
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

# inherit sub convertPlane

=head2 finishPixels

	$pixels->finishPixels();

Marks the end of the writeable phase of this pixels file's life cycle.
After this method has been called, none of the set* or convert*
methods can be called.

=cut

sub finishPixels {
    my $self = shift;
    my $filename = $self->[FILENAME];
    my $header_filename = "${filename}.header";

    $self->[FINISHED] = 1;

    # Read in the pixels' dimensions from the header file
    CORE::open HEADER, "> $header_filename"
      or die "Cannot open header file $header_filename";

    my @output = @{$self}[SIZE_X..BIG_ENDIAN];
    print HEADER join("\t",@output),"\n";

    close HEADER;

    return;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


