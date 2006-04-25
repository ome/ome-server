/*
 * org.openmicroscopy.xml.EmissionFilterNode
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

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * EmissionFilterNode is the node corresponding to the
 * "EmissionFilter" XML element.
 *
 * Name: EmissionFilter
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class EmissionFilterNode extends AttributeNode
  implements EmissionFilter
{

  // -- Constructors --

  /**
   * Constructs an EmissionFilter node
   * with the given associated DOM element.
   */
  public EmissionFilterNode(Element element) { super(element); }

  /**
   * Constructs an EmissionFilter node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public EmissionFilterNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("EmissionFilter"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an EmissionFilter node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public EmissionFilterNode(OMEXMLNode parent, String manufacturer,
    String model, String lotNumber, String type, Filter filter)
  {
    this(parent);
    setManufacturer(manufacturer);
    setModel(model);
    setLotNumber(lotNumber);
    setType(type);
    setFilter(filter);
  }


  // -- EmissionFilter API methods --

  /**
   * Gets Manufacturer attribute
   * of the EmissionFilter element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the EmissionFilter element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);
  }

  /**
   * Gets Model attribute
   * of the EmissionFilter element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the EmissionFilter element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);
  }

  /**
   * Gets LotNumber attribute
   * of the EmissionFilter element.
   */
  public String getLotNumber() {
    return getAttribute("LotNumber");
  }

  /**
   * Sets LotNumber attribute
   * for the EmissionFilter element.
   */
  public void setLotNumber(String value) {
    setAttribute("LotNumber", value);
  }

  /**
   * Gets Type attribute
   * of the EmissionFilter element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the EmissionFilter element.
   */
  public void setType(String value) {
    setAttribute("Type", value);
  }

  /**
   * Gets Filter referenced by Filter
   * attribute of the EmissionFilter element.
   */
  public Filter getFilter() {
    return (Filter)
      createReferencedNode(FilterNode.class,
      "Filter", "Filter");
  }

  /**
   * Sets Filter referenced by Filter
   * attribute of the EmissionFilter element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FilterNode
   */
  public void setFilter(Filter value) {
    setReferencedNode((OMEXMLNode) value, "Filter", "Filter");
  }

}
