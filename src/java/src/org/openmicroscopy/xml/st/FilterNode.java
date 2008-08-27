/*
 * org.openmicroscopy.xml.FilterNode
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
 * FilterNode is the node corresponding to the
 * "Filter" XML element.
 *
 * Name: Filter
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class FilterNode extends AttributeNode
  implements Filter
{

  // -- Constructors --

  /**
   * Constructs a Filter node
   * with the given associated DOM element.
   */
  public FilterNode(Element element) { super(element); }

  /**
   * Constructs a Filter node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilterNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Filter node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilterNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Filter", attach);
  }

  /**
   * Constructs a Filter node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public FilterNode(CustomAttributesNode parent, Instrument instrument)
  {
    this(parent, true);
    setInstrument(instrument);
  }


  // -- Filter API methods --

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the Filter element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      getAttrReferencedNode("Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the Filter element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setAttrReferencedNode((OMEXMLNode) value, "Instrument");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this Filter node.
   */
  public List getLogicalChannelList() {
    return getAttrReferringNodes("LogicalChannel", "Filter");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this Filter node.
   */
  public int countLogicalChannelList() {
    return getAttrReferringCount("LogicalChannel", "Filter");
  }

  /**
   * Gets a list of ExcitationFilter elements
   * referencing this Filter node.
   */
  public List getExcitationFilterList() {
    return getAttrReferringNodes("ExcitationFilter", "Filter");
  }

  /**
   * Gets the number of ExcitationFilter elements
   * referencing this Filter node.
   */
  public int countExcitationFilterList() {
    return getAttrReferringCount("ExcitationFilter", "Filter");
  }

  /**
   * Gets a list of Dichroic elements
   * referencing this Filter node.
   */
  public List getDichroicList() {
    return getAttrReferringNodes("Dichroic", "Filter");
  }

  /**
   * Gets the number of Dichroic elements
   * referencing this Filter node.
   */
  public int countDichroicList() {
    return getAttrReferringCount("Dichroic", "Filter");
  }

  /**
   * Gets a list of EmissionFilter elements
   * referencing this Filter node.
   */
  public List getEmissionFilterList() {
    return getAttrReferringNodes("EmissionFilter", "Filter");
  }

  /**
   * Gets the number of EmissionFilter elements
   * referencing this Filter node.
   */
  public int countEmissionFilterList() {
    return getAttrReferringCount("EmissionFilter", "Filter");
  }

  /**
   * Gets a list of FilterSet elements
   * referencing this Filter node.
   */
  public List getFilterSetList() {
    return getAttrReferringNodes("FilterSet", "Filter");
  }

  /**
   * Gets the number of FilterSet elements
   * referencing this Filter node.
   */
  public int countFilterSetList() {
    return getAttrReferringCount("FilterSet", "Filter");
  }

  /**
   * Gets a list of OTF elements
   * referencing this Filter node.
   */
  public List getOTFList() {
    return getAttrReferringNodes("OTF", "Filter");
  }

  /**
   * Gets the number of OTF elements
   * referencing this Filter node.
   */
  public int countOTFList() {
    return getAttrReferringCount("OTF", "Filter");
  }

}
