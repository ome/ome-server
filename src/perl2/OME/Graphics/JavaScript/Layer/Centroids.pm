# OME/Graphics/JavaScript/Layer/Centroids.pm

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


package OME::Graphics::JavaScript::Layer::Centroids;
use strict;
use OME::Graphics::JavaScript::Layer;
use vars qw($VERSION @ISA);
use OME;
$VERSION = $OME::VERSION;
@ISA = ("OME::Graphics::JavaScript::Layer");

my $JStype = 'Centroids';
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

=head1 Centroids.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, L<"Function calls to OME Modules">, L<"Data references to OME Modules">

=head2 Description

A specialized subclass of L<OME::Graphics::JavaScript::Layer> that handles centroid overlays. 

=head2 Path

src/perl2/OME/Graphics/JavaScript/Layer/Centroids.pm

=head2 Package name

OME::Graphics::JavaScript::Layer::Centroids

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

L<"new()">, L<"JSinstance()">, L<"Form()">

=head2 new()

=over 4

=item Description

constructor

=item Parameters

In addition to parameters specified in L<OME::Graphics::JavaScript::Layer>, Centroids takes
an optional I<color> parameter. This specifies the color the centroids will be drawn in.

=item Returns

I<$self>

=item Overrides function L<OME::Graphics::JavaScript::Layer/"new()">

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
	

	if (not (exists $self->{color} and defined $self->{color})) {
		if (exists $params{color} and defined $params{color}) {
			$self->{color} = $params{color};
		} else {
			$self->{color} = "red";
		}
	}



	return $self;
}

=pod

=head2 JSinstance()

=over 4

=item Description

Makes a javascript command to instantiate the javascript object Centroids.

=item Parameters

none

=item Returns

A line of javascript.

=item Overrides function L<OME::Graphics::JavaScript::Layer/"JSinstance()">

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
