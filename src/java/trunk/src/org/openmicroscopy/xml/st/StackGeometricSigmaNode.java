/*
 * org.openmicroscopy.xml.StackGeometricSigmaNode
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
 * StackGeometricSigmaNode is the node corresponding to the
 * "StackGeometricSigma" XML element.
 *
 * Name: StackGeometricSigma
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class StackGeometricSigmaNode extends AttributeNode
  implements StackGeometricSigma
{

  // -- Constructors --

  /**
   * Constructs a StackGeometricSigma node
   * with the given associated DOM element.
   */
  public StackGeometricSigmaNode(Element element) { super(element); }

  /**
   * Constructs a StackGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackGeometricSigmaNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a StackGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackGeometricSigmaNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "StackGeometricSigma", attach);
  }

  /**
   * Constructs a StackGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public StackGeometricSigmaNode(CustomAttributesNode parent, Integer theC,
    Integer theT, Float geometricSigma)
  {
    this(parent, true);
    setTheC(theC);
    setTheT(theT);
    setGeometricSigma(geometricSigma);
  }


  // -- StackGeometricSigma API methods --

  /**
   * Gets TheC attribute
   * of the StackGeometricSigma element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the StackGeometricSigma element.
   */
  public void setTheC(Integer value) {
    setAttribute("TheC", value);  }

  /**
   * Gets TheT attribute
   * of the StackGeometricSigma element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the StackGeometricSigma element.
   */
  public void setTheT(Integer value) {
    setAttribute("TheT", value);  }

  /**
   * Gets GeometricSigma attribute
   * of the StackGeometricSigma element.
   */
  public Float getGeometricSigma() {
    return getFloatAttribute("GeometricSigma");
  }

  /**
   * Sets GeometricSigma attribute
   * for the StackGeometricSigma element.
   */
  public void setGeometricSigma(Float value) {
    setAttribute("GeometricSigma", value);  }

}
