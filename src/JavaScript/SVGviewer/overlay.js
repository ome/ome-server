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
		layout #1
		
	tested
		
*****/
Overlay.prototype.buildSVG = function() {
	// check for initialization
	if(this.colors == null) return null;

// phony info
	this.layerNames = new Array();
	this.layerNames.push("Nucleus Vector");
	this.layerNames.push("Nucleus Outline");
	this.layerNames.push("Nucleus Centroid");
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
		60, 30, this.colors, this.changeColor, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.colorPopupList.setLabel(-2, 12, "Color:");
	this.colorPopupList.getLabel().setAttribute("text-anchor", "end");
	this.displayButton = new button(
		120, 30, this.displayLayer,
		'<text y="12">Off</text>',
		'<text y="12">On</text>'
	);
	
	
	this.dynamicControls = svgDocument.createElementNS( svgns, "g" );
	this.dynamicControls.setAttribute("transform", "translate(20,60)");
	this.dynamicControls.padding = 5;
	this.dynamicControls.appendChild( this.displayButton.textToSVG(
		'<rect x="-' + this.dynamicControls.padding + '" y="-' +
			this.dynamicControls.padding + '" height="0" width="0" ' +
			'fill="none" stroke="black" stroke-width="2" opacity="0.7"/>'
	));
	this.dynamicControls.border = this.dynamicControls.lastChild;
	
	this.markViewButton = new button(
		100, 0, this.markView
	);
	this.markViewButton.setLabel(-7, 10,"Mark current view");
	this.markViewButton.getLabel().setAttribute("text-anchor", "end");
	this.markViewPopupList = new popupList(
		74, 20, this.markedViews, this.changeMarkedView, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
		
	);
	this.markViewPopupList.setLabel(-2, 12, "Marked views");
	this.markViewPopupList.getLabel().setAttribute("text-anchor", "end");
	this.viewDisplayButton = new button(
		20, 40, this.displayMarkedView,
		'<g>' +
		'	<rect x="-2" width="34" height="14" fill="gray" opacity="0.7"/>' +
		'	<text x="2" y="1em">Hide</text>' +
		'</g>',
		'<g>' +
		'	<rect x="-2" width="34" height="14" fill="gray" opacity="0.7"/>' +
		'	<text y="1em">Show</text>' +
		'</g>',
		'<rect x="-2" width="34" height="14" fill="white"/>'

	);
	this.removeView = new button(
		80, 40, this.removeMarkedView,
		'<g>' +
		'	<rect x="-2" width="50" height="14" fill="gray" opacity="0.7"/>' +
		'	<text y="1em">Remove</text>' +
		'</g>',
		null,
		'<rect x="-2" width="50" height="14" fill="white"/>'
	);



	// place GUI elements in containers
	this.root.appendChild( this.dynamicControls );

	this.markViewButton.realize( this.dynamicControls );
	this.viewDisplayButton.realize( this.dynamicControls );
	this.removeView.realize( this.dynamicControls );
	this.markViewPopupList.realize( this.dynamicControls );
	
	this.dynamicControls.border.setAttribute("width", 180);
	this.dynamicControls.border.setAttribute("height", 70);

	this.colorPopupList.realize( this.root );
	this.displayButton.realize( this.root );
	this.layerPopupList.realize( this.root );
	
	// build background
	
	return this.root;
}

/*****
	
	buildSVG2
	
	returns:
		SVG chunk describing Overlay pane
	notes:
		for use in conjuction with multipaneToolBox
		#2 layout
		
	tested
		
*****/
Overlay.prototype.buildSVG2 = function() {
	// check for initialization
	if(this.colors == null) return null;

// phony info
	this.layerNames = new Array();
	this.layerNames.push("Nucleus Vector");
	this.layerNames.push("Nucleus Outline");
	this.layerNames.push("Nucleus Centroid");
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
		60, 30, this.colors, this.changeColor, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.colorPopupList.setLabel(-2, 12, "Color:");
	this.colorPopupList.getLabel().setAttribute("text-anchor", "end");
	this.displayButton = new button(
		120, 30, this.displayLayer,
		'<text y="12">Off</text>',
		'<text y="12">On</text>'
	);
	
	
	this.dynamicControls = svgDocument.createElementNS( svgns, "g" );
	this.dynamicControls.setAttribute("transform", "translate(20,60)");
	this.dynamicControls.padding = 5;
	this.dynamicControls.appendChild( this.displayButton.textToSVG(
		'<rect x="-' + this.dynamicControls.padding + '" y="-' +
			this.dynamicControls.padding + '" height="0" width="0" ' +
			'fill="none" stroke="black" stroke-width="2" opacity="0.7"/>'
	));
	this.dynamicControls.border = this.dynamicControls.lastChild;
	
	this.allZButton = new button(
		100, 0, this.allZ
	);
	this.allZButton.setLabel(-7, 10,"Show all Z");
	this.allZButton.getLabel().setAttribute("text-anchor", "end");
	this.allTButton = new button(
		100, 20, this.allT
	);
	this.allTButton.setLabel(-7, 10,"Show all T");
	this.allTButton.getLabel().setAttribute("text-anchor", "end");


	// place GUI elements in containers
	this.root.appendChild( this.dynamicControls );

	this.allZButton.realize( this.dynamicControls );
	this.allTButton.realize( this.dynamicControls );
	
	this.dynamicControls.border.setAttribute("width", 180);
	this.dynamicControls.border.setAttribute("height", 40);

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

	// for GUI layout 1
	this.markView = null
	this.changeMarkedView = null;
	this.removeMarkedView = null;
	this.displayMarkedView = null;

	// for GUI layout 2
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