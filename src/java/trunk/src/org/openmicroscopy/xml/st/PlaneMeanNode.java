/*
 * org.openmicroscopy.xml.PlaneMeanNode
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
 * PlaneMeanNode is the node corresponding to the
 * "PlaneMean" XML element.
 *
 * Name: PlaneMean
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneMeanNode extends AttributeNode
  implements PlaneMean
{

  // -- Constructors --

  /**
   * Constructs a PlaneMean node
   * with the given associated DOM element.
   */
  public PlaneMeanNode(Element element) { super(element); }

  /**
   * Constructs a PlaneMean node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMeanNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlaneMean node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneMeanNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneMean"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneMean node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneMeanNode(OMEXMLNode parent, Integer theZ, Integer theC,
    Integer theT, Float mean)
  {
    this(parent, true);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setMean(mean);
  }


  // -- PlaneMean API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneMean element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneMean element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneMean element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneMean element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneMean element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneMean element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Mean attribute
   * of the PlaneMean element.
   */
  public Float getMean() {
    return getFloatAttribute("Mean");
  }

  /**
   * Sets Mean attribute
   * for the PlaneMean element.
   */
  public void setMean(Float value) {
    setFloatAttribute("Mean", value);
  }

}