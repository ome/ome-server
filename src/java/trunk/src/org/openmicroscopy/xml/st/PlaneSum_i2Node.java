/*
 * org.openmicroscopy.xml.PlaneSum_i2Node
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
 * PlaneSum_i2Node is the node corresponding to the
 * "PlaneSum_i2" XML element.
 *
 * Name: PlaneSum_i2
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneSum_i2Node extends AttributeNode
  implements PlaneSum_i2
{

  // -- Constructors --

  /**
   * Constructs a PlaneSum_i2 node
   * with the given associated DOM element.
   */
  public PlaneSum_i2Node(Element element) { super(element); }

  /**
   * Constructs a PlaneSum_i2 node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_i2Node(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneSum_i2 node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_i2Node(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneSum_i2"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneSum_i2 node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneSum_i2Node(OMEXMLNode parent, Integer theZ, Integer theC,
    Integer theT, Float sum_i2)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setSum_i2(sum_i2);
  }


  // -- PlaneSum_i2 API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneSum_i2 element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneSum_i2 element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneSum_i2 element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneSum_i2 element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneSum_i2 element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneSum_i2 element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Sum_i2 attribute
   * of the PlaneSum_i2 element.
   */
  public Float getSum_i2() {
    return getFloatAttribute("Sum_i2");
  }

  /**
   * Sets Sum_i2 attribute
   * for the PlaneSum_i2 element.
   */
  public void setSum_i2(Float value) {
    setFloatAttribute("Sum_i2", value);
  }

}
