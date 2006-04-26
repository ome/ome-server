/*
 * org.openmicroscopy.xml.DisplayROINode
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
 * DisplayROINode is the node corresponding to the
 * "DisplayROI" XML element.
 *
 * Name: DisplayROI
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: A region of interest within the image for display purposes
 */
public class DisplayROINode extends AttributeNode
  implements DisplayROI
{

  // -- Constructors --

  /**
   * Constructs a DisplayROI node
   * with the given associated DOM element.
   */
  public DisplayROINode(Element element) { super(element); }

  /**
   * Constructs a DisplayROI node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DisplayROINode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a DisplayROI node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DisplayROINode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("DisplayROI"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a DisplayROI node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DisplayROINode(OMEXMLNode parent, Integer x0, Integer y0, Integer z0,
    Integer x1, Integer y1, Integer z1, Integer t0, Integer t1,
    DisplayOptions displayOptions)
  {
    this(parent, true);
    setX0(x0);
    setY0(y0);
    setZ0(z0);
    setX1(x1);
    setY1(y1);
    setZ1(z1);
    setT0(t0);
    setT1(t1);
    setDisplayOptions(displayOptions);
  }


  // -- DisplayROI API methods --

  /**
   * Gets X0 attribute
   * of the DisplayROI element.
   */
  public Integer getX0() {
    return getIntegerAttribute("X0");
  }

  /**
   * Sets X0 attribute
   * for the DisplayROI element.
   */
  public void setX0(Integer value) {
    setIntegerAttribute("X0", value);
  }

  /**
   * Gets Y0 attribute
   * of the DisplayROI element.
   */
  public Integer getY0() {
    return getIntegerAttribute("Y0");
  }

  /**
   * Sets Y0 attribute
   * for the DisplayROI element.
   */
  public void setY0(Integer value) {
    setIntegerAttribute("Y0", value);
  }

  /**
   * Gets Z0 attribute
   * of the DisplayROI element.
   */
  public Integer getZ0() {
    return getIntegerAttribute("Z0");
  }

  /**
   * Sets Z0 attribute
   * for the DisplayROI element.
   */
  public void setZ0(Integer value) {
    setIntegerAttribute("Z0", value);
  }

  /**
   * Gets X1 attribute
   * of the DisplayROI element.
   */
  public Integer getX1() {
    return getIntegerAttribute("X1");
  }

  /**
   * Sets X1 attribute
   * for the DisplayROI element.
   */
  public void setX1(Integer value) {
    setIntegerAttribute("X1", value);
  }

  /**
   * Gets Y1 attribute
   * of the DisplayROI element.
   */
  public Integer getY1() {
    return getIntegerAttribute("Y1");
  }

  /**
   * Sets Y1 attribute
   * for the DisplayROI element.
   */
  public void setY1(Integer value) {
    setIntegerAttribute("Y1", value);
  }

  /**
   * Gets Z1 attribute
   * of the DisplayROI element.
   */
  public Integer getZ1() {
    return getIntegerAttribute("Z1");
  }

  /**
   * Sets Z1 attribute
   * for the DisplayROI element.
   */
  public void setZ1(Integer value) {
    setIntegerAttribute("Z1", value);
  }

  /**
   * Gets T0 attribute
   * of the DisplayROI element.
   */
  public Integer getT0() {
    return getIntegerAttribute("T0");
  }

  /**
   * Sets T0 attribute
   * for the DisplayROI element.
   */
  public void setT0(Integer value) {
    setIntegerAttribute("T0", value);
  }

  /**
   * Gets T1 attribute
   * of the DisplayROI element.
   */
  public Integer getT1() {
    return getIntegerAttribute("T1");
  }

  /**
   * Sets T1 attribute
   * for the DisplayROI element.
   */
  public void setT1(Integer value) {
    setIntegerAttribute("T1", value);
  }

  /**
   * Gets DisplayOptions referenced by DisplayOptions
   * attribute of the DisplayROI element.
   */
  public DisplayOptions getDisplayOptions() {
    return (DisplayOptions)
      createReferencedNode(DisplayOptionsNode.class,
      "DisplayOptions", "DisplayOptions");
  }

  /**
   * Sets DisplayOptions referenced by DisplayOptions
   * attribute of the DisplayROI element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of DisplayOptionsNode
   */
  public void setDisplayOptions(DisplayOptions value) {
    setReferencedNode((OMEXMLNode) value, "DisplayOptions", "DisplayOptions");
  }

}
