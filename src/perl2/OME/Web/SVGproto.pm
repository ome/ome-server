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
package OME::Web::SVGproto;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
use OME::Image;
@ISA = ("OME::Web");

my $URLRoot = "serve.pl?Page=OME::Web::SVGproto";

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
		return('HTML', $self->DrawMainWindowSVG());
	} elsif ( $cgi->url_param('BuildSVGviewer') ) {
		return('SVG', $self->BuildSVGviewer());
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
L<"DrawLayersControls()" and L<"DrawGraphics()">

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

=head1 Internally referenced functions

=over 4

=item

=head2 DrawMainWindowSVG()

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
L<"DrawLayersControls()" and L<"DrawGraphics()">

=back

=cut

sub DrawMainWindowSVG {
my $self = shift;
my $cgi   = $self->CGI();
my $ImageID = $cgi->url_param("ImageID")  || die "\nImage id not supplied to GetGraphics.pm ";
my $HTML='';

	$self->{contentType} = 'text/html';
#	$HTML = $cgi->start_html(-title=>'OME SVG 2D Viewer');
# Add controls to change the displayed image. e.g. switch to previous or next image in a set.
# Embedding in frames instead of object allows Mozilla > v1 to run it. Keep if no problems w/ it.
	$HTML .= <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<title>OME SVG 2D Viewer</title>
	<frameset rows="*">
		<frame src="$URLRoot&BuildSVGviewer=1&ImageID=$ImageID">
	</frameset>
</html>
ENDHTML
#	$HTML .= qq '\n<embed width="100%" height="100%" src="$URLRoot&BuildSVGviewer=1&ImageID=$ImageID">\n';
#	$HTML .= $cgi->end_html;

	return ($HTML);
}


# Build the SVG viewer.
sub BuildSVGviewer {
	# A server link needs to be made to src/JavaScript/ for the SVG JavaScript references to function
my $self = shift;
my $SVG;

my $JSgraphics = $self->SVGgetJS();
my $OMEimage = $JSgraphics->{layers}->[0];
my $Wavelengths = $OMEimage->JS_Wavelengths();
$OMEimage->Stats();
my $Stats = $OMEimage->{JS_Stats};
my $ImageID = $JSgraphics->{ImageID};
my $pDims = $JSgraphics->{Dims};
my $Dims = '['.join (',', @$pDims).']';

my $image = $self->Factory()->loadObject("OME::Image",$ImageID);
my $Path = $image->getFullPath();
my $CGI_URL = '/cgi-bin/OME_JPEG';
my $CGI_optionStr  = '&Path='.$Path;

	$self->{contentType} = "image/svg+xml";
	$SVG = <<'ENDSVG';
<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN"
	"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [
	<!ATTLIST svg
		xmlns:a3 CDATA #IMPLIED
		a3:scriptImplementation CDATA #IMPLIED>
	<!ATTLIST script
		a3:scriptImplementation CDATA #IMPLIED>
]>
<svg xml:space="preserve" onload="init(evt)"
	xmlns="http://www.w3.org/2000/svg"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:a3="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"
	a3:scriptImplementation="Adobe">
	<!--            GUI classes             -->
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/widget.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/toolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/multipaneToolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/multipaneToolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/slider.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/popupList.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/button.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/AntiZoomAndPan.js" />
	<!--            Backend classes         -->
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/OMEimage.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/scale.js" />
    <script type="text/ecmascript" a3:scriptImplementation="Adobe"><![CDATA[
ENDSVG

# dynamic initialization of JS objects goes here:
$SVG .= <<ENDSVG;
	// GUI components
		var controlsToolBox, multiToolBox;
		var zSlider, tSlider;
		var blackSlider, whiteSlider;
		var redPopupList, bluePopupList, greenPopupList, bwPopupList;
		var scalePopupList, panePopupList;
		var RGBpopupListBox, BWpopupListBox;
		var redButton, blueButton, greenButton, RGB_BWbutton;
		var azap = new AntiZoomAndPan();

	// backend components
		var image;
		var scale;
		
	// constants & references
		// Z and T are dims of z and t
		var Z = $pDims->[2];
		var T = $pDims->[4];
		var scaleWidth = 180;
		var Wavelengths = $Wavelengths;
		var Stats = $Stats;
		var fluors = new Array();
		
	// global variables
		// theZ & theT are current values of z & t
		var theZ, theT;


        function init(e) {
            if ( window.svgDocument == null )
                svgDocument = e.ownerDocument;

		// initialize back end
			image = new OMEimage($ImageID,$Wavelengths,$Stats,$Dims,"$CGI_URL","$CGI_optionStr");
			image.realize( svgDocument.getElementById("image") );
// need to add query for RGBon for image.setRGBon			

			// setup fluors used in this image
			for(i in Wavelengths)
				fluors[Wavelengths[i]['WaveNum']] = Wavelengths[i]['Fluor'];

		// initialize frontend
			controlToolBox = new toolBox(
				50, 30, 200, 150,
				svgDocument.getElementById("menuBar").firstChild.data,
				svgDocument.getElementById("hideControl").firstChild.data,
				svgDocument.getElementById("GUIbox").firstChild.data
			);
			controlToolBox.setLabel(90,12,"Controls")
			controlToolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
			
			multiToolBox = new multipaneToolBox(
				55, 265, 200, 100,
				svgDocument.getElementById("menuBar").firstChild.data,
				svgDocument.getElementById("hideControl").firstChild.data,
				'<g>' +
				'	<rect width="{\$width}" height="1000" fill="none" stroke="black"	stroke-width="2"/>'+
				'	<rect width="{\$width}" height="1000" fill="ghostwhite" opacity="0.5"/>' +
				'</g>'
			);
			
			zSlider = new Slider(
				30, 120, 100, -90,
				updateTheZ,
				svgDocument.getElementById("zSliderBody").firstChild.data,
				svgDocument.getElementById("zSliderThumb").firstChild.data
			);
			zSlider.setLabel(0,-102,"");
			zSlider.getLabel().setAttribute( "fill", "white" );
			zSlider.getLabel().setAttribute( "text-anchor", "middle" );

			tSlider = new Slider(
				60, 30, 100, 0,
				updateTheT
			);
			tSlider.setLabel(60,-13,"");
			tSlider.getLabel().setAttribute( "fill", "white" );

			// wavelength to channel popupLists
			redPopupList = new popupList(
				-50, 0, fluors, updateRedWavelength, 1,
				svgDocument.getElementById("redAnchorText").firstChild.data,
				svgDocument.getElementById("redItemBackgroundText").firstChild.data,
				svgDocument.getElementById("redItemHighlightText").firstChild.data
			);

			greenPopupList = new popupList(
				0, 0, fluors, updateGreenWavelength, 0,
				svgDocument.getElementById("greenAnchorText").firstChild.data,
				svgDocument.getElementById("greenItemBackgroundText").firstChild.data,
				svgDocument.getElementById("greenItemHighlightText").firstChild.data
			);

			bluePopupList = new popupList(
				50, 0, fluors, updateBlueWavelength, 0,
				svgDocument.getElementById("blueAnchorText").firstChild.data,
				svgDocument.getElementById("blueItemBackgroundText").firstChild.data,
				svgDocument.getElementById("blueItemHighlightText").firstChild.data
			);
			
			bwPopupList = new popupList(
				0, 0, fluors, updateBWWavelength
			);
			
			// set up channel on/off buttons
			redButton = new button( 
				Math.round(redPopupList.x + redPopupList.width/2), -13, turnRedOnOff,
				svgDocument.getElementById("redButtonOn").firstChild.data,
				svgDocument.getElementById("redButtonOff").firstChild.data,
				svgDocument.getElementById("blankButtonRadius5Highlight").firstChild.data
			);
			greenButton = new button( 
				Math.round(greenPopupList.x + greenPopupList.width/2), -13, turnGreenOnOff,
				svgDocument.getElementById("greenButtonOn").firstChild.data,
				svgDocument.getElementById("greenButtonOff").firstChild.data,
				svgDocument.getElementById("blankButtonRadius5Highlight").firstChild.data
			);
			blueButton = new button(
				Math.round(bluePopupList.x + bluePopupList.width/2), -13, turnBlueOnOff,
				svgDocument.getElementById("blueButtonOn").firstChild.data,
				svgDocument.getElementById("blueButtonOff").firstChild.data,
				svgDocument.getElementById("blankButtonRadius5Highlight").firstChild.data
			);
			
			// set up RGB to grayscale button
			RGB_BWbutton = new button(
				110, 115, switchRGB_BW,
				svgDocument.getElementById("RGB_BWButtonOn").firstChild.data,
				svgDocument.getElementById("RGB_BWButtonOff").firstChild.data,
				svgDocument.getElementById("blankButtonRadius13Highlight").firstChild.data
			);
			
			// z & t increment buttons
			tUpButton = new button(
				182, 30, tUp,
				svgDocument.getElementById("triangleRight").firstChild.data
			)
			tDownButton = new button(
				178, 30, tDown,
				svgDocument.getElementById("triangleLeft").firstChild.data
			)
			zUpButton = new button(
				15, 106, zUp,
				svgDocument.getElementById("triangleUp").firstChild.data
			)
			zDownButton = new button(
				15, 110, zDown,
				svgDocument.getElementById("triangleDown").firstChild.data
			)
				
		// realize the GUI elements in the appropriate containers
            var controls  = svgDocument.getElementById("controls");
            controlToolBox.realize(controls);
            
            // Z & T controls
			zSlider.realize(controlToolBox.getGUIbox());
			tSlider.realize(controlToolBox.getGUIbox());
			tUpButton.realize(controlToolBox.getGUIbox());
			tDownButton.realize(controlToolBox.getGUIbox());
			zUpButton.realize(controlToolBox.getGUIbox());
			zDownButton.realize(controlToolBox.getGUIbox());

			// RGB & BW switcheroo
			RGB_BWbutton.realize(controlToolBox.getGUIbox());

			// RGB channel controls
			RGBpopupListBox = svgDocument.createElementNS( svgns, "g" );
			RGBpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
			controlToolBox.getGUIbox().appendChild( RGBpopupListBox );
			redButton.realize( RGBpopupListBox );
			greenButton.realize( RGBpopupListBox );
			blueButton.realize( RGBpopupListBox );
			redPopupList.realize( RGBpopupListBox );
			greenPopupList.realize( RGBpopupListBox );
			bluePopupList.realize( RGBpopupListBox );

			// Grayscale controls
			BWpopupListBox = svgDocument.createElementNS( svgns, "g" );
			BWpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
			BWpopupListBox.setAttribute( "display", "none" );
			controlToolBox.getGUIbox().appendChild( BWpopupListBox );
			bwPopupList.realize( BWpopupListBox );
			
			// toolbox to house all other interfaces
			multiToolBox.realize(controls);
			//	These panes to come from DB eventually
			scale = new Scale(image, updateBlackLevel, updateWhiteLevel);
			multiToolBox.addPane( scale.buildSVG(), "Scale");
			multiToolBox.addPaneText(
				svgDocument.getElementById("info").firstChild.data, "Info" );
			multiToolBox.addPane( null, "Other");
			// set up multiToolBox pane control popupList
			panePopupList = new popupList(
				0, 0, multiToolBox.getPaneIndexes(), updatePane );
			panePopupList.realize( multiToolBox.getMenuBar() );


            azap.appendNode(controls); 
            
			// Set up display. These values should come from DB eventually.
			setTimeout( "redPopupList.setSelection(0)", 0 );
			setTimeout( "greenPopupList.setSelection(1)", 0 );
			setTimeout( "bluePopupList.setSelection(1)", 0 );
			setTimeout( "bwPopupList.setSelection(0)", 0 );
			setTimeout( "panePopupList.setSelection(0)", 0 );
			var RGBon = image.getRGBon(); 
			setTimeout( "redButton.setState(" + (RGBon[0]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "greenButton.setState(" + (RGBon[1]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "blueButton.setState(" + (RGBon[2]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "RGB_BWbutton.setState(true)", 0 );

			zSlider.setValue(50,true);	// 50% of z range
			tSlider.setValue(0,true);	// 0% of t range

//			image.setPreload(1);//*/
		}
	
/*	// Scale stuff	
		function buildScalePane() {
			var root = svgDocument.createElementNS(svgns, "g");
		
			blackSlider = new Slider( 
				10, 60, scaleWidth, 0, 
				updateBlackLevel,
				'<rect width="'+scaleWidth+'" height="10" opacity="0"/>',
				'<rect x="-2" width="4" height="10" fill="black"/>'
			);
			whiteSlider = new Slider( 
				10, 70, scaleWidth, 0, 
				updateWhiteLevel,
				'<rect width="'+scaleWidth+'" height="10" opacity="0"/>',
				'<rect x="-2" width="4" height="10" fill="white"/>'
			);
			scalePopupList = new popupList(
				10, 90, fluors, null
			);
		
			root.appendChild( whiteSlider.textToSVG(
				'<g transform="translate(10,70)">' +
				'	<line x2="'+ scaleWidth +'" stroke-width="2" stroke="blue"/>' +
				'	<line id="geomeanTick" y1="-10" y2="10" stroke-width="2" stroke="blue"/>' +
				'</g>'
			));
			
			root.appendChild( whiteSlider.textToSVG(
				'<text x="20" y="2em">Black level: </text>' ));
			blackLabel = root.lastChild;
			root.appendChild( whiteSlider.textToSVG(
				'<text x="20" y="3em">White level: </text>' ));
			whiteLabel = root.lastChild;
			root.appendChild( whiteSlider.textToSVG(
				'<text x="20" y="4em">Scale: </text>' ));
			scaleLabel = root.lastChild;
		
			blackSlider.realize( root );
			whiteSlider.realize( root );
			scalePopupList.realize( root );
			
			return root;
		}
		// updateScale should be called when time or scale wavelength is changed
		// tick marks and calculated length of scale bar are dependent on those things
		function updateScale(t) {
			if(blackSlider == null || whiteSlider == null) return null;
			var wavenum = wavePopupList.getSelection();
			var min = Stats[wavenum][theT]['min'];
			var max = Stats[wavenum][theT]['max'];
			var sigma = Stats[wavenum][theT]['sigma'];
			var geomeanX = (Stats[wavenum][theT]['geomean'] - min) / (max - min) * scaleWidth;
			svgDocument.getElementById("geomeanTick").setAttribute("transform", "translate("+geomeanX+",0)");
			// set B&W sliderVals to correct positions
		}*/

		function updateBlackLevel(val) {
		scale.blackLabel.firstChild.data = "Black level: " + val;
			// make val in bounds
			// set val to in bounds
			// update black bar
			// set scale.BS
			// call scale.updateWBS
		}
	
		function updateWhiteLevel(val) {
		scale.whiteLabel.firstChild.data = "White level: " +val;
			// make val in bounds
			// set val to in bounds
			// update white bar
			// convert val to native WBS
			// set scale.BS
			// call scale.updateWBS
		}

ENDSVG

# more static stuff
$SVG .= <<'ENDSVG';
        
		
	// these functions connect GUI with backend
		function updateTheZ(data) {
			data=Math.round(data/100*(Z-1));
			var sliderVal = (Z==1 ? 0 : Math.round(data/(Z-1)*100) );
			zSlider.setValue(sliderVal);
			zSlider.setLabel(null, null, data + "/" + (Z-1) );
			theZ=data;
			
			image.updatePic(theZ,theT);
		}
		function zUp() {
			var data = (theZ< Z-1 ? theZ + 1 : theZ)
			var sliderVal = ( Z==1 ? 0 : Math.round( data/(Z-1)*100 ) );
			updateTheZ(sliderVal);
		}
		function zDown() {
			var data = (theZ> 0 ? theZ - 1 : theZ)
			var sliderVal = ( Z==1 ? 0 : Math.round( data/(Z-1)*100 ) );
			updateTheZ(sliderVal);
		}

		function updateTheT(data) {
			theT=Math.round(data/100*(T-1));
			var sliderVal = ( T==1 ? 0 : Math.round(theT/(T-1)*100) );
			tSlider.setValue(sliderVal);
			tSlider.setLabel(null, null, "time (" + theT + "/" + (T-1) +")" );
			
			image.updatePic(theZ,theT);
		}
		function tUp() {
			var data = (theT< T-1 ? theT+1 : theT)
			var sliderVal = ( T==1 ? 0 : Math.round( data/(T-1)*100 ) );
			updateTheT(sliderVal);
		}
		function tDown() {
			var data = (theT> 0 ? theT -1 : theT)
			var sliderVal = ( T==1 ? 0 : Math.round( data/(T-1)*100 ) );
			updateTheT(sliderVal);
		}

		// reflect changes made to popupLists controlling wavelength to RGB channels
		function updateRedWavelength(item) {
			WBS = image.getWBS();
			WBS[0]=item;
			image.setWBS(WBS);
		}
		function updateGreenWavelength(item) {
			WBS = image.getWBS();
			WBS[3]=item;
			image.setWBS(WBS);
		}
		function updateBlueWavelength(item) {
			WBS = image.getWBS();
			WBS[6]=item;
			image.setWBS(WBS);
		}
		function updateBWWavelength(item) {
			WBS = image.getWBS();
			WBS[9]=item;
			image.setWBS(WBS);
		}
		function updatePane(item) {
			var itemList = panePopupList.getItemList();
			multiToolBox.changePane( itemList[item] );
		}
		function turnRedOnOff(val) {
			RGBon = image.getRGBon();
			RGBon[0] = (val ? 1 : 0);
			image.setRGBon(RGBon);
		}
		function turnGreenOnOff(val) {
			RGBon = image.getRGBon();
			RGBon[1] = (val ? 1 : 0);
			image.setRGBon(RGBon);
		}
		function turnBlueOnOff(val) {
			RGBon = image.getRGBon();
			RGBon[2] = (val ? 1 : 0);
			image.setRGBon(RGBon);
		}
		function switchRGB_BW(val) {
			//	decide which way to flip
			if(val) {	// val == true means mode = RGB
				BWpopupListBox.setAttribute( "display", "none" );
				RGBpopupListBox.setAttribute( "display", "inline" );
			}
			else {	// mode = BW
				BWpopupListBox.setAttribute( "display", "inline" );
				RGBpopupListBox.setAttribute( "display", "none" );
			}
			image.setDisplayRGB_BW(val);
		}
		
    ]]></script>
	<defs>
		<text id="menuBar"><![CDATA[
			<g>
				<g opacity="0.8">
					<rect width="{$width}" height="15" fill="lawngreen" rx="10" ry="5"/>
					<rect y="5" width="{$width}" height="10" fill="lawngreen"/>
				</g>
			</g>
		]]></text>
		<text id="hideControl"><![CDATA[
			<g>
				<ellipse rx="5" ry="5" fill="ghostwhite" stroke="forestgreen" stroke-width="1">
					<animate id="anim1" attributeName="ry" from="5" to="2" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>
					<animate id="anim2" attributeName="ry" from="2" to="5" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>
				</ellipse>
			</g>
		]]></text>
		<text id="GUIbox"><![CDATA[
			<g style="font-size:10;">
				<linearGradient id="GUIboxBackground" x1="0" y1="0" x2="0" y2="100%">
					<stop offset="5%" stop-color="green" />
					<stop offset="95%" stop-color="palegreen" />
				</linearGradient>
				<rect width="{$width}" height="{$height}" fill="url(#GUIboxBackground)" opacity="0.7"/>
				<rect width="{$width}" height="{$height}" fill="none" stroke="black" stroke-width="3" opacity="1"/>

				<animateTransform attributeName="transform" type="rotate" from="0" to="-90" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>
				<animateTransform attributeName="transform" type="rotate" from="-90" to="0" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>
				<set attributeName="display" to="inline" begin="indefinite"/>
				<set attributeName="display" to="none" begin="indefinite"/>
			</g>
		]]></text>
		<text id="zSliderBody"><![CDATA[
			<g stroke="rgb(80,80,80)" transform="rotate(90)">
				<g id="xyPlane" transform="scale(.6) skewX(-45)">
					<polyline points=
						"-27,0 -25,-3 -30,0 -25,3 -27,0 27,0 25,3 30,0 25,-3 27,0"/>
					<text x="17" y="10" style="font-size:10;">x</text>
					<polyline points=
						"0,-27 -3,-25 0,-30 3,-25 0,-27 0,27 3,25 0,30 -3,25 0,27"/>
					<text x="5" y="-17" style="font-size:10;">y</text>
				</g>
				<g id="zAxis">
					<polyline points="0,0 0,-100 -4,-92 0,-95 4,-92 0,-100"/>
					<rect x="-7" y="-100" width="14" height="100" opacity="0"/>
					<text x="-9" y="-82" style="font-size:12;" fill="black" stroke="none">z</text>
				</g>
			</g>
		]]></text>
		<text id="zSliderThumb"><![CDATA[
			<g>
				<rect x="-1" y="-7" width="2" height="14" fill="black"/>
				<rect x="-3" y="-7" width="6" height="14" fill="red" opacity="0">
					<set attributeName="opacity" to="0.4" begin="mouseover"
						end="mouseout"/>
				</rect>
			</g>
		]]></text>
		<text id="redAnchorText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="rgb(255,70,70)"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="redItemBackgroundText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="0" fill="rgb(255,70,70)"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">
				<animate attributeName="height" from="0" to="{$height}" dur="0.1s"
					fill="freeze" begin="indefinite"/>
				<animate attributeName="height" from="{$height}" to="0" dur="0.1s"
					fill="freeze" begin="indefinite"/>
			</rect>
		]]></text>
		<text id="redItemHighlightText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="rgb(255,130,130)"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="greenAnchorText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="mediumseagreen"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="greenItemBackgroundText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="0" fill="mediumseagreen"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">
				<animate attributeName="height" from="0" to="{$height}" dur="0.1s"
					fill="freeze" begin="indefinite"/>
				<animate attributeName="height" from="{$height}" to="0" dur="0.1s"
					fill="freeze" begin="indefinite"/>
			</rect>
		]]></text>
		<text id="greenItemHighlightText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="lime"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="blueAnchorText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="cornflowerblue"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="blueItemBackgroundText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="0" fill="cornflowerblue"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">
				<animate attributeName="height" from="0" to="{$height}" dur="0.1s"
					fill="freeze" begin="indefinite"/>
				<animate attributeName="height" from="{$height}" to="0" dur="0.1s"
					fill="freeze" begin="indefinite"/>
			</rect>
		]]></text>
		<text id="blueItemHighlightText"><![CDATA[
			<rect x="-2" width="{$width + 4}" height="{$height}" fill="aqua"
				rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>
		]]></text>
		<text id="redButtonOn"><![CDATA[
			<circle cy="5" r="5" fill="pink" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="redButtonOff"><![CDATA[
			<circle cy="5" r="5" fill="darkred"/>
		]]></text>
		<text id="greenButtonOn"><![CDATA[
			<circle cy="5" r="5" fill="lightgreen" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="greenButtonOff"><![CDATA[
			<circle cy="5" r="5" fill="darkgreen"/>
		]]></text>
		<text id="blueButtonOn"><![CDATA[
			<circle cy="5" r="5" fill="lightblue" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="blueButtonOff"><![CDATA[
			<circle cy="5" r="5" fill="darkblue"/>
		]]></text>
		<text id="RGB_BWButtonOn"><![CDATA[
			<g>
				<circle cy="13" r="13" fill="white" stroke="black" stroke-width="1"/>
				<text fill="black" text-anchor="middle" dominant-baseline="middle" 
					y="17">B/W</text>
			</g>
		]]></text>
		<text id="RGB_BWButtonOff"><![CDATA[
			<g>
				<circle cy="13" r="13" fill="white" stroke="black" stroke-width="1"/>
				<text fill="black" text-anchor="middle" dominant-baseline="middle" 
					y="17">RGB</text>
			</g>
		]]></text>
		<text id="blankButtonRadius13Highlight"><![CDATA[
			<circle cy="13" r="13" fill="white" stroke="none" opacity="0"/>
		]]></text>
		<text id="blankButtonRadius5Highlight"><![CDATA[
			<circle cy="5" r="5" fill="white" stroke="none" opacity="0"/>
		]]></text>
		<text id="info"><![CDATA[
			<g>
				<text y="1em">Information:</text>
				<text id="info1" x="30" y="2em"> </text>
				<text id="info2" x="30" y="3em"> </text>
			</g>
		]]></text>
		<text id="triangleRight"><![CDATA[
			<path d="M 0,4 l 6,-4 l -6,-4 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="triangleLeft"><![CDATA[
			<path d="M 0,4 l -6,-4 l 6,-4 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="triangleDown"><![CDATA[
			<path d="M 4,0 l -4,6 l -4,-6 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>
		]]></text>
		<text id="triangleUp"><![CDATA[
			<path d="M 4,0 l -4,-6 l -4,6 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>
		]]></text>
	</defs>
	<g id="image">
	</g>
	<g id="overlays">
	</g>
	<g id="controls">
	</g>
</svg>
ENDSVG
;

	return $SVG;
}

# this is for use during development only! it's fucking ugly!
sub SVGgetJS {
	my $self = shift;

    my $cgi   = $self->CGI();

    my $ImageID = $cgi->url_param('ImageID') || die "ImageID not supplied to GetGraphics.pm";
    $self->{ImageID} = $ImageID;

    my $layer;
    my $image;

    my $OMEimage =
                  {
                      JStype   => 'OMEimage',
                      LayerCGI => '../cgi-bin/OME_JPEG',
                      SQL      => undef,
                      Options  => 'name=Image234&allZ=0&allT=0&isRGB=1'
                  };

    # Don't bother with the image if we're just drawing the layer controls.
    $image = $self->Factory()->loadObject("OME::Image",$ImageID);
    die "Could not retreive Image from ImageID=$ImageID\n"
    	unless defined $image;
    print STDERR ref($self)."->getJSgraphics:  ImageID=".$image->image_id()." Name=".$image->name." Path=".$image->getFullPath()."\n";
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
    $layer = eval 'new OME::Graphics::JavaScript::Layer::'.$OMEimage->{JStype}.'(%$OMEimage)';
    if ($@ || !defined $layer) {
        print STDERR "Error loading package - $@\n";
        die "Error loading package - $@\n";
    } else {
        $JSgraphics->AddLayer ($layer);
    }

    return $JSgraphics;
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