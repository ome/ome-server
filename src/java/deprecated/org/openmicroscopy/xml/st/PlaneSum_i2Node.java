/*
 * org.openmicroscopy.xml.PlaneSum_i2Node
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
  public PlaneSum_i2Node(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneSum_i2 node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_i2Node(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PlaneSum_i2", attach);
  }

  /**
   * Constructs a PlaneSum_i2 node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneSum_i2Node(CustomAttributesNode parent, Integer theZ,
    Integer theC, Integer theT, Float sum_i2)
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
    setAttribute("TheZ", value);  }

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
    setAttribute("TheC", value);  }

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
    setAttribute("TheT", value);  }

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
    setAttribute("Sum_i2", value);  }

}
