/*****

	ImageInfo.js

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

/*global Util, svgDocument, toolBox */

ImageInfo.prototype.toolboxApperance = {
	x: 155,
	y: 265, 
	noclip: 'noclip'
};

/********************************************************************************************
                                 Public Functions 
********************************************************************************************/

/*****

	constructor
		imageInfo = associative array w/ info about image
*****/
function ImageInfo( imageInfo, pixelList ) {
	this.init( imageInfo, pixelList );
}

ImageInfo.prototype.buildToolBox = function( controlLayer ) {
	this.buildDisplay();
	var bbox = this.displayContent.getBBox();
	this.toolboxApperance['width']  = bbox.width + 2 * toolBox.padding;
	this.toolboxApperance['height'] = bbox.height + 2 * toolBox.padding;
	this.toolBox = new toolBox( this.toolboxApperance );
	this.toolBox.closeOnMinimize( true );
	this.toolBox.setLabel(90,12,"Image Information");
	this.toolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( this.displayContent );
	
};

/*****
	
	buildDisplay
	
	returns:
		GUI controls loaded into SVG DOM. <g> is the root
		
*****/
ImageInfo.prototype.buildDisplay = function() {

	this.displayContent = Util.createElementSVG( "g" );
	var lineCount = 0;
	var fontSize  = 10;
	for( var i in this.imageInfo ) {
		var newLabel = Util.createElementSVG( "text", {
			y:                   (lineCount + 'em'),
			"dominant-baseline": 'hanging', 
			"font-size":         fontSize
		});
		newLabel.appendChild( svgDocument.createTextNode( i ) );
		this.labels[ i ] = newLabel;
		
		var newField = Util.createElementSVG( "text", {
			x:                   160,
			y:                   (lineCount + 'em'),
			"text-anchor":       'end',
			"dominant-baseline": 'hanging', 
			"font-size":         fontSize
		});
		newField.appendChild( svgDocument.createTextNode( this.imageInfo[i] ) );
		this.fields[ i ] = newField;

		this.displayContent.appendChild( newLabel );
		this.displayContent.appendChild( newField );
		
		lineCount++;
	}
	if( Util.isArray( this.pixelList ) && this.pixelList.length > 1 ) {
		newLabel = Util.createTextSVG( "Other Pixels", {
			y:                   (lineCount + 'em'),
			"dominant-baseline": 'hanging', 
			"font-size":         fontSize
		});
		
		this.pixelsPopupList = new popupList( {
			x: 160, 
			y: newLabel.getBBox().y,
			itemList: this.pixelList,
			textStyle: [ 'text-anchor', 'end' ]
		} );
		this.displayContent.appendChild( newLabel );
		this.pixelsPopupList.realize( this.displayContent );
		this.pixelsPopupList.alignUpperRight();
	}

	var translate = 'translate( '+ toolBox.padding + ', ' + toolBox.padding + ')';
	this.displayContent.setAttribute( 'transform', translate );
		
	
	return this.displayContent;
};


/********************************************************************************************
                                 Private Functions 
********************************************************************************************/

ImageInfo.prototype.init = function(imageInfo, pixelList) {
	this.imageInfo = imageInfo;
	this.pixelList = pixelList;
	this.fields   = new Array();
	this.labels   = new Array();
	
};

