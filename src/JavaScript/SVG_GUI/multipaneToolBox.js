/*****
*    
*   multipaneToolBox.js
*     external files dependecies: widget.js, toolBox.js
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
	
	tested
	
*****/
multipaneToolBox.prototype.updateLabel = function(val) {
	if(val) {
		this.UPDATE_LABEL = true;
		this.setLabel(0, "1em", " ");
		this.getLabel().setAttribute("text-anchor", "end");
	}
	else
		this.UPDATE_LABEL = false;
}

/*****

	addLayer( newLayer, name )
		adds a single layer
		newLayer is a single SVG node
		name is optional. If given, you may refer to the layer by name instead of number.
		if called without any parameters, it will make a new empty layer
		returns index to newLayer
	
	tested

*****/
multipaneToolBox.prototype.addLayer = function(newLayer, name) {
	var i = ( name ? name : this.layers.length )

	//	make a new layer, turn its display off
	this.layers[i] = svgDocument.createElementNS(svgns, 'g');
	this.layers[i].setAttribute("display","none");
	this.getGUIbox().appendChild(this.layers[i]);

	//	add layer content
	if(newLayer)
		this.layers[i].appendChild(newLayer);

	// return index to layer
	return i;
}

/*****

	addLayers( newLayers )
		adds multiple layers at once
		newLayers is an array of SVG nodes
		returns array of indexes to layers
		
	untested
	
*****/
multipaneToolBox.prototype.addLayers = function(newLayers) {
	var indexes = new Array();
	for(var i in newLayers)
		indexes.push(this.addLayer(newLayers[i]));
	return indexes;
}

/*****

	addLayerText( layerText, name )
		adds a layer, makes content from SVG text
		layerText is the layer content as SVG tags
		name is optional. If given, you may refer to the layer by name instead of number.
		returns index to newLayer
		
	tested
	
*****/
multipaneToolBox.prototype.addLayerText = function( layerText, name ) {
	return this.addLayer( this.textToSVG( layerText ), name );
}

/*****

	addLayersText( layerTextArray )
		adds multiple layers, makes content from SVG text
		layerTextArray is an array of SVG tags
		returns array of indexes to layers
		
	tested
	
*****/
multipaneToolBox.prototype.addLayersText = function( layerTextArray ) {
	var indexes = new Array();
	for(i in layerTextArray)
		indexes.push(this.addLayerText( layerTextArray[i] ));
	return indexes;
}

/*****

	changeLayer(layerIndex)
		changes displayed layer to layerIndex
		returns layer if successful
		returns null if unsuccessful
		
		untested
	
*****/
multipaneToolBox.prototype.changeLayer = function(layerIndex) {
	if(this.layers[layerIndex]) {
		// switch layers, update pointer to displayed layer
		if(this.currentDisplay) {
			this.layers[ this.currentDisplay ].setAttribute("display","none");
			var Obbox = this.layers[ this.currentDisplay ].getBBox();
		}
		this.layers[layerIndex].setAttribute("display","inline");
		this.currentDisplay = layerIndex;

		// update label
		if(this.UPDATE_LABEL)
			this.setLabel(null, null, layerIndex);
		// change size to match size of new layer
		if(Obbox) {
			if(Obbox.width>=0 && Obbox.height>=0) {
				this.shrinkGUIboxWidth.setAttribute("from", Obbox.width + 2*Obbox.x);
				this.shrinkGUIboxHeight.setAttribute("from", Obbox.height + 2*Obbox.y);
			}
		}
		var Nbbox = this.layers[layerIndex].getBBox();
		if(Nbbox.width>=1 && Nbbox.height>=1) {
			this.shrinkGUIboxWidth.setAttribute("to", Nbbox.width + 2*Nbbox.x);
			this.shrinkGUIboxHeight.setAttribute("to", Nbbox.height + 2*Nbbox.y);
			this.shrinkGUIboxWidth.beginElement();
			this.shrinkGUIboxHeight.beginElement();
		}
	}
	return this.layers[layerIndex];
}

/*****

	getLayerIndexes()
		returns a complete list of layer indexes
		
	untested
	
*****/
multipaneToolBox.prototype.getLayerIndexes = function() {
	var layerIndexes = new Array();
	for(var i in this.layers)
		layerIndexes.push(i);
	return layerIndexes;
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

	this.layers = new Array();
	this.currentDisplay = null;
}

/*****

	buildSVG()

*****/
multipaneToolBox.prototype.buildSVG = function() {
	// call superclass method
	multipaneToolBox.superclass.buildSVG.call(this);
	
	this.shrinkGUIboxWidth = svgDocument.createElementNS(svgns, "animate");
	this.shrinkGUIboxWidth.setAttributeNS(null, "attributeName", "width");
	this.shrinkGUIboxWidth.setAttributeNS(null, "dur", "0.2s");
	this.shrinkGUIboxWidth.setAttributeNS(null, "fill", "freeze");
	this.shrinkGUIboxWidth.setAttributeNS(null, "begin", "indefinite");
	this.shrinkGUIboxWidth.setAttributeNS(null, "repeatCount", 0);

	this.shrinkGUIboxHeight = svgDocument.createElementNS(svgns, "animate");
	this.shrinkGUIboxHeight.setAttributeNS(null, "attributeName", "height");
	this.shrinkGUIboxHeight.setAttributeNS(null, "dur", "0.2s");
	this.shrinkGUIboxHeight.setAttributeNS(null, "fill", "freeze");
	this.shrinkGUIboxHeight.setAttributeNS(null, "begin", "indefinite");
	this.shrinkGUIboxHeight.setAttributeNS(null, "repeatCount", 0);

	this.nodes.GUIboxBorder.appendChild(this.shrinkGUIboxWidth);
	this.nodes.GUIboxBorder.appendChild(this.shrinkGUIboxHeight);
}