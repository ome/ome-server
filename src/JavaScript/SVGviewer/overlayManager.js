/*****

	overlayManager.js
		external file dependencies: widget.js, button.js, popupList.js
		
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

	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
OverlayManager.VERSION = 0.1;

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		sketchSpace = container in which to draw overlays
		turnLayerOnOff = function to issue callbacks to when the On/Off button is clicked
		switchOverlay = function to issue callbacks to when another overlay is selected
		
	tested

*****/
function OverlayManager(sketchSpace, turnLayerOnOff, switchOverlay, showAllZs, showAllTs) {
	this.init(sketchSpace, turnLayerOnOff, switchOverlay, showAllZs, showAllTs);
}

/*****
	
	makeControls
	
	returns:
		The controls for this class, loaded into DOM with a <g> as the root.
		
	tested
		
*****/
OverlayManager.prototype.makeControls = function() {
	// check for initialization
	if(this.layerNames == null) return null;

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	var currentLayer = this.layerNames[0];

	// set up GUI
	this.layerPopupList = new popupList(
		40, 10, this.layerNames, this.switchOverlay, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.layerPopupList.setLabel(-2, 12, "Layer:");
	this.layerPopupList.getLabel().setAttribute("text-anchor", "end");

	this.displayButton = new button(
		160, 10, this.turnLayerOnOff,
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
		100, 0, this.showAllZs
	);
	this.allZButton.setLabel(-9, 9,"Show all Z");
	this.allZButton.getLabel().setAttribute("text-anchor", "end");
	this.allTButton = new button(
		100, 20, this.showAllTs
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

OverlayManager.prototype._showAllZs = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.overlayByName[name].showAllZs( value );
}

OverlayManager.prototype._showAllTs = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.overlayByName[name].showAllTs( value );
}

OverlayManager.prototype._switchOverlay = function( item ) {
	items = this.layerPopupList.getItemList();
	name = items[item];

	this.displayButton.setState( this.onByName[name] );
	this.allZButton.setState( this.overlayByName[name].allZ );
	this.allTButton.setState( this.overlayByName[name].allT );
}

// This function turns the layer on or off
OverlayManager.prototype._turnLayerOnOff = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.onByName[name] = value;
	this.overlayByName[name].turnOnOff(value);
}

// This is supposed to add a layer. the contents of the layer are an array of svg in string format.
OverlayManager.prototype.addLayer = function( name, overlay ) {
	this.layerNames.push( name );
	this.overlayByName[name] = overlay;
	this.onByName[name] = false;
}


OverlayManager.prototype.updateIndex = function( theZ, theT ) {
	for( overlay in this.overlayByName ) {
		this.overlayByName[overlay].updateIndex( theZ, theT );
	}
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

OverlayManager.prototype.init = function( sketchSpace, turnLayerOnOff, switchOverlay, showAllZs, showAllTs ) {

	this.sketchSpace = sketchSpace;
	this.turnLayerOnOff = turnLayerOnOff;
	this.switchOverlay = switchOverlay;
	this.showAllZs = showAllZs;
	this.showAllTs = showAllTs;

	this.updateLayer = null;
	this.changeColor = null;
	this.displayLayer = null;
	
	this.layerNames = new Array();
	this.onByName = new Array();
	this.overlayByName = new Array();
	
}
