/*****

	featureInfo.js

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
********************************************************************************************/

/*****

	constructor
		image = OMEimage
		updateBlack = function for black slider to call
		updateWhite = function for white slider to call
		waveChagne = function for wave popuplist to call
		
	tested

*****/
function FeatureInfo(featureData) {
	this.init( featureData );
}

FeatureInfo.prototype.buildToolBox = function( controlLayer ) {
	this.buildDisplay();
	var bbox = this.displayContent.getBBox();
	var width = bbox.width + 2 * toolBox.padding;
	var height = bbox.height + 2 * toolBox.padding;
	this.toolBox = new toolBox(
		155, 265, width, height
	);
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(90,12,"Feature Information");
	this.toolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( this.displayContent );
	
}

/*****
	
	buildDisplay
	
	returns:
		GUI controls loaded into SVG DOM. <g> is the root
		
*****/
FeatureInfo.prototype.buildDisplay = function() {

	this.displayContent = svgDocument.createElementNS( svgns, "g" );
	for( id in this.featureData ) break;
	var lineCount = 0;
	for( i in this.featureData[id] ) {
		var newLabel = svgDocument.createElementNS( svgns, "text" );
		newLabel.setAttribute( "dominant-baseline", 'hanging' );
		newLabel.setAttribute( "y", lineCount + 'em' );
		newLabel.appendChild( svgDocument.createTextNode( i ) );
		this.labels[ i ] = newLabel;
		
		var newField = svgDocument.createElementNS( svgns, "text" );
		newField.setAttribute( "x", 160 );
		newField.setAttribute( "y", lineCount + 'em' );
		newField.setAttribute( "text-anchor", 'end' );
		newField.setAttribute( "dominant-baseline", 'hanging' );
		newField.appendChild( svgDocument.createTextNode( '.' ) );
		this.fields[ i ] = newField;

		this.displayContent.appendChild( newLabel );
		this.displayContent.appendChild( newField );
		
		lineCount++;
	}

	var translate = 'translate( '+ toolBox.padding + ', ' + toolBox.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );
		
	
	return this.displayContent;
}


/*****

loadFeature
	loads and displays a feature specified by 'id'
	this class loads data for display on request. text is expensive to render.

*****/
FeatureInfo.prototype.loadFeature = function( id, openToolBox ) {
	if( openToolBox != null && this.toolBox.hidden == true )
		this.toolBox.unhide();
	for( i in this.fields ) {
		if( this.fields[i].lastChild ) this.fields[i].removeChild( this.fields[i].lastChild );
		this.fields[i].appendChild( svgDocument.createTextNode( this.features[ id ]['data'][i] ) );
	}
}

/********************************************************************************************
                                 Private Functions 
********************************************************************************************/

FeatureInfo.prototype.init = function(featureData) {
	this.featureData = featureData;
	this.fields   = new Array();
	this.features = new Array();
	this.labels   = new Array();
	
	for( i in this.featureData ) {
		var id = this.featureData[i]['ID'];
		this.features[ id ] = new Array();
		this.features[ id ]['data'] = this.featureData[ i ];
	}
}

