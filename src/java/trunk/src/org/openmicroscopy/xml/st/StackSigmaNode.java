/*
 * org.openmicroscopy.xml.StackSigmaNode
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
 * Created by curtis via Xmlgen on Oct 19, 2007 5:03:39 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * StackSigmaNode is the node corresponding to the
 * "StackSigma" XML element.
 *
 * Name: StackSigma
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class StackSigmaNode extends AttributeNode
  implements StackSigma
{

  // -- Constructors --

  /**
   * Constructs a StackSigma node
   * with the given associated DOM element.
   */
  public StackSigmaNode(Element element) { super(element); }

  /**
   * Constructs a StackSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackSigmaNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a StackSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackSigmaNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "StackSigma", attach);
  }

  /**
   * Constructs a StackSigma node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public StackSigmaNode(CustomAttributesNode parent, Integer theC,
    Integer theT, Float sigma)
  {
    this(parent, true);
    setTheC(theC);
    setTheT(theT);
    setSigma(sigma);
  }


  // -- StackSigma API methods --

  /**
   * Gets TheC attribute
   * of the StackSigma element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the StackSigma element.
   */
  public void setTheC(Integer value) {
    setAttribute("TheC", value);  }

  /**
   * Gets TheT attribute
   * of the StackSigma element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the StackSigma element.
   */
  public void setTheT(Integer value) {
    setAttribute("TheT", value);  }

  /**
   * Gets Sigma attribute
   * of the StackSigma element.
   */
  public Float getSigma() {
    return getFloatAttribute("Sigma");
  }

  /**
   * Sets Sigma attribute
   * for the StackSigma element.
   */
  public void setSigma(Float value) {
    setAttribute("Sigma", value);  }

}
