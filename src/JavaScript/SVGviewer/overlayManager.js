/*****

	overlayManager.js
		
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

	
	Written by: Josiah Johnston <siah@nih.gov>
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
OverlayManager.VERSION = 0.2;

/********************************************************************************************
                                       Public Functions 
********************************************************************************************/

/*****

	constructor
		sketchSpace = container in which to draw overlays

*****/
function OverlayManager(sketchSpace) {
	this.init(sketchSpace);
}

OverlayManager.prototype.buildToolBox = function( controlLayer ) {
	var displayContent = this.buildDisplay();
	var bbox = displayContent.getBBox();
	var width = bbox.width + 2 * toolBox.prototype.padding;
	var height = bbox.height + 2 * toolBox.prototype.padding;
	this.toolBox = new toolBox(
		255, 250, width, height
	);
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(10,12,"Overlay Manager");
	this.toolBox.getLabel().setAttribute( "text-anchor", "start");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( displayContent );
	
}


OverlayManager.prototype.buildDisplay = function() {
	if(!this.initialized) return null;

	this.displayContent = svgDocument.createElementNS(svgns, "g");

	var currentLayer = this.layerNames[0];

	// set up GUI
	this.layerPopupList = new popupList(
		40, 10, this.layerNames, 
		{ obj: this, method: 'switchOverlay' },
		null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.layerPopupList.setLabel(-2, 12, "Layer:");
	this.layerPopupList.getLabel().setAttribute("text-anchor", "end");

	this.displayButton = new button(
		160, 10, 
		{ obj: this, method: 'turnLayerOnOff' },
		'<g>' +
		'	<rect x="-12" y="-1" width="24" height="18" fill="lightslategray"/>' +
		'	<text y="12" text-anchor="middle">Off</text>'+
		'</g>',
		'<g>' +
		'	<rect x="-12" y="-1" width="24" height="18" fill="lightslategray"/>' +
		'	<text y="12" text-anchor="middle">On</text>'+
		'</g>'
	);
	
	this.dynamicControls = svgDocument.createElementNS( svgns, "g" );
	this.dynamicControls.setAttribute("transform", "translate(20,70)");
	this.dynamicControls.padding = 5;
	
	this.allZButton = new button(
		100, 0,
		{ obj: this, method: 'showAllZs' }
	);
	this.allZButton.setLabel(-9, 9,"Show all Z");
	this.allZButton.getLabel().setAttribute("text-anchor", "end");
	this.allTButton = new button(
		100, 20,
		{ obj: this, method: 'showAllTs' }
	);
	this.allTButton.setLabel(-9, 9,"Show all T");
	this.allTButton.getLabel().setAttribute("text-anchor", "end");


	// place GUI elements in containers
	this.displayContent.appendChild( this.dynamicControls );

	this.allZButton.realize( this.dynamicControls );
	this.allTButton.realize( this.dynamicControls );
	
	// draw some background
	this.dynamicControls.appendChild( parseXML(
		'<rect x="30" y="-5" width="80" height="39" fill="none" stroke="black" stroke-width="2" opacity="0.7"/>',
		svgDocument
	));

//	this.colorPopupList.realize( this.displayContent );
	this.displayButton.realize( this.displayContent );
	this.layerPopupList.realize( this.displayContent );
	
	// build background
	
	return this.displayContent;
}

OverlayManager.prototype.showAllZs = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.overlayByName[name].showAllZs( value );
}

OverlayManager.prototype.showAllTs = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.overlayByName[name].showAllTs( value );
}

OverlayManager.prototype.switchOverlay = function( item ) {
	items = this.layerPopupList.getItemList();
	name = items[item];

	this.displayButton.setState( this.onByName[name] );
	this.allZButton.setState( this.overlayByName[name].allZ );
	this.allTButton.setState( this.overlayByName[name].allT );
}

// This function turns the layer on or off
OverlayManager.prototype.turnLayerOnOff = function( value ) {
	name = this.layerPopupList.getSelectionName();
	this.onByName[name] = value;
	this.overlayByName[name].turnOnOff(value);
	this.displayButton.setState( value, 1 );
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

/********************************************************************************************
                                       Private Functions 
********************************************************************************************/

OverlayManager.prototype.init = function( sketchSpace ) {
	this.initialized = true;
	this.sketchSpace = sketchSpace;

	this.updateLayer = null;
	this.changeColor = null;
	this.displayLayer = null;
	
	this.layerNames = new Array();
	this.onByName = new Array();
	this.overlayByName = new Array();
	
};
