/*
 * org.openmicroscopy.xml2007.GreyChannelNode
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
 * The wave number, black level, white level and optional gamma for a greyscale image.
 * The GreyChannel element may contain an optional ColorMap attribute, which can be set to 'Greyscale', 'Spectrum' or 'Blackbody'
 * Pixel values between BlackLevel and WhiteLevel will be assigned values 0-255, inclusive.
 * Values below BlackLevel or above WhiteLevel will be assigned 0 and 255 respectively.
 */
public class GreyChannelNode extends ChannelSpecNode {

  // -- Constructor --

  public GreyChannelNode(Element element) { super(element); }

  // -- GreyChannelNode API methods --

  public String getColorMap() {
    return getAttribute("ColorMap");
  }

  public void setColorMap(String colorMap) {
    setAttribute("ColorMap", colorMap);
  }

}
