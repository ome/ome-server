/*****
*
*	imageControls.js

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

svgns = "http://www.w3.org/2000/svg";

/*****

	ImageControls(...)

*****/


function ImageControls(  ) {

	this.init(  );
}

ImageControls.prototype.init = function(  ) {


}


/*****

buildControls( ... )

parameters:
	actions - associative array (AKA hash) of functions or 'method name'/object pairs
		to tie controls into
	supplimentaryControls - control window names to give access to in a pop-up list
	channelLabels - labels of the channels in the image

*****/
ImageControls.prototype.buildControls = function( actions, supplimentaryControls, channelLabels ) {

	this.controlsRoot = svgDocument.createElementNS( svgns, "g" );

	// Z section controls
	this.zSlider = new Slider(
		30, 120, 100, -90,
		actions['zSlider'],
		skinLibrary["zSliderBody"],
		skinLibrary["zSliderThumb"]
	);
	this.zSlider.setLabel(0,-102,"");
	this.zSlider.getLabel().setAttribute( "fill", "white" );
	this.zSlider.getLabel().setAttribute( "text-anchor", "middle" );
	this.zUpButton = new button(
		15, 106, 
		actions['zUp'],
		skinLibrary["triangleUpWhite"]
	);
	this.zDownButton = new button(
		15, 110,
		actions['zDown'],
		skinLibrary["triangleDownWhite"]
	);
	this.zAnimUpButton = new button(
		15, 86, 
		actions['zAnimUp'],
		skinLibrary["triangleUpRed"],
		null,
		skinLibrary["triangleUpWhite"]
	);
	this.zAnimDownButton = new button(
		15, 90, 
		actions['zAnimDown'],
		skinLibrary["triangleDownRed"],
		null,
		skinLibrary["triangleDownWhite"]
	);

	// Timepoint controls
	this.tSlider = new Slider(
		60, 30, 100, 0,
		actions['tSlider']
	);
	this.tSlider.setLabel(60,-13,"");
	this.tSlider.getLabel().setAttribute( "fill", "white" );
	this.tUpButton = new button(
		182, 25,
		actions['tUp'],
		skinLibrary["triangleRightWhite"]
	);
	this.tDownButton = new button(
		178, 25,
		actions['tDown'],
		skinLibrary["triangleLeftWhite"]
	);
	this.tAnimUpButton = new button(
		182, 35, 
		actions['tAnimUp'],
		skinLibrary["triangleRightRed"],
		null,
		skinLibrary["triangleRightWhite"]
	);
	this.tAnimDownButton = new button(
		178, 35, 
		actions['tAnimDown'],
		skinLibrary["triangleLeftRed"],
		null,
		skinLibrary["triangleLeftWhite"]
	);

	// wavelength to channel popupLists
	this.redPopupList = new popupList(
		-50, 0, channelLabels, 
		actions['setRedLogicalChannel'],
		1,
		skinLibrary["redAnchorText"],
		skinLibrary["redItemBackgroundText"],
		skinLibrary["redItemHighlightText"]
	);

	this.greenPopupList = new popupList(
		0, 0, channelLabels, 
		actions['setGreenLogicalChannel'],
		0,
		skinLibrary["greenAnchorText"],
		skinLibrary["greenItemBackgroundText"],
		skinLibrary["greenItemHighlightText"]
	);

	this.bluePopupList = new popupList(
		50, 0, channelLabels, 
		actions['setBlueLogicalChannel'],
		0,
		skinLibrary["blueAnchorText"],
		skinLibrary["blueItemBackgroundText"],
		skinLibrary["blueItemHighlightText"]
	);
	
	this.greyPopupList = new popupList(
		0, 0, channelLabels, actions['setGreyLogicalChannel']
	);
	
	// set up channel on/off buttons
	this.redButton = new button( 
		Math.round(this.redPopupList.x + this.redPopupList.width/2), -13, 
		actions['OnOffR'],
		skinLibrary["redButtonOn"],
		skinLibrary["redButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.greenButton = new button( 
		Math.round(this.greenPopupList.x + this.greenPopupList.width/2), -13, 
		actions['OnOffG'],
		skinLibrary["greenButtonOn"],
		skinLibrary["greenButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.blueButton = new button(
		Math.round(this.bluePopupList.x + this.bluePopupList.width/2), -13,
		actions['OnOffB'],
		skinLibrary["blueButtonOn"],
		skinLibrary["blueButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);

	this.redScaleButton = new button(
		Math.round(this.redPopupList.x + this.redPopupList.width/2), 25,
		actions['showRedScale'],
		'<text fill="maroon" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.greenScaleButton = new button(
		Math.round(this.greenPopupList.x + this.greenPopupList.width/2), 25,
		actions['showGreenScale'],
		'<text fill="darkgreen" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.blueScaleButton = new button(
		Math.round(this.bluePopupList.x + this.bluePopupList.width/2), 25,
		actions['showBlueScale'],
		'<text fill="midnightblue" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.greyScaleButton = new button(
		Math.round(this.greyPopupList.x + this.greyPopupList.width/2), 25,
		actions['showGreyScale'],
		'<text fill="black" text-anchor="middle">Scale</text>',
		null,
		'<text fill="white" text-anchor="middle">Scale</text>'
	);

	
	// save button
	this.saveButton = new button(
		85, 130, 
		actions['Save'],
		'<text fill="black" text-anchor="end">Save</text>',
		null,
		'<text fill="white" text-anchor="end">Save</text>'
	);
	this.loadButton = new button(
		85, 140, 
		actions['preload'],
		'<text fill="black" text-anchor="end">Prefetch</text>',
		null,
		'<text fill="white" text-anchor="end">Prefetch</text>'
	);
	

	// set up RGB to grayscale button
	this.RGB_BWbutton = new button(
		105, 115, 
		actions['RGB2BW'],
		skinLibrary["RGB_BWButtonOn"],
		skinLibrary["RGB_BWButtonOff"],
		skinLibrary["blankButtonRadius13Highlight"]
	);
	
	// buttons to access panes
	
// Rest of these buttons should live somewhere else.
	this.panePopupList = new popupList(
		125, 125,
		supplimentaryControls,
		actions['openWindow'],
		null,
		skinLibrary["transparentBox"],
		null, 
		skinLibrary["whiteTranslucentBox"],
		[ 'text-anchor', 'end' ]
	);

	// Z & T controls
	this.zSlider.realize(this.controlsRoot);
	this.tSlider.realize(this.controlsRoot);
	this.tUpButton.realize(this.controlsRoot);
	this.tDownButton.realize(this.controlsRoot);
	this.zUpButton.realize(this.controlsRoot);
	this.zDownButton.realize(this.controlsRoot);
	this.tAnimUpButton.realize(this.controlsRoot);
	this.tAnimDownButton.realize(this.controlsRoot);
	this.zAnimUpButton.realize(this.controlsRoot);
	this.zAnimDownButton.realize(this.controlsRoot);

	this.loadButton.realize(this.controlsRoot);

	// RGB & BW switcheroo
	this.RGB_BWbutton.realize(this.controlsRoot);
	
	// Save button
	this.saveButton.realize(this.controlsRoot);

	// RGB channel controls
	this.RGBpopupListBox = svgDocument.createElementNS( svgns, "g" );
	this.RGBpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
	this.controlsRoot.appendChild( this.RGBpopupListBox );
	this.redButton.realize( this.RGBpopupListBox );
	this.greenButton.realize( this.RGBpopupListBox );
	this.blueButton.realize( this.RGBpopupListBox );
	this.redPopupList.realize( this.RGBpopupListBox );
	this.greenPopupList.realize( this.RGBpopupListBox );
	this.bluePopupList.realize( this.RGBpopupListBox );
	this.redScaleButton.realize( this.RGBpopupListBox );
	this.greenScaleButton.realize( this.RGBpopupListBox );
	this.blueScaleButton.realize( this.RGBpopupListBox );

	// Grayscale controls
	this.BWpopupListBox = svgDocument.createElementNS( svgns, "g" );
	this.BWpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
	this.BWpopupListBox.setAttribute( "display", "none" );
	this.controlsRoot.appendChild( this.BWpopupListBox );
	this.greyPopupList.realize( this.BWpopupListBox );
	this.greyScaleButton.realize( this.BWpopupListBox );
	
	this.panePopupList.realize( this.controlsRoot );

	return this.controlsRoot;

};

