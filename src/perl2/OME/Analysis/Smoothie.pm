# OME/Analysis/SmoothOrFill.pm

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


package OME::Analysis::SmoothOrFill;

=head1 NAME

OME::Analysis::SmoothOrFill  -  smooth edges, remove small spots, fill gaps


=head1 SYNOPSIS

use OME::Analysis::SmoothOrFill


=head1 DESCRIPTION


    This package provides tools that can remove small spots (shot noise) from
    images, smooth edges in an image, or fill in gaps in an image.


=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);
our @EXPORT = qw( Smooth Fill);

use Log::Agent;
use OME::Image::Pix;


=head1 METHODS

=head2 B<new>

    my $imageSmoothie = OME::Analysis::Smoothie->
        new($location,$session,$module,$node);

=cut


sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$module,$node);

    bless $self,$class;
    return $self;
}




=head2 B<smooth>

    $imageSmoothie->smooth($image, $numIterations)

    Perform I<$numIterations> iterations of the sequence of first eroding
    the passed image, and then dilating the image. This sequence of
    operations, performed in this order, smooth out spikes and sharp corners.
    It also eliminates small spots. This latter effect cleans up shot noise
    and other small random clutter. But it may also erase small puncta
    signals that are a legitimate part of the image.

=cut

sub smooth {
    my $self   = shift;
    my $numIters = shift;

    my $image = $self->getCurrentImage();
    my $pixels = $self->getImageInputs("Pixels")->[0];
    my $numChan = $pixels->SizeC();
    my $numTimes = $pixels->SizeT();
    my $numZ = $pixels->SizeZ();
    my $numY = $pixels->SizeY();
    my $numX = $pixels->SizeX();
	my ($pixSz) = OME::Tasks::PixelsManager->getPixelTypeInfo( $pixels->PixelType() );

    for (my $t = 0; $t < $numT; $t++) {
	for (my $c = 0; $c < $numC; $c++) {
	    for (my $z = 0; $z < $numZ; $z++) {
		while ($numIters > 0) {
		    $self->erode($pixels, $numX, $numY, $pixSz, $z, $c, $t);
		    $self->dilate($pixels, $numX, $numY, $pixSz, $z, $c, $t);
		    $numIters--;
		}
	    }
	}
    }
}




=head2 B<fill>

    $imageSmoothie->fill($image, $numIterations)

    Perform I<$numIterations> iterations of th0e sequence of first dilating
    the passed image, followed by eroding the image. This sequence of
    operations, performed in this order, fill in small holes & gaps. This
    routine cannot distinguish between gap caused by imperfect optics
    or actual gaps in the specimen.

=cut



sub fill {
    my $self   = shift;
    my $numIters = shift;

    my $image = $self->getCurrentImage();
    my $pixels = $self->getImageInputs("Pixels")->[0];
    my $numChan = $pixels->SizeC();
    my $numTimes = $pixels->SizeT();
    my $numZ = $pixels->SizeZ();
    my $numY = $pixels->SizeY();
    my $numX = $pixels->SizeX();
	my ($pixSz) = OME::Tasks::PixelsManager->getPixelTypeInfo( $pixels->PixelType() );

    for (my $t = 0; $t < $numT; $t++) {
	for (my $c = 0; $c < $numC; $c++) {
	    for (my $z = 0; $z < $numZ; $z++) {
		while ($numIters > 0) {
		    $self->dilate($pixels, $numX, $numY, $pixSz, $z, $c, $t);
		    $self->erode($pixels, $numX, $numY, $pixSz, $z, $c, $t);
		    $numIters--;
		}
	    }
	}
    }

}



1;
