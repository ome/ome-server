/*****

	ViewerPreferences.js

Copyright (C) 2003 Open Microscopy Environment
		Massachusetts Institute of Technology,
		National Institutes of Health,
		University of Dundee

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
ViewerPreferences.VERSION = .2;
ViewerPreferences.ScaleSliderWidth = 50;

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		image = OMEimage
		
		make instance in viewer to be scale
		
	tested

*****/
function ViewerPreferences( resizeToolBox, resizeMultiToolBox, savePreferences ) {
	this.init( resizeToolBox, resizeMultiToolBox, savePreferences );
}

ViewerPreferences.prototype.buildToolBox = function( controlLayer ) {
	var displayContent = this.buildDisplay();
	var bbox = displayContent.getBBox();
	var width = bbox.width + 2 * toolBox.prototype.padding+ 20;
// hack alert!! '+ 20'
	var height = bbox.height + 2 * toolBox.prototype.padding+ 20;
	this.toolBox = new toolBox(
		255, 250, width, height
	);
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(10,12,"Viewer Preferences");
	this.toolBox.getLabel().setAttribute( "text-anchor", "start");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( displayContent );
	
}

 ViewerPreferences.prototype.buildDisplay = function() {
	// check for initialization
	if(! this.initialized) return null;

// build SVG
	this.displayContent = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.toolBoxSizeSlider = new Slider(
		110,0,ViewerPreferences.ScaleSliderWidth,0,
		{ obj: this, method: 'resizeToolboxes' }
	);
	this.toolBoxSizeSlider.setLabel(-95,3,"Resize toolbox:");
	this.applyChangesToSelfButton = new button(
		0, 25, 
		{ obj: this, method: 'resizeSelf' },
		'<g transform="translate(90,0)">'+
		'	<rect x="-90" width="180" height="18" fill="lightslategray"/>'+
		'	<text y="2" dominant-baseline="hanging" text-anchor="middle">Apply changes to this toolbox</text>'+
		'	<rect x="-90" width="180" height="18" opacity="0"/>'+
		'</g>',
		null,
		'<g transform="translate(90,0)">'+
		'	<rect x="-90" width="180" height="18" fill="aquamarine"/>'+
		'	<text y="2" dominant-baseline="hanging" text-anchor="middle">Apply changes to this toolbox</text>'+
		'	<rect x="-90" width="180" height="18" opacity="0"/>'+
		'</g>'
	);
	this.saveChangesButton = new button(
		40, 55, 
		{ obj: this, method: 'savePreferences' },
		'<g transform="translate(50,0)">'+
		'	<rect x="-50" width="100" height="18" fill="lightslategray"/>'+
		'	<text y="2" dominant-baseline="hanging" text-anchor="middle">Save changes</text>'+
		'	<rect x="-50" width="100" height="18" opacity="0"/>'+
		'</g>',
		null,
		'<g transform="translate(50,0)">'+
		'	<rect x="-50" width="100" height="18" fill="aquamarine"/>'+
		'	<text y="2" dominant-baseline="hanging" text-anchor="middle">Save changes</text>'+
		'	<rect x="-50" width="100" height="18" opacity="0"/>'+
		'</g>'
	);

	this.toolBoxSizeSlider.realize( this.displayContent );
	this.applyChangesToSelfButton.realize( this.displayContent );
	this.saveChangesButton.realize( this.displayContent );
	
	var translate = 'translate( '+ toolBox.prototype.padding + ', ' + toolBox.prototype.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );

	return this.displayContent;
};

ViewerPreferences.prototype.setWindowControllers = function(windowControllers) {
	this.windowControllers   = windowControllers;
};

/********************************************************************************************
                            Private Functions
********************************************************************************************/

ViewerPreferences.prototype.init = function(imageControlToolbox) {
	this.initialized         = true;
	this.imageControlToolbox = imageControlToolbox;
};

ViewerPreferences.prototype.resizeToolboxes = function( scale, applyToAll ) {
	this.toolBoxSizeSlider.setValue(scale);
	this.imageControlToolbox.setScale(1 + scale/ViewerPreferences.ScaleSliderWidth );
	for( i in this.windowControllers ) {
		if( applyToAll || this.windowControllers[i].toolBox != this.toolBox ) {
			this.windowControllers[i].toolBox.setScale(1 + scale/ViewerPreferences.ScaleSliderWidth );
		}
	}
};


ViewerPreferences.prototype.resizeSelf = function() {
	scale = 1 + this.toolBoxSizeSlider.getValue()/ViewerPreferences.ScaleSliderWidth;
	this.toolBox.setScale(scale);
};


ViewerPreferences.prototype.savePreferences = function(  ) {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	// The purpose of unique is to bypass any image caching
	var unique  = Math.random();
	var imageURL = SaveDisplayCGI_URL + 
		'&toolBoxScale=' + controlToolBox.getScale() +
		"&Unique=" + unique;
	tmpImg.setAttributeNS(xlinkns, "xlink:href",imageURL);

	this.controlsRoot.appendChild(tmpImg);
	this.controlsRoot.removeChild(tmpImg);
};
