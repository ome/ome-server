/*
 * org.openmicroscopy.xml.PlaneSigmaNode
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
 * Created by curtis via Xmlgen on Apr 24, 2006 4:30:18 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PlaneSigmaNode is the node corresponding to the
 * "PlaneSigma" XML element.
 *
 * Name: PlaneSigma
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneSigmaNode extends AttributeNode
  implements PlaneSigma
{

  // -- Constructors --

  /**
   * Constructs a PlaneSigma node
   * with the given associated DOM element.
   */
  public PlaneSigmaNode(Element element) { super(element); }

  /**
   * Constructs a PlaneSigma node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSigmaNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneSigma"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneSigma node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneSigmaNode(OMEXMLNode parent, Integer theZ, Integer theC,
    Integer theT, Float sigma)
  {
    this(parent);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setSigma(sigma);
  }


  // -- PlaneSigma API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneSigma element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneSigma element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneSigma element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneSigma element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneSigma element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneSigma element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Sigma attribute
   * of the PlaneSigma element.
   */
  public Float getSigma() {
    return getFloatAttribute("Sigma");
  }

  /**
   * Sets Sigma attribute
   * for the PlaneSigma element.
   */
  public void setSigma(Float value) {
    setFloatAttribute("Sigma", value);
  }

}
