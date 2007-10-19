/*
 * org.openmicroscopy.xml.LightSourceNode
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
 * Created by curtis via Xmlgen on Oct 19, 2007 5:03:39 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import java.util.List;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * LightSourceNode is the node corresponding to the
 * "LightSource" XML element.
 *
 * Name: LightSource
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class LightSourceNode extends AttributeNode
  implements LightSource
{

  // -- Constructors --

  /**
   * Constructs a LightSource node
   * with the given associated DOM element.
   */
  public LightSourceNode(Element element) { super(element); }

  /**
   * Constructs a LightSource node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LightSourceNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a LightSource node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LightSourceNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "LightSource", attach);
  }

  /**
   * Constructs a LightSource node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public LightSourceNode(CustomAttributesNode parent, String manufacturer,
    String model, String serialNumber, Instrument instrument)
  {
    this(parent, true);
    setManufacturer(manufacturer);
    setModel(model);
    setSerialNumber(serialNumber);
    setInstrument(instrument);
  }


  // -- LightSource API methods --

  /**
   * Gets Manufacturer attribute
   * of the LightSource element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the LightSource element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);  }

  /**
   * Gets Model attribute
   * of the LightSource element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the LightSource element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);  }

  /**
   * Gets SerialNumber attribute
   * of the LightSource element.
   */
  public String getSerialNumber() {
    return getAttribute("SerialNumber");
  }

  /**
   * Sets SerialNumber attribute
   * for the LightSource element.
   */
  public void setSerialNumber(String value) {
    setAttribute("SerialNumber", value);  }

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the LightSource element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      getAttrReferencedNode("Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the LightSource element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setAttrReferencedNode((OMEXMLNode) value, "Instrument");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this LightSource node
   * via a LightSource attribute.
   */
  public List getLogicalChannelListByLightSource() {
    return getAttrReferringNodes("LogicalChannel", "LightSource");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this LightSource node.
   */
  public int countLogicalChannelListByLightSource() {
    return getAttrReferringCount("LogicalChannel", "LightSource");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this LightSource node
   * via a AuxLightSource attribute.
   */
  public List getLogicalChannelListByAuxLightSource() {
    return getAttrReferringNodes("LogicalChannel", "AuxLightSource");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this LightSource node
   * via a AuxLightSource attribute.
   */
  public int countLogicalChannelListByAuxLightSource() {
    return getAttrReferringCount("LogicalChannel", "AuxLightSource");
  }

  /**
   * Gets a list of Laser elements
   * referencing this LightSource node
   * via a LightSource attribute.
   */
  public List getLaserListByLightSource() {
    return getAttrReferringNodes("Laser", "LightSource");
  }

  /**
   * Gets the number of Laser elements
   * referencing this LightSource node.
   */
  public int countLaserListByLightSource() {
    return getAttrReferringCount("Laser", "LightSource");
  }

  /**
   * Gets a list of Laser elements
   * referencing this LightSource node
   * via a Pump attribute.
   */
  public List getLaserListByPump() {
    return getAttrReferringNodes("Laser", "Pump");
  }

  /**
   * Gets the number of Laser elements
   * referencing this LightSource node
   * via a Pump attribute.
   */
  public int countLaserListByPump() {
    return getAttrReferringCount("Laser", "Pump");
  }

  /**
   * Gets a list of Filament elements
   * referencing this LightSource node.
   */
  public List getFilamentList() {
    return getAttrReferringNodes("Filament", "LightSource");
  }

  /**
   * Gets the number of Filament elements
   * referencing this LightSource node.
   */
  public int countFilamentList() {
    return getAttrReferringCount("Filament", "LightSource");
  }

  /**
   * Gets a list of Arc elements
   * referencing this LightSource node.
   */
  public List getArcList() {
    return getAttrReferringNodes("Arc", "LightSource");
  }

  /**
   * Gets the number of Arc elements
   * referencing this LightSource node.
   */
  public int countArcList() {
    return getAttrReferringCount("Arc", "LightSource");
  }

}
