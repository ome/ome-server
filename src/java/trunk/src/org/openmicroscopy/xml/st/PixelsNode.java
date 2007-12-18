/*
 * org.openmicroscopy.xml.PixelsNode
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

import java.util.List;
import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PixelsNode is the node corresponding to the
 * "Pixels" XML element.
 *
 * Name: Pixels
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Lugar de almacenamiento y tipo de dato de los pixeles de la
 *   imagen, incluyendo todas las dimensiones del arreglo 5-D.
 */
public class PixelsNode extends AttributeNode
  implements Pixels
{

  // -- Constructors --

  /**
   * Constructs a Pixels node
   * with the given associated DOM element.
   */
  public PixelsNode(Element element) { super(element); }

  /**
   * Constructs a Pixels node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PixelsNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Pixels node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PixelsNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Pixels", attach);
  }

  /**
   * Constructs a Pixels node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PixelsNode(CustomAttributesNode parent, Integer sizeX, Integer sizeY,
    Integer sizeZ, Integer sizeC, Integer sizeT, String pixelType,
    String fileSHA1, Repository repository, Long imageServerID)
  {
    this(parent, true);
    setSizeX(sizeX);
    setSizeY(sizeY);
    setSizeZ(sizeZ);
    setSizeC(sizeC);
    setSizeT(sizeT);
    setPixelType(pixelType);
    setFileSHA1(fileSHA1);
    setRepository(repository);
    setImageServerID(imageServerID);
  }


  // -- PixelsNode API methods --

  /** Gets BigEndian attribute of the Pixels element. */
  public Boolean isBigEndian() { return getBooleanAttribute("BigEndian"); }

  /** Sets BigEndian attribute for the Pixels element. */
  public void setBigEndian(Boolean value) {
    setAttribute("BigEndian", value);
  }

  /** Gets DimensionOrder attribute of the Pixels element. */
  public String getDimensionOrder() { return getAttribute("DimensionOrder"); }

  /** Sets DimensionOrder attribute for the Pixels element. */
  public void setDimensionOrder(String value) {
    setAttribute("DimensionOrder", value);
  }


  // -- Pixels API methods --

  /**
   * Gets SizeX attribute
   * of the Pixels element.
   */
  public Integer getSizeX() {
    return getIntegerAttribute("SizeX");
  }

  /**
   * Sets SizeX attribute
   * for the Pixels element.
   */
  public void setSizeX(Integer value) {
    setAttribute("SizeX", value);  }

  /**
   * Gets SizeY attribute
   * of the Pixels element.
   */
  public Integer getSizeY() {
    return getIntegerAttribute("SizeY");
  }

  /**
   * Sets SizeY attribute
   * for the Pixels element.
   */
  public void setSizeY(Integer value) {
    setAttribute("SizeY", value);  }

  /**
   * Gets SizeZ attribute
   * of the Pixels element.
   */
  public Integer getSizeZ() {
    return getIntegerAttribute("SizeZ");
  }

  /**
   * Sets SizeZ attribute
   * for the Pixels element.
   */
  public void setSizeZ(Integer value) {
    setAttribute("SizeZ", value);  }

  /**
   * Gets SizeC attribute
   * of the Pixels element.
   */
  public Integer getSizeC() {
    return getIntegerAttribute("SizeC");
  }

  /**
   * Sets SizeC attribute
   * for the Pixels element.
   */
  public void setSizeC(Integer value) {
    setAttribute("SizeC", value);  }

  /**
   * Gets SizeT attribute
   * of the Pixels element.
   */
  public Integer getSizeT() {
    return getIntegerAttribute("SizeT");
  }

  /**
   * Sets SizeT attribute
   * for the Pixels element.
   */
  public void setSizeT(Integer value) {
    setAttribute("SizeT", value);  }

  /**
   * Gets PixelType attribute
   * of the Pixels element.
   */
  public String getPixelType() {
    return getAttribute("PixelType");
  }

  /**
   * Sets PixelType attribute
   * for the Pixels element.
   */
  public void setPixelType(String value) {
    setAttribute("PixelType", value);  }

  /**
   * Gets FileSHA1 attribute
   * of the Pixels element.
   */
  public String getFileSHA1() {
    return getAttribute("FileSHA1");
  }

  /**
   * Sets FileSHA1 attribute
   * for the Pixels element.
   */
  public void setFileSHA1(String value) {
    setAttribute("FileSHA1", value);  }

  /**
   * Gets Repository referenced by Repository
   * attribute of the Pixels element.
   */
  public Repository getRepository() {
    return (Repository)
      getAttrReferencedNode("Repository", "Repository");
  }

  /**
   * Sets Repository referenced by Repository
   * attribute of the Pixels element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of RepositoryNode
   */
  public void setRepository(Repository value) {
    setAttrReferencedNode((OMEXMLNode) value, "Repository");
  }

  /**
   * Gets ImageServerID attribute
   * of the Pixels element.
   */
  public Long getImageServerID() {
    return getLongAttribute("ImageServerID");
  }

  /**
   * Sets ImageServerID attribute
   * for the Pixels element.
   */
  public void setImageServerID(Long value) {
    setAttribute("ImageServerID", value);  }

  /**
   * Gets a list of PixelChannelComponent elements
   * referencing this Pixels node.
   */
  public List getPixelChannelComponentList() {
    return getAttrReferringNodes("PixelChannelComponent", "Pixels");
  }

  /**
   * Gets the number of PixelChannelComponent elements
   * referencing this Pixels node.
   */
  public int countPixelChannelComponentList() {
    return getAttrReferringCount("PixelChannelComponent", "Pixels");
  }

  /**
   * Gets a list of DisplayOptions elements
   * referencing this Pixels node.
   */
  public List getDisplayOptionsList() {
    return getAttrReferringNodes("DisplayOptions", "Pixels");
  }

  /**
   * Gets the number of DisplayOptions elements
   * referencing this Pixels node.
   */
  public int countDisplayOptionsList() {
    return getAttrReferringCount("DisplayOptions", "Pixels");
  }

}
