/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:    Josiah Johnston <siah@nih.gov>
 *
 *------------------------------------------------------------------------------
 */

/*
This is a hack of the google maps API that will overlay an OME image on the map
with an expanding info box.
*/

// A OMEImage is a simple overlay that outlines a lat/lng bounds on the
// map. 
function OMEImage(topLeft, pixelsInfo, startingScale ) {
  this.topLeftPoint = topLeft;
  this.scaleRefPoint = new GLatLng(this.topLeftPoint.lat() + .1, this.topLeftPoint.lng() + .1);
  this.pixelsInfo = pixelsInfo;
  this.Scale = startingScale || 0.5;
  this.currentDownloadedScale = this.Scale;
}
OMEImage.prototype = new GOverlay();


// Creates the DIV representing this OMEImage.
OMEImage.prototype.initialize = function(map) {
  // Create the DIV representing our OMEImage
  var div = document.createElement("div");
  div.style.position = "absolute";
  
  // Add an image within the DIV
  this.thumbnail = document.createElement("img");
	  this.thumbnail.src = this.pixelsInfo.omeis_url + "?Method=GetThumb" + 
		"&PixelsID=" + this.pixelsInfo.id + "&Format=PNG" + 
		"&Size=" + Math.round( this.pixelsInfo.sizeX * this.Scale ) + "," +  + Math.round( this.pixelsInfo.sizeY * this.Scale );
  div.appendChild( this.thumbnail );

  // Make a marker for this image.
  // copying this to a temporary string lets me access it inside the function below.
  var tmpString = this.pixelsInfo.moreInfo;
  var marker = new GMarker(this.topLeftPoint);
  GEvent.addListener(marker, "click", function() {
	marker.openInfoWindowHtml(tmpString);
  });
  map.addOverlay(marker);

  // Our OMEImage is flat against the map, so we add our selves to the
  // MAP_PANE pane, which is at the same z-index as the map itself (i.e.,
  // below the marker shadows)
  map.getPane(G_MAP_MAP_PANE).appendChild(div);

  this.map_ = map;
  this.div_ = div;

  // Calculate the width now to make it easier to calculate change in scale later.
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.scaleRefPoint);
  this.OrigNumericWidth = Math.abs(c2.x - c1.x) / this.Scale;

}

// Remove the main DIV from the map pane
OMEImage.prototype.remove = function() {
  this.div_.parentNode.removeChild(this.div_);
}

// Copy our data to a new OMEImage
OMEImage.prototype.copy = function() {
  return new OMEImage(this.bounds_, this.weight_, this.color_,
					   this.backgroundColor_, this.opacity_);
}

// Redraw the OMEImage based on the current projection and zoom level
OMEImage.prototype.redraw = function(force) {
  // We only need to redraw if the coordinate system has changed
  if (!force) return;

  // Calculate the DIV coordinates of two opposite corners of our bounds to
  // get the size and position of our OMEImage
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.scaleRefPoint);

  // Position our DIV based on the DIV coordinates of our bounds
  this.div_.style.left = c1.x + "px";
  this.div_.style.top = c1.y + "px";

  this.NumericWidth = Math.abs(c2.x - c1.x);
  this.Scale = this.NumericWidth / this.OrigNumericWidth;

  // Update the image.
  // If we need a higher resolution, update from OMEIS
  // If we need a lower resolution, downsample.
  if( this.Scale > this.currentDownloadedScale ) {
	  // update from omeis
	  this.div_.removeChild( this.thumbnail );
	  this.thumbnail = document.createElement("img");
	  this.thumbnail.src = this.pixelsInfo.omeis_url + "?Method=GetThumb" + 
		"&PixelsID=" + this.pixelsInfo.id + "&Format=JPEG" + 
		"&Size=" + Math.round( this.pixelsInfo.sizeX * this.Scale ) + "," +  + Math.round( this.pixelsInfo.sizeY * this.Scale );

	  this.div_.appendChild( this.thumbnail );
	  this.currentDownloadedScale = this.Scale;
  } else {
	  // Redraw at lower Res.
	  this.thumbnail.width = Math.round( this.pixelsInfo.sizeX * this.Scale );
	  this.thumbnail.height = Math.round( this.pixelsInfo.sizeY * this.Scale );	 
  }
}

OMEImage.prototype.lngWidth = function() {
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.scaleRefPoint);

  var lngDist = this.topLeftPoint.lng() - this.scaleRefPoint.lng();
  var pixelDist = c1.x - c2.x;
  var lngToPixRatio = lngDist / pixelDist;
  
  var imageWidth = this.pixelsInfo.sizeX * this.Scale * lngToPixRatio;
  return imageWidth;
}

OMEImage.prototype.latHeight = function() {
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.scaleRefPoint);

  var latDist = this.topLeftPoint.lat() - this.scaleRefPoint.lat();
  var pixelDist = c1.y - c2.y;
  var latToPixRatio = Math.abs( latDist / pixelDist );
  
  var imageHeight = this.pixelsInfo.sizeY * this.Scale * latToPixRatio;
  return imageHeight;
}
