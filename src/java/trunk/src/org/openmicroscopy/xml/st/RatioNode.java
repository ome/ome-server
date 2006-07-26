/*
 * org.openmicroscopy.xml.RatioNode
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
 * RatioNode is the node corresponding to the
 * "Ratio" XML element.
 *
 * Name: Ratio
 * AppliesTo: F
 * Location: OME/src/xml/OME/Tests/featureExample.ome
 */
public class RatioNode extends AttributeNode
  implements Ratio
{

  // -- Constructors --

  /**
   * Constructs a Ratio node
   * with the given associated DOM element.
   */
  public RatioNode(Element element) { super(element); }

  /**
   * Constructs a Ratio node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public RatioNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Ratio node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public RatioNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Ratio", attach);
  }

  /**
   * Constructs a Ratio node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public RatioNode(CustomAttributesNode parent, Float ratio)
  {
    this(parent, true);
    setRatio(ratio);
  }


  // -- Ratio API methods --

  /**
   * Gets Ratio attribute
   * of the Ratio element.
   */
  public Float getRatio() {
    return getFloatAttribute("Ratio");
  }

  /**
   * Sets Ratio attribute
   * for the Ratio element.
   */
  public void setRatio(Float value) {
    setFloatAttribute("Ratio", value);
  }

}
