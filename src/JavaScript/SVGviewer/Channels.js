/*****

	Channels.js

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

/********************************************************************************************
                                 Public Functions 

SYNOPSIS
	var channel_control = new Channels( image, channel_labels );
	channel_control.build_toolbox( rendering_layer );

********************************************************************************************/

/*****
	Channels (constructor)
*****/

function Channels(image, channel_labels) {
	this.init(image, channel_labels);
}


/*****
	class constants
*****/
Channels.VERSION = 0.2;
Channels.scaleWidth = 180;
Channels.prototype.toolboxApperance = {
	x: 400,
	y: 0, 
	menuBarText: skinLibrary["greyMenubar"],
	hideControlText: skinLibrary["XhideControl"],
	GUIboxText: '\
<g>\
	<rect width="$width" height="$height" fill="gainsboro" opacity="0.9"/>\
	<text y="2" x="2" dominant-baseline="hanging" font-style="italic">Channel</text>\
	<text y="2" x="{$width - 50}" dominant-baseline="hanging" font-style="italic" text-anchor="end">Black<tspan x="{$width - 50}" dy="1em">Level</tspan></text>\
	<text y="2" x="{$width - 2}" dominant-baseline="hanging" font-style="italic" text-anchor="end">White<tspan x="{$width - 2}" dy="1em">Level</tspan></text>\
</g>\
',
	noclip: true
};
// map display channel names to status bar colors
Channels.prototype.disp_channel_colors = {
	r: 'red',
	g: 'limegreen',
	b: 'mediumslateblue',
	grey: 'grey'
};

// build a toolBox that houses controls. append it to the rendering layer.
Channels.prototype.build_toolbox = function( rendering_layer ) {
	this.rendering_layer = rendering_layer;

	// there is one pane for RGB controls and another for greyscale
	// only one will be visible at a time
	this.colorPane = Util.createElementSVG( 'g' );
	this.greyscalePane = Util.createElementSVG( 'g' );

	/* keep track of control pieces in these arrays. index by display
	   channel names ( r, g, b, grey ) */
	this.ch_lists = new Array();
	this.ch_on_off = new Array();
	this.B_sliders = new Array();
	this.W_sliders = new Array();
	this.B_bars = new Array();
	this.W_bars = new Array();
	this.B_labels = new Array();
	this.W_labels = new Array();
	
	var panes = {
		r: this.colorPane,
		g: this.colorPane,
		b: this.colorPane,
		grey: this.greyscalePane	
	};
	var pane_offset = {
		r: 30,
		g: 65,
		b: 100,
		grey: 30	
	};

	/* make a set of controls for each display channel */
	for( var disp_ch in this.disp_channel_colors ) {
		// colored bar
		panes[ disp_ch ].appendChild( 
			Util.createElementSVG( 'rect', {
				y: pane_offset[ disp_ch ],
				width: Channels.scaleWidth,
				height: 15,
				fill: this.disp_channel_colors[ disp_ch ]
			})
		);
		
		// channel label. doubles as control to switch channels
		this.ch_lists[ disp_ch ] = new popupList(
			0, pane_offset[ disp_ch ], this.channel_labels, 
			{ method: disp_ch+'_ch', obj: this.image },
			undefined,
			skinLibrary["transparentBox"],
			undefined, 
			skinLibrary["whiteTranslucentBox"]
		);
		this.ch_lists[ disp_ch ].realize( panes[ disp_ch ] );
		
		// button to turn display channel off and on
		if( disp_ch != 'grey' ) {
			this.ch_on_off[ disp_ch ] = new button( {
				x: this.ch_lists[ disp_ch ].width, 
				y: pane_offset[ disp_ch ],
				callback: { obj: this.image, method: disp_ch+'_on' },
				onText: '<text y="2" x="4" dominant-baseline="hanging" font-weight="bold" text-decoration="underline" fill="black">On</text>',
				offText: '<text y="2" x="4" dominant-baseline="hanging" font-weight="bold" text-decoration="underline" fill="black">Off</text>',
				highlightText: '<rect width="26" height="15" fill="white"/>'
			} );
			this.ch_on_off[ disp_ch ].realize( panes[ disp_ch ] );
		}
	
		// black level label
		this.B_labels[ disp_ch ] = Util.createTextSVG( ' ', {
			'dominant-baseline': 'hanging',
			'text-anchor': 'end', 
			x: (Channels.scaleWidth - 50),
			y: 2 + pane_offset[ disp_ch ],
			fill: 'black'
		} );
		panes[ disp_ch ].appendChild( this.B_labels[ disp_ch ] );
		
		// white level label
		this.W_labels[ disp_ch ] = Util.createTextSVG( ' ', {
			'dominant-baseline': 'hanging',
			'text-anchor': 'end', 
			y: 2 + pane_offset[ disp_ch ],
			x: Channels.scaleWidth,
			fill: 'white'
		} );
		panes[ disp_ch ].appendChild( this.W_labels[ disp_ch ] );
		
		// white scale slider
		this.W_sliders[disp_ch] = new Slider( 
			0, ( 15 + pane_offset[ disp_ch ] ), Channels.scaleWidth, 0, 
			{ method: disp_ch+'_W', obj: this.image },
			'<rect width="'+Channels.scaleWidth+'" height="10" opacity="0"/>',
			'<rect x="-2" width="4" height="10" fill="white"/>'
		);
		// white translucent bar
		this.W_bars[disp_ch] = Util.createElementSVG( 'rect', {
			x: 0,
			y: (15 + pane_offset[ disp_ch ]),
			width: 1,
			height: 10,
			fill: 'white',
			opacity: 0.3
		});
		panes[ disp_ch ].appendChild( this.W_bars[disp_ch] );
		this.W_sliders[disp_ch].realize( panes[ disp_ch ] );
		
		// black scale slider
		this.B_sliders[ disp_ch ] = new Slider( 
			0, ( 25 + pane_offset[ disp_ch ] ), Channels.scaleWidth, 0, 
			{ method: disp_ch + '_B', obj: this.image },
			'<rect width="'+Channels.scaleWidth+'" height="10" opacity="0"/>',
			'<rect x="-2" width="4" height="10" fill="black"/>'
		);
		// black translucent bar
		this.B_bars[disp_ch] = Util.createElementSVG( 'rect', {
			y: ( 25 + pane_offset[ disp_ch ] ),
			width: 1,
			height: 10,
			fill: 'black',
			opacity: 0.3
		});
		panes[ disp_ch ].appendChild( this.B_bars[disp_ch] );
		this.B_sliders[ disp_ch ].realize( panes[ disp_ch ] );
	}

	// make the toolbox to house these controls
	var bbox = this.colorPane.getBBox();
	var toolboxAppearance = this.toolboxApperance;
	toolboxAppearance[ 'width' ]  = bbox.width;
 	this.toolBox = new multipaneToolBox( toolboxAppearance );
	this.toolBox.realize( rendering_layer );
	rendering_layer.appendChild( parseXML(
'<linearGradient id="ChannelColorBG" x1="0" y1="0" x2="100%" y2="0">\
	<stop offset="0%" stop-color="red" />\
	<stop offset="33%" stop-color="red" />\
	<stop offset="66%" stop-color="limegreen" />\
	<stop offset="100%" stop-color="mediumslateblue" />\
</linearGradient>'	
	, svgDocument) );
	
	// a button/label to switch display between color & greyscale
	this.colorButton = new button( {
		x: 0,
		y: 0,
		callback: { obj: this.image, method: 'colorDisplay' },
		onText: '<text y="2" x="4" dominant-baseline="hanging" text-anchor="begin" text-decoration="underline" font-weight="bold" fill="black">Color Map</text>',
		offText: '<text y="2" x="4" dominant-baseline="hanging" text-anchor="begin" text-decoration="underline" font-weight="bold" fill="black">Greyscale Map</text>',
		highlightText: '<rect width="92" height="15" fill="white"/>'
	} );
	this.colorButton.realize( this.toolBox.getMenuBar() );
	
	this.toolBox.addPane( this.colorPane, 'color' );
	this.toolBox.addPane( this.greyscalePane, 'greyscale' );
};


/* initialization code is split from constructor function because of javaScript inheritence wierdness */
Channels.prototype.init = function(image, channel_labels) {
	this.initialized = true;
	this.image = image;
	this.channel_labels = channel_labels;

	this.displayChannels = new Array();
	this.Stats = image.Stats;

	for( var disp_ch in this.disp_channel_colors ) {
		this.image.registerListener( disp_ch + '_ch', this, 'sync_color_map', [disp_ch] );
		this.image.registerListener( disp_ch + '_B', this, 'sync_black_level', [disp_ch] );
		this.image.registerListener( disp_ch + '_W', this, 'sync_white_level', [disp_ch] );
		if( disp_ch != 'grey' ) {
			this.image.registerListener( disp_ch + '_on', this, 'sync_disp_ch_on', [disp_ch] );
		}
	}
	this.image.registerListener( 'color_display', this, 'sync_color_display' );

	// BW = Blacklevel & Whitelevel. indexed by channel number
	this.global_Min = new Array();
	this.global_Max = new Array();
	for(var c in this.Stats) {
		this.global_Min[c] = this.Stats[c][0]['Minimum'];
		this.global_Max[c] = this.Stats[c][0]['Maximum'];
		for( var t in this.Stats[c] ) {
			this.global_Min[c] = Math.min(this.Stats[c][t]['Minimum'], this.global_Min[c]);
			this.global_Max[c] = Math.max(this.Stats[c][t]['Maximum'], this.global_Max[c]);
		}
	}

};

// These functions synchronize the View in this class with the Model in image

// synchronize all Channel controls and displays with image model
Channels.prototype.sync = function( ) {
	for( var disp_ch in this.disp_channel_colors ) {
		this.sync_color_map(disp_ch);
		this.sync_black_level(disp_ch);
		this.sync_white_level(disp_ch);
		if( disp_ch != 'grey' ) {
			this.sync_disp_ch_on(disp_ch);
		}
	}
	this.sync_color_display();
};

// synchronize color vs. greyscale mode
Channels.prototype.sync_color_display = function(  ) {
	this.colorButton.setState( this.image.colorDisplay(), true );
	if( this.image.colorDisplay() ) {
		this.toolBox.changePane( 'color' );
		this.toolBox.getMenuBar().getElementsByTagName('rect').item(0).setAttribute( 'fill', 'url(#ChannelColorBG)' );
	} else {
		this.toolBox.changePane( 'greyscale' );
		this.toolBox.getMenuBar().getElementsByTagName('rect').item(0).setAttribute( 'fill', 'lightgrey' );
	}
};

// synchronize RGB display channels being visible
Channels.prototype.sync_disp_ch_on = function( disp_ch ) {
	this.ch_on_off[ disp_ch ].setState( this.image.channel_visible(disp_ch), true );
};

// synchronize channels mapped to display channels
Channels.prototype.sync_color_map = function( disp_ch ) {
	this.ch_lists[ disp_ch ].setSelectionByExternalIndex( this.image.color_map(disp_ch), true );
};

// synchronize the black level of a display channel
Channels.prototype.sync_black_level = function( disp_ch ) {
	var ch = this.image.color_map(disp_ch);
	var b = this.image.getB( ch );
	this.B_sliders[ disp_ch ].setMinmax( 
		this.global_Min[ ch ], 
		this.global_Max[ ch ],
		false
	);
	this.B_sliders[ disp_ch ].setValue( b );
	this.B_bars[disp_ch].setAttribute( 'width', this.B_sliders[ disp_ch ].getPosition() );	
	this.B_labels[ disp_ch ].firstChild.data = b;
};

// synchronize the white level of a display channel
Channels.prototype.sync_white_level = function( disp_ch ) {
	var ch = this.image.color_map(disp_ch);
	var w = this.image.getW( ch );
	this.W_sliders[ disp_ch ].setMinmax( 
		this.global_Min[ ch ], 
		this.global_Max[ ch ],
		false
	);
	this.W_sliders[ disp_ch ].setValue( w );
	this.W_bars[disp_ch].setAttribute( 'width', Channels.scaleWidth - this.W_sliders[disp_ch].getPosition()  );
	this.W_bars[disp_ch].setAttribute( 'x', this.W_sliders[disp_ch].getPosition() );
	this.W_labels[ disp_ch ].firstChild.data = w;
};
