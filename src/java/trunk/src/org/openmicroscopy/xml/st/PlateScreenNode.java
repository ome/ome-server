/*
 * org.openmicroscopy.xml.PlateScreenNode
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
 * PlateScreenNode is the node corresponding to the
 * "PlateScreen" XML element.
 *
 * Name: PlateScreen
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Screen.ome
 * Description: Define la relacion entre platos y pantallas.
 */
public class PlateScreenNode extends AttributeNode
  implements PlateScreen
{

  // -- Constructors --

  /**
   * Constructs a PlateScreen node
   * with the given associated DOM element.
   */
  public PlateScreenNode(Element element) { super(element); }

  /**
   * Constructs a PlateScreen node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlateScreenNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a PlateScreen node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlateScreenNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "PlateScreen", attach);
  }

  /**
   * Constructs a PlateScreen node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlateScreenNode(CustomAttributesNode parent, Plate plate,
    Screen screen)
  {
    this(parent, true);
    setPlate(plate);
    setScreen(screen);
  }


  // -- PlateScreen API methods --

  /**
   * Gets Plate referenced by Plate
   * attribute of the PlateScreen element.
   */
  public Plate getPlate() {
    return (Plate)
      getAttrReferencedNode("Plate", "Plate");
  }

  /**
   * Sets Plate referenced by Plate
   * attribute of the PlateScreen element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of PlateNode
   */
  public void setPlate(Plate value) {
    setAttrReferencedNode((OMEXMLNode) value, "Plate");
  }

  /**
   * Gets Screen referenced by Screen
   * attribute of the PlateScreen element.
   */
  public Screen getScreen() {
    return (Screen)
      getAttrReferencedNode("Screen", "Screen");
  }

  /**
   * Sets Screen referenced by Screen
   * attribute of the PlateScreen element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ScreenNode
   */
  public void setScreen(Screen value) {
    setAttrReferencedNode((OMEXMLNode) value, "Screen");
  }

}
