# OME/Analysis.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Program::CalculateImageStatistics;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
use OME::Session;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my ($proto,$analysis) = shift;
    my $class = ref($proto) || $proto;
    
    my $self = {
	analysis => $analysis
    };
    bless $self, $class;

    return $self;
}


sub startAnalysis {
    my ($self,$dataset) = @_;
}


sub analyzeOneImage {
    my ($self,$image,$imageParams) = @_;

    my $sizeX = $image->Field("sizeX");
    my $sizeY = $image->Field("sizeY");
    my $sizeZ = $image->Field("sizeZ");
    my $sizeW = $image->Field("sizeW");
    my $sizeT = $image->Field("sizeT");

    my $pixels = $image->GetPixelArray(0,$sizeX-1,
				       0,$sizeY-1,
				       0,$sizeZ-1,
				       0,$sizeW-1,
				       0,$sizeT-1);
    my $length = scalar(@$pixels);
    
    use integer;
    my $sum = 0;
    for (my $i = 0; $i < $length; $i++)
    {
	$sum += $pixels->[$i];
    }

    no integer;
    my $mean = $sum/$length;

    use integer;
    my $sdsum = 0;
    for (my $i = 0; $i < $length; $i++)
    {
	my $diff = ($pixels->[$i]) - $mean;
	$sdsum += ($diff * $diff);
    }

    no integer;
    my $stddev = $sdsum / ($length-1);
    $stddev = sqrt($stddev);

    print "Mean:  $mean\n";
    print "Sigma: $stddev\n";
}


sub finishAnalysis {
    my ($self) = @_;
}
