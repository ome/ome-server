/*****
*
*	XYPlaneControls.js

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

XYPlaneControls.prototype.toolboxParams = {
	x: 250,
	y: 30, 
	width: 200, 
	height: 150,
	menuBarText: skinLibrary["roundGreenMenuBar"],
	hideControlText: skinLibrary["ovalSquishHideControl"],
	GUIboxText: skinLibrary["greenGradientGUIbox"],
	noclip: 'noclip'
};

/*****
	XYPlaneControls
		actions - associative array (AKA hash) of functions or 'method name'/object pairs
			to tie controls into
		supplimentaryControls - control window names to give access to in a pop-up list
		channelLabels - labels of the channels in the image
*****/
function XYPlaneControls( actions, supplimentaryControls, channelLabels, image ) {
	this.init( actions, supplimentaryControls, channelLabels, image );
}

XYPlaneControls.prototype.init = function( actions, supplimentaryControls, channelLabels, image ) {
	this.actions = actions;
	this.supplimentaryControls = supplimentaryControls;
	this.channelLabels = channelLabels;
	this.image = image;

	this.actions['OnOffR']       = { obj: this.image, method: 'setRedOn' };
	this.actions['OnOffG']       = { obj: this.image, method: 'setGreenOn' };
	this.actions['OnOffB']       = { obj: this.image, method: 'setBlueOn' };
	this.actions['switchRGB_BW'] = { obj: this.image, method: 'setDisplayRGB_BW' };
	this.actions['planeCommand'] = { obj: this, method: 'ExecPlaneCommand' };
	this.planeCommands           = [ 'Save', 'Prefetch', 'View Plane' ];
	this.planeActions            = [ 
		{ obj: this.image, method: 'saveState' }, 
		{ obj: this.image, method: 'prefetchImages' },
		null
	];
};

XYPlaneControls.prototype.buildToolBox = function( toolboxLayer ) {
	var displayContent = this.buildDisplay();
	this.toolBox = new toolBox( this.toolboxParams );
	this.toolBox.setLabel(100,12,"XY Plane Controls");
	this.toolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
	this.toolBox.realize( toolboxLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( displayContent );
	
};

XYPlaneControls.prototype.setWindowControllers = function( windowControllers ) {
	this.windowControllers = windowControllers;
};

XYPlaneControls.prototype.setImageURL = function ( imageURL ) {
	if( this.openImgLink ) {
		this.openImgLink.setAttributeNS( xlinkns, 'href', imageURL);
	}
};



XYPlaneControls.prototype.buildDisplay = function(  ) {

	this.displayContent = Util.createElementSVG( "g" );

	// Z section controls
	this.zSlider = new Slider(
		30, 120, 100, -90,
		this.actions['zSlider'],
		skinLibrary["zSliderBody"],
		skinLibrary["zSliderThumb"],
		theZ
	);
	this.zSlider.setLabel(0,-102,"");
	this.zSlider.getLabel().setAttribute( "fill", "white" );
	this.zSlider.getLabel().setAttribute( "text-anchor", "middle" );
	this.zSlider.realize(this.displayContent);
	this.zSlider.setMinmax( 0, (this.image.getDimZ() - 1) );

	this.zUpButton = new button(
		15, 106, 
		{ obj: this, method: 'zUp' },
		skinLibrary["triangleUpWhite"]
	);
	this.zDownButton = new button(
		15, 110,
		{ obj: this, method: 'zDown' },
		skinLibrary["triangleDownWhite"]
	);
	this.zAnimUpButton = new button(
		15, 86, 
		{ obj: this, method: 'zAnimUp' },
		skinLibrary["triangleUpRed"],
		null,
		skinLibrary["triangleUpWhite"]
	);
	this.zAnimDownButton = new button(
		15, 90, 
		{ obj: this, method: 'zAnimDown' },
		skinLibrary["triangleDownRed"],
		null,
		skinLibrary["triangleDownWhite"]
	);

	// Timepoint controls
	this.tSlider = new Slider(
		60, 30, 100, 0,
		this.actions['tSlider'],
		null,
		null,
		theT
	);
	this.tSlider.setLabel(60,-13,"");
	this.tSlider.getLabel().setAttribute( "fill", "white" );
	this.tSlider.realize(this.displayContent);
	this.tSlider.setMinmax( 0, (this.image.getDimT() - 1) );

	this.tUpButton = new button(
		182, 25,
		{ obj: this, method: 'tUp' },
		skinLibrary["triangleRightWhite"]
	);
	this.tDownButton = new button(
		178, 25,
		{ obj: this, method: 'tDown' },
		skinLibrary["triangleLeftWhite"]
	);
	this.tAnimUpButton = new button(
		182, 35, 
		{ obj: this, method: 'tAnimUp' },
		skinLibrary["triangleRightRed"],
		null,
		skinLibrary["triangleRightWhite"]
	);
	this.tAnimDownButton = new button(
		178, 35, 
		{ obj: this, method: 'tAnimDown' },
		skinLibrary["triangleLeftRed"],
		null,
		skinLibrary["triangleLeftWhite"]
	);

	// wavelength to channel popupLists
	this.redPopupList = new popupList(
		-50, 0, this.channelLabels, 
		this.actions['setRedLogicalChannel'],
		1,
		skinLibrary["redAnchorText"],
		skinLibrary["redItemBackgroundText"],
		skinLibrary["redItemHighlightText"]
	);

	this.greenPopupList = new popupList(
		0, 0, this.channelLabels, 
		this.actions['setGreenLogicalChannel'],
		0,
		skinLibrary["greenAnchorText"],
		skinLibrary["greenItemBackgroundText"],
		skinLibrary["greenItemHighlightText"]
	);

	this.bluePopupList = new popupList(
		50, 0, this.channelLabels, 
		this.actions['setBlueLogicalChannel'],
		0,
		skinLibrary["blueAnchorText"],
		skinLibrary["blueItemBackgroundText"],
		skinLibrary["blueItemHighlightText"]
	);
	
	this.greyPopupList = new popupList(
		0, 0, this.channelLabels, this.actions['setGreyLogicalChannel']
	);
	
	// set up channel on/off buttons
	this.redButton = new button( 
		Math.round(this.redPopupList.x + this.redPopupList.width/2), -13, 
		this.actions['OnOffR'],
		skinLibrary["redButtonOn"],
		skinLibrary["redButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.greenButton = new button( 
		Math.round(this.greenPopupList.x + this.greenPopupList.width/2), -13, 
		this.actions['OnOffG'],
		skinLibrary["greenButtonOn"],
		skinLibrary["greenButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.blueButton = new button(
		Math.round(this.bluePopupList.x + this.bluePopupList.width/2), -13,
		this.actions['OnOffB'],
		skinLibrary["blueButtonOn"],
		skinLibrary["blueButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);

	this.redScaleButton = new button(
		Math.round(this.redPopupList.x + this.redPopupList.width/2), 25,
		this.actions['showRedScale'],
		'<text fill="maroon" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.greenScaleButton = new button(
		Math.round(this.greenPopupList.x + this.greenPopupList.width/2), 25,
		this.actions['showGreenScale'],
		'<text fill="darkgreen" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.blueScaleButton = new button(
		Math.round(this.bluePopupList.x + this.bluePopupList.width/2), 25,
		this.actions['showBlueScale'],
		'<text fill="midnightblue" text-anchor="middle">Scale</text>',
		null,
		'<text fill="black" text-anchor="middle">Scale</text>'
	);
	this.greyScaleButton = new button(
		Math.round(this.greyPopupList.x + this.greyPopupList.width/2), 25,
		this.actions['showGreyScale'],
		'<text fill="black" text-anchor="middle">Scale</text>',
		null,
		'<text fill="white" text-anchor="middle">Scale</text>'
	);

	
	// popup list for plane commands
	this.planeCommandPopupList = new popupList(
		35, 125,
		this.planeCommands,
		this.actions['planeCommand'],
		null,
		skinLibrary["transparentBox"],
		null, 
		skinLibrary["whiteTranslucentBox"],
		[ 'text-anchor', 'end' ]
	);
	this.planeCommandPopupList.realize(this.displayContent);
	this.openImgLink = this.planeCommandPopupList.makeCellIntoLink(
		this.planeCommandPopupList.getIndexFromValue( 'View Plane' ), {
		target:          'plane_window',
	} );
 
 	// RGB to grayscale button
	this.RGB_BWbutton = new button(
		110, 110, 
		{ obj: this, method: 'switchRGB_BW' },
		skinLibrary["RGB_BWButtonOn"],
		skinLibrary["RGB_BWButtonOff"],
		skinLibrary["blankButtonRadius13Highlight"]
	);
	
	// popup list to access panes
	this.panePopupList = new popupList(
		125, 125,
		this.supplimentaryControls,
		{ obj: this, method: 'openWindow' },
		null,
		skinLibrary["transparentBox"],
		null, 
		skinLibrary["whiteTranslucentBox"],
		[ 'text-anchor', 'start' ]
	);

	// Z & T controls
	this.tUpButton.realize(this.displayContent);
	this.tDownButton.realize(this.displayContent);
	this.zUpButton.realize(this.displayContent);
	this.zDownButton.realize(this.displayContent);
	this.tAnimUpButton.realize(this.displayContent);
	this.tAnimDownButton.realize(this.displayContent);
	this.zAnimUpButton.realize(this.displayContent);
	this.zAnimDownButton.realize(this.displayContent);
	
	// RGB & BW switcheroo
	this.RGB_BWbutton.realize(this.displayContent);
	
	// RGB channel controls
	this.RGBpopupListBox = svgDocument.createElementNS( svgns, "g" );
	this.RGBpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
	this.displayContent.appendChild( this.RGBpopupListBox );
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
	this.displayContent.appendChild( this.BWpopupListBox );
	this.greyPopupList.realize( this.BWpopupListBox );
	this.greyScaleButton.realize( this.BWpopupListBox );
	
	this.panePopupList.realize( this.displayContent );

	return this.displayContent;

};

XYPlaneControls.prototype.exec_action = function ( action, value ) {
	if( ! action ) {
		return;
	} else if( this.actions[action] ) {
		action = this.actions[action];
	}
	if( Util.isFunction( action) ) { 
		action(value); 
	} else { 
		eval( "action['obj']."+action['method']+"(value)"); 
	}
};


/************
	Callback functions for GUI components
************/

XYPlaneControls.prototype.zUp = function () {
	setTheZ( theZ < this.image.getDimZ() - 1 ? theZ + 1 : theZ );
};
XYPlaneControls.prototype.zDown = function() {
	setTheZ( theZ> 0 ? theZ - 1 : theZ );
};
XYPlaneControls.prototype.zAnimUp = function() {
	var Z = this.image.getDimZ();
	if(Z > 1) {
		for(var i=theZ;i<Z;++i) {
			setTimeout("setTheZ(" + i + ")", (i-theZ)*100);
		}
	}
};
XYPlaneControls.prototype.zAnimDown = function() {
	var Z = this.image.getDimZ();
	if(Z > 1) {
		for(var i=theZ;i>=0;--i) {
			setTimeout("setTheZ(" + i + ")", (theZ-i)*100);
		}
	}
};


XYPlaneControls.prototype.tUp = function() {
	setTheT( theT < this.image.getDimT() - 1 ? theT+1 : theT );
};
XYPlaneControls.prototype.tDown = function() {
	setTheT( theT > 0 ? theT - 1 : theT );
};
XYPlaneControls.prototype.tAnimUp = function() {
	var T = this.image.getDimT();
	if(T>1) {
		for(var i=theT;i<T;++i) {
			setTimeout("setTheT(" + i + ")", (i-theT)*100);
		}
	}
};
XYPlaneControls.prototype.tAnimDown = function() {
	if(this.image.getDimT() > 1) {
		for(var i=theT;i>=0;--i) {
			setTimeout("setTheT(" + i + ")", (theT-i)*100);
		}
	}
};


XYPlaneControls.prototype.ExecPlaneCommand = function( planeCommandName ) {
	this.exec_action(this.planeActions[planeCommandName]);
};


XYPlaneControls.prototype.openWindow = function( windowName ) {
	this.windowControllers[ this.supplimentaryControls[ windowName ] ].toolBox.unhide();
};


XYPlaneControls.prototype.switchRGB_BW = function( val ) {
	//	decide which way to flip
	if(val) {	// val == true means mode = RGB
		this.BWpopupListBox.setAttribute( "display", "none" );
		this.RGBpopupListBox.setAttribute( "display", "inline" );
	}
	else {	// mode = BW
		this.BWpopupListBox.setAttribute( "display", "inline" );
		this.RGBpopupListBox.setAttribute( "display", "none" );
	}
	this.exec_action( 'switchRGB_BW', val );
};
