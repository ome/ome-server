# OME/Analysis/Modules/Statistics/StackHistogram.pm

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


package OME::Analysis::Modules::Histogram::StackHistogram;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Image::Server;
use OME::Tasks::PixelsManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

=head1 NAME

OME::Analysis::Modules::Histogram::StackHistogram

=head2 DESCRIPTION

This analysis module calculates the stack-based histogram.
It does not actually perform any computations, though,
because it assumes that the pixels are stored on an image server,
which will have already calculated these statistics.  Therefore, it
reads the histogram from the image server and writes them to the
database as the output of this module. For more info, read the documentation
on OMEIS's GetStackHist method.

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
      getStackHistogram($pixels_attr->ImageServerID());
	  
    foreach my $c (keys %$hist) {
  	     foreach my $t (keys %{$hist->{$c}}) {
       		my ($lowBound,$uppBound,@histBins) = @{%$hist->{$c}{$t}};
		my $hist_str;

		# convert list of histogram bins into a space delimited string
       		foreach my $i (@histBins){
			$hist_str .= "$i ";
		}

          	$self->newAttributes('StackHistNumBins',
           		{
                        TheC => $c,
                        TheT => $t,
           		NumBins => 128,
            		LowBound => $lowBound,
            		UppBound => $uppBound,
			Bins => $hist_str
		});
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
