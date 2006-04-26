/*
 * org.openmicroscopy.xml.DatasetAnnotationNode
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
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:48 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * DatasetAnnotationNode is the node corresponding to the
 * "DatasetAnnotation" XML element.
 *
 * Name: DatasetAnnotation
 * AppliesTo: D
 * Location: OME/src/xml/OME/Annotations/annotations.ome
 * Description: An annotation that applies to a particular dataset. Right now,
 *   can only be text; although the text could be interpreted as a reference to
 *   a more media-rich type.
 */
public class DatasetAnnotationNode extends AttributeNode
  implements DatasetAnnotation
{

  // -- Constructors --

  /**
   * Constructs a DatasetAnnotation node
   * with the given associated DOM element.
   */
  public DatasetAnnotationNode(Element element) { super(element); }

  /**
   * Constructs a DatasetAnnotation node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DatasetAnnotationNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a DatasetAnnotation node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public DatasetAnnotationNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("DatasetAnnotation"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a DatasetAnnotation node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DatasetAnnotationNode(OMEXMLNode parent, String content,
    Boolean valid)
  {
    this(parent, true);
    setContent(content);
    setValid(valid);
  }


  // -- DatasetAnnotation API methods --

  /**
   * Gets Content attribute
   * of the DatasetAnnotation element.
   */
  public String getContent() {
    return getAttribute("Content");
  }

  /**
   * Sets Content attribute
   * for the DatasetAnnotation element.
   */
  public void setContent(String value) {
    setAttribute("Content", value);
  }

  /**
   * Gets Valid attribute
   * of the DatasetAnnotation element.
   */
  public Boolean isValid() {
    return getBooleanAttribute("Valid");
  }

  /**
   * Sets Valid attribute
   * for the DatasetAnnotation element.
   */
  public void setValid(Boolean value) {
    setBooleanAttribute("Valid", value);
  }

}
