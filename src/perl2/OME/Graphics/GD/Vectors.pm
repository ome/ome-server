package Graphics::GD::Vectors;
use Graphics::GD;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("Graphics::GD");

# new
# ---

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

	if (exists $params{color} and defined $params{color}) {
		$self->{color} = $self->Color($params{color});
	} else {
# This is a red drawing color.
		$self->{color} = $self->Color([255,0,0]);
	}

	if (exists $params{fill} and defined $params{fill}) {
		$self->{fill} = $self->Color($params{fill});
	} else {
# Default is a fill with the same color, set this to -1 for no fill.
		$self->{fill} = $self->{color};
	}

# The parent Graphics::GD will convert a path specification into a polygon, polyline, whatever.
# If we don't get a parameter, we make up a nice little bitty arrow.
	if (not exists $params{arrow} or not defined $params{arrow}) {
		$params{arrow} = 'M 0 0 L -5 -3 L -5 3 z';
	}
	$self->{arrow} = $self->Path ($params{arrow});

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
my $x1s = $self->{x1};
my $y1s = $self->{y1};
my $z0s = $self->{z0};
my $ts = $self->{t};
my $nVectors = $#{@{$x0s}}+1;
my ($x0,$y0,$x1,$y1);
my ($dX,$dY,$H);
my $err;
my $arrow;

	for ($i = 0;$i <  $nVectors; $i++ ) {
		next unless $allZ or sprintf ("%d",$z0s->[$i]) == $theZ;
		next unless $allT or sprintf ("%d",$ts->[$i]) == $theT;

		$x0 = $x0s->[$i];
		$x1 = $x1s->[$i];
		$y0 = $y0s->[$i];
		$y1 = $y1s->[$i];
	# draw the line:
		$image->line($x0,$y0,$x1,$y1,$color);
		
	# draw the arrow:
	#	<!-- matrix(dX/H,dY/H,-dY/H,dX/H,tX,tY) where dX = x2-x1, dY = y2-y1, H=sqr(dX^2+dY^2), tx and ty are translations -->
		$dX = $x1-$x0;
		$dY = $y1-$y0;
		$H = sqrt ( ($dX*$dX) + ($dY*$dY) );
	#	Copy the arrow and transform it.
		$arrow = GD::Polygon->new;
        foreach ($self->{arrow}->vertices) {
			$arrow->addPt(@$_);
        }
		$arrow->transform($dX/$H, $dY/$H, -$dY/$H, $dX/$H, $x1, $y1);
		$fill > 0 ? $image->filledPolygon($arrow,$fill) : $image->polygon($arrow,$color)
	}
	
}

1;

