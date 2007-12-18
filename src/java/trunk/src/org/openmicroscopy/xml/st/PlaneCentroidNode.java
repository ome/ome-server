/*
 * org.openmicroscopy.xml.PlaneCentroidNode
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
 * PlaneCentroidNode is the node corresponding to the
 * "PlaneCentroid" XML element.
 *
 * Name: PlaneCentroid
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneCentroidNode extends AttributeNode
  implements PlaneCentroid
{

  // -- Constructors --

  /**
   * Constructs a PlaneCentroid node
   * with the given associated DOM element.
   */
  public PlaneCentroidNode(Element element) { super(element); }

  /**
   * Constructs a PlaneCentroid node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneCentroidNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneCentroid node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneCentroidNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PlaneCentroid", attach);
  }

  /**
   * Constructs a PlaneCentroid node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneCentroidNode(CustomAttributesNode parent, Integer theZ,
    Integer theC, Integer theT, Float x, Float y)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setX(x);
    setY(y);
  }


  // -- PlaneCentroid API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneCentroid element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneCentroid element.
   */
  public void setTheZ(Integer value) {
    setAttribute("TheZ", value);  }

  /**
   * Gets TheC attribute
   * of the PlaneCentroid element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneCentroid element.
   */
  public void setTheC(Integer value) {
    setAttribute("TheC", value);  }

  /**
   * Gets TheT attribute
   * of the PlaneCentroid element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneCentroid element.
   */
  public void setTheT(Integer value) {
    setAttribute("TheT", value);  }

  /**
   * Gets X attribute
   * of the PlaneCentroid element.
   */
  public Float getX() {
    return getFloatAttribute("X");
  }

  /**
   * Sets X attribute
   * for the PlaneCentroid element.
   */
  public void setX(Float value) {
    setAttribute("X", value);  }

  /**
   * Gets Y attribute
   * of the PlaneCentroid element.
   */
  public Float getY() {
    return getFloatAttribute("Y");
  }

  /**
   * Sets Y attribute
   * for the PlaneCentroid element.
   */
  public void setY(Float value) {
    setAttribute("Y", value);  }

}
