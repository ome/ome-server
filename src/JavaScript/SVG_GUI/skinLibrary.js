/*****

	skinLibrary.js
		external file dependencies: none
		
		Author: Josiah Johnston
		email: siah@nih.gov
	
*****/

skinLibrary = new Array();

skinLibrary['TEST'] = true;

skinLibrary["menuBar"] =
'<g>' +
'	<g opacity="0.8">' +
'		<rect width="{$width}" height="15" fill="lawngreen" rx="10" ry="5"/>' +
'		<rect y="5" width="{$width}" height="10" fill="lawngreen"/>' +
'	</g>' +
'</g>';
skinLibrary["hideControl"] =
'<g>' +
'	<ellipse rx="5" ry="5" fill="ghostwhite" stroke="forestgreen" stroke-width="1">' +
'		<animate attributeName="ry" from="5" to="2" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'		<animate attributeName="ry" from="2" to="5" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'	</ellipse>' +
'</g>';
skinLibrary["GUIbox"] =
'<g style="font-size:10;">' +
'	<linearGradient id="GUIboxBackground" x1="0" y1="0" x2="0" y2="100%">' +
'		<stop offset="5%" stop-color="green" />' +
'		<stop offset="95%" stop-color="palegreen" />' +
'	</linearGradient>' +
'	<rect width="{$width}" height="{$height}" fill="url(#GUIboxBackground)" opacity="0.7"/>' +
'	<rect width="{$width}" height="{$height}" fill="none" stroke="black" stroke-width="3" opacity="1"/>' +
'	<animateTransform attributeName="transform" type="rotate" from="0" to="-90" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'	<animateTransform attributeName="transform" type="rotate" from="-90" to="0" dur="0.3s" fill="freeze" repeatCount="0" restart="whenNotActive" begin="indefinite"/>' +
'</g>';
skinLibrary["menuBar17"] =
'<g>' +
'	<g opacity="0.8">' +
'		<rect width="{$width}" height="17" fill="lightsteelblue" rx="10" ry="5"/>' +
'		<rect y="5" width="{$width}" height="12" fill="lightsteelblue"/>' +
'	</g>' +
'</g>';
skinLibrary["XhideControl"] =
'<g>' +
'	<circle r="5" fill="ghostwhite" stroke="forestgreen" stroke-width="1"/>' +
'	<g transform="rotate(45)">' +
'		<line x1="-5" x2="5" stroke="forestgreen" stroke-width="2"/>' +
'		<line y1="-5" y2="5" stroke="forestgreen" stroke-width="2"/>' +
'	</g>' +
'</g>';
skinLibrary["tallGUIbox"] =
'<g>' +
'	<rect width="{$width}" height="1000" fill="lightslategray" opacity="0.5"/>' +
'</g>';
skinLibrary["popupListAnchorUpperLeftRoundedLightslategray"] = 
'<g>' +
'	<rect width="{$width}" height="{$height}" rx="10" ry="5" fill="lightslategray"/>' +
'	<rect y="5" width="{$width}" height="{$height - 5}" fill="lightslategray"/>' +
'	<rect x="{$width - 10}" width="10" height="{$height}" fill="lightslategray"/>' +
'</g>';
skinLibrary["popupListAnchorLightslategray"] = 
'<rect width="{$width}" height="{$height}" fill="lightslategray"/>';
skinLibrary["popupListBackgroundLightskyblue"] = 
'<rect width="{$width}" height="{$height}" fill="lightskyblue" opacity="0.5"/>';
skinLibrary["popupListHighlightAquamarine"] = 
'<rect width="{$width}" height="{$height}" fill="aquamarine" opacity="0.5">';
skinLibrary["zSliderBody"] =
'<g stroke="rgb(80,80,80)" transform="rotate(90)">' +
'	<g id="xyPlane" transform="scale(.6) skewX(-45)">' +
'		<polyline points="-27,0 -25,-3 -30,0 -25,3 -27,0 27,0 25,3 30,0 25,-3 27,0"/>' +
'		<text x="17" y="10" style="font-size:10;">x</text>' +
'		<polyline points="0,-27 -3,-25 0,-30 3,-25 0,-27 0,27 3,25 0,30 -3,25 0,27"/>' +
'		<text x="5" y="-17" style="font-size:10;">y</text>' +
'	</g>' +
'	<g id="zAxis">' +
'		<polyline points="0,0 0,-100 -4,-92 0,-95 4,-92 0,-100"/>' +
'		<rect x="-7" y="-100" width="14" height="100" opacity="0"/>' +
'		<text x="-9" y="-82" style="font-size:12;" fill="black" stroke="none">z</text>' +
'	</g>' +
'</g>';
skinLibrary["zSliderThumb"] =
'<g>' +
'	<rect x="-1" y="-7" width="2" height="14" fill="black"/>' +
'	<rect x="-3" y="-7" width="6" height="14" fill="red" opacity="0">' +
'		<set attributeName="opacity" to="0.4" begin="mouseover" end="mouseout"/>' +
'	</rect>' +
'</g>';
skinLibrary["redAnchorText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="rgb(255,70,70)" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["redItemBackgroundText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="rgb(255,70,70)"	rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">';
skinLibrary["redItemHighlightText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="rgb(255,130,130)" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["greenAnchorText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="mediumseagreen" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["greenItemBackgroundText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="mediumseagreen" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">';
skinLibrary["greenItemHighlightText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="lime" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["blueAnchorText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="cornflowerblue" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["blueItemBackgroundText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="cornflowerblue" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}">';
skinLibrary["blueItemHighlightText"] =
'<rect x="-2" width="{$width + 4}" height="{$height}" fill="aqua" rx="{Math.round($height/2)}" ry="{Math.round($height/2)}"/>';
skinLibrary["redButtonOn"] =
'<circle cy="5" r="5" fill="pink" stroke="black" stroke-width="1"/>';
skinLibrary["redButtonOff"] =
'<circle cy="5" r="5" fill="darkred"/>';
skinLibrary["greenButtonOn"] =
'<circle cy="5" r="5" fill="lightgreen" stroke="black" stroke-width="1"/>';
skinLibrary["greenButtonOff"] =
'<circle cy="5" r="5" fill="darkgreen"/>';
skinLibrary["blueButtonOn"] =
'<circle cy="5" r="5" fill="lightblue" stroke="black" stroke-width="1"/>';
skinLibrary["blueButtonOff"] =
'<circle cy="5" r="5" fill="darkblue"/>';
skinLibrary["RGB_BWButtonOn"] =
'<g>' +
'	<circle cy="13" r="13" fill="white" stroke="black" stroke-width="1"/>' +
'	<text fill="black" text-anchor="middle" dominant-baseline="middle" y="17">B/W</text>' +
'</g>';
skinLibrary["RGB_BWButtonOff"] =
'<g>' +
'	<circle cy="13" r="13" fill="white" stroke="black" stroke-width="1"/>' +
'	<text fill="black" text-anchor="middle" dominant-baseline="middle" y="17">RGB</text>' +
'</g>';
skinLibrary["blankButtonRadius13Highlight"] =
'<circle cy="13" r="13" fill="white" stroke="none" opacity="0"/>';
skinLibrary["blankButtonRadius5Highlight"] =
'<circle cy="5" r="5" fill="white" stroke="none" opacity="0"/>';
skinLibrary["triangleRightWhite"] =
'<path d="M 0,4 l 6,-4 l -6,-4 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>';
skinLibrary["triangleLeftWhite"] =
'<path d="M 0,4 l -6,-4 l 6,-4 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>';
skinLibrary["triangleDownWhite"] =
'<path d="M 4,0 l -4,6 l -4,-6 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>';
skinLibrary["triangleUpWhite"] =
'<path d="M 4,0 l -4,-6 l -4,6 Z" fill="ghostwhite" stroke="black" stroke-width="1"/>';
skinLibrary["triangleRightRed"] =
'<path d="M 0,4 l 6,-4 l -6,-4 Z" fill="coral" stroke="black" stroke-width="1"/>';
skinLibrary["triangleLeftRed"] =
'<path d="M 0,4 l -6,-4 l 6,-4 Z" fill="coral" stroke="black" stroke-width="1"/>';
skinLibrary["triangleDownRed"] =
'<path d="M 4,0 l -4,6 l -4,-6 Z" fill="coral" stroke="black" stroke-width="1"/>';
skinLibrary["triangleUpRed"] =
'<path d="M 4,0 l -4,-6 l -4,6 Z" fill="coral" stroke="black" stroke-width="1"/>';
skinLibrary["hiddenButton"] =
'<circle r="1" fill=black/>';
skinLibrary["hiddenButtonHighlight"] =
'<circle r="4" fill="cyan"/>';
