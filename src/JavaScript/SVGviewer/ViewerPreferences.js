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
ViewerPreferences.toolboxApperance = {
	x: 190,
	y: 190,
	width: 165,
	height: 55
};

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****
	ViewerPreferences
		constructor
*****/
function ViewerPreferences( SavePrefsCGI_URL, image ) {
	this.init( SavePrefsCGI_URL, image );
}

ViewerPreferences.prototype.buildToolBox = function( controlLayer ) {
	var displayContent = this.buildDisplay();
	this.toolBox = new toolBox( ViewerPreferences.toolboxApperance );
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(10,12,"Resize toolboxes");
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
		90,0,ViewerPreferences.ScaleSliderWidth,0,
		{ obj: this, method: 'applyScale' }
	);
	this.toolBoxSizeSlider.setLabel(-95,3,"Resize toolbox:");
	this.toolBoxSizeSlider.realize( this.displayContent );
	this.toolBoxSizeSlider.setMinmax(1,2,false);

	this.saveChangesButton = new button(
		30, 20, 
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

ViewerPreferences.prototype.init = function(SavePrefsCGI_URL, image) {
	this.initialized      = true;
	this.SavePrefsCGI_URL = SavePrefsCGI_URL;
	this.image            = image;
};

ViewerPreferences.prototype.applyScale = function( scale, applyToAll ) {
	this.scale = scale;
	this.toolBoxSizeSlider.setValue(scale);
	for( i in this.windowControllers ) {
		if( applyToAll || this.windowControllers[i].toolBox != this.toolBox ) {
			this.windowControllers[i].toolBox.setScale( this.scale );
		}
	}
	this.image.moveImageLayer( 0, this.windowControllers['xyPlaneControls'].toolBox.getActualHeight() );
};


ViewerPreferences.prototype.resizeSelf = function() {
	var scale = 1 + this.toolBoxSizeSlider.getValue()/ViewerPreferences.ScaleSliderWidth;
	this.toolBox.setScale(this.scale);
};


ViewerPreferences.prototype.savePreferences = function(  ) {
	this.resizeSelf();
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	// The purpose of unique is to bypass any image caching
	var d = new Date();
	var unique  = d.getDate() + d.getMonth() + d.getYear() + d.getHours() + d.getMinutes() + d.getSeconds();
	var imageURL = this.SavePrefsCGI_URL + 
		'&toolBoxScale=' + this.scale +
		"&Unique=" + unique;
	tmpImg.setAttributeNS(xlinkns, "xlink:href",imageURL);

	this.displayContent.appendChild(tmpImg);
	this.displayContent.removeChild(tmpImg);
};
