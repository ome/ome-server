/*****

	ViewerPreferences.js
		external file dependencies: widget.js, button.js, popupList.js, slider.js
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
ViewerPreferences.VERSION = 0.1;

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

/*****
	
	buildSVG
	
	returns:
		SVG chunk describing Overlay pane
	notes:
		for use in conjuction with multipaneToolBox
		
	tested
		
*****/
ViewerPreferences.prototype.buildSVG = function() {
	// check for initialization
	if(this.resizeToolBox == null) return null;

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.toolBoxSizeSlider = new Slider(
		120,15,50,0,
		this.resizeToolBox
	);
	this.toolBoxSizeSlider.setLabel(-95,3,"Resize toolbox:");
	this.applyChangesToMultiButton = new button(
		100, 35, 
		this.resizeMultiToolBox,
		'<g>'+
		'	<rect x="-90" width="180" height="18" fill="lightslategray"/>'+
		'	<text y="13" text-anchor="middle">Apply changes to this toolbox</text>'+
		'	<rect x="-90" width="180" height="18" opacity="0"/>'+
		'</g>',
		null,
		'<g>'+
		'	<rect x="-90" y="-1" width="180" height="18" fill="aquamarine"/>'+
		'	<text y="13" text-anchor="middle">Apply changes to this toolbox</text>'+
		'	<rect x="-90" width="180" height="18" opacity="0"/>'+
		'</g>'
	);
	this.saveChangesButton = new button(
		100, 65, 
		this.savePreferences,
		'<g>'+
		'	<rect x="-50" width="100" height="18" fill="lightslategray"/>'+
		'	<text y="13" text-anchor="middle">Save changes</text>'+
		'	<rect x="-50" width="100" height="18" opacity="0"/>'+
		'</g>',
		null,
		'<g>'+
		'	<rect x="-50" width="100" height="18" fill="aquamarine"/>'+
		'	<text y="13" text-anchor="middle">Save changes</text>'+
		'	<rect x="-50" width="100" height="18" opacity="0"/>'+
		'</g>'
	);

	this.toolBoxSizeSlider.realize( this.root );
	this.applyChangesToMultiButton.realize( this.root );
	this.saveChangesButton.realize( this.root );
	
	return this.root;
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

ViewerPreferences.prototype.init = function(resizeToolBox, resizeMultiToolBox, savePreferences) {
	this.resizeToolBox      = resizeToolBox;
	this.resizeMultiToolBox = resizeMultiToolBox;
	this.savePreferences    = savePreferences;
}
