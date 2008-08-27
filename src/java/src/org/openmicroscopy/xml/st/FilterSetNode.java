/*
 * org.openmicroscopy.xml.FilterSetNode
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

import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * FilterSetNode is the node corresponding to the
 * "FilterSet" XML element.
 *
 * Name: FilterSet
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class FilterSetNode extends AttributeNode
  implements FilterSet
{

  // -- Constructors --

  /**
   * Constructs a FilterSet node
   * with the given associated DOM element.
   */
  public FilterSetNode(Element element) { super(element); }

  /**
   * Constructs a FilterSet node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilterSetNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a FilterSet node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilterSetNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "FilterSet", attach);
  }

  /**
   * Constructs a FilterSet node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public FilterSetNode(CustomAttributesNode parent, String manufacturer,
    String model, String lotNumber, Filter filter)
  {
    this(parent, true);
    setManufacturer(manufacturer);
    setModel(model);
    setLotNumber(lotNumber);
    setFilter(filter);
  }


  // -- FilterSet API methods --

  /**
   * Gets Manufacturer attribute
   * of the FilterSet element.
   */
  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  /**
   * Sets Manufacturer attribute
   * for the FilterSet element.
   */
  public void setManufacturer(String value) {
    setAttribute("Manufacturer", value);  }

  /**
   * Gets Model attribute
   * of the FilterSet element.
   */
  public String getModel() {
    return getAttribute("Model");
  }

  /**
   * Sets Model attribute
   * for the FilterSet element.
   */
  public void setModel(String value) {
    setAttribute("Model", value);  }

  /**
   * Gets LotNumber attribute
   * of the FilterSet element.
   */
  public String getLotNumber() {
    return getAttribute("LotNumber");
  }

  /**
   * Sets LotNumber attribute
   * for the FilterSet element.
   */
  public void setLotNumber(String value) {
    setAttribute("LotNumber", value);  }

  /**
   * Gets Filter referenced by Filter
   * attribute of the FilterSet element.
   */
  public Filter getFilter() {
    return (Filter)
      getAttrReferencedNode("Filter", "Filter");
  }

  /**
   * Sets Filter referenced by Filter
   * attribute of the FilterSet element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FilterNode
   */
  public void setFilter(Filter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Filter");
  }

}
