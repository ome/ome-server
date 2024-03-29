/*****
*
*   Widget.js
*
*   copyright 2002, Kevin Lindsey
*
*****/

/*****
*
*   Class variables
*
*****/
Widget.VERSION = 1.0;


/*****
*
*   constructor
*
*****/
function Widget(x, y) {
    if ( arguments.length > 0 ) {
        this.init(x, y);
    }
}


/*****
*
*   init
*
*****/
Widget.prototype.init = function(x, y) {
    this.x     = x;
    this.y     = y;
    this.nodes = new Object();
    var svgRoot = document.documentElement;

    // Initialize properties for anti-zoom and pan;
    this.x_trans  = 0;
    this.y_trans  = 0;
    this.scale    = 1;
    this.lastTM   = svgRoot.createSVGMatrix();

    // Setup event listeners to capture zoom and scroll events
    svgRoot.addEventListener('SVGZoom',   this, false);
    svgRoot.addEventListener('SVGScroll', this, false);
    svgRoot.addEventListener('SVGResize', this, false);
};


/*****
*
*   realize
*
*****/
Widget.prototype.realize = function(svgParentNode) {
    this.nodes.parent = svgParentNode;

    // The following 2 lines were added by Josiah Johnston on 11/13/02
    if( this.nodes.label )
    	svgParentNode.appendChild( this.nodes.label );
    	
    this.buildSVG();
    this.addEventListeners();
};


/*****
*
*   buildSVG
*
*****/
Widget.prototype.buildSVG = function() {
    // abstract method
};


/*****
*
*   addEventListeners
*
*****/
Widget.prototype.addEventListeners = function() {
    // abstract method
};

/*****
*
*   setLabel
*      added by Josiah Johnston 11/13/02
*
*****/
Widget.prototype.setLabel = function(x, y, content) {
	if(!this.nodes.label) {
		this.nodes.label = document.createElementNS( "http://www.w3.org/2000/svg", "text" );
		this.nodes.label.appendChild( document.createTextNode(content) );
    	if( this.nodes.parent )
    		this.nodes.parent.appendChild( this.nodes.label );
    }
    else
    	this.nodes.label.firstChild.data = content;
	if(x!=null) this.nodes.label.setAttribute( "x", x+this.x );
	if(y!=null) this.nodes.label.setAttribute( "y", y+this.y );
}

/*****
*
*   getLabel
*      added by Josiah Johnston 11/13/02
*
*****/
Widget.prototype.getLabel = function() {
	return this.nodes.label;
};

/*****
*
*   alignUpperRight
*      added by Josiah Johnston 2/4/04
*
*****/
Widget.prototype.alignUpperRight = function() {
	this.move( this.x - this.width, this.y );
};

/*****
*
*   alignUpperLeft
*      added by Josiah Johnston 2/4/04
*
*****/
Widget.prototype.alignUpperLeft = function() {
	this.move( this.x, this.y );
};

/*****
*
*   alignLowerRight
*      added by Josiah Johnston 2/4/04
*
*****/
Widget.prototype.alignLowerRight = function() {
	this.move( this.x - this.width, this.y - this.height );
};

/*****
*
*   alignLowerLeft
*      added by Josiah Johnston 2/4/04
*
*****/
Widget.prototype.alignLowerLeft = function() {
	this.move( this.x, this.y - this.height );
};

/*****
*
*   move
*      added by Josiah Johnston 2/4/04
*
*****/
Widget.prototype.move = function(x,y) {
	if( !x && x !== 0 ) { x = this.x; }
	if( !y && y !== 0 ) { y = this.y; }
	var transform = "translate(" + x + "," + y  + ")";
	this.nodes.root.setAttributeNS(null, "transform", transform);
};


/*****
*
*   textToSVG
*
*****/
Widget.prototype.textToSVG = function(text) {
    var self = this;
    var svg  = text.replace(
        /\$(\{[a-zA-Z][-a-zA-Z]*\}|[a-zA-Z][-a-zA-Z]*)/g,
        function(property) {
            var name = property.replace(/[\$\{\}]/g, "");

            return self[name];
        }
    ).replace(
        /\{[^\}]+\}/g,
        function(functionText) {
            return eval( functionText.substr(1, functionText.length - 2) );
        }
    );

    return parseXML(svg, document);
};


/*****
*
*   getUserCoordinate
*
*****/
Widget.prototype.getUserCoordinate = function(node, x, y) {
    var svgRoot    = document.documentElement;
    var pan        = svgRoot.getCurrentTranslate();
    var zoom       = svgRoot.getCurrentScale();
    var CTM        = this.getTransformToElement(node);
    var iCTM       = CTM.inverse();
    var worldPoint = document.documentElement.createSVGPoint();
    
    worldPoint.x = (x - pan.x) / zoom;
    worldPoint.y = (y - pan.y) / zoom;

    return worldPoint.matrixTransform(iCTM);
};


/*****
*
*   getTransformToElement
*
*****/
Widget.prototype.getTransformToElement = function(node) {
    var CTM = node.getCTM();

    while ( (node = node.parentNode) != document ) {
        CTM = node.getCTM().multiply(CTM);
    }
    
    return CTM;
};


/*****	Event Handlers	*****/

/*****
*
*   handleEvent
*
*****/
Widget.prototype.handleEvent = function(e) {
    if ( e.type in this ) this[e.type](e);
};
