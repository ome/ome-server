package OME::Graphics::GD::Centroids;
use OME::Graphics::GD;
use strict;
use vars qw($VERSION @ISA);
$VERSION = 2.000_000;
@ISA = ("OME::Graphics::GD");

# new
# ---
# Centroids are drawn only at the Z section closest to the actual centroid.
# They are never drawn on other Z sections or other timepoints.

sub new {
my $proto = shift;
my $class = ref($proto) || $proto;
my %params = @_;
	
	my $self = $class->SUPER::new(@_);
	
	bless $self,$class;

	if (exists $params{weight} and defined $params{weight}) {
		$self->{weight} = $params{weight};
	} else {
		$self->{weight} = 1.5;
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
# The image was set up by the GD parent.
#
#  The fill and draw colors have to be allocated in the image.
#  Colors in the parameters to new are passed in as R,G,B array refs (i.e. color => [255,0,0] for red).
#  We must make sure that the image has the chosen color allocated.
#  If the exact color can't be allocated, then we choose the closest color.
#  In the actual object, these are stored as ColorIndex types specific for GD.
	if (exists $params{fill} and defined $params{fill}) {
		$self->{fill} = $self->Color($params{fill});
	} else {
# This is a no fill, set this to -1.
		$self->{fill} = -1;
	}

	if (exists $params{color} and defined $params{color}) {
		$self->{color} = $self->Color($params{color});
	} else {
# This is a red drawing color.
		$self->{color} = $self->Color([255,0,0]);
	}

# The parent Graphics::GD will convert a path specification into a polygon, polyline, whatever.
# This primitive is composed of two components if allZ is specified, crosshairs are drawn over all
# z-sections.  The centroid is drawn over only those Z sections which match the centroid's rounded Z.
# If we don't get a parameter, we make up a crosshair with a box inside.
	if (not exists $params{crosshair} or not defined $params{crosshair}) {
		$params{crosshair} = 'M -4 0 L 4 0 L 0 0 L 0 -4 L 0 4';
	}
	$self->{crosshair} = $self->Path ($params{crosshair});

	if (not exists $params{centroid} or not defined $params{centroid}) {
		$params{centroid} = 'M 0 3 L -3 0 L 0 -3 L 3 0 z';
	}
	$self->{centroid} = $self->Path ($params{centroid});

#
# Finally, we need to make sure we have a hash to play with.
# This hash gets used by lots of primitives, but not all of them.
# It may have been passed in in the parameters, or not.
# The GetHash method is originally defined in Graphics.
# The bits of the hash we need in this case are x0,y0,z0,x1,y1,z1,t.
	$self->InitHash (@_);

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
my $fill = $self->{fill};
my $x0s = $self->{x0};
my $y0s = $self->{y0};
my $z0s = $self->{z0};
my $ts = $self->{t};
my $nVectors = $#{@{$x0s}}+1;
my ($centroid,$crosshair);
my ($myZ,$myT);

	for ($i = 0;$i <  $nVectors; $i++ ) {
		$myZ = sprintf ("%d",$z0s->[$i]);
		$myT = sprintf ("%d",$ts->[$i]);
		next unless $allZ or $myZ == $theZ;
		next unless $allT or $myT == $theT;

	# draw the crosshair:
	#	Copy the crosshair and transform it.
		$crosshair = GD::Polygon->new;
        foreach ($self->{crosshair}->vertices) {
			$crosshair->addPt(@$_);
        }
		$crosshair->offset($x0s->[$i], $y0s->[$i]);
		$fill > 0 ? $image->filledPolygon($crosshair,$fill) : $image->polygon($crosshair,$color);

	# We're done unless we're drawing actual centroids.
		next unless $myT == $theT and $myZ == $theZ;

	# draw the centroid:
	#	Copy the centroid and transform it.
		$centroid = GD::Polygon->new;
        foreach ($self->{centroid}->vertices) {
			$centroid->addPt(@$_);
        }
		$centroid->offset($x0s->[$i], $y0s->[$i]);
		$fill > 0 ? $image->filledPolygon($centroid,$fill) : $image->polygon($centroid,$color)
	}
	
}

1;

