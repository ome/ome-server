/*****

	scale.js
		external file dependencies: widget.js, slider.js, button.js, popupList.js
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
Scale.VERSION = 0.1;
Scale.prototype.scaleWidth = 180;

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
function Scale(image, updateBlack, updateWhite, waveChange) {
	if(image.Dims != null)
		this.init(image, updateBlack, updateWhite, waveChange)
	else
		alert("Bad parameters or image not initialized. Class creation of Scale.js failed");
}

/*****

	setChannelWavelength
		channel = R | G | B | Gray
		waveNum
	purpose:
		Adjusts WBS and sets it in image		
	returns:
		nothing
		
	untested

*****/
Scale.prototype.setChannelWavelength = function( channel, waveNum ) {
}

/*****
	
	buildSVG
	
	returns:
		SVG chunk describing Scale pane
	notes:
		for use in conjuction with multipaneToolBox
		
	tested
		
*****/
Scale.prototype.buildSVG = function() {
	// has initialization occured?
	if(this.image == null) 
		return null;
// set up references & constants
	this.fluors = new Array();
	for(var i in this.image.Wavelengths)
		this.fluors[this.image.Wavelengths[i]['WaveNum']] = this.image.Wavelengths[i]['Fluor'];

// build SVG
	this.root = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.blackSlider = new Slider( 
		10, 70, this.scaleWidth, 0, 
		this.updateBlack,
		'<rect width="'+this.scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="black"/>'
	);
	this.whiteSlider = new Slider( 
		10, 80, this.scaleWidth, 0, 
		this.updateWhite,
		'<rect width="'+this.scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="white"/>'
	);
	this.wavePopupList = new popupList(
		10, 100, this.fluors, this.waveChange
	);
	
	// build background
	this.root.appendChild( this.whiteSlider.textToSVG(
'<g transform="translate(10,80)">\
	<line x2="'+ this.scaleWidth +'" stroke-width="2" stroke="blue"/>\
	<line y1="-10" y2="10" stroke-width="2" stroke="blue"/>\
</g>'
	));
	this.geomeanTick = this.root.lastChild.lastChild;
	this.root.lastChild.appendChild( this.whiteSlider.textToSVG(
		'<rect y="-10" width="0" height="10" fill="black" opacity="0.3"/>'
	));
	this.blackBar = this.root.lastChild.lastChild;
	this.root.lastChild.appendChild( this.whiteSlider.textToSVG(
		'<rect width="0" height="10" fill="white" opacity="0.3"/>'
	));
	this.whiteBar = this.root.lastChild.lastChild;
	
	// build displays
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="20" y="2em">Black level: </text>'));
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="40" y="3em"> </text>'));
	this.blackLabel = this.root.lastChild;
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="20" y="4em">White level: </text>'));
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="40" y="5em"> </text>'));
	this.whiteLabel = this.root.lastChild;

	this.blackSlider.realize( this.root );
	this.whiteSlider.realize( this.root );
	this.wavePopupList.realize( this.root );
	
	return this.root;
}

/*****

	updateScale
		t = theT
	
	purpose:
		update scale based on info particular to W & T

	untested
	
*****/

Scale.prototype.updateScale = function(t) {
	// has buildSVG been called?
	if(this.root == null) return null;
	// verify params 
	if(t != null && t>=0 && t<this.Dims['T'])
		this.theT = t;
	
	// construct variables
	var wavenum = this.wavePopupList.getSelection();
	var min = this.Stats[wavenum][this.theT]['min'];
	var max = this.Stats[wavenum][this.theT]['max'];
	var range = max-min;
	var sigma = this.Stats[wavenum][this.theT]['sigma'];
	this.geomeanX = (this.Stats[wavenum][this.theT]['geomean'] - min) / range * this.scaleWidth;

	// move geomeanTick
	this.geomeanTick.setAttribute("transform", "translate("+this.geomeanX+",0)");
	// set B&W sliderVals to correct positions
	var wSliderVal = (this.getCWhiteLevel(wavenum, this.theT) - min)/range * this.scaleWidth;
	wSliderVal = Math.round(wSliderVal*100)/100;
	this.whiteSlider.setValue(wSliderVal, true);
	var bSliderVal = (this.getCBlackLevel(wavenum, this.theT) - min)/range * this.scaleWidth;
	bSliderVal = Math.round(bSliderVal*100)/100;
	this.blackSlider.setValue(bSliderVal, true);
}

/*****
	
	updateWBS
	
	purpose:
		update image.WBS

*****/
Scale.prototype.updateWBS = function( channel, wavenum) {
	if(scale.image == null) return null;
	var channelMap = new Array();
	channelMap['R'] = 0;
	channelMap['G'] = 3;
	channelMap['B'] = 6;
	channelMap['Gray'] = 9;
	var WBS = this.image.getWBS();
	var changed = false;
	if(channel != null && wavenum != null)
		if(channelMap[channel] != null) {
			WBS[channelMap[channel]] = wavenum;
			changed = true;
		}

	for(i=0;i<4;i++) {
		var wavenum = WBS[i*3];
		if(WBS[i*3+1] != this.BS[wavenum]['B']) {
			changed = true;
			WBS[i*3+1] = this.BS[wavenum]['B'];
		}
		if(WBS[i*3+2] != this.BS[wavenum]['S']) {
			changed = true;
			WBS[i*3+2] = this.BS[wavenum]['S'];
		}
	}
	if(changed)
		this.image.setWBS(WBS);
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init
		image = OMEimage

	tested

*****/

Scale.prototype.init = function(image, updateBlack, updateWhite, waveChange) {
	this.Dims = image.Dims;
	this.Stats = image.Stats;
	this.BS = new Array();
	// set BS according to values from image.WBS or defaults
	for(var i in image.Wavelengths) {
		this.BS[image.Wavelengths[i]['WaveNum']] = new Array();
		var BSflag = false;
		// are values in image.WBS?
		for(var j=0;j<4;j++)
			if(image.WBS[j*3] == image.Wavelengths[i]['WaveNum']) {
				this.BS[ image.WBS[j*3] ]['B'] = image.WBS[j*3+1];
				this.BS[ image.WBS[j*3] ]['S'] = image.WBS[j*3+2];
				BSflag = true;
			}
		if(!BSflag) {
		// values weren't in image.WBS, set to default
			this.BS[ image.WBS[j*3] ]['B'] = 0;
			this.BS[ image.WBS[j*3] ]['S'] = 4;
		}
	}
	this.image = image;
	this.theT = (this.image.oldT == null ? 0 : this.image.oldT);
	this.updateBlack = updateBlack;
	this.updateWhite = updateWhite;
	this.waveChange = waveChange;
}

Scale.prototype.getCWhiteLevel = function(w, t) {
	return this.Stats[w][t]['geomean'] + this.Stats[w][t]['sigma'] * this.BS[w]['S'];
}

Scale.prototype.getCBlackLevel = function(w, t) {
	return this.Stats[w][t]['geomean'] + this.Stats[w][t]['sigma'] * this.BS[w]['B'];
}
