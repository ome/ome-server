/*
 * org.openmicroscopy.xml.DimensionsNode
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
 * DimensionsNode is the node corresponding to the
 * "Dimensions" XML element.
 *
 * Name: Dimensions
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Describe el tamano fisico de cada dimension de los pixeles en
 *   una imagen, en micras.
 */
public class DimensionsNode extends AttributeNode
  implements Dimensions
{

  // -- Constructors --

  /**
   * Constructs a Dimensions node
   * with the given associated DOM element.
   */
  public DimensionsNode(Element element) { super(element); }

  /**
   * Constructs a Dimensions node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DimensionsNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Dimensions node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DimensionsNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Dimensions", attach);
  }

  /**
   * Constructs a Dimensions node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DimensionsNode(CustomAttributesNode parent, Float pixelSizeX,
    Float pixelSizeY, Float pixelSizeZ, Float pixelSizeC, Float pixelSizeT)
  {
    this(parent, true);
    setPixelSizeX(pixelSizeX);
    setPixelSizeY(pixelSizeY);
    setPixelSizeZ(pixelSizeZ);
    setPixelSizeC(pixelSizeC);
    setPixelSizeT(pixelSizeT);
  }


  // -- Dimensions API methods --

  /**
   * Gets PixelSizeX attribute
   * of the Dimensions element.
   */
  public Float getPixelSizeX() {
    return getFloatAttribute("PixelSizeX");
  }

  /**
   * Sets PixelSizeX attribute
   * for the Dimensions element.
   */
  public void setPixelSizeX(Float value) {
    setAttribute("PixelSizeX", value);  }

  /**
   * Gets PixelSizeY attribute
   * of the Dimensions element.
   */
  public Float getPixelSizeY() {
    return getFloatAttribute("PixelSizeY");
  }

  /**
   * Sets PixelSizeY attribute
   * for the Dimensions element.
   */
  public void setPixelSizeY(Float value) {
    setAttribute("PixelSizeY", value);  }

  /**
   * Gets PixelSizeZ attribute
   * of the Dimensions element.
   */
  public Float getPixelSizeZ() {
    return getFloatAttribute("PixelSizeZ");
  }

  /**
   * Sets PixelSizeZ attribute
   * for the Dimensions element.
   */
  public void setPixelSizeZ(Float value) {
    setAttribute("PixelSizeZ", value);  }

  /**
   * Gets PixelSizeC attribute
   * of the Dimensions element.
   */
  public Float getPixelSizeC() {
    return getFloatAttribute("PixelSizeC");
  }

  /**
   * Sets PixelSizeC attribute
   * for the Dimensions element.
   */
  public void setPixelSizeC(Float value) {
    setAttribute("PixelSizeC", value);  }

  /**
   * Gets PixelSizeT attribute
   * of the Dimensions element.
   */
  public Float getPixelSizeT() {
    return getFloatAttribute("PixelSizeT");
  }

  /**
   * Sets PixelSizeT attribute
   * for the Dimensions element.
   */
  public void setPixelSizeT(Float value) {
    setAttribute("PixelSizeT", value);  }

}
