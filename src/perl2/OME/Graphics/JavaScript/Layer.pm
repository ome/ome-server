# OME/Graphics/JavaScript/Layer.pm

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


package OME::Graphics::JavaScript::Layer;
use strict;
use vars qw($VERSION @ISA);
use OME;
$VERSION = $OME::VERSION;
@ISA = ("");

my $JStype = 'Layer';
my $JSobject = <<ENDJSOBJECT;
// The Layer object.
function $JStype (CGI_URL,name,optionsStr) {
	this.parent = undefined;
	this.CGI_URL = CGI_URL || "";
	this.name = name;
	this.options = ['name'];  // This is an array of object fields that will be put on the URL
	this.optionsStr = optionsStr;

	this.overlay = [[]];       // 2-D array [Z][T]
	this.allZoverlay = [];   // 1-D array [T]
	this.allToverlay = [];   // 1-D array [Z]
	this.allZToverlay = undefined;  // a single image.
	this.RedrawImage = RedrawImage;
	this.SetAllZ = SetAllZ;
	this.SetAllT = SetAllT;
	this.LoadImage = LoadImage;
	this.SetVisible = SetVisible;
	this.Dirty = Dirty;
	this.DisplayImage = DisplayImage;

	// specific to html
	if (document.getElementById)
		this.Style = document.getElementById(name).style;
	else if (document.layers)
		this.Style = document[name];
	else if (document.all)
		this.Style = document.all[name].style;
	else
		this.Style = undefined;

	this.ImageName = this.name+'-Image';
	// specific to html
	if (document.images)
		this.Image = document.images[this.ImageName];

	return this;

	function SetAllZT (allZ,allT) {
		var redraw = false;
	
//		alert (this.name+'->SetAllZT('+allZ+','+allT+')');
		if (this.allZ != allZ || this.allT != allT)
			redraw = true;
		this.allZ = allZ;
		this.allT = allT;
		if (redraw)
			this.RedrawImage ();
	}


	function SetAllZ (allZ) {
//		alert (this.name+'->SetAllZ('+allZ+')');
		if (this.allZ == allZ)
			return;
		this.allZ = allZ;
		this.RedrawImage ();
	}

	function SetAllT (allT) {
//		alert (this.name+'->SetAllT('+allT+')');
		if (this.allT == allT)
			return;
		this.allT = allT;
		this.RedrawImage ();
	}

	function RedrawImage () {
//		alert (this.name+'->RedrawImage()');
	if (!this.parent) return;
	var theZ = this.parent.theZ;
	var theT = this.parent.theT;
	
		if (this.allZ && this.allT) {
			if (!this.allZToverlay)
				this.allZToverlay = this.LoadImage ();
			this.allZToverlay = this.DisplayImage (this.allZToverlay);
		}
		else if ( this.allZ && !this.allT ) {
			if ( !this.allZoverlay[theT] ) 
				this.allZoverlay[theT] = this.LoadImage ();
			this.allZoverlay[theT] = this.DisplayImage (this.allZoverlay[theT]);
		}
		else if ( !this.allZ && this.allT ) {
			if (!this.allToverlay[theZ])
				this.allToverlay[theZ] = this.LoadImage ();
			this.allToverlay[theZ] = this.DisplayImage (this.allToverlay[theZ]);
		}
		else if ( !this.allZ && !this.allT ) {
			if (!this.overlay[theZ])
				this.overlay[theZ] = [];
			if (!this.overlay[theZ][theT])
				this.overlay[theZ][theT] = this.LoadImage ();
			this.overlay[theZ][theT] = this.DisplayImage (this.overlay[theZ][theT]);
		}
	}
	
	function Dirty () {
//		alert (this.name+'->Dirty()');
	
		this.overlay = [[]];       // 2-D array [Z][T]
		this.allZoverlay = [];   // 1-D array [T]
		this.allToverlay = [];   // 1-D array [Z]
		this.allZToverlay = undefined;  // a single image.
	}

	// LoadImage method:
	function LoadImage () {
		var theZ = this.parent.theZ;
		var theT = this.parent.theT;
		var ImageID = this.parent.ImageID;
		var CGI = this.CGI_URL;
		var i;
		var options = [];
		for (i=0;i<this.options.length;i++) {
			options.push (this.options[i]+'='+eval ('this.'+this.options[i]) );
		}
		var imageURL = CGI+'?ImageID='+ImageID+'&theZ='+theZ+'&theT='+theT+'&'+options.join ('&',options)+'&'+optionsStr;
//		var myImage = new Image ();
//		myImage.src = imageURL;
//		alert (this.name+'->LoadImage(); src='+imageURL);
		return imageURL;
	}
	
	// specific to html
	function DisplayImage (theImageURL) {
		if (this.Image.src != theImageURL)
			this.Image.src = theImageURL;
		return this.Image.src;
	}
	
	// specific to html
	function SetVisible (checked) {
//		alert (this.name+'->SetVisible('+checked+')');
		this.Style.visibility = checked ? 'visible' : 'hidden';
	}
} // Layer

ENDJSOBJECT

# initial draft of pod added by Josiah Johnston, siah@nih.gov

#need to add info on what javascript object does. and a better overview would be nice.
=pod

=head1 Layer.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, L<"Function calls to OME Modules">, L<"Data references to OME Modules">

=head2 Description

Tools for constructing and manipulating a javascript object, Layer, which serves to control
a layer in the 2d viewer.

=head2 Path

F<src/perl2/OME/Graphics/JavaScript/Layer.pm>

=head2 Package name

OME::Graphics::JavaScript::Layer

=head2 Dependencies

none

=head2 Function calls to OME Modules

none

=head2 Data references to OME Modules

none

=head1 Externally referenced functions

=head2 new()

=over 4

=item Description

constructor new()

=item Parameters

B<optional>
	allZ, allT, name, LayerCGI, Options

	allZ and allT are integers acting as booleans
	name is a string. it will be the name of this layer in the html version.
	LayerCGI is the URL of the CGI associated with this layer
	Options is a list of options in the format: optA=valA&optB=valB&...

=item Returns

I<$self>

=item Uses functions

L<"ParseOptions()">

=back

=cut


# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my %params = @_;

#	foreach (keys(%params)) {
#		print STDERR $_.' => '.$params{$_}."\n" if defined $params{$_};
#	}
#	my $self = $class->SUPER::new(@_);
	bless $self,$class;
	
	$self->{JavaScript} = '';
	$self->{JSdeps} = [$JStype];
	$self->{JSdefs} = [$JSobject];
	$self->{Form} = '';
	$self->{JStype} = $JStype;
	$self->{ObjectRef} = '';
	$self->{OptionsString} = '';

	if (exists $params{allZ} and defined $params{allZ}) {
		$self->{allZ} = $params{allZ};
	} else {
		$self->{allZ} = 0;
	}

	if (exists $params{allT} and defined $params{allT}) {
		$self->{allT} = $params{allT};
	} else {
		$self->{allT} = 0;
	}

	if (exists $params{name} and defined $params{name}) {
		$self->{name} = $params{name};
	} else {
		$self->{name} = $self->{JStype}.int(rand(99999));
	}

	if (exists $params{LayerCGI} and defined $params{LayerCGI}) {
		$self->{LayerCGI} = $params{LayerCGI};
	} else {
		$self->{LayerCGI} = $0;
	}
	
	if (exists $params{Options} and defined $params{Options}) {
		$self->ParseOptions ($params{Options});
	}

	return $self;
}

=pod

X<Window()>

=head2 Window()

=over 4

=item Description

Sets the ObjectRef parameter. ObjectRef is used in html and javascript as the root object
to use when applying modifications.

=item Parameters

I<$window>, a text string containing the name of the window to use as a root object.

=item Returns

nothing

=item Uses no functions

=back

=cut

#
sub Window {
my $self = shift;
my $window = shift;
$self->{ObjectRef} = $window ? $window.'.'.$self->{name} : $self->{name};
}

=pod

=head2 JSinstance()

=over 4

=item Description

Makes a javascript command to instantiate the layer object in javascript.

=item Parameters

none

=item Returns

A line of javascript

=item Uses no functions

=back

=cut

sub JSinstance {
my $self = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $LayerCGI = $self->{LayerCGI};
my $allZ = $self->{allZ} ? 'true' : 'false';
my $allT = $self->{allT} ? 'true' : 'false';
my $JSoptions = $self->{OptionsString};
#FIXME: Should probably deal with the OptionsString better - make it a JS hash or make fields.
	return <<ENDJS;
var $objName = new $JStype ("$LayerCGI","$objName","$JSoptions");
ENDJS
}

=pod

X<HTMLdiv()>

=head2 HTMLdiv()

=over 4

=item Description

Makes an HTML div tag for this layer.

=item Parameters

I<$params>: A text string to set as the style attribute of the DIV tag

=item Returns

An HTML snippet

=item Uses no functions

=back

=cut

sub HTMLdiv {
my $self = shift;
my $params = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $imgName = $objName.'-Image';
my $LayerCGI = $self->{LayerCGI};
#my $imgSrc = "$LayerCGI?name=$objName;foo1=10;foo2=456";
my $imgSrc = "";

	return <<ENDJS;
<div id="$objName" style="$params">
	<img name="$imgName" src="$imgSrc">
</div>
ENDJS
}

=pod

X<X11Colors()>

=head2 X11Colors()

=over 4

=item Description

Contains a hash table called X11ColorDefs of color names and associated RGB values.

=item Parameters

none

=item Returns

A reference to a hash table containing color names and associated RGB values.

=item Uses no functions

=back

=cut

sub X11Colors {
my $X11ColorDefs = {
	"aliceblue" => [240,248,255],
	"antiquewhite" => [250,235,215],
	"aqua" => [0,255,255],
	"aquamarine" => [127,255,212],
	"azure" => [240,255,255],
	"beige" => [245,245,220],
	"bisque" => [255,228,196],
	"black" => [0,0,0],
	"blanchedalmond" => [255,235,205],
	"blue" => [0,0,255],
	"blueviolet" => [138,43,226],
	"brown" => [165,42,42],
	"burlywood" => [222,184,135],
	"cadetblue" => [95,158,160],
	"chartreuse" => [127,255,0],
	"chocolate" => [210,105,30],
	"coral" => [255,127,80],
	"cornflowerblue" => [100,149,237],
	"cornsilk" => [255,248,220],
	"crimson" => [220,20,60],
	"cyan" => [0,255,255],
	"darkblue" => [0,0,139],
	"darkcyan" => [0,139,139],
	"darkgoldenrod" => [184,134,11],
	"darkgray" => [169,169,169],
	"darkgreen" => [0,100,0],
	"darkkhaki" => [189,183,107],
	"darkmagenta" => [139,0,139],
	"darkolivegreen" => [85,107,47],
	"darkorange" => [255,140,0],
	"darkorchid" => [153,50,204],
	"darkred" => [139,0,0],
	"darksalmon" => [233,150,122],
	"darkseagreen" => [143,188,143],
	"darkslateblue" => [72,61,139],
	"darkslategray" => [47,79,79],
	"darkturquoise" => [0,206,209],
	"darkviolet" => [148,0,211],
	"deeppink" => [255,20,147],
	"deepskyblue" => [0,191,255],
	"dimgray" => [105,105,105],
	"dodgerblue" => [30,144,255],
	"firebrick" => [178,34,34],
	"floralwhite" => [255,250,240],
	"forestgreen" => [34,139,34],
	"fuchsia" => [255,0,255],
	"gainsboro" => [220,220,220],
	"ghostwhite" => [248,248,255],
	"gold" => [255,215,0],
	"goldenrod" => [218,165,32],
	"gray" => [128,128,128],
	"green" => [0,255,0],		# [0,128,0]
	"greenyellow" => [173,255,47],
	"honeydew" => [240,255,240],
	"hotpink" => [255,105,180],
	"indianred" => [205,92,92],
	"indigo" => [75,0,130],
	"ivory" => [255,255,240],
	"khaki" => [240,230,140],
	"lavender" => [230,230,250],
	"lavenderblush" => [255,240,245],
	"lawngreen" => [124,252,0],
	"lemonchiffon" => [255,250,205],
	"lightblue" => [173,216,230],
	"lightcoral" => [240,128,128],
	"lightcyan" => [224,255,255],
	"lightgoldenrodyellow" => [250,250,210],
	"lightgreen" => [144,238,144],
	"lightgrey" => [211,211,211],
	"lightpink" => [255,182,193],
	"lightsalmon" => [255,160,122],
	"lightseagreen" => [32,178,170],
	"lightskyblue" => [135,206,250],
	"lightslategray" => [119,136,153],
	"lightsteelblue" => [176,196,222],
	"lightyellow" => [255,255,224],
	"lime" => [0,255,0],
	"limegreen" => [50,205,50],
	"linen" => [250,240,230],
	"magenta" => [255,0,255],
	"maroon" => [128,0,0],
	"mediumaquamarine" => [102,205,170],
	"mediumblue" => [0,0,205],
	"mediumorchid" => [186,85,211],
	"mediumpurple" => [147,112,219],
	"mediumseagreen" => [60,179,113],
	"mediumslateblue" => [123,104,238],
	"mediumspringgreen" => [0,250,154],
	"mediumturquoise" => [72,209,204],
	"mediumvioletred" => [199,21,133],
	"midnightblue" => [25,25,112],
	"mintcream" => [245,255,250],
	"mistyrose" => [255,228,225],
	"moccasin" => [255,228,181],
	"navajowhite" => [255,222,173],
	"navy" => [0,0,128],
	"oldlace" => [253,245,230],
	"olive" => [128,128,0],
	"olivedrab" => [107,142,35],
	"orange" => [255,165,0],
	"orangered" => [255,69,0],
	"orchid" => [218,112,214],
	"palegoldenrod" => [238,232,170],
	"palegreen" => [152,251,152],
	"paleturquoise" => [175,238,238],
	"palevioletred" => [219,112,147],
	"papayawhip" => [255,239,213],
	"peachpuff" => [255,218,185],
	"peru" => [205,133,63],
	"pink" => [255,192,203],
	"plum" => [221,160,221],
	"powderblue" => [176,224,230],
	"purple" => [128,0,128],
	"red" => [255,0,0],
	"rosybrown" => [188,143,143],
	"royalblue" => [65,105,225],
	"saddlebrown" => [139,69,19],
	"salmon" => [250,128,114],
	"sandybrown" => [244,164,96],
	"seagreen" => [46,139,87],
	"seashell" => [255,245,238],
	"sienna" => [160,82,45],
	"silver" => [192,192,192],
	"skyblue" => [135,206,235],
	"slateblue" => [106,90,205],
	"slategray" => [112,128,144],
	"snow" => [255,250,250],
	"springgreen" => [0,255,127],
	"steelblue" => [70,130,180],
	"tan" => [210,180,140],
	"teal" => [0,128,128],
	"thistle" => [216,191,216],
	"tomato" => [255,99,71],
	"turquoise" => [64,224,208],
	"violet" => [238,130,238],
	"wheat" => [245,222,179],
	"white" => [255,255,255],
	"whitesmoke" => [245,245,245],
	"yellow" => [255,255,0],
	"yellowgreen" => [154,205,50]
    };

	return $X11ColorDefs;
}

=pod

=head1 Functions intended to be internally referenced

C<Form_allZ()>, C<Form_allT()>, C<Form_visible>,  C<Form_color>, C<ParseOptions>

X<Form_allZ()>

=head2 Form_allZ()

=over 4

=item Description

Makes an HTML checkbox to control the javascript function SetAllZ() in the
javascript object Layer.

=item Parameters

none

=item Returns

An HTML checkbox

=item Uses no functions

=back

=cut

sub Form_allZ {
my $self = shift;
my $name = $self->{name}."allZ";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};
my $checked = '';

	$checked = 'CHECKED' if ($self->{allZ});

	return <<ENDFORM;
		<INPUT TYPE="checkbox" NAME="$name" $checked VALUE="$name" onclick = "$objRef.SetAllZ(this.checked);">
		All Z</INPUT>
ENDFORM
}

=pod

X<Form_allT()>

=head2 Form_allT()

=over 4

=item Description

Makes an HTML checkbox to control the javascript function SetAllT() in the
javascript object Layer.

=item Parameters

none

=item Returns

An HTML checkbox

=item Uses no functions

=back

=cut

sub Form_allT {
my $self = shift;
my $name = $self->{name}."allT";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};
my $checked = '';

	$checked = 'CHECKED' if ($self->{allT});

	return <<ENDFORM;
		<INPUT TYPE="checkbox" NAME="$name" $checked VALUE="$name" onclick = "$objRef.SetAllT(this.checked);">
		All T</INPUT>
ENDFORM
}

=pod

X<Form_visible()>

=head2 Form_visible()

=over 4

=item Description

Makes an HTML checkbox to control the javascript function SetVisible() in the
javascript object Layer. This controls the visibility of the html layer specified in
I<{ObjectRef}>.

=item Parameters

none

=item Returns

An HTML checkbox

=item Uses no functions

=back

=cut

sub Form_visible {
my $self = shift;
my $name = $self->{name}."Visible";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};

	
	return <<ENDFORM;
	<INPUT TYPE="checkbox" NAME="$name" CHECKED VALUE="$name" onclick = "$objRef.SetVisible(this.checked);"/>
ENDFORM
}

=pod

X<Form_color()>

=head2 Form_color()

=over 4

=item Description

Makes an HTML select element (e.g. comboBox) to control the javascript function SetColor() in some
javascript objects that inherit from Layer. This javascript function sets the color of the reference
layer. NOTE: If a perl subclass uses this function, its associated javascript object must have a
SetColor() function.

=item Parameters

none

=item Returns

An HTML select element full of color names that reports back to 

=item Uses functions

X11Colors()

=back

=cut

sub Form_color {
my $self = shift;
my $name = $self->{name}."Color";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};
my $color = $self->{color};
my $colors = $self->X11Colors();
my $JS = "\tColor:<SELECT NAME=\"$name\" onchange=\"$objRef.SetColor(this.options[this.selectedIndex].text);\">\n";

	
	foreach (sort (keys %$colors)) {
		$JS .= '		<option value="['.join (',',@{$colors->{$_}}).']"';
		$JS .= ' selected' if $_ eq $color;
		$JS .= '>'.$_."</option>\n";
	}
	
	$JS .= "\t</SELECT>\n";

	return $JS;
}

=pod

X<ParseOptions()>

=head2 ParseOptions()

=over 4

=item Description

Takes a URL style parameter list and parses it, making new variables in I<$self> for each element.

=item Parameters

optionsStr

optionsStr is a URL style parameter list. (i.e. optA=valA&optB=valB&optC=valC... )

=item Returns

nothing

=item Uses No functions

=back

=cut

sub ParseOptions () {
my $self = shift;
my $optionsStr = shift;
my @options = split ('&',$optionsStr);
my ($option,$value);

	$self->{OptionsString} = $optionsStr;
	foreach (@options) {
		($option,$value) = split ('=',$_);
		# URL-unescape the value
		# use this to escape: =~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
		$value =~ tr/+/ /;       # pluses become spaces
		$value =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
		$self->{$option} = $value;
	}
}


1;
