/*****

	overlay.js
		external file dependencies: widget.js, button.js, popupList.js
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
Overlay.VERSION = 0.1;

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
function Overlay() {
	this.init(arguments)
}

/*****
	
	buildSVG
	
	returns:
		SVG chunk describing Overlay pane
	notes:
		for use in conjuction with multipaneToolBox
		
	tested
		
*****/
Overlay.prototype.buildSVG = function() {
	// check for initialization
	if(this.colors == null) return null;

// phony info
	this.layerNames = new Array();
	this.layerNames.push("Vector");
	this.layerNames.push("Outline");
	this.layerNames.push("Centroid");
	this.layerNames.push("Scale");
	
	this.markedViews = new Array;
	this.markedViews.push("Z 12 T 0");
	this.markedViews.push("Z 5 T 15");

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.layerPopupList = new popupList(
		40, 10, this.layerNames, this.updateLayer, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.layerPopupList.setLabel(-2, 12, "Layer:");
	this.layerPopupList.getLabel().setAttribute("text-anchor", "end");
	this.colorPopupList = new popupList(
		90, 35, this.colors, this.changeColor, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.colorPopupList.setLabel(-2, 12, "Color:");
	this.colorPopupList.getLabel().setAttribute("text-anchor", "end");
	this.displayButton = new button(
		30, 35, this.displayLayer,
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

	this.colorPopupList.realize( this.root );
	this.displayButton.realize( this.root );
	this.layerPopupList.realize( this.root );
	
	// build background
	
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

Overlay.prototype.init = function() {
	this.updateLayer = null;
	this.changeColor = null;
	this.displayLayer = null;

	this.allZ = null;
	this.allT = null;
	
	this.makeColors();
}

/*****
	
	makeColors
	
	purpose:
		make a list of valid colors
		
	returns:
		list of colors
		
	tested
	
*****/

Overlay.prototype.makeColors = function() {
	if(this.colors != null) 
		return this.colors;
	this.colors = new Array();
	this.colors.push("red");
	this.colors.push("blue");
	this.colors.push("green");
	this.colors.push("yellow");
	this.colors.push("black");
	this.colors.push("white");
	return this.colors;
}