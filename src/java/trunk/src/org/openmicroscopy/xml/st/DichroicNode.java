/*
 * org.openmicroscopy.xml.DichroicNode
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

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * DichroicNode is the node corresponding to the
 * "Dichroic" XML element.
 *
 * Name: Dichroic
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class DichroicNode extends AttributeNode
  implements Dichroic
{

  // -- Constructors --

  /**
   * Constructs a Dichroic node
   * with the given associated DOM element.
   */
  public DichroicNode(Element element) { super(element); }

  /**
   * Constructs a Dichroic node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DichroicNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Dichroic node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DichroicNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Dichroic", attach);
  }

  /**
   * Constructs a Dichroic node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DichroicNode(CustomAttributesNode parent, String manufacturer,
    String model, String lotNumber, Filter filter)
  {
    this(parent, true);
    setManufacturer(manufacturer);
    setModel(model);
    setLotNumber(lotNumber);
    setFilter(filter);
  }


  // -- Dichroic API methods --

  /**
   * Gets Manufacturer attribute
   * of the Dichroic element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the Dichroic element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);  }

  /**
   * Gets Model attribute
   * of the Dichroic element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the Dichroic element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);  }

  /**
   * Gets LotNumber attribute
   * of the Dichroic element.
   */
  public String getLotNumber() {
    return getAttribute("LotNumber");
  }

  /**
   * Sets LotNumber attribute
   * for the Dichroic element.
   */
  public void setLotNumber(String value) {
    setAttribute("LotNumber", value);  }

  /**
   * Gets Filter referenced by Filter
   * attribute of the Dichroic element.
   */
  public Filter getFilter() {
    return (Filter)
      getAttrReferencedNode("Filter", "Filter");
  }

  /**
   * Sets Filter referenced by Filter
   * attribute of the Dichroic element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FilterNode
   */
  public void setFilter(Filter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Filter");
  }

}
