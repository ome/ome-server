/*****

button.js
	external files dependencies: widget.js
Known bugs:
	#1. Calling setState shortly after button is drawn will not update
the button's animations. I believe this is due to viewer implementation.
	Setting setState to be called after a delay of 0 is an easy way of
bypassing this bug. i.e. setTimeout( "button1.setState(false)", 0 );

My development vocabulary:
	untested: the function has not been run
	tested: the function runs and appears to works as advertised
	comprehensively tested: i've checked the output and side effects fairly throughly

*****/

svgns = "http://www.w3.org/2000/svg";

/*****
*
*   button inheritance
*
*****/

button.prototype = new Widget();
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
		Animation notes:
			onText and offText can (optionally) include animations to 
			override the default animation of fading in and out. The 
			first animation should turn	it on, the second should turn it off.
			offText should initially be in it's "off" state.

	tested

*****/
function button(x, y, callback, onText, offText, highlightText) {
	if(arguments.length >= 3)
		this.init(x, y, callback, onText, offText, highlightText);
}

/*****

	setState(val)
		control to turn button on or off
		val == true ? button is turned on : button is turned off

	tested

*****/
button.prototype.setState = function(val) {
	if(val) {
		this.isOn = true;
		if(this.nodes.on) {
			this.onAnimOn.beginElement();
			this.offAnimOff.beginElement();
		}
	}
	else {
		this.isOn = false;
		if(this.nodes.on) {
			this.onAnimOff.beginElement();
			this.offAnimOn.beginElement();
		}
	}
	this.callback(val);
}

/*****

	setHighlight(val)
		turns Highlight feature on & off
	
	comprehensively tested
	
*****/
button.prototype.setHighlight = function(val) {
	if(val)
		this.HIGHLIGHT_OFF = false;
	else
		this.HIGHLIGHT_OFF = true;
}

/*****

	getState()
		returns true if button is on
		returns false if button is off
	
	comprehensively tested

*****/
button.prototype.getState = function() {
	if(isOn)
		return true;
	else
		return false;
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init

	tested

*****/
button.prototype.init = function(x, y, callback, onText, offText, highlightText) {

	// call superclass initialization
	button.superclass.init.call(this, x, y);

	// set variables
	this.callback = callback;
	this.isOn = true;

	// override default appearances
	if(onText != null)
		this.onText = onText;
	if(offText != null)
		this.offText = offText;
	if(highlightText != null)
		this.highlightText = highlightText;
}


/*****

	buildSVG

	tested

*****/
button.prototype.buildSVG = function() {
	// set up translation for root node
	var transform = "translate(" + this.x + "," + this.y  + ")";
	
	// create root node
	root = svgDocument.createElementNS(svgns, "g");
	root.setAttributeNS(null, "transform", transform);
	this.nodes.root = root;
	this.nodes.parent.appendChild(root);

	// create off appearance
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
	}

	// create on appearance
	root.appendChild( this.textToSVG(this.onText) );
	this.nodes.on = root.lastChild;
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
	}

	// create highlight
	root.appendChild( this.textToSVG(this.highlightText) );
	this.nodes.highlight = root.lastChild;
	this.nodes.highlight.appendChild( this.textToSVG(this.onSwitchText) );
	this.highlightAnimOn = this.nodes.highlight.lastChild;
	this.nodes.highlight.appendChild( this.textToSVG(this.offSwitchText) );
	this.highlightAnimOff = this.nodes.highlight.lastChild;
	this.nodes.highlight.setAttribute("opacity",0);
	
}

/*****

	addEventListeners

	tested

*****/
button.prototype.addEventListeners = function() {
	this.nodes.highlight.addEventListener("click", this, false);
	this.nodes.highlight.addEventListener("mouseover", this, false);
	this.nodes.highlight.addEventListener("mouseout", this, false);
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
