# OME/Analysis/Modules/Statistics/PlaneHistogram.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Histogram::PlaneHistogram;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Image::Server;
use OME::Tasks::PixelsManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

=head1 NAME

OME::Analysis::Modules::Histogram::PlaneHistogram

=head2 DESCRIPTION

This analysis module calculates the plane-based histogram.
It does not actually perform any computations, though,
because it assumes that the pixels are stored on an image server,
which will have already calculated these statistics.  Therefore, it
reads the histogram from the image server and writes them to the
database as the output of this module. For more info, read the documentation
on OMEIS's GetPlaneHist method.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    return $self;
}


sub startImage {
    my $self = shift;
    $self->SUPER::startImage(@_);

    my ($image) = @_;
    my $pixelses = $self->getCurrentInputAttributes('Pixels');

    die "Pixels input must be a singleton"
      unless scalar(@$pixelses) == 1;

    my $pixels_attr = $pixelses->[0];
    my $pix = OME::Tasks::PixelsManager->serverLoadPixels($pixels_attr);

    # The serverLoadPixels call will have activated the Pixels's
    # repository, so that calls to the OME::Image::Server class will
    # be routed to the correct image server.

    # The image server will have already calculated the histogram, so
    # we'll just load them in from the image server, and write them to
    # the database.

    my $hist = OME::Image::Server->
      getPlaneHistogram($pixels_attr->ImageServerID());

    foreach my $z (keys %$hist) {
        foreach my $c (keys %{$hist->{$z}}) {
            foreach my $t (keys %{$hist->{$z}{$c}}) {
            	$self->newAttributes('PlaneHistNumBins',
            				{
            				 TheZ => $z,
                             TheC => $c,
                             TheT => $t,
            				 NumBins => 128
							});
			    my ($lowBound,$uppBound,@histBins) = @{%$hist->{$z}{$c}{$t}}; 
				$self->newAttributes('PlaneHistLowBound',
            				{
            				 TheZ => $z,
                             TheC => $c,
                             TheT => $t,
            				 LowBound => $lowBound
							});
				$self->newAttributes('PlaneHistUppBound',
            				{
            				 TheZ => $z,
                             TheC => $c,
                             TheT => $t,
            				 UppBound => $uppBound
							});
							
         		my $iter = 0;							
            	foreach my $i (@histBins) {
    	            $self->newAttributes('PlaneHistBins',
                                     {
                                      TheZ => $z,
                                      TheC => $c,
                                      TheT => $t,
                                      BinIndex => $iter,
                                      BinCount => $i
                                     });
             	   $iter++;
				}
            }
        }
    }
}


1;

__END__

=head1 AUTHOR

Tom Macura, <tmacura@nih.gov>
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
