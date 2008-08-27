/*
 * org.openmicroscopy.xml.ImageAnnotationNode
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
 * ImageAnnotationNode is the node corresponding to the
 * "ImageAnnotation" XML element.
 *
 * Name: ImageAnnotation
 * AppliesTo: I
 * Location: OME/src/xml/OME/Annotations/annotations.ome
 * Description: An annotation that applies to a particular image. Right now,
 *   can only be text; although the text could be interpreted as a reference to
 *   a more media-rich type.
 */
public class ImageAnnotationNode extends AttributeNode
  implements ImageAnnotation
{

  // -- Constructors --

  /**
   * Constructs an ImageAnnotation node
   * with the given associated DOM element.
   */
  public ImageAnnotationNode(Element element) { super(element); }

  /**
   * Constructs an ImageAnnotation node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageAnnotationNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImageAnnotation node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageAnnotationNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "ImageAnnotation", attach);
  }

  /**
   * Constructs an ImageAnnotation node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImageAnnotationNode(CustomAttributesNode parent, String content,
    Integer theC, Integer theT, Integer theZ, Boolean valid)
  {
    this(parent, true);
    setContent(content);
    setTheC(theC);
    setTheT(theT);
    setTheZ(theZ);
    setValid(valid);
  }


  // -- ImageAnnotation API methods --

  /**
   * Gets Content attribute
   * of the ImageAnnotation element.
   */
  public String getContent() {
    return getAttribute("Content");
  }

  /**
   * Sets Content attribute
   * for the ImageAnnotation element.
   */
  public void setContent(String value) {
    setAttribute("Content", value);  }

  /**
   * Gets TheC attribute
   * of the ImageAnnotation element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the ImageAnnotation element.
   */
  public void setTheC(Integer value) {
    setAttribute("TheC", value);  }

  /**
   * Gets TheT attribute
   * of the ImageAnnotation element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the ImageAnnotation element.
   */
  public void setTheT(Integer value) {
    setAttribute("TheT", value);  }

  /**
   * Gets TheZ attribute
   * of the ImageAnnotation element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the ImageAnnotation element.
   */
  public void setTheZ(Integer value) {
    setAttribute("TheZ", value);  }

  /**
   * Gets Valid attribute
   * of the ImageAnnotation element.
   */
  public Boolean isValid() {
    return getBooleanAttribute("Valid");
  }

  /**
   * Sets Valid attribute
   * for the ImageAnnotation element.
   */
  public void setValid(Boolean value) {
    setAttribute("Valid", value);  }

}
