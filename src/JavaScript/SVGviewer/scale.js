/*****

	scale.js

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

/*****
	class constants
*****/
Scale.VERSION = 0.2;
Scale.scaleWidth = 180;
Scale.defaultChannel = 0;
Scale.toolboxApperance = {
	Red: {
		x: 50,
		y: 50, 
		menuBarText: skinLibrary["redMenubar"],
		hideControlText: skinLibrary["XhideControl"],
		GUIboxText: skinLibrary["redGUIboxBG"],
	},
	Green: {
		x: 70,
		y: 70, 
		menuBarText: skinLibrary["greenMenubar"],
		hideControlText: skinLibrary["XhideControl"],
		GUIboxText: skinLibrary["greenGUIboxBG"],
	},
	Blue: {
		x: 90,
		y: 90, 
		menuBarText: skinLibrary["blueMenubar"],
		hideControlText: skinLibrary["XhideControl"],
		GUIboxText: skinLibrary["blueGUIboxBG"],
	},
	Grey: {
		x: 110,
		y: 110, 
		menuBarText: skinLibrary["greyMenubar"],
		hideControlText: skinLibrary["XhideControl"],
		GUIboxText: skinLibrary["greyGUIboxBG"],
	}	
};

Scale.CBWmap = { 
	Red: 0,
	Green: 3,
	Blue: 6,
	Grey: 9
};

/********************************************************************************************
                                 Public Functions 

	Developer notes:
		This class is set up to have exactly 4 instances (one for each
		display channel) that share class data. Each instance has a
		toolBox. Initialization is:
			Scale.setClassData( image );
			redScale = new Scale('Red', toolboxLayer);
			blueScale = new Scale('Blue', toolboxLayer);
			greenScale = new Scale('Green', toolboxLayer);
			greyScale = new Scale('Grey', toolboxLayer);
				

********************************************************************************************/

/*****
	Scale (constructor)
		displayChannelLabel = Red, Green, Blue, or Grey
		toolboxLayer = layer to render toolbox in
*****/

function Scale(displayChannelLabel, toolboxLayer) {
	if(Scale.initialized &&
	   Scale.toolboxApperance[displayChannelLabel] ) {
		this.init(displayChannelLabel, toolboxLayer);
		Scale.displayChannels[ displayChannelLabel ] = this;
	} else {
		alert("Scale.setClassData has not been called!");
	}
}



/*****
	setLogicalChannel
		logicalChannelIndex
	change the logical channel mapped to this display channel
*****/
Scale.prototype.setLogicalChannel = function(logicalChannelIndex) {
	if(!(this.initialized)) { return null; }
	var CBW = Scale.image.getCBW();
	CBW[this.CBWmap] = logicalChannelIndex;
	Scale.image.setCBW(CBW);
	
	var itemList = this.logicalChannelPopupList.getItemList();
	this.logicalChannelPopupList.setSelectionByValue( itemList[logicalChannelIndex], true);
	if( this.tiedLogicalChannelPopupLists ) {
		for( var i in this.tiedLogicalChannelPopupLists ) {
			var tiedPopupList = this.tiedLogicalChannelPopupLists[i]['PopupList'];
			itemList = tiedPopupList.getItemList();
			var noCallback = this.tiedLogicalChannelPopupLists[i]['NoCallback']
			tiedPopupList.setSelectionByValue( itemList[logicalChannelIndex], noCallback);
		}
	}
	this.updateScaleDisplay();
};




/*****
	updateBlackLevel
		val - value of white slider bar
	callback for moving the white level slider
*****/
Scale.prototype.updateBlackLevel = function( val ) {
	if(Math.round(val) == this.blackBar.getAttribute("width")) { return; }
	
	var c = this.logicalChannelPopupList.getSelection();

	if(val >= this.whiteSlider.getValue()) {
		val = this.whiteSlider.getValue() - 0.00001;
	}
	Scale.BW[c]['B'] = this.inverseCalcScalePos( val );
	Scale.updateCBW();

	// update display
	this.blackSlider.setValue(val);
	this.blackLabel.firstChild.data = Scale.BW[c]['B'];
	this.blackBar.setAttribute("width", Math.round(val) );

	return Scale.BW[c]['B'];
};



/*****
	updateWhiteLevel
		val - value of white slider bar
	callback for moving the white level slider
*****/
Scale.prototype.updateWhiteLevel = function( val ) {
	if(Math.round(val) == this.whiteBar.getAttribute("x")) { return; }
	
	var c = this.logicalChannelPopupList.getSelection();

	if(val <= this.blackSlider.getValue()) {
		val = this.blackSlider.getValue() + 0.00001;
	}
	Scale.BW[c]['W'] = this.inverseCalcScalePos( val );
	Scale.updateCBW();

	// update display
	this.whiteSlider.setValue(val);
	this.whiteLabel.firstChild.data = Scale.BW[c]['W'];
	this.whiteBar.setAttribute("width", Scale.scaleWidth - Math.round(val) );
	this.whiteBar.setAttribute("x", Math.round(val) );

	return Scale.BW[c]['W'];
};



/*****
	updateScaleDisplay
		instance method
		uses global var 'theT'
	Update scale bar to match a stack's info. Specifically, move tick 
	marks & update labels.
*****/
Scale.prototype.updateScaleDisplay = function() {
	if(!this.initialized) {
		return null;
	}

	// construct variables
	var c = this.logicalChannelPopupList.getSelection();
	var min = Scale.Stats[c][theT]['min'];
	var max = Scale.Stats[c][theT]['max'];

	var minSliderPos = this.calcScalePos( min );
	var maxSliderPos = this.calcScalePos( max );
	
	// set stack ticks & labels
	this.stackMinLabel.setAttribute( 'transform', 'translate('+ minSliderPos+',0)' );
	this.stackMinTick.setAttribute( 'transform', 'translate('+minSliderPos+',0)' );
	this.stackMaxTick.setAttribute( 'transform', 'translate('+maxSliderPos+',0)' );
	this.stackMaxLabel.setAttribute( 'transform', 'translate('+maxSliderPos+',0)' );
	this.stackMinLabel.firstChild.data = min;
	this.stackMaxLabel.firstChild.data = max;
	this.globalMinLabel.firstChild.data = Scale.global_Min[c];
	this.globalMaxLabel.firstChild.data = Scale.global_Max[c];
};



/*****
	tieLogicalChannelPopupList ()
		popupList - popupList to synchronize logical Channel with.
		noCallback - set to false to have synchronized popuplist engage
		its callback function. careful to avoid infinite loops if you
		use this.
	allows multiple control to be synchonized with the logical Channel map popup List.
*****/
Scale.prototype.tieLogicalChannelPopupList = function(logicalChannelPopupList, noCallback) {
	if( noCallback !== false ) { noCallback = true; }
	if( ! this.tiedLogicalChannelPopupLists ) { this.tiedLogicalChannelPopupLists = new Array(); }
	this.tiedLogicalChannelPopupLists.push( { PopupList: logicalChannelPopupList, NoCallback: noCallback } );
};


/*****
	updateScaleDisplay
		class method
	Update scale bar for all instances.
*****/
Scale.updateScaleDisplay = function() {
	if(!Scale.initialized) {
		return null;
	}

	for( var i in Scale.displayChannels ) {
		Scale.displayChannels[ i ].updateScaleDisplay();
	}
};




Scale.setClassData = function(image, channelLabels) {
	Scale.initialized = true;
	Scale.displayChannels = new Array();
	Scale.image = image;
	Scale.Dims = image.Dims;
	Scale.Stats = image.Stats;
	// BW = Blacklevel & Whitelevel. Array indexed by channel number that stores Black level and Scale.
	Scale.BW = new Array();
	// set BW according to values from image.getCBW()
	var imageCBW = image.getCBW();
	Scale.channelLabels = channelLabels;
	Scale.popupListChannelLabels = new Array();
	for(var channelIndex in channelLabels) {
		Scale.BW[channelIndex] = new Array();
		Scale.popupListChannelLabels[channelIndex] = '[ ' + channelLabels[channelIndex] + ' ]';
		// copy values from image's CBW?
		for(var j=0;j<4;++j) {
			if(imageCBW[j*3] == channelIndex) {
				Scale.BW[ channelIndex ]['B'] = imageCBW[j*3+1];
				Scale.BW[ channelIndex ]['W'] = imageCBW[j*3+2];
			}
		}
	}
	Scale.global_Min = new Array();
	Scale.global_Max = new Array();
	for(var c in Scale.Stats) {
		Scale.global_Min[c] = Scale.Stats[c][0]['min'];
		Scale.global_Max[c] = Scale.Stats[c][0]['max'];
		for( var t in Scale.Stats[c] ) {
			Scale.global_Min[c] = Math.min(Scale.Stats[c][t]['min'], Scale.global_Min[c]);
			Scale.global_Max[c] = Math.max(Scale.Stats[c][t]['max'], Scale.global_Max[c]);
		}
	}

};

/********************************************************************************************
                                 Private Functions 
********************************************************************************************/


Scale.updateCBW = function() {
	if(!(this.initialized)) { return null; }

	var CBW = Scale.image.getCBW();
	var changed = false;

	for(var i=0;i<4;++i) {
		var _ci = CBW[i*3];
		if(CBW[i*3+1] != Scale.BW[_ci]['B']) {
			changed = true;
			CBW[i*3+1] = Scale.BW[_ci]['B'];
		}
		if(CBW[i*3+2] != Scale.BW[_ci]['W']) {
			changed = true;
			CBW[i*3+2] = Scale.BW[_ci]['W'];
		}
	}
	if(changed) {
		Scale.image.setCBW(CBW);
	}
};



Scale.prototype.buildToolBox = function( ) {
	if( !this.initialized ) {
		return null;
	}
	var displayContent = this.buildDisplay();
	var bbox = displayContent.getBBox();
	var toolboxAppearance = Scale.toolboxApperance[ this.displayChannelLabel ];
	toolboxAppearance[ 'width' ]  = bbox.width + 2 * toolBox.prototype.padding;
	toolboxAppearance[ 'height' ] = bbox.height + 2 * toolBox.prototype.padding;

	this.toolBox = new toolBox( toolboxAppearance );
	this.logicalChannelPopupList = new popupList(
		90, 0, Scale.popupListChannelLabels, 
		{ method: 'setLogicalChannel', obj: this },
		0,
		skinLibrary["transparentBox"],
		null, 
		skinLibrary["whiteTranslucentBox"]
	);
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel( 4,12,this.displayChannelLabel+" Scale");
	this.toolBox.getLabel().setAttribute( "text-anchor", "start");
	this.toolBox.realize( this.toolboxLayer );
	this.logicalChannelPopupList.realize( this.toolBox.getMenuBar() );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( displayContent );
	
};


Scale.prototype.buildDisplay = function() {
	if(!this.initialized) {
		return null;
	}

	// set up references & constants
	var channelIndex        = Scale.defaultChannel;
	var blackLevel          = Math.round(Scale.BW[channelIndex]['B']);
	var whiteLevel          = Math.round(Scale.BW[channelIndex]['W']);
	var blackSliderPosition = this.calcScalePos( blackLevel );
	var whiteSliderPosition = this.calcScalePos( whiteLevel );
	if( blackSliderPosition < 0 ) { blackSliderPosition = 0; }
	if( whiteSliderPosition > Scale.scaleWidth ) { whiteSliderPosition = Scale.scaleWidth; }


// build SVG
	this.displayContent =  Util.createElementSVG( 'g' );

	// set up GUI
	this.blackSlider = new Slider( 
		0, 70, Scale.scaleWidth, 0, 
		{ method: 'updateBlackLevel', obj: this },
		'<rect width="'+Scale.scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="black"/>',
		blackSliderPosition
	);
	this.whiteSlider = new Slider( 
		0, 58, Scale.scaleWidth, 0, 
		{ method: 'updateWhiteLevel', obj: this },
		'<rect width="'+Scale.scaleWidth+'" height="10" opacity="0"/>',
		'<rect x="-2" width="4" height="10" fill="white"/>',
		whiteSliderPosition
	);
		
	// build slider background
	this.backgroundLayer = Util.createElementSVG( 'g', {
		transform: 'translate(0,70)'
	});
	this.backgroundLayer.appendChild( 
		Util.createElementSVG( 'line', {
			x2: (Scale.scaleWidth),
			'stroke-width': 2,
			stroke: "midnightblue"
		})
	);
	// global minimum tick
	this.backgroundLayer.appendChild( 
		Util.createElementSVG( 'line', { 
			y2: 10, 
			'stroke-width': 2, 
			stroke: "midnightblue" 
		}) 
	);
	// global minimum label
	this.globalMinLabel = Util.createTextSVG( Scale.global_Min[channelIndex], { 
		'text-anchor': 'middle', 
		y: 10, 
		'dominant-baseline': 'hanging'
	});
	this.backgroundLayer.appendChild( this.globalMinLabel );
	// global maximum tick
	this.backgroundLayer.appendChild( 
		Util.createElementSVG( 'line', {
			x1: Scale.scaleWidth, 
			x2: Scale.scaleWidth, 
			y2: 10, 
			'stroke-width': 2, 
			stroke: "midnightblue" 
		}) 
	);
	// global maximum label
	this.globalMaxLabel = Util.createTextSVG( Scale.global_Max[channelIndex], { 
		'text-anchor': 'middle', 
		x: Scale.scaleWidth, 
		y: 10, 
		'dominant-baseline': 'hanging'
	});
	this.backgroundLayer.appendChild( this.globalMaxLabel );
	// global label
	this.backgroundLayer.appendChild( 
		Util.createTextSVG( 'min <-- GLOBAL --> max', { 
			'text-anchor': 'middle', 
			x: (Scale.scaleWidth/2), 
			y: 10, 
			'dominant-baseline': 'hanging',
			fill: 'darkslategrey',
			opacity: 0.7
		}) 
	);
	// stack label
	this.backgroundLayer.appendChild( 
		Util.createTextSVG( 'STACK', { 
			'text-anchor': 'middle', 
			x: (Scale.scaleWidth/2), 
			y: -2, 
			fill: 'darkslategrey',
			opacity: 0.7
		}) 
	);
	// stack min/max ticks & labels
	this.stackMinTick = Util.createElementSVG( 'line', { 
		y1: -12, 
		y2: 0, 
		'stroke-width': 2, 
		stroke: "midnightblue" 
	});
	this.stackMinLabel = Util.createTextSVG( '', { 
		'text-anchor': 'middle', 
		y: -14
	});
	this.stackMaxTick = Util.createElementSVG( 'line', {
		y1: -12, 
		y2: 0, 
		'stroke-width': 2, 
		stroke: "midnightblue" 
	});
	this.stackMaxLabel = Util.createTextSVG( '', { 
		'text-anchor': 'middle', 
		y: -14
	});
	this.backgroundLayer.appendChild( this.stackMinTick );
	this.backgroundLayer.appendChild( this.stackMinLabel );
	this.backgroundLayer.appendChild( this.stackMaxTick );
	this.backgroundLayer.appendChild( this.stackMaxLabel );

	this.blackBar = Util.createElementSVG( 'rect', {
		y: 0,
		width: blackSliderPosition,
		height: 10,
		fill: 'black',
		opacity: 0.3
	});
	this.backgroundLayer.appendChild( this.blackBar );
	this.whiteBar = Util.createElementSVG( 'rect', {
		x: whiteSliderPosition,
		y: -12,
		width: ( Scale.scaleWidth - whiteSliderPosition ),
		height: 10,
		fill: 'white',
		opacity: 0.3
	});
	this.backgroundLayer.appendChild( this.whiteBar );
	this.displayContent.appendChild( this.backgroundLayer );

	// build displays
	this.blackLabel = Util.createTextSVG( blackLevel, { x: Scale.scaleWidth, y: '1em', 'text-anchor': 'end' });
	this.whiteLabel = Util.createTextSVG( whiteLevel, { x: Scale.scaleWidth, y: '2em', 'text-anchor': 'end' });
	this.displayContent.appendChild( this.blackLabel );
	this.displayContent.appendChild( this.whiteLabel );
	this.displayContent.appendChild( Util.createTextSVG( 'Black level: ', { x: 10, y: '1em' }));
	this.displayContent.appendChild( Util.createTextSVG( 'White level: ', { x: 10, y: '2em' }));

	this.blackSlider.realize( this.displayContent );
	this.whiteSlider.realize( this.displayContent );
	
	var translate = 'translate( '+ toolBox.prototype.padding + ', ' + toolBox.prototype.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );

	return this.displayContent;
};



Scale.prototype.calcScalePos = function( x ) {
	if( !(Scale.initialized) ) { return 0; }
	var c;
	if( this.logicalChannelPopupList ) {
		c = this.logicalChannelPopupList.getSelection();
	} else { 
		c = Scale.defaultChannel;
	}
	return Math.round( (x - Scale.global_Min[c])/(Scale.global_Max[c] - Scale.global_Min[c]) * Scale.scaleWidth );
};



Scale.prototype.inverseCalcScalePos = function( x ) {
	if( !(Scale.initialized) ) { return 0; }
	var c;
	if( this.logicalChannelPopupList ) {
		c = this.logicalChannelPopupList.getSelection();
	} else { 
		c = Scale.defaultChannel;
	}
	return Math.round( x/(Scale.scaleWidth)*(Scale.global_Max[c] - Scale.global_Min[c]) + Scale.global_Min[c] );
};


Scale.prototype.init = function(displayChannelLabel,toolboxLayer) {
	this.initialized = true;
	this.displayChannelLabel = displayChannelLabel;
	this.toolboxLayer = toolboxLayer;
	this.CBWmap = Scale.CBWmap[ displayChannelLabel ];
	this.buildToolBox();
};

