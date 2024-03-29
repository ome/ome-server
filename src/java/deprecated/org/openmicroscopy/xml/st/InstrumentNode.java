/*
 * org.openmicroscopy.xml.InstrumentNode
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
 * Created by curtis via Xmlgen on Dec 18, 2007 12:41:44 PM CST
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import java.util.List;
import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * InstrumentNode is the node corresponding to the
 * "Instrument" XML element.
 *
 * Name: Instrument
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 * Description: Describe a un microscopio. Principalmente actua como un
 *   contenedor para los componenetes que lo constituyen (Objetivos, Filtros,
 *   ect)
 */
public class InstrumentNode extends AttributeNode
  implements Instrument
{

  // -- Constructors --

  /**
   * Constructs an Instrument node
   * with the given associated DOM element.
   */
  public InstrumentNode(Element element) { super(element); }

  /**
   * Constructs an Instrument node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public InstrumentNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an Instrument node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public InstrumentNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Instrument", attach);
  }

  /**
   * Constructs an Instrument node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public InstrumentNode(CustomAttributesNode parent, String manufacturer,
    String model, String serialNumber, String type)
  {
    this(parent, true);
    setManufacturer(manufacturer);
    setModel(model);
    setSerialNumber(serialNumber);
    setType(type);
  }


  // -- Instrument API methods --

  /**
   * Gets Manufacturer attribute
   * of the Instrument element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the Instrument element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);  }

  /**
   * Gets Model attribute
   * of the Instrument element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the Instrument element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);  }

  /**
   * Gets SerialNumber attribute
   * of the Instrument element.
   */
  public String getSerialNumber() {
    return getAttribute("SerialNumber");
  }

  /**
   * Sets SerialNumber attribute
   * for the Instrument element.
   */
  public void setSerialNumber(String value) {
    setAttribute("SerialNumber", value);  }

  /**
   * Gets Type attribute
   * of the Instrument element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the Instrument element.
   */
  public void setType(String value) {
    setAttribute("Type", value);  }

  /**
   * Gets a list of ImageInstrument elements
   * referencing this Instrument node.
   */
  public List getImageInstrumentList() {
    return getAttrReferringNodes("ImageInstrument", "Instrument");
  }

  /**
   * Gets the number of ImageInstrument elements
   * referencing this Instrument node.
   */
  public int countImageInstrumentList() {
    return getAttrReferringCount("ImageInstrument", "Instrument");
  }

  /**
   * Gets a list of LightSource elements
   * referencing this Instrument node.
   */
  public List getLightSourceList() {
    return getAttrReferringNodes("LightSource", "Instrument");
  }

  /**
   * Gets the number of LightSource elements
   * referencing this Instrument node.
   */
  public int countLightSourceList() {
    return getAttrReferringCount("LightSource", "Instrument");
  }

  /**
   * Gets a list of Detector elements
   * referencing this Instrument node.
   */
  public List getDetectorList() {
    return getAttrReferringNodes("Detector", "Instrument");
  }

  /**
   * Gets the number of Detector elements
   * referencing this Instrument node.
   */
  public int countDetectorList() {
    return getAttrReferringCount("Detector", "Instrument");
  }

  /**
   * Gets a list of Objective elements
   * referencing this Instrument node.
   */
  public List getObjectiveList() {
    return getAttrReferringNodes("Objective", "Instrument");
  }

  /**
   * Gets the number of Objective elements
   * referencing this Instrument node.
   */
  public int countObjectiveList() {
    return getAttrReferringCount("Objective", "Instrument");
  }

  /**
   * Gets a list of Filter elements
   * referencing this Instrument node.
   */
  public List getFilterList() {
    return getAttrReferringNodes("Filter", "Instrument");
  }

  /**
   * Gets the number of Filter elements
   * referencing this Instrument node.
   */
  public int countFilterList() {
    return getAttrReferringCount("Filter", "Instrument");
  }

  /**
   * Gets a list of OTF elements
   * referencing this Instrument node.
   */
  public List getOTFList() {
    return getAttrReferringNodes("OTF", "Instrument");
  }

  /**
   * Gets the number of OTF elements
   * referencing this Instrument node.
   */
  public int countOTFList() {
    return getAttrReferringCount("OTF", "Instrument");
  }

}
