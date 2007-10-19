/*
 * org.openmicroscopy.xml.LocationNode
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
 * LocationNode is the node corresponding to the
 * "Location" XML element.
 *
 * Name: Location
 * AppliesTo: F
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 * Description: Specifies a feature's 3D spatial location, in pixels
 */
public class LocationNode extends AttributeNode
  implements Location
{

  // -- Constructors --

  /**
   * Constructs a Location node
   * with the given associated DOM element.
   */
  public LocationNode(Element element) { super(element); }

  /**
   * Constructs a Location node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LocationNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Location node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public LocationNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Location", attach);
  }

  /**
   * Constructs a Location node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public LocationNode(CustomAttributesNode parent, Float theX, Float theY,
    Float theZ)
  {
    this(parent, true);
    setTheX(theX);
    setTheY(theY);
    setTheZ(theZ);
  }


  // -- Location API methods --

  /**
   * Gets TheX attribute
   * of the Location element.
   */
  public Float getTheX() {
    return getFloatAttribute("TheX");
  }

  /**
   * Sets TheX attribute
   * for the Location element.
   */
  public void setTheX(Float value) {
    setAttribute("TheX", value);  }

  /**
   * Gets TheY attribute
   * of the Location element.
   */
  public Float getTheY() {
    return getFloatAttribute("TheY");
  }

  /**
   * Sets TheY attribute
   * for the Location element.
   */
  public void setTheY(Float value) {
    setAttribute("TheY", value);  }

  /**
   * Gets TheZ attribute
   * of the Location element.
   */
  public Float getTheZ() {
    return getFloatAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the Location element.
   */
  public void setTheZ(Float value) {
    setAttribute("TheZ", value);  }

}
