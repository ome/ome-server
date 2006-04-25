/*
 * org.openmicroscopy.xml.PlateNode
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

import java.util.List;
import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * PlateNode is the node corresponding to the
 * "Plate" XML element.
 *
 * Name: Plate
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Plate.ome
 * Description: Stores information about the plates that make up a
 *   high-throughput screen. Plates may belong to more than one screen, and
 *   have a many-to-many relationship to screens.
 */
public class PlateNode extends AttributeNode
  implements Plate
{

  // -- Constructors --

  /**
   * Constructs a Plate node
   * with the given associated DOM element.
   */
  public PlateNode(Element element) { super(element); }

  /**
   * Constructs a Plate node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public PlateNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Plate"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Plate node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public PlateNode(OMEXMLNode parent, String name, String externalReference,
    Screen screen)
  {
    this(parent);
    setName(name);
    setExternalReference(externalReference);
    setScreen(screen);
  }


  // -- Plate API methods --

  /**
   * Gets Name attribute
   * of the Plate element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the Plate element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets ExternalReference attribute
   * of the Plate element.
   */
  public String getExternalReference() {
    return getAttribute("ExternalReference");
  }

  /**
   * Sets ExternalReference attribute
   * for the Plate element.
   */
  public void setExternalReference(String value) {
    setAttribute("ExternalReference", value);
  }

  /**
   * Gets Screen referenced by Screen
   * attribute of the Plate element.
   */
  public Screen getScreen() {
    return (Screen)
      createReferencedNode(ScreenNode.class,
      "Screen", "Screen");
  }

  /**
   * Sets Screen referenced by Screen
   * attribute of the Plate element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ScreenNode
   */
  public void setScreen(Screen value) {
    setReferencedNode((OMEXMLNode) value, "Screen", "Screen");
  }

  /**
   * Gets a list of ImagePlate elements
   * referencing this Plate node.
   */
  public List getImagePlateList() {
    return createAttrReferralNodes(ImagePlateNode.class,
      "ImagePlate", "Plate");
  }

  /**
   * Gets the number of ImagePlate elements
   * referencing this Plate node.
   */
  public int countImagePlateList() {
    return getSize(getAttrReferrals("ImagePlate",
      "Plate"));
  }

  /**
   * Gets a list of PlateScreen elements
   * referencing this Plate node.
   */
  public List getPlateScreenList() {
    return createAttrReferralNodes(PlateScreenNode.class,
      "PlateScreen", "Plate");
  }

  /**
   * Gets the number of PlateScreen elements
   * referencing this Plate node.
   */
  public int countPlateScreenList() {
    return getSize(getAttrReferrals("PlateScreen",
      "Plate"));
  }

}
