/*
 * org.openmicroscopy.xml.PlaneSum_YiNode
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

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PlaneSum_YiNode is the node corresponding to the
 * "PlaneSum_Yi" XML element.
 *
 * Name: PlaneSum_Yi
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneSum_YiNode extends AttributeNode
  implements PlaneSum_Yi
{

  // -- Constructors --

  /**
   * Constructs a PlaneSum_Yi node
   * with the given associated DOM element.
   */
  public PlaneSum_YiNode(Element element) { super(element); }

  /**
   * Constructs a PlaneSum_Yi node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_YiNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneSum_Yi node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_YiNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PlaneSum_Yi", attach);
  }

  /**
   * Constructs a PlaneSum_Yi node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneSum_YiNode(CustomAttributesNode parent, Integer theZ,
    Integer theC, Integer theT, Float sum_Yi)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setSum_Yi(sum_Yi);
  }


  // -- PlaneSum_Yi API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneSum_Yi element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneSum_Yi element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneSum_Yi element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneSum_Yi element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneSum_Yi element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneSum_Yi element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Sum_Yi attribute
   * of the PlaneSum_Yi element.
   */
  public Float getSum_Yi() {
    return getFloatAttribute("Sum_Yi");
  }

  /**
   * Sets Sum_Yi attribute
   * for the PlaneSum_Yi element.
   */
  public void setSum_Yi(Float value) {
    setFloatAttribute("Sum_Yi", value);
  }

}
