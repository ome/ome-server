package OME::Graphics::JavaScript::Layer::Vectors;
use strict;
use OME::Graphics::JavaScript::Layer;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("OME::Graphics::JavaScript::Layer");

my $JStype = 'Vectors';
my $JSobject = <<ENDJSOBJECT
function $JStype (CGI_URL,name,color,allZ,allT,optionsStr) {
	this.base = Layer;
	this.base(CGI_URL,name,optionsStr);
	this.color = color || "red";
	this.allZ = allZ || true;  // N.B.  NOT Boolean objects.
	this.allT = allT || false;
	this.options.push ('allZ');
	this.options.push ('allT');
	this.options.push ('color');

	this.optionsStr = optionsStr;

	this.SetColor = SetColor;
	
	return this;
	
	function SetColor (color) {
//		alert (this.name+'->SetColor('+color+')');
		this.color = color;
		this.Dirty();
		this.RedrawImage();
	}
	
}
$JStype.prototype = new Layer;

ENDJSOBJECT
;
# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;
	my $self = $class->SUPER::new(@_);
	bless $self,$class;
	
	$self->{JStype} = $JStype;
	push (@{$self->{JSdeps}},$JStype);
	push (@{$self->{JSdefs}},$JSobject);
	

	if (exists $params{color} and defined $params{color}) {
		$self->{color} = $params{color};
	} else {
		$self->{color} = "red";
	}




	return $self;
}



sub JSinstance {
my $self = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $LayerCGI = $self->{LayerCGI};
my $allZ = $self->{allZ} ? 'true' : 'false';
my $allT = $self->{allT} ? 'true' : 'false';
my $color = $self->{color};
my $JSoptions = $self->{OptionsString};

	return <<ENDJS
var $objName = new $JStype ("$LayerCGI","$objName","$color",$allZ,$allT,"$JSoptions");
ENDJS
;
}


#
sub Form {
my $self = shift;

	return '<TR><TD>'.$self->Form_visible."</TD><TD>$self->{name}</TD></TR>\n".
		"<TR><TD></TD><TD>".$self->Form_allZ.'</TD><TD>'.
		$self->Form_allT.'</TD><TD>'.
		$self->Form_color."</TD><TD></TR>\n";
}

1;

