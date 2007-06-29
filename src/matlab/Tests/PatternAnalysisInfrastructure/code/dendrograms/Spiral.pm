use strict;

package Spiral;
use POSIX;

my $pi = 3.141592654;

sub new {
	my ( $proto, $markerRadius, $x0, $y0, $theta0 ) = @_;
	my $class = ref( $proto ) || $proto;
	
	my $self = {
		markerRadius => $markerRadius,
		theta        => $theta0 || 0,
		exponent     => 1,  # Archemedian spiral
		x0           => $x0 || 0,
		y0           => $y0 || 0,
	};
	bless $self, $class;
	
	$self->_calibrateTension();
	
	return $self;
}

sub resetAndRecenter {
	my ( $self, $x0, $y0, $theta0 ) = @_;
	$self->{ x0 } = $x0 || 0;
	$self->{ y0 } = $y0 || 0;
	$self->{ theta } = $theta0 || 0;
	return $self;
}

sub getR_incTheta {
	my ( $self ) = @_;
	my $r = $self->getR();
	$self->incTheta();
	return $r;
}

sub getR {
	my ( $self, $theta ) = @_;
	$theta = $theta || $self->{ theta };
	return $self->{ tension } * $theta ** $self->{ exponent }; 	
}

sub getTheta {
	my ( $self, $r ) = @_;
	return $self->{ theta }
		unless( $r );
	return ( $r / $self->{ tension } ) ** ( 1/ $self->{ exponent } );
}

sub _calibrateTension {
	my ( $self ) = @_;
	$self->{ tension } = $self->{ markerRadius } / $pi;
}

sub incTheta {
	my ( $self ) = @_;
	my $theta = $self->{ theta };
	my $r     = $self->getR();
	if( $theta > 0 ) {
		$theta += POSIX::acos(1 - 2*($self->{ markerRadius } ** 2) / ( $r ** 2 ));
	} else {
		$theta = $self->getTheta( $self->{ markerRadius }*2 );#, $self->{ spiral_tension } );
	}
	$self->{ theta } = $theta;
	return $theta;
}

sub incThetaApprox {
	# This method approximates the spiral as a circle and increments theta based on the
	# instantaneous circumference and marker width
	my ( $self ) = @_;
	my $theta = $self->{ theta };
	my $r    = $self->getR();
	if( $theta > 0 ) {
		my $instantaneous_circum = $r * 2*$pi;
		my $ticks_in_this_circum = $instantaneous_circum / (2 * $self->{ markerRadius });
		my $tick_radians = 2 * $pi / $ticks_in_this_circum;
		$theta += $tick_radians;
	} else {
		$theta = $self->getTheta( $self->{ markerRadius }*2 );#, $self->{ spiral_tension } );
	}
	$self->{ theta } = $theta;
	return $theta;
}

1;