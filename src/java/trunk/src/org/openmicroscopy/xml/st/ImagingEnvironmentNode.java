/*
 * org.openmicroscopy.xml.ImagingEnvironmentNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
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
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:48 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ImagingEnvironmentNode is the node corresponding to the
 * "ImagingEnvironment" XML element.
 *
 * Name: ImagingEnvironment
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Various environmental conditions at the time of image
 *   acquisition.
 */
public class ImagingEnvironmentNode extends AttributeNode
  implements ImagingEnvironment
{

  // -- Constructors --

  /**
   * Constructs an ImagingEnvironment node
   * with the given associated DOM element.
   */
  public ImagingEnvironmentNode(Element element) { super(element); }

  /**
   * Constructs an ImagingEnvironment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImagingEnvironmentNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImagingEnvironment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImagingEnvironmentNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImagingEnvironment"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImagingEnvironment node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImagingEnvironmentNode(OMEXMLNode parent, Float temperature,
    Float airPressure, Float humidity, Float co2Percent)
  {
    this(parent, true);
    setTemperature(temperature);
    setAirPressure(airPressure);
    setHumidity(humidity);
    setCO2Percent(co2Percent);
  }


  // -- ImagingEnvironment API methods --

  /**
   * Gets Temperature attribute
   * of the ImagingEnvironment element.
   */
  public Float getTemperature() {
    return getFloatAttribute("Temperature");
  }

  /**
   * Sets Temperature attribute
   * for the ImagingEnvironment element.
   */
  public void setTemperature(Float value) {
    setFloatAttribute("Temperature", value);
  }

  /**
   * Gets AirPressure attribute
   * of the ImagingEnvironment element.
   */
  public Float getAirPressure() {
    return getFloatAttribute("AirPressure");
  }

  /**
   * Sets AirPressure attribute
   * for the ImagingEnvironment element.
   */
  public void setAirPressure(Float value) {
    setFloatAttribute("AirPressure", value);
  }

  /**
   * Gets Humidity attribute
   * of the ImagingEnvironment element.
   */
  public Float getHumidity() {
    return getFloatAttribute("Humidity");
  }

  /**
   * Sets Humidity attribute
   * for the ImagingEnvironment element.
   */
  public void setHumidity(Float value) {
    setFloatAttribute("Humidity", value);
  }

  /**
   * Gets CO2Percent attribute
   * of the ImagingEnvironment element.
   */
  public Float getCO2Percent() {
    return getFloatAttribute("CO2Percent");
  }

  /**
   * Sets CO2Percent attribute
   * for the ImagingEnvironment element.
   */
  public void setCO2Percent(Float value) {
    setFloatAttribute("CO2Percent", value);
  }

}
