#!/usr/bin/perl -w
# Copyright (C) 2002 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
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
package OME::Web::GetGraphics;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
use OME::Image;
@ISA = ("OME::Web");

use GD;
use OME::Graphics::JavaScript;
use OME::Graphics::JavaScript::Layer::Vectors;
use OME::Graphics::JavaScript::Layer::Centroids;
use OME::Graphics::JavaScript::Layer::OMEimage;
use OME::Graphics::GD::Vectors;
use OME::Graphics::GD::Centroids;
use Benchmark;

# initial draft of pod added by Josiah Johnston, siah@nih.gov
=pod

=head1 GetGraphics.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, 
L<"Function calls to OME Modules">, L<"Data references to OME Modules">
L<"ome database tables accessed">

=head2 Description

Generates 2D viewer of an image using html with JavaScript controls

=head2 Path

src/perl2/OME/Web/

=head2 Package name

OME::Web::GetGraphics

=head2 Dependencies

=over 4

=item Inherits from

OME::Web

=item Non-OME Modules

	CGI
	GD
	Benchmark

=item OME Modules

=over 4

=item L<OME::Web|OME::Web>

=item L<OME::DBObject|OME::DBObject>

=item L<OME::Image|OME::Image>

=item L<OME::Graphics::GD::Vectors|OME::Graphics::GD::Vectors>

=item L<OME::Graphics::GD::Centroids|OME::Graphics::GD::Centroids>

=item L<OME::Graphics::JavaScript|OME::Graphics::JavaScript>

=item L<OME::Graphics::JavaScript::Layer::Vectors|OME::Graphics::JavaScript::Layer::Vectors>

=item L<OME::Graphics::JavaScript::Layer::Centroids|OME::Graphics::JavaScript::Layer::Centroids>

=item L<OME::Graphics::JavaScript::Layer::OMEimage|OME::Graphics::JavaScript::Layer::OMEimage>

=back

=back

=head2 Function calls to OME Modules

=over 4

=item L<OME::Factory.loadObject()|OME::Factory/"loadObject()">

=item OME::Graphics::GD::*

 
new()
Draw()
getImage()
imageType()

=item L<OME::Graphics::JavaScript.AddLayer()|OME::Graphics::JavaScript/"AddLayer()">

=item L<OME::Graphics::JavaScript.Form()|OME::Graphics::JavaScript/"Form()">

=item L<OME::Graphics::JavaScript.new()|OME::Graphics::JavaScript/"new()">

=item OME::Graphics::JavaScript::Layer::*

new()

=item L<OME::Session.DBH()|OME::Session/"DBH()">

=item L<OME::Web.CGI()|OME::Web/"CGI()">

=item L<OME::Web.Factory()|OME::Web/"Factory()">

=item L<OME::Web.new()|OME::Web/"new()">

=item L<OME::Web.Session()|OME::Web/"Session()">

=head2 Data references to OME Modules 

=over 4

=item L<OME::Graphics::JavaScript::Layer.X11Colors|OME::Graphics::JavaScript::Layer>

=item OME::Graphics::GD::*

image

=back

=head2 OME database tables accessed

attributes_image_xyzwt

=head1 Externally referenced functions

=over 4

=item

=head2 new()

=over 4

=item Description

constructor

=item Returns

I<$self>
	$self is a OME::Web::GetGraphics object

=item Overrides function

L<OME::Web/"new()">

=item Uses functions

L<OME::Web.new()|OME::Web/"new()">

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);

#    $self->{RequireLogin} = 0;

    return $self;
}

=pod

=head2 createOMEPage()

=over 4

=item Description

uses url_parameters to call appropriate content generation functions

=item Returns

contentType, content

	contentType is a string. either "HTML" or "IMAGE"
	content is either an HTML file or an image object from GD::image
	HTML files are either a main window or layer controls

=item Overrides function

L<OME::Web/"createOMEPage()">

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=item CGI->url()

=item L<"DrawLayersControls()">

=item L<"DrawGraphics()">

=item L<"DrawMainWindow()">

=back

=back

=cut

sub createOMEPage {
	my $self  = shift;
	my $cgi   = $self->CGI();
	my @params = $cgi->url_param();
#print STDERR ref($self)."->createOMEPage()\nURL='".$cgi->url(-query=>1)."\n";
	if ( $cgi->url_param('DrawLayersControls') ) {
		return ('HTML',$self->DrawLayersControls());
	} elsif ( $cgi->url_param('name') ) {
		return ('IMAGE',$self->DrawGraphics());
	} elsif ( $cgi->url_param('SVG') ) {
		return('SVG', '<SVG/>');
	} else {
		return ('HTML',$self->DrawMainWindow());
	}
}


=pod

=head2 getPageTitle()

=over 4

=item Description

Displays page title

=item Returns

hard-coded string: "Open Microscopy Environment"

=item Overrides function

L<OME::Web/"getPageTitle()">

=item Uses No functions

=back

=cut

sub getPageTitle {
    return "Open Microscopy Environment";
}

=pod

=head2 contentType()

=over 4

=item Description

returns contentType

=item Returns

I<$self->{contentType}>

=item Overrides function

L<OME::Web/"contentType()">

=item Uses No functions

=back

=back

=cut

sub contentType {
my $self = shift;
	return $self->{contentType};
}

=pod

=head1 Internally referenced functions

=over 4

=item

=head2 DrawMainWindow()

=over 4

=item Description

Generates an HTML file housing the most commonly used controls

=item Returns

an HTML file

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item getJSgraphics()

=item CGI->start_html()

=item CGI->end_html()

=item L<OME::Graphics::JavaScript/"JSobjectDefs()">

=item L<OME::Graphics::JavaScript/"JSinstance()">

=back

=item Accesses external data

L<OME::Graphics::JavaScript/"{JSref}">

=item Generated Javascript will reference

OME::Web::GetGraphics via serve.pl, eventually calling 
L<"DrawLayersControls()"> and L<"DrawGraphics()">

=back

=cut

sub DrawMainWindow {
my $self = shift;
my $cgi   = $self->CGI();
my $JSgraphics = $self->getJSgraphics() ;
my $JS;
my $HTML;

	$JS = <<ENDJS;
	function MakePopup () {
		if (!document.popup)
			document.popup = window.open('serve.pl?Page=OME::Web::GetGraphics&DrawLayersControls=1&ImageID=$self->{ImageID}', 'cal', 'dependent=yes, width=400, height=600, screenX=0, screenY=0, titlebar=yes');
		if (!document.popup.opener) document.popup.opener = self;
		if (document.popup.focus) document.popup.focus();
	}
	function doNothing () {
	}
ENDJS


	$self->{contentType} = 'text/html';
	$HTML = $cgi->start_html(-title=>'Graphics Test', -script=>$JS.$JSgraphics->JSobjectDefs());
	$HTML .= qq '<form onsubmit="doNothing()">';
	$HTML .= qq 'Z:<input type="button" name="theZdown" value="v" onclick="$JSgraphics->{JSref}.Zdown()">\n';
	$HTML .= qq '<input type="text" name="theZtextBox" size="3" onchange="$JSgraphics->{JSref}.SwitchZ(parseInt(this.value))">\n';
	$HTML .= qq '<input type="button" name="theZup" value="^" onclick="$JSgraphics->{JSref}.Zup()">&nbsp;&nbsp;\n';
	$HTML .= qq 'T:<input type="button" name="theTdown" value="<" onclick="$JSgraphics->{JSref}.Tdown()">\n';
	$HTML .= qq '<input type="text" name="theTtextBox" size="3" onchange="$JSgraphics->{JSref}.SwitchT(parseInt(this.value))">\n';
	$HTML .= qq '<input type="button" name="theTup" value=">" onclick="$JSgraphics->{JSref}.Tup()">\n';
	$HTML .= qq '&nbsp;&nbsp;&nbsp;&nbsp;<a href="javascript:MakePopup()">Layers</a></form>\n';
	$HTML .= $JSgraphics->JSinstance ('position:absolute; left:0; top:35; visibility:visible; border-width:1 border-style:solid border-color:black');

	$HTML .= $cgi->end_html;
	return ($HTML);
}

=pod

=head2 DrawGraphics()

=over 4

=item Description

Generates an overlay image for the layers. It uses classes inherited from OME::Graphics::GD

=item Returns

An image object of type GD::Image

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=item OME::Graphics::GD::*->new()

this dynamically instantiates a new object of unknown type.
Type is specified in parameters and is not subject to prior checks.
It is supposed to be a subclass of L<OME::Graphics::GD>.

=item OME::Graphics::GD::*->Draw()

=item OME::Graphics::GD::*->getImage()

=item OME::Graphics::GD::*->imageType()

=item L<OME::Graphics::JavaScript::Layer/"X11Colors()">

=item GD::Image->colorResolve()

=item GD::Image->string()

=back

=item Accesses external data

OME::Graphics::GD::* -> image

=back

=cut

sub DrawGraphics {
my $self = shift;
my $cgi   = $self->CGI();
my %params;
my $type;
my $layer;
my @string;

	foreach ($cgi->url_param()) {
		$params{$_} = $cgi->url_param($_);
		push (@string,$_.' = '.$cgi->url_param($_));
	}

	$params{allZ} = $params{allZ} eq 'true' ? 1 : 0;
	$params{allT} = $params{allT} eq 'true' ? 1 : 0;
	$params{width} = 782;
	$params{height} = 854;
	$params{color} = OME::Graphics::JavaScript::Layer->X11Colors->{ $params{color} };
	$type = delete $params{layerType};
	
	# $type should be something under OME::Graphics::GD
	$layer = eval ("new $type (%params)") || die "Layer of type '$type' is not supported\n";
	$layer->Draw ();

# some stuff for testing - this draws the params onto the image.
	my $Y=0;
	my $black = $layer->{image}->colorResolve(1,1,1);
	foreach (@string) {
		$layer->{image}->string(gdSmallFont,10,$Y,$_,$black);
		$Y += 12;
	}

# Output the layer's image.
	$self->{contentType} = $layer->imageType;
	return $layer->getImage;
}

# Add to Layer:
# imageType (i.e. 'image/png')
# getImage returns the actual image, i.e. {image}->png, etc.
# Change type to a full module spec.

=pod

=head2 DrawLayersControls()

=over 4

=item Description

Generates an html file housing the rest of the controls

=item Returns

An html file

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item L<"getJSgraphics()">

=item L<OME::Graphics::JavaScript/"Form()">

=back

=back

=cut

sub DrawLayersControls {
my $self = shift;
my $cgi   = $self->CGI();
my $JSgraphics = $self->getJSgraphics() ;

	$self->{contentType} = 'text/html';
	return $cgi->start_html(-title=>'Layers Popup').$JSgraphics->Form('opener').$cgi->end_html;
}

=pod

=head2 getJSgraphics()

=over 4

=item Description

Generates a OME::Graphics::JavaScript object for internal use

=item Returns

an object of type L<OME::Graphics::JavaScript>

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">	(via self)

=item CGI->url_param()

=item L<OME::Web/"Factory()">

=item L<OME::Factory/"loadObject()">	(via OME::Session, OME::Factory)

=item L<OME::Web/"Session()">

=item L<OME::Session/"DBH()">

=item DBI->prepare()

	$sth->execute()
	$sth->fetchrow_array()

=item L<OME::Graphics::JavaScript/"new()">

=item L<OME::Graphics::JavaScript/"AddLayer()">

=item OME::Graphics::JavaScript::Layer::*->new()

Object type declared dynamically at runtime.

=back

=item Accesses ome database tables

attributes_image_xyzwt

=item Generated Javascript will reference

OME::Web::GetGraphics via serve.pl, eventually calling
	L<"DrawGraphics()">

../cgi-bin/OME_JPEG

=back

=back

=cut

# This gets called when the Image window gets made in order to make the JS objects
# This also gets called when the layer control popup opens because the same Perl objects
# make the JS objects and make the form controls for them.
# The popup call has a DrawLayersControls URL parameter.
# FIXME?  Maybe we should have the JS objects make their own form elements on the client without bothering the server?
sub getJSgraphics {
    my $self = shift;
    my $cgi   = $self->CGI();

    my $ImageID = $cgi->url_param('ImageID') || die "ImageID not supplied to GetGraphics.pm";
    $self->{ImageID} = $ImageID;
    my $image;

    my $layer;

# This to come from the DB eventually.
    my $Layers = [
                  {
                      JStype   => 'OMEimage',
                      LayerCGI => '../cgi-bin/OME_JPEG',
                      SQL      => undef,
                      Options  => 'name=Image234&allZ=0&allT=0&isRGB=1'
                      },{
                          JStype   => 'Vectors',
                          LayerCGI => 'serve.pl',
                          SQL      => undef,
                          Options  => 'Page=OME::Web::GetGraphics&layerType=OME::Graphics::GD::Vectors&color=green&name=Vectors2&allZ=1&allT=0'
                          },{
                              JStype   => 'Centroids',
                              LayerCGI => 'serve.pl',
                              SQL      => undef,
                              Options  => 'Page=OME::Web::GetGraphics&layerType=OME::Graphics::GD::Centroids&color=blue&name=Centroids11&allZ=1&allT=0'
                              },{
                                  JStype   => 'Vectors',
                                  LayerCGI => 'serve.pl',
                                  SQL      => undef,
                                  Options  => 'Page=OME::Web::GetGraphics&layerType=OME::Graphics::GD::Vectors&color=blue&name=Vectors1&allZ=1&allT=0'
                                  }];
    my $layerSpec;

    # Don't bother with the image if we're just drawing the layer controls.
    $image = $self->Factory()->loadObject("OME::Image",$ImageID);
    die "Could not retreive Image from ImageID=$ImageID\n"
    	unless defined $image;
    print STDERR ref($self)."->getJSgraphics:  ImageID=".$image->image_id()." Name=".$image->name." Path=".$image->getFullPath()."\n";
#    my $attributes = $image->ImageAttributes();
	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp);
	my $SQL = <<ENDSQL;
	SELECT size_x,size_y,size_z,num_waves,num_times,bits_per_pixel FROM attributes_image_xyzwt WHERE image_id=?;
ENDSQL

	my $DBH = $self->Session()->DBH();
	my $sth = $DBH->prepare ($SQL);
	$sth->execute($ImageID);
	($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp) = $sth->fetchrow_array;
	$bpp /= 8;

# Set theZ and theT to defaults unless they are in the CGI url_param.
    my $theZ = $cgi->url_param('theZ') || ( defined $sizeZ ? sprintf "%d",$sizeZ / 2 : 0 );
    my $theT = $cgi->url_param('theT') || 0;

    my $JSgraphics = new OME::Graphics::JavaScript (
                                                    theZ=>$theZ,theT=>$theT,Session=>$self->Session(),ImageID=>$ImageID,
                                                    Dims=>[$sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp]);

# Add the layers
    foreach $layerSpec (@$Layers) {

        $layer = eval 'new OME::Graphics::JavaScript::Layer::'.$layerSpec->{JStype}.'(%$layerSpec)';
        if ($@ || !defined $layer) {
            print STDERR "Error loading package - $@\n";
            die "Error loading package - $@\n";
        } else {
            $JSgraphics->AddLayer ($layer);
        }
    }

    return $JSgraphics;

}

=pod

=head1 Questions

=over 4

=item Q:

Why isn't there a "getPageBody" function to override the one in OME::Web? Comments
in OME::Web indicate all subclasses should override this function. While
createOMEpage seems to fullfill this functional role, why wasn't this class
constructed to follow the described standard?

=item A:

Because the described standard results in a page fitting a generic style. 
GetGraphics is supposed to appear in a minimal popup window. OME::Web uses
createOMEpage to make the generic page. Overriding createOMEpage prevents
calls to getPageBody and returns a full html file.

=back

=cut
