/*****

	overlay.js
		
		
	Copyright (C) 2002 Open Microscopy Environment
	Author: Josiah Johnston <siah@nih.gov>
	
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
	
	A superclass for all overlays.

*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
Overlay.VERSION = .1;

/********************************************************************************************
                                 Public Functions 
********************************************************************************************/

/*****

	constructor
				
*****/
function Overlay( ) {
}

/*****
	
	makeControls
	
	returns:
		The controls for this class, loaded into DOM with a <g> as the root.
				
*****/
Overlay.prototype.makeControls = function() {
}

/*****
	
	makeOverlay
	
	returns:
		The overlay for this instance.
		The data it uses was acquired during initialization.
				
*****/
Overlay.prototype.makeOverlay = function( ) {
}

/*****
	
	updateIndex
	
	switches overlays on and off based on changes to Z and T indexes
		
*****/
Overlay.prototype.updateIndex = function( theZ, theT ) {
	if( this.oldZ == null ) this.oldZ = theZ;
	if( this.oldT == null ) this.oldT = theT;
	
	if( this.sliceByIndex[this.oldZ] != null ) {
		if( this.sliceByIndex[this.oldZ][this.oldT] != null ) {
			this.sliceByIndex[this.oldZ][this.oldT].setAttribute( "display", "none" );
		}
	}
	if( this.sliceByIndex[theZ] != null ) {
		if( this.sliceByIndex[theZ][theT] != null ) {
			this.sliceByIndex[theZ][theT].setAttribute( "display", "inline" );
		}
	}
	
	if( this.allZ ) {
		for( z in this.sliceByIndex ) {
			if( this.sliceByIndex[z][this.oldT] ) {
				this.sliceByIndex[z][this.oldT].setAttribute( "display", "none" );
			}
			if( this.sliceByIndex[z][theT] ) {
				this.sliceByIndex[z][theT].setAttribute( "display", "inline" );
			}
		}
	}
	if( this.allT ) {
		for( t in this.sliceByIndex[this.oldZ] ) {
			if( this.sliceByIndex[this.oldZ][t] ) {
				this.sliceByIndex[this.oldZ][t].setAttribute( "display", "none" );
			}
		}
		for( t in this.sliceByIndex[theZ] ) {
			if( this.sliceByIndex[theZ][t] ) {
				this.sliceByIndex[theZ][t].setAttribute( "display", "inline" );
			}
		}
	}
	
	this.oldZ = theZ;
	this.oldT = theT;
	
}

/*****
	
	turnOnOff
	
	switches the display of this overlay on and off
		
*****/
Overlay.prototype.turnOnOff = function( value ) {
	this.overlayRoot.setAttribute( "display", (value ? "inline" : "none") );
}

/*****
	
	showAllZs
		
*****/
Overlay.prototype.showAllZs = function( value ) {
	this.allZ = value;
	if( !value ) {
		for( z in this.sliceByIndex ) {
			if( this.sliceByIndex[z][this.oldT] && z != this.oldZ ) {
				this.sliceByIndex[z][this.oldT].setAttribute( "display", "none" );
			}	
		}
	}
	this.updateIndex( this.oldZ, this.oldT );
}

/*****
	
	showAllTs
		
*****/
Overlay.prototype.showAllTs = function( value ) {
	this.allT = value;
	if( !value ) {
		for( t in this.sliceByIndex[this.oldZ] ) {
			if( this.sliceByIndex[this.oldZ][t] && t != this.oldT ) {
				this.sliceByIndex[this.oldZ][t].setAttribute( "display", "none" );
			}	
		}
	}
	this.updateIndex( this.oldZ, this.oldT );
}

/*****
	
	addLayerSlice
	
	adds a layer slice to the overlay
		
*****/
Overlay.prototype.addLayerSlice = function( theZ, theT, layerSlice ) {
	layerSlice.setAttribute( "display", "none" );
	if( this.sliceByIndex[theZ] == null ) 
		this.sliceByIndex[theZ] = new Array();
	if( this.sliceByIndex[theZ][theT] == null ) 
		this.sliceByIndex[theZ][theT] = new Array();
	this.sliceByIndex[theZ][theT] = layerSlice;
	this.overlayRoot.appendChild( layerSlice );
}

/********************************************************************************************
                                 Private Functions 
********************************************************************************************/

Overlay.prototype.init = function( ) {

	this.allZ = false;
	this.allT = false;
	
	this.oldZ = null;
	this.oldT = null;
	this.overlayRoot = svgDocument.createElementNS( svgns, "g" );
	this.sliceByIndex = new Array();
	
}

/*****
	makeColors
		returns a list of colors
*****/

Overlay.prototype.makeColors = function() {
	if(this.colors != null) 
		return this.colors;
	this.colors = new Array();
	this.colors.push("red");
	this.colors.push("blue");
	this.colors.push("green");
	this.colors.push("yellow");
	this.colors.push("black");
	this.colors.push("white");
	return this.colors;
}
