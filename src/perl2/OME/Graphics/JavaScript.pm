package OME::Graphics::JavaScript;
use strict;
use OME::Graphics;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("OME::Graphics");

my $JStype = 'JSgraphics';
my $JSobject = <<ENDJSOBJECT;
// This is the JSgraphics object, which conatins an array of Layer objects.
// The JSgraphics constructor
function $JStype (ImageID, dims, theZ, theT) {
	this.layers = new Array ();
	this.theZ = theZ;
	this.theT = theT;
	this.imgDims = dims;
	this.ImageID = ImageID;
	this.AddLayer = AddLayer;
	this.SwitchZT = SwitchZT;
	this.SwitchZ = SwitchZ;
	this.Zup = Zup;
	this.Zdown = Zdown;
	this.Tup = Tup;
	this.Tdown = Tdown;
	this.SwitchT = SwitchT;
	this.SwitchAllZT = SwitchAllZT;
	this.Redraw = Redraw;
	
	this.theZtextBox = document.forms[0].theZtextBox;
	this.theTtextBox = document.forms[0].theTtextBox;
	
	this.theZtextBox.value = theZ;
	this.theTtextBox.value = theT;

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

	function Zup () {
		this.SwitchZT (this.theZ+1,this.theT);
	}

	function Zdown () {
		this.SwitchZT (this.theZ-1,this.theT);
	}

	function SwitchT (theT) {
		this.SwitchZT (this.theZ,theT);
	}

	function Tup () {
		this.SwitchZT (this.theZ,this.theT+1);
	}

	function Tdown () {
		this.SwitchZT (this.theZ,this.theT-1);
	}

	// SwitchZT method:
	// Calls all the layers' SetZ/SetT method, which changes the displayed Z and/or T.
	function SwitchZT (theZ,theT) {
		
		if (theZ >= this.imgDims[2]) theZ = this.imgDims[2]-1;
		if (theZ < 0) theZ = 0;
		if (theT >= this.imgDims[4]) theT = this.imgDims[4]-1;
		if (theT < 0) theT = 0;

		this.theZtextBox.value = theZ;
		this.theTtextBox.value = theT;

		if (this.theZ == theZ && this.theT == theT)
			return;
		
		this.theZ = theZ;
		this.theT = theT;
		
		var i;
		var nLayers = this.layers.length;
		for (i = 0; i < nLayers; i++) {
				this.layers[i].RedrawImage ();
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

# First draft of POD written by Josiah Johnston. siah@nih.gov
=pod

=head1 JavaScript.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, L<"Function calls to OME Modules">, L<"Data references to OME Modules">

=head2 Description

Creates javascript classes and html snippets. Right now it is specific to 
L<OME::Web::GetGraphics>, but that could change in the future.

=head2 Path

src/perl2/OME/Graphics/JavaScript

=head2 Package name

OME::Graphics::JavaScript

=head2 Dependencies

B<Inherits from>

OME::Graphics

B<makes use of OME Modules>

OME::Graphics::JavaScript::Layer

OME::Graphics::JavaScript::Layer::*

=head2 Function calls to OME Modules

L<OME::Graphics/"new()">

L<OME::Graphics::JavaScript::Layer/"HTMLdiv()">

L<OME::Graphics::JavaScript::Layer/"Window()">

OME::Graphics::JavaScript::Layer::*->Form()

OME::Graphics::JavaScript::Layer::*->JSinstance()

=head2 Data references to OME Modules

OME::Graphics::JavaScript::Layer::*->{Parent}

OME::Graphics::JavaScript::Layer::*->{JSdefs}

OME::Graphics::JavaScript::Layer->{name}

=head1 Functions

L<"Externaly referenced">, L<"Intended to be internally referenced">

=head2 Externally referenced


=over 4

X<new()>

=item new()

=over 4

=item Description

constructor

=item Parameters

B<required>
	ImageID, Session, Dims

B<optional>
	theZ, theT

=item Returns

I<$self>

=item Overrides function in OME::Graphics

=item Uses functions

L<OME::Graphics/"new()">

=back

=cut

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
	$self->{JSref} = $JStype;
	$self->{layers} = [];
	
	die "ImageID must be specified when making a new ".ref($self)." object\n"
		unless exists $params{ImageID} and defined $params{ImageID} and $params{ImageID};

	$self->{ImageID} = $params{ImageID};
	$self->{Session} = $params{Session};

	if (exists $params{theZ} and defined $params{theZ}) {
		$self->{theZ} = $params{theZ};
	}

	if (exists $params{theT} and defined $params{theT}) {
		$self->{theT} = $params{theT};
	} else {
		$self->{theT} = 0;
	}

	die ref($self)."->new:  Image dimensions not specified\n" unless
		exists $params{Dims} and defined $params{Dims} and ref($params{Dims}) eq 'ARRAY'
		and scalar(@{$params{Dims}}) == 6;
	$self->{Dims} = $params{Dims};

	return $self;
}

=pod

X<AddLayer()>

=item AddLayer()

=over 4

=item Description

pushes a Layer object onto the layers array

=item Parameters

I<$layer>

layer should be a reference to an object of type OME::Graphics::JavaScript::Layer::*

=item Returns

I<$layer>

=item Uses NO functions

=item Accesses external data:

OME::Graphics::JavaScript::Layer::*->{Parent}

OME::Graphics::JavaScript::Layer::*->{name}

=back

=cut

#
# This method pushes a Layer object onto the layers array.
sub AddLayer {
my $self = shift;
my $layer = shift;
my $i;

	# Give the layer a link to ourselves.
	$layer->{Parent} = $self;
	push (@{ $self->{layers} },$layer);
	
	$self->{JSlayers} .= 'JSgraphics.AddLayer ('.$layer->{name}.");\n";
	return $layer;
}

=pod

X<JavaScript()>

=item JavaScript()

=over 4

=item Description

Generates necessary javascript classes, div layers, and javascript commands to instantiate
the javascript objects. It does not appear to currently be in use anywhere.

=item Parameters

none

=item Returns

Text containing Javascript classes embeded in html tags, div tags associated with the known
layers, and Javascript commands to instantiate the layers.

=item Uses functions

JSobjectDefs()

JSinstance()

=back

=cut

sub JavaScript {
my $self = shift;
my $JS;

	$JS .= $self->JSobjectDefs()."\n".$self->JSinstance()."\n";

	return $JS;
}

=pod

X<JSobjectDefs()>

=item JSobjectDefs()

=over 4

=item Description

Generates javascript objects embedded in html tags. Will NOT generate multiple objects of same type.
The following objects are generated: JSGraphics, necessary objects for each layer.

=item Parameters

none

=item Returns

Text containing Javascript classes embedded in html tags.

=item Uses NO functions

=item Accesses external data

OME::Graphics::JavaScript::Layer::*->{JSdefs}

these are the layer's javascript object definitions

=back

=cut

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

=pod

X<Form()>

=item Form()

=over 4

=item Description

Generates an html form housing controls to manipulate the layers.

=item Parameters

I<$window>

$window is passed to L<OME::Graphics::JavaScript::Layer/"Window()">. look there for more info.

=item Returns

An html form.

=item Uses functions

L<OME::Graphics::JavaScript::Layer/"Window()">

OME::Graphics::JavaScript::Layer::*->Form()

=back

=cut

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

=pod

X<JSinstance()>

=item JSinstance()

=over 4

=item Description

Generates DIV tags associated with the layers, and Javascript commands to instantiate the layer
objects.

=item Parameters

A text string to pass to L<"HTMLlayersDIVs()">.

=item Returns

An HTML snippet containing DIV tags and javascript commands.

=item Uses functions

L<"HTMLlayersDIVs()">

L<"JSlayersInstances()">

=back

=cut

# Here we need to write the DIV tags, then instantiate the JS objects.
sub JSinstance {
my $self = shift;
my $params = shift;
my $instance;
	die ref($self)."->JSinstance: The Dims field is undefined - probably the Image object was not passed as a parameter to new\n"
		unless exists $self->{Dims} and defined $self->{Dims};
	my $JS_Dims = '['.join (',', @{$self->{Dims}}).']';

	$instance = $self->HTMLlayersDIVs($params);
	$instance .= qq `<script type="text/javascript" language="Javascript"><!--\n`;
	$instance .= "var $self->{JSref} = new $JStype ($self->{ImageID},$JS_Dims,$self->{theZ},$self->{theT});\n";
	$instance .= $self->JSlayersInstances();
	$instance .= "$self->{JSlayers}\n";
	$instance .= "$self->{JSref}.Redraw();";
	$instance .= qq `//--></script>\n`;
#	print STDERR $instance;
	return $instance;
}

=pod

X<JSref()>

=item JSref()

=over 4

=item Description

Returns variable I<self-E<gt>{JSref}>. This variable currently is "JSgraphics", the javascript
object specified in OME::Graphics::JavaScript (this package).

=item Parameters

none

=item Returns

A string consisting of the name of the javascript object specified specifically in this package.

=item Uses NO functions

=back

=cut

sub JSref {
	my $self = shift;
	return $self->{JSref};
}

=pod

=head2 Intended to be internally referenced

L<"JSlayersInstances">, L<"HTMLlayersDIVs">, L<"DrawLayers">

X<JSlayersInstances()>

=item JSlayersInstances()

=over 4

=item Description

Collects javascript commands to instantiate the layer objects.

=item Parameters

none

=item Returns

A text string consisting of a series of Javascript commands.

=item Uses functions

OME::Graphics::JavaScript::Layer::*->JSinstance()

=back

=cut

sub JSlayersInstances {
my $self = shift;
my $JS;

	foreach (@{$self->{layers}}) {
		$JS .= $_->JSinstance()."\n";
	}
	$JS .= "\n";
	return $JS;
}

=pod

X<HTMLlayersDIVs()>

=item HTMLlayersDIVs()

=over 4

=item Description

Collects DIV tags from the all the layers.

=item Parameters

A text string to pass to L<OME::Graphics::JavaScript::Layer/"HTMLdiv()">

=item Returns

HTML tags for the layers.

=item Uses functions

L<OME::Graphics::JavaScript::Layer/"HTMLdiv()">

=back

=cut

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

=pod

X<DrawLayers()>

=item DrawLayers()

=over 4

=item Description

Returns javascript commands to call functions in the javascript object specified in this package 
(currently its name is JSGraphics) with the intent of adding all the layers and redrawing. 
This function is not in use at this time. It appears to be depricated.

=item Parameters

none

=item Returns

Javascript commands to issue function calls to javascript object I<$JStype> (e.g. JSGraphics).

=back

=cut

sub DrawLayers {
my $self = shift;
my $JS;
	$JS .= $self->{JSlayers}."\n$JStype.Redraw()";
}

1;

