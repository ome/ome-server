# OME/Graphics/GD.pm

# Copyright (C) 2002 Open Microscopy Environment
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

package OME::Graphics::GD;

use strict;
use OME::Graphics;
use GD;
#use GD::Polyline;

use vars qw($VERSION @ISA);
$VERSION = 2.000_000;
@ISA = ("OME::Graphics");

# new
# ---

sub new {
my $proto = shift;
my $class = ref($proto) || $proto;
my %params = @_;
	
	my $self = $class->SUPER::new(@_);
	
# The width and height fields are set by the parent (Graphics).
# Allocate a new image if one wasn't passed as a parameter, and wasn't defined by a parent.
# The parameter over-rides an image set by the parent.
# If a new image is allocated, its set up to be transparent.
# If one was passed in, or exists already, we don't mess with it.
	if (exists $params{image} and defined $params{image}) {
		$self->{image} = $params{image};
	} elsif (not exists $self->{image} or not defined $self->{image}) {
		my $err;
		$self->{image} = new GD::Image($self->{width},$self->{height});
		$self->{black} = $self->{image}->colorResolve(0,0,0);
		$self->{image}->transparent($self->{black});
		$self->{image}->interlaced('true');
	}

	bless $self,$class;
	return $self;
}


# Method Color
# This method will always return a color of the ColorIndex type as specified in GD.pm,
# Either by allocating a new one, or by returning a color already existing in the image.
# The parameter is an array reference to [Red, Green, Blue].
# If the parameter is not an array reference, this method will return -1,
# which is generally interpreted as 'none'.
sub Color {
my $self = shift;
my $colorIn = shift;
my $color;

# If we got an array reference, then try to get the color set up in the image.
# First we try for an exact color if already defined, or a new one if not.
# If we ran out of colors and can't make a new one, then we get the closest one.
	if (ref $colorIn) {
		$color = $self->{image}->colorResolve( @$colorIn );
		$color = $self->{image}->colorClosest( @$colorIn ) if $color < 0;
# Otherwise we return -1.
	} else {
		$color = -1;
	}
	
	return $color;
	
}

# Method Path
# very very poor SVG 'path' interpreter for GD.  FIXME?
sub Path {
my $self = shift;
my $path = shift;
my $poly;
my @vertices;
my @tokens = split (' ',$path);
my $i;

#	($path =~ /[Zz]/) ? $poly = new GD::Polygon : $poly = new GD::Polyline;
	$poly = new GD::Polygon;


	for ($i = 0; $i < $#tokens;) {
		if ($tokens[$i++] =~ /[MmLl]/) {
			$poly->addPt ( $tokens[$i++],$tokens[$i++] );
		}
	}

	return ($poly);
}



sub imageType {
return 'image/png';
}

sub getImage {
my $self = shift;
	return ($self->{image}->png);
}



1;

