/*
 * org.openmicroscopy.xml.StackMinimumNode
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
 * StackMinimumNode is the node corresponding to the
 * "StackMinimum" XML element.
 *
 * Name: StackMinimum
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class StackMinimumNode extends AttributeNode
  implements StackMinimum
{

  // -- Constructors --

  /**
   * Constructs a StackMinimum node
   * with the given associated DOM element.
   */
  public StackMinimumNode(Element element) { super(element); }

  /**
   * Constructs a StackMinimum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackMinimumNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a StackMinimum node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackMinimumNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("StackMinimum"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a StackMinimum node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public StackMinimumNode(OMEXMLNode parent, Integer theC, Integer theT,
    Integer minimum)
  {
    this(parent, true);
    setTheC(theC);
    setTheT(theT);
    setMinimum(minimum);
  }


  // -- StackMinimum API methods --

  /**
   * Gets TheC attribute
   * of the StackMinimum element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the StackMinimum element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the StackMinimum element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the StackMinimum element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Minimum attribute
   * of the StackMinimum element.
   */
  public Integer getMinimum() {
    return getIntegerAttribute("Minimum");
  }

  /**
   * Sets Minimum attribute
   * for the StackMinimum element.
   */
  public void setMinimum(Integer value) {
    setIntegerAttribute("Minimum", value);
  }

}
