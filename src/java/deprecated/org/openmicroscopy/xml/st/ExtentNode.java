/*
 * org.openmicroscopy.xml.ExtentNode
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
 * ExtentNode is the node corresponding to the
 * "Extent" XML element.
 *
 * Name: Extent
 * AppliesTo: F
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 * Description: Specifies information about the shape of a feature
 */
public class ExtentNode extends AttributeNode
  implements Extent
{

  // -- Constructors --

  /**
   * Constructs an Extent node
   * with the given associated DOM element.
   */
  public ExtentNode(Element element) { super(element); }

  /**
   * Constructs an Extent node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExtentNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an Extent node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExtentNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Extent", attach);
  }

  /**
   * Constructs an Extent node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ExtentNode(CustomAttributesNode parent, Integer minX, Integer minY,
    Integer minZ, Integer maxX, Integer maxY, Integer maxZ, Float sigmaX,
    Float sigmaY, Float sigmaZ, Integer volume, Float surfaceArea,
    Float perimeter, Float formFactor)
  {
    this(parent, true);
    setMinX(minX);
    setMinY(minY);
    setMinZ(minZ);
    setMaxX(maxX);
    setMaxY(maxY);
    setMaxZ(maxZ);
    setSigmaX(sigmaX);
    setSigmaY(sigmaY);
    setSigmaZ(sigmaZ);
    setVolume(volume);
    setSurfaceArea(surfaceArea);
    setPerimeter(perimeter);
    setFormFactor(formFactor);
  }


  // -- Extent API methods --

  /**
   * Gets MinX attribute
   * of the Extent element.
   */
  public Integer getMinX() {
    return getIntegerAttribute("MinX");
  }

  /**
   * Sets MinX attribute
   * for the Extent element.
   */
  public void setMinX(Integer value) {
    setAttribute("MinX", value);  }

  /**
   * Gets MinY attribute
   * of the Extent element.
   */
  public Integer getMinY() {
    return getIntegerAttribute("MinY");
  }

  /**
   * Sets MinY attribute
   * for the Extent element.
   */
  public void setMinY(Integer value) {
    setAttribute("MinY", value);  }

  /**
   * Gets MinZ attribute
   * of the Extent element.
   */
  public Integer getMinZ() {
    return getIntegerAttribute("MinZ");
  }

  /**
   * Sets MinZ attribute
   * for the Extent element.
   */
  public void setMinZ(Integer value) {
    setAttribute("MinZ", value);  }

  /**
   * Gets MaxX attribute
   * of the Extent element.
   */
  public Integer getMaxX() {
    return getIntegerAttribute("MaxX");
  }

  /**
   * Sets MaxX attribute
   * for the Extent element.
   */
  public void setMaxX(Integer value) {
    setAttribute("MaxX", value);  }

  /**
   * Gets MaxY attribute
   * of the Extent element.
   */
  public Integer getMaxY() {
    return getIntegerAttribute("MaxY");
  }

  /**
   * Sets MaxY attribute
   * for the Extent element.
   */
  public void setMaxY(Integer value) {
    setAttribute("MaxY", value);  }

  /**
   * Gets MaxZ attribute
   * of the Extent element.
   */
  public Integer getMaxZ() {
    return getIntegerAttribute("MaxZ");
  }

  /**
   * Sets MaxZ attribute
   * for the Extent element.
   */
  public void setMaxZ(Integer value) {
    setAttribute("MaxZ", value);  }

  /**
   * Gets SigmaX attribute
   * of the Extent element.
   */
  public Float getSigmaX() {
    return getFloatAttribute("SigmaX");
  }

  /**
   * Sets SigmaX attribute
   * for the Extent element.
   */
  public void setSigmaX(Float value) {
    setAttribute("SigmaX", value);  }

  /**
   * Gets SigmaY attribute
   * of the Extent element.
   */
  public Float getSigmaY() {
    return getFloatAttribute("SigmaY");
  }

  /**
   * Sets SigmaY attribute
   * for the Extent element.
   */
  public void setSigmaY(Float value) {
    setAttribute("SigmaY", value);  }

  /**
   * Gets SigmaZ attribute
   * of the Extent element.
   */
  public Float getSigmaZ() {
    return getFloatAttribute("SigmaZ");
  }

  /**
   * Sets SigmaZ attribute
   * for the Extent element.
   */
  public void setSigmaZ(Float value) {
    setAttribute("SigmaZ", value);  }

  /**
   * Gets Volume attribute
   * of the Extent element.
   */
  public Integer getVolume() {
    return getIntegerAttribute("Volume");
  }

  /**
   * Sets Volume attribute
   * for the Extent element.
   */
  public void setVolume(Integer value) {
    setAttribute("Volume", value);  }

  /**
   * Gets SurfaceArea attribute
   * of the Extent element.
   */
  public Float getSurfaceArea() {
    return getFloatAttribute("SurfaceArea");
  }

  /**
   * Sets SurfaceArea attribute
   * for the Extent element.
   */
  public void setSurfaceArea(Float value) {
    setAttribute("SurfaceArea", value);  }

  /**
   * Gets Perimeter attribute
   * of the Extent element.
   */
  public Float getPerimeter() {
    return getFloatAttribute("Perimeter");
  }

  /**
   * Sets Perimeter attribute
   * for the Extent element.
   */
  public void setPerimeter(Float value) {
    setAttribute("Perimeter", value);  }

  /**
   * Gets FormFactor attribute
   * of the Extent element.
   */
  public Float getFormFactor() {
    return getFloatAttribute("FormFactor");
  }

  /**
   * Sets FormFactor attribute
   * for the Extent element.
   */
  public void setFormFactor(Float value) {
    setAttribute("FormFactor", value);  }

}
