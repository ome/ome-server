/*
 * org.openmicroscopy.xml.ImagePlateNode
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
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:49 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ImagePlateNode is the node corresponding to the
 * "ImagePlate" XML element.
 *
 * Name: ImagePlate
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Defines the relationship between Plates and Images.
 */
public class ImagePlateNode extends AttributeNode
  implements ImagePlate
{

  // -- Constructors --

  /**
   * Constructs an ImagePlate node
   * with the given associated DOM element.
   */
  public ImagePlateNode(Element element) { super(element); }

  /**
   * Constructs an ImagePlate node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImagePlateNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImagePlate node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImagePlateNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImagePlate"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImagePlate node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImagePlateNode(OMEXMLNode parent, Plate plate, Integer sample,
    String well)
  {
    this(parent, true);
    setPlate(plate);
    setSample(sample);
    setWell(well);
  }


  // -- ImagePlate API methods --

  /**
   * Gets Plate referenced by Plate
   * attribute of the ImagePlate element.
   */
  public Plate getPlate() {
    return (Plate)
      createReferencedNode(PlateNode.class,
      "Plate", "Plate");
  }

  /**
   * Sets Plate referenced by Plate
   * attribute of the ImagePlate element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of PlateNode
   */
  public void setPlate(Plate value) {
    setReferencedNode((OMEXMLNode) value, "Plate", "Plate");
  }

  /**
   * Gets Sample attribute
   * of the ImagePlate element.
   */
  public Integer getSample() {
    return getIntegerAttribute("Sample");
  }

  /**
   * Sets Sample attribute
   * for the ImagePlate element.
   */
  public void setSample(Integer value) {
    setIntegerAttribute("Sample", value);
  }

  /**
   * Gets Well attribute
   * of the ImagePlate element.
   */
  public String getWell() {
    return getAttribute("Well");
  }

  /**
   * Sets Well attribute
   * for the ImagePlate element.
   */
  public void setWell(String value) {
    setAttribute("Well", value);
  }

}
