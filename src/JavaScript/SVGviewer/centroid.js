/*****

	centroid.js
	
	Copyright (C) 2002 Open Microscopy Environment
	Author: Josiah Johnston <siah@nih.gov>
	
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


		JavaScript classes (Centroid & CentroidOverlay) for managing and
	displaying Centroids. 
		
		External File dependencies: overlayManager.js, widget.js
		
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****
*
*   inheritance
*
*****/

Centroid.prototype = new Widget();
Centroid.prototype.constructor = Centroid;
Centroid.superclass = Widget.prototype;

Centroid.VERSION = 1;

Centroid.prototype.circleText = 
'<circle r="5" stroke="blue" fill="none" cx="0" cy="0"/>';
Centroid.prototype.focusText =
'<g>'+
'<line x1="-5" y1="-5" x2="5" y2="5" stroke="green"/>'+
'<line x1="-5" y1="5" x2="5" y2="-5" stroke="green"/>'+
'</g>';
Centroid.prototype.mouseCatcherText = 
'<rect x="-5" y="-5" width="10" height="10" opacity="0"/>';
Centroid.prototype.pathData =
'M0,0 l10,-10';
Centroid.prototype.textPadding = 2;

Centroid.prototype.animateTime = '0.2s';

function Centroid ( data ) {//theX, theY, theZ, theT ) {
	this.init( data ); //theX, theY, theZ, theT );
}

Centroid.prototype.init = function( data ) { //theX, theY, theZ, theT ) {
	this.theX = data['theX'];
	this.theY = data['theY'];

	Centroid.superclass.init.call(this, this.theX, this.theY);

	this.theZ = data['theZ'];
	this.theT = data['theT'];	
	this.data = data;
	
	this.ignoreMouseOver = false;
	
/*
	this.coordinate = new Array();
	this.coordinate.push( this.theX +1);
	this.coordinate.push( this.theY +1);
	this.coordinate.push( parseInt(this.theZ) +1);
	this.coordinate.push( parseInt(this.theT) +1);
*/
	
}


Centroid.prototype.makePath = function( pathData ) {
	path = svgDocument.createElementNS( svgns, "path" );
	path.setAttribute( "d", pathData );
	path.setAttribute( "stroke", "green" );
	return path;
}

Centroid.prototype.makeTextBox = function( ) {
	textBox = svgDocument.createElementNS( svgns, "g" );
	text = svgDocument.createElementNS( svgns, "text" );
	data = svgDocument.createTextNode( '(' + 'foo' + ')');
//	data = svgDocument.createTextNode( '(' + this.coordinate.join( ', ' ) + ')');
	text.appendChild( data );
	text.setAttribute( "fill", "black" );
	text.setAttribute( "y", text.getBBox().height  );
	text.setAttribute( "x", this.textPadding );
	
	textRect = svgDocument.createElementNS( svgns, "rect" );
	textRect.setAttribute( "width", text.getBBox().width + this.textPadding * 2 );
	textRect.setAttribute( "height", text.getBBox().height + this.textPadding * 2 );
	textRect.setAttribute( "fill", "white" );
	textRect.setAttribute( "opacity", "0.5" );
	
	textBox.appendChild( textRect );
	textBox.appendChild( text );
	
	return textBox;	
}

Centroid.prototype.buildSVG = function() {
	centroidSVG = svgDocument.createElementNS(svgns, "g");
	centroidSVG = svgDocument.createElementNS( svgns, "g" );
	translation = 'translate(' + this.theX + ',' + this.theY + ')';
	centroidSVG.setAttribute( "transform", translation );
	centroidSVG.appendChild( parseXML( this.circleText, svgDocument ) );
	this.glyph = centroidSVG.lastChild;

	centroidSVG.appendChild( parseXML( this.focusText, svgDocument ) );
	this.focusGraphic = centroidSVG.lastChild;
	this.focusGraphic.setAttribute( "display", "none" );

	// mouseCatcher goes on top!
	centroidSVG.appendChild( parseXML( this.mouseCatcherText, svgDocument ) );
	this.mouseCatcher = centroidSVG.lastChild;
	this.mouseCatcher.addEventListener( "mouseover", this, false );
	this.mouseCatcher.addEventListener( "mouseout", this, false );
	this.mouseCatcher.addEventListener( "click", this, false );
	
	return centroidSVG;
}

Centroid.prototype.mouseover = function(e) {
	if( this.ignoreMouseOver == false )
		this.focus(e);
}

Centroid.prototype.mouseout = function(e) {
	if( this.ignoreMouseOver == false )
		this.unfocus(e);
}

Centroid.prototype.focus = function(e) {
	featureInfo.loadFeature( this.data['featureID'] );
	this.focusGraphic.setAttribute( "display", "inline" );
}

Centroid.prototype.unfocus = function(e) {
	this.focusGraphic.setAttribute( "display", "none" );
}

Centroid.prototype.click = function(e) {
	setTheZ( this.theZ );
	setTheT( this.theT );
}


/*****
*
*   inheritance
*
*****/

CentroidOverlay.prototype = new Overlay();
CentroidOverlay.prototype.constructor = CentroidOverlay;
CentroidOverlay.superclass = Overlay.prototype;

/*****

	class variables
	
*****/
CentroidOverlay.VERSION = 1;

CentroidOverlay.prototype.circleText = 
'<circle r="5" stroke="blue" fill="none" cx="0" cy="0"/>';

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
				
	tested

*****/
function CentroidOverlay( centroidData ) {
	this.init( centroidData );
}

/*****
	
	makeControls
	
	returns:
		The controls for this class, loaded into DOM with a <g> as the root.
		
	tested
		
*****/
CentroidOverlay.prototype.makeControls = function() {
	// check for initialization
	if(this.colors == null) return null;

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	var currentLayer = this.layerNames[0];

	// set up GUI
	this.layerPopupList = new popupList(
		40, 10, this.layerNames, this.switchCentroid, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.layerPopupList.setLabel(-2, 12, "Layer:");
	this.layerPopupList.getLabel().setAttribute("text-anchor", "end");
/*
	this.colorPopupList = new popupList(
		90, 35, this.colors, this.changeColor, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.colorPopupList.setLabel(-2, 12, "Color:");
	this.colorPopupList.getLabel().setAttribute("text-anchor", "end");
*/
	this.displayButton = new button(
		30, 35, this.turnLayerOnOff,
		'<g>' +
		'	<rect x="-12" y="-1" width="24" height="18" fill="lightslategray"/>' +
		'	<text y="12" text-anchor="middle">On</text>'+
		'</g>',
		'<g>' +
		'	<rect x="-12" y="-1" width="24" height="18" fill="lightslategray"/>' +
		'	<text y="12" text-anchor="middle">Off</text>'+
		'</g>'
	);
	
	this.dynamicControls = svgDocument.createElementNS( svgns, "g" );
	this.dynamicControls.setAttribute("transform", "translate(20,70)");
	this.dynamicControls.padding = 5;
	
	this.allZButton = new button(
		100, 0, this.allZ
	);
	this.allZButton.setLabel(-9, 9,"Show all Z");
	this.allZButton.getLabel().setAttribute("text-anchor", "end");
	this.allTButton = new button(
		100, 20, this.allT
	);
	this.allTButton.setLabel(-9, 9,"Show all T");
	this.allTButton.getLabel().setAttribute("text-anchor", "end");


	// place GUI elements in containers
	this.root.appendChild( this.dynamicControls );

	this.allZButton.realize( this.dynamicControls );
	this.allTButton.realize( this.dynamicControls );
	
	// draw some background
	this.dynamicControls.appendChild( parseXML(
		'<rect x="30" y="-5" width="80" height="39" fill="none" stroke="black" stroke-width="2" opacity="0.7"/>',
		svgDocument
	));

//	this.colorPopupList.realize( this.root );
	this.displayButton.realize( this.root );
	this.layerPopupList.realize( this.root );
	
	// build background
	
	return this.root;
}

/*****
	
	makeOverlay
	
	returns:
		The centroid overlay for this instance, loaded into DOM with a <g> as the root.
		The data it uses was acquired during initialization.
		
	tested
		
*****/
CentroidOverlay.prototype.makeOverlay = function( ) {
	
	for( i in this.centroidData ) {
		layerSlice = svgDocument.createElementNS( svgns, "g" );
		theZ = this.centroidData[i]['theZ'];
		theT = this.centroidData[i]['theT'];
		centroid = new Centroid( this.centroidData[i] );
		layerSlice.appendChild( centroid.buildSVG() );
		this.addLayerSlice( theZ, theT, layerSlice );
	}
	
	return this.overlayRoot;

}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init
		
	tested

*****/
CentroidOverlay.prototype.init = function( centroidData ) {

	// call superclass initialization
	CentroidOverlay.superclass.init.call(this);

	this.centroidData = centroidData;

}
