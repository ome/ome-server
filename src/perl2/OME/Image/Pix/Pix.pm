# OME/Image/Pix.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:
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


package OME::Image::Pix;

require 5.005;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OME::Image::Pix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ();

our @EXPORT_OK = ();

our @EXPORT = ();
our $VERSION = 2.000_000;

bootstrap OME::Image::Pix $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

OME::Image::Pix - A Perl interface to the OME libpix library

=head1 SYNOPSIS

  use OME::Image::Pix;
  my $pix = new OME::Image::Pix ('/OME/repository/123456.orf',
  	$sizeX,$sizeY,$sizeZ,$numWaves,$numTimes,$bytesPerPixel)
  	|| die "Could not instantiate OME::Image::Pix object";

  # Get the entire 5-D image
  my $pixels = $pix->GetPixels () || die "Could not allocate buffer\n";

  # Get an XY plane of pixels by specifying theZ, theW, and theT
  my $plane = $pix->GetPlane ($theZ,$theW,$theT) || die "Could not allocate buffer\n";

  # The returned scalar can be unpacked into an array.  This is probably never a good idea:
  my @pixArray = unpack ("S*",$plane);

  # It can also be manipulated by Perl's vec() function:
  # Note that these changes will not be permanent (i.e. written to the image file)
  # unless $pix->SetPlane() (or another Set method) is called.
  vec ($plane, $sizeX * $x + $y, 16) = 3;

  # Get an XYZ stack of pixels by specifying theW, and theT
  my $stack = $pix->GetStack ($theW,$theT) || die "Could not allocate buffer\n";

  # Get a 5D ROI:
  my $ROI = $pix->GetROI ($x0,$y0,$z0,$w0,$t0,$x1,$y1,$z1,$w1,$t1) || die "Could not allocate buffer\n";


  # Set the entire 5-D image.
  # $nPixOut is the number of pixels (not bytes) written to the file.  This value should be checked.
  my $nPixOut = $pix->SetPixels ($pixels);

  # Set an XY plane of pixels by specifying theZ, theW, and theT
  my $nPixOut = $pix->SetPlane ($plane,$theZ,$theW,$theT);

  # Set an XYZ stack of pixels by specifying theW, and theT
  my $nPixOut = $pix->SetStack ($stack,$theW,$theT);

  # Set a 5D ROI:
  my $nPixOut = $pix->SetROI ($ROI,$x0,$y0,$z0,$w0,$t0,$x1,$y1,$z1,$w1,$t1);

  # Convert a plane of pixels to a TIFF file (8 or 16 bits per pixel)
  my $nPixOut = $pix->Plane2TIFF ($theZ,$theW,$theT,'testTIFF16.tiff');

  # Convert a plane of pixels to an 8 bit per pixel TIFF file
  # $pix8 = ($pix16 - $offset) * $scale;
  # if $pix8 is outside of the range 0-255, it is clipped.
  my $nPixOut = $pix->Plane2TIFF8 ($theZ,$theW,$theT,'testTIFF8.tiff',$scale,$offset);

  # Convert a TIFF file to a plane of pixels
  my $nPixOut = $pix->TIFF2Plane ('testTIFF.tiff',$theZ,$theW,$theT);
  
  # Set an arbitrary file for conversion to OME format - $bigEndian is 1 for big endian files, 0 otherwise
  # byte swapping will be accomplished automatically.  This function returns 1 if the file could be opened, 0 otherwise.
  $pix->setConvertFile ('path/to/somePixelFile',$bytesPerPixel,$bigEndian)
  # All of the convert methods return the number of pixels converted.
  # $offset is the offset in the source file where the read begins.
  # Convert a row, a set of rows, a plane and an XYZ stack from the source file to the OME format file
  $nPix = $pix->convertRow ($offset,$theY,$theZ,$theW,$theT);
  $nPix = $pix->convertRows ($offset,$nRows,$theY,$theZ,$theW,$theT);
  $nPix = $pix->convertPlane ($offset,$theZ,$theW,$theT);
  $nPix = $pix->convertStack ($offset,$theW,$theT);
  # Call convertFinish to close the source file when you are finished with it.
  # This will be called automatically when perl garbage collects the $pix object.
  # setConvertFile calls this for you, so you can keep calling setConvertFile to incorporate
  # multiple files into an OME Image, and call this at the end.
  $pix->convertFinish();





=head1 DESCRIPTION

This is implemented by blessing the C struct pointer used in libpix (returned by libpix->NewPix())
into the Perl class OME::Image::Pix.
The purpose of this class is to provide some pixel get/set and manipulation methods implemented in C.
This class is meant to be used by OME::Image.  It is fully independent of it, but not very useful without it.

Usually, access to Pix is handled through OME::Image:


  my $image = #However you got your OME::Image
  my $plane = $image->GetPix->GetPlane ($theZ, $theT, $theW);

There is nothing special to do with the memory allocated in OME::Image::Pix.  All memory is safely passed to Perl and
is managed by Perl's garbage collection.  In other words, move along, nothing to see here, don't mind the man behind the curtain.
There are some more memory allocation/deallocation details for the pathologically curious:

The memory allocated in C by NewPix is returned to Perl as an object blessed into the OME::Image::Pix package (a reference to a scalar).
The memory is de-allocated during the regular Perl garbage collection process through the DESTROY Perl class call, 
which in-turn calls libpix->FreePix().

Memory allocated in C by the Get methods return that memory as a regular Perl 'string', which is not NULL-terminated and
which may have embedded NULLs.  This can be manipulated in Perl using vec() and unpack().
This string is also targeted for regular Perl garbage collection just like regular strings.
For efficiency, the memory allocated is not copied to the Perl string.  The pointer to Perl's string memory is simply re-assigned to what was
allocated in libpix.  You can dig around Pix.xs and PERLGUTS to figure out how that's done.

=head2 EXPORT

Nothing is exported.


=head1 AUTHOR

Ilya G. Goldberg (igg@nih.gov)

=head1 SEE ALSO

OME::Image.

=cut
