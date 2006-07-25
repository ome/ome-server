/*
 * org.openmicroscopy.xml.StackMaximumNode
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
 * Created by curtis via Xmlgen on Jul 25, 2006 12:37:01 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * StackMaximumNode is the node corresponding to the
 * "StackMaximum" XML element.
 *
 * Name: StackMaximum
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class StackMaximumNode extends AttributeNode
  implements StackMaximum
{

  // -- Constructors --

  /**
   * Constructs a StackMaximum node
   * with the given associated DOM element.
   */
  public StackMaximumNode(Element element) { super(element); }

  /**
   * Constructs a StackMaximum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackMaximumNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a StackMaximum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackMaximumNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("StackMaximum"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a StackMaximum node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public StackMaximumNode(CustomAttributesNode parent, Integer theC,
    Integer theT, Integer maximum)
  {
    this(parent, true);
    setTheC(theC);
    setTheT(theT);
    setMaximum(maximum);
  }


  // -- StackMaximum API methods --

  /**
   * Gets TheC attribute
   * of the StackMaximum element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the StackMaximum element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the StackMaximum element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the StackMaximum element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Maximum attribute
   * of the StackMaximum element.
   */
  public Integer getMaximum() {
    return getIntegerAttribute("Maximum");
  }

  /**
   * Sets Maximum attribute
   * for the StackMaximum element.
   */
  public void setMaximum(Integer value) {
    setIntegerAttribute("Maximum", value);
  }

}
