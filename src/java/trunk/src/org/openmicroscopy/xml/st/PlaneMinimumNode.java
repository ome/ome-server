/*
 * org.openmicroscopy.xml.PlaneMinimumNode
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
 * PlaneMinimumNode is the node corresponding to the
 * "PlaneMinimum" XML element.
 *
 * Name: PlaneMinimum
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneMinimumNode extends AttributeNode
  implements PlaneMinimum
{

  // -- Constructors --

  /**
   * Constructs a PlaneMinimum node
   * with the given associated DOM element.
   */
  public PlaneMinimumNode(Element element) { super(element); }

  /**
   * Constructs a PlaneMinimum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMinimumNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneMinimum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMinimumNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PlaneMinimum", attach);
  }

  /**
   * Constructs a PlaneMinimum node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneMinimumNode(CustomAttributesNode parent, Integer theZ,
    Integer theC, Integer theT, Integer minimum)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setMinimum(minimum);
  }


  // -- PlaneMinimum API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneMinimum element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneMinimum element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneMinimum element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneMinimum element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneMinimum element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneMinimum element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Minimum attribute
   * of the PlaneMinimum element.
   */
  public Integer getMinimum() {
    return getIntegerAttribute("Minimum");
  }

  /**
   * Sets Minimum attribute
   * for the PlaneMinimum element.
   */
  public void setMinimum(Integer value) {
    setIntegerAttribute("Minimum", value);
  }

}
