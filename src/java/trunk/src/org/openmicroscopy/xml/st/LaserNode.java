/*
 * org.openmicroscopy.xml.LaserNode
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
 * Created by curtis via Xmlgen on Jul 26, 2006 3:09:05 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * LaserNode is the node corresponding to the
 * "Laser" XML element.
 *
 * Name: Laser
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 * Description: Laser types are specified using two attributes - the Type and
 *   the lasing medium (Medium). Additionally, the Wavelength (in nm), and
 *   whether or not the laser is FrequencyDoubled or Tunable may be specified.
 *   The Laser may optionally contain a Pump which refers to a LightSource used
 *   as a laser pump.
 */
public class LaserNode extends AttributeNode
  implements Laser
{

  // -- Constructors --

  /**
   * Constructs a Laser node
   * with the given associated DOM element.
   */
  public LaserNode(Element element) { super(element); }

  /**
   * Constructs a Laser node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LaserNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Laser node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LaserNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Laser", attach);
  }

  /**
   * Constructs a Laser node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public LaserNode(CustomAttributesNode parent, String type, String medium,
    Integer wavelength, Boolean frequencyDoubled, Boolean tunable,
    String pulse, Float power, LightSource lightSource, LightSource pump)
  {
    this(parent, true);
    setType(type);
    setMedium(medium);
    setWavelength(wavelength);
    setFrequencyDoubled(frequencyDoubled);
    setTunable(tunable);
    setPulse(pulse);
    setPower(power);
    setLightSource(lightSource);
    setPump(pump);
  }


  // -- Laser API methods --

  /**
   * Gets Type attribute
   * of the Laser element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the Laser element.
   */
  public void setType(String value) {
    setAttribute("Type", value);
  }

  /**
   * Gets Medium attribute
   * of the Laser element.
   */
  public String getMedium() {
    return getAttribute("Medium");
  }

  /**
   * Sets Medium attribute
   * for the Laser element.
   */
  public void setMedium(String value) {
    setAttribute("Medium", value);
  }

  /**
   * Gets Wavelength attribute
   * of the Laser element.
   */
  public Integer getWavelength() {
    return getIntegerAttribute("Wavelength");
  }

  /**
   * Sets Wavelength attribute
   * for the Laser element.
   */
  public void setWavelength(Integer value) {
    setIntegerAttribute("Wavelength", value);
  }

  /**
   * Gets FrequencyDoubled attribute
   * of the Laser element.
   */
  public Boolean isFrequencyDoubled() {
    return getBooleanAttribute("FrequencyDoubled");
  }

  /**
   * Sets FrequencyDoubled attribute
   * for the Laser element.
   */
  public void setFrequencyDoubled(Boolean value) {
    setBooleanAttribute("FrequencyDoubled", value);
  }

  /**
   * Gets Tunable attribute
   * of the Laser element.
   */
  public Boolean isTunable() {
    return getBooleanAttribute("Tunable");
  }

  /**
   * Sets Tunable attribute
   * for the Laser element.
   */
  public void setTunable(Boolean value) {
    setBooleanAttribute("Tunable", value);
  }

  /**
   * Gets Pulse attribute
   * of the Laser element.
   */
  public String getPulse() {
    return getAttribute("Pulse");
  }

  /**
   * Sets Pulse attribute
   * for the Laser element.
   */
  public void setPulse(String value) {
    setAttribute("Pulse", value);
  }

  /**
   * Gets Power attribute
   * of the Laser element.
   */
  public Float getPower() {
    return getFloatAttribute("Power");
  }

  /**
   * Sets Power attribute
   * for the Laser element.
   */
  public void setPower(Float value) {
    setFloatAttribute("Power", value);
  }

  /**
   * Gets LightSource referenced by LightSource
   * attribute of the Laser element.
   */
  public LightSource getLightSource() {
    return (LightSource)
      createReferencedNode(LightSourceNode.class,
      "LightSource", "LightSource");
  }

  /**
   * Sets LightSource referenced by LightSource
   * attribute of the Laser element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of LightSourceNode
   */
  public void setLightSource(LightSource value) {
    setReferencedNode((OMEXMLNode) value, "LightSource", "LightSource");
  }

  /**
   * Gets Pump referenced by LightSource
   * attribute of the Laser element.
   */
  public LightSource getPump() {
    return (LightSource)
      createReferencedNode(LightSourceNode.class,
      "LightSource", "Pump");
  }

  /**
   * Sets Pump referenced by LightSource
   * attribute of the Laser element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of LightSourceNode
   */
  public void setPump(LightSource value) {
    setReferencedNode((OMEXMLNode) value, "LightSource", "Pump");
  }

}
