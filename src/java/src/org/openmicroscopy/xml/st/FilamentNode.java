/*
 * org.openmicroscopy.xml.FilamentNode
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
 * FilamentNode is the node corresponding to the
 * "Filament" XML element.
 *
 * Name: Filament
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class FilamentNode extends AttributeNode
  implements Filament
{

  // -- Constructors --

  /**
   * Constructs a Filament node
   * with the given associated DOM element.
   */
  public FilamentNode(Element element) { super(element); }

  /**
   * Constructs a Filament node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilamentNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Filament node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilamentNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Filament", attach);
  }

  /**
   * Constructs a Filament node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public FilamentNode(CustomAttributesNode parent, String type, Float power,
    LightSource lightSource)
  {
    this(parent, true);
    setType(type);
    setPower(power);
    setLightSource(lightSource);
  }


  // -- Filament API methods --

  /**
   * Gets Type attribute
   * of the Filament element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the Filament element.
   */
  public void setType(String value) {
    setAttribute("Type", value);  }

  /**
   * Gets Power attribute
   * of the Filament element.
   */
  public Float getPower() {
    return getFloatAttribute("Power");
  }

  /**
   * Sets Power attribute
   * for the Filament element.
   */
  public void setPower(Float value) {
    setAttribute("Power", value);  }

  /**
   * Gets LightSource referenced by LightSource
   * attribute of the Filament element.
   */
  public LightSource getLightSource() {
    return (LightSource)
      getAttrReferencedNode("LightSource", "LightSource");
  }

  /**
   * Sets LightSource referenced by LightSource
   * attribute of the Filament element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of LightSourceNode
   */
  public void setLightSource(LightSource value) {
    setAttrReferencedNode((OMEXMLNode) value, "LightSource");
  }

}
