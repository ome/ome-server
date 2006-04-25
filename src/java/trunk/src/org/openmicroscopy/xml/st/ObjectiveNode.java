/*
 * org.openmicroscopy.xml.ObjectiveNode
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
 * Created by curtis via Xmlgen on Apr 24, 2006 4:30:18 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import java.util.List;
import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ObjectiveNode is the node corresponding to the
 * "Objective" XML element.
 *
 * Name: Objective
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class ObjectiveNode extends AttributeNode
  implements Objective
{

  // -- Constructors --

  /**
   * Constructs an Objective node
   * with the given associated DOM element.
   */
  public ObjectiveNode(Element element) { super(element); }

  /**
   * Constructs an Objective node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ObjectiveNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Objective"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an Objective node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ObjectiveNode(OMEXMLNode parent, String manufacturer, String model,
    String serialNumber, Float lensNA, Float magnification,
    Instrument instrument)
  {
    this(parent);
    setManufacturer(manufacturer);
    setModel(model);
    setSerialNumber(serialNumber);
    setLensNA(lensNA);
    setMagnification(magnification);
    setInstrument(instrument);
  }


  // -- Objective API methods --

  /**
   * Gets Manufacturer attribute
   * of the Objective element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the Objective element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);
  }

  /**
   * Gets Model attribute
   * of the Objective element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the Objective element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);
  }

  /**
   * Gets SerialNumber attribute
   * of the Objective element.
   */
  public String getSerialNumber() {
    return getAttribute("SerialNumber");
  }

  /**
   * Sets SerialNumber attribute
   * for the Objective element.
   */
  public void setSerialNumber(String value) {
    setAttribute("SerialNumber", value);
  }

  /**
   * Gets LensNA attribute
   * of the Objective element.
   */
  public Float getLensNA() {
    return getFloatAttribute("LensNA");
  }

  /**
   * Sets LensNA attribute
   * for the Objective element.
   */
  public void setLensNA(Float value) {
    setFloatAttribute("LensNA", value);
  }

  /**
   * Gets Magnification attribute
   * of the Objective element.
   */
  public Float getMagnification() {
    return getFloatAttribute("Magnification");
  }

  /**
   * Sets Magnification attribute
   * for the Objective element.
   */
  public void setMagnification(Float value) {
    setFloatAttribute("Magnification", value);
  }

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the Objective element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      createReferencedNode(InstrumentNode.class,
      "Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the Objective element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setReferencedNode((OMEXMLNode) value, "Instrument", "Instrument");
  }

  /**
   * Gets a list of ImageInstrument elements
   * referencing this Objective node.
   */
  public List getImageInstrumentList() {
    return createAttrReferralNodes(ImageInstrumentNode.class,
      "ImageInstrument", "Objective");
  }

  /**
   * Gets the number of ImageInstrument elements
   * referencing this Objective node.
   */
  public int countImageInstrumentList() {
    return getSize(getAttrReferrals("ImageInstrument",
      "Objective"));
  }

  /**
   * Gets a list of OTF elements
   * referencing this Objective node.
   */
  public List getOTFList() {
    return createAttrReferralNodes(OTFNode.class,
      "OTF", "Objective");
  }

  /**
   * Gets the number of OTF elements
   * referencing this Objective node.
   */
  public int countOTFList() {
    return getSize(getAttrReferrals("OTF",
      "Objective"));
  }

}
