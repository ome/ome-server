/*****
*    
*   multipaneToolBox.js



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
	
				
*     external file dependencies: widget.js, toolBox.js
*     Known bugs:
*       bug #1:
*          Attempting to unhide the GUIbox while it is hiding causes
*       it to turn invisible. It can be made visible by hiding and unhiding 
*       it again.
*
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****
*
*   setup inheritance
*
*****/
multipaneToolBox.prototype = new toolBox();
multipaneToolBox.prototype.constructor = multipaneToolBox;
multipaneToolBox.superclass = toolBox.prototype;

/*****
*
*   Class variables
*
*****/
multipaneToolBox.VERSION = .2;



/********************************************************************************************
                                 Public Functions 
********************************************************************************************/


/*****
*
*   multipaneToolBox constructor
*
*     Parameter description:
*       read documentation for toolbox
*
*****/
function multipaneToolBox(x, y, width, height, menuBarText, hideControlText, GUIboxText, noclip) {
	this.init(x, y, width, height, menuBarText, hideControlText, GUIboxText, noclip);
}

/*****
	updateLabel(val)
		will automatically update the label if turned on
		val == true ? turn on : turn off
		Don't call this before calling realize.
*****/
multipaneToolBox.prototype.updateLabel = function(val) {
	// has realization occured?
	if(this.getMenuBar()) {
		if(val) {
			this.UPDATE_LABEL = true;
			var Labelx = this.width - 2*this.getMenuBar().getBBox().height;
			this.setLabel(Labelx , "1em", "");
			this.getLabel().setAttribute("text-anchor", "end");
		}
		else
			this.UPDATE_LABEL = false;
	}
}

/*****
	addPane( newPane, name )
		adds a single pane to GUIboxContainer, a grand parent of GUIbox that is not subject
		to clipping
		newPane is a single SVG node
		name is optional. If given, you may refer to the pane by name instead of number.
		if called without any parameters, it will make a new empty pane
		returns index to newPane
*****/
multipaneToolBox.prototype.addPane = function(newPane, name) {
	var i = ( name ? name : this.panes.length );

	//	make a new pane, turn its display off
	this.panes[i] = svgDocument.createElementNS(svgns, 'g');
	this.panes[i].setAttribute("display","none");
	this.getGUIbox().appendChild(this.panes[i]);

	//	add pane content
	if(newPane) {
		// magic to draw background of appropriate size
		var bbox = newPane.getBBox();
		var old_height = this.height;
		this.height = Math.max( bbox.height + Math.max( bbox.y, 0 ), 1 );
		this.panes[i].appendChild( this.textToSVG( this.GUIboxText ) );
		this.height = old_height;
		
		this.panes[i].appendChild(newPane);
	}

	// return index to pane
	return i;
}

/*****
	addPaneText( paneText, name )
		adds a pane, makes content from SVG text
		paneText is the pane content as SVG tags
		name is optional. If given, you may refer to the pane by name instead of number.
		returns index to newPane
*****/
multipaneToolBox.prototype.addPaneText = function( paneText, name ) {
	return this.addPane( this.textToSVG( paneText ), name );
}

/*****
	changePane(paneIndex)
		changes displayed pane to paneIndex
		returns pane if successful
		returns null if unsuccessful	
*****/
multipaneToolBox.prototype.changePane = function(paneIndex) {
	if(this.panes[paneIndex]) {
		// make the toolBox visible
		if(this.hidden)
			this.unhide();

		// switch panes
		if(this.currentDisplay)
			this.panes[ this.currentDisplay ].setAttribute("display","none");
		this.panes[paneIndex].setAttribute("display","inline");

		// update label
		if(this.UPDATE_LABEL)
			this.setLabel(null, null, paneIndex);
		
		// change size to match size of new pane
		// find size:
		var oHeight, Obbox, nHeight, Nbbox;
		if( this.panes[ this.currentDisplay ] ) {
			Obbox = this.panes[ this.currentDisplay ].getBBox();
			oHeight = Math.max( Obbox.height + Obbox.y*2, 1 );
		}
		else
			oHeight = 1;
		Nbbox = this.panes[paneIndex].getBBox();
		nHeight = Math.max( Nbbox.height + Nbbox.y*2, 1 );

		this.shrinkGUIboxHeight.setAttribute("from", oHeight);
		this.shrinkGUIboxHeight.setAttribute("to", nHeight);
		this.shrinkGUIboxHeight.beginElement();
	}
	this.currentDisplay = paneIndex;
	return this.panes[paneIndex];
}

/*****
	getPaneIndexes()
		returns a complete list of pane indexes
*****/
multipaneToolBox.prototype.getPaneIndexes = function() {
	var paneIndexes = new Array();
	for(var i in this.panes)
		paneIndexes.push(i);
	return paneIndexes;
}

/*****
	getPane(index)
		returns the pane pointed to by index if index is valid	
*****/
multipaneToolBox.prototype.getPane = function(index) {
	if(this.panes != null)
		return this.panes[index];
}

/********************************************************************************************
                                 Private Functions 
********************************************************************************************/

multipaneToolBox.prototype.init = function( x, y, width, menuBarText,
		hideControlText, GUIboxText, noclip) {
	// call superclass method
	var params;
	if( x.constructor != Number ) {
		params = x;
		params[ 'height' ] = 0;
	} else {
		params = {
			'x': x,
			'y': y, 
			'width': width,
			'height': 0,
			'menuBarText': menuBarText,
			'hideControlText': hideControlText,
			'GUIboxText': GUIboxText,
			'noclip': noclip
		};
	}
	multipaneToolBox.superclass.init.call(this, params);

	this.panes = new Array();
	this.currentDisplay = null;
}


multipaneToolBox.prototype.buildSVG = function() {
	// call superclass method
	multipaneToolBox.superclass.buildSVG.call(this);
	
	this.shrinkGUIboxHeight = svgDocument.createElementNS(svgns, "animate");
	this.shrinkGUIboxHeight.setAttributeNS(null, "attributeName", "height");
	this.shrinkGUIboxHeight.setAttributeNS(null, "dur", "0.2s");
	this.shrinkGUIboxHeight.setAttributeNS(null, "fill", "freeze");
	this.shrinkGUIboxHeight.setAttributeNS(null, "begin", "indefinite");
	this.shrinkGUIboxHeight.setAttributeNS(null, "repeatCount", 0);

	this.nodes.GUIboxClip.appendChild(this.shrinkGUIboxHeight);
}
