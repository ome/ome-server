/*****
*
*	XYPlaneControls.js

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

XYPlaneControls.prototype.toolboxApperance = {
	x: 0,
	y: 0, 
	width: 400, 
	height: 80,
	menuBarText: skinLibrary["roundGreenMenuBar"],
	hideControlText: skinLibrary["ovalSquishHideControl"],
	GUIboxText: skinLibrary["greenGradientGUIbox"],
	noclip: 'noclip'
};

/*****
	XYPlaneControls
*****/
function XYPlaneControls( urls, image, stats, prefs, overlays ) {
	this.init( urls, image, stats, prefs, overlays );
}

XYPlaneControls.prototype.init = function( urls, image, stats, prefs, overlays ) {
	this.urls  = urls;
	this.image = image;
	this.stats = stats;
	this.prefs = prefs;
	this.overlays = overlays;
	
	this.image.registerListener( 'theZ', this, 'sync_z' );
	this.image.registerListener( 'theT', this, 'sync_t' );
	this.image.registerListener( 'updatePlane', this, 'updatePlaneURL' );
};

XYPlaneControls.prototype.buildToolBox = function( toolboxLayer ) {
	var displayContent = this.buildDisplay();
	this.toolBox = new toolBox( this.toolboxApperance );
	this.toolBox.setLabel(2, 2, "Plane");
	this.toolBox.getLabel().setAttribute("text-anchor", "start");
	this.toolBox.getLabel().setAttribute("dominant-baseline", "hanging");
	this.toolBox.realize( toolboxLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( displayContent );
	
	// initialize 'View Plane' link
	this.updatePlaneURL();
};

XYPlaneControls.prototype.updatePlaneURL = function ( ) {
	this.saveAsTIFFLink.setAttributeNS( xlinkns, 'href', this.image.getImageURL() );
};



XYPlaneControls.prototype.buildDisplay = function(  ) {

	this.displayContent = Util.createElementSVG( "g" );

	// Z section controls
	this.zLabel = Util.createTextSVG( 'Z-slice (n/Z)', {
		x: 10,
		y: 4,
		'dominant-baseline': 'hanging',
		fill: 'indigo'
	} );
	this.displayContent.appendChild( this.zLabel );
	this.zDownButton = new button(
		150, 10,
		zDown,
		skinLibrary["triangleLeftWhite"],
		undefined,
		skinLibrary["triangleLeftRed"]
	);
	this.zDownButton.realize(this.displayContent);
	this.zUpButton = new button(
		154, 10, 
		zUp,
		skinLibrary["triangleRightWhite"],
		undefined,
		skinLibrary["triangleRightRed"]
	);
	this.zUpButton.realize(this.displayContent);
	this.zAnimDownButton = new button(
		180, 10, 
		zAnimDown,
		skinLibrary["triangleLeftRed"],
		undefined,
		skinLibrary["triangleLeftWhite"]
	);
	this.zAnimDownButton.realize(this.displayContent);
	this.zAnimUpButton = new button(
		184, 10, 
		zAnimUp,
		skinLibrary["triangleRightRed"],
		undefined,
		skinLibrary["triangleRightWhite"]
	);
	this.zAnimUpButton.realize(this.displayContent);
	this.zSlider = new Slider(
		10, 20, 180, 0,
		{ obj: this.image, method: 'theZ' },
		skinLibrary["thinSliderBody"],
		skinLibrary["thinSliderThumb"]
	);
	this.zSlider.realize(this.displayContent);
	this.zSlider.setMinmax( 0, (this.image.getDimZ() - 1), false );

	// Timepoint controls
	this.tLabel = Util.createTextSVG( 'Time (n/T)', {
		x: 210,
		y: 4,
		'dominant-baseline': 'hanging',
		fill: 'indigo'
	} );
	this.displayContent.appendChild( this.tLabel );
	this.tDownButton = new button(
		350, 10,
		tDown,
		skinLibrary["triangleLeftWhite"]
	);
	this.tDownButton.realize(this.displayContent);
	this.tUpButton = new button(
		354, 10,
		tUp,
		skinLibrary["triangleRightWhite"]
	);
	this.tUpButton.realize(this.displayContent);
	this.tAnimDownButton = new button(
		380, 10, 
		tAnimDown,
		skinLibrary["triangleLeftRed"],
		null,
		skinLibrary["triangleLeftWhite"]
	);
	this.tAnimDownButton.realize(this.displayContent);
	this.tAnimUpButton = new button(
		384, 10, 
		tAnimUp,
		skinLibrary["triangleRightRed"],
		null,
		skinLibrary["triangleRightWhite"]
	);
	this.tAnimUpButton.realize(this.displayContent);
	this.tSlider = new Slider(
		210, 20, 180, 0,
		{ obj: this.image, method: 'theT' },
		skinLibrary["thinSliderBody"],
		skinLibrary["thinSliderThumb"]
	);
	this.tSlider.realize(this.displayContent);
	this.tSlider.setMinmax( 0, (this.image.getDimT() - 1), false );

	// Image commands
	this.displayContent.appendChild( 
		Util.createTextSVG( 'Image:', {
			x: 4,
			y: 50,
			fill: 'indigo',
			style: 'font-size: 14pt'
		} )
	);
	this.displayContent.appendChild( Util.createTextLinkSVG( {
		href: this.urls[ 'imageInfo' ],
		attrs: { target: 'imageInfo' },
		text: 'Info',
		text_attrs: {
			x: 55,
			y: 50,
			fill: 'black',
			'text-decoration': 'underline'
		}
	} ) );
	this.statsButton = new button( 
		85, 50, 
		{ obj: this.stats.toolBox, method: 'unhide' },
		'<text fill="black" text-decoration="underline">Stats</text>'
	);
	this.statsButton.realize( this.displayContent );
	this.saveSettingsButton = new button( 
		122, 50, 
		{ obj: this.image, method: 'saveState' },
		'<text fill="black" text-decoration="underline">Save settings</text>'
	);
	this.saveSettingsButton.realize( this.displayContent );
	this.saveAsTIFFLink = new Util.createTextLinkSVG( {
		href: this.image.getImageURL(),
		text: 'Save as TIFF...',
		text_attrs: {
			x: 211,
			y: 50,
			fill: 'black',
			'text-decoration': 'underline'
		}
	} );
	this.displayContent.appendChild( this.saveAsTIFFLink );

	this.prefetchButton = new button( 
		300, 50, 
		{ obj: this.image, method: 'prefetchImages' },
		'<text fill="black" text-decoration="underline">Preload planes</text>'
	);
	this.prefetchButton.realize( this.displayContent );
 	
	this.prefsButton = new button( 
		10, 70, 
		{ obj: this.prefs.toolBox, method: 'unhide' },
		'<text fill="black" text-decoration="underline">Resize Toolboxes</text>'
	);
	this.prefsButton.realize( this.displayContent );

	if( this.overlays ) {
		this.overlaysButton = new button( 
			130, 70, 
			{ obj: this.overlays.toolBox, method: 'unhide' },
			'<text fill="black" text-decoration="underline">Overlays</text>'
		);
		this.overlaysButton.realize( this.displayContent );
	}

	return this.displayContent;

};

XYPlaneControls.prototype.sync = function () {
	this.sync_z();
	this.sync_t();
}
XYPlaneControls.prototype.sync_z = function () {
	this.zSlider.setValue( this.image.theZ() );
	this.zLabel.firstChild.data = 'Z-slice: (' + (this.image.theZ() + 1) + "/" + this.image.getDimZ() + ')';
}
XYPlaneControls.prototype.sync_t = function () {
	this.tSlider.setValue( this.image.theT() );
	this.tLabel.firstChild.data = "Timepoint: (" + (this.image.theT()+1) + "/" + this.image.getDimT() +")";
}
