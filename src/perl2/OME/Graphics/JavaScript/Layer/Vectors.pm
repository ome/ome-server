package OME::Graphics::JavaScript::Layer::Vectors;
use strict;
use OME::Graphics::JavaScript::Layer;
use vars qw($VERSION @ISA);
$VERSION = 2.000_000;
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

# initial draft of pod added by Josiah Johnston, siah@nih.gov
=pod

=head1 Vectors.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, L<"Function calls to OME Modules">, L<"Data references to OME Modules">

=head2 Description

A specialized subclass of L<OME::Graphics::JavaScript::Layer> that handles vector overlays. 

=head2 Path

src/perl2/OME/Graphics/JavaScript/Layer/Vectors.pm

=head2 Package name

OME::Graphics::JavaScript::Layer::Vectors

=head2 Dependencies

B<inherits from>
	L<OME::Graphics::JavaScript::Layer>

=head2 Function calls to OME Modules

=over 4

=item L<OME::Graphics::JavaScript::Layer/"Form_visible()">

=item L<OME::Graphics::JavaScript::Layer/"Form_allZ()">

=item L<OME::Graphics::JavaScript::Layer/"Form_allT()">

=item L<OME::Graphics::JavaScript::Layer/"Form_color()">

=back

=head2 Data references to OME Modules

none

=head1 Externally referenced Functions

C<new()>, C<JSinstance()>, C<Form()>

=head2 new()

=over 4

=item Description

constructor

=item Parameters

In addition to parameters specified in L<OME::Graphics::JavaScript::Layer>, Vectors takes
an optional I<color> parameter. This specifies the color the vectors will be drawn in.

=item Returns

I<$self>

=item Overrides function in L<OME::Graphics::JavaScript::Layer/"new()">

=item Uses functions

L<OME::Graphics::JavaScript::Layer/"new()">

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

=pod

=head2 JSinstance()

=over 4

=item Description

Makes a javascript command to instantiate the javascript object Vectors.

=item Parameters

none

=item Returns

A line of javascript.

=item Overrides function in L<OME::Graphics::JavaScript::Layer/"JSinstance()">

=item Uses NO functions

=back

=cut

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

=pod

=head2 Form()

=over 4

=item Description

Makes html form elements to control the javascript object associated with this layer.
The form elements are inside of table rows.

=item Parameters

none

=item Returns

An HTML snippet.

=item Uses functions

=over 4

=item L<OME::Graphics::JavaScript::Layer/"Form_visible()">

=item L<OME::Graphics::JavaScript::Layer/"Form_allZ()">

=item L<OME::Graphics::JavaScript::Layer/"Form_allT()">

=item L<OME::Graphics::JavaScript::Layer/"Form_color()">

=back

=back

=cut

#
sub Form {
my $self = shift;

	return '<TR><TD>'.$self->Form_visible."</TD><TD>$self->{name}</TD></TR>\n".
		"<TR><TD></TD><TD>".$self->Form_allZ.'</TD><TD>'.
		$self->Form_allT.'</TD><TD>'.
		$self->Form_color."</TD><TD></TR>\n";
}

1;

