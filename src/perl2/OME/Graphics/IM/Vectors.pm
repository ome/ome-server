# OME/Graphics/IM/Vectors.pm

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
# Written by:  
#
#-------------------------------------------------------------------------------


package Graphics::IM::Vectors;
use Graphics::Vectors;
use strict;
use Image::Magick;
use vars qw($VERSION @ISA);
use OME;
$VERSION = $OME::VERSION;
@ISA = ("Graphics::Vectors");

# new
# ---

sub new {
my $proto = shift;
my $class = ref($proto) || $proto;
my %params = @_;
	
	my $self = $class->SUPER::new(@_);

	if (exists $params{color} and defined $params{color}) {
		$self->{color} = $params{color};
	} else {
		$self->{color} = "red";
	}
	
	if (exists $params{fill} and defined $params{fill}) {
		$self->{fill} = $params{fill};
	} else {
		$self->{fill} = 'red';
	}
	
	if (exists $params{weight} and defined $params{weight}) {
		$self->{weight} = $params{weight};
	} else {
		$self->{weight} = 1.5;
	}
	
	if (exists $params{arrow} and defined $params{arrow}) {
		$self->{arrow} = $params{arrow};
	} else {
#		$self->{arrow} = "M 0 0 L -5 -2.5 M 0 0 L -5 2.5";
		$self->{arrow} = "M 0 0 L -5 -3 L -5 3 z";
	}
	
	if (exists $params{allZ} and defined $params{allZ}){
		$self->{allZ} = $params{allZ} ;
	} else {
		$self->{allZ} = 1;
	}
	
	if (exists $params{allT} and defined $params{allT}) {
		$self->{allT} = $params{allT};
	} else {
		$self->{allT} = 0;
	}

# The width and height fields are set by the parent (Graphics).
# Allocate a new image if one wasn't passed as a parameter, and wasn't defined by a parent.
# The parameter over-rides an image set by the parent.
# If a new image is allocated, its set up to be transparent.
# If one was passed in, or exists already, we don't mess with it.
	if (exists $params{image} and defined $params{image}) {
		$self->{image} = $params{image};
	} elsif (not exists $self->{image} or not defined $self->{image}) {
		my $err;
		$self->{image} = new Image::Magick;
		$err = $self->{image}->Set(size=>$self->{width}.'x'.$self->{height});
		warn "$err" if "$err";
		$err = $self->{image}->Set(antialias=>'False');
		warn "$err" if "$err";
		$err = $self->{image}->ReadImage('xc:transparent');
		warn "$err" if "$err";
	}

	
	bless $self,$class;
	return $self;
}

sub Draw {
my $self = shift;
my $i;
my $allZ = $self->{allZ};
my $allT = $self->{allT};
my $theZ = $self->{theZ};
my $theT = $self->{theT};
my $image = $self->{image};
my $color = $self->{color};
my $weight = $self->{weight};
my $arrow = $self->{arrow};
my $fill = $self->{fill};
my $x0s = $self->{x0};
my $y0s = $self->{y0};
my $x1s = $self->{x1};
my $y1s = $self->{y1};
my $z0s = $self->{z0};
my $ts = $self->{t};
my $nVectors = $#{@{$x0s}}+1;
my ($x0,$y0,$x1,$y1);
my ($dX,$dY,$H);
my $err;

print "nVectors: $nVectors, arrow: '$arrow', color: $color, weight: $weight\n";
	for ($i = 0;$i <  $nVectors; $i++ ) {
		next unless $allZ or $z0s->[$i] == $theZ;
		next unless $allT or $ts->[$i] == $theT;
		$x0 = $x0s->[$i];
		$x1 = $x1s->[$i];
		$y0 = $y0s->[$i];
		$y1 = $y1s->[$i];
	# draw the line:
		$err = $image->Draw (antialias=>'False',stroke=>$color, strokewidth=>$weight, primitive=>'line', points=>"$x0,$y0 $x1,$y1");
		warn "$err" if "$err";
		
	# draw the arrow:
	#	<!-- matrix(dX/H,dY/H,-dY/H,dX/H,tX,tY) where dX = x2-x1, dY = y2-y1, H=sqr(dX^2+dY^2), tx and ty are translations -->
		$dX = $x1-$x0;
		$dY = $y1-$y0;
		$H = sqrt ( ($dX*$dX) + ($dY*$dY) );
	#	For some silly reason, we need to put an extra value in the matrix array.
		$err = $image->Draw (antialias=>'False', strokewidth=>$weight, affine => [$dX/$H, $dY/$H, -$dY/$H, $dX/$H, $x1, $y1,0],
			stroke=>$color, fill=>$fill, primitive=>'Path', points=>$arrow);
		warn "$err" if "$err";
	}
	
}

1;

