# OME/Analysis/Modules/Statistics/StackStatistics.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Statistics::StackStatistics;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Image::Server;
use OME::Tasks::PixelsManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

=head1 NAME

OME::Analysis::Modules::Statistics::StackStatistics

=head2 DESCRIPTION

This analysis module calculates the standard stack-based pixel
statistics.  It does not actually perform any computations, though,
because it assumes that the pixels are stored on an image server,
which will have already calculated these statistics.  Therefore, it
reads the statistics from the image server and writes them to the
database as the output of this module.

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

    # The image server will have already calculated the statistics, so
    # we'll just load them in from the image server, and write them to
    # the database.

    my $stats = OME::Image::Server->
      getStackStatistics($pixels_attr->ImageServerID());

    foreach my $c (keys %$stats) {
        foreach my $t (keys %{$stats->{$c}}) {
            my $sstat = $stats->{$c}{$t};

            $self->newAttributes('Minima',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  Minimum => int($sstat->{Minimum}),
                                 },
                                 'Maxima',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  Maximum => int($sstat->{Maximum}),
                                 },
                                 'Mean',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  Mean => $sstat->{Mean},
                                 },
                                 'Geomean',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  GeometricMean => $sstat->{Geomean},
                                 },
                                 'Sigma',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  Sigma => $sstat->{Sigma},
                                 },
                                 'Geosigma',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  GeometricSigma => $sstat->{Geosigma},
                                 },
                                 'Centroid',
                                 {
                                  TheC => $c,
                                  TheT => $t,
                                  X    => $sstat->{CentroidX},
                                  Y    => $sstat->{CentroidY},
                                  Z    => $sstat->{CentroidZ},
                                 },
                                );
        }
    }
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
