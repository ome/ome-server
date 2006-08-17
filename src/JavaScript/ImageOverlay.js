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
  this.pixelsInfo = pixelsInfo;
  this.Scale = startingScale || 0.5;
  this.currentDownloadedScale = 0;
}
OMEImage.prototype = new GOverlay();


// Creates the DIV representing this OMEImage.
OMEImage.prototype.initialize = function(map) {
  // Create the DIV representing our OMEImage
  var div = document.createElement("div");
  div.style.position = "absolute";
  div.style.background = "grey";
  
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

  // Construct the boundaries of this overlay. 
  // Start with the pixel coordinates, 
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var minX = c1.x;
  var minY = c1.y;
  var maxX = minX + Math.round( this.pixelsInfo.sizeX * this.Scale );
  var maxY = minY + Math.round( this.pixelsInfo.sizeY * this.Scale );
  // Convert to lat & lng
  var SW = this.map_.fromDivPixelToLatLng( new GPoint( minX, maxY ) );
  var NE = this.map_.fromDivPixelToLatLng( new GPoint( maxX, minY ) );
  this.bounds = new GLatLngBounds( SW, NE );
  this.div_.style.width = Math.round( this.pixelsInfo.sizeX * this.Scale ) + "px";
  this.div_.style.height = Math.round( this.pixelsInfo.sizeY * this.Scale ) + "px";

  // Calculate the width now to make it easier to calculate change in scale later.
  var c2 = this.map_.fromLatLngToDivPixel(this.bounds.getNorthEast());
  this.OrigNumericWidth = Math.abs(c2.x - c1.x) / this.Scale;

  // Add a placeholder image within the DIV
  this.thumbnail = document.createElement("img");
  this.thumbnail.src = '/ome-images/one_transparent_pixel.gif';
  div.appendChild( this.thumbnail );

}

// Remove the main DIV from the map pane
OMEImage.prototype.remove = function() {
  this.div_.parentNode.removeChild(this.div_);
}

// Copy our data to a new OMEImage
OMEImage.prototype.copy = function() {
  return new OMEImage(topLeft, pixelsInfo, startingScale );
}

// Redraw the OMEImage based on the current projection and zoom level
OMEImage.prototype.redraw = function(force) {

  var greyOutAtWidth = 20;

  // Calculate the DIV coordinates of two opposite corners of our bounds to
  // get the size and position of our OMEImage
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.bounds.getNorthEast());
  this.NumericWidth = Math.abs(c2.x - c1.x);
  this.Scale = this.NumericWidth / this.OrigNumericWidth;
  this.width = Math.round( this.pixelsInfo.sizeX * this.Scale );
  this.height = Math.round( this.pixelsInfo.sizeY * this.Scale );


  // Position our DIV based on the DIV coordinates of our bounds
  this.div_.style.left = c1.x + "px";
  this.div_.style.top = c1.y + "px";
  this.div_.style.width = this.width + "px";
  this.div_.style.height = this.height + "px";
  this.thumbnail.width = this.width;
  this.thumbnail.height = this.height;	 

  // update from OMEIS if we need a higher resolution and we're in the current viewing window
  var viewWindow = this.map_.getBounds();
  if( (this.width >= greyOutAtWidth ) && 
      ( this.Scale > this.currentDownloadedScale ) &&  
        viewWindow.intersects( this.bounds ) ) {
	  // update from omeis
	  if( this.thumbnail ) this.div_.removeChild( this.thumbnail );
	  this.thumbnail = document.createElement("img");
	  this.thumbnail.src = this.pixelsInfo.omeis_url + "?Method=GetThumb" + 
		"&PixelsID=" + this.pixelsInfo.id + "&Format=JPEG" + 
		"&Size=" + this.width + "," +  + this.height;

	  this.div_.appendChild( this.thumbnail );
	  this.currentDownloadedScale = this.Scale;
  }
  if( this.width < greyOutAtWidth ) {
	  if( this.thumbnail ) this.div_.removeChild( this.thumbnail );
	  this.thumbnail = document.createElement("img");
      this.thumbnail.src = '/ome-images/one_transparent_pixel.gif';
      this.div_.appendChild( this.thumbnail );
      this.currentDownloadedScale = 0;
  }
  

}

OMEImage.prototype.lngWidth = function() {
  var c1 = this.map_.fromLatLngToDivPixel(this.topLeftPoint);
  var c2 = this.map_.fromLatLngToDivPixel(this.bounds.getNorthEast());

  var lngDist = this.topLeftPoint.lng() - this.bounds.getNorthEast().lng();
  var pixelDist = c1.x - c2.x;
  var lngToPixRatio = lngDist / pixelDist;
  
  var imageWidth = this.pixelsInfo.sizeX * this.Scale * lngToPixRatio;
  return imageWidth;
}

OMEImage.prototype.latHeight = function() {
  var c1 = this.map_.fromLatLngToDivPixel(this.bounds.getSouthWest());
  var c2 = this.map_.fromLatLngToDivPixel(this.bounds.getNorthEast());

  var latDist = this.bounds.getSouthWest().lat() - this.bounds.getNorthEast().lat();
  var pixelDist = c1.y - c2.y;
  var latToPixRatio = Math.abs( latDist / pixelDist );
  
  var imageHeight = this.pixelsInfo.sizeY * this.Scale * latToPixRatio;
  return imageHeight;
}
