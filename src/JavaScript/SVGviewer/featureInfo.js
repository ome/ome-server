/*****

	featuresInfo.js
		external file dependencies: widget.js, slider.js, button.js, popupList.js, skinLibrary.js
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

var svgns = "http://www.w3.org/2000/svg";

/*****

	class variables
	
*****/
FeatureInfo.VERSION = 0.1;
FeatureInfo.prototype.templateText = 
'<g>'+
'<text x="20" y="2em">ID: </text><text x="180" y="2em" id="id"> </text>'+
'<text x="20" y="3em">Tag: </text><text x="180" y="3em" id="tag" text-anchor="end"> </text>'+
'<text x="20" y="4em">Name: </text><text x="180" y="4em" id="name" text-anchor="end"> </text>'+
'</g>';
FeatureInfo.prototype.labelText = [ 
	'<text x="20" y="2em">ID: </text>',
	'<text x="20" y="3em">Tag: </text>',
	'<text x="20" y="4em">Name: </text>'
];
FeatureInfo.prototype.fieldText = [
	'<text x="180" y="2em" id="featureID"> </text>',
	'<text x="180" y="3em" id="featureTag" text-anchor="end"> </text>',
	'<text x="180" y="4em" id="featureName" text-anchor="end"> </text>'
];

/********************************************************************************************/
/********************************************************************************************/
/*************************** Functions open to the world ************************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	constructor
		image = OMEimage
		updateBlack = function for black slider to call
		updateWhite = function for white slider to call
		waveChagne = function for wave popuplist to call
		
	tested

*****/
function FeatureInfo(featureData) {
	this.init( featureData );
}

FeatureInfo.prototype.buildToolBox = function( controlLayer ) {
	this.toolBox = new toolBox(
		155, 265, 200, 100
	);
	this.toolBox.setLabel(90,12,"Feature Information")
	this.toolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
	this.toolBox.realize( controlLayer );
	this.displayPane = this.toolBox.getGUIbox();
	this.displayPane.appendChild( this.buildDisplay() );
	
}

FeatureInfo.prototype.constructTemplate = function() {
	
	var displayPane = svgDocument.createElementNS( svgns, "g" );
	for( id in this.featureData ) break;
	var lineCount = 0;
	for( i in this.featureData[id] ) {
		var newLabel = svgDocument.createElementNS( svgns, "text" );
		newLabel.setAttribute( "x", 20 );
		newLabel.setAttribute( "y", (2+lineCount) + 'em' );
		newLabel.appendChild( svgDocument.createTextNode( i ) );
		this.labels[ i ] = newLabel;
		
		var newField = svgDocument.createElementNS( svgns, "text" );
		newField.setAttribute( "x", 180 );
		newField.setAttribute( "y", (2+lineCount) + 'em' );
		newField.setAttribute( "text-anchor", 'end' );
		this.fields[ i ] = newField;

		displayPane.appendChild( newLabel );
		displayPane.appendChild( newField );
		
		lineCount++;
	}

	return displayPane;	
}

/*****
	
	buildDisplay
	
	returns:
		GUI controls loaded into SVG DOM <g> is the root
		
	tested
		
*****/
FeatureInfo.prototype.buildDisplay = function() {

	this.displayPane = this.constructTemplate();
		
	
	return this.displayPane;
}


/*****

loadFeature
	loads and displays a feature specified by 'id'
	this class loads data for display on request. text is expensive to render.

*****/
FeatureInfo.prototype.loadFeature = function( id ) {
	for( i in this.fields ) {
		if( this.fields[i].lastChild ) this.fields[i].removeChild( this.fields[i].lastChild );
		this.fields[i].appendChild( svgDocument.createTextNode( this.features[ id ]['data'][i] ) );
	}
}

/********************************************************************************************/
/********************************************************************************************/
/************************** Functions without safety nets ***********************************/
/********************************************************************************************/
/********************************************************************************************/

/*****

	init
		image = OMEimage

	tested

*****/

FeatureInfo.prototype.init = function(featureData) {
	this.featureData = featureData;
	this.fields   = new Array();
	this.features = new Array();
	this.labels   = new Array();
	
	for( i in this.featureData ) {
		var id = this.featureData[i]['ID'];
		this.features[ id ] = new Array();
		this.features[ id ]['data'] = this.featureData[ i ];
	}
}

