package Graphics::JavaScript;
use strict;
use Graphics;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("Graphics");

my $JStype = 'JSgraphics';
my $JSobject = <<ENDJSOBJECT;
// This is the JSgraphics object, which conatins an array of Layer objects.
// The JSgraphics constructor
function $JStype (theZ, theT) {
	this.layers = new Array ();
	this.theZ = theZ;
	this.theT = theT;
	this.AddLayer = AddLayer;
	this.SwitchZT = SwitchZT;
	this.SwitchZ = SwitchZ;
	this.SwitchT = SwitchT;
	this.SwitchAllZT = SwitchAllZT;
	this.Redraw = Redraw;

	return this;

	// AddLayer method:
	// pushes a Layer object onto the layers array.
	function AddLayer (layer) {
		layer.parent = this;
		this.layers.push (layer);
		return (layer);
	}

	function SwitchZ (theZ) {
		this.SwitchZT (theZ,this.theT);
	}

	function SwitchT (theT) {
		this.SwitchZT (this.theZ,theT);
	}

	// SwitchZT method:
	// Calls all the layers' SetZ/SetT method, which changes the displayed Z and/or T.
	function SwitchZT (theZ,theT) {
		if (this.theZ == theZ && this.theT == theT)
			return;
		this.theZ = theZ || this.theZ;
		this.theT = theT || this.theT;

		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].Redraw ();
		}
	}

	function SwitchAllZT (allZ,allT) {
		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].SetAllZT (allZ,allT);
		}
	}

	function SwitchAllZ (allZ) {
		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].SetAllZ (allZ);
		}
	}

	function SwitchAllT (allT) {
		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].SetAllT (allT);
		}
	}

	function Redraw () {
		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].RedrawImage ();
		}
	}

}
ENDJSOBJECT



# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;
	my $self = $class->SUPER::new(@_);
	bless $self,$class;
	
	$self->{JSlayers} = "";
	$self->{Form} = "";
	$self->{JStype} = $JStype;
	$self->{layers} = [];
	

	if (exists $params{theZ} and defined $params{theZ}) {
		$self->{theZ} = $params{theZ};
	} else {
		$self->{theZ} = 0;
	}

	if (exists $params{theT} and defined $params{theT}) {
		$self->{theT} = $params{theT};
	} else {
		$self->{theT} = 0;
	}

	return $self;
}

#
# This method pushes a Layer object onto the layers array.
sub AddLayer {
my $self = shift;
my $layer = shift;
my $i;

	
	push (@{ $self->{layers} },$layer);
	
	$self->{JSlayers} .= 'JSgraphics.AddLayer ('.$layer->{name}.");\n";
	return $layer;
}

sub JavaScript {
my $self = shift;
my $JS;

	$JS .= $self->JSobjectDefs()."\n".$self->JSinstance()."\n";

	return $JS;
}

sub JSobjectDefs {
my $self = shift;
my $layer;
my $i;
my %JSobjects;
my $JSdefs = $JSobject;

	foreach $layer (@{$self->{layers}}) {
		for ($i=0;$i < scalar (@{$layer->{JSdeps}});$i++) {
			if (not exists $JSobjects{$layer->{JSdeps}->[$i]} ) {
				$JSobjects{$layer->{JSdeps}->[$i]} = 1;
				$JSdefs .= $layer->{JSdefs}->[$i]."\n";
			}
		}
	}
	return $JSdefs;
}

sub Form {
my $self = shift;
my $window = shift;
my $form = <<ENDFORM;
<form method="post" name="GraphicsGUI">
<table bgcolor="#FFFFFF">
ENDFORM

	foreach (@{$self->{layers}}) {
		$_->Window ($window);
		$form .= $_->Form();
	}

	$form .= <<ENDFORM;
</table>
</form>
ENDFORM

	return $form;
}


# Here we need to write the DIV tags, then instantiate the JS objects.
sub JSinstance {
my $self = shift;
my $params = shift;
my $instance;

	$instance = $self->HTMLlayersDIVs($params);
	$instance .= qq `<script type="text/javascript" language="Javascript"><!--\n`;
	$instance .= "var $JStype = new $JStype (".$self->{theZ}.','.$self->{theT}.");\n";
	$instance .= $self->JSlayersInstances();
	$instance .= $self->{JSlayers}."\n$JStype.Redraw();";
	$instance .= qq `//--></script>\n`;
}

sub JSlayersInstances {
my $self = shift;
my $JS;

	foreach (@{$self->{layers}}) {
		$JS .= $_->JSinstance()."\n";
	}
	$JS .= "\n";
	return $JS;
}

sub HTMLlayersDIVs {
my $self = shift;
my $params = shift;
my $HTML;
	foreach (@{$self->{layers}}) {
		$HTML .= $_->HTMLdiv($params)."\n";
	}
	$HTML .= "\n";
	return $HTML;
}

sub DrawLayers {
my $self = shift;
my $JS;
	$JS .= $self->{JSlayers}."\n$JStype.Redraw()";
}

1;

