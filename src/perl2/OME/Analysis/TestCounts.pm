# OME/Analysis/TestCounts.pm

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


package OME::Analysis::TestCounts;

use OME::Analysis::PerlAnalysis;

use strict;
our $VERSION = '1.0';


use base qw(OME::Analysis::PerlAnalysis);

sub new {
    my ($proto,$factory) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($factory);

    bless $self,$class;
    return $self;
}


sub precalculateImage {
    my ($self) = @_;
    my $factory = $self->{_factory};
    my $image = $self->{_currentImage};

    my $average = $self->{_imageInputs}->{Average}->avg_intensity();
    
    my $dimensions = $image->Dimensions();

    my $sizeX = $dimensions->size_x();
    my $sizeY = $dimensions->size_y();
    my $sizeZ = $dimensions->size_z();
    my $sizeW = $dimensions->num_waves();
    my $sizeT = $dimensions->num_times();

    my $pix = $image->Pix()->GetPixels();
    #my $pixels = $image->GetPixelArray(0,$sizeX-1,
	#			       0,$sizeY-1,
	#			       0,$sizeZ-1,
	#			       0,$sizeW-1,
	#			       0,$sizeT-1);
    #my $length = scalar(@$pixels);
    my @pixels = unpack(($bbp == 8)? "C*": "S*",$pix);
    my $length = scalar(@pixels);
    
    my $numBright = 0;
    my $numAverage = 0;
    my $numDim = 0;
    foreach my $pixel (@pixels) {
	$numBright++ if $pixel > $average;
	$numAverage++ if $pixel == $average;
	$numDim++ if $pixel < $average;
    }

    print STDERR "      Bright:  $numBright\n";
    print STDERR "      Average: $numAverage\n";
    print STDERR "      Dim:     $numDim\n";

    my $datatype = OME::DataType->findByTable("SIMPLE_COUNTS");
    my $pkg = $datatype->getAttributePackage();
    my $attribute = $factory->newObject($pkg,{
	image_id    => $image->id(),
	num_bright  => $numBright,
	num_average => $numAverage,
	num_dim     => $numDim
    });

    my $imageOutputs = {
	'Bright count'  => $attribute,
	'Average count' => $attribute,
	'Dim count'     => $attribute
    };

    $self->{_imageOutputs} = $imageOutputs;
}


1;
