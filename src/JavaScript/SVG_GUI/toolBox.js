/*****
*    
*   toolBox.js
*     external files dependecies: widget.js
*     Known bugs:
*       bug #1:
*          Attempting to unhide the GUIbox while it it hiding causes
*       it to turn invisible. It can be made visible by hiding and unhiding 
*       it again.
*     Author: Josiah Johnston
*     email: johnstonjo@grc.nia.nih.gov
*
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****
*
*   setup inheritance
*
*****/
toolBox.prototype = new Widget();
toolBox.prototype.constructor = toolBox;
toolBox.superclass = Widget.prototype;

/*****
*
*   Class variables
*
*****/
toolBox.VERSION = 1.0;

toolBox.prototype.menuBarText = 
'<g>' +
'	<rect width="{$width}" height="15" fill="blue" opacity="0.3"/>' +
'</g>';

toolBox.prototype.hideControlText = 
'<g>' +
'	<g transform="rotate(90)">' +
'		<path d="M -5,-3 l 0,6 l 9,-3 z" fill="purple" ' +
'			stroke="green" stroke-width="1" opacity="0.9"/>' +
'		<animateTransform attributeName="transform"' +
'			type="rotate" from="90" to="0" dur="0.1s" fill="freeze"' +
'			repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'		<animateTransform attributeName="transform"' +
'			type="rotate" from="0" to="90" dur="0.1s" fill="freeze"' +
'			repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'	</g>' +
'</g>';

toolBox.prototype.GUIboxText = 
'<g>' +
'	<rect width="{$width}" height="{$height}" fill="black" opacity="0.2"/>' +
'</g>';
toolBox.prototype.fadeInText = 
'<animate attributeName="opacity" from="0" to="1" dur="0.1s" fill="freeze"' +
'	repeatCount="0" restart="whenNotActive"	begin="indefinite"/>';
toolBox.prototype.fadeOutText = 
'<animate attributeName="opacity" from="1" to="0" dur="0.1s" fill="freeze"' +
'	repeatCount="0" restart="whenNotActive"	begin="indefinite"/>';
toolBox.prototype.onSwitchText = 
'<set attributeName="display" to="inline" begin="indefinite"/>';
toolBox.prototype.offSwitchText = 
'<set attributeName="display" to="none" begin="indefinite"/>';

// GUIboxHideDelay is the delay from clicking hideControl till GUIbox's display
// is hidden. It should match the animations' duration.
toolBox.prototype.GUIboxHideDelay = 1;


/*****
*
*   toolBox constructor
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
function toolBox(x,y,width,height,menuBarText,hideControlText,GUIboxText) {
	if(arguments.length > 0 )
		this.init(x,y,width,height,menuBarText,hideControlText,GUIboxText);
}

/*****
*
*   init
*
*****/
toolBox.prototype.init = function( x, y, width, height, menuBarText,
		hideControlText, GUIboxText) {
	// call superclass method
	toolBox.superclass.init.call(this,x,y);
	
	// init properties
	this.height = height;
	this.width = width;
	this.activeMove = false;
	this.hidden = false;
	this.GUIboxScale = 1;
	
	// allow user defined custimization of apperance
	if( menuBarText != null ) this.menuBarText = menuBarText;
	if( hideControlText != null ) this.hideControlText = hideControlText;
	if( GUIboxText != null ) this.GUIboxText = GUIboxText;
}

/*****
*
*   buildSVG
*
*****/
toolBox.prototype.buildSVG = function() {
	// set up movement of location
	var translate = "translate(" + this.x + "," + this.y + ")";
	var transform = translate;
	var box = svgDocument.createElementNS(svgns, "g");
	box.setAttribute("transform", transform);
	
	// Add toolBox components and keep track of them.
	var GUIboxContainer = svgDocument.createElementNS(svgns, "g");
	var GUIboxBorder = svgDocument.createElementNS(svgns, "svg");
	GUIboxBorder.setAttributeNS( null, "width", this.width );
	GUIboxBorder.setAttributeNS( null, "height", this.height );
	GUIboxBorder.appendChild( this.textToSVG(this.GUIboxText) );
	GUIboxContainer.appendChild( GUIboxBorder );
	box.appendChild( GUIboxContainer );
	this.nodes.GUIbox = GUIboxBorder.lastChild;
	this.nodes.GUIboxContainer = GUIboxContainer;
	this.nodes.GUIboxBorder = GUIboxBorder;

	box.appendChild( this.textToSVG(this.menuBarText) );
	this.nodes.menuBar = box.lastChild;
	
	box.appendChild( this.textToSVG(this.hideControlText) );
	this.nodes.hideControl = box.lastChild;

	this.nodes.root = box;
	this.nodes.parent.appendChild(box);
	// draw the label on top of everything else
	if(this.nodes.label) {
		this.nodes.label.getParentNode().removeChild( this.nodes.label );
		box.appendChild(this.nodes.label);
		labelx = this.nodes.label.getAttributeNS(null, "x");
		labely = this.nodes.label.getAttributeNS(null, "y");
		this.nodes.label.setAttributeNS(null, "x", labelx - this.x);
		this.nodes.label.setAttributeNS(null, "y", labely - this.y);
	}

	// Find the animation controls.
	var hideControlAnimations = findAnimationsInNode( this.nodes.hideControl );
	this.hideControlAnimate1 = hideControlAnimations.item(0);
	this.hideControlAnimate2 = hideControlAnimations.item(1);
	var GUIboxAnimations = findAnimationsInNode( this.nodes.GUIbox );
	if(GUIboxAnimations.length == 2) {
		this.GUIboxAnimate1 = GUIboxAnimations.item(0);
		this.GUIboxAnimate2 = GUIboxAnimations.item(1);
	}
	else {
		this.nodes.GUIbox.appendChild( this.textToSVG( this.fadeOutText ));
		this.GUIboxAnimate1 = this.nodes.GUIbox.lastChild;
		this.nodes.GUIbox.appendChild( this.textToSVG( this.fadeInText ));
		this.GUIboxAnimate2 = this.nodes.GUIbox.lastChild;
	}
	this.nodes.GUIbox.appendChild( this.textToSVG( this.onSwitchText ));
	this.GUIboxOn = this.nodes.GUIbox.lastChild;
	this.nodes.GUIbox.appendChild( this.textToSVG( this.offSwitchText ));
	this.GUIboxOff = this.nodes.GUIbox.lastChild;
	this.GUIboxHideDelay = this.GUIboxAnimate2.getAttributeNS( null, "dur" );
	
	// Move hideControl and GUIbox to proper position
	var newX = this.width - 8;
	translate = "translate(" + newX + ",8 )";
	transform = translate;
	this.nodes.hideControl.setAttributeNS(null, "transform", transform );
	GUIboxContainer.setAttributeNS(null, "transform", "translate(0,15)");
}


/****************   Get functions   **********************/

/*****
*
*   get GUIbox
*
*****/
toolBox.prototype.getGUIbox = function(){
	return this.nodes.GUIbox;
}

/*****
*
*	getMenuBar
*
*****/
toolBox.prototype.getMenuBar = function() {
	return this.nodes.menuBar;
}

/****************   Visual functions   *******************/

/*****
*
*   hide
*
*****/
toolBox.prototype.hide = function() {
	this.hidden = true;
	
	// begin animations
	this.hideControlAnimate1.beginElement();
	this.GUIboxAnimate1.beginElement();
	this.GUIboxOff.beginElementAt(this.GUIboxHideDelay);
	
}


/*****
*
*  unhide
*
*****/
toolBox.prototype.unhide = function() {
	this.hidden = false;
	
	// begin animations
	this.GUIboxOn.beginElement();
	this.hideControlAnimate2.beginElement();
	this.GUIboxAnimate2.beginElement();
}

/*****
*
*   close
*
*	untested
*
*****/
toolBox.prototype.close = function() {
	if(this.nodes.root)
		this.nodes.root.setAtribute("display", "none");
}


/*****
*
*   open
*
*	untested
*
*****/
toolBox.prototype.open = function() {
	if(this.nodes.root)
		this.nodes.root.setAtribute("display", "inline");
}

/*****
*
*   move
*
*****/
toolBox.prototype.move = function(e) {
	this.x = e.clientX - this.localPoint.x;
	this.y = e.clientY - this.localPoint.y;
	var translate = "translate(" + this.x + "," + this.y + ")";
	this.nodes.root.setAttributeNS(null, "transform", translate);
}

/*****
*
*   addEventListeners
*
*****/
toolBox.prototype.addEventListeners = function() {
	this.nodes.menuBar.addEventListener("mousedown", this, false);
	this.nodes.menuBar.addEventListener("mouseup", this, false);
	svgDocument.documentElement.addEventListener("mousemove", this, false);
	this.nodes.hideControl.addEventListener("click", this, false);
}


/************   Event handlers   ************/

/*****
*
*   mousedown
*
*****/
toolBox.prototype.mousedown = function(e) {
	this.activeMove=true;
	this.localPoint = this.getUserCoordinate(this.nodes.root, e.clientX,
		e.clientY);
}

/*****
*
*   mouseup
*
*****/
toolBox.prototype.mouseup = function(e) {
	this.activeMove=false;
}

/*****
*
*   mousemove
*
*****/
toolBox.prototype.mousemove = function(e) {
	if(this.activeMove) 
		this.move(e);
}

/*****
*
*   click
*
*****/
toolBox.prototype.click = function(e) {
	if(this.hidden)
		this.unhide();
	else
		this.hide();		
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
