/*****

	scale.js
		external file dependencies: none
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
scale.VERSION = 0.1;

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		image = OMEimage
		
	untested

*****/
function scale(image) {
	if(image.Dims != null)
		this.init(image, default_WBS )
	else
		alert("Bad parameters or image not initialized. Class creation of scale.js failed");
}

/*****

	setChannelWavelength
		channel = R | G | B | Gray
		waveNum
	purpose:
		Adjusts WBS and sets it in image		
	returns:
		nothing
		
	untests

*****/
scale.prototype.setChannelWavelength = function( channel, waveNum ) {
}

/*****
	
	buildSVG
	
	returns:
		SVG node containing scale pane
	notes:
		for use in conjuction with multipaneToolBox
		
	untested
		
*****/
scale.prototype.buildSVG = function() {
	return svgDocument.createElementNS("<g/>");
}

/********************************************************************************************/
/************************ Functions not part of this class **********************************/
/********************************************************************************************/

/*****

	verifyWBS
		WBS = WBS to verify
		
	returns:
		possibly altered WBS that is valid
		
	GOES IN OMEIMAGE WHEN DONE!!!!!!!!!!!!!!!!!!!!!!!!!!!
		
	untested
		

*****/
function verifyWBS(WBS) {
	return WBS;
}

/*****

	test
	
	purpose:
		to instantiate this object and call all functions to see if they crash
		
	untested

*****/
function test() {
}

/*****

	updateBlack
		val = slider value from black slider
	
	purpose:
		do backend response to changing Black scale in GUI
		
	untested

*****/
function updateBlack(val) {
}

/*****

	updateWhite
		val = slider value from white slider
	
	purpose:
		do backend response to changing White scale in GUI
		
	untested

*****/
function updateWhite(val) {
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init
		image = OMEimage

	untested

*****/

scale.prototype.init = function(image) {
	this.Dims = image.Dims;
	this.Stats = image.Stats;
	
}

/********************************************************************************************/
/************************ Functions not part of this class **********************************/
/********************************************************************************************/
