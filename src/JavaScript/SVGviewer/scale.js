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
scaleWidth = 180;

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
function Scale(image, updateBlack, updateWhite) {
	if(image.Dims != null)
		this.init(image, updateBlack, updateWhite)
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
	if(this.image == null) 
		return null;

	this.root = svgDocument.createElementNS(svgns, "g");

	this.fluors = new Array();
	for(var i in this.image.Wavelengths)
		this.fluors[this.image.Wavelengths[i]['WaveNum']] = this.image.Wavelengths[i]['Fluor'];
	this.blackSlider = new Slider( 
		10, 60, scaleWidth, 0, 
		this.updateBlack,
		'<rect width="'+scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="black"/>'
	);
	this.whiteSlider = new Slider( 
		10, 70, scaleWidth, 0, 
		this.updateWhite,
		'<rect width="'+scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="white"/>'
	);
	this.wavePopupList = new popupList(
		10, 90, this.fluors, null
	);

	this.root.appendChild( this.whiteSlider.textToSVG(
'<g transform="translate(10,70)">\
	<line x2="'+ scaleWidth +'" stroke-width="2" stroke="blue"/>\
	<line id="geomeanTick" y1="-10" y2="10" stroke-width="2" stroke="blue"/>\
</g>'
	));
	this.geomeanTick = this.root.lastChild.lastChild;
	
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="20" y="2em">Black level: </text>' ));
	this.blackLabel = this.root.lastChild;
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="20" y="3em">White level: </text>' ));
	this.whiteLabel = this.root.lastChild;
	this.root.appendChild( this.whiteSlider.textToSVG(
		'<text x="20" y="4em">Scale: </text>' ));
	this.scaleLabel = this.root.lastChild;

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

Scale.prototype.updateGeomean = function(t) {
	if(this.root == null) return null;
	if(t != null && t>=0 && t<this.Dims['T'])
		this.theT = t;
	var wavenum = this.wavePopupList.getSelection();
	var min = this.Stats[wavenum][this.theT]['min'];
	var max = this.Stats[wavenum][this.theT]['max'];
	var sigma = this.Stats[wavenum][this.theT]['sigma'];
	var geomeanX = (this.Stats[wavenum][this.theT]['geomean'] - min) / (max - min) * scaleWidth;
	this.geomeanTick.setAttribute("transform", "translate("+geomeanX+",0)");
	// set B&W sliderVals to correct positions
}

/********************************************************************************************/
/************************ Functions not part of this class **********************************/
/********************************************************************************************/

/*****

	verifyWBS
		WBS = WBS to verify
		
	returns:
		possibly altered WBS that is valid
		
	GOES IN OMEimage.js WHEN DONE!!!!!!!!!!!!!!!!!!!!!!!!!!!
		
	untested
		

*****/
function verifyWBS(WBS) {
	return WBS;
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

Scale.prototype.init = function(image, updateBlack, updateWhite) {
	this.Dims = image.Dims;
	this.Stats = image.Stats;
	this.BS = new Array(this.Dims['W']);
	this.image = image;
	this.theT = (this.image.oldT == null ? 0 : this.image.oldT);
	this.updateBlack = updateBlack;
	this.updateWhite = updateWhite;
}

/********************************************************************************************/
/************************ Functions not part of this class **********************************/
/********************************************************************************************/
