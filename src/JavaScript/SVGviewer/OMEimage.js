/*****
	OMEimage.js


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

svgns = "http://www.w3.org/2000/svg";
xlinkns  = "http://www.w3.org/1999/xlink";

OMEimage.VERSION = .2;

/********************************************************************************************/
/*                                 Public Functions */
/********************************************************************************************/

/************************** Setup Functions ***********************************/

/*****

	OMEimage (constructor)
		parameters:
			imageID is a database key
			Stats is a 2d array of hashes. The array is indexed by [channel index][t].
				Hash keys must contain geomean and geosigma  ( sigma).
			Dims is a 6 member array representing dimensions of the 5d image. Members are:
				X,Y,Z,W,T,bpp
				bpp is bits per pixel
			CGI_URL is the url to call to generate a 2d image
			CGI_optionStr will be added to the options passed to the CGI
			CBW contains Pixel Channel, Black Level, and White level for each RGB-grey display channel.
			RGBon is a boolean array, indicating which RGB channels are enabled.
			isRGB is a boolean value, indication if display is set to RGB or Greyscale

*****/
function OMEimage( imageID, Stats, Dims, CGI_URL, CGI_optionStr, 
	SaveDisplayCGI_URL, CBW, RGBon, isRGB ) {

	this.init(imageID, Stats, Dims, CGI_URL, CGI_optionStr, 
		SaveDisplayCGI_URL, CBW, RGBon, isRGB );
		
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
	for(i in this.Dims) d.push(this.Dims[i]);
	// The purpose of unique is to bypass any browser image caching
	var unique   = Math.random();
	var imageURL = this.SaveDisplayCGI_URL + '&ImageID=' + this.imageID + 
		'&theZ=' + theZ + '&theT=' + theT + "&RGBon=" + this.RGBon.join() +
		'&CBW=' + this.CBW.join() + "&isRGB=" + this.inColor + "&Unique=" + unique;
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

	// turn off display of currently displayed pic
	if(this.oldZ !== undefined && this.oldT !== undefined && this.SVGimages[this.oldZ][this.oldT])
		this.SVGimages[this.oldZ][this.oldT].setAttribute("display","none");
	
	// update indexes
	this.oldZ = theZ; this.oldT = theT;
	
	// retrieve image from cache if possible
	if(this.SVGimages[theZ][theT] !== undefined) {
		this.SVGimages[theZ][theT].setAttribute("display","inline");
	}
	else {	// load the plane
		return this.loadPlane(theZ, theT);
	}
	
	return this.SVGimages[theZ][theT];
};


OMEimage.prototype.loadPlane = function(theZ, theT, invisible) {
	// color or RGB?
	var colorStr;
	var CBS = this.getCBS(theT);
	if( this.inColor == 1 )
		colorStr = "&RGB=" + CBS.slice(0,9).join(',');
	else
		colorStr = "&Gray=" + CBS.slice(9,12).join(',');
	
	// Dims is an associative array. join won't work on it.
	var d=new Array();
	for(i in this.Dims) d.push(this.Dims[i]);
	
	var imageURL = this.CGI_URL + '?ImageID=' + this.imageID + '&theZ=' + theZ + '&theT=' + 
		theT + '&Dims=' + d.join(',') + colorStr + "&RGBon=" + this.RGBon +
		'&'+this.CGI_optionStr;
	
	this.SVGimages[theZ][theT] = createElementSVG( 'image', {
		width: this.Dims['X'],
		height: this.Dims['Y'],
		display: (invisible ? 'none' : 'inline')
	});
	this.SVGimages[theZ][theT].setAttributeNS(xlinkns, "href",imageURL);
	this.SVGimageContainer.appendChild(this.SVGimages[theZ][theT]);
	return this.SVGimages[theZ][theT];
};


/************************** Set Functions ***********************************/

/*****

	setCBW(CBW)
		returns 1 if CBW is accepted
		returns 0 if CBW is rejected

*****/
OMEimage.prototype.setCBW = function(CBW) {
	// check new CBW for change
	var changeFlag=0; // 0 means no change
	for(i=0;i<12;i++)
		if(CBW[i]!=this.CBW[i]) {
			changeFlag=1;
			break;
		}

	if(changeFlag) {
		this.CBW = CBW;
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
			// check if initialization has occured before calling wipe
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
	setPreload(preloadOn)
		turns on and off preload option
*****/
OMEimage.prototype.setPreload = function(preloadOn) {
	if(preloadOn) {
		this.preload = true;
		// check if initialzation has occured before calling loadAllPics
		if(this.Dims != null) this.loadAllPics();
	}
	else {
		this.preload = false;
	}
}


/*****
	prefetchImages(prefetchImages)
		prefetches all the pictures
*****/
OMEimage.prototype.prefetchImages = function() {
	if( !this.preloadOn ) {
		this.setPreload(true);
		this.setPreload(false);
	}
}


/*****
	setRGBon(RGBon)
		turns RGB channels on and off
*****/
OMEimage.prototype.setRGBon = function(RGBon) {	
	if(!this.initialized) return;
	var changeFlag = 0;
	for(i in this.RGBon)
		if(this.RGBon[i] != RGBon[i]) {
			changeFlag=1;
			break;
		}

	if(changeFlag) {
		this.RGBon = RGBon;
		this.wipe();
	}
}

/************************** Get Functions ***********************************/

/*****
	getRGBon()
		returns on/off states of the RGB channels	
*****/
OMEimage.prototype.getRGBon = function() {
	// return a COPY
	return this.RGBon.join().split(',');
}


/*****

	getCBW()
		returns Channel-BlackLevel-WhiteLevel array
		
		CBW is an array of length 12. It is divided into 4 
	chunks of 3. Each chunk represents information for a display channel. The
	chunks correspond to display channels Red, Green, Blue, and Grey, 
	respectively. The format of each chunk is Channel Index, Black Level, White Level.

*****/
OMEimage.prototype.getCBW = function() {
	return this.CBW.join().split(',');
}


/*****

	getCBS(theT)
		converts Channel-BlackLevel-WhiteLevel array to Channel-BlackLevel-Scale array and performs bounds checking

*****/
OMEimage.prototype.getCBS = function(theT) {
	
	var CBS = new Array();
	
	for(var i=0;i<4;i++) {
		var lci = this.CBW[i*3]; // logical channel index
		CBS.push( lci );
		B = this.CBW[i*3+1];
		if( B < this.Stats[lci][theT]["min"] )
			B = this.Stats[lci][theT]["min"];
// is this rounding necessary?
		B = Math.round( B );
		CBS.push( B );
		var delta_B_W = this.CBW[i*3+2] - B;
		if ( delta_B_W == 0 ) delta_B_W = 0.00001;
		S = 255 / delta_B_W;
		S = Math.round( S*100000 ) / 100000;
		CBS.push( S );		
	}
	
	return CBS;
}


/*****
	isInColor()
		returns 1 if display is color, 0 if display is b/w
*****/
OMEimage.prototype.isInColor = function() {
	return this.inColor;
}


/********************************************************************************************/
/*                                 Private Functions */
/********************************************************************************************/

/*****

	init
		see constructor for information on parameters
		
*****/
OMEimage.prototype.init = function( imageID, Stats, Dims,  CGI_URL, CGI_optionStr,
	SaveDisplayCGI_URL, default_CBW, default_RGBon, default_isRGB ) {
	// set variables
	this.imageID            = imageID;
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
	this.CBW = default_CBW;
	this.inColor = default_isRGB;
	this.RGBon = default_RGBon;

	// make SVGimages array. It is indexable by [z][t]
	this.SVGimages = new Array(this.Dims['Z']);
	for(var i=0;i<this.SVGimages.length;i++)
		this.SVGimages[i] = new Array(this.Dims['T']);

	for(var c in Stats) {
		for( var t in Stats[c] ) {
			if( this._gMin != null || this._gMin > Stats[c][t]['min'] )
				this._gMin = Stats[c][t]['min'];
			if( this._gMax != null || this._gMax < Stats[c][t]['max'] )
				this._gMax = Stats[c][t]['max'];
		}
	}

			
}

/*****

	buildSVG()
		Creates SVG elements and all that junk

*****/
OMEimage.prototype.buildSVG = function() {
	// make image container
	// I've never had trouble w/ svgDocument not existing. but just in case...
	this.SVGimageContainer = svgDocument.createElementNS(svgns,'g');

	// put image container in this.SVGparentNode
	this.SVGparentNode.appendChild(this.SVGimageContainer);

}

/*****

	loadAllPics()
		preloads the pics
		
*****/

OMEimage.prototype.loadAllPics = function() {
	for(var theZ=0;theZ<this.Dims['Z'];theZ++) {
		for(var theT=0;theT<this.Dims['T'];theT++) {
			if(this.SVGimages[theZ][theT] == null) { // if the image is not loaded yet...
				this.loadPlane(theZ, theT, true);
			}
		}
	}
}


/*****

	wipe()
		erases all cached images and redraws current image
		
*****/

OMEimage.prototype.wipe = function() {
	// erase all images from image array.
	for(i in this.SVGimages)
		for(j in this.SVGimages[i]) {
			if(this.SVGimages[i][j]!== undefined) {
				this.SVGimageContainer.removeChild(this.SVGimages[i][j]);
				this.SVGimages[i][j] = undefined;
			}
		}
		
	// redraw
	this.updatePic(this.oldZ,this.oldT);
	if(this.preload) this.loadAllPics();
}
