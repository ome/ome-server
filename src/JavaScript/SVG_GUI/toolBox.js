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
'<rect width="{$width}" height="15" fill="blue" opacity="0.3"/>';

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
// is hidden. buildSVG sets it to the duration of GUIbox's off animation.
toolBox.prototype.GUIboxHideDelay = 1;


/*****
*
*   toolBox constructor
*
*     Parameter description:
*		x,y = x,y of upper left corner of toolbox
*		width = width of toolbox
*		height = height of GUIbox
*       The last three parameters are optional. They allow the user to control
*       the appearance of the toolBox. width of menuBar and GUIbox should be
*		{$width} wide. GUIbox should be "{$height}" tall.
*		hideControl needs to have animations. The first animation will be
*		called when the control is activated, the second when deactivated.
*		If you do not specify animations for GUIbox, it will fade in and out.
*		If you specify animations for GUIbox they will be called in the same
*		fashion	as hideControl's.
*		GUIbox may have elements placed inside it. Use a g or something similar
*		for the root node if you plan on doing that.
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
	this.hidden = false;
	
	// allow user defined custimization of apperance
	if( menuBarText != null ) this.menuBarText = menuBarText;
	if( hideControlText != null ) this.hideControlText = hideControlText;
	if( GUIboxText != null ) this.GUIboxText = GUIboxText;
}

/*****
*
*   realize
*		overrides method in widget for purposes of putting label in proper position
*
*****/
toolBox.prototype.realize = function(svgParentNode) {
    this.nodes.parent = svgParentNode;

    this.buildSVG();
    this.addEventListeners();
    if( this.nodes.label )
    	this.nodes.menuBar.appendChild( this.nodes.label );
};


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
	this.nodes.root = box;
	this.nodes.parent.appendChild(box);
	
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

	// create menuBar. I'm putting stuff in it, so I'm making sure it has a g
	// for a root node.
	this.nodes.menuBar = svgDocument.createElementNS(svgns, 'g');
	this.nodes.menuBar.appendChild( this.textToSVG(this.menuBarText) );
	box.appendChild( this.nodes.menuBar );
	var menuHeight = this.nodes.menuBar.getBBox().height;
	
	// create hideControl, move into position, & append to menuBar
	this.nodes.menuBar.appendChild( this.textToSVG(this.hideControlText) );
	this.nodes.hideControl = this.nodes.menuBar.lastChild;

	// Find the animation controls.
	var hideControlAnimations = findAnimationsInNode( this.nodes.hideControl );
	this.hideControlAnimate1 = hideControlAnimations.item(0);
	this.hideControlAnimate2 = hideControlAnimations.item(1);
	
	// Look for GUIboxAnimations. If not found, add standard animations.
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
	
	// Add on and off switches to control GUIbox display & root
	this.nodes.GUIbox.appendChild( this.textToSVG( this.onSwitchText ));
	this.GUIboxOn = this.nodes.GUIbox.lastChild;
	this.nodes.GUIbox.appendChild( this.textToSVG( this.offSwitchText ));
	this.GUIboxOff = this.nodes.GUIbox.lastChild;
	this.GUIboxHideDelay = this.GUIboxAnimate2.getAttributeNS( null, "dur" );
	this.nodes.root.appendChild( this.textToSVG( this.onSwitchText ));
	this.rootOn = this.nodes.root.lastChild;
	this.nodes.root.appendChild( this.textToSVG( this.offSwitchText ));
	this.rootOff = this.nodes.root.lastChild;

	
	// Move hideControl and GUIbox to proper position
	var hideY = Math.round( menuHeight/2 );
	var hideX = this.width - hideY;
	this.nodes.hideControl.setAttribute("transform", "translate(" + hideX + "," + hideY +")" );

	GUIboxContainer.setAttributeNS(null, "transform", "translate(0,"+ menuHeight +")");
}

/*****
*
*	closeOnMinimize(val)
*
*****/
toolBox.prototype.closeOnMinimize = function(val) {
	if(val) 
		this.CLOSE_ON_MINIMIZE = true;
	else
		this.CLOSE_ON_MINIMIZE = false;
}

/****************   Get functions   **********************/

/*****
*
*   getGUIbox
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

/****************   Set functions   **********************/

/*****
*
*   setLabel
*      overrides function in Widget
*
*****/
toolBox.prototype.setLabel = function(x, y, content) {
	if(!this.nodes.label) {
		this.nodes.label = svgDocument.createElementNS( "http://www.w3.org/2000/svg", "text" );
		this.nodes.label.appendChild( svgDocument.createTextNode(content) );
    	if( this.nodes.menuBar )
    		this.nodes.menuBar.appendChild( this.nodes.label );
    }
    else
    	this.nodes.label.firstChild.data = content;
	if(x!=null) this.nodes.label.setAttribute( "x", x );
	if(y!=null) this.nodes.label.setAttribute( "y", y );
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
	if(this.hideControlAnimate1)
		this.hideControlAnimate1.beginElement();
	this.GUIboxAnimate1.beginElement();
	this.GUIboxOff.beginElementAt(this.GUIboxHideDelay);
	if(this.CLOSE_ON_MINIMIZE)
		this.rootOff.beginElementAt(this.GUIboxHideDelay);
	
}


/*****
*
*  unhide
*
*****/
toolBox.prototype.unhide = function() {
	this.hidden = false;
	
	// begin animations
	if(this.hideControlAnimate2)
		this.hideControlAnimate2.beginElement();
	this.GUIboxOn.beginElement();
	this.GUIboxAnimate2.beginElement();
	if(this.CLOSE_ON_MINIMIZE)
		this.rootOn.beginElement();
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
	this.nodes.hideControl.addEventListener("click", this, false);
}


/************   Event handlers   ************/

/*****
*
*   mousedown
*
*****/
toolBox.prototype.mousedown = function(e) {
	svgDocument.documentElement.addEventListener("mousemove", this, false);
	this.localPoint = this.getUserCoordinate(this.nodes.root, e.clientX, e.clientY);
}

/*****
*
*   mouseup
*
*****/
toolBox.prototype.mouseup = function(e) {
	svgDocument.documentElement.removeEventListener("mousemove", this, false);
}

/*****
*
*   mousemove
*
*****/
toolBox.prototype.mousemove = function(e) {
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
