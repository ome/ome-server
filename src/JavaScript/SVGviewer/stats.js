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

/*****

	class variables
	
*****/
Statistics.VERSION = .2;
Statistics.prototype.padding = 5;

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
function Statistics(stats, waveLabels) {
	if(!stats ) { return null; }
	this.init(stats, waveLabels)
}

Statistics.prototype.buildToolBox = function( controlLayer ) {
	this.buildDisplay();
	var bbox = this.displayContent.getBBox();
	var width = bbox.width + 2 * toolBox.prototype.padding;
	var height = bbox.height + 2 * toolBox.prototype.padding;
	this.toolBox = new toolBox(
		255, 50, width, height
	);
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(10,12,"Statistics");
	this.toolBox.getLabel().setAttribute( "text-anchor", "start");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( this.displayContent );
	
}


/*****
	
	buildDisplay
	
	returns:
		SVG chunk describing Statistics pane
		
*****/
Statistics.prototype.buildDisplay = function() {
	if( !this.initialized) return null;

	this.displayContent = svgDocument.createElementNS(svgns, "g");

	// set up GUI
	this.logicalChannelPopupList = new popupList(
		70, 0, this.waveLabels, 
		{ obj: this, method: 'updateStats'},
		null,
		skinLibrary["popupListAnchorLightslategray"],
		skinLibrary["popupListBackgroundLightskyblue"],
		skinLibrary["popupListHighlightAquamarine"]
	);
	this.logicalChannelPopupList.setLabel(-2, 12, "Channel: ");
	this.logicalChannelPopupList.getLabel().setAttribute("text-anchor", "end");
	this.logicalChannelPopupList.realize( this.displayContent );
	
	// build displays
	this.labels = new Array();
	this.fields = new Array();
	this.displayContent.appendChild( this.logicalChannelPopupList.textToSVG(
		'<text x="0" y="2em" dominant-baseline="hanging">theT: </text>'
	));
	this.labels['theT'] = this.displayContent.lastChild;
	this.displayContent.appendChild( this.logicalChannelPopupList.textToSVG(
		'<text x="160" y="2em" text-anchor="end" dominant-baseline="hanging">.</text>'
	));
	this.fields['theT'] = this.displayContent.lastChild;

	for( c in this.stats )
		for( t in this.stats[c] ) break;
	var lineCount = 3;
	for( statType in this.stats[t][c] ) {
		var newLabel = svgDocument.createElementNS( svgns, "text" );
		newLabel.setAttribute( "dominant-baseline", 'hanging' );
		newLabel.setAttribute( "y", lineCount + 'em' );
		newLabel.appendChild( svgDocument.createTextNode( statType ) );
		this.labels[ statType ] = newLabel;
		
		var newField = svgDocument.createElementNS( svgns, "text" );
		newField.setAttribute( "x", 160 );
		newField.setAttribute( "y", lineCount + 'em' );
		newField.setAttribute( "text-anchor", 'end' );
		newField.setAttribute( "dominant-baseline", 'hanging' );
		newField.appendChild( svgDocument.createTextNode( '.' ) );
		this.fields[ statType ] = newField;

		this.displayContent.appendChild( newLabel );
		this.displayContent.appendChild( newField );

		lineCount++;
	}

	var translate = 'translate( '+ toolBox.prototype.padding + ', ' + toolBox.prototype.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );

	return this.displayContent;
}

/*****

	updateStats
		t = theT
	
	purpose:
		update stack stats
	
*****/

Statistics.prototype.updateStats = function(t) {
	// has buildSVG been called?
	if(this.displayContent == null) return null;
	// verify params
	if(t == null) return;
	
	// update fields
	var c = this.logicalChannelPopupList.getSelection();
	this.fields['theT'].firstChild.data = t;
	for( statType in this.stats[c][t] ) {
		this.fields[statType].firstChild.data = this.stats[c][t][statType];
	}
}

/*****
	
	changeWavenumber
		theW = wavenumber
	
	purpose:
		change selected wavelength
	
	untested
	
*****/
Statistics.prototype.changeWavenumber = function(theW) {
	v = this.logicalChannelPopupList.getItemList();
	this.logicalChannelPopupList.setSelectionByValue( v[theW], true);
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

	tested

*****/

Statistics.prototype.init = function(stats, waveLabels) {
	this.initialized = true;
	this.stats = stats;
	this.waveLabels = waveLabels;
}
