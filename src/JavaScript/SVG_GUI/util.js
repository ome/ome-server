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

svgns = "http://www.w3.org/2000/svg";

function createElementSVG( name, attr_list ) {
	var new_element = svgDocument.createElementNS(svgns, name);
	for( attr in attr_list ) {
		new_element.setAttribute( attr, attr_list[attr] );
	}
	return new_element;
}

function createTextSVG( text_data, attr_list ) {
	var text_element = createElementSVG( 'text', attr_list );
	text_element.appendChild( svgDocument.createTextNode( text_data ) );
	return text_element;
}

function isArray(Array_IN) {
	return(typeof(Array_IN) == 'Object' && Array_IN.constructor == Array)
}

function isFunction(Function_IN) {
	return(typeof(Function_IN) == 'function' );
}
