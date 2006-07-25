/*
 * org.openmicroscopy.xml.PlaneGeometricSigmaNode
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
 * PlaneGeometricSigmaNode is the node corresponding to the
 * "PlaneGeometricSigma" XML element.
 *
 * Name: PlaneGeometricSigma
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneGeometricSigmaNode extends AttributeNode
  implements PlaneGeometricSigma
{

  // -- Constructors --

  /**
   * Constructs a PlaneGeometricSigma node
   * with the given associated DOM element.
   */
  public PlaneGeometricSigmaNode(Element element) { super(element); }

  /**
   * Constructs a PlaneGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneGeometricSigmaNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneGeometricSigmaNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneGeometricSigma"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneGeometricSigma node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneGeometricSigmaNode(CustomAttributesNode parent, Integer theZ,
    Integer theC, Integer theT, Float geometricSigma)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setGeometricSigma(geometricSigma);
  }


  // -- PlaneGeometricSigma API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneGeometricSigma element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneGeometricSigma element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneGeometricSigma element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneGeometricSigma element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneGeometricSigma element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneGeometricSigma element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets GeometricSigma attribute
   * of the PlaneGeometricSigma element.
   */
  public Float getGeometricSigma() {
    return getFloatAttribute("GeometricSigma");
  }

  /**
   * Sets GeometricSigma attribute
   * for the PlaneGeometricSigma element.
   */
  public void setGeometricSigma(Float value) {
    setFloatAttribute("GeometricSigma", value);
  }

}
