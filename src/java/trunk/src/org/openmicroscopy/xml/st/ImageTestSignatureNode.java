/*
 * org.openmicroscopy.xml.ImageTestSignatureNode
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
 * ImageTestSignatureNode is the node corresponding to the
 * "ImageTestSignature" XML element.
 *
 * Name: ImageTestSignature
 * AppliesTo: I
 * Location: OME/src/xml/OME/Tests/datasetExample.ome
 */
public class ImageTestSignatureNode extends AttributeNode
  implements ImageTestSignature
{

  // -- Constructors --

  /**
   * Constructs an ImageTestSignature node
   * with the given associated DOM element.
   */
  public ImageTestSignatureNode(Element element) { super(element); }

  /**
   * Constructs an ImageTestSignature node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageTestSignatureNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImageTestSignature node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageTestSignatureNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImageTestSignature"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImageTestSignature node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImageTestSignatureNode(OMEXMLNode parent, Float value)
  {
    this(parent, true);
    setValue(value);
  }


  // -- ImageTestSignature API methods --

  /**
   * Gets Value attribute
   * of the ImageTestSignature element.
   */
  public Float getValue() {
    return getFloatAttribute("Value");
  }

  /**
   * Sets Value attribute
   * for the ImageTestSignature element.
   */
  public void setValue(Float value) {
    setFloatAttribute("Value", value);
  }

}