/*
 * org.openmicroscopy.xml.ClassificationNode
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
 * ClassificationNode is the node corresponding to the
 * "Classification" XML element.
 *
 * Name: Classification
 * AppliesTo: I
 * Location: OME/src/xml/OME/Annotations/classification.ome
 * Description: Reference to the Category an image belongs to.
 */
public class ClassificationNode extends AttributeNode
  implements Classification
{

  // -- Constructors --

  /**
   * Constructs a Classification node
   * with the given associated DOM element.
   */
  public ClassificationNode(Element element) { super(element); }

  /**
   * Constructs a Classification node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ClassificationNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Classification node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ClassificationNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Classification", attach);
  }

  /**
   * Constructs a Classification node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ClassificationNode(CustomAttributesNode parent, Category category,
    Float confidence, Boolean valid)
  {
    this(parent, true);
    setCategory(category);
    setConfidence(confidence);
    setValid(valid);
  }


  // -- Classification API methods --

  /**
   * Gets Category referenced by Category
   * attribute of the Classification element.
   */
  public Category getCategory() {
    return (Category)
      getAttrReferencedNode("Category", "Category");
  }

  /**
   * Sets Category referenced by Category
   * attribute of the Classification element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of CategoryNode
   */
  public void setCategory(Category value) {
    setAttrReferencedNode((OMEXMLNode) value, "Category");
  }

  /**
   * Gets Confidence attribute
   * of the Classification element.
   */
  public Float getConfidence() {
    return getFloatAttribute("Confidence");
  }

  /**
   * Sets Confidence attribute
   * for the Classification element.
   */
  public void setConfidence(Float value) {
    setAttribute("Confidence", value);  }

  /**
   * Gets Valid attribute
   * of the Classification element.
   */
  public Boolean isValid() {
    return getBooleanAttribute("Valid");
  }

  /**
   * Sets Valid attribute
   * for the Classification element.
   */
  public void setValid(Boolean value) {
    setAttribute("Valid", value);  }

}
