package Graphics::JavaScript::Layer;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("");

my $JStype = 'Layer';
my $JSobject = <<ENDJSOBJECT;
// The Layer object.
function $JStype (CGI_URL,name,allZ,allT) {
	this.parent = undefined;
	this.CGI_URL = CGI_URL || "";
	this.name = name;
	this.allZ = allZ || true;  // N.B.  NOT Boolean objects.
	this.allT = allT || false;
	this.options = ['allZ','allT','name'];  // This is an array of object fields that will be put on the URL

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

	if (document.getElementById)
		this.Style = document.getElementById(name).style;
	else if (document.layers)
		this.Style = document[name];
	else if (document.all)
		this.Style = document.all[name].style;
	else
		this.style = undefined;

	this.ImageName = this.name+'-Image';
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
			this.DisplayImage (this.allZToverlay);
		}
		else if ( this.allZ && !this.allT ) {
			if ( !this.allZoverlay[theT] )
				this.allZoverlay[theT] = this.LoadImage ();
			this.DisplayImage (this.allZoverlay[theT]);
		}
		else if ( !this.allZ && this.allT ) {
			if (!this.allToverlay[theZ])
				this.allToverlay[theZ] = this.LoadImage ();
			this.DisplayImage (this.allToverlay[theZ]);
		}
		else if ( !this.allZ && !this.allT ) {
			if (!this.overlay[theZ])
				this.overlay[theZ] = [];
			if (!this.overlay[theZ][theT])
				this.overlay[theZ][theT] = this.LoadImage ();
			this.DisplayImage (this.overlay[theZ][theT]);
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
		var CGI = this.CGI_URL;
		var i;
		var options = [];
		for (i=0;i<this.options.length;i++) {
			options.push (this.options[i]+'='+eval ('this.'+this.options[i]) );
		}
		var imageURL = CGI+'?theZ='+theZ+';theT='+theT+';'+options.join (';',options);
		var myImage = new Image ();
		myImage.src = imageURL;
//		alert (this.name+'->LoadImage(); src='+imageURL);
		return myImage;
	}
	
	function DisplayImage (theImage) {
		this.Image.src = theImage.src;
	}
	
	function SetVisible (checked) {
//		alert (this.name+'->SetVisible('+checked+')');
		this.Style.visibility = checked ? 'visible' : 'hidden';
	}
} // Layer

ENDJSOBJECT





# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my %params = @_;
#	my $self = $class->SUPER::new(@_);
	bless $self,$class;
	
	$self->{JavaScript} = '';
	$self->{JSdeps} = [$JStype];
	$self->{JSdefs} = [$JSobject];
	$self->{Form} = '';
	$self->{JStype} = $JStype;
	$self->{ObjectRef} = '';
	

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

	return $self;
}

#
sub Window {
my $self = shift;
my $window = shift;
$self->{ObjectRef} = $window ? $window.'.'.$self->{name} : $self->{name};
}

sub JSinstance {
my $self = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $LayerCGI = $self->{LayerCGI};
my $allZ = $self->{allZ} ? 'true' : 'false';
my $allT = $self->{allT} ? 'true' : 'false';

	return <<ENDJS;
var $objName = new $JStype ("$LayerCGI","$objName",$allZ,$allT);
ENDJS
}

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

sub Form_visible {
my $self = shift;
my $name = $self->{name}."Visible";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};

	
	return <<ENDFORM;
	<INPUT TYPE="checkbox" NAME="$name" CHECKED VALUE="$name" onclick = "$objRef.SetVisible(this.checked);"/>
	$objName</INPUT>
ENDFORM
}


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

1;

