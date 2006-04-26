/*
 * org.openmicroscopy.xml.PlaneMaximumNode
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
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:49 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PlaneMaximumNode is the node corresponding to the
 * "PlaneMaximum" XML element.
 *
 * Name: PlaneMaximum
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneMaximumNode extends AttributeNode
  implements PlaneMaximum
{

  // -- Constructors --

  /**
   * Constructs a PlaneMaximum node
   * with the given associated DOM element.
   */
  public PlaneMaximumNode(Element element) { super(element); }

  /**
   * Constructs a PlaneMaximum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMaximumNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneMaximum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMaximumNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneMaximum"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneMaximum node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneMaximumNode(OMEXMLNode parent, Integer theZ, Integer theC,
    Integer theT, Integer maximum)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setMaximum(maximum);
  }


  // -- PlaneMaximum API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneMaximum element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneMaximum element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneMaximum element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneMaximum element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneMaximum element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneMaximum element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Maximum attribute
   * of the PlaneMaximum element.
   */
  public Integer getMaximum() {
    return getIntegerAttribute("Maximum");
  }

  /**
   * Sets Maximum attribute
   * for the PlaneMaximum element.
   */
  public void setMaximum(Integer value) {
    setIntegerAttribute("Maximum", value);
  }

}
