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
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::DBObject;
use OME::Image;
use base qw{ OME::Web };

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

=item L<OME::Image.Dimensions()|OME::Image/"Dimensions()">

=item L<OME::Image.XYZ_info|OME::Image/"XYZ_info">

=item L<OME::Image.wavelengths|OME::Image/"wavelengths">

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

	# Does this image ID exist? If it doesn't and we trap the error now, then we can display error message.
	my $ImageID   = $cgi->url_param('ImageID');
	my $DatasetID = $cgi->url_param('DatasetID');
	if( !defined $ImageID and !defined $DatasetID ) {
		die "Package needs either ImageID or DatasetID as url parameters. Neither was supplied. This message generated by ".(ref $self)."->createOMEpage().";
	}
	if( defined $ImageID ) {
		my $image = $self->Session->Factory()->loadObject("OME::Image",$ImageID);
		die "Could not load Image (ID=$ImageID) from database. This message generated by ".(ref $self)."->createOMEpage()."
			unless defined $image;
	}
	if( defined $DatasetID ) {
		my $dataset = $self->Session()->Factory()->loadObject("OME::Dataset",$DatasetID);
		die "Could not load Dataset (ID=$DatasetID) from database. This message generated by ".(ref $self)."->createOMEpage()."
			unless defined $dataset;
	}

	if ( $cgi->url_param('DrawLayersControls') ) {
		return ('HTML',$self->DrawLayersControls());
	} elsif ( $cgi->url_param('name') ) {
		return ('IMAGE',$self->DrawGraphics());
	} elsif ( $cgi->url_param('HTML') ) {
		return ('HTML',$self->DrawMainWindow());
	} elsif ( $cgi->url_param('BuildSVGviewer') ) {
		return('SVG', $self->BuildSVGviewer());
	} elsif ( $cgi->url_param('DrawDatasetControl')) {
		return('HTML', $self->DrawDatasetControl());
	} elsif ( $cgi->url_param('ImageID')) {
		return('HTML', $self->DrawMainWindowSVGimage());
	} elsif ( $cgi->url_param('DatasetID')) {
		return('HTML', $self->DrawMainWindowSVGdataset());
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

=head2 DrawMainWindowSVG()

=over 4

=item Description

Generates an HTML file housing the svg viewer

=item Returns

an HTML file

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=back

=back

=cut

sub DrawMainWindowSVGimage {
my $self      = shift;
my $cgi       = $self->CGI();
my $ImageID   = $cgi->url_param("ImageID")  || die "\nImage id not supplied to GetGraphics.pm ";
my $DatasetID = $cgi->url_param("DatasetID");
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
		<frame src="serve.pl?Page=OME::Web::GetGraphics&BuildSVGviewer=1&ImageID=$ImageID
ENDHTML
$HTML .= "&DatasetID=$DatasetID"
	if defined $DatasetID;
$HTML .= <<ENDHTML;
">
	</frameset>
</html>
ENDHTML
#	$HTML .= qq '\n<embed width="100%" height="100%" src="serve.pl?Page=OME::Web::GetGraphics&BuildSVGviewer=1&ImageID=$ImageID">\n';
#	$HTML .= $cgi->end_html;

	return ($HTML);
}

=pod

=head2 DrawMainWindowSVGdataset()

=over 4

=item Description

Generates an HTML file housing dataset controls & the svg viewer

=item Returns

an HTML file

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=back

=back

=cut

sub DrawMainWindowSVGdataset {
my $self = shift;
my $cgi   = $self->CGI();
my $DatasetID = $cgi->url_param('DatasetID') || die "\nDataset id not supplied to GetGraphics.pm ";
my $HTML='';

	$self->{contentType} = 'text/html';
	$HTML .= <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<title>OME Dataset Viewer</title>
	<frameset rows="80,*" border="0">
		<frame name="controls" src="serve.pl?Page=OME::Web::GetGraphics&DrawDatasetControl=1&DatasetID=$DatasetID">
		<frame name="viewer" src="">
	</frameset>
</html>
ENDHTML

	return ($HTML);
}

=pod

=head2 DrawDatasetControl()

=over 4

=item Description

Generates an HTML file housing dataset controls

=item Returns

an HTML file

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=back

=back

=cut

sub DrawDatasetControl {
	my $self = shift;
	my $cgi   = $self->CGI();
	my $DatasetID = $cgi->url_param('DatasetID') || die "\nDataset id not supplied to GetGraphics.pm ";
	my $Dataset = $self->Session()->Factory()->loadObject("OME::Dataset",$DatasetID) || die "\nInvalide dataset id provided to GetGraphics.pm\n";
	my $imageMaps = $Dataset->image_links();
	my ($imageMap, @ImageIDs, $JSimageIDs, %ImagePaths, $JS_SetImagePathArray, $HTML);
	my $numImages = 0;
	my $datasetName = $Dataset->name();
	
    while (my $imageMap = $imageMaps->next()) {
		$numImages++;
		push (@ImageIDs, $imageMap->image()->image_id());
		$ImagePaths{ $imageMap->image()->image_id() } = $imageMap->image()->path();
	}	
	$JSimageIDs = '['.join(',',@ImageIDs).']';
	$JS_SetImagePathArray = join( "\n", map( "imagePaths[$_] = '".$ImagePaths{$_}."';", keys %ImagePaths) );
	

	$self->{contentType} = 'text/html';
	$HTML = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head>
<title>Select Image from Dataset</title>
<script language="JavaScript">
<!--

var imageIDs   = $JSimageIDs;
var imagePaths = new Array();
$JS_SetImagePathArray
var currentIndex;
var imageNumTextBox;
var imageInfoTextBox;

// have to initialize pointer variables after document loads
function init() {
	imageNumTextBox  = document.forms[0].num;
	imageInfoTextBox = document.forms[0].ImageInfo;
	currentIndex = 0;
}

function previousImage() {
	if(currentIndex > 0) {
		currentIndex--;
		update();
	}
}

function nextImage() {
	if(currentIndex + 1 < imageIDs.length) {
		currentIndex++;
		update();
	}
}

function isInteger(data) {
	var inputStr = data.toString()
	var flag = true;
	for (var i = 0; i < inputStr.length; i++)
		{
		var oneChar = inputStr.charAt(i)
		if ((oneChar < "0" || oneChar > "9") && oneChar != "/")
				{
					flag = false;
				}
		}
	return flag;
}

function changeImage(i) {
	if( !isInteger(i) ) {
		imageNumTextBox.value = currentIndex+1;
		return;
	}
	i--;
	if( i != Math.round(i) ) i = Math.round(i);
	if( i<0 ) i=0;
	if( i>imageIDs.length-1 ) i=imageIDs.length-1;
	if(currentIndex != i) {
		currentIndex = i;
		update();
	}
}

function update() {
	imageNumTextBox.value  = currentIndex+1;
	imageInfoTextBox.value = imagePaths[ imageIDs[currentIndex] ];
	var str = "serve.pl?Page=OME::Web::GetGraphics&DatasetID=$DatasetID&ImageID=" + imageIDs[currentIndex];
	parent.viewer.location.href = str;
}

//-->
</script>
</head>
<body onload="init(); update();">
<table width="100%">
<form onsubmit="return false;">
<tr><td align="left">
	<input type="button" name="prev" value="<" onclick="previousImage()">
	<input type="text" name="num" size="5" onchange="changeImage(parseInt(this.value))" maxlength="5">
	<input type="button" name="next" value=">" onclick="nextImage()">
</td><td align="right">
	Image Path: <input type="text" name="ImageInfo" size="40" disabled>
</form>
</td></tr><tr><td colspan='2'>
Displaying dataset "$datasetName". It contains $numImages images.
</td></tr></table>
</html>
ENDHTML

	return ($HTML);

}

=pod

=head2 BuildSVGviewer()

=over 4

=item Description

Generates SVG viewer

=item Returns

an SVG file

=item Uses functions

=over 4

=item SVGgetDataJS()

=back

=back

=cut

# Build the SVG viewer.
sub BuildSVGviewer {
	# A server link needs to be made to src/JavaScript/ for the SVG JavaScript references to function
my $self      = shift;
my $cgi       = $self->CGI();
my $SVG;


my $JSinfo = $self->SVGgetDataJS();

my $DatasetID          = $cgi->url_param('DatasetID') || 'null';
my $ImageID            = $JSinfo->{ ImageID };
my $Stats              = $JSinfo->{ Stats };
my $Wavelengths        = $JSinfo->{ Wavelengths };
my $Dims               = $JSinfo->{ Dims };
my $CGI_URL            = $JSinfo->{ CGI_URL };
my $CGI_optionStr      = $JSinfo->{ CGI_optionStr };
my $SaveDisplayCGI_URL = $JSinfo->{ SaveDisplayCGI_URL };
my $theZ               = $JSinfo->{ theZ };
my $theT               = $JSinfo->{ theT };
my $isRGB              = $JSinfo->{ isRGB };
my $WBS                = $JSinfo->{ WBS };
my $RGBon              = $JSinfo->{ RGBon };
my $toolBoxScale       = $JSinfo->{ toolBoxScale };

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
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/skinLibrary.js" />
	<!--            Backend classes         -->
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/OMEimage.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/scale.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/overlay.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/ViewerPreferences.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/stats.js" />
    <script type="text/ecmascript" a3:scriptImplementation="Adobe"><![CDATA[
ENDSVG

# dynamic initialization of JS objects goes here:
$SVG .= <<ENDSVG;
	// GUI components
		var controlsToolBox, multiToolBox;
		var zSlider, tSlider;
		var redPopupList, bluePopupList, greenPopupList, bwPopupList;
		var scalePopupList, panePopupList;
		var RGBpopupListBox, BWpopupListBox;
		var redButton, blueButton, greenButton, RGB_BWbutton;
		var infoButton;
		var azap = new AntiZoomAndPan();

	// backend components
		var image;
		var scale;
		var stats;
		var overlay;
		var viewerPreferences;
		
	// constants & references
		var Wavelengths        = $Wavelengths;
		var Stats              = $Stats;
		var Dims               = $Dims;
		var DatasetID          = $DatasetID;
		// Z and T are dims of z and t
		var Z                  = Dims[2];
		var T                  = Dims[4];
		var fluors             = new Array();
		var SaveDisplayCGI_URL = "$SaveDisplayCGI_URL";
		var toolBoxScale       = $toolBoxScale;
		
	// global variables
		// theZ & theT are current values of z & t
		var theZ = $theZ;
		var theT = $theT;

		function init(e) {
			if ( window.svgDocument == null )
				svgDocument = e.ownerDocument;
		// initialize back end
			image = new OMEimage($ImageID,$Wavelengths,$Stats,$Dims,"$CGI_URL","$CGI_optionStr", 
				SaveDisplayCGI_URL, $WBS, $RGBon, $isRGB, DatasetID);
			image.realize( svgDocument.getElementById("image") );

			// setup fluors used in this image
			for(i in Wavelengths)
				fluors[Wavelengths[i]['WaveNum']] = Wavelengths[i]['Label'];
		// initialize frontend
			controlToolBox = new toolBox(
				50, 30, 200, 150,
				skinLibrary["menuBar"],
				skinLibrary["hideControl"],
				skinLibrary["GUIbox"]
			);
			controlToolBox.setLabel(90,12,"Primary Controls")
			controlToolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
			
			multiToolBox = new multipaneToolBox(
				55, 265, 200, 100,
				skinLibrary["menuBar17"],
				skinLibrary["XhideControl"],
				skinLibrary["tallGUIbox"]
			);
			
			zSlider = new Slider(
				30, 120, 100, -90,
				updateTheZ,
				skinLibrary["zSliderBody"],
				skinLibrary["zSliderThumb"]
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
				skinLibrary["redAnchorText"],
				skinLibrary["redItemBackgroundText"],
				skinLibrary["redItemHighlightText"]
			);

			greenPopupList = new popupList(
				0, 0, fluors, updateGreenWavelength, 0,
				skinLibrary["greenAnchorText"],
				skinLibrary["greenItemBackgroundText"],
				skinLibrary["greenItemHighlightText"]
			);

			bluePopupList = new popupList(
				50, 0, fluors, updateBlueWavelength, 0,
				skinLibrary["blueAnchorText"],
				skinLibrary["blueItemBackgroundText"],
				skinLibrary["blueItemHighlightText"]
			);
			
			bwPopupList = new popupList(
				0, 0, fluors, updateBWWavelength
			);
			
			// set up channel on/off buttons
			redButton = new button( 
				Math.round(redPopupList.x + redPopupList.width/2), -13, turnRedOnOff,
				skinLibrary["redButtonOn"],
				skinLibrary["redButtonOff"],
				skinLibrary["blankButtonRadius5Highlight"]
			);
			greenButton = new button( 
				Math.round(greenPopupList.x + greenPopupList.width/2), -13, turnGreenOnOff,
				skinLibrary["greenButtonOn"],
				skinLibrary["greenButtonOff"],
				skinLibrary["blankButtonRadius5Highlight"]
			);
			blueButton = new button(
				Math.round(bluePopupList.x + bluePopupList.width/2), -13, turnBlueOnOff,
				skinLibrary["blueButtonOn"],
				skinLibrary["blueButtonOff"],
				skinLibrary["blankButtonRadius5Highlight"]
			);
			
			// save button
			saveButton = new button(
				85, 132, saveImage,
				'<text fill="black" text-anchor="end">Save</text>',
				null,
				'<text fill="white" text-anchor="end">Save</text>'
			);

			// set up RGB to grayscale button
			RGB_BWbutton = new button(
				110, 115, switchRGB_BW,
				skinLibrary["RGB_BWButtonOn"],
				skinLibrary["RGB_BWButtonOff"],
				skinLibrary["blankButtonRadius13Highlight"]
			);
			
			// buttons to access panes
			statsButton = new button(
				190, 110, showStats,
				'<text fill="black" text-anchor="end">Stats</text>',
				null,
				'<text fill="white" text-anchor="end">Stats</text>'
			);
			scaleButton = new button(
				190, 120, showScale,
				'<text fill="black" text-anchor="end">Scale</text>',
				null,
				'<text fill="white" text-anchor="end">Scale</text>'
			);
			overlayButton = new button(
				190, 130, showOverlay,
				'<text fill="black" text-anchor="end">Overlay</text>',
				null,
				'<text fill="white" text-anchor="end">Overlay</text>'
			);
			settingsButton = new button(
				190, 140, showPreferences,
				'<text fill="black" text-anchor="end">Preferences</text>',
				null,
				'<text fill="white" text-anchor="end">Preferences</text>'
			);
				
		
			// z & t increment buttons
			tUpButton = new button(
				182, 25, tUp,
				skinLibrary["triangleRightWhite"]
			);
			tDownButton = new button(
				178, 25, tDown,
				skinLibrary["triangleLeftWhite"]
			);
			zUpButton = new button(
				15, 106, zUp,
				skinLibrary["triangleUpWhite"]
			);
			zDownButton = new button(
				15, 110, zDown,
				skinLibrary["triangleDownWhite"]
			);
				
			// z & t animation buttons
			tAnimUpButton = new button(
				182, 35, tAnimUp,
				skinLibrary["triangleRightRed"],
				null,
				skinLibrary["triangleRightWhite"]
			);
			tAnimDownButton = new button(
				178, 35, tAnimDown,
				skinLibrary["triangleLeftRed"],
				null,
				skinLibrary["triangleLeftWhite"]
			);
			zAnimUpButton = new button(
				15, 86, zAnimUp,
				skinLibrary["triangleUpRed"],
				null,
				skinLibrary["triangleUpWhite"]
			);
			zAnimDownButton = new button(
				15, 90, zAnimDown,
				skinLibrary["triangleDownRed"],
				null,
				skinLibrary["triangleDownWhite"]
			);
			
			loadButton = new button(
				5, 5, loadAllImages,
				skinLibrary["hiddenButton"],
				null,
				skinLibrary["hiddenButtonHighlight"]
			);
			
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
			tAnimUpButton.realize(controlToolBox.getGUIbox());
			tAnimDownButton.realize(controlToolBox.getGUIbox());
			zAnimUpButton.realize(controlToolBox.getGUIbox());
			zAnimDownButton.realize(controlToolBox.getGUIbox());

			loadButton.realize(controlToolBox.getGUIbox());

			// RGB & BW switcheroo
			RGB_BWbutton.realize(controlToolBox.getGUIbox());
			
			// Save button
			saveButton.realize(controlToolBox.getGUIbox());

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

			statsButton.realize( controlToolBox.getGUIbox() );
			scaleButton.realize( controlToolBox.getGUIbox() );
			overlayButton.realize( controlToolBox.getGUIbox() );
			settingsButton.realize( controlToolBox.getGUIbox() );

			// toolbox to house all other interfaces
			multiToolBox.realize(controls);

			// set up panes in the multi toolbox
// These panes to come from DB eventually?
			stats = new Statistics( Stats, fluors, updateStatsWave );
			multiToolBox.addPane( stats.buildSVG(), "Stats" );
			scale = new Scale(image, updateBlackLevel, updateWhiteLevel, scaleWaveChange);
			scale.updateScale(theT);
			multiToolBox.addPane( scale.buildSVG(), "Scale");
			overlay = new Overlay();
			multiToolBox.addPane( overlay.buildSVG(), "Overlay");
			viewerPreferences = new ViewerPreferences( resizeToolBox, resizeMultiToolBox, savePreferences );
			multiToolBox.addPane( viewerPreferences.buildSVG(), "Preferences");
			// finish setup & make controller
			multiToolBox.closeOnMinimize(true);
			
			panePopupList = new popupList(
				0, 0, multiToolBox.getPaneIndexes(), updatePane, 0,
				skinLibrary["popupListAnchorUpperLeftRoundedLightslategray"],
				skinLibrary["popupListBackgroundLightskyblue"],
				skinLibrary["popupListHighlightAquamarine"]
			);
			panePopupList.realize( multiToolBox.getMenuBar() );
			
			
			// voodoo to switch which component is rendered on top
			//  this makes the popupList be drawn on top 
			multiToolBox.nodes.GUIboxContainer.setAttribute( "onmouseover", 'multiToolBox.drawGUITop()' );
			multiToolBox.getMenuBar().setAttribute( "onmouseover", 'multiToolBox.drawMenuTop()' );


			azap.appendNode(controls);
			mouseTrap = svgDocument.getElementById("mouseTrap");
			azap.appendNode(mouseTrap); 

			// Set up display. These values come from DB eventually.
			var WBS = image.getWBS();
			setTimeout( "redPopupList.setSelectionByValue("+ 
				redPopupList.getItemList()[ WBS[0] ]
				+")", 0 );
			setTimeout( "greenPopupList.setSelectionByValue("+ 
				greenPopupList.getItemList()[ WBS[3] ]
				+")", 0 );
			setTimeout( "bluePopupList.setSelectionByValue("+ 
				bluePopupList.getItemList()[ WBS[6] ]
				+")", 0 );
			setTimeout( "bwPopupList.setSelectionByValue("+ 
				bwPopupList.getItemList()[ WBS[9] ]
				+")", 0 );
			var RGBon = image.getRGBon(); 
			setTimeout( "resizeToolBox(50 * ("+toolBoxScale+" - 1 ) )", 0);
			setTimeout( "multiToolBox.hide()", 0);
			setTimeout( "resizeMultiToolBox()", 500);
			setTimeout( "redButton.setState(" + (RGBon[0]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "greenButton.setState(" + (RGBon[1]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "blueButton.setState(" + (RGBon[2]==1 ? "true" : "false") + ")", 0 );
			setTimeout( "RGB_BWbutton.setState("+image.getDisplayRGB_BW()+")", 0 );
			setTimeout( "loadButton.setState(false)", 0 );
			zSlider.setValue(theZ/Z*100,true);
			tSlider.setValue(theT/T*100,true);
		}
		
ENDSVG

# more static stuff
$SVG .= <<'ENDSVG';
        
		
	// these functions connect GUI with backend
		function savePreferences() {
			var tmpImg;
			tmpImg = svgDocument.createElementNS(svgns,"image");
			tmpImg.setAttribute("width",0);
			tmpImg.setAttribute("height",0);
			// The purpose of unique is to bypass any image caching
			var unique   = Math.random();
			var imageURL = SaveDisplayCGI_URL + 
				'&toolBoxScale=' + controlToolBox.getScale() +
				"&Unique=" + unique;
			tmpImg.setAttributeNS(xlinkns, "xlink:href",imageURL);
		
			controlToolBox.getGUIbox().appendChild(tmpImg);
			controlToolBox.getGUIbox().removeChild(tmpImg);
		}
	
		function resizeToolBox(data) {
			viewerPreferences.toolBoxSizeSlider.setValue(data);
			controlToolBox.setScale(1 + data/50);	// resizes the controlToolBox
		}
		function resizeMultiToolBox() {
			multiToolBox.setScale( controlToolBox.getScale() );	// resizes the multiToolBox
		}

		
		function saveImage() {
			image.saveState();
		}
	
		function loadAllImages(val) {
			image.setPreload(val);
		}
	
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
		function zAnimUp() {
			if(Z > 1) {
				for(i=theZ;i<Z;i++)
					setTimeout("updateTheZ(" + (i/(Z-1)) + "*100)", (i-theZ)*100);
			}
		}
		function zAnimDown() {
			if(Z > 1) {
				for(i=theZ;i>=0;i--)
					setTimeout("updateTheZ(" + (i/(Z-1)) + "*100)", (theZ-i)*100);
			}
		}

		function updateTheT(data) {
			if(data<0) data=0;
			theT=Math.round(data/100*(T-1));
			var sliderVal = ( T==1 ? 0 : Math.round(theT/(T-1)*100) );
			tSlider.setValue(sliderVal);
			tSlider.setLabel(null, null, "time (" + theT + "/" + (T-1) +")" );
			
			image.updatePic(theZ,theT);
			scale.updateScale(theT);
			stats.updateStats(theT);
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
		function tAnimUp() {
			if(T>1) {
				for(i=theT;i<T;i++)
					setTimeout("updateTheT(" + (i/(T-1)) + "*100)", (i-theT)*100);
			}
		}
		function tAnimDown() {
			if(T>1) {
				for(i=theT;i>=0;i--)
					setTimeout("updateTheT(" + (i/(T-1)) + "*100)", (theT-i)*100);
			}
		}

		// popupLists controlling channels
		function updateRedWavelength(item) {
			scale.updateWBS('R', item);
		}
		function updateGreenWavelength(item) {
			scale.updateWBS('G', item);
		}
		function updateBlueWavelength(item) {
			scale.updateWBS('B', item);
		}
		function updateBWWavelength(item) {
			scale.updateWBS('Gray', item);
		}

		function updatePane(item) {
			var itemList = panePopupList.getItemList();
			multiToolBox.changePane( itemList[item] );
		}
		
		// buttons controlling channels
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
		
		function showOverlay() {
			panePopupList.setSelectionByValue("Overlay");
		}
		function showPreferences() {
			panePopupList.setSelectionByValue("Preferences");
		}

		// Stats stuff
		function showStats() {
			panePopupList.setSelectionByValue("Stats");
		}
		function updateStatsWave(wavenum) {
			stats.updateStats(theT);
		}

		// Scale stuff
		function updateBlackLevel(val) {
			// has scale been initialized?
			if(scale.image == null ) return;
			if(Math.round(val) == scale.blackBar.getAttribute("width")) return;

			// set up constants
			var wavenum = scale.wavePopupList.getSelection();
			var min = scale.Stats[wavenum][theT]['min'];
			var max = scale.Stats[wavenum][theT]['max'];
			var range = max-min;
			var geomean = scale.Stats[wavenum][theT]['geomean'];
			var sigma = scale.Stats[wavenum][theT]['sigma'];
			
			// correct val, crunch numbers
			if(val >= scale.whiteSlider.getValue())
				val = scale.whiteSlider.getValue() - 0.00001;
			var cBlackLevel = Math.round(val/scale.scaleWidth * range + min);
			val = (cBlackLevel-min)/range * scale.scaleWidth;

			// update backend
			var nBlackLevel = (cBlackLevel - geomean)/sigma;
			nBlackLevel = Math.round(nBlackLevel * 10) / 10;
			scale.BS[wavenum]['B'] = nBlackLevel;
			scale.updateWBS();

			// update display
			scale.blackSlider.setValue(val);
			scale.blackLabel.firstChild.data = "geomean + SD * " + nBlackLevel;
			scale.blackBar.setAttribute("width", Math.round(val) );
		}
		function updateWhiteLevel(val) {
			// has scale been initialized?
			if(scale.image == null ) return;
			if(Math.round(val) == scale.whiteBar.getAttribute("x")) return;

			// set up constants
			var wavenum = scale.wavePopupList.getSelection();
			var min = scale.Stats[wavenum][theT]['min'];
			var max = scale.Stats[wavenum][theT]['max'];
			var range = max-min;
			var geomean = scale.Stats[wavenum][theT]['geomean'];
			var sigma = scale.Stats[wavenum][theT]['sigma'];
			
			// correct val, crunch numbers
			if(val <= scale.blackSlider.getValue())
				val = scale.blackSlider.getValue() + 0.00001;
			var cWhiteLevel = Math.round(val/scale.scaleWidth * range + min);
			if(cWhiteLevel == geomean)
				cWhiteLevel -= 0.00001;
			val = (cWhiteLevel-min)/range * scale.scaleWidth;

			// update backend
			var nScale = (cWhiteLevel - geomean)/sigma;
			nScale = Math.round(nScale*10)/10;
			scale.BS[wavenum]['S'] = nScale;
			scale.updateWBS();

			// update display
			scale.whiteSlider.setValue(val);
			scale.whiteLabel.firstChild.data = "geomean + SD * " + nScale;
			scale.whiteBar.setAttribute("width", scale.scaleWidth - Math.round(val) );
			scale.whiteBar.setAttribute("x", Math.round(val) );
		}
		function scaleWaveChange(val) {
			scale.updateScale(theT);
		}
		function showScale() {
			panePopupList.setSelectionByValue("Scale");
		}
		
    ]]></script>
	<g id="mouseTrap">
		<!-- The mouse only registers over elements. This rect prevents
			 loosing the mouse while moving the toolbox. It is drawn first
			 so it will be placed
			 on bottom so it will not trap mouse events unless nothing
			 else does. -->
		<rect width="100%" height="100%" fill="blue" opacity="0"/>	
	</g>
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

=pod

=head2 SVGgetDataJS()

=over 4

=item Description

Gathers data for BuildSVGviewer() & formats it for use in JavaScript.

=item Returns

A hash of data, JavaScript formatted.

=item Uses functions

=over 4

=item L<OME::Web/"CGI()">

=item CGI->url_param()

=item L<OME::Web/"Factory()">

=item L<OME::Factory/"loadObject()">	(via OME::Session, OME::Factory)

=item L<OME::Image/"Dimensions()">

=item L<OME::Image/"wavelengths">

=item L<OME::Image/"XYZ_info">

=back

=back

=cut

sub SVGgetDataJS {
	my $self    = shift;
	my $cgi     = $self->CGI();
	my $JSinfo  = {};
	my $session = $self->Session();
	my $factory = $session->Factory();

    my $ImageID = $cgi->url_param('ImageID') || die "ImageID not supplied to GetGraphics.pm";

	$JSinfo->{ ImagedID } = $ImageID;

	my $image = $self->Session()->Factory()->loadObject("OME::Image",$ImageID);
	die "Could not retreive Image from ImageID=$ImageID\n"
		unless defined $image;

	# get Dimensions from image and make them readable
	my $d = $image->Dimensions()
		or die "Could not retrieve image->Dimensions";
	my $dims = [ $d->size_x(),
	             $d->size_y(),
	             $d->size_z(),
	             $d->num_waves(),
	             $d->num_times(),
	             $d->bits_per_pixel()/8
	            ];
	
	# get wavelengths from image and make them JavaScript readable
	my @w = $image->wavelengths
		or die "Could not retrieve image->wavelengths";
	my @wavelengths;
	
# get this from DB eventually
	my $FluorWavelength = {
		FITC   => 528,
		TR     => 617,
		GFP    => 528,
		DAPI   => 457
	};
	foreach (@w) {
		push @wavelengths, [$_->wavenumber(), $_->em_wavelength(), $_->fluor()];
	}
	# construct em_wavelength from fluor if possible, otherwise make sure it's filled in w/ something
	foreach (@wavelengths) {
		$_->[1] = $FluorWavelength->{$_->[2]} unless defined $_->[1] and $_->[1];
		$_->[1] = $_->[0]+1 unless defined $_->[1] and $_->[1];
	}
	my $wav = [sort {$b->[1] <=> $a->[1]} @wavelengths];
	my @JSwavelengths;
	foreach (@$wav) {
		push @JSwavelengths, '{WaveNum:'.$_->[0].',Label:"'.(exists $_->[2] and defined $_->[2] ? $_->[2] : $_->[1]).'"}';
	}

	# get stats from image & make them JavaScript readable
	my @s = $image->XYZ_info;
	die ref ($self) . "->SVGgetDataJS: No stack statistics found for image! (id=".$image->id().")"
		if( scalar(@s) == 0 );
	my ($stats, @JS_Stats_Waves, $JSstats);
	foreach (@s) {
		$stats->[$_->theW()][$_->theT()] = 
			"{ min:".$_->min().", max:".$_->max().", mean:".$_->mean().", geomean:".$_->geomean().",sigma:".$_->sigma()."}";
	}
	for (my $i=0;$i<scalar (@$stats);$i++) {
		push (@JS_Stats_Waves,'['.join (',',@{$stats->[$i]}).']');
	}
	$JSstats = '['.join (',',@JS_Stats_Waves).']';
	
	# get display settings
	my $displaySettings   = $factory->findObject( 'OME::DisplaySettings', image_id => $image->id() );
	my $viewerPreferences = $factory->findObject( 'OME::ViewerPreferences', experimenter_id => $session->User()->id() );
	
	$JSinfo->{ ImageID }            = $ImageID;
	$JSinfo->{ Stats }              = $JSstats;
	$JSinfo->{ Wavelengths }        = '['.join(',',@JSwavelengths).']';
	$JSinfo->{ pDims }              = $dims;
	$JSinfo->{ Dims }               = '['.join (',', @$dims).']';
	$JSinfo->{ CGI_URL }            = '/cgi-bin/OME_JPEG';
	$JSinfo->{ CGI_optionStr }      = '&Path='.$image->getFullPath();
	$JSinfo->{ SaveDisplayCGI_URL } = '/perl2/serve.pl?Page=OME::Web::SaveViewerSettings';
	$JSinfo->{ theZ }               = $cgi->url_param('theZ') || ( defined $dims ? sprintf "%d",$dims->[2] / 2 : 0 );
	$JSinfo->{ theT }               = $cgi->url_param('theT') || 0;
	$JSinfo->{ isRGB }              = 'null';
	$JSinfo->{ WBS }                = 'null';
	$JSinfo->{ RGBon }              = 'null';
	$JSinfo->{ toolBoxScale }       = 1;
	if( defined $displaySettings ) {
		$JSinfo->{ theZ }      = $displaySettings->theZ()
			if( not defined $cgi->url_param('theZ') );
		$JSinfo->{ theT }      = $displaySettings->theT()
			if( not defined $cgi->url_param('theT') );
		$JSinfo->{ isRGB }     = $displaySettings->isRGB();
		$JSinfo->{ WBS }       = '[' . join(',', @{ $displaySettings->WBS() }) . ']';
		$JSinfo->{ RGBon }     = '[' . join(',', @{ $displaySettings->RGBon() } ) . ']';
	}
	if( defined $viewerPreferences ) {
		$JSinfo->{ toolBoxScale } = $viewerPreferences->toolbox_scale();
	}

	return $JSinfo;
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

=item L<OME::Image/"Dimensions()">

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
    $image = $self->Session()->Factory()->loadObject("OME::Image",$ImageID);
    die "Could not retreive Image from ImageID=$ImageID\n"
    	unless defined $image;
    print STDERR ref($self)."->getJSgraphics:  ImageID=".$image->image_id()." Name=".$image->name." Path=".$image->getFullPath()."\n";
    my $dimensions = $image->Dimensions();
	my ($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp);
	($sizeX,$sizeY,$sizeZ,$numW,$numT,$bpp) = ($dimensions->size_x(),$dimensions->size_y(),$dimensions->size_z(),
        $dimensions->num_waves(),$dimensions->num_times(),
        $dimensions->bits_per_pixel());

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
