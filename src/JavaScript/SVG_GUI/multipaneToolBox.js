/*****
*    
*   multipaneToolBox.js
*     external file dependencies: widget.js, toolBox.js
*     Known bugs:
*       bug #1:
*          Attempting to unhide the GUIbox while it is hiding causes
*       it to turn invisible. It can be made visible by hiding and unhiding 
*       it again.
*     Author: Josiah Johnston
*     email: siah@nih.gov
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
multipaneToolBox.VERSION = 1.0;



/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/


/*****
*
*   multipaneToolBox constructor
*
*     Parameter description:
*       The last three parameters are optional. They allow the user to control
*       the appearance of the toolBox. AT THIS TIME menuBar needs to be
*       15 pixels tall and "$width" wide. hideControl should not be
*       longer or taller than 9 pixels. GUIbox needs to be "$height" tall
*       and "$width" wide.
*       hideControl's animations can be adjusted, but they must
*       the first and second animations.
*		The same goes with GUIbox's animations, and GUIbox needs to retain its 
*       on and off switches.
*
*****/
function multipaneToolBox(x,y,width,height,menuBarText,hideControlText,GUIboxText) {
	if(arguments.length >= 4 )
		this.init(x,y,width,height,menuBarText,hideControlText,GUIboxText);
}

/*****

	updateLabel(val)
		will automatically update the label if turned on
		val == true ? turn on : turn off
		Don't call this before calling realize.
	
	tested
	
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
	
	tested

*****/
multipaneToolBox.prototype.addPane = function(newPane, name) {
	var i = ( name ? name : this.panes.length )

	//	make a new pane, turn its display off
	this.panes[i] = svgDocument.createElementNS(svgns, 'g');
	this.panes[i].setAttribute("display","none");
	this.getGUIboxNoClip().appendChild(this.panes[i]);

	//	add pane content
	if(newPane)
		this.panes[i].appendChild(newPane);

	// return index to pane
	return i;
}

/*****

	addPanes( newPanes )
		adds multiple panes at once
		newPanes is an array of SVG nodes
		returns array of indexes to panes
		
	tested
	
*****/
multipaneToolBox.prototype.addPanes = function(newPanes) {
	var indexes = new Array();
	for(var i in newPanes)
		indexes.push(this.addPane(newPanes[i]));
	return indexes;
}

/*****

	addPaneText( paneText, name )
		adds a pane, makes content from SVG text
		paneText is the pane content as SVG tags
		name is optional. If given, you may refer to the pane by name instead of number.
		returns index to newPane
		
	tested
	
*****/
multipaneToolBox.prototype.addPaneText = function( paneText, name ) {
	return this.addPane( this.textToSVG( paneText ), name );
}

/*****

	addPanesText( paneTextArray )
		adds multiple panes, makes content from SVG text
		paneTextArray is an array of SVG tags
		returns array of indexes to panes
		
	tested
	
*****/
multipaneToolBox.prototype.addPanesText = function( paneTextArray ) {
	var indexes = new Array();
	for(i in paneTextArray)
		indexes.push(this.addPaneText( paneTextArray[i] ));
	return indexes;
}

/*****

	changePane(paneIndex)
		changes displayed pane to paneIndex
		returns pane if successful
		returns null if unsuccessful
		
	tested
	
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
		if( this.panes[ this.currentDisplay ] )
			if(this.panes[this.currentDisplay].height)
				oHeight = this.panes[this.currentDisplay].height;
			else {
				Obbox = this.panes[ this.currentDisplay ].getBBox();
				oHeight = Math.max( Obbox.height + Obbox.y*2, 1 );
			}
		else
			oHeight = 1;
		if(this.panes[paneIndex].height)
			nHeight = this.panes[paneIndex].height;
		else {
			Nbbox = this.panes[paneIndex].getBBox();
			nHeight = Math.max( Nbbox.height + Nbbox.y*2, 1 );
		}

		this.shrinkGUIboxHeight.setAttribute("from", oHeight);
		this.shrinkGUIboxHeight.setAttribute("to", nHeight);
		this.shrinkGUIboxHeight.beginElement();
	}
	this.currentDisplay = paneIndex;
	return this.panes[paneIndex];
}

/*****
	
	takePaneSizeSnapshot
	
	purpose
		find height for animation purposes. animation will move to the height found here.
	
*****/
multipaneToolBox.prototype.takePaneSizeSnapshot = function() {
	for(i in this.panes) {
		bbox = this.panes[i].getBBox();
		this.panes[i].height = Math.max(bbox.height + 2*bbox.y, 1);
	}
}

/*****

	getPaneIndexes()
		returns a complete list of pane indexes
		
	tested
	
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
	
	comprehensively tested
	
*****/
multipaneToolBox.prototype.getPane = function(index) {
	if(this.panes != null)
		return this.panes[index];
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/


/*****
*
*   init
*
*****/
multipaneToolBox.prototype.init = function( x, y, width, height, menuBarText,
		hideControlText, GUIboxText) {
	// call superclass method
	multipaneToolBox.superclass.init.call(this,x,y, width, height, menuBarText, hideControlText, GUIboxText );

	this.panes = new Array();
	this.currentDisplay = null;
}

/*****

	buildSVG()

*****/
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