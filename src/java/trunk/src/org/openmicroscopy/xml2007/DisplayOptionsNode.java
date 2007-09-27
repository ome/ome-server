/*
 * org.openmicroscopy.xml2007.DisplayOptionsNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2007 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee,
 *      University of Wisconsin-Madison
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
 *-----------------------------------------------------------------------------
 */

/*-----------------------------------------------------------------------------
 *
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by user via NameOfAutogenerator on Sep 22, 2007 12:00:00 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml2007;

import org.w3c.dom.Element;

/**
 * There is optionally one of these per Image.
 * This specifies mapping of image channel components to RGB or greyscale colorspace with one byte per pixel per RGB channel.
 * RedChannel, GreenChannel, BlueChannel, and GreyChannel specify the scaling of pixel values to 8-bit colorspace values.
 * Display indicates to display the image as Greyscale or RGB.
 * The Projection element specifies that the display is a maximum intensity projection.
 * The range of Z-sections for the projection is specified with the ZStart and ZStop attributes.
 * The Time element restricts the range of timepoints displayed.
 * The range of timepoints to display is specified by the TStart and TStop attributes.
 * The MIME type of the desired video format is specified by Movie's MIMEtype attribute.
 * The ROI element describes a 3-D region of interest.  It is up to the viewer to either display the ROI only,
 * or to simply mark it somehow.
 */
public class DisplayOptionsNode extends OMEXMLNode {

  // -- Constructor --

  public DisplayOptionsNode(Element element) { super(element); }

  // -- DisplayOptionsNode API methods --

  public ChannelSpecNode getRedChannel() {
    return (ChannelSpecNode) getChildNode("ChannelSpec", "RedChannel");
  }

  public ChannelSpecNode getGreenChannel() {
    return (ChannelSpecNode) getChildNode("ChannelSpec", "GreenChannel");
  }

  public ChannelSpecNode getBlueChannel() {
    return (ChannelSpecNode) getChildNode("ChannelSpec", "BlueChannel");
  }

  public GreyChannelNode getGreyChannel() {
    return (GreyChannelNode) getChildNode("GreyChannel");
  }

  public ProjectionNode getProjection() {
    return (ProjectionNode) getChildNode("Projection");
  }

  public TimeNode getTime() {
    return (TimeNode) getChildNode("Time");
  }

  public ROINode getROI() {
    return (ROINode) getChildNode("ROI");
  }

  public Float getZoom() {
    return getFloatAttribute("Zoom");
  }

  public void setZoom(Float zoom) {
    setAttribute("Zoom", zoom);
  }

	/** Specifies to display the image as greyscale or RGB */
  public String getDisplay() {
    return getAttribute("Display");
  }

  public void setDisplay(String display) {
    setAttribute("Display", display);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
