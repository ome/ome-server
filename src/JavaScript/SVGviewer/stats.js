/*****

	stats.js
		
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

/*global toolBox, skinLibrary, svgDocument, popupList */

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		stats = list of hashes containing stats for image xyz stacks
		waveLabels = list of wave labels indexed by wavenums
		
	tested

*****/
function Statistics(stats, waveLabels, image) {
	this.init(stats, waveLabels,image);
}

/*****

	class variables
	
*****/
Statistics.VERSION = 0.2;
Statistics.toolboxApperance = {
	x: 130,
	y: 130,
	width: 165,
	height: 55,
	noclip: true
};


Statistics.prototype.buildToolBox = function( controlLayer ) {
	this.buildDisplay();
	var bbox = this.displayContent.getBBox();
	this.toolboxApperance = Statistics.toolboxApperance;
	this.toolboxApperance['width'] = bbox.width + 2 * toolBox.padding;
	this.toolboxApperance['height'] = bbox.height + 2 * toolBox.padding;
	this.toolBox = new toolBox( this.toolboxApperance );
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(10,12,"Statistics");
	this.toolBox.getLabel().setAttribute( "text-anchor", "start");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( this.displayContent );
	
	
	this.labels['theT'] = Util.createTextSVG( "theT: ", {
		"dominant-baseline": 'hanging',
		"x":                 70,
		"y":                 2
	} );
	this.fields['theT'] = Util.createTextSVG( this.image.theT(), {
		"dominant-baseline": 'hanging',
		"x":                 100,
		"y":                 2,
		"font-weight":       "bold"
	} );
	this.toolBox.getMenuBar().appendChild( this.labels['theT'] );
	this.toolBox.getMenuBar().appendChild( this.fields['theT'] );
};


/*****
	
	buildDisplay
	
	returns:
		SVG chunk describing Statistics pane
		
*****/
Statistics.prototype.buildDisplay = function() {
	var theT = this.image.theT();
	
	var colWidth = 50;

	this.displayContent = svgDocument.createElementNS(svgns, "g");
	
	// build displays
	this.labels = new Array();
	this.fields = new Array();

	// get c and t indexes into stats
	for( var c in this.stats ) {
		for( var t in this.stats[c] ) {
			break;
		}
		break;
	}
	
	var lineCount = 0;
	var colCount = 0;
	// Make Channel row
	this.labels[ 'channel' ] = Util.createTextSVG( "Channel", {
		"dominant-baseline": 'hanging',
		"y":                 lineCount + 'em'
	} );
	this.displayContent.appendChild( this.labels[ 'channel' ] );
	this.fields[ 'channel' ] = new Array();
	for( var ch_i in this.waveLabels ) {
		var newField = Util.createTextSVG( this.waveLabels[ ch_i ], {
			"text-anchor":       'end',
			"dominant-baseline": 'hanging',
			"x":                 110 + ( colCount * colWidth ),
			"y":                 lineCount + 'em'
		} );
		this.fields[ 'channel' ][ ch_i ] = newField;
		this.displayContent.appendChild( newField );
		++colCount;
	}
	
	
	++lineCount;
	for( var statType in this.stats[c][t] ) {
		var newLabel = Util.createTextSVG( statType, {
			"dominant-baseline": 'hanging',
			"y":                 lineCount + 'em'
		} );
		this.labels[ statType ] = newLabel;
		this.displayContent.appendChild( newLabel );
		
		colCount = 0;
		this.fields[ statType ] = new Array();
		for( var ch_i in this.waveLabels ) {
			var newField = Util.createTextSVG( this.stats[ ch_i ][ theT ][statType], {
				"text-anchor":       'end',
				"dominant-baseline": 'hanging',
				"x":                 110 + ( colCount * colWidth ),
				"y":                 lineCount + 'em'
			} );
			this.fields[ statType ][ ch_i ] = newField;
			this.displayContent.appendChild( newField );
			++colCount;
		}

		++lineCount;
	}

	var translate = 'translate( '+ toolBox.prototype.padding + ', ' + toolBox.prototype.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );

	return this.displayContent;
};

Statistics.prototype.updateChannelStats = function () {
	this.updateStats( this.fields['theT'].firstChild.data );
};

Statistics.prototype.updateStats = function() {
	// update fields
	var t = this.image.theT();
//	var c = this.logicalChannelPopupList.getSelection();
	this.fields['theT'].firstChild.data = t + 1;
	for( var c in this.stats ) {
		for( var statType in this.stats[c][t] ) {
			this.fields[statType][c].firstChild.data = this.stats[c][t][statType];
		}
	}
};

/*****

	init
		Stats = list of hashes containing stats for image xyz stacks
		waveLabels = list of wave labels indexed by wavenums

	tested

*****/

Statistics.prototype.init = function(stats, waveLabels, image) {
	this.initialized = true;
	this.stats = stats;
	this.waveLabels = waveLabels;
	this.image = image;
	this.image.registerListener( 'theT', this, 'updateStats' );
};
