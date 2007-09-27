/*
 * org.openmicroscopy.xml2007.ChannelSpecNode
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

public class ChannelSpecNode extends OMEXMLNode {

  // -- Constructor --

  public ChannelSpecNode(Element element) { super(element); }

  // -- ChannelSpecNode API methods --

  /** Specifies the channel number in the pixel dump.  Channels are numbered from 0. */
  public Integer getChannelNumber() {
    return getIntegerAttribute("ChannelNumber");
  }

  public void setChannelNumber(Integer channelNumber) {
    setAttribute("ChannelNumber", channelNumber);
  }

  /**
   * The black level is used to scale pixel values to an 8 bit colorspace for display. For example, a 16 bit pixel value must be downscaled to fit an 8 bit display. 
   * Any pixel value below the black value will be set to the minimum value of the scale range (0). 
   * Because the file schema offers support for non-integer pixel types, this is stored as a floating point number to offer maximum generality. Specifying a decimal value for an integer pixel type is ill defined.
   * Valid range of values for black level is less than the white level and within the data range for the pixel type.
   */
  public Float getBlackLevel() {
    return getFloatAttribute("BlackLevel");
  }

  public void setBlackLevel(Float blackLevel) {
    setAttribute("BlackLevel", blackLevel);
  }

  /**
   * The white level is used  to scale pixel values to an 8 bit colorspace for display. For example, a 16 bit pixel value must be downscaled to fit an 8 bit display. 
   * Any pixel value above the white value will be set to the maximum value of the scale range (255). 
   * Because the file schema offers support for non-integer pixel types, this is stored as a floating point number to offer maximum generality. Specifying a decimal value for an integer pixel type is ill defined.
   * The valid range for white level is greater than the black level and within the data range for the pixel type.
   */
  public Float getWhiteLevel() {
    return getFloatAttribute("WhiteLevel");
  }

  public void setWhiteLevel(Float whiteLevel) {
    setAttribute("WhiteLevel", whiteLevel);
  }

  public Float getGamma() {
    return getFloatAttribute("Gamma");
  }

  public void setGamma(Float gamma) {
    setAttribute("Gamma", gamma);
  }

  public Boolean isisOn() {
    return getBooleanAttribute("isOn");
  }

  public void setisOn(Boolean isOn) {
    setAttribute("isOn", isOn);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
