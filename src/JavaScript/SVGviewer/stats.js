/*****

	stats.js
		external file dependencies: none
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
Statistics.VERSION = 0.1;

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		Stats = list of hashes containing stats for image xyz stacks
		waveLabels = list of wave labels indexed by wavenums
		waveUpdate = function for wavelength popupList to call
		
	tested

*****/
function Statistics(Stats, waveLabels, waveUpdate) {
	if(Stats == null)
		return null;
	this.init(Stats, waveLabels, waveUpdate)
}

/*****
	
	buildSVG
	
	returns:
		SVG chunk describing Statistics pane
	notes:
		for use in conjuction with multipaneToolBox
		
	tested
		
*****/
Statistics.prototype.buildSVG = function() {
	// verify initialization
	if(this.Stats == null) return null;

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.wavePopupList = new popupList(
		120, 12, this.waveLabels, this.waveUpdate, null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.wavePopupList.setLabel(-2, 12, "Wavelength: ");
	this.wavePopupList.getLabel().setAttribute("text-anchor", "end");
	
	// build displays
	this.labels = new Object;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="3em">theT: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="3em" text-anchor="end"> </text>'
	));
	this.labels.theT = this.root.lastChild;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="4em">min: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="4em" text-anchor="end"> </text>'
	));
	this.labels.min = this.root.lastChild;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="5em">max: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="5em" text-anchor="end"> </text>'
	));
	this.labels.max = this.root.lastChild;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="6em">mean: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="6em" text-anchor="end"> </text>'
	));
	this.labels.mean = this.root.lastChild;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="7em">geomean: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="7em" text-anchor="end"> </text>'
	));
	this.labels.geomean = this.root.lastChild;
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="20" y="8em">sigma: </text>'
	));
	this.root.appendChild( this.wavePopupList.textToSVG(
		'<text x="180" y="8em" text-anchor="end"> </text>'
	));
	this.labels.sigma = this.root.lastChild;
	
	this.wavePopupList.realize( this.root );

	return this.root;
}

/*****

	updateStats
		t = theT
	
	purpose:
		update stats based on info particular to W & T

	untested
	
*****/

Statistics.prototype.updateStats = function(t) {
	// has buildSVG been called?
	if(this.root == null) return null;
	// verify params
	if(t == null) return;
	
	// update labels
	var wavenum = this.wavePopupList.getSelection();
	this.labels.theT.firstChild.data = t;
	this.labels.min.firstChild.data = this.Stats[wavenum][t]['min'];
	this.labels.max.firstChild.data = this.Stats[wavenum][t]['max'];
	this.labels.mean.firstChild.data = this.Stats[wavenum][t]['mean'];
	this.labels.geomean.firstChild.data = this.Stats[wavenum][t]['geomean'];
	this.labels.sigma.firstChild.data = this.Stats[wavenum][t]['sigma'];
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init
		Stats = list of hashes containing stats for image xyz stacks
		waveLabels = list of wave labels indexed by wavenums
		waveUpdate = function for wavelength popupList to call

	tested

*****/

Statistics.prototype.init = function(Stats, waveLabels, waveUpdate) {
	this.Stats = Stats;
	this.waveLabels = waveLabels;
	this.waveUpdate = waveUpdate;
}
