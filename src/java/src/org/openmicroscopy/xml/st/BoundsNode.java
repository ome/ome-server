/*
 * org.openmicroscopy.xml.BoundsNode
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
 * Created by curtis via Xmlgen on Dec 18, 2007 12:41:44 PM CST
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * BoundsNode is the node corresponding to the
 * "Bounds" XML element.
 *
 * Name: Bounds
 * AppliesTo: F
 * Location: OME/src/xml/OME/Tests/featureExample.ome
 * Description: Bounds of a feature
 */
public class BoundsNode extends AttributeNode
  implements Bounds
{

  // -- Constructors --

  /**
   * Constructs a Bounds node
   * with the given associated DOM element.
   */
  public BoundsNode(Element element) { super(element); }

  /**
   * Constructs a Bounds node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public BoundsNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Bounds node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public BoundsNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Bounds", attach);
  }

  /**
   * Constructs a Bounds node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public BoundsNode(CustomAttributesNode parent, Integer x, Integer y,
    Integer width, Integer height)
  {
    this(parent, true);
    setX(x);
    setY(y);
    setWidth(width);
    setHeight(height);
  }


  // -- Bounds API methods --

  /**
   * Gets X attribute
   * of the Bounds element.
   */
  public Integer getX() {
    return getIntegerAttribute("X");
  }

  /**
   * Sets X attribute
   * for the Bounds element.
   */
  public void setX(Integer value) {
    setAttribute("X", value);  }

  /**
   * Gets Y attribute
   * of the Bounds element.
   */
  public Integer getY() {
    return getIntegerAttribute("Y");
  }

  /**
   * Sets Y attribute
   * for the Bounds element.
   */
  public void setY(Integer value) {
    setAttribute("Y", value);  }

  /**
   * Gets Width attribute
   * of the Bounds element.
   */
  public Integer getWidth() {
    return getIntegerAttribute("Width");
  }

  /**
   * Sets Width attribute
   * for the Bounds element.
   */
  public void setWidth(Integer value) {
    setAttribute("Width", value);  }

  /**
   * Gets Height attribute
   * of the Bounds element.
   */
  public Integer getHeight() {
    return getIntegerAttribute("Height");
  }

  /**
   * Sets Height attribute
   * for the Bounds element.
   */
  public void setHeight(Integer value) {
    setAttribute("Height", value);  }

}
