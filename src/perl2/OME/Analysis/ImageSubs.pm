# OME/Analysis/ImageSubs.pm

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


package OME::Analysis::ImageSubs;

=head1 NAME

OME::Analysis::ImageSubs   -  useful routines for image analysis

=head1 SYNOPSIS

use OME::Analysis::ImageSubs


=head1 DESCRIPTION

    This file holds various little analysis routines useful as a
toolset in constructing larger image analysis tasks.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);
our @EXPORT = qw( dilate erode onCount connCount);

use Log::Agent;
use OME::Image::Pix;

use constant ON_THRESH => 4;

use constant IGNORE_CONN => 8;
use constant PRESERVE_CONN => 1;
use constant CHANGE_CONN   => 2;

use constant ERODE  => 1;
use constant DILATE => 2;

=head2 B<onCount>

    ($number, $bitmask) = onCount($pRef, $sizeX, $sizeY, $pxiSz, $target, $maskSize, $onLevel)

        $pRef     - refence to an XY plane of pixels
        $sizeX    - number of pixels in a row
        $sizeY    - number of pixels in a column
        $pixSz    - size of a pixel, in bytes
        $target   - offset into the plane of the target pixel
        $maskSize - length of side of square mask
        $onLevel  - the threshold value of an ON pixel

    Returns a list consisting of a pixel count and a bitmask. The count
value holds the number of pixels surrounding a target pixel that have a
value at or above the ON threshold value. The routine uses a passed square
mask to determine which area around the target to examine. Any part of
the mask that falls outside of the image plane is ignored.
    The bitmask records which of the 8-neighbors of the target pixel have
a value at or above the threshold value. This bitmask can be used to
calculate how many 8-connected groups the target pixel's neighborhood
contains.

    Image plane pixel values are assumed to be integers.

=cut

sub onCount {
    my ($pRef, $sizeX, $sizeY, $pixSz, $target, $maskSize, $onLevel) = @_;

    my $cnt = 0;
    my $bitmask = 0;

    # the mask is square of edge length $maskSize overlaying the $target pixel
    my $halfwide = $maskSize >> 1;
    my $imgY = int($target/$sizeX) - $halfwide;      # starting row
    my $imgX = ($target % $sizeX) - $halfwide;       # starting column

    for (my $y = 0; $y < $maskSize; $y++) {
	my $offset = ($imgY + $y)*$sizeX + $imgX;
	for (my $x = 0; $x < $maskSize; $x++) {
	    $bitmask <<= 1;
	    next
		if ((($imgY + $y) < 0) || 
		    ($imgY+$y >= $sizeY) ||
		    ($imgX+$x >= $sizeX));
	    next
		if (int($offset/$sizeX) < $imgY+$y);
	    if (vec($$pRef, $offset++, $pixSz) >= $onLevel) {
		$cnt++;
		if ($offset != $target) {
		    $bitmask |= 1;
		}
	    }
	}
    }

    return ($cnt, $bitmask);
}



=head2 B<connCount>

     $cnt = connCount($bitmask)

    This routine calculates the number of 8-connected groups in
the target pixel's 8-neighborhood. A pixel's 8-neighborhood contains
the 8 pixels which are immediately adjacent to it -- horizontally,
vertically, or diagonally. An 8-connected group of pixels is one for which
each of the pixels is an 8-neighbor of at least one of the other pixels in 
the group, excluding the target pixel. 


         $bitmask - a string of 8 bits that represents the
                    target pixel's 8 neighbors. If a bit is
                    on, then the corresponding pixel is on.
                    Expects that the bitmask was constructed
                    by a routine scanning each x line in turn
                    as it steps through y values, producing a
                    mask in this pixel order:

                         1 2 3
                         4   5
                         6 7 8

                    This routine has to take this bit ordering into 
                    account, e.g. by testing that bit 5 (not bit 4)
                    is adjacent to bit 3.

                    Count # of non-adjacent off bits to determine
                    # of separate groups. Note that bits 1, 3, 6, or 8
                    may be off without creating a gap, since their
                    adjacent pixels are still connected to a diagonal
                    neighbor.

=cut


sub connCount {
    my $bitmask = shift;
    my $zerocnt = 0;
    my $gapcnt = 0;
    my $maskref = [7, 6, 5, 3, 4, 0, 1, 2];
    my $mask;

    for (my $cnt = 0; $cnt < 8; $cnt++) {
	$mask = (1 << $$maskref[$cnt]);
	if ($mask & $bitmask) {
	    if ($zerocnt > 1) {
		$gapcnt++;
	    } 
	    elsif ($zerocnt == 1) {
		if (($cnt == 2) || ($cnt == 4) || ($cnt == 6)) {
		    $gapcnt++;
		}
	    }
	    $zerocnt = 0;
	} 
	else {
	    $zerocnt++;
	}
    }

    return $gapcnt == 0 ? 1 : $gapcnt;
}



=head2 B<erode>

    erode($pix, $xSize, $ySize, $pixSz, $theZ, $theC, $theT)

        $pix - reference to a plane of pixels
        $xSize  -  pixel plane x dimension
        $ySize  -  pixel plane y dimension
        $pixSz  -  size of a pixel
        $theZ   -  the Z coordinate of the plane
        $theC   -  the Channel (Wavelength) coordinate of the plane
        $theT   -  the Time coordinate of the plane

This routine strips out pixels that are at least partially isolated. It thins
regions and erases singleton spots.

=cut


sub erode {
    erode_or_dilate(ERODE, @_);
}



=head2 B<dilate>

    dilate($pix, $xSize, $ySize, $pixSz, $theZ, $theC, $theT)

        $pix - reference to a plane of pixels
        $xSize  -  pixel plane x dimension
        $ySize  -  pixel plane y dimension
        $pixSz  -  size of a pixel
        $theZ   -  the Z coordinate of the plane
        $theC   -  the Channel (Wavelength) coordinate of the plane
        $theT   -  the Time coordinate of the plane

This routine adds pixels adjacent to pixels that are already adjacent
to enough other lit pixels. It bulks up regions and fills in small gaps.

=cut

sub dilate {
    erode_or_dilate(DILATE, @_);
}


=head2 B<erode_or_dilate>

    erode_or_dilate ($Which_operation, <rest of erode & dilate's args>)

This helper routine does the work for both erode & dilate, since
their code is almost identical.

=cut

sub erode_or_dilate {
    my $op = shift;
    my ($pix, $xSize, $ySize, $pixSize, $theZ, $theC, $theT)  = @_;
    my $plane = $pix->getPlane($theZ, $theC, $theT);

    # if no plane stats, default lowest On level to 1/2 dynamic range
    my $onLevel = 1;
    my $onLevel <<= (7 + ($pixSize-1)*8);

    my $planeSize = $xSize * $ySize;
    for (my $px = 0; $px < $planeSize; $px++) {
	my $proceed;
	if ($op == ERODE) {
	    $proceed = (vec($plane, $px, $pixSize) >= $onLevel);
	}
	else {
	    $proceed = (vec($plane, $px, $pixSize) < $onLevel);
	}
	if ($proceed) {
	    (my $onCnt, my $bitmask) = onCount($plane, $xSize, $ySize, 
					       $pixSize, $px, 3, $onLevel);
	    if ($op == ERODE) {
		if ($onCnt < ON_THRESH) {
		    my $connCnt = connCount($bitmask);
		    if ($connCnt == PRESERVE_CONN) {
			# TODO - fill pixel w/ mean value of plane
			vec($plane, $px, $pixSize) = 0;
		    }
		}
	    }
	    else {
		if ($onCnt >= ON_THRESH) {
		    #my $connCnt = connCount($bitmask);
		    #if ($connCnt >= PRESERVE_CONN) {
		    # TODO - fill pixel w/ mean value of plane
		    vec($plane, $px, $pixSize) = $onLevel;
		    #}
		}
	    }
	}
    }

}


1;
