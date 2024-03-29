/*****

button.js



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
	

Known bugs:
	#1. Calling setState shortly after button is drawn will not update
the button's animations. I believe this is due to viewer implementation.
	Setting setState to be called after a delay of 0 is an easy way of
bypassing this bug. i.e. setTimeout( "button1.setState(false)", 0 );

*****/

svgns = "http://www.w3.org/2000/svg";

/*****
*
*   button inheritance
*
*****/

button.prototype = new Widget();
button.VERSION = 0.2;
button.prototype.constructor = button;
button.superclass = Widget.prototype;

/*****
*
*   Class variables
*
*****/

button.VERSION = 1;
button.prototype.onText = 
'<circle cy="5" r="5" fill="white" stroke="black" stroke-width="1"/>';
button.prototype.offText = 
'<circle cy="5" r="5" fill="black" stroke="white" stroke-width="1"/>';
button.prototype.highlightText = 
'<circle cy="5" r="5" fill="cyan" opacity="0"/>';
button.prototype.mouseTrapText = 
'<rect x="$x" y="$y" width="$width" height="$height" opacity="0"/>';
button.prototype.onSwitchText = 
'<set attributeName="opacity" to="0.3" begin="indefinite"/>';
button.prototype.offSwitchText = 
'<set attributeName="opacity" to="0" begin="indefinite"/>';
button.prototype.fadeInText = 
'<animate attributeName="opacity" from="0" to="1"' +
'	dur="0.1s" fill="freeze" repeatCount="0" restart="whenNotActive"' +
'	begin="indefinite"/>';
button.prototype.fadeOutText = 
'<animate attributeName="opacity" from="1" to="0"' +
'	dur="0.1s" fill="freeze" repeatCount="0" restart="whenNotActive"' +
'	begin="indefinite"/>';


/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****
	constructor
		variable explanations:
			x, y = obvious
			callback = function to call when a item is selected by the user
		The rest of these variables are optional.
			state == true ? button = on : button = off
			onText = svg tags to overwrite default 'on' apperance
			offText = svg tags to overwrite default 'off' apperance
			highlightText = svg tags to overwrite default highlight
		Button notes:
			If onText if specified and offText isn't, then the button will
			not change appearance.
		Animation notes:
			onText and offText can (optionally) include animations to 
			override the default animation of fading in and out. The 
			first animation should turn	it on, the second should turn it off.
			offText should initially be in it's "off" state.
			Animations will only be used if there is both an on and an off
			button.

	tested

*****/
function button(x, y, callback, onText, offText, highlightText) {
	this.init(x, y, callback, onText, offText, highlightText);
}

/*****

	setState(val)
		control to turn button on or off
		val == true ? button is turned on : button is turned off

	tested

*****/
button.prototype.setState = function(val, noCallBack) {
	if(val) {
		this.isOn = true;
		// have we been initialized? does on have an animation?
		if(this.nodes.on && this.onAnimOn) {
			this.onAnimOn.beginElement();
			if(this.offAnimOff)
				this.offAnimOff.beginElement();
		}
	}
	else {
		this.isOn = false;
		// have we been initialized? does on have an animation?
		if(this.nodes.on && this.onAnimOff) {
			this.onAnimOff.beginElement();
			if(this.offAnimOn)
				this.offAnimOn.beginElement();
		}
	}
	if(!noCallBack) { this.issueCallback(val); }
}


button.prototype.issueCallback = function(value) {
	if( this.callback_obj && this.callback) { 
		eval( "this.callback_obj."+this.callback+"(value)"); 
	} else { 
		if( this.callback) { this.callback(value); } 
	}
};


button.prototype.setHighlight = function(val) {
	if(val && this.highlightText != null)
		this.HIGHLIGHT_OFF = false;
	else
		this.HIGHLIGHT_OFF = true;
};

button.prototype.getState = function() {
	if(this.isOn)
		return true;
	else
		return false;
};

/********************************************************************************************
                                Private Functions 
********************************************************************************************/

/*****

	init

	tested

*****/
button.prototype.init = function(x, y, callback, onText, offText, highlightText) {
	var isOn = true;
	if( x.constructor !== Number ) {
		y = x['y'];
		callback = x['callback'];
		onText = x['onText']; 
		offText = x['offText']; 
		highlightText = x['highlightText']; 
		isOn = x['isOn']; 
		x = x['x'];
	}

	// call superclass initialization
	button.superclass.init.call(this, x, y);

	// record initialization params...
	if( !callback || Util.isFunction(callback) ) {
		this.callback = callback;
	} else {
		this.callback = callback['method'];
		this.callback_obj = callback['obj'];
	}
	if( isOn ) {
		this.isOn = true;
	} else {
		this.isOn = false;
	}

	// override default appearances
	if(onText != null)
		this.onText = onText;

	if(offText != null)
		this.offText = offText;
	else if( onText!=null )
		this.offText = null;

	if(highlightText != null)
		this.highlightText = highlightText;
	else if( onText !=null )
		this.highlightText = null;
}


/*****

	buildSVG

	tested

*****/
button.prototype.buildSVG = function() {
	// set up translation for root node
	var transform = "translate(" + this.x + "," + this.y  + ")";
	
	// create root node
	root = document.createElementNS(svgns, "g");
	root.setAttributeNS(null, "transform", transform);
	this.nodes.root = root;
	this.nodes.parent.appendChild(root);

	// create off appearance. It goes on the bottom.
	if(this.offText) {
		root.appendChild( this.textToSVG(this.offText) );
		this.nodes.off = root.lastChild;
		switches = findAnimationsInNode( this.nodes.off );
		if(switches.length == 2) {
			this.offAnimOn = switches.item(0);
			this.offAnimOff = switches.item(1);
		}
		else {
			this.nodes.off.appendChild( this.textToSVG(this.fadeInText) );
			this.offAnimOn = this.nodes.off.lastChild;
			this.nodes.off.appendChild( this.textToSVG(this.fadeOutText) );
			this.offAnimOff = this.nodes.off.lastChild;
			if( this.isOn ) {
				this.nodes.off.setAttribute("opacity", 0);
			}
		}
	}

	// create on appearance. It goes in the middle.
	root.appendChild( this.textToSVG(this.onText) );
	this.nodes.on = root.lastChild;
	// we only need animations if there is also an off apperance
	if(this.offText) {
		switches = findAnimationsInNode( this.nodes.on );
		if(switches.length == 2) {
			this.onAnimOn = switches.item(0);
			this.onAnimOff = switches.item(1);
		}
		else {
			this.nodes.on.appendChild( this.textToSVG(this.fadeInText) );
			this.onAnimOn = this.nodes.on.lastChild;
			this.nodes.on.appendChild( this.textToSVG(this.fadeOutText) );
			this.onAnimOff = this.nodes.on.lastChild;
			if( this.isOn !== true ) {
				this.nodes.on.setAttribute("opacity", 0);
			}
		}
	}

	// create highlight. It goes on top.
	if(this.highlightText) {
		this.HIGHLIGHT_OFF = false;
		root.appendChild( this.textToSVG(this.highlightText) );
		this.nodes.highlight = root.lastChild;
		this.nodes.highlight.appendChild( this.textToSVG(this.onSwitchText) );
		this.highlightAnimOn = this.nodes.highlight.lastChild;
		this.nodes.highlight.appendChild( this.textToSVG(this.offSwitchText) );
		this.highlightAnimOff = this.nodes.highlight.lastChild;
		this.nodes.highlight.setAttribute("opacity",0);
		this.nodes.mouseTrap = this.nodes.highlight;
	}
	else {
		this.HIGHLIGHT_OFF = true;
		// magic to install a mousecatcher that will notice the clicks
		var bbox = this.nodes.root.getBBox();
		this.width = Math.round( bbox.width );
		this.height = Math.round( bbox.height );
		var o_y = this.y;
		var o_x = this.x;
		this.y = Math.round( bbox.y );
		this.x = Math.round( bbox.x );
		root.appendChild( this.textToSVG(this.mouseTrapText) );
		this.nodes.mouseTrap = root.lastChild;
		this.y = o_y;
		this.x = o_x;
	}
	
}

/*****

	addEventListeners

	tested

*****/
button.prototype.addEventListeners = function() {
	if(this.highlightText) {
		this.nodes.highlight.addEventListener("mouseover", this, false);
		this.nodes.highlight.addEventListener("mouseout", this, false);
	}
	this.nodes.mouseTrap.addEventListener("click", this, false);
}

/************   Event handlers   ************/

/*****

	click

	tested

*****/
button.prototype.click = function(e) {
	// switch value
	if(this.isOn)
		this.setState(false);
	else
		this.setState(true);
}

/*****

	mouseover

	tested

*****/
button.prototype.mouseover = function(e) {
	// turn highlight on
	if(!this.HIGHLIGHT_OFF)
		this.highlightAnimOn.beginElement();
}

/*****

	mouseout

	tested

*****/
button.prototype.mouseout = function(e) {
	// turn highlight on
	if(!this.HIGHLIGHT_OFF)
		this.highlightAnimOff.beginElement();
}

/***************** Functions not part of the class ******************/

/*****

	findAnimationsInNode


	comprehensively tested

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
