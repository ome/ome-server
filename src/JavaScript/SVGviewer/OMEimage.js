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

var svgns = "http://www.w3.org/2000/svg";
var xlinkns  = "http://www.w3.org/1999/xlink";

/********************************************************************************************
                                 Class Data
********************************************************************************************/

/* 	Map from display channel name to indexes in the CBW array. */
/*	Index positions store the logical channel number mapped to the display channel. */
OMEimage.prototype._CBW_dispCh = {
	r: 0,
	g: 3,
	b: 6,
	grey: 9
};
/* Map from display channel name to indexes in the RGB-on/off array. */
OMEimage.prototype._dispCh_RGB_onOff = {
	r: 0,
	g: 1,
	b: 2
};


/********************************************************************************************
                                 Public Functions
********************************************************************************************/

/*****

	OMEimage (constructor)
		parameters:
			imageID is a database key
			Stats is a 2d array of hashes. The array is indexed by [channel index][t].
				Hash keys must contain geomean and geosigma  ( sigma).
			Dims is a 6 member array representing dimensions of the 5d image. Members are:
				X,Y,Z,C,T,bpp
				bpp is bits per pixel
			CGI_URL is the url to call to generate a 2d image
			SaveDisplayCGI_URL is a url that will accept display
				parameters and save them to the db
			CBW contains a 3 element chunk for each display channel (r, g, b, & grey).
				the 3 elements are: Pixel Channel, Black Level, and White level
			RGBon is a boolean array, indicating which RGB channels are
				enabled.
			isRGB is a boolean value, indication if display is set to
				RGB or Greyscale
			imageServerID is the Image Server's Pixels ID of the pixels
				being displayed

*****/
function OMEimage( imageID, pixelsID, Stats, Dims, CGI_URL, 
                   SaveDisplayCGI_URL, CBW, RGBon, isRGB,
                   imageServerID, theZ, theT ) {
	this.init( imageID, pixelsID, Stats, Dims, CGI_URL, SaveDisplayCGI_URL, CBW, RGBon, isRGB, imageServerID, theZ, theT );
}

/*****
	realize(SVGparentNode)
		initialize the graphical objects into SVGparentNode
*****/
OMEimage.prototype.realize = function(SVGparentNode) {
	this.SVGparentNode = SVGparentNode;
	this.buildSVG();
	this.updatePlane();
};

/*****
	saveState()
		calls a CGI to save current view settings for this image to the DB
*****/
OMEimage.prototype.saveState = function() {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	// The purpose of unique is to bypass any browser image caching.
	var date = new Date();
	var unique   = date.getSeconds() + '' + date.getUTCMilliseconds();
	var imageURL = this.SaveDisplayCGI_URL + '&ImageID=' + this.imageID + 
		'&theZ=' + this.theZ() + '&theT=' + this.theT() + "&RGBon=" + this.RGBon.join() +
		'&CBW=' + this.getCBW().join() + "&isRGB=" + ( this.colorDisplay() ? 1 : 0 ) + "&Unique=" + unique + 
		'&PixelsID=' + this.pixelsID;
	tmpImg.setAttributeNS(xlinkns, "href",imageURL);
Util.err( imageURL.replace( /&/g, '@' ) );

	this.SVGimageContainer.appendChild(tmpImg);
	this.SVGimageContainer.removeChild(tmpImg);
	
	this.saveStateThumb();

	return 1;
};

/* makes array storing color-channel map, black, and white levels. Used
to support legacy data formatting. */
OMEimage.prototype.getCBW = function() {
	var CBW = new Array(
		this.color_map( 'r' ),
		this.black_level( 'r' ),
		this.white_level( 'r' ),
		this.color_map( 'g' ),
		this.black_level( 'g' ),
		this.white_level( 'g' ),
		this.color_map( 'b' ),
		this.black_level( 'b' ),
		this.white_level( 'b' ),
		this.color_map( 'grey' ),
		this.black_level( 'grey' ),
		this.white_level( 'grey' )
	);
	return CBW;
}

/*****
	saveStateThumb()
		calls a CGI to save current view settings to the thumbnail
*****/
OMEimage.prototype.saveStateThumb = function() {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	var imageURL = this.getCompositeURL( theZ, theT ) + '&SetThumb=1';
	tmpImg.setAttributeNS(xlinkns, "href",imageURL);

	this.SVGimageContainer.appendChild(tmpImg);
	this.SVGimageContainer.removeChild(tmpImg);
};


/*****
	updatePlane()
		updates the displayed plane
*****/
OMEimage.prototype.updatePlane = function() {
	if( this.Dims === null || this.paused() ) { return null; }

	// turn off display of currently displayed pic
	if( this.SVGimages[this._oldZ][this._oldT] ) {
		this.SVGimages[this._oldZ][this._oldT].setAttribute("display","none");
	}
	this._oldZ = this._theZ;
	this._oldT = this._theT;
	
	// retrieve image from cache if possible
	if(this.SVGimages[this._theZ][this._theT] !== undefined) {
		this.SVGimages[this._theZ][this._theT].setAttribute("display","inline");
	}
	else {	// load the plane
		this.loadPlane(this._theZ, this._theT);
	}
	
	this.broadcast( 'updatePlane' );
};

/*******
registerListener( event, obj, method, method_params )
	mimics DOM event listeners. When event happens, method is called
	on obj with params.

update the white level slider when the white level changes for the red display channel
	image.registerListener( 'r_W', channel_Control_GUI, 'W_sync', ['r'] );

When the white level for the red display channel is modified, 
	channel_Control_GUI.W_sync( 'r' );
will be eval'ed.
	
recognized events are: 
	r_W, g_W, b_W, grey_W: called when the white level of a display channel is changed
	r_B, g_B, b_B, grey_B: called when the black level of a display channel is changed
	r_ch, g_ch, b_ch, grey_ch: called when the logical channel mapped to a display channel is changed
	theZ: called when the Z index is changed
	theT: called when the T index is changed
	updatePlane: called when the Z or T indexes are changed
*******/
OMEimage.prototype.registerListener = function(event, obj, method, method_params) {
	if( ! this.allListeners[ event ] ) { this.allListeners[ event ] = new Array(); }
	this.allListeners[ event ].push( obj, method, method_params );
};


/*******
black_level( disp_ch, b )
	accessor/mutator for the black level of a display channel

what is the black level of the red channel?

	if( image.black_level( 'r' ) ) ...

set the blue channel's black level to 700

	image.black_level( 'b', 700 );

parameters are: 
	disp_ch: should be 'r', 'g', 'b', or 'grey'
	b: the new black level

return value is the black level of the given display channel

note: The new black level may be adjusted. The return value will
always be the actual black level.

*******/
OMEimage.prototype.black_level = function(disp_ch, b) {
	var ch = this.color_map( disp_ch )
	if( b && b !== this.getB( ch ) ) {
		b = Math.round( b );
		// don't let the black level be bigger than the white level
		b = Math.min( b, this.getW( ch ) );
		this.BW_backup[ ch ]['B'] = b;
		this.wipe();
		// send broadcasts to each display channel linked to this logical channel.
		if( this.color_map( 'r' ) == ch ) { this.broadcast( 'r_B' ); }
		if( this.color_map( 'g' ) == ch ) { this.broadcast( 'g_B' ); }
		if( this.color_map( 'b' ) == ch ) { this.broadcast( 'b_B' ); }
		if( this.color_map( 'grey' ) == ch ) { this.broadcast( 'grey_B' ); }
	}
	return this.BW_backup[ ch ]['B'];
}


/*******
white_level( disp_ch, w )
	accessor/mutator for the white level of a display channel

what is the white level of the red channel?

	if( image.white_level( 'r' ) ) ...

set the blue channel's white level to 700

	image.white_level( 'b', 700 );


parameters are: 
	disp_ch: should be 'r', 'g', 'b', or 'grey'
	w: the new white level

return value is the white level of the given display channel	

note: The new white level may be adjusted. The return value will
always be the actual white level.
*******/
OMEimage.prototype.white_level = function(disp_ch, w) {
	var ch = this.color_map( disp_ch )
	if( w && w !== this.getW( ch ) ) {
		w = Math.round( w );
		// don't let the white level be smaller than the black level
		w = Math.max( w, this.black_level( disp_ch ) );
		this.BW_backup[ ch ]['W'] = w;
		this.wipe();
		// send broadcasts to each display channel linked to this logical channel.
		if( this.color_map( 'r' ) == ch ) { this.broadcast( 'r_W' ); }
		if( this.color_map( 'g' ) == ch ) { this.broadcast( 'g_W' ); }
		if( this.color_map( 'b' ) == ch ) { this.broadcast( 'b_W' ); }
		if( this.color_map( 'grey' ) == ch ) { this.broadcast( 'grey_W' ); }
	}
	return this.BW_backup[ ch ]['W'];
}

/*******
color_map( disp_ch, ch )
	accessor/mutator for mapping display channels to logical channels

what is the red channel assigned to?

	if( image.color_map( 'r' ) ) ...

set the blue channel to logical channel 2

	image.color_map( 'b', 2 );	

parameters are: 
	disp_ch: should be 'r', 'g', 'b', or 'grey'
	ch: the new logical channel id

return value is the logical channel assigned to the given display channel	
*******/
OMEimage.prototype.color_map = function( disp_ch, new_ch ) {
	if( new_ch && new_ch !== this._color_map[ disp_ch ] ) {
		this.paused( true );
		this._color_map[ disp_ch ] = new_ch;
		this.black_level( disp_ch, this.getB( new_ch ) );
		this.white_level( disp_ch, this.getW( new_ch ) );
		this.paused( false );
		this.wipe();
		this.broadcast( disp_ch + '_ch' );
	}
	return this._color_map[ disp_ch ];
};

/*******
channel_visible( disp_ch, visible )
	accessor/mutator for the visibility of RGB channels

is the red channel on?

	if( image.channel_visible( 'r' ) ) ...

turn the blue channel off

	image.channel_visible( 'b', false );	

parameters are: 
	disp_ch: should be 'r', 'g', or 'b'
	visible: boolean indicating if the display channel is on or off

return value is visibility of the display channel	
*******/
OMEimage.prototype.channel_visible = function( disp_ch, visible ) {
	var on_i = this._dispCh_RGB_onOff[ disp_ch ];
	if( visible !== undefined ) {
		this.RGBon[ on_i ] = (visible ? 1 : 0);
		this.wipe();
		this.broadcast( disp_ch + '_on' );
	}
	return this.RGBon[ on_i ];
};

OMEimage.prototype.r_ch = function(ch) { return this.color_map( 'r', ch ); }
OMEimage.prototype.g_ch = function(ch) { return this.color_map( 'g', ch ); }
OMEimage.prototype.b_ch = function(ch) { return this.color_map( 'b', ch ); }
OMEimage.prototype.grey_ch = function(ch) { return this.color_map( 'grey', ch ); }

OMEimage.prototype.r_B = function(B) { return this.black_level( 'r', B ); };
OMEimage.prototype.g_B = function(B) { return this.black_level( 'g', B ); };
OMEimage.prototype.b_B = function(B) { return this.black_level( 'b', B ); };
OMEimage.prototype.grey_B = function(B) { return this.black_level( 'grey', B ); };

OMEimage.prototype.r_W = function(W) { return this.white_level( 'r', W ); };
OMEimage.prototype.g_W = function(W) { return this.white_level( 'g', W ); };
OMEimage.prototype.b_W = function(W) { return this.white_level( 'b', W ); };
OMEimage.prototype.grey_W = function(W) { return this.white_level( 'grey', W ); };

OMEimage.prototype.r_on = function(visible) { return this.channel_visible( 'r', visible ); };
OMEimage.prototype.g_on = function(visible) { return this.channel_visible( 'g', visible ); };
OMEimage.prototype.b_on = function(visible) { return this.channel_visible( 'b', visible ); };

/* accessor/mutator for the display being set to RGB color or greyscale.
	accepts and returns boolean values. 
	true indicates a color display
	false indicates a greyscale display
*/
OMEimage.prototype.colorDisplay = function( on_or_off ) { 
	if( on_or_off !== undefined && on_or_off != this._inColor ) {
		this._inColor = on_or_off;
		this.wipe();
		this.broadcast( 'color_display' );
	}
	return this._inColor;
};


/* functions to prevent the displayed pane from being updated */
OMEimage.prototype.paused = function( isPaused ) { 
	if( isPaused ) { this._paused = true; }
	else           { this._paused = false; }
	return this._paused;
}

/* functions to get the Black & White levels for any logical channel.
	the input parameter is the logical channel id */
OMEimage.prototype.getB = function( ch ) { return this.BW_backup[ ch ]['B']; }
OMEimage.prototype.getW = function( ch ) { return this.BW_backup[ ch ]['W']; }

/* message passing for multi-threading. See tAnimDown() and theT() for
example usages. */
OMEimage.prototype.busyWith = function( activity, isBusy ) {
	if( isBusy !== undefined ) {
		this._busyWith[activity] = isBusy;
	}
	if( this._busyWith[activity] === true ) {
		return true;
	} else {
		return false;
	}
}

/* mutator/accessor functions for the Z and T indexes */
OMEimage.prototype.theZ = function( newZ ) {
	if( newZ !== undefined ) {
		this.busyWith( 'theZ', true );
		var inc = newZ - this._theZ;
		if( Math.round( inc ) == 0 ) {
			if( inc < 0 ) { this._theZ -= 1; }
			if( inc > 0 ) {	this._theZ += 1; }
		} else {
			this._theZ = Math.round( newZ );
		}
		this.broadcast( 'theZ' );
	}
	this.busyWith( 'theZ', false );
	return this._theZ;
}
OMEimage.prototype.theT = function( newT ) {
	if( newT !== undefined ) {
		this.busyWith( 'theT', true );
		var inc = newT - this._theT;
		if( Math.round( inc ) == 0 ) {
			if( inc < 0 ) { this._theT -= 1; }
			if( inc > 0 ) {	this._theT += 1; }
		} else {
			this._theT = Math.round( newT );
		}
		this.broadcast( 'theT' );
	}
	this.busyWith( 'theT', false );
	return this._theT;
}

/* dimension read-only accessors */
OMEimage.prototype.getDimX = function() { return this.Dims['X']; };
OMEimage.prototype.getDimY = function() { return this.Dims['Y']; };
OMEimage.prototype.getDimZ = function() { return this.Dims['Z']; };
OMEimage.prototype.getDimC = function() { return this.Dims['C']; };
OMEimage.prototype.getDimT = function() { return this.Dims['T']; };


/*****
	prefetchImages()
		loads and caches every plane in the image
*****/
OMEimage.prototype.prefetchImages = function() {
	for(var theZ=0;theZ<this.Dims['Z'];theZ++) {
		for(var theT=0;theT<this.Dims['T'];theT++) {
			if(this.SVGimages[theZ][theT] == null) { // if the image is not loaded yet...
				this.loadPlane(theZ, theT, true);
			}
		}
	}
}


/********************************************************************************************
                                 Private Functions
********************************************************************************************/

OMEimage.prototype.init = function( imageID, pixelsID, Stats, Dims,  CGI_URL, 
	SaveDisplayCGI_URL, CBW, default_RGBon, default_isRGB, imageServerID, theZ, theT ) {
	this.initialized        = true;
	// set variables
	this.imageID            = imageID;
	this.pixelsID           = pixelsID;
	this.imageServerID      = imageServerID;
	this.Stats              = Stats;
	this.CGI_URL            = CGI_URL;
	this.SaveDisplayCGI_URL = SaveDisplayCGI_URL;
	this.Dims               = new Array();
	this.Dims['X']          = Dims[0];
	this.Dims['Y']          = Dims[1];
	this.Dims['Z']          = Dims[2];
	this.Dims['C']          = Dims[3];
	this.Dims['T']          = Dims[4];
	this.Dims['bpp']        = Dims[5];
	this._inColor           = default_isRGB;
	this.RGBon              = default_RGBon;
	this.allListeners       = new Array();
	this._theZ              = theZ;
	this._theT              = theT;
	this._oldZ              = theZ;
	this._oldT              = theT;

	this._paused             = false;
	this._busyWith          = new Array();

	// make SVGimages array. It is indexable by [z][t]
	this.SVGimages = new Array(this.Dims['Z']);
	this.imageURLs = new Array(this.Dims['Z']);
	for(var i=0;i<this.SVGimages.length;i++) {
		this.SVGimages[i] = new Array(this.Dims['T']);
		this.imageURLs[i] = new Array(this.Dims['T']);
	}

	this.registerListener( 'theT', this, 'updatePlane' );
	this.registerListener( 'theZ', this, 'updatePlane' );

	// black and white levels indexed by channel
	this.BW_backup = new Array();
	this._color_map = new Array();
	// ch: logical channel id
	var ch;
	for(var disp_ch in this._CBW_dispCh) {
		// ch_i is channel index, an index into CBW, that points to the logical channel id mapped to the display channel
		var ch_i = this._CBW_dispCh[ disp_ch ];
		ch = CBW[ch_i];
		this._color_map[ disp_ch ] = ch;
		this.BW_backup[ ch ] = new Array();
		this.BW_backup[ ch ]['B'] = CBW[ ch_i + 1 ];
		this.BW_backup[ ch ]['W'] = CBW[ ch_i + 2 ];
	}
	

	// default black & white level
	this.global_Min = new Array();
	this.global_Max = new Array();
	for( ch in this.Stats) {
		this.global_Min[ch] = this.Stats[ch][0]['min'];
		this.global_Max[ch] = this.Stats[ch][0]['max'];
		for( var t in this.Stats[ch] ) {
			this.global_Min[ch] = Math.min(this.Stats[ch][t]['min'], this.global_Min[ch]);
			this.global_Max[ch] = Math.max(this.Stats[ch][t]['max'], this.global_Max[ch]);
		}
		if( ! this.BW_backup[ ch ] ) {
			this.BW_backup[ ch ] = new Array();
			this.BW_backup[ ch ]['B'] = this.global_Min[ch];
			this.BW_backup[ ch ]['W'] = this.global_Max[ch];
		}
	}

};


/*****
	buildSVG()
		Creates SVG elements
*****/
OMEimage.prototype.buildSVG = function() {
	// make image container & put in in the parent node
	this.SVGimageContainer = svgDocument.createElementNS(svgns,'g');
	this.SVGparentNode.appendChild(this.SVGimageContainer);
}

OMEimage.prototype.loadPlane = function(theZ, theT, invisible) {
	var imageURL = this.getCompositeURL( theZ, theT ) + '&Format=JPEG';
	//imageURLs is used to load high quality image. that means TIFF format
	this.imageURLs[theZ][theT] = this.getCompositeURL( theZ, theT ) + '&Format=TIFF';

	this.SVGimages[theZ][theT] = Util.createElementSVG( 'image', {
		y: 95,
		width: this.Dims['X'],
		height: this.Dims['Y'],
		display: (invisible ? 'none' : 'inline')
	});
	this.SVGimages[theZ][theT].setAttributeNS(xlinkns, "href", imageURL);
	this.SVGimageContainer.appendChild(this.SVGimages[theZ][theT]);
	return this.imageURLs[theZ][theT];
};

OMEimage.prototype.getCompositeURL = function( theZ, theT ) {
	var colorStr = '';
	if( this._inColor ) {
		var ch;
		if( this.channel_visible( 'r' ) ) { 
			ch = this.color_map( 'r' );
			colorStr += '&RedChannel=' + ch + ',' + this.getB( ch ) + ',' + this.getW( ch ) + ',1.0';
		}
		if( this.channel_visible( 'g' ) ) {
			ch = this.color_map( 'g' );
			colorStr += '&GreenChannel=' + ch + ',' + this.getB( ch ) + ',' + this.getW( ch ) + ',1.0';
		}
		if( this.channel_visible( 'b' ) ) {
			ch = this.color_map( 'b' );
			colorStr += '&BlueChannel=' + ch + ',' + this.getB( ch ) + ',' + this.getW( ch ) + ',1.0';
		}
	} else {
		ch = this.color_map( 'grey' );
		colorStr += '&GrayChannel=' + ch + ',' + this.getB( ch ) + ',' + this.getW( ch ) + ',1.0';
	}
	
	return this.CGI_URL + '?theZ=' + theZ + '&theT=' + 
		theT + colorStr + '&PixelsID='+this.imageServerID+'&Method=Composite';
}


OMEimage.prototype.getImageURL = function() {
	if( this.imageURLs[ this.theZ() ][ this.theT() ] ) {
		return this.imageURLs[ this.theZ() ][ this.theT() ];
	} else {
		return '';
	}
}

/*****
	wipe()
		erases all cached images and redraws current image
*****/
OMEimage.prototype.wipe = function() {
	if( !this.initialized ) { return; }

	// erase all images from image array
	for(i in this.SVGimages)
		for(j in this.SVGimages[i]) {
			if(this.SVGimages[i][j]!== undefined) {
				this.SVGimageContainer.removeChild(this.SVGimages[i][j]);
				this.SVGimages[i][j] = undefined;
			}
		}
		
	// redraw current plane
	this.updatePlane();
}

OMEimage.prototype.broadcast = function(func) {
	var listeners = this.allListeners[func];
	if( listeners ) {
		for( var i=0; i < listeners.length; i+=3 ) {
			var obj    = listeners[i];
			var method = listeners[i+1];
			var params = listeners[i+2];

			var param_list;
			if( params ) {
				var p2 = new Array;
				for( var j in params ) {
					p2.push( 'params['+j+']' );
				}
				param_list = '(' + p2.join( ', ' ) + ')';
			} else {
				param_list = '()';
			}
			
			var obj_string = ( obj ? 'obj.' : '' );

			eval( obj_string + method + param_list );
		}
	}
};

/************************************************************************

                        Control Functions

	These require a global instance of OMEimage named 'image'.
Globally defined data is an implementation restriction of setTimeout,
which is used by the animation functions.

************************************************************************/

// Controls (in context of MVC)
function zUp() {
	var theZ = image.theZ();
	if( theZ < image.getDimZ() - 1) { 
		image.theZ( theZ + 1 );
		return true;
	} else {
		return false;
	}
}
function zDown() {
	var theZ = image.theZ();
	if( theZ > 0) { 
		image.theZ( theZ - 1 );
		return true;
	} else {
		return false;
	}
}
function zAnimUp() {
	if( image.busyWith('theZ') ) {
		setTimeout( "zAnimUp()", 100 );
	} else {
		if( zUp() ) {
			setTimeout( "zAnimUp()", 100 );
		}
	}
}
function zAnimDown() {
	if( image.busyWith('theZ') ) {
		setTimeout( "zAnimDown()", 100 );
	} else {
		if( zDown() ) {
			setTimeout( "zAnimDown()", 100 );
		}
	}
}
function setTheZ( newZ ) {
	image.theZ(newZ);
}

function tUp() {
	var theT = image.theT();
	if( theT < image.getDimT() - 1) { 
		image.theT( theT + 1 );
		return true;
	} else {
		return false;
	}
}
function tDown() {
	var theT = image.theT();
	if( theT > 0) { 
		image.theT( theT - 1 );
		return true;
	} else {
		return false;
	}
}
function tAnimUp() {
	if( image.busyWith('theT') ) {
		setTimeout( "tAnimUp()", 100 );
	} else {
		if( tUp() ) {
			setTimeout( "tAnimUp()", 100 );
		}
	}
}
function tAnimDown() {
	if( image.busyWith('theT') ) {
		setTimeout( "tAnimDown()", 100 );
	} else {
		if( tDown() ) {
			setTimeout( "tAnimDown()", 100 );
		}
	}
}
function setTheT( newT ) {
	image.theT(newT);
}
		
