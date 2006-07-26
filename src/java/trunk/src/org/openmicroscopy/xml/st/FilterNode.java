/*
 * org.openmicroscopy.xml.FilterNode
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
      createReferencedNode(InstrumentNode.class,
      "Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the Filter element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setReferencedNode((OMEXMLNode) value, "Instrument", "Instrument");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this Filter node.
   */
  public List getLogicalChannelList() {
    return createAttrReferralNodes(LogicalChannelNode.class,
      "LogicalChannel", "Filter");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this Filter node.
   */
  public int countLogicalChannelList() {
    return getSize(getAttrReferrals("LogicalChannel",
      "Filter"));
  }

  /**
   * Gets a list of ExcitationFilter elements
   * referencing this Filter node.
   */
  public List getExcitationFilterList() {
    return createAttrReferralNodes(ExcitationFilterNode.class,
      "ExcitationFilter", "Filter");
  }

  /**
   * Gets the number of ExcitationFilter elements
   * referencing this Filter node.
   */
  public int countExcitationFilterList() {
    return getSize(getAttrReferrals("ExcitationFilter",
      "Filter"));
  }

  /**
   * Gets a list of Dichroic elements
   * referencing this Filter node.
   */
  public List getDichroicList() {
    return createAttrReferralNodes(DichroicNode.class,
      "Dichroic", "Filter");
  }

  /**
   * Gets the number of Dichroic elements
   * referencing this Filter node.
   */
  public int countDichroicList() {
    return getSize(getAttrReferrals("Dichroic",
      "Filter"));
  }

  /**
   * Gets a list of EmissionFilter elements
   * referencing this Filter node.
   */
  public List getEmissionFilterList() {
    return createAttrReferralNodes(EmissionFilterNode.class,
      "EmissionFilter", "Filter");
  }

  /**
   * Gets the number of EmissionFilter elements
   * referencing this Filter node.
   */
  public int countEmissionFilterList() {
    return getSize(getAttrReferrals("EmissionFilter",
      "Filter"));
  }

  /**
   * Gets a list of FilterSet elements
   * referencing this Filter node.
   */
  public List getFilterSetList() {
    return createAttrReferralNodes(FilterSetNode.class,
      "FilterSet", "Filter");
  }

  /**
   * Gets the number of FilterSet elements
   * referencing this Filter node.
   */
  public int countFilterSetList() {
    return getSize(getAttrReferrals("FilterSet",
      "Filter"));
  }

  /**
   * Gets a list of OTF elements
   * referencing this Filter node.
   */
  public List getOTFList() {
    return createAttrReferralNodes(OTFNode.class,
      "OTF", "Filter");
  }

  /**
   * Gets the number of OTF elements
   * referencing this Filter node.
   */
  public int countOTFList() {
    return getSize(getAttrReferrals("OTF",
      "Filter"));
  }

}
