/*****

	util.js

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
	
*****/

/*global svgDocument */

var Util = new Object();

Util.svgns = "http://www.w3.org/2000/svg";
Util.xlinkns  = "http://www.w3.org/1999/xlink";

Util.createElementSVG = function( name, attr_list ) {
	var new_element = svgDocument.createElementNS(Util.svgns, name);
	if( attr_list ) {
		for( var attr in attr_list ) {
			new_element.setAttribute( attr, attr_list[attr] );
		}
	}
	return new_element;
};

Util.createTextSVG = function( text_data, attr_list ) {
	var text_element = Util.createElementSVG( 'text', attr_list );
	text_element.appendChild( svgDocument.createTextNode( text_data ) );
	return text_element;
};

Util.createTextLinkSVG = function( dat ) { 
	var link_node = Util.createElementSVG( 'a', dat[ 'attrs' ] );
	link_node.setAttributeNS( Util.xlinkns, 'href',  dat[ 'href' ] );
	var text_node = Util.createTextSVG(  dat[ 'text' ],  dat[ 'text_attrs' ] ); 
	link_node.appendChild( text_node );
	return link_node;
};

Util.isArray = function(Array_IN) {
	return(typeof(Array_IN) == 'object' && Array_IN.constructor == Array);
};

Util.isFunction = function(Function_IN) {
	return(typeof(Function_IN) == 'function' );
};

Util.err = function( msg ) {
	var tmpImg;
	tmpImg = svgDocument.createElementNS(svgns,"image");
	tmpImg.setAttribute("width",0);
	tmpImg.setAttribute("height",0);
	// The purpose of unique is to bypass any browser image caching. really, it should be a timestamp
	var date = new Date();
	var unique   = date.getSeconds() + '' + date.getUTCMilliseconds();
	var imageURL = "/perl2/SVGcatchMsg.pl?msg=" + msg + "&unique=" + unique;
	tmpImg.setAttributeNS(Util.xlinkns, "href",imageURL);
	var toolboxLayer  = svgDocument.getElementById("toolboxLayer");
	toolboxLayer.appendChild(tmpImg);
	toolboxLayer.removeChild(tmpImg);

	// scrolling error messages if there's a text element w/ id "_util_text_err"
	if( !this.err_text ) {
		this.err_text = svgDocument.getElementById("_util_text_err");
		this.err_lines = new Array();
	}
	if( this.err_text ) {
		if( this.err_lines.length == 5 ) {
			var old_line = this.err_lines.shift();
			this.err_text.removeChild( old_line );
		}
		var newLine = this.createElementSVG( "tspan", { 'x': 0, 'dy': '1em' } );
		newLine.appendChild( svgDocument.createTextNode( msg ) );
		this.err_lines.push( newLine );
		this.err_text.appendChild( newLine );
	}
};
