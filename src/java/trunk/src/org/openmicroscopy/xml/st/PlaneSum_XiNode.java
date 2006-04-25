/*
 * org.openmicroscopy.xml.PlaneSum_XiNode
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
 * PlaneSum_XiNode is the node corresponding to the
 * "PlaneSum_Xi" XML element.
 *
 * Name: PlaneSum_Xi
 * AppliesTo: I
 * Location: OME/src/xml/OME/Import/ImageServerStatistics.ome
 */
public class PlaneSum_XiNode extends AttributeNode
  implements PlaneSum_Xi
{

  // -- Constructors --

  /**
   * Constructs a PlaneSum_Xi node
   * with the given associated DOM element.
   */
  public PlaneSum_XiNode(Element element) { super(element); }

  /**
   * Constructs a PlaneSum_Xi node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlaneSum_XiNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlaneSum_Xi"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlaneSum_Xi node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlaneSum_XiNode(OMEXMLNode parent, Integer theZ, Integer theC,
    Integer theT, Float sum_Xi)
  {
    this(parent);
    setTheZ(theZ);
    setTheC(theC);
    setTheT(theT);
    setSum_Xi(sum_Xi);
  }


  // -- PlaneSum_Xi API methods --

  /**
   * Gets TheZ attribute
   * of the PlaneSum_Xi element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the PlaneSum_Xi element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheC attribute
   * of the PlaneSum_Xi element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the PlaneSum_Xi element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

  /**
   * Gets TheT attribute
   * of the PlaneSum_Xi element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the PlaneSum_Xi element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets Sum_Xi attribute
   * of the PlaneSum_Xi element.
   */
  public Float getSum_Xi() {
    return getFloatAttribute("Sum_Xi");
  }

  /**
   * Sets Sum_Xi attribute
   * for the PlaneSum_Xi element.
   */
  public void setSum_Xi(Float value) {
    setFloatAttribute("Sum_Xi", value);
  }

}
