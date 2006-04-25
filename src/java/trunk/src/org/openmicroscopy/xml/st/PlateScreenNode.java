/*
 * org.openmicroscopy.xml.PlateScreenNode
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
 * Created by curtis via Xmlgen on Apr 24, 2006 4:30:18 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PlateScreenNode is the node corresponding to the
 * "PlateScreen" XML element.
 *
 * Name: PlateScreen
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Screen.ome
 * Description: Defines the relationship between Plates and Screens.
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
  public PlateScreenNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("PlateScreen"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a PlateScreen node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlateScreenNode(OMEXMLNode parent, Plate plate, Screen screen)
  {
    this(parent);
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
      createReferencedNode(PlateNode.class,
      "Plate", "Plate");
  }

  /**
   * Sets Plate referenced by Plate
   * attribute of the PlateScreen element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of PlateNode
   */
  public void setPlate(Plate value) {
    setReferencedNode((OMEXMLNode) value, "Plate", "Plate");
  }

  /**
   * Gets Screen referenced by Screen
   * attribute of the PlateScreen element.
   */
  public Screen getScreen() {
    return (Screen)
      createReferencedNode(ScreenNode.class,
      "Screen", "Screen");
  }

  /**
   * Sets Screen referenced by Screen
   * attribute of the PlateScreen element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ScreenNode
   */
  public void setScreen(Screen value) {
    setReferencedNode((OMEXMLNode) value, "Screen", "Screen");
  }

}
