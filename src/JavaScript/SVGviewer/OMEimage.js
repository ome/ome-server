/*****
*
*	OMEimage.js
*		External file dependencies: none
*		Functions open to the world:
*			OMEimage
*				constructor
*		Functions without safety nets:
*			init
*****/

svgns = "http://www.w3.org/2000/svg";
xlinkns  = "http://www.w3.org/1999/xlink";

OMEimage.VERSION = 0.5;

/* My development vocabulary:
	untested: the function has not been run
	tested: the function runs and appears to works as advertised
	comprehensively tested: i've checked the output and side effects fairly throughly
*/

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/


	/************************** Setup Functions ***********************************/


/*****

	OMEimage(...)
		parameters:
			imageID is a database key
			Wavelengths is an array of hashes. Hash keys must contain:
				WaveNum, Emmission, and Fluor
			Stats is a 2d array of hashes. The array is indexed by [wavenum][t].
				Hash keys must contain geomean and sigma.
			Dims is a 6 member array representing dimensions of the 5d image. Members are:
				X,Y,Z,W,T,bpp
				bpp is bits per pixel
			CGI_URL is the url to call to generate a 2d image
			CGI_optionStr will be added to the options passed to the CGI
			default_WBS is optional. If found, it will set the WBS for the image display.
				For now, the image gets one WBS that applies to all stacks in the image.
				B & S of WBS are in terms of constants to functions of geomean and standard dev,
				not hard numbers. See getConvertWBS(...) for more information.
		
	comprehensively tested

*****/


function OMEimage( imageID, Wavelengths, Stats, Dims, CGI_URL, CGI_optionStr, 
	SaveDisplayCGI_URL, default_WBW, default_RGBon, default_isRGB, DatasetID ) {

	// A mild test for valid input
	var goodInput = 1; 
	if( arguments.length < 6 ) 
		goodInput = 0; 
	else {
		if(Dims.length != 6)
			goodInput = 0;
		else
			if(Wavelengths.length != Dims[3] || Stats.length != Dims[3])
				goodInput = 0;
	}

	// Test over. Did you pass?
	if(goodInput == 1)
		this.init(imageID, Wavelengths, Stats, Dims, CGI_URL, CGI_optionStr, 
			SaveDisplayCGI_URL, default_WBW, default_RGBon, default_isRGB, DatasetID );
	else
		alert("Bad initialization parameters given to OMEimage.js");
}

/*****

	realize(SVGparentNode)
		
	comprehensively tested

*****/

OMEimage.prototype.realize = function(SVGparentNode) {
	if(SVGparentNode == null)
		alert("OMEimage.realize() was passed a null parameter.");
	else {
		this.SVGparentNode = SVGparentNode;
		this.buildSVG();
	}
}

/********************* Functions for Interactivity & Utilities ****************************/

/*****

	saveState()
		calls a CGI to save current view settings for this image to the DB

	untested

*****/
OMEimage.prototype.saveState = function() {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	var d = new Array();
	var cWBW = this.getAbsoluteWBWfromWBS( theT );
	for(i in this.Dims) d.push(this.Dims[i]);
	// The purpose of unique is to bypass any browser image caching
	var unique   = Math.random();
	var imageURL = this.SaveDisplayCGI_URL + '&ImageID=' + this.imageID + 
		'&theZ=' + theZ + '&theT=' + theT + "&RGBon=" + this.RGBon.join() +
		'&WBS=' + cWBW.join() + "&isRGB=" + this.inColor + "&Unique=" + unique;
	tmpImg.setAttributeNS(xlinkns, "xlink:href",imageURL);

	this.SVGimageContainer.appendChild(tmpImg);
	this.SVGimageContainer.removeChild(tmpImg);

	return 1;
}

/*****

	saveStateDataset()
		calls a CGI to apply current view settings to all images in dataset

	comprehensively tested

*****/
OMEimage.prototype.saveStateDataset = function() {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	var d = new Array();
	for(i in this.Dims) d.push(this.Dims[i]);
	// The purpose of unique is to bypass any image caching
	var unique   = Math.random();
	var imageURL = this.SaveDisplayCGI_URL + '&DatasetID=' + this.DatasetID + 
		'&theZ=' + theZ + '&theT=' + theT + "&RGBon=" + this.RGBon.join() +
		'&WBS=' + this.WBS.join() + "&isRGB=" + this.inColor + "&Unique=" + unique;
	tmpImg.setAttributeNS(xlinkns, "xlink:href",imageURL);

	this.SVGimageContainer.appendChild(tmpImg);
	this.SVGimageContainer.removeChild(tmpImg);

	return 1;
}

/*****

	updatePic(theZ, theT)
		updates the displayed picture
		returns null if unsuccesful for any reason
		returns the SVG image node if successful
		
	tested

*****/
OMEimage.prototype.updatePic = function(theZ, theT) {
	if(this.Dims == null) return null;

	// check theZ & theT for valid type & range
	if( theZ == null) theZ = 0;
	if( theZ < 0) theZ = 0;
	if( theZ >= this.Dims['Z'] ) theZ = this.Dims['Z'] -1;
	if( theZ != Math.round(theZ) ) theZ = Math.round(theZ);
	if( theT == null) theT = 0;
	if( theT < 0) theT = 0;
	if( theT >= this.Dims['T'] ) theT = this.Dims['T'] -1;
	if( theT != Math.round(theT) ) theT = Math.round(theT);
	
	// turn off display of currently displayed pic
	if(this.oldZ != null && this.oldT != null) // is there an old image?
		if(this.SVGimages[this.oldZ][this.oldT] != null)  // is there Really?
			this.SVGimages[this.oldZ][this.oldT].setAttribute("display","none");
	
	// update ref to displayed pic
	this.oldZ = theZ;
	this.oldT = theT;
	
	// check for availibility of new pic
	if(this.SVGimages[theZ][theT] != null) {
		// turn on the image
		this.SVGimages[theZ][theT].setAttribute("display","inline");
	}
	else {	// create the image
		// I've never had trouble w/ svgDocument not existing. but just in case...
		if(svgDocument == null)
			alert("Big trouble! svgDocument doesn't exist in OMEimage.updatePic! Why is this happening? Alert siah in the OME group at http://sourceforge.net/projects/OME and he'll try to figure out something");
		this.SVGimages[theZ][theT] = svgDocument.createElementNS(svgns,"image");
		this.SVGimages[theZ][theT].setAttribute("width",this.Dims['X']);
		this.SVGimages[theZ][theT].setAttribute("height",this.Dims['Y']);

		// prepare image URL string
	
		// color or RGB?
		var color;
		var cWBS = this.getConvertedWBS4OME_JPEG(theT);
		// make sure Black level and Scale aren't out of range for this time point
		// This has been tested. It don't crash.
		for(i=0;i<4;i++) {
			var wavenum = cWBS[i*3];
			// is black level within bounds?
			if(cWBS[i*3+1]<this.Stats[wavenum][theT]['min'])
				cWBS[i*3+1] = Math.ceil( this.Stats[wavenum][theT]['min'] );
			if(cWBS[i*3+1]>this.Stats[wavenum][theT]['max'])
				cWBS[i*3+1] = Math.floor( this.Stats[wavenum][theT]['max'] );
			// calculate whiteLevel
			var whiteLevel = this.Stats[wavenum][theT]['geomean'] + this.WBS[i*3+2] * this.Stats[wavenum][theT]['sigma'];
			var recalculate = false;
			// is it within bounds?
			if(whiteLevel<this.Stats[wavenum][theT]['min']) {
				whiteLevel = this.Stats[wavenum][theT]['min'];
				recalculate = true;
			}
			if(whiteLevel>this.Stats[wavenum][theT]['max']) {
				whiteLevel = this.Stats[wavenum][theT]['max'];
				recalculate = true;
			}
			if(recalculate) {
				if(whiteLevel - this.Stats[wavenum][theT]['geomean'] == 0)
					whiteLevel += 0.00001;
				cWBS[i*3+2] = 255 / (whiteLevel - this.Stats[wavenum][theT]['geomean']);
			}			
		}
		if( this.inColor == 1 )
			color = "&RGB=" + cWBS.slice(0,9).join();
		else
			color = "&Gray=" + cWBS.slice(9,12).join();
		
		var d=new Array();
		for(i in this.Dims) d.push(this.Dims[i]);

		var imageURL = this.CGI_URL + '?ImageID=' + this.imageID + '&theZ=' + theZ + '&theT=' + 
			theT + '&Dims=' + d.join() + color + "&RGBon=" + this.RGBon +
			'&'+this.CGI_optionStr;
		this.SVGimages[theZ][theT].setAttributeNS(xlinkns, "xlink:href",imageURL);

		this.SVGimageContainer.appendChild(this.SVGimages[theZ][theT]);
	}
	
	return this.SVGimages[theZ][theT];
}

/*****

	makeWBSnative(WBS,theT)
		utility to convert WBS from hard numbers to native format
		returns WBS in native format if successful
		
	comprehensively tested

*****/
OMEimage.prototype.makeWBSnative = function(WBS,theT) {
	if(this.Stats == null || this.Dims == null) return null;

	// input validation check
	if(WBS.length!=12 || theT<0 || theT>this.Dims['T'] || theT != Math.round(theT)) return null;

	// conversion and further validation checks
	for(i=0;i<4;i++) {
		var wavenum = WBS[i*3];
		if(wavenum<0 || wavenum>=this.Dims['W'] || wavenum != Math.round(wavenum) ) return null;
		// set black level
		WBS[i*3+1] = (WBS[i*3+1] + this.Stats[wavenum][theT]['geomean'] )/ this.Stats[wavenum][theT]["sigma"];
		WBS[i*3+1] = Math.round(WBS[i*3+1]);
		if(WBS[i*3+2] == 0) WBS[i*3+2] = 0.00001;
		WBS[i*3+2] = 255/( this.Stats[wavenum][theT]['sigma'] * WBS[i*3+2] );
		WBS[i*3+2] = Math.round(WBS[i*3+2]*100000)/100000;
	}
	return WBS;
}

/*****

	makeWBWnative(WBW,theT)
		utility to convert an absolute WBW to native WBS format
		returns WBS in native format if successful
		
	comprehensively tested

*****/
OMEimage.prototype.makeWBWnative = function(WBW,theT) {
	if(this.Stats == null || this.Dims == null) return null;

	// input validation check
	if(WBW.length!=12 || theT<0 || theT>this.Dims['T'] || theT != Math.round(theT)) return null;

	// conversion and further validation checks
	for(i=0;i<4;i++) {
		var wavenum = WBW[i*3];
		if(wavenum<0 || wavenum>=this.Dims['W'] || wavenum != Math.round(wavenum) ) return null;
		// set black level
		WBW[i*3+1] = (WBW[i*3+1] - this.Stats[wavenum][theT]['geomean'] )/ this.Stats[wavenum][theT]["sigma"];
		WBW[i*3+1] = Math.round(WBW[i*3+1]);
		if(WBW[i*3+2] == 0) WBW[i*3+2] = 0.00001;
		WBW[i*3+2] = (WBW[i*3+2] - this.Stats[wavenum][theT]['geomean']) / this.Stats[wavenum][theT]['sigma'];
		WBW[i*3+2] = Math.round(WBW[i*3+2]*100000)/100000;
	}
	return WBW;
}

/************************** Set Functions ***********************************/

/*****

	setWBS(newWBS)
		newWBS should be in native format
		returns 1 if newWBS is accepted
		returns 0 if newWBS is rejected
		
	comprehensively tested

*****/
OMEimage.prototype.setWBS = function(newWBS) {
	// check newWBS for size, wavenum range, B&S range
	if(newWBS.length!=12) {
		alert("In OMEimage.setWBS, newWBS is incorrect size. Should be 12. Is " + newWBS.length);
		return 0;
	}
	for(i=0;i<4;i++) {
		var C = new Array("red", "green", "blue", "gray");
		if(newWBS[i*3] != Math.round(newWBS[i*3]) ) {
			alert("OMEimage.setWBS called with a WBS containing a wavenumber that's not a whole number. It's gotta be a whole number, not "+newWBS[i*3]+". BTW, it was on channel "+C[i]+".");
			return 0;
		}
		if(newWBS[i*3]<0 || newWBS[i*3]>=this.Dims['W']) {
			alert("In OMEimage.setWBS, newWBS has a wavenum outside of range. wavenum refers to "+C[i]+" channel. Wavenum is "+newWBS[i*3]+". According to the dimensions of this image, the valid range is 0 to "+(this.Dims['W']-1)+".");
			return 0;
		}
		// A native scale of 0 will cause a divide by 0 error. This corrects for that.
		if(newWBS[i*3+2] == 0)
			newWBS[i*3+2] = 0.00001;

	}
	
	// check new WBS for change
	var changeFlag=0; // 0 means no change
	for(i=0;i<12;i++)
		if(newWBS[i]!=this.WBS[i]) {
			changeFlag=1;
			break;
		}

	if(changeFlag) {
		this.WBS = newWBS;
		// erase all images from image array. They must be redrawn with the new WBS.
		// check if initialzation has occured before calling wipe
		if(this.Dims != null) this.wipe();
	}
	return 1;
}

/*****

	setDisplayRGB_BW(val)
		Makes the image display in color or grayscale
		val = true ? RGB : BW
		
	comprehensively tested
		
*****/
OMEimage.prototype.setDisplayRGB_BW = function(val) {
	if(val) {	// mode = RGB
		if(!this.inColor) {
			this.inColor = 1;
			// check if initialzation has occured before calling wipe
			if(this.Dims != null) this.wipe();
		}
	}
	else {	// mode = BW
		if(this.inColor) {
			this.inColor = 0;
			// check if initialzation has occured before calling wipe
			if(this.Dims != null) this.wipe();
		}
	}
}

/*****

	setPreload(a)
		turns on and off preload option
		call it with 0 to turn off
		call it with 1 to turn on
		
	tested

*****/
OMEimage.prototype.setPreload = function(a) {
	if(a) {
		this.preload = 1;
		// check if initialzation has occured before calling loadAllPics
		if(this.Dims != null) this.loadAllPics();
	}
	else
		this.preload = 0;
}

/*****

	setRGBon(RGBon)
		turns RGB channels on and off
		
	comprehensively tested

*****/
OMEimage.prototype.setRGBon = function(RGBon) {
	// test input validity
	if(RGBon.length != 3) return;
	for(i in RGBon)
		if(RGBon[i] != 0 && RGBon[i] != 1) return;

	// input looks good
	var changeFlag = 0;
	for(i in this.RGBon)
		if(this.RGBon[i] != RGBon[i]) {
			changeFlag=1;
			break;
		}

	if(changeFlag) {
		this.RGBon = RGBon;
		// check if initialzation has occured before calling wipe
		if(this.Dims != null) this.wipe();
	}
}

/************************** Get Functions ***********************************/

/*****

	getRGBon()
		returns on/off states of the RGB channels
	
	comprehensively tested
	
*****/
OMEimage.prototype.getRGBon = function() {
	// return a COPY
	return this.RGBon.join().split(',');
}


/*****

	getWavelengths()
		
	comprehensively tested

*****/
OMEimage.prototype.getWavelengths = function() {
	// return a COPY
	return this.Wavelengths.join().split(',');
}

/*****

	getWBS()
		returns WBS in native format
		
		WBS in native format is an array of size 12. It is divided into 4 
	chunks of 3. Each chunk represents information for a display channel. The
	chunks correspond to display channels Red, Green, Blue, and Grey, 
	respectively. The format of each chunk is Wavenumber, Black Level, Scale.
	Black Level and Scale are relative to the geometric mean and sigma of pixel
	values for a pixel XYZ stack specified by a Wavenumber and Timepoint. See
	getConvertedWBS4OME_JPEG for more information on Black Level and Scale.
		Wavenumber is a depricated name that is now called 'ChannelNumber' by
	the rest of the OME system)
		
	comprehensively tested

*****/
OMEimage.prototype.getWBS = function() {
	if(this.WBS == null)
		this.WBS = this.makeWBS();
	// return a COPY of the WBS array
	return this.WBS.join().split(',');
}

/*****

	getConvertedWBS4OME_JPEG(theT)
		converts WBS from native format to hard numbers suitable for OME_JPEG
		Currently it uses these functions.
		c indicates converted, n indicates native
			cB = geomean * nB
			cS = 255 / ( sigma * nS )
		White level in OME_JPEG is geomean + sigma*nS
		returns null if unsuccessful
		returns converted WBS if successful
		
	comprehensively tested

*****/
OMEimage.prototype.getConvertedWBS4OME_JPEG = function(theT) {
	if(this.Stats == null || this.Dims == null) return null;

	// input validation check
	if(theT<0 || theT>this.Dims['T'] || theT != Math.round(theT)) return null;
	
	var cWBS = new Array();
	
	for(var i=0;i<4;i++) {
		var wavenum = this.WBS[i*3];
		cWBS.push( wavenum );
		B = this.Stats[wavenum][theT]["geomean"] + this.Stats[wavenum][theT]["sigma"] * this.WBS[i*3+1];
		B = Math.round( B );
		cWBS.push( B );
		if(this.WBS[i*3+2] == 0)
			this.WBS[i*3+2] = 0.00001;
		S = 255/ ( this.Stats[wavenum][theT]["sigma"] * this.WBS[i*3+2] );
		S = Math.round( S*100000 ) / 100000;
		cWBS.push( S );		
	}
	
	return cWBS;
}

/*****

	getAbsoluteWBWfromWBS(theT)
		converts WBS from native format to WBW absolute numbers
		WBW means Wavenumber, Black Level, White Level. See getWBS for more 
	info on layout of the array.
		White level in OME_JPEG is geomean + sigma*nS
		returns null if unsuccessful
		returns converted WBS if successful
		
	comprehensively tested

*****/
OMEimage.prototype.getAbsoluteWBWfromWBS = function(theT) {
	if(this.Stats == null || this.Dims == null) return null;

	// input validation check
	if(theT<0 || theT>this.Dims['T'] || theT != Math.round(theT)) return null;
	
	var cWBW = new Array();
	
	for(var i=0;i<4;i++) {
		var wavenum = this.WBS[i*3];
		cWBW.push( wavenum );
		B = this.Stats[wavenum][theT]["geomean"] + this.Stats[wavenum][theT]["sigma"] * this.WBS[i*3+1];
		B = Math.round( B );
		cWBW.push( B );
		if(this.WBS[i*3+2] == 0)
			this.WBS[i*3+2] = 0.00001;
		W = this.Stats[wavenum][theT]["geomean"] + this.Stats[wavenum][theT]["sigma"] * this.WBS[i*3+2];
		W = Math.round( W );
		cWBW.push( W );		
	}
	
	return cWBW;
}

/*****

	getDisplayRGB_BW()
		returns 1 if display is color, 0 if display is b/w
		
	comprehensively tested
		
*****/
OMEimage.prototype.getDisplayRGB_BW = function() {
	return this.inColor;
}


/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/
/*	init(...), buildSVG(), loadAllPics(), makeWBS(), wipe() */

/*****

	init(...)
		see constructor for more information
		
	comprehensively tested

*****/
OMEimage.prototype.init = function( imageID, Wavelengths, Stats, Dims,  CGI_URL, CGI_optionStr,
	SaveDisplayCGI_URL, default_WBW, default_RGBon, default_isRGB, DatasetID ) {
	// set variables
	this.DatasetID          = DatasetID
	this.imageID            = imageID;
	this.Wavelengths        = Wavelengths;
	this.Stats              = Stats;
	this.CGI_URL            = CGI_URL;
	this.CGI_optionStr      = CGI_optionStr;
	this.SaveDisplayCGI_URL = SaveDisplayCGI_URL;
	this.Dims               = new Array();
	this.Dims['X']          = Dims[0];
	this.Dims['Y']          = Dims[1];
	this.Dims['Z']          = Dims[2];
	this.Dims['W']          = Dims[3];
	this.Dims['T']          = Dims[4];
	this.Dims['bpp']        = Dims[5];
	
	// set optional variable
	if( default_WBW != null )
		this.WBS = this.makeWBWnative( default_WBW, theT );
	else
		this.WBS = this.makeWBS();

	// make SVGimages array. It is indexable by [z][t]
	this.SVGimages = new Array(this.Dims['Z']);
	for(var i=0;i<this.SVGimages.length;i++)
		this.SVGimages[i] = new Array(this.Dims['T']);

	this.inColor = (default_isRGB != null ? default_isRGB : 1 );
	if( default_RGBon != null )
		this.RGBon = default_RGBon;
	else {
		this.RGBon = new Array();
		for(i=0;i<3;i++)
			if(i<this.Dims['W'])
				this.RGBon.push(1);
			else
				this.RGBon.push(0);
	}			
}

/*****

	buildSVG()
		Creates SVG elements and all that junk

	comprehensively tested

*****/
OMEimage.prototype.buildSVG = function() {
	// make image container
	// I've never had trouble w/ svgDocument not existing. but just in case...
	if(svgDocument == null)
		alert("Big trouble! svgDocument doesn't exist in OMEimage.buildSVG! Why is this happening? Alert siah in the OME group at http://sourceforge.net/projects/OME and he'll try to figure out something");
	this.SVGimageContainer = svgDocument.createElementNS(svgns,'g');

	// put image container in this.SVGparentNode
	this.SVGparentNode.appendChild(this.SVGimageContainer);

}

/*****

	loadAllPics()
		preloads the pics
		
	comprehensively tested
	
*****/

OMEimage.prototype.loadAllPics = function() {
	for(var theZ=0;theZ<this.Dims['Z'];theZ++)
		for(var theT=0;theT<this.Dims['T'];theT++)
			if(this.SVGimages[theZ][theT] == null) { // if the image is not loaded yet...
				// I've never had trouble w/ svgDocument not existing. but just in case...
				if(svgDocument == null)
					alert("Big trouble! svgDocument doesn't exist in OMEimage.updatePic! Why is this happening? Alert siah in the OME group at http://sourceforge.net/projects/OME and he'll try to figure out something");
				this.SVGimages[theZ][theT] = svgDocument.createElementNS(svgns,"image");
				this.SVGimages[theZ][theT].setAttribute("width",this.Dims['X']);
				this.SVGimages[theZ][theT].setAttribute("height",this.Dims['Y']);
				this.SVGimages[theZ][theT].setAttribute("display","none");
		
				// prepare image URL string
				
				// color or RGB?
				var color;
				var WBS = this.getConvertedWBS4OME_JPEG(theT);
				if( this.inColor == 1 )
					color = "&RGB=" + WBS.slice(0,9).join();
				else
					color = "&Gray=" + WBS.slice(9,12).join();
				
				var d=new Array();
				for(i in this.Dims) d.push(this.Dims[i]);
		
				var imageURL = this.CGI_URL + '?ImageID=' + this.imageID + '&theZ=' + theZ + '&theT=' + 
					theT + '&Dims=' + d.join() + color + "&RGBon=" + this.RGBon +
					'&'+this.CGI_optionStr;
				this.SVGimages[theZ][theT].setAttributeNS(xlinkns, "xlink:href",imageURL);

				this.SVGimageContainer.appendChild(this.SVGimages[theZ][theT]);
			}
}

/*****

	makeWBS()
		makes WBS array to default parameters 
		
	comprehensively tested

*****/
OMEimage.prototype.makeWBS = function() {
	var i, WBS, waves, L;
	WBS = new Array();
	waves = new Array();
	
	L = this.Wavelengths.length;
	waves.push( this.Wavelengths[0]["WaveNum"] ); // red
	waves.push( this.Wavelengths[Math.floor(L/2)]["WaveNum"] ); // green
	waves.push( this.Wavelengths[L-1]["WaveNum"] ); // blue
	waves.push( this.Wavelengths[0]["WaveNum"] ); // gray
	
	for(i=0;i<4;i++) {
		WBS.push( waves[i] );
		WBS.push( 0 );
		WBS.push( 4 );
	}
	
	return WBS;
}

/*****

	wipe()
		erases all cached images and redraws current image
		
	tested

*****/

OMEimage.prototype.wipe = function() {
	// erase all images from image array.
	for(i in this.SVGimages)
		for(j in this.SVGimages[i]) {
			if(this.SVGimages[i][j]!= null) {
				this.SVGimageContainer.removeChild(this.SVGimages[i][j]);
				this.SVGimages[i][j] = null;
			}
		}
		
	// redraw
	this.updatePic(this.oldZ,this.oldT);
	if(this.preload) this.loadAllPics();
}
