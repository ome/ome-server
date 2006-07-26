/*
 * org.openmicroscopy.xml.StackGeometricMeanNode
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
 * StackGeometricMeanNode is the node corresponding to the
 * "StackGeometricMean" XML element.
 *
 * Name: StackGeometricMean
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class StackGeometricMeanNode extends AttributeNode
  implements StackGeometricMean
{

  // -- Constructors --

  /**
   * Constructs a StackGeometricMean node
   * with the given associated DOM element.
   */
  public StackGeometricMeanNode(Element element) { super(element); }

  /**
   * Constructs a StackGeometricMean node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackGeometricMeanNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a StackGeometricMean node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public StackGeometricMeanNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "StackGeometricMean", attach);
  }

  /**
   * Constructs a StackGeometricMean node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public StackGeometricMeanNode(CustomAttributesNode parent, Integer theC,
    Integer theT, Float geometricMean)
  {
    this(parent, true);
    setTheC(theC);
    setTheT(theT);
    setGeometricMean(geometricMean);
  }


  // -- StackGeometricMean API methods --

  /**
   * Gets TheC attribute
   * of the StackGeometricMean element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the StackGeometricMean element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the StackGeometricMean element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the StackGeometricMean element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets GeometricMean attribute
   * of the StackGeometricMean element.
   */
  public Float getGeometricMean() {
    return getFloatAttribute("GeometricMean");
  }

  /**
   * Sets GeometricMean attribute
   * for the StackGeometricMean element.
   */
  public void setGeometricMean(Float value) {
    setFloatAttribute("GeometricMean", value);
  }

}
