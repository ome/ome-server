/*****

popupList.js
	external files dependencies: widget.js

Known bugs:
	#1. Calling setSelection shortly after popupList is realized will not update
the popupList's animations. I believe this is due to viewer implementation.
	Setting setState to be called after a delay of 0 is an easy way of
bypassing this bug. i.e. setTimeout( "popup1.setSelection(3)", 0 );

*****/

svgns = "http://www.w3.org/2000/svg";

/*****
*
*   popupList inheritance
*
*****/

popupList.prototype = new Widget();
popupList.prototype.constructor = popupList;
popupList.superclass = Widget.prototype;

/*****
*
*   Class variables
*
*****/

popupList.VERSION = 1;
popupList.prototype.anchorText = 
'<rect width="{$width}" height="{$height}" fill="lightskyblue"/>';
popupList.prototype.itemBackgroundText = 
'<rect width="{$width}" height="{$height}" fill="cornflowerblue"/>';
popupList.prototype.itemHighlightText = 
'<rect width="{$width}" height="{$height}" fill="aqua"/>';
popupList.prototype.itemMouseCatcherText = 
'<rect width="{$width}" height="{$height}" opacity="0"/>';
popupList.prototype.onSwitchText = 
'<set attributeName="display" to="inline" begin="indefinite"/>';
popupList.prototype.offSwitchText = 
'<set attributeName="display" to="none" begin="indefinite"/>';
popupList.prototype.transformText = 
'<animateTransform attributeName="transform" type="translate" dur="0.1"' +
'	fill="freeze" begin="indefinite"/>';

/*****
*
*   constructor
*     variable explanations:
*       x, y = obvious
*       itemList = array of strings to insert into the list
*       callback = function to call when a item is selected by the user
*     The rest of these variables are optional.
*       selection = item number (numbering starts at 0) to select initially
*       anchorText = svg tags to overwrite default background of minimized popupList
*       itemBackgroundText = svg tags to overwrite default background of list elements
*       itemHighlightText = svg tags to overwrite default highlight of list elements
*
*****/
function popupList(x, y, itemList, callback, selection, anchorText, 
	itemBackgroundText, itemHighlightText) {
	if(arguments.length >= 3)
		this.init(x, y, itemList, callback, selection, anchorText,
			itemBackgroundText, itemHighlightText);
}


/*****
*
*	setSelection(i, noAnimate)
*
*****/
popupList.prototype.setSelection = function(i, noAnimate) {
	if(i<0)
		i=0;
	if(i>=this.size)
		i=this.size -1;
	if(i!=Math.round(i))
		i = Math.round(i);

	this.selection = i;
	this.update(noAnimate);
	if( this.callback )
		this.callback( this.getSelection() );
}

/*****
*
*	setSelectionByValue(val)
		
		notes:
			because this function is only called externally, it will not cause update to animate.
			update should only animate when opening or closing a popupList, not when the value is
			externally changed.
*
*****/
popupList.prototype.setSelectionByValue = function(val) {
	// search through itemList for val
	for(var i in this.itemList)
		if(this.itemList[i] == val) {
			// found it. now find corrosponding selection.
			for(var j in this.listIndex)
				if(this.listIndex[j] == i)
					break;
			this.setSelection(j, true);
			break;
		}
	if(this.itemList[i] == val)
		return true;
	else
		return false;
}

/*****
*
*	getItemList()
*
*****/
popupList.prototype.getItemList = function() {
	// return a COPY
	var itemList = new Array();
	for(i in this.itemList)
		itemList[i] = this.itemList[i];
	return itemList;
}

/*****
*
*	getSelection()
*
*****/
popupList.prototype.getSelection = function() {
	return this.listIndex[this.selection];
}

popupList.prototype.getSelectionName = function() {
	return this.itemList[ this.getSelection() ];
}

/*****
*
*   update
*		noAnimate is a boolean flag. when true, it updates the popupList with minimal fanfare.
*			if the popupList is closed, it will stay closed instead of blinking.
*			if the popupList is open, it will not blink after moving.
*			(blinking refers to defaults animation that fades in and out quickly)
*
*****/
popupList.prototype.update = function(noAnimate) {
	if(!this.nodes.listBox)
		return;

	if( this.active ) {
		// turn anchor off & all boxes on
		// if noAnimate is true and this isActive, then the list has already been opened
		//    and we don't have to do anything else
		if(!noAnimate) {
			this.anchorOff.beginElement();
			for(i=0;i<this.size;i++) {
				// move itemBox to position & make it visible
				y = (i-this.selection)*this.height;
				this.itemBoxSetY[i].setAttribute("from", this.itemBoxSetY[i].getAttribute("to")	);
				this.itemBoxSetY[i].setAttribute("to", "0," + y);
				this.itemBoxSetY[i].beginElement();
				this.itemBoxOn[i].beginElement();
				this.itemBackgroundOn[i].beginElement();
			}
		}
	}
	else {
		this.anchorOn.beginElement();
		// turn everything off except selected text 
		for(i=0;i<this.size;i++) {
			if( i == this.selection ) {
				this.itemBoxOn[i].beginElement();
				this.itemBackgroundOff[i].beginElement();
			}
			else {
				if(noAnimate)
					this.itemBoxOff[i].beginElement();
				else
					this.itemBoxOff[i].beginElementAt( this.itemBoxAnimSpeed );
			}
			this.itemHighlightOff[i].beginElement();
			// set up movement
			this.itemBoxSetY[i].setAttribute("from", this.itemBoxSetY[i].getAttribute("to"));
			this.itemBoxSetY[i].setAttribute("to", "0,0");
			// move boxes
			if(noAnimate) // make the movement instataneous
				this.itemBox[i].setAttribute("transform","translate(0,0)");
			else
				this.itemBoxSetY[i].beginElement();
		}
	}
}

/*****
*
*   init
*
*****/
popupList.prototype.init = function(x, y, itemList, callback, selection,
	anchorText, itemBackgroundText, itemHighlightText) {

	// call superclass initialization
	popupList.superclass.init.call(this, x, y);

	// set variables
	this.callback = callback;
	this.active = false;
	this.padding = 3;
	this.itemList = itemList;
	//	itemList could be an array with holes or a mix of a hash and array or anything
	//	popupList will return the INDEX of itemList that corrosponds with the selection
	//	listIndex holds these indexes
	this.listIndex = new Array();
	
	// make list of elements, find width & height
	this.itemText = new Array();
	var width = 0; 
	var height = 0;
	this.size = 0;
	for(i in itemList) {
		this.size++;
		var text = svgDocument.createElementNS( svgns, "text");
		text.appendChild( svgDocument.createTextNode(itemList[i]) );
		text.setAttributeNS(null, "y", "1em");
		text.setAttributeNS(null, "text-anchor", "middle");
		// add set text style
		this.itemText.push(text);
		this.listIndex.push(i);
		bbox = text.getBBox();
		width = Math.max(width, bbox.width);
		height = Math.max(height, bbox.height);
	}
	this.width = Math.round(width + 2*this.padding);
	this.height = Math.round(height + 2*this.padding);
	for(i in this.itemText)
		this.itemText[i].setAttributeNS(null, "x", Math.round(this.width/2) );
		
	// set selection
	if(selection == null) selection = 0;
	else {
		if(selection < 0) selection = 0;
		if(selection >= this.size) selection = this.size - 1;
	}
	this.selection = selection;

	// overwrite default appearances
	if(anchorText != null)
		this.anchorText = anchorText;
	if(itemBackgroundText != null)
		this.itemBackgroundText = itemBackgroundText;

	if(itemHighlightText != null)
		this.itemHighlightText = itemHighlightText;
		
}


/*****
*
*   buildSVG
*
*****/
popupList.prototype.buildSVG = function() {
	// set up translation for root node
	var transform = "translate(" + this.x + "," + this.y  + ")";

	// create root node
	root = svgDocument.createElementNS(svgns, "g");
	root.setAttributeNS(null, "transform", transform);
	this.nodes.root = root;
	this.nodes.parent.appendChild(root);

	// create anchor
	root.appendChild( this.textToSVG(this.anchorText) );
	this.nodes.anchor = root.lastChild;
	this.nodes.anchor.appendChild( this.textToSVG(this.onSwitchText) );
	this.anchorOn = this.nodes.anchor.lastChild;
	this.nodes.anchor.appendChild( this.textToSVG(this.offSwitchText) );
	this.anchorOff = this.nodes.anchor.lastChild;

	// create container to hold list elements
	this.nodes.listBox = svgDocument.createElementNS(svgns, "g");
	root.appendChild(this.nodes.listBox);

	// create list elements and add to appropriate container
	this.itemBox = new Array();
	this.itemBoxOn = new Array();
	this.itemBoxOff = new Array();
	this.itemBoxSetY = new Array();
	this.itemMouseCatcher = new Array();
	this.itemHighlightOn = new Array();
	this.itemHighlightOff = new Array();
	this.itemBackgroundOn = new Array();
	this.itemBackgroundOff = new Array();
	for(i=0;i<this.size;i++) {
		// add container, move it to position, add on/off animations & switches
		itemBox = svgDocument.createElementNS(svgns, "g");
		if( i!=this.selection)
			itemBox.setAttributeNS(null, "display","none");
		else
			itemBox.setAttributeNS(null,"display","inline");
		itemBox.appendChild( this.textToSVG(this.onSwitchText) );
		itemBoxOn = itemBox.lastChild;
		itemBox.appendChild( this.textToSVG(this.offSwitchText) );
		itemBoxOff = itemBox.lastChild;
		itemBox.appendChild( this.textToSVG(this.transformText) );
		itemBoxSetY = itemBox.lastChild;

		// add Background layer and on/off switches
		itemBox.appendChild( this.textToSVG(this.itemBackgroundText) );
		itemBackground = itemBox.lastChild;
		itemBackground.appendChild( this.textToSVG(this.onSwitchText) );
		itemBackgroundOn = itemBackground.lastChild;
		itemBackground.appendChild( this.textToSVG(this.offSwitchText) );
		itemBackgroundOff = itemBackground.lastChild;
		itemBackground.setAttribute( "display", "none");

		// add Highlight layer and on/off switches
		itemBox.appendChild( this.textToSVG(this.itemHighlightText) );
		itemHighlight = itemBox.lastChild;
		itemHighlight.appendChild( this.textToSVG(this.onSwitchText) );
		itemHighlightOn = itemHighlight.lastChild;
		itemHighlight.appendChild( this.textToSVG(this.offSwitchText) );
		itemHighlightOff = itemHighlight.lastChild;
		itemHighlight.setAttribute("display","none");

		// add text layer
		itemBox.appendChild( this.itemText[i] );

		// add mousecatcher layer
		itemBox.appendChild( this.textToSVG(this.itemMouseCatcherText) );
		itemMouseCatcher = itemBox.lastChild;

		// add itemBox to listBox
		this.nodes.listBox.appendChild(itemBox);

		// keep track of switches and mousecatcher for future use
		this.itemBox.push(itemBox);
		this.itemBoxOn.push(itemBoxOn);
		this.itemBoxOff.push(itemBoxOff);
		this.itemBoxSetY.push(itemBoxSetY);
		this.itemMouseCatcher.push(itemMouseCatcher);
		this.itemHighlightOn.push(itemHighlightOn);
		this.itemHighlightOff.push(itemHighlightOff);
		this.itemBackgroundOn.push(itemBackgroundOn);
		this.itemBackgroundOff.push(itemBackgroundOff);
	}
	if(this.size > 0)
		this.itemBoxAnimSpeed = this.itemBoxSetY[0].getAttributeNS( null, "dur" );
}

/*****
*
*   addEventListeners
*
*****/
popupList.prototype.addEventListeners = function() {
	for(i=0;i<this.size;i++) {
		this.itemMouseCatcher[i].addEventListener("click", this, false);
		this.itemMouseCatcher[i].addEventListener("mouseover", this, false);
		this.itemMouseCatcher[i].addEventListener("mouseout", this, false);
	}
}

/************   Event handlers   ************/

/*****
*
*   click
*
*****/
popupList.prototype.click = function(e) {
	// find where the click is
	for(i=0;i<this.size;i++)
		if(e.target==this.itemMouseCatcher[i]) break;

	// open the list?
	if(i==this.selection && this.active == false) {
		// make this popupList drawn on top of all else in parent node
		this.nodes.parent.removeChild(this.nodes.root);
		this.nodes.parent.appendChild(this.nodes.root);

		// do the popup
		this.active=true;
		this.update();
		return;
	}

	// set selection
	if(this.active) {
		this.active=false;
		this.setSelection(i);
	}
}

/*****
*
*   mouseover
*
*****/
popupList.prototype.mouseover = function(e) {
	// find the mouse...
	for(i=0;i<this.size;i++)
		if(e.target==this.itemMouseCatcher[i]) break;
	// ...and highlight the target
	this.itemHighlightOn[i].beginElement();
}

/*****
*
*   mouseout
*
*****/
popupList.prototype.mouseout = function(e) {
	// find the mouse...
	for(i=0;i<this.size;i++)
		if(e.target==this.itemMouseCatcher[i]) break;
	// ...and unhighlight the target
	this.itemHighlightOff[i].beginElement();
}


/***************** Functions not part of the class ******************/

/*****
*
*   findAnimationsInNode
*
*****/
function findAnimationsInNode( node ) {
	var animations =
		node.getElementsByTagNameNS( svgns, "animateTransform");
	if(animations.length ==0)
		animations = node.getElementsByTagNameNS( svgns,"animate");
	if(animations.length ==0)
		animations = node.getElementsByTagNameNS( svgns,"animateMotion");
	if(animations.length ==0)
		animations = node.getElementsByTagNameNS( svgns,"animateColor");
	return animations;
}
