/*
 * org.openmicroscopy.xml.DetectorNode
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

import java.util.List;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * DetectorNode is the node corresponding to the
 * "Detector" XML element.
 *
 * Name: Detector
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class DetectorNode extends AttributeNode
  implements Detector
{

  // -- Constructors --

  /**
   * Constructs a Detector node
   * with the given associated DOM element.
   */
  public DetectorNode(Element element) { super(element); }

  /**
   * Constructs a Detector node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DetectorNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Detector node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DetectorNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Detector", attach);
  }

  /**
   * Constructs a Detector node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DetectorNode(CustomAttributesNode parent, String manufacturer,
    String model, String serialNumber, String type, Float gain, Float voltage,
    Float offset, Instrument instrument)
  {
    this(parent, true);
    setManufacturer(manufacturer);
    setModel(model);
    setSerialNumber(serialNumber);
    setType(type);
    setGain(gain);
    setVoltage(voltage);
    setOffset(offset);
    setInstrument(instrument);
  }


  // -- Detector API methods --

  /**
   * Gets Manufacturer attribute
   * of the Detector element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the Detector element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);
  }

  /**
   * Gets Model attribute
   * of the Detector element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the Detector element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);
  }

  /**
   * Gets SerialNumber attribute
   * of the Detector element.
   */
  public String getSerialNumber() {
    return getAttribute("SerialNumber");
  }

  /**
   * Sets SerialNumber attribute
   * for the Detector element.
   */
  public void setSerialNumber(String value) {
    setAttribute("SerialNumber", value);
  }

  /**
   * Gets Type attribute
   * of the Detector element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the Detector element.
   */
  public void setType(String value) {
    setAttribute("Type", value);
  }

  /**
   * Gets Gain attribute
   * of the Detector element.
   */
  public Float getGain() {
    return getFloatAttribute("Gain");
  }

  /**
   * Sets Gain attribute
   * for the Detector element.
   */
  public void setGain(Float value) {
    setFloatAttribute("Gain", value);
  }

  /**
   * Gets Voltage attribute
   * of the Detector element.
   */
  public Float getVoltage() {
    return getFloatAttribute("Voltage");
  }

  /**
   * Sets Voltage attribute
   * for the Detector element.
   */
  public void setVoltage(Float value) {
    setFloatAttribute("Voltage", value);
  }

  /**
   * Gets Offset attribute
   * of the Detector element.
   */
  public Float getOffset() {
    return getFloatAttribute("Offset");
  }

  /**
   * Sets Offset attribute
   * for the Detector element.
   */
  public void setOffset(Float value) {
    setFloatAttribute("Offset", value);
  }

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the Detector element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      createReferencedNode(InstrumentNode.class,
      "Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the Detector element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setReferencedNode((OMEXMLNode) value, "Instrument", "Instrument");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this Detector node.
   */
  public List getLogicalChannelList() {
    return createAttrReferralNodes(LogicalChannelNode.class,
      "LogicalChannel", "Detector");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this Detector node.
   */
  public int countLogicalChannelList() {
    return getSize(getAttrReferrals("LogicalChannel",
      "Detector"));
  }

}
