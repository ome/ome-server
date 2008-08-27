/*
 * org.openmicroscopy.xml.PixelChannelComponentNode
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
 * PixelChannelComponentNode is the node corresponding to the
 * "PixelChannelComponent" XML element.
 *
 * Name: PixelChannelComponent
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Describe como cada canal en el arreglo de pixeles se relacion
 *   con los Canales Logicos.
 */
public class PixelChannelComponentNode extends AttributeNode
  implements PixelChannelComponent
{

  // -- Constructors --

  /**
   * Constructs a PixelChannelComponent node
   * with the given associated DOM element.
   */
  public PixelChannelComponentNode(Element element) { super(element); }

  /**
   * Constructs a PixelChannelComponent node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PixelChannelComponentNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PixelChannelComponent node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PixelChannelComponentNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PixelChannelComponent", attach);
  }

  /**
   * Constructs a PixelChannelComponent node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PixelChannelComponentNode(CustomAttributesNode parent, Pixels pixels,
    Integer index, String colorDomain, LogicalChannel logicalChannel)
  {
    this(parent, true);
    setPixels(pixels);
    setIndex(index);
    setColorDomain(colorDomain);
    setLogicalChannel(logicalChannel);
  }


  // -- PixelChannelComponent API methods --

  /**
   * Gets Pixels referenced by Pixels
   * attribute of the PixelChannelComponent element.
   */
  public Pixels getPixels() {
    return (Pixels)
      getAttrReferencedNode("Pixels", "Pixels");
  }

  /**
   * Sets Pixels referenced by Pixels
   * attribute of the PixelChannelComponent element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of PixelsNode
   */
  public void setPixels(Pixels value) {
    setAttrReferencedNode((OMEXMLNode) value, "Pixels");
  }

  /**
   * Gets Index attribute
   * of the PixelChannelComponent element.
   */
  public Integer getIndex() {
    return getIntegerAttribute("Index");
  }

  /**
   * Sets Index attribute
   * for the PixelChannelComponent element.
   */
  public void setIndex(Integer value) {
    setAttribute("Index", value);  }

  /**
   * Gets ColorDomain attribute
   * of the PixelChannelComponent element.
   */
  public String getColorDomain() {
    return getAttribute("ColorDomain");
  }

  /**
   * Sets ColorDomain attribute
   * for the PixelChannelComponent element.
   */
  public void setColorDomain(String value) {
    setAttribute("ColorDomain", value);  }

  /**
   * Gets LogicalChannel referenced by LogicalChannel
   * attribute of the PixelChannelComponent element.
   */
  public LogicalChannel getLogicalChannel() {
    return (LogicalChannel)
      getAttrReferencedNode("LogicalChannel", "LogicalChannel");
  }

  /**
   * Sets LogicalChannel referenced by LogicalChannel
   * attribute of the PixelChannelComponent element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of LogicalChannelNode
   */
  public void setLogicalChannel(LogicalChannel value) {
    setAttrReferencedNode((OMEXMLNode) value, "LogicalChannel");
  }

}
