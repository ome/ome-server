/*****
*
*	imageControls.js
*		Global Data dependencies: theT, theZ, Z, T
*		Global Function dependencies: updateTheT, updateTheZ
*		
*		External file dependencies: none


*
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
	functionPointers - associative array (AKA hash) of functions to tie controls into

*****/
ImageControls.prototype.buildControls = function( functionPointers ) {

	this.controlsRoot = svgDocument.createElementNS( svgns, "g" );

	// Z section controls
	this.zSlider = new Slider(
		30, 120, 100, -90,
		functionPointers['zSlider'],
		skinLibrary["zSliderBody"],
		skinLibrary["zSliderThumb"]
	);
	this.zSlider.setLabel(0,-102,"");
	this.zSlider.getLabel().setAttribute( "fill", "white" );
	this.zSlider.getLabel().setAttribute( "text-anchor", "middle" );
	this.zUpButton = new button(
		15, 106, 
		functionPointers['zUp'],
		skinLibrary["triangleUpWhite"]
	);
	this.zDownButton = new button(
		15, 110,
		functionPointers['zDown'],
		skinLibrary["triangleDownWhite"]
	);
	this.zAnimUpButton = new button(
		15, 86, 
		functionPointers['zAnimUp'],
		skinLibrary["triangleUpRed"],
		null,
		skinLibrary["triangleUpWhite"]
	);
	this.zAnimDownButton = new button(
		15, 90, 
		functionPointers['zAnimDown'],
		skinLibrary["triangleDownRed"],
		null,
		skinLibrary["triangleDownWhite"]
	);

	// Timepoint controls
	this.tSlider = new Slider(
		60, 30, 100, 0,
		functionPointers['tSlider']
	);
	this.tSlider.setLabel(60,-13,"");
	this.tSlider.getLabel().setAttribute( "fill", "white" );
	this.tUpButton = new button(
		182, 25,
		functionPointers['tUp'],
		skinLibrary["triangleRightWhite"]
	);
	this.tDownButton = new button(
		178, 25,
		functionPointers['tDown'],
		skinLibrary["triangleLeftWhite"]
	);
	this.tAnimUpButton = new button(
		182, 35, 
		functionPointers['tAnimUp'],
		skinLibrary["triangleRightRed"],
		null,
		skinLibrary["triangleRightWhite"]
	);
	this.tAnimDownButton = new button(
		178, 35, 
		functionPointers['tAnimDown'],
		skinLibrary["triangleLeftRed"],
		null,
		skinLibrary["triangleLeftWhite"]
	);

	// wavelength to channel popupLists
	this.redPopupList = new popupList(
		-50, 0, fluors, 
		functionPointers['updateR'],
		1,
		skinLibrary["redAnchorText"],
		skinLibrary["redItemBackgroundText"],
		skinLibrary["redItemHighlightText"]
	);

	this.greenPopupList = new popupList(
		0, 0, fluors, 
		functionPointers['updateG'],
		0,
		skinLibrary["greenAnchorText"],
		skinLibrary["greenItemBackgroundText"],
		skinLibrary["greenItemHighlightText"]
	);

	this.bluePopupList = new popupList(
		50, 0, fluors, 
		functionPointers['updateB'],
		0,
		skinLibrary["blueAnchorText"],
		skinLibrary["blueItemBackgroundText"],
		skinLibrary["blueItemHighlightText"]
	);
	
	this.bwPopupList = new popupList(
		0, 0, fluors, functionPointers['updateBW']
	);
	
	// set up channel on/off buttons
	this.redButton = new button( 
		Math.round(this.redPopupList.x + this.redPopupList.width/2), -13, 
		functionPointers['OnOffR'],
		skinLibrary["redButtonOn"],
		skinLibrary["redButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.greenButton = new button( 
		Math.round(this.greenPopupList.x + this.greenPopupList.width/2), -13, 
		functionPointers['OnOffG'],
		skinLibrary["greenButtonOn"],
		skinLibrary["greenButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	this.blueButton = new button(
		Math.round(this.bluePopupList.x + this.bluePopupList.width/2), -13,
		functionPointers['OnOffB'],
		skinLibrary["blueButtonOn"],
		skinLibrary["blueButtonOff"],
		skinLibrary["blankButtonRadius5Highlight"]
	);
	
	// save button
	this.saveButton = new button(
		85, 130, 
		functionPointers['Save'],
		'<text fill="black" text-anchor="end">Save</text>',
		null,
		'<text fill="white" text-anchor="end">Save</text>'
	);
	this.loadButton = new button(
		85, 140, 
		functionPointers['preload'],
		'<text fill="black" text-anchor="end">Load All</text>',
		null,
		'<text fill="white" text-anchor="end">Load All</text>'
	);
	

	// set up RGB to grayscale button
	this.RGB_BWbutton = new button(
		110, 115, 
		functionPointers['RGB2BW'],
		skinLibrary["RGB_BWButtonOn"],
		skinLibrary["RGB_BWButtonOff"],
		skinLibrary["blankButtonRadius13Highlight"]
	);
	
	// buttons to access panes
	this.scaleButton = new button(
		190, 120,
		functionPointers['showScale'],
		'<text fill="black" text-anchor="end">Scale</text>',
		null,
		'<text fill="white" text-anchor="end">Scale</text>'
	);
	
// Rest of these buttons should live somewhere else.
	this.statsButton = new button(
		190, 110, showStats,
		'<text fill="black" text-anchor="end">Stats</text>',
		null,
		'<text fill="white" text-anchor="end">Stats</text>'
	);
	this.overlayButton = new button(
		190, 130, showOverlay,
		'<text fill="black" text-anchor="end">Overlay</text>',
		null,
		'<text fill="white" text-anchor="end">Overlay</text>'
	);
	this.settingsButton = new button(
		190, 140, showPreferences,
		'<text fill="black" text-anchor="end">Preferences</text>',
		null,
		'<text fill="white" text-anchor="end">Preferences</text>'
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

	// Grayscale controls
	this.BWpopupListBox = svgDocument.createElementNS( svgns, "g" );
	this.BWpopupListBox.setAttribute( "transform", "translate( 95, 70 )" );
	this.BWpopupListBox.setAttribute( "display", "none" );
	this.controlsRoot.appendChild( this.BWpopupListBox );
	this.bwPopupList.realize( this.BWpopupListBox );

	this.statsButton.realize( this.controlsRoot );
	this.scaleButton.realize( this.controlsRoot );
	this.overlayButton.realize( this.controlsRoot );
	this.settingsButton.realize( this.controlsRoot );

	return this.controlsRoot;

}

