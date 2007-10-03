/*
 * org.openmicroscopy.xml2007.DetectorNode
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
 * The type of detector used to capture the image.
 * The Detector ID can be used as a reference within the LogicalChannel element in the Image element.
 * The Type attribute can be set to 'CCD','Intensified-CCD','Analog-Video','PMT','Photodiode','Spectroscopy','Life-time-Imaging','Correlation-Spectroscopy','FTIR'.
 * Added new types EM-CCD, APD, and CMOS - ajp
 * Added new optional attributes AmplificationGain and Zoom - ajp
 */
public class DetectorNode extends ManufactSpecNode {

  // -- Constructor --

  public DetectorNode(Element element) { super(element); }

  // -- DetectorNode API methods --

  public Float getGain() {
    return getFloatAttribute("Gain");
  }

  public void setGain(Float gain) {
    setAttribute("Gain", gain);
  }

  public Float getVoltage() {
    return getFloatAttribute("Voltage");
  }

  public void setVoltage(Float voltage) {
    setAttribute("Voltage", voltage);
  }

  public Float getOffset() {
    return getFloatAttribute("Offset");
  }

  public void setOffset(Float offset) {
    setAttribute("Offset", offset);
  }

  public Float getZoom() {
    return getFloatAttribute("Zoom");
  }

  public void setZoom(Float zoom) {
    setAttribute("Zoom", zoom);
  }

  public Float getAmplificationGain() {
    return getFloatAttribute("AmplificationGain");
  }

  public void setAmplificationGain(Float amplificationGain) {
    setAttribute("AmplificationGain", amplificationGain);
  }

  public String getType() {
    return getAttribute("Type");
  }

  public void setType(String type) {
    setAttribute("Type", type);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
